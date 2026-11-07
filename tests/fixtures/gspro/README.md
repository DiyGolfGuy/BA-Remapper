# Real GSPro scramble screens

- `gspro-2p.jpg`, `gspro-3p.jpg`, `gspro-4p.jpg`: Bruce's own GSPro scramble shot-select screenshots (3397-3438 x 2097-2137), player names replaced. The card button reads **USE** (GSPro before its late-2026 update).
- `gspro-2p-select.jpg`, `gspro-3p-select.jpg`, `gspro-4p-select.jpg`: the same three screens with only the button word repainted **Select**, made by `tests/make_select_fixtures.py` on 2026-11-07. GSPro's update renamed the button; Bruce's projector photo of a bay that day showed the same card layout (number, name, distance, lie + shot, button) with "Select". These are edited images, not new captures; replace them with real screenshots of the updated GSPro when available.

`tests/verify_remapper.py` (RealShotSmoke) reads every file with the real Windows reader and checks the card count, the pick and the highlight frame against the card edges.
