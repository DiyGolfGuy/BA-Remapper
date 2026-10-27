BA Remapper 5.1.1 keeps the 64-bit build that 5.1.0 moved to and fixes two ways Auto-Pick Scramble could misread a distance on the putting green. Install it right over 5.1.0 or earlier — profiles, settings and learned Smart Click spots are kept.

### What changed

- **Green distances with curly marks.** Windows can return the feet and inch marks as curly or "prime" quote marks. The 64-bit build was reading 14' 7" (with the ' misread as 1) as 141 feet, which could make the pick choose the wrong ball on the green. Every kind of quote mark is now treated the same.
- **Inch mark read as `1'`.** Windows' own text reader, tested on a Windows PC, read 29' 7" as `291 71'` and the app took it as 29,171 feet. That happened in every earlier version, 32-bit or 64-bit, and could hand the pick to a farther ball. It now reads 29' 7". A "green distance" over 199 feet is treated as unreadable instead of being scored.
- **64-bit only.** The installer now says so plainly on a 32-bit Windows PC instead of installing a program that cannot start there. Windows 11 only comes in 64-bit.

### How this was checked

- The source was checked line by line for anything that behaves differently in the 64-bit build. Only the quote marks did.
- On a Windows PC (GitHub's Windows runner), the real Windows text reader in the 64-bit build read drawn scramble cards and picked correctly: putting green (28' 0" vs 29' 7", 14' 7" vs 9' 11"), around the green (a lone 8 yd fringe ball vs 13 yd rough, a green ball beating a closer fringe ball) and yards (a 2nd-shot fairway ball beating a 3rd-shot tee ball).
- 40 green/fringe/yards reading checks and the earlier 141 regression checks pass in both the 32-bit and 64-bit AutoHotkey.
- Not yet checked on a live GSPro screen. One thing to watch: on the test screen, with 3 or 4 cards side by side, Windows read none of the cards when it read the whole window. Two cards read fine. If a 3- or 4-player scramble does not auto-pick, press OCR Test with the cards up and send `ocr_last_scan.txt`.

### Downloads

- **BARemapper_Setup_v5.1.1.zip** — recommended. Unzip and run the installer over the existing version.
- **BARemapper_v5.1.1_portable.zip** — the same app without an installer.
- **SHA256SUMS.txt** — checksums for both downloads.

The application is not code-signed. If Windows SmartScreen appears: More info → Run anyway.

---

Built and released with [Claude Code](https://claude.com/claude-code) for BA Custom Products.
