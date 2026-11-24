# Website update: BA Remapper 5.2.2

For the bacustomproducts.com session. This file has the facts and wording for the BA Remapper page. Use the site's own release and listing procedure to apply them. Nothing here asks for emails, payments or any other change. Written 2026-11-24 by the Claude Code session that built the release.

If the 5.2.1 changes are not on the page yet, apply [WEBSITE-UPDATE-5.2.1.md](WEBSITE-UPDATE-5.2.1.md) first (feature bullets, FAQ, home page caption). This file adds 5.2.2 on top of it.

## Release facts (checked against the published files)

| | |
|---|---|
| Version | **5.2.2** (latest; replaces 5.2.1) |
| Released | 2026-11-24 13:28 CT (2026-11-24 19:28 UTC on GitHub) |
| Release page | https://github.com/DiyGolfGuy/BA-Remapper/releases/tag/v5.2.2 |
| Setup | `BARemapper_Setup_v5.2.2.zip`, 699,710 bytes (about 683 KB) |
| Setup SHA-256 | `5e03b602f26fed7b95937856d33237590e34f687e7718ec1f643d303a80c9a0c` |
| Portable | `BARemapper_v5.2.2_portable.zip`, 749,526 bytes (about 732 KB) |
| Portable SHA-256 | `a00c81687cd86768a2ed8c6d3fdfccea48c4107c8289a693bb3d7516fc60eadd` |
| Requirements | Unchanged: 64-bit Windows 10 or 11, GSPro, a BA Custom Products control box |

The site's updater picks `BARemapper_Setup_v<version>.zip` from public GitHub releases, so the download itself needs no hand edit.

## What's new in 5.2.2 (for the page)

Short version:

> Fix: the Mulligan button now takes the mulligan on GSPro 4's water relief list too, the same as on out of bounds.

Details, if the page shows more:

- With mulligans on, the water relief list has four choices, and Mulligan is number 4. In 5.2.1, the box's Mulligan button highlighted Mulligan there but did not press Enter. Out of bounds worked.
- Cause: while Mulligan was the highlighted card, the box did not count that card as part of the list. It now does, so one press takes the mulligan on water as well.
- With mulligans off, or anywhere else in GSPro, the button still does exactly what it always did. It never presses Enter on its own.

## Page wording to update

**Version history.** Add at the top:

- **5.2.2**: The Mulligan button now takes the mulligan on GSPro 4's water relief list too (the highlighted fourth choice is read correctly).

**FAQ.** The 5.2.1 answer "Does the Mulligan button work on GSPro 4's water and OB screens?" stays true. Change "from 5.2.1" to "from 5.2.2" there, because water only works from 5.2.2.

**Key features.** No change from the 5.2.1 wording.

## Keep the claims accurate

- **Tested by the AI:**
  - The exact case from Bruce's bay log, as test data: 5.2.1 dropped the highlighted Mulligan card, and 5.2.2 keeps it as choice 4.
  - Windows tests on Bruce's real GSPro 4 screenshots and on four-choice test screens built from them.
  - The published downloads: checksums match, the program is 64-bit, and the version is 5.2.2.
- **Not yet tested:** 5.2.2 on a bay in a live round. Don't claim it was field tested until Bruce confirms it on the water hole.
- **Wording:** say "the Mulligan button takes the mulligan in one press". Don't say it "fixes GSPro"; the miss was in the Remapper.
