# BA Remapper

**Control box software for GSPro — by BA Custom Products**

BA Remapper is the companion app for the BA Custom Products wireless control box. Out of the box, every button sends its printed GSPro hotkey with no software at all. BA Remapper adds the FN secondary layer (the yellow print), on-screen Smart Clicks powered by built-in Windows OCR, and an automatic scramble shot picker. Free with your box; installs like any normal Windows program (a portable version is available too).

---

## Install

**Recommended — the installer:**

1. Download the **Setup** zip from the [latest release](../../releases/latest) (or bacustomproducts.com) and unzip it.
2. Run the `BARemapper_Setup` exe inside. If Windows SmartScreen appears, click **More info → Run anyway** (the app is not yet code-signed).
3. Follow the wizard — check **"Start BA Remapper with Windows"** for a sim PC and it boots ready forever.

The installer puts BA Remapper in Program Files, adds it to the Start Menu and **Add/Remove Programs** with a proper uninstaller, and keeps your settings and profiles in `Documents\BA Custom Products\Remapper` — uninstalling asks before touching them, so a reinstall picks up right where you left off. Installing a newer version over an older one upgrades in place.

**Upgrading:** run the newer Setup right over the installed version — your profiles and settings are kept.

**Portable option:** prefer no installer? Download the portable zip from the same release instead, unzip `BARemapper.exe` to a permanent folder of your choosing, and run it — same app, you manage the location.

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
Five penalty/relief menu actions are built in: **Move Forward, Move Back, Next Option, Drop Ball / Rehit, OB Rehit**. Before any click, the app verifies the entire relief menu — the Options counter and the buttons, in order, evenly spaced, one column — and clicks the verified position inside it. It works with mulligans on or off (GSPro hides the Mulligan button when they're off). It never clicks a lone matched word, never clicks into an opening or closing animation, and if a button's own text misreads, the surrounding menu still proves where it is. Drop Ball / Rehit clicks the changing second slot whichever word it currently shows; OB Rehit handles the "You have hit OB!" dialog (with or without its Mulligan button) and the relief menu's rehit option. The app starts reading the screen the moment you press FN, and keeps retrying while a menu is still fading in, so one press is all it takes. If the menu genuinely isn't on screen, the app tells you instead of guessing.

**Locked spots — fast after the first press.** The first Smart Click on a PC reads the screen twice, checks both reads agree, and locks in where every menu button sits (saved in `settings.ini`). From then on each press reads only that button's small area and clicks right away, with no click positions to program. The spots are tied to the GSPro window size: change the resolution and they are re-learned automatically on the next press. Tray menu → **Reset Smart Click spots** forces a fresh learn.

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

The lie is not judged otherwise — rough, woods and concrete never stop a pick. If the group wants a longer ball from a better lie, they pick it themselves before the countdown ends.

Lie and shot number are read from each card's lie row only, so a player name like "Woods" or "Sandy" can never be mistaken for a lie. The row is read whether the screen reader returns it as one piece ("ROUGH 4TH") or two, and a single misread letter ("R0UGH") is tolerated. Pick manually any time — when the cards close, the countdown cancels silently. If a frame can't be read (the animated green grid on the putting green can spoil one), it re-reads the next frames; if the cards still can't be read completely, the picker stands down and leaves the choice to the players. It never guesses. Works with 2, 3, or 4 player groups. The setting is global (all profiles).

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
| `launch_log.txt` | Every app launch: time, version, manual vs Windows-startup, exe path |
| `ocr_last_scan.txt` | Written by the **OCR Test** button — everything the OCR currently reads, with coordinates |
| `ocr_last_miss.txt` | Written when a Smart Click can't find its target — shows exactly what the screen said |
| `scramble_last_decision.txt` | Written on every auto-pick attempt — each card's lie, shot number, and distance as parsed, the exact text read on each card, and the decision or the reason it stood down |
| `scramble_log.txt` | The same record for the last ~100 attempts, so an earlier miss is never lost when a later pick succeeds |
| `ocr_trace.txt` | Every Smart Click press, step by step: each screen read, where it found the button, the click — or why it held off |
| `error_log.txt` | Any internal error the app caught and recovered from, with version and location |

The **OCR Test** button (main window and tray menu) scans the GSPro window on demand and opens the result in Notepad — the first stop for any "it didn't click" question. With scramble cards on screen it also shows which card the auto-pick would choose from that exact frame (no key is sent).

**Cleanup / Reset** removes the auto-start entry and all data files if you ever want a factory-fresh start or a clean uninstall. Deleting the folder plus the exe removes every trace.

---

## Troubleshooting

**SmartScreen prompt on first run** — click More info → Run anyway. Once per downloaded file; the app clears the flag automatically after that.

**"Smart App Control blocked a file that may be unsafe"** — Windows 11's Smart App Control (a stricter feature than SmartScreen) blocks unsigned apps with no override. Windows Security → App & browser control → Smart App Control settings → Off. Note Windows makes this a one-way switch.

**Didn't start with Windows** — check `launch_log.txt`. No WINDOWS-STARTUP line after a reboot means Windows didn't run it: check Task Manager → Startup apps → BARemapper is Enabled (the app re-enables this itself on next manual run), and see the Smart App Control note above. A WINDOWS-STARTUP line present means it ran — check the tray for the green BA icon.

**A Smart Click missed** — press OCR Test with the menu on screen and send in `ocr_last_scan.txt`, plus `ocr_trace.txt` and `error_log.txt` if present. Nearly every miss is wording or layout the dump reveals immediately.

**Auto-pick didn't pick** — send `scramble_last_decision.txt` (or `scramble_log.txt` if it picked later); it shows each card exactly as read and the reason it stood down.

**Typing goes weird in other apps** — mapping is ON and catching your keys. Ctrl+F12 toggles it off instantly.

---

## Version History

**v5.0.6** — Smart Clicks are fast again: the first press on a PC verifies the menu with two reads and locks in every button's position; later presses read only that button's small area. Spots re-learn automatically when the GSPro window size changes (or via tray → Reset Smart Click spots). A sliding/zooming menu is never clicked; extra Drop Ball taps during a press are dropped; the scramble watcher pauses while FN is held. Auto-pick rule: fewest strokes → green always wins → shortest; the lie no longer stops a pick (5.0.5 stood down on CONCRETE). Green distances parse correctly when the ' mark reads as a 1.

**v5.0.5** — Fixes auto-pick standing down on screens where the text reader splits a card's lie row in two ("ROUGH" | "4TH") — the v5.0.4 lie-row change only looked at the "4TH" piece. Smart Clicks now click only when two back-to-back screen reads agree on the button's position, so a menu caught mid-animation can never send a click between Drop Ball and Move Back. A failed screen read is skipped instead of aborting the press, and two reads never run on top of each other. Fixes OCR Test failing (and the trace / miss / error logs never being created) on PCs that had not written those files before. New `scramble_log.txt`; OCR Test shows the card auto-pick would choose.

**v5.0.4** — Reliability release. Scramble picker reads lie and shot from the lie row only (player names can no longer be mistaken for a lie, so a ball on the green always wins as intended), rejects mangled distance reads, and re-reads frames spoiled by the animated green grid instead of giving up. Smart Clicks: full support for the mulligans-off relief menu and the Rehit-only OB dialog, screen read starts the moment FN is pressed, menus still fading in are waited out, scans never collide, picks the GSPro game window by size so connector apps can't confuse it, on-screen messages appear on the game screen on multi-monitor rigs. Internal errors are logged and recovered from instead of stopping a feature.

**v5.0** — Smart Clicks (Windows OCR, menu-verified clicking), Basic Secondary built-in preset, Auto-Pick Scramble with penalty-aware best-ball logic and on-screen countdown, Select Shot 1–4 hotkeys, Builder yellow secondary labels, rapid-tap fast paths, self-healing Windows startup, full diagnostics suite.

**v4.x** — Builder redesigned to mirror the physical panel, per-profile .ini storage in Documents, boot profile system, mutex-based reopen, Startup-folder auto-start, auto-save everywhere.

---

## Source and Transparency

The complete application source (`BARemapper.ahk`) and the installer script (`BARemapper_Setup.nsi`) are published in this repository — what you install is exactly what you can read. BA Remapper makes no network connections, collects nothing, and sends nothing anywhere; every file it writes lives visibly in your Documents folder. Each release lists the SHA-256 of its download so you can verify your copy (`certutil -hashfile <file> SHA256`).

---

## Support

BA Custom Products — bacustomproducts@gmail.com
Include the relevant file from the Diagnostics table above and it's usually a one-reply fix.
