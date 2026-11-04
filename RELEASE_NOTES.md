# BA Remapper 5.1.4

Button Mapping now turns ON every time BA Remapper opens, whatever opens it. Before, only the Windows startup shortcut turned it on. A PC where another program opens the Remapper, such as a BayLauncher game card, got the full window with mapping OFF until someone pressed Turn Mapping ON. Scramble Auto-Pick, Smart Clicks and key delivery are unchanged.

## What changed

- **Mapping ON on every launch.** Windows startup, another program, or you opening it by hand: mapping is ON when it comes up. Ctrl+F12 or the button still turns it off to type.
- **Opened by another program = same as Windows startup.** Stays in the tray, loads the Windows Startup Profile, shows the "Mapping is ACTIVE" note. Double-click the tray icon to open the window.
- **Opened by hand = window shows.** From the desktop icon, Start menu or taskbar, the window comes up as before, now with mapping ON. The installer's "Launch BA Remapper now" box opens the window too.
- **Opened again while it is running.** A program opening it again (for example the next golf game on a BayLauncher bay) turns mapping back ON and does not pop the window up over the game. Opening it again by hand still brings the window up.
- **launch_log.txt names the opener.** Each line now says `manual`, `WINDOWS-STARTUP` or `opened-by-program`, and which program opened it.

## How this was checked

- Windows CI starts the app with no argument from another program and checks: mapping ON, window hidden, startup profile loaded, the opener read from Windows. It then turns mapping off, opens the app again from a program (mapping back ON, window still hidden), and again with `/show` (window up). The how-it-decides table (explorer.exe = by hand; BayLauncher or unknown = program; `/startup` and `/show` first) is checked directly.
- The existing Windows-startup check (`/startup`: startup profile, mapping ON, hidden), UI/profile/hotkey/factory-reset checks, drawn-card and real GSPro screenshot scramble checks, 64-bit build and installer upgrade still pass.
- Not tested by the AI: a real BayLauncher bay, opening it from the real desktop/Start menu, a live GSPro round, the physical control box.

## Update/install

Exit the running app from its tray menu. Download and extract **BARemapper_Setup_v5.1.4.zip**, then run Setup over the installed version. Profiles and settings are kept. On a PC where BayLauncher opens the Remapper, untick "Start BA Remapper with Windows" in Setup. The portable alternative is **BARemapper_v5.1.4_portable.zip**. **SHA256SUMS.txt** lists download checksums.

[Illustrated guide](https://github.com/DiyGolfGuy/BA-Remapper/blob/main/docs/scramble-preview.md) · [Full how-to](https://github.com/DiyGolfGuy/BA-Remapper/blob/main/HOW_TO_USE.txt)

---

Built and released with [Claude Code](https://claude.com/claude-code) for BA Custom Products.
