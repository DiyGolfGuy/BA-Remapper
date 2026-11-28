# BA Remapper 5.3.0

The cheat sheet is now a picture of your control box, it comes up by itself on GSPro 4's relief list and the scramble cards, and on those screens the buttons work without holding FN.

## What's new

- **A picture of your box.** The cheat sheet shows the V2.5 control box from above, round buttons and all, with each button's job printed in yellow under it. It is drawn by Windows' own graphics engine, sharp at any size, resolution, Windows scale or number of screens. Size and Place works as before.
- **It knows the screen.** When GSPro 4's water or out-of-bounds relief list comes up, or the scramble shot cards, the sheet appears by itself and says what each button does on that screen. When the screen closes it goes away and every button is back to normal.
- **No FN needed on the relief list.** Aim Right takes the highlighted choice (press it again to confirm a Lateral Drop or Flag Line drop), Aim Left goes to the next choice, Tee Left rehits, Aim Up / Down move a Flag Line drop closer / further back. FN still works there, and FN + Club is still Clear View everywhere.
- **Scramble cards from the box.** The bottom row picks a card: Reset Aim (a quick tap) card 1, Tee Left card 2, Tee Right card 3, Shot Cam card 4. Remapper frames it and clicks the player's name, so GSPro shows where that ball is; press another to compare. Aim Right takes the picked card. With Auto-Pick on, the countdown keeps running and takes the card you picked at zero. The sheet shows CARD 1-4 along the bottom row and TAKE CARD on Aim Right.
- **Light on the PC.** While the GSPro picture is on screen, Remapper looks at a few pixels of it about three times a second (no screen reading). Windows OCR reads the screen once, when the list or the cards appear. Nothing is uploaded.
- **GSPro 4 only, Basic Secondary first.** The older GSPro relief menu's reading and the Reset Smart Click Spots button are gone (everyone is on GSPro 4). A new install starts on Basic Secondary; a PC still on the empty "Default" profile from an older version moves to Basic Secondary once (any other profile is kept as it is).
- **Only what works on that screen.** The sheet shows just the jobs for the screen that is up: relief jobs on the relief list, CARD 1-4 and TAKE CARD on the scramble cards, and Clear View (plus anything you add) when you hold FN during play.
- **The box always goes to GSPro.** Clicked a video or a stats page on another screen? The next box press brings GSPro back to the front first, then presses. The relief list and scramble cards work the same: the sheet still comes up by itself and the first press does that screen's job. To type in another program, turn mapping off with Ctrl+F12.
- **Builder on the box picture.** Click a round button on the picture to set its jobs. Every GSPro hotkey is in the list with its name.
- **Two new settings** on the main window, both on: *Show it by itself on the relief list (water / OB) and scramble cards* and *On those screens the buttons work without FN*.

## How this was checked

- Windows CI: the drawn sheet captured from the screen and checked; the labels for every screen; the keys each press sends, recorded by a separate program; the pixel looks on your real relief and scramble screenshots at full size and 1920 wide.
- The whole screen watch on a 1920 x 1080 test screen, with your water screenshot and a 2-player scramble screenshot shown in a window named like GSPro: the water list was spotted and confirmed in 1.1 s and the sheet came up with the Flag Line labels; Aim Right without FN took the choice; the list was read again after Enter; the scramble cards were found in 1.6 s (Auto-Pick off) with CARD 1 / CARD 2 / TAKE CARD; closing either screen put everything back to normal.
- The watch's cost, measured on the test PC: about 3 ms of CPU per look, under 1% of one core.
- All earlier checks (your real screenshots, FN and held-B delivery, Mulligan, scramble Auto-Pick, startup, installer upgrade) still pass.
- Not tested by the AI: your bay, the box itself, a live round, and GSPro 4's real scramble screen (the scramble test screens are from before GSPro 4, with the button word changed to Select). Please try the water hole, an OB, and a scramble.
