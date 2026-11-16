# BA Remapper 5.1.6

GSPro 4 shows water-hazard and out-of-bounds relief as a numbered list at the top left of the screen. You press a number to pick a choice and Enter to take it, and on Flag Line, B / F move the drop further back or closer. The control box's yellow functions only knew the older relief menu, so they did nothing on this screen. 5.1.6 makes the same buttons work on both.

## What changed

On the GSPro 4 relief list, the box buttons press GSPro's own keys:

| FN + button (yellow print) | GSPro 4 relief list | Older GSPro relief menu |
|---|---|---|
| Tee Left: OB Rehit | Rehit's number, then Enter (1 on out of bounds, 3 on water) | Clicks Rehit (unchanged) |
| Aim Right: Drop Ball / Rehit | Enter: takes the highlighted choice | Clicks Drop Ball / Rehit (unchanged) |
| Aim Left: Next Option | Highlights the next choice (1, 2, 3, back to 1) | Clicks Next Option (unchanged) |
| Aim Up: Move Forward | F: Closer, when Flag Line is picked | Clicks Move Forward (unchanged) |
| Aim Down: Move Back | B: Further Back, when Flag Line is picked | Clicks Move Back (unchanged) |

- **It reads before it presses.** A quick read of the list's corner decides which GSPro is showing. Without the list on screen, every press goes to the older menu exactly as in 5.1.5. Nothing is pressed into the game unless the list is there.
- **It reads which choice is highlighted** (the blue one), so Next Option moves on from wherever the player is, even after a mouse click.
- **Basic options only.** Preview Lie, rotating or zooming the map, and clicking a spot on the course stay with the mouse and keyboard.
- Scramble Auto-Pick, Button Mapping and the startup behaviour are unchanged.

## How this was checked

- Your three GSPro 4 screenshots (water with Lateral Drop highlighted, water with Flag Line highlighted, out of bounds with Rehit) are read with the real Windows reader on every build, as captured and shrunk to a 1920-wide window. Each must find the list, all its choices in order and the highlighted one, and plan the right keys for every box button (water: OB Rehit = 3 Enter, Next Option = 2 or 3, Flag Line Closer/Further = F/B; out of bounds: OB Rehit = 1 Enter).
- The scramble screenshots are never taken for the relief list, and the older menu's words always send a press to the older menu.
- On a test window, FN + Aim Left and FN + Tee Left were sent through the real box-key path and the window received 2, then 3, then Enter, with no Tee Left or Aim Left key leaking.
- The scramble, startup, hotkey, 64-bit build and installer checks still pass.
- Not tested by the AI: GSPro 4 itself, out of bounds with Mulligan on (planned from your photo: Rehit 1, Mulligan 2), a live round, the physical box.

## Update/install

Exit the running app from its tray menu. Download and extract **BARemapper_Setup_v5.1.6.zip**, then run Setup over the installed version. Profiles and settings are kept. On a PC where BayLauncher opens the Remapper, untick "Start BA Remapper with Windows" in Setup. The portable alternative is **BARemapper_v5.1.6_portable.zip**. **SHA256SUMS.txt** lists download checksums.

[Illustrated guide](https://github.com/DiyGolfGuy/BA-Remapper/blob/main/docs/scramble-preview.md) · [Full how-to](https://github.com/DiyGolfGuy/BA-Remapper/blob/main/HOW_TO_USE.txt)

---

Built and released with [Claude Code](https://claude.com/claude-code) for BA Custom Products.
