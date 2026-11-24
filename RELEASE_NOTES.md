# BA Remapper 5.2.1

Two improvements for GSPro 4's relief list (the numbered RELIEF OPTIONS / YOUR OPTIONS list at the top left after water or out of bounds).

## Mulligan button takes the mulligan

On that list, the box's Mulligan button used to only highlight the Mulligan choice; the player still had to press Enter (FN + Drop Ball). Now one press takes it: the box's Ctrl+M still goes to GSPro exactly as before, then the Remapper looks at the list, and only when **Mulligan is one of the choices** it presses Mulligan's number and Enter. With mulligans off, or anywhere else in GSPro, nothing more is sent, so Enter can never take a drop or a rehit by mistake. With mapping off (Ctrl+F12) Ctrl+M is not touched at all.

## The FN cheat sheet follows the relief list

Hold FN on the relief list and the cheat sheet shows what each button does on that screen, for the choice that is highlighted right now, and changes as soon as a different choice is picked (box, number key or mouse):

- The top line shows the pick, for example **RELIEF LIST: 2 FLAG LINE PICKED**.
- Drop Ball / Rehit reads **ENTER: FLAG LINE** - Enter takes (on water: previews) the highlighted choice.
- Next Option reads **NEXT: 3 REHIT** - the choice it moves to, going down the list (1, 2 or 3 choices, depending on mulligans).
- Move Forward / Move Back read **CLOSER (F)** / **FURTHER BACK (B)** only while Flag Line is picked, like GSPro's own bottom bar; the B (Clear View) buttons show FURTHER BACK there too, because that is what B does on that screen.
- OB Rehit reads **REHIT + ENTER**; the Mulligan button reads **MULLIGAN + ENTER** when Mulligan is a choice.

Away from the relief list the sheet shows the printed names as before.

5.2.0 brought custom layouts (custom keys, key sequences, custom taps, relief-list actions, test mode, layout check, profile Export / Import) and the FN cheat sheet with Size and Place; all of it is unchanged.

## How this was checked

- Your GSPro 4 screenshots (water with Lateral Drop and with Flag Line picked, out of bounds), as captured and at 1920 wide: the sheet labels for each (ENTER: LATERAL / NEXT: 2 FLAG LINE; ENTER: FLAG LINE / NEXT: 3 REHIT / CLOSER (F) / FURTHER BACK (B); ENTER: REHIT) and no Mulligan follow-up on any of them. An out-of-bounds list with Mulligan as choice 2 gives the Mulligan button "2, Enter".
- Windows CI: a real Ctrl+M through the hotkey reaches the test game window untouched and, with no relief list, nothing follows it; with mapping off or another window in front, Ctrl+M is not watched. The sheet on screen switches from the Flag Line labels to the Lateral Drop labels when the pick changes, and back to the printed names when the list closes.
- All earlier checks (FN and held-B delivery, scramble, startup, relief list, cheat sheet size and place, 64-bit build, installer) still pass.
- Not tested by the AI: a real bay, the physical box, a live round with mulligans on.

## Update/install

Exit the running app from its tray menu. Download and extract **BARemapper_Setup_v5.2.1.zip**, then run Setup over the installed version. Profiles, settings and the cheat sheet's size and spot are kept. On a PC where BayLauncher opens the Remapper, untick "Start BA Remapper with Windows" in Setup. The portable alternative is **BARemapper_v5.2.1_portable.zip**. **SHA256SUMS.txt** lists download checksums.

[Illustrated guide](https://github.com/DiyGolfGuy/BA-Remapper/blob/main/docs/scramble-preview.md) · [Full how-to](https://github.com/DiyGolfGuy/BA-Remapper/blob/main/HOW_TO_USE.txt)

---

Built and released with [Claude Code](https://claude.com/claude-code) for BA Custom Products.
