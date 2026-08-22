param(
	[ValidateSet("debug", "release")]
	[string]$Configuration = "debug",
	[ValidateSet("build", "check", "test")]
	[string]$Command = "build"
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
Set-Location $Root

$ToolRoot = Join-Path $Root ".toolchains\llvm-mingw-20260505-ucrt-x86_64\bin"
if (-not (Test-Path $ToolRoot)) {
	throw "llvm-mingw toolchain not found: $ToolRoot (run scripts/bootstrap-deps.ps1 and toolchain bootstrap first)"
}

$DllToolAlias = Join-Path $ToolRoot "dlltool.exe"
if (-not (Test-Path $DllToolAlias)) {
	Copy-Item (Join-Path $ToolRoot "x86_64-w64-mingw32-dlltool.exe") $DllToolAlias -Force
}

$WinResAlias = Join-Path $ToolRoot "windres.exe"
if (-not (Test-Path $WinResAlias)) {
	Copy-Item (Join-Path $ToolRoot "x86_64-w64-mingw32-windres.exe") $WinResAlias -Force
}

# PATH order matters:
#   1) C:\msys64\mingw64\bin  -- libclang.dll's transitive deps
#                                (libstdc++, libwinpthread) live here.
#                                soapysdr-sys's build script invokes
#                                bindgen, which loads libclang via
#                                LoadLibraryExW; without these on PATH
#                                it fails with "LoadLibraryExW failed".
#   2) %USERPROFILE%\.cargo\bin -- cargo + rustup shims.
#   3) llvm-mingw\bin           -- our pinned cross-compiler.
#
# An earlier version of this script tried putting llvm-mingw first,
# theorizing that Clang's MinGW driver was "adopting" a competing GCC
# install found via a PATH scan at link time. That theory turned out to
# be wrong -- the stray `-L C:/msys64/mingw64/bin/../lib` search path
# that prompted it actually comes from soapysdr-sys's own build script
# (visible directly in its build output: `cargo:rustc-link-search=
# native=C:/msys64/mingw64/bin/../lib`), not from Clang's compiler
# detection -- and reordering PATH broke bindgen's ability to load
# libclang.dll instead (it needs MSYS2's copies of libstdc++/
# libwinpthread found ahead of llvm-mingw's own differently-built
# same-named DLLs). MSYS2 first is correct; the real fix for the
# undefined-symbol link error lives in `.cargo/config.toml`'s
# `rustflags` (pointing the linker at our own toolchain's
# libmingw32.a/libmingwex.a directly, sidestepping the question of which
# `-L` dir "wins" entirely).
$MsysBin = "C:\msys64\mingw64\bin"
if (-not (Test-Path $MsysBin)) {
	Write-Warning "MSYS2 mingw64 not found at $MsysBin -- bindgen-based build scripts may fail to load libclang."
	$env:PATH = "$env:USERPROFILE\.cargo\bin;$ToolRoot;$env:PATH"
} else {
	$env:PATH = "$MsysBin;$env:USERPROFILE\.cargo\bin;$ToolRoot;$env:PATH"
	# bindgen also reads LIBCLANG_PATH directly; setting it explicitly
	# avoids relying purely on PATH ordering for libclang.dll discovery.
	$env:LIBCLANG_PATH = $MsysBin
}

# audiopus_sys vendors libopus and configures it with the `cmake` crate
# when no system Opus.pc is found (which is always, on this MSYS2 setup --
# we only install SoapySDR-related packages, not opus). Upstream opus's
# CMakeLists.txt still declares `cmake_minimum_required(VERSION 3.1)`;
# CMake 4.0 dropped all support for `cmake_minimum_required` below 3.5 and
# now hard-errors ("Compatibility with CMake < 3.5 has been removed")
# instead of just warning. This is CMake's own documented escape hatch --
# it doesn't relax anything about our own build, just tells CMake to treat
# opus's un-updated CMakeLists.txt as if it had asked for policies as of
# 3.5. The `cmake` Rust crate (used by audiopus_sys's build script) does
# not clear the child process's environment before invoking `cmake.exe`,
# so setting this here reaches it the same way LIBCLANG_PATH above does.
# NOTE: this can't live in `.cargo/config.toml`'s `[target.*.env]` -- that
# key isn't part of Cargo's actual config schema (only a top-level `[env]`
# table is), so anything placed there is silently a no-op.
# Safe to drop once audiopus_sys/opus bump their declared minimum.
$env:CMAKE_POLICY_VERSION_MINIMUM = "3.5"

# Tell CMake explicitly which C/C++ compiler to use for that same opus
# build. The `cmake` crate generates clang-style flags for this target
# (`--target=x86_64-pc-windows-gnu`) but -- on Windows, with the
# MinGW-Makefiles generator we end up on here -- deliberately leaves
# picking the actual compiler *binary* to CMake's own autodetection
# rather than passing `-DCMAKE_C_COMPILER` itself. Left alone, that
# autodetection just searches PATH for something named `cc`/`gcc`/`clang`
# and finds MSYS2's real GCC first (its dir has to be on PATH, earlier,
# for libclang.dll) -- and GCC doesn't understand clang's `--target=`
# flag, so the build breaks with "unrecognized command-line option
# '--target=...'". Pointing CC/CXX at our own bundled llvm-mingw clang
# resolves the mismatch: same compiler the flags were written for, same
# one `.cargo/config.toml` already names as the linker.
$env:CC = Join-Path $ToolRoot "x86_64-w64-mingw32-clang.exe"
$env:CXX = Join-Path $ToolRoot "x86_64-w64-mingw32-clang++.exe"

# rustup writes its "info: syncing channel updates..." progress to
# stderr; under $ErrorActionPreference = "Stop" PowerShell 5.1 wraps
# every native stderr line as a RemoteException error record and aborts
# the script before cargo runs. Temporarily downgrade to "Continue" for
# the native-command sections and rely on $LASTEXITCODE for real failure
# detection.
$prev = $ErrorActionPreference
$ErrorActionPreference = "Continue"
try {
	& rustup toolchain install stable-x86_64-pc-windows-gnullvm
	if ($LASTEXITCODE -ne 0) {
		throw "rustup toolchain install failed with exit code $LASTEXITCODE"
	}

	$cargoArgs = @("+stable-x86_64-pc-windows-gnullvm", $Command, "--target", "x86_64-pc-windows-gnullvm")
	if ($Configuration -eq "release") {
		$cargoArgs += "--release"
	}

	& cargo @cargoArgs
	$cargoExit = $LASTEXITCODE
}
finally {
	$ErrorActionPreference = $prev
}
exit $cargoExit
