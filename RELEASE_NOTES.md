# BA Remapper 5.2.2

A fix for the Mulligan button on GSPro 4's **water** relief list.

## What was wrong

With mulligans on, pressing the box's Mulligan button on the water relief list highlighted Mulligan (choice 4) but did not press Enter - until the map had been moved around. On out of bounds it worked.

The most likely cause: after Ctrl+M, GSPro flies the map to your last spot and shows its MULLIGAN callout and the map's choice labels there - which can be right beside the relief list. The Remapper reads that corner of the screen, and text beside the list could end up on the same line as a choice's title; the title was then not recognised, Mulligan looked absent, and nothing more was pressed (the safe outcome). Moving the map moved that text away. The Windows tests could not reproduce the miss itself, so 5.2.2 hardens every step of that path and logs what it reads.

## What 5.2.2 does

- A choice's title is taken from the capital words at the start of its line, so text beside the list no longer hides it, and the list's own column is used when a callout or label sits next to it.
- If the list is seen without Mulligan, it reads again (up to three reads, 0.35 s apart) while GSPro finishes moving the map.
- When Mulligan is already highlighted (GSPro does that on Ctrl+M), it presses **Enter** only - the TAKE MULLIGAN step; otherwise Mulligan's number first, then Enter.
- Ctrl+M is also watched when GSPro is open behind another program; GSPro is brought to the front before anything is pressed.
- With mulligans off, or with no relief list on screen, nothing changes: Ctrl+M only, never Enter on its own.
- The Remapper's log (ocr_trace.txt) now records what it read when Mulligan is not found.

## How this was checked

- Windows CI on test screens built from your real water screenshot with GSPro's Mulligan callout placed beside the list, including its last line on Mulligan's title row and a map label under the panel, plus line-by-line reads where that text is merged into the title line: four choices found every time, and the Mulligan button gives Enter (Mulligan highlighted) or "4, Enter".
- All earlier checks (your real screenshots, FN and held-B delivery, cheat sheet, scramble, startup, installer) still pass.
- Not tested by the AI: the bay itself. Please try it on the same water hole.

5.2.1 brought the one-press Mulligan button and the FN cheat sheet that follows the relief list; 5.2.0 brought custom layouts and the FN cheat sheet with Size and Place. All of it is unchanged.

## Update/install

Exit the running app from its tray menu. Download and extract **BARemapper_Setup_v5.2.2.zip**, then run Setup over the installed version. Profiles, settings and the cheat sheet's size and spot are kept. On a PC where BayLauncher opens the Remapper, untick "Start BA Remapper with Windows" in Setup. The portable alternative is **BARemapper_v5.2.2_portable.zip**. **SHA256SUMS.txt** lists download checksums.

[Illustrated guide](https://github.com/DiyGolfGuy/BA-Remapper/blob/main/docs/scramble-preview.md) · [Full how-to](https://github.com/DiyGolfGuy/BA-Remapper/blob/main/HOW_TO_USE.txt)

---

Built and released with [Claude Code](https://claude.com/claude-code) for BA Custom Products.
