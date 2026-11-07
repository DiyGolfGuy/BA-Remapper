# BA Remapper 5.1.5

GSPro's latest update renamed the button on the scramble cards from **USE** to **Select**. Auto-Pick found the cards by looking for two or more "USE" buttons, so with the new GSPro it never saw them: no countdown, no green frame and no pick. 5.1.5 accepts either word, so it works with the new GSPro and with older versions.

## What changed

- **Auto-Pick sees "Select" cards.** Every place that recognized the scramble cards by the word USE (finding the cards, the card-strip safety net, the check that the cards are still up at zero, and the OCR Test) now accepts USE or Select. The match is the whole button word only: "Selected" or "Select Course" do not count.
- **Unchanged:** how the cards are read, the voting, the countdown, the pick rule (fewest strokes, then a ball on the green, then shortest), the shot key it presses, and Button Mapping.

## How this was checked

- Your real 2-, 3- and 4-player GSPro screenshots, with the button word repainted "Select" to match the new GSPro, are read with the real Windows reader on every build: every card found in the full read and in the strip, the correct pick, and the green frame on each card's edges. The original USE screenshots still pass too.
- Every drawn-card scenario (green feet/inches, around the green, yards, 2/3/4 cards, fewest strokes) now runs with both a USE and a Select button. A single Select card does not start Auto-Pick.
- Not tested by the AI: the updated GSPro itself (the "Select" screenshots are edited copies of your earlier screenshots, matched to your photo of the bay), a live round, the physical control box.

## Update/install

Exit the running app from its tray menu. Download and extract **BARemapper_Setup_v5.1.5.zip**, then run Setup over the installed version. Profiles and settings are kept. On a PC where BayLauncher opens the Remapper, untick "Start BA Remapper with Windows" in Setup. The portable alternative is **BARemapper_v5.1.5_portable.zip**. **SHA256SUMS.txt** lists download checksums.

[Illustrated guide](https://github.com/DiyGolfGuy/BA-Remapper/blob/main/docs/scramble-preview.md) · [Full how-to](https://github.com/DiyGolfGuy/BA-Remapper/blob/main/HOW_TO_USE.txt)

---

Built and released with [Claude Code](https://claude.com/claude-code) for BA Custom Products.
