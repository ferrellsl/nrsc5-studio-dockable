<#
Diagnostic-only script -- makes no changes to the app or your system.

Purpose: our last two attempts assumed Windows was auto-minimizing the
pop-out panel windows because they were Win32 "owned" windows of the main
window (GWLP_HWNDPARENT set). Reading eframe/egui-winit/winit's actual
source confirmed neither eframe nor egui ever sets that relationship (or
a WS_CHILD parent relationship) for these windows -- so that theory was
wrong, which is also why both fixes built on it did nothing observable.

This script watches the live windows of the running app and prints, once
a second, each visible top-level window's title, whether Windows currently
considers it minimized (Iconic), and its raw owner HWND (0 = none). Run it
WHILE reproducing the bug so we can see what actually changes at the
moment the main window gets minimized (or a new pop-out is opened) --
that tells us what's really driving this instead of guessing again.

Usage:
    1. Launch NRSC5 Studio and pop out a couple of panels.
    2. Run:  .\scripts\diag-popout-windows.ps1
    3. While it's running (30 seconds), minimize the main window, then
       restore it, then pop out one more panel while the others are open.
    4. Copy/paste the full console output back.
#>

Add-Type @"
using System;
using System.Runtime.InteropServices;
using System.Text;
public class Win32Diag {
    public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);
    [DllImport("user32.dll")] public static extern bool EnumWindows(EnumWindowsProc lpEnumFunc, IntPtr lParam);
    [DllImport("user32.dll")] public static extern int GetWindowTextLength(IntPtr hWnd);
    [DllImport("user32.dll")] public static extern int GetWindowText(IntPtr hWnd, StringBuilder lpString, int nMaxCount);
    [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint lpdwProcessId);
    [DllImport("user32.dll")] public static extern IntPtr GetWindowLongPtr(IntPtr hWnd, int nIndex);
    [DllImport("user32.dll")] public static extern bool IsIconic(IntPtr hWnd);
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr hWnd);
}
"@

$GWL_STYLE = -16
$GWLP_HWNDPARENT = -8

# Matched by window TITLE instead of process/exe name -- the exe name
# turned out not to be "nrsc5-studio.exe" as expected (the previous run
# found no matching process at all), but every window this app creates
# has a title starting with "NRSC5 Studio" (see src/main.rs and the
# `title = format!("NRSC5 Studio \u{2014} {}", ...)` in app.rs), so
# matching on that is more robust than guessing the process name again.
function Get-AppWindows {
    $rows = New-Object System.Collections.Generic.List[object]

    $cb = {
        param($hWnd, $lParam)
        $len = [Win32Diag]::GetWindowTextLength($hWnd)
        if ($len -gt 0) {
            $sb = New-Object System.Text.StringBuilder ($len + 1)
            [Win32Diag]::GetWindowText($hWnd, $sb, $sb.Capacity) | Out-Null
            $title = $sb.ToString()
            if ($title -like "NRSC5 Studio*") {
                $procId = 0
                [Win32Diag]::GetWindowThreadProcessId($hWnd, [ref]$procId) | Out-Null
                $procName = try { (Get-Process -Id $procId -ErrorAction Stop).ProcessName } catch { "?" }
                $visible = [Win32Diag]::IsWindowVisible($hWnd)
                $iconic = [Win32Diag]::IsIconic($hWnd)
                $owner = [Win32Diag]::GetWindowLongPtr($hWnd, $GWLP_HWNDPARENT)
                $style = [Win32Diag]::GetWindowLongPtr($hWnd, $GWL_STYLE)
                $rows.Add([PSCustomObject]@{
                    Title   = $title
                    Process = $procName
                    HWND    = "0x{0:X}" -f $hWnd.ToInt64()
                    Visible = $visible
                    Iconic  = $iconic
                    Owner   = "0x{0:X}" -f $owner.ToInt64()
                    Style   = "0x{0:X8}" -f ($style.ToInt64() -band 0xFFFFFFFF)
                })
            }
        }
        return $true
    }
    [Win32Diag]::EnumWindows($cb, [IntPtr]::Zero) | Out-Null
    return $rows
}

Write-Host "Watching for 30 seconds. Minimize/restore the main window and pop out a panel now..." -ForegroundColor Cyan
Write-Host ""

$prev = $null
for ($i = 0; $i -lt 30; $i++) {
    $rows = Get-AppWindows
    if ($rows.Count -eq 0) {
        Write-Host "[$i s] no matching window found yet"
    } else {
        $snapshot = $rows | Sort-Object Title | Format-Table -AutoSize | Out-String
        if ($snapshot -ne $prev) {
            Write-Host "--- t=${i}s ---" -ForegroundColor Yellow
            Write-Host $snapshot
            $prev = $snapshot
        }
    }
    Start-Sleep -Seconds 1
}

Write-Host "Done." -ForegroundColor Green
