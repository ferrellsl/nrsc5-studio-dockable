<div align="center">

![NRSC5 Studio Icon](packaging/linux/icons/hicolor/64x64/apps/nrsc5-studio.png)

# NRSC5 Studio

**HD Radio reception, decoded and visualized in real time.**

A native Windows and Linux desktop app for listening to **HD Radio** broadcasts with an RTL-SDR, SDRplay, or HackRF receiver. Built in Rust with [egui](https://www.egui.rs/), wrapped around the excellent [`nrsc5`](https://github.com/theori-io/nrsc5) HD Radio decoder.

This fork of NRSC5 Studio provides the user with detachable viewports that can be moved anywhere on the screen or even onto a different display monitor.  To detach a viewport window from the main application, right-click on its tab and a context menu will appear.  Select "Open in a New Window". You can now move this window anywhere.  To reattach the window(s) to the main viewport, click on "Return to Dock".  All windows, including the main viewport can be moved, minimized, maximized and resized independently of one another.  Just drop the EXE into your existing NRSC5 Studio folder and run it from there.

<img width="2560" height="1440" alt="image" src="https://github.com/user-attachments/assets/1c18edce-2bf5-4aa6-94aa-ce507a6993f9" />


<img width="2560" height="1440" alt="image" src="https://github.com/user-attachments/assets/968ec28f-17cf-4554-b971-7841b746ad4b" />




## Features

- **Full HD Radio playback** — **HD1–HD8** subchannel selection (the full HD Radio program range), with a **SIS-aware selector grid**: subchannels the station actually advertises light up at full intensity; the rest stay dimmed-but-clickable with a tooltip explaining the station doesn't list that program (you can still probe). Automatic retune on frequency change, persistent presets you can save, recall, rename, and re-target via a double-click edit dialog.
- **Now-Playing pane** — title / artist / album / genre from broadcast metadata, plus cover art and the station logo if the station you are listening to transmits it.
- **Analog-FM fallback (stereo + RDS)** — when the HD signal can't lock (a weak fringe station, a deep fade, or a plain non-HD FM broadcast), NRSC5 Studio can demodulate the underlying analog FM signal from the same I/Q stream and keep audio flowing. A **Mode Select** control on the Station Information panel picks the source: **Digital Only** (analog path stays silent — the default), **Automatic** (HD while synced, then falls back down the HD → analog-stereo → mono → squelch ladder and climbs back when the signal recovers), or **Analog Only** (forces the analog demod to own the audio). The analog chain locks the 19 kHz pilot with a PLL for **stereo** and blends stereo width toward mono as the pilot weakens (so it degrades cleanly instead of getting noisy), applies 75 µs de-emphasis, and decodes the 57 kHz **RDS** subcarrier to surface the Program Service name and RadioText in a scrolling ticker (and as the now-playing fallback when no HD metadata is present). Mode, stereo, and RDS toggles all persist between runs.
- **Station Information pane** — a first-class home for everything the station broadcasts about *itself* via the HD Radio SIS (Station Information Service) table: call sign, slogan, rolling message banner, country and FCC facility ID (linked to the FCC public lookup), transmitter latitude / longitude / altitude, per-subchannel short name + program type + sound experience + live audio bit rate in kbps, the station's data services (Traffic, Weather, Album Art, etc.), and any active emergency alert in a red callout banner. A **band-aware service-mode badge** is also displayed — it reads the PSMI value straight from the decoder's `SYNC` telemetry and labels it for the tuned band: `MA1` / `MA3` for AM stations and `MP1` / `MP2` / `MP3` / `MP5` / `MP6` / `MP11` for FM, matching nrsc5's own `SERVICE_MODE_*` definitions (so an FM hybrid station reads `MP1`, not the AM-only `MA1`). Fields populate progressively after sync (call sign and slogan in seconds; location and FCC ID can take a minute or two).
- **Album-Art Collage** — a rolling 8-hour squarified-treemap heat-map of every unique cover seen on the station. Frequent plays grow into bigger tiles; the layout re-flows as new art comes in. **Survives restarts** — covers are cached to disk (`data\art-cache\` in portable mode, `%LOCALAPPDATA%\nrsc5-studio\art-cache\` otherwise) so the heat-map repopulates instantly on relaunch (within the 8-hour window).
- **24-Hour Song Log** — every play the station broadcasts metadata for is captured with a timestamp and persisted across restarts. Two views: a **Timeline** of the most recent plays and a **Top Played** grouping by `(title, artist)`. Export to RFC-4180 CSV for the scrobbler crowd. Aggressive filtering keeps station IDs, slogans, and call signs out of the log.
- **Spectrum + Waterfall** — a dedicated SDR scope tab with a 1024-bin live FFT trace (SDR#-style translucent gradient fill, ±20 dB grid, faint shading at the HD digital sidebands at ±129–199 kHz) and a 256-row scrolling waterfall underneath with a turbo colormap. Driven from a tap on the same I/Q stream that feeds the decoder, so what you see is what nrsc5 sees.
- **QPSK Constellation** — a phosphor-green scope showing the OFDM-subcarrier constellation cloud, with cloud spread driven by live MER per sideband. Watch the cloud tighten as signal quality improves — especially satisfying while the AGC walks into its sweet spot.
- **Closed-Loop AGC** — a host-side automatic-gain-control loop (separate from the dongle's built-in AGC) that drives the active SDR's primary gain element to maximize per-sideband MER for whatever signal you're tuned to. Profile-driven: on RTL-SDR it walks the R820T2 gain table; on SDRplay it controls IF gain reduction (with sign-flip handled automatically); on HackRF it drives the LNA. Switch between **Auto** / **Manual** / **Hardware AGC** in the Signal panel; choice persists between runs.
- **Traffic Map** — TPEG traffic-tile decode, stitched into a single map image the moment all tiles for an area arrive. Carried by stations that broadcast the Total Traffic Network (TTN) or HERE data services.
- **Weather Radar Animation** — every weather overlay frame from the broadcast is captured with its real wall-clock timestamp. Play / pause / scrub through up to 90 minutes of frames with a rocker slider; duplicate frames are deduplicated by content hash so the loop only advances when the station actually pushes new radar. Carried by stations that broadcast the Total Traffic Network (TTN) or HERE data services.
- **Signal Quality** — live MER (lower / upper sidebands), BER counters, and the current AGC gain in dB with a status badge (probing / settled / bailed) and time-since-last-change.
- **Per-app Volume** — on Windows, a COM-based per-process volume / mute control so NRSC5 Studio's volume slider only changes NRSC5 Studio's audio (not the whole system). On Linux the slider applies a software-side gain to the cpal output stream.
- **Multi-SDR support** — RTL-SDR (R820T2 / E4000), SDRplay (RSP1A / RSPduo / RSPdx via the proprietary SDRplay API), and HackRF One out of the box. Switch devices via the hamburger menu's **📡 SDR Settings…** modal; per-element gain sliders, PPM correction, and HD-Radio-specific notes are surfaced per driver.
- **Friendly first-run experience** — if no SDR is plugged in, a centered "Plug in an SDR and press Refresh" overlay replaces the cryptic empty state. The overlay auto-dismisses the moment a device is detected.
- **Persistent dock layout** — drag tabs into floating sub-panes, split horizontally or vertically. Your layout is restored on the next launch.
- **Dark / light themes**, DPI-aware sizing, and a procedurally-rendered window icon.

---

## Hardware requirements

- An installed and working **SDR** with an antenna suitable for FM (87.5–108 MHz). Generic RTL2832U + R820T2 dongles are still the cheapest, most-tested option.
- A nearby HD Radio FM broadcaster. (Most U.S. metro areas have several.)
- Windows 10 or 11 (x86_64), or a Linux distribution recent enough to run a modern egui app (Debian 12+, Ubuntu 22.04+, Fedora 40+) on x86_64.
- **Have a different SDR you'd like supported?** If it has a [SoapySDR](https://github.com/pothosware/SoapySDR) module, [open an issue](https://github.com/LTCAshraven/nrsc5-studio/issues) and I'll get right on it. It should be straightforward to add.

### Supported SDRs (v0.3.0)

NRSC5 Studio v0.3.0 introduces a unified [SoapySDR](https://github.com/pothosware/SoapySDR) backend so the same build supports multiple SDR families. Switch between them via the **hamburger menu → 📡 SDR Settings…**.

| Device family       | Status        | Notes                                                                                          |
|---------------------|---------------|------------------------------------------------------------------------------------------------|
| RTL-SDR (R820T2)    | ✅ Validated   | Reference platform. Cheapest entry point.                                                       |
| RTL-SDR (E4000)     | ✅ Validated   | Nooelec SmartXTR and similar. AGC drives `TUNER`; six other IF stages settable manually.        |
| SDRplay RSP1A       | ✅ Validated   | 14-bit ADC, much wider dynamic range than RTL-SDR. **Requires SDRplay API v3.x** (see below).   |
| SDRplay (other RSP) | 🟡 Should work | RSPduo / RSPdx use the same profile as RSP1A; bench-validation contributions welcome.            |
| HackRF One          | 🟡 Profile-only | Profile ships but is not yet bench-validated. AGC drives `LNA`; report any issues you find.     |

#### RTL-SDR (Zadig)

If you don't already have working RTL-SDR drivers, install [Zadig](https://zadig.akeo.ie/) and follow the standard [WinUSB driver setup](https://www.rtl-sdr.com/rtl-sdr-quick-start-guide/) once before running NRSC5 Studio. This is the only end-user prerequisite for RTL-SDR support.

#### SDRplay (proprietary API)

SDRplay receivers (RSP1A, RSPduo, RSPdx, …) require the SDRplay API service to be installed separately. It's free but **cannot be redistributed** under SDRplay's license — so the portable zip ships only the open-source `libsdrPlaySupport.dll` bridge module. To use an SDRplay device:

1. Download and install the **SDRplay API v3.x** from [sdrplay.com/downloads](https://www.sdrplay.com/downloads/).
2. Plug in your SDRplay device.
3. Launch NRSC5 Studio. Open **📡 SDR Settings…**, click **Refresh**, and pick the SDRplay entry.

Users without an SDRplay device can ignore this entirely — the bundled module loads lazily.

#### HackRF One

HackRF support ships in v0.3.0 but is **not yet bench-validated**. The device profile (`LNA`, `VGA`, `AMP` gain stages) is conservative but may need tuning for HD Radio. If you have a HackRF and try it, opening an issue with your findings would be hugely appreciated.

### Remote SDRs (SoapyRemote and rtl_tcp)

NRSC5 Studio can drive a remote SDR via one of two protocols, picked from the **Transport** row at the top of **📡 SDR Settings…**:

- **SoapyRemote** — connects to a `SoapySDRServer` instance on the remote host. Use this when the remote dongle is anything other than a plain RTL-SDR (e.g. SDRplay over the network) or when you want SoapySDR's full feature set (per-element gain, antenna selection, etc.). The remote machine must have **SoapyRemote** installed alongside the device's Soapy module (`SoapyRTLSDR`, `SoapySDRPlay3`, …). Default port `55132`.
- **rtl_tcp** — connects directly to a native `rtl_tcp` server. Use this for the classic RTL-SDR-over-network case where you only need a single tuner-gain control. The remote machine just needs `rtl_tcp` (ships with `rtl-sdr` on most distributions). Default port `1234`.

Pick the transport, enter the remote host and port, and press Start as usual. The in-process spectrum, AGC, and audio pipeline are identical regardless of transport.

Configs from earlier 0.2.x / 0.3.x releases that used `use_rtl_tcp = true` are migrated automatically to `transport = "rtl_tcp_remote"` on first launch; the legacy keys are then dropped from `config.toml`.


### Prerequisites

- A Rust toolchain (install via [rustup](https://rustup.rs/)). The build pins `stable-x86_64-pc-windows-gnullvm`.
- The bundled `llvm-mingw` toolchain. The repo expects it at `.toolchains\llvm-mingw-20260505-ucrt-x86_64\` — download a release from [mstorsjo/llvm-mingw](https://github.com/mstorsjo/llvm-mingw/releases) and extract it there.
- The bundled `bin\` runtime (`libnrsc5.dll`, `libSoapySDR.dll`, `librtlsdr.dll`, Soapy plugin modules) — already in the repo. If you ever need to rebuild `libnrsc5.dll` from upstream source, `scripts\build-nrsc5-msys2.ps1` drives the full MSYS2 build of the pinned nrsc5 v3.2.0 tag with `USE_STATIC=ON`.

### Build

From an elevated PowerShell prompt in the repo root:

```powershell
.\scripts\cargo-gnu.ps1
```

This installs the gnullvm Rust toolchain if missing, then produces `target\x86_64-pc-windows-gnullvm\debug\nrsc5-studio.exe`.

For a release build:

```powershell
.\scripts\cargo-gnu.ps1 -Configuration release
```

The portable distribution also bundles several third-party binaries that
remain under their original licenses (GPL-2.0, GPL-3.0, and LGPL-2.1). Their
full notices and upstream sources are listed in
[THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
