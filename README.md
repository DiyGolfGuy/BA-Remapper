# BA Remapper

**Control box software for GSPro — by BA Custom Products**

BA Remapper is the companion app for the BA Custom Products wireless control box. Out of the box, every button sends its printed GSPro hotkey with no software at all. BA Remapper adds the FN secondary layer (the yellow print), on-screen Smart Clicks powered by built-in Windows OCR, and an automatic scramble shot picker — all in a single portable .exe with nothing to install.

---

## Download and First Run

1. Download `BARemapper.exe` from the [Releases](../../releases) page (or bacustomproducts.com).
2. Put it somewhere permanent — recommended: `Documents\BA Custom Products\Remapper\BARemapper.exe`. Don't run it from Downloads long-term; the auto-start shortcut follows the file.
3. Double-click to run. If Windows SmartScreen appears, click **More info → Run anyway** (the app is not yet code-signed; this prompt appears once per downloaded file).
4. That first run automatically clears the Windows download flag, so "Start with Windows" launches cleanly at every boot afterward.

**Requirements:** Windows 10 or 11, GSPro. Smart Clicks and Auto-Pick Scramble use the OCR engine built into Windows (standard English installs qualify) — no extra software, no internet, nothing sent anywhere.

---

## What It Does

### Primary keys — always working
The box's white-printed functions (Heat Map, Putt, Flyover, Club Up/Down, Aim arrows, Tee position, Reset Aim, Shot Cam, Mulligan) work exactly as printed, remapper running or not. Turning the remapper OFF (Ctrl+F12 or the big button) restores plain typing everywhere.

### FN secondary layer
Hold the FN button (Reset Aim by default) and press any other button to fire its secondary function. Keep FN held and tap repeatedly — consecutive presses of the same Smart Click fire near-instantly, so you can cycle Next Option or walk the ball with Move Forward / Move Back as fast as you can tap.

Each button's secondary can be one of three types:

| Type | What it does |
|---|---|
| **GSPro Hotkey** | Sends any GSPro key, including scramble Select Shot 1–4, Clear View (B), Mulligan, and every standard binding |
| **Smart Click (OCR)** | Reads the live GSPro screen, finds the menu button by its text, and clicks it — zero setup, works at any resolution, any monitor count, any Windows scaling |
| **Taught Screen Click** | Clicks a fixed position you capture yourself (the classic method, still available) |

### Smart Clicks
Five penalty/relief menu actions are built in: **Move Forward, Move Back, Next Option, Drop Ball / Rehit, OB Rehit**. Before any click, the app verifies the entire relief menu — all buttons, in order, evenly spaced, one column — and clicks the verified position inside it. It never clicks a lone matched word, never clicks into an opening or closing animation, and if a button's own text misreads, the surrounding menu still proves where it is. Drop Ball / Rehit clicks the changing second slot whichever word it currently shows; OB Rehit handles both the "You have hit OB!" dialog and the relief menu's rehit option. If the menu genuinely isn't on screen, the app tells you instead of guessing.

### Built-in preset: "Basic Secondary"
Select **Basic Secondary** from the profile dropdown and the yellow print on the box just works — zero programming:

| FN + button | Action |
|---|---|
| CLUB DOWN | Clear View (B) |
| TEE LEFT | OB Rehit |
| AIM UP | Move Forward |
| AIM DOWN | Move Back |
| AIM LEFT | Next Option |
| AIM RIGHT | Drop Ball / Rehit |

The preset is locked so it always matches the print — it can't be edited, reset, or renamed. Pressing **Del** on it restores factory defaults instantly. To customize, create your own profile with **+ New**.

### Auto-Pick Scramble
Turn on the checkbox and BA Remapper watches for GSPro's scramble shot-select cards whenever the app is running. After your chosen delay (5 / 10 / 15 / 20 seconds, with an optional on-screen countdown), it picks the best ball by pressing its shot key (1–4):

1. **Fewest strokes first** — a 2nd-shot ball always beats a closer 3rd-shot ball from a penalty drop
2. **Green always wins** among those — a ball on the green beats any distance advantage elsewhere
3. **Shortest distance** decides the rest

Pick manually any time — when the cards close, the countdown cancels silently. If the cards can't be read completely, the picker stands down and leaves the choice to the players; it never guesses. Works with 2, 3, or 4 player groups. The setting is global (all profiles).

### Button Builder
The Builder window mirrors the physical panel — same layout, with each button's current secondary printed in yellow beneath it, exactly like the box. Click any button to set its secondary in one dialog (hotkey list, Smart Click list, position capture, or none). Everything auto-saves the moment you change it.

### Profiles
Each profile is a plain .ini file in the profiles folder — copy them, back them up, share them. The **Boot Profile** (tagged [BOOT]) is what loads at Windows startup, kept separate from whatever you're experimenting with, so the sim always boots into a known state.

### Start with Windows
Check the box and BA Remapper launches hidden at every boot — straight to the tray, Boot Profile loaded, mapping ON, nothing to touch. The tray balloon confirms it, and the green BA icon's tooltip shows the live state. The startup chain is self-healing: the app repairs its startup shortcut, re-enables itself if Windows' Startup-apps list has it disabled, clears the download flag that can silently block logon launches, and writes every launch to `launch_log.txt` so boot behavior is never a mystery.

---

## Files and Diagnostics

Everything lives in `Documents\BA Custom Products\Remapper\` — visible, plain files, no registry data, no hidden folders.

| File | Purpose |
|---|---|
| `settings.ini` | App-wide preferences |
| `profiles\*.ini` | One file per profile |
| `launch_log.txt` | Every app launch: time, manual vs Windows-startup, exe path |
| `ocr_last_scan.txt` | Written by the **OCR Test** button — everything the OCR currently reads, with coordinates |
| `ocr_last_miss.txt` | Written when a Smart Click can't find its target — shows exactly what the screen said |
| `scramble_last_decision.txt` | Written on every auto-pick attempt — each card's lie, shot number, and distance as parsed, and the decision or the reason it stood down |

The **OCR Test** button (main window and tray menu) scans the GSPro window on demand and opens the result in Notepad — the first stop for any "it didn't click" question.

**Cleanup / Reset** removes the auto-start entry and all data files if you ever want a factory-fresh start or a clean uninstall. Deleting the folder plus the exe removes every trace.

---

## Troubleshooting

**SmartScreen prompt on first run** — click More info → Run anyway. Once per downloaded file; the app clears the flag automatically after that.

**"Smart App Control blocked a file that may be unsafe"** — Windows 11's Smart App Control (a stricter feature than SmartScreen) blocks unsigned apps with no override. Windows Security → App & browser control → Smart App Control settings → Off. Note Windows makes this a one-way switch.

**Didn't start with Windows** — check `launch_log.txt`. No WINDOWS-STARTUP line after a reboot means Windows didn't run it: check Task Manager → Startup apps → BARemapper is Enabled (the app re-enables this itself on next manual run), and see the Smart App Control note above. A WINDOWS-STARTUP line present means it ran — check the tray for the green BA icon.

**A Smart Click missed** — press OCR Test with the menu on screen and read (or send in) `ocr_last_miss.txt` / `ocr_last_scan.txt`. Nearly every miss is wording or layout the dump reveals immediately.

**Typing goes weird in other apps** — mapping is ON and catching your keys. Ctrl+F12 toggles it off instantly.

---

## Version History

**v5.0** — Smart Clicks (Windows OCR, menu-verified clicking), Basic Secondary built-in preset, Auto-Pick Scramble with penalty-aware best-ball logic and on-screen countdown, Select Shot 1–4 hotkeys, Builder yellow secondary labels, rapid-tap fast paths, self-healing Windows startup, full diagnostics suite.

**v4.x** — Builder redesigned to mirror the physical panel, per-profile .ini storage in Documents, boot profile system, mutex-based reopen, Startup-folder auto-start, auto-save everywhere.

---

## Support

BA Custom Products — bacustomproducts@gmail.com
Include the relevant file from the Diagnostics table above and it's usually a one-reply fix.
