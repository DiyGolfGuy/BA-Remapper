# Website update: BA Remapper 5.3.0

For the bacustomproducts.com session. This file has the facts and wording for the BA Remapper page and for the GitHub repository description. Use the site's own release and listing procedure to apply them. Nothing here asks for emails, payments or any other change. Written 2026-11-27 by the Claude Code session that built 5.3.0.

**Status: candidate, not released.** Do not change the page until Bruce approves the release and the release facts below are filled in from the published files.

If the 5.2.1 and 5.2.2 changes are not on the page yet, apply [WEBSITE-UPDATE-5.2.1.md](WEBSITE-UPDATE-5.2.1.md) and [WEBSITE-UPDATE-5.2.2.md](WEBSITE-UPDATE-5.2.2.md) first.

## Release facts (filled in at release, from the published files)

| | |
|---|---|
| Version | **5.3.0** |
| Released | (at release) |
| Release page | https://github.com/DiyGolfGuy/BA-Remapper/releases/tag/v5.3.0 |
| Setup | `BARemapper_Setup_v5.3.0.zip`, size and SHA-256 at release |
| Portable | `BARemapper_v5.3.0_portable.zip`, size and SHA-256 at release |
| Requirements | Unchanged: 64-bit Windows 10 or 11, GSPro, a BA Custom Products control box |

The site's updater picks `BARemapper_Setup_v<version>.zip` from public GitHub releases, so the download itself needs no hand edit.

## What's new in 5.3.0 (for the page)

Short version:

> The cheat sheet is now a picture of your control box, and it comes up by itself on GSPro 4's water / OB relief list and the scramble cards. On those screens the buttons work without holding FN.

Bullets:

- **A picture of your box.** The cheat sheet shows the V2.5 control box from above, round buttons and all, with each button's job printed in yellow under it. It is sharp at any size, on any screen.
- **It knows the screen.** When GSPro 4's water or out-of-bounds relief list comes up, or the scramble shot cards, the sheet appears by itself and says what each button does on that screen. When the screen closes, it goes away and every button is back to normal.
- **No FN needed there.** On the relief list, Aim Right takes the highlighted choice, Aim Left goes to the next one, Tee Left rehits, and Aim Up / Down move a Flag Line drop, without holding FN. FN + Club is still Clear View.
- **Pick scramble shots from the box.** The bottom row picks a card: Reset Aim card 1, Tee Left card 2, Tee Right card 3, Shot Cam card 4. GSPro shows where that ball is; press another to compare. Aim Right takes it. With Auto-Pick on, the countdown keeps running and takes the card you picked.
- **Light on the PC.** It looks at a few pixels of the GSPro picture about three times a second; Windows' own OCR reads the screen only once, when the list or the cards appear.
- Both are on by default and can be turned off on the main window.
- **Only what works on that screen.** The sheet shows just that screen's jobs: relief jobs on the relief list, CARD 1-4 and TAKE CARD on the scramble cards, Clear View (and anything you add) when FN is held during play.
- **The box always goes to GSPro.** After a click on another screen (a video, a stats page), the next box press brings GSPro back to the front first. To type in another program, turn mapping off with Ctrl+F12.
- **Builder on the box picture**, with every GSPro hotkey listed by name.
- **GSPro 4 only.** The older GSPro relief menu is no longer read; the Reset Smart Click Spots button is gone. New installs start on Basic Secondary.

## Page wording to update

**Key features.** Replace the cheat sheet bullet with:

- Cheat sheet: a picture of your control box with each button's yellow job, over the game. Hold FN to see it anytime; on GSPro 4's relief list and the scramble cards it comes up by itself. You choose its size and spot (Size and Place).

Add:

- No FN needed on GSPro 4's relief list and the scramble cards: the buttons switch to what that screen needs, and switch back when it closes.
- Scramble picking from the box: the bottom row picks a card (GSPro shows the ball), Aim Right takes it; Auto-Pick takes your pick at zero.

**Version history.** Add at the top:

- **5.3.0**: Cheat sheet with a picture of the box; it comes up by itself on the relief list and scramble cards, where the buttons work without FN. Scramble cards can be picked from the box.

**FAQ.** Add:

- *Do I still need FN?* For Clear View (FN + Club) and the other yellow jobs during play, yes. On the water / OB relief list and the scramble cards, no: the buttons do that screen's jobs by themselves.
- *Does watching the screen slow the PC down?* It checks a few pixels about three times a second while GSPro is in front, and reads the screen with Windows OCR only when the list or the cards appear. Nothing is uploaded.
- *Can I turn it off?* Yes, two checkboxes on the main window: the sheet coming up by itself, and the buttons working without FN.

## GitHub repository description

Bruce sets this on GitHub himself (Settings, About, the gear icon). Suggested text (under 350 characters):

> Free companion app for BA Custom Products golf simulator control boxes (GSPro). Cheat sheet with a picture of your box, buttons that switch by themselves on GSPro 4's relief list and scramble cards, custom layouts, Smart Clicks and scramble Auto-Pick. Windows 10/11.

## Keep the claims accurate

- **Tested by the AI:** Windows CI with the real Windows OCR on a 1920 x 1080 screen, using Bruce's real GSPro 4 relief screenshots and GSPro scramble screenshots shown on screen (water list found in 1.1 s, scramble cards in 1.6 s); the drawn sheet captured and checked; the keys each press sends recorded by a separate program; the watch measured at about 3 ms of CPU per look (under 1% of one core). Say "light on the PC", not a number, on the page.
- **Not tested by the AI:** a live round on a bay with the box, GSPro 4's real scramble screen (the scramble test screens are from before GSPro 4, with the button word edited), and the click on the player's name in GSPro. Don't claim field testing until Bruce confirms it.
- **Picture:** the sheet's box picture is drawn from Bruce's product photo; call it "a picture of your control box", not a photo.
- **Wording:** say "works without FN on the relief list and scramble cards", not "no FN button needed" in general: FN is still used for Clear View and the other jobs during play.
