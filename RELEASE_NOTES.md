# BA Remapper 5.1.3

Checked against real GSPro scramble screens. 5.1.3 fixes the card-strip safety net so it reads where GSPro actually draws the cards, fits the chosen-card highlight to the real card edges, and keeps the highlight windows from tying into GSPro's input. Picks, voting, countdown and shot-key delivery are unchanged. This remains the 64-bit Unicode Windows build.

## What changed

- **Card-strip safety net reads the right place.** When a full read of the game misses the cards, Auto-Pick reads the card strip again. On real GSPro 2-, 3- and 4-player screens the USE buttons sit at about 74–76% of the game height, and 5.1.2's strip (25%–75%) cut right through them: with the real Windows reader it found 1 of 2, 0 of 3 and 0 of 4 cards. The strip now covers 45%–92% and finds every card.
- **Highlight fits the card.** The green frame was running about 90 px above and 40 px below the chosen card on a 2100 px-tall screen. It now sits on the card's edges, measured from real GSPro screens.
- **Highlight windows stand on their own.** They are no longer "owned" by the GSPro window. When one program's window is owned by another program's, Windows ties the two programs' keyboard/mouse handling together, so a busy game could hold up the remapper. They stay on top, click-through and out of the way, and still hide whenever GSPro is not the active window.

## How this was checked

- Real GSPro 2-, 3- and 4-player scramble screenshots (player names replaced) are read with the real Windows reader on every build. Every card is found in the full read and in the strip alone, the pick is correct (the shorter fairway ball; the only 1st-shot ball; the shortest of four) and the highlight frame lands on each card's real edges.
- The existing drawn-card checks (green feet/inches, around the green, yards, 2/3/4 cards, preview focus/click-through/capture exclusion), hotkey checks, 64-bit build and installer upgrade still pass.
- Not tested by the AI: a live GSPro round, the physical control box, a physical multi-monitor setup.

## Update/install

Exit the running app from its tray menu. Download and extract **BARemapper_Setup_v5.1.3.zip**, then run Setup over the installed version. Profiles and settings are kept. The portable alternative is **BARemapper_v5.1.3_portable.zip**. **SHA256SUMS.txt** lists download checksums.

[Illustrated guide](https://github.com/DiyGolfGuy/BA-Remapper/blob/main/docs/scramble-preview.md) · [Full how-to](https://github.com/DiyGolfGuy/BA-Remapper/blob/main/HOW_TO_USE.txt)

---

Built and released with [Claude Code](https://claude.com/claude-code) for BA Custom Products.
