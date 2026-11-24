# BA Remapper 5.2.2

A fix for the Mulligan button on GSPro 4's **water** relief list.

## What was wrong

With mulligans on, pressing the box's Mulligan button on the water relief list highlighted Mulligan (choice 4) but did not press Enter, until the highlight had been moved off Mulligan or the map moved around. On out of bounds it worked.

Your log (ocr_trace.txt) showed why: on water, every miss read "3 choices: LATERAL DROP, FLAG LINE, REHIT". The 4th card, MULLIGAN, was not read while it was the highlighted card; with another card highlighted the same screen read all four. The highlighted card's white number on its blue circle is read as part of its line, which starts that line to the left of the other titles, and 5.2.1 set such a line aside as not belonging to the list. With Mulligan missing it did the safe thing: Ctrl+M only. On out of bounds Mulligan is card 2 of two, where the same shift was tolerated.

## What 5.2.2 does

- A choice whose line starts with its number circle is placed in the list's column correctly, so the highlighted card always counts, whichever it is.
- A title one card-spacing below the last card counts as the next choice even if its detail line was not read.
- A choice's title is taken from the capital words at the start of its line, so GSPro's callout or a map label beside the list can't hide it, and the list's own column is used when they sit next to it.
- If the list is seen without Mulligan, it reads again (up to three reads, 0.35 s apart) while GSPro finishes moving the map.
- When Mulligan is already highlighted (GSPro does that on Ctrl+M), it presses **Enter** only, the TAKE MULLIGAN step; otherwise Mulligan's number first, then Enter.
- Ctrl+M is also watched when GSPro is open behind another program; GSPro is brought to the front before anything is pressed.
- With mulligans off, or with no relief list on screen, nothing changes: Ctrl+M only, never Enter on its own.
- ocr_trace.txt now records the lines it read whenever Mulligan is not found.

## How this was checked

- The case from your log, as line-by-line reads: the highlighted Mulligan card's line starting with its number - read as choice 4 (5.2.1 dropped it), also with its detail line missing; a map label under the list is not taken as a choice.
- Windows CI on test screens built from your real water screenshot with GSPro's Mulligan callout beside the list (including its last line on Mulligan's title row) and a map label under the panel: four choices every time; the Mulligan button gives Enter (Mulligan highlighted) or "4, Enter".
- All earlier checks (your real screenshots, FN and held-B delivery, cheat sheet, scramble, startup, installer) still pass.
- Not tested by the AI: the bay itself. Please try it on the same water hole.

5.2.1 brought the one-press Mulligan button and the FN cheat sheet that follows the relief list; 5.2.0 brought custom layouts and the FN cheat sheet with Size and Place. All of it is unchanged.

## Update/install

Exit the running app from its tray menu. Download and extract **BARemapper_Setup_v5.2.2.zip**, then run Setup over the installed version. Profiles, settings and the cheat sheet's size and spot are kept. On a PC where BayLauncher opens the Remapper, untick "Start BA Remapper with Windows" in Setup. The portable alternative is **BARemapper_v5.2.2_portable.zip**. **SHA256SUMS.txt** lists download checksums.

[Illustrated guide](https://github.com/DiyGolfGuy/BA-Remapper/blob/main/docs/scramble-preview.md) · [Full how-to](https://github.com/DiyGolfGuy/BA-Remapper/blob/main/HOW_TO_USE.txt)

---

Built and released with [Claude Code](https://claude.com/claude-code) for BA Custom Products.
