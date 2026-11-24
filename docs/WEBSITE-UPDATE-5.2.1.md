# Website update: BA Remapper 5.2.1

For the bacustomproducts.com session. This file gives the facts and the wording for the BA Remapper page. Use the site's own release and listing procedure to apply it. Nothing here asks for emails, payments or any other change. Written 2026-11-23 by the Claude Code session that built the release.

## Release facts (checked against the published files)

| | |
|---|---|
| Version | **5.2.1** (latest; replaces 5.2.0) |
| Released | 2026-11-23 18:59 CT, which is 2026-11-24 00:59 UTC on GitHub |
| Release page | https://github.com/DiyGolfGuy/BA-Remapper/releases/tag/v5.2.1 |
| Setup | `BARemapper_Setup_v5.2.1.zip`, 698,907 bytes (about 683 KB) |
| Setup SHA-256 | `5255b2780b9cb75df70e54c71fe25434507e4fcdd81a3f3ddcb3adb9474f2638` |
| Portable | `BARemapper_v5.2.1_portable.zip`, 748,596 bytes (about 731 KB) |
| Portable SHA-256 | `78561d13786bd8a35e33cb26e0a7c928184ce3add37a1aafbf3e3aff9319d69c` |
| Requirements | Unchanged: 64-bit Windows 10 or 11, GSPro, a BA Custom Products control box |

The site's updater already picks `BARemapper_Setup_v<version>.zip` from public GitHub releases, so the download itself needs no hand edit.

## What's new in 5.2.1 (for the page)

Short version:

> Two improvements for GSPro 4's relief list: the box's Mulligan button now takes the mulligan in one press, and the FN cheat sheet follows the relief screen and the choice you have picked.

Bullets:

- **One-press Mulligan.** With mulligans on, GSPro 4's relief list includes Mulligan: choice 4 on water, choice 2 on out of bounds. The box's Mulligan button used to only highlight it, so players still had to press Enter. Now one press takes the mulligan. With mulligans off, or anywhere else in GSPro, the button does exactly what it always did, and Remapper never presses Enter on its own.
- **The cheat sheet follows the relief list.** Hold FN on the relief list and the cheat sheet shows what each button does for the choice that is highlighted right now, for example ENTER: FLAG LINE, NEXT: 3 REHIT, and CLOSER / FURTHER BACK on the arrows while Flag Line is picked. It changes as soon as another choice is picked.

## Page wording to update

**Key features.** Replace the two bullets below. The other bullets stay as they are.

- FN cheat sheet: hold FN in GSPro and a picture of your control box appears over the game, with each button's yellow function under it. You choose its size and spot (Size and Place). On GSPro 4's relief list it follows the screen and the choice you have picked.
- Water and out-of-bounds relief for GSPro 4's numbered relief list and the older relief menu. On GSPro 4, OB Rehit, Next Option, Drop Ball (Enter), Closer / Further Back on Flag Line, and a one-press Mulligan when mulligans are on.

**Version history.** Add at the top:

- **5.2.1**: GSPro 4 relief list. The Mulligan button takes the mulligan in one press when Mulligan is one of the choices, and the FN cheat sheet follows the list and the highlighted choice.

**FAQ.** Add these two:

- *Does the Mulligan button work on GSPro 4's water and OB screens?* Yes, from 5.2.1. When mulligans are on, GSPro lists Mulligan as a choice and one press of the Mulligan button takes it.
- *What if mulligans are turned off?* Nothing changes. Mulligan isn't on the list, Remapper sees that and sends nothing extra, so the button can never take a drop or a rehit by mistake.

If the page has a GSPro 4 compatibility answer, it can add: "Lateral Drop and Flag Line show the lie first. Press Drop Ball again to confirm the drop."

**Home page.** The software screenshot caption says "BA Remapper 5.2.0's Button Builder". The Builder did not change in 5.2.1, so the picture is still right. Make the caption version-free ("BA Remapper's Button Builder") or change it to 5.2.1.

## Keep the claims accurate

- **Tested by the AI:**
  - Windows tests on Bruce's real GSPro 4 screenshots (water and out of bounds).
  - Four-choice water screens built from those screenshots to match Bruce's projector photos.
  - A real Ctrl+M through the Mulligan hotkey.
  - The published downloads (checksums, 64-bit, version 5.2.1).
- **Not yet tested:** 5.2.1 on a bay with the box in a live round. Don't claim it was field tested until Bruce says so.
- **Wording:** say "takes the mulligan in one press" or "one-press Mulligan". Don't say it "fixes GSPro".
