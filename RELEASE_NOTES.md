# BA Remapper 5.2.0

Two things in this release: customers can build their own button layouts with many more choices, and players can see what each button does without looking it up.

## FN cheat sheet

Hold FN (Reset Aim on the standard layout) in GSPro and a picture of the control box appears at the bottom left of the game. Every button is where it sits on the box, the FN button is yellow, and each button's yellow function for the current profile is printed under it, like the yellow print on the box. On GSPro 4's relief list it shows what the buttons do there (Next choice, Closer, Further Back...). It disappears when FN is released, never takes clicks or focus, and stays out of screen captures and streams. A custom layout shows its own functions. **Show FN cheat sheet** on the main window turns it on or off.

**Size and Place...** on the main window shows the sheet over GSPro, the way it will look when FN is held, with a green outline. Slide the size (20% to 80% of the GSPro screen width) and it changes live; drag the sheet anywhere on the GSPro screen; **Lock it in** saves the size and spot for good (kept through updates). **Back to bottom left** returns it to the starting corner, and **Cancel** keeps what was locked in before.

## Your own layout

Choose **Customize a Copy**, open the **Button Builder** and click a button:

- **Tap alone** (white print): keep the box print, choose a key from the list, or **Custom key or combo...** (click the box and press the key; Ctrl / Alt / Shift combos work). A `*` on the Builder button marks a custom tap. Basic Secondary stays locked to the box print.
- **Hold FN** (yellow print):
  - **GSPro Hotkey:** the list (now with E, M, X, minus, equals, F2–F12, Home, End, Page Up/Down, Insert, Delete) or **Custom key or combo...**
  - **Smart Click:** the relief-menu actions as before, plus new **GSPro 4 relief-list** actions: Choice 1 / 2 / 3 + Enter, Lateral Drop / Flag Line / Mulligan + Enter (it finds the choice's number on screen), Rotate Left / Right (Q / E), Zoom In / Out, Recenter.
  - **Key Sequence:** up to 4 keys in a row with a set pause (100–800 ms), for example "2 then Enter".
  - Taught Screen Click or None, as before.
- **Test mode:** tick it in the Builder and press the box buttons. The Builder shows what each one does, and nothing is sent to GSPro.
- **Layout check:** the Builder's bottom line flags anything worth a look, such as a screen click with no position or two buttons that tap the same key. Click it for the full list.
- **Export / Import Profile:** a `.baprofile` file to copy a layout to another bay or share it with a customer. Imported profiles are checked: a profile can only press keys (no Win-key combos, clicks or typed text), and anything else is turned off and listed. Screen-click spots from another PC are flagged to re-check.

Also: typing a profile name or a custom key in the app's own boxes now gets the plain box keys instead of remapping them.

Unchanged: Basic Secondary, the GSPro 4 relief list and older relief menu Smart Clicks, scramble Auto-Pick, startup behaviour.

## How this was checked

- Windows CI sends real key presses through the box-key path to a test window: the key sequence (4 then F2) and a custom tap (X) arrive in order, the buttons' own printed keys never leak, and the GSPro 4 relief keys still arrive as before.
- The cheat sheet is shown over a GSPro-titled window while FN is held: it sits at the bottom left, draws grey buttons, the yellow FN button and the yellow print, is the chosen size, is click-through and never takes focus, hides when FN is released, and stays off when switched off. FN + Club Down still sends a real held B (Clear View) to the game with the sheet showing, and the game keeps focus.
- Size and Place: the sheet is shown over the game and takes the mouse; the size slider resizes it live; a real mouse drag moves it; nothing is saved until Lock it in, which saves the size and spot; holding FN afterwards shows it at exactly that size and spot; Cancel keeps the locked values; holding FN while placing leaves the sheet being placed alone. A saved top-right spot shows it top right.
- Builder test mode reports FN + Club Up = Clear View, the custom tap and FN tapped alone, and sends nothing. Typing in the app's own text box gets the plain keys.
- Export and import keep every kind of function; a hostile profile file (Win-key combo, a click, an unknown action, typed text, the preset's name) is renamed and every unsafe entry is turned off and listed.
- Your GSPro 4 screenshots plan the right keys for every new relief action, and Recenter is found on each screenshot as captured and at 1920 wide.
- All earlier checks (scramble, startup, relief list, 64-bit build, installer) still pass.
- Not tested by the AI: a real bay, the physical box, a live round, how the cheat sheet looks on a projector.

## Update/install

Exit the running app from its tray menu. Download and extract **BARemapper_Setup_v5.2.0.zip**, then run Setup over the installed version. Profiles and settings are kept. On a PC where BayLauncher opens the Remapper, untick "Start BA Remapper with Windows" in Setup. The portable alternative is **BARemapper_v5.2.0_portable.zip**. **SHA256SUMS.txt** lists download checksums.

[Illustrated guide](https://github.com/DiyGolfGuy/BA-Remapper/blob/main/docs/scramble-preview.md) · [Full how-to](https://github.com/DiyGolfGuy/BA-Remapper/blob/main/HOW_TO_USE.txt)

---

Built and released with [Claude Code](https://claude.com/claude-code) for BA Custom Products.
