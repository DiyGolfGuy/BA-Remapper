# BA Remapper 5.1.2

See which scramble card Auto-Pick plans to use, with a green highlight and a readable countdown/explanation beneath the cards. Existing printed control-box functions, Smart Clicks, profiles, ranking and shot-key delivery are preserved. This remains the 64-bit Unicode Windows build.

## What changed

- **Scramble card highlight:** follows the same vote-leading choice the picker uses. Shows card number, parsed distance, lie, shot number, selection reason and time remaining. Clicks pass through and GSPro keeps focus.
- **Feet stay feet:** `100'` keeps its 100-foot value. Curved/prime feet and inch marks and the existing close-up OCR recovery are preserved. Letter recovery applies consistent validation.
- **Two, three or four cards:** when a full game-window read misses the cards, the picker retries the central card strip on that same display.
- **How-to included:** the installer adds **BA Remapper How To** to the Start menu. Both installer and portable downloads include **HOW_TO_USE.txt**. Quick Start and Help explain the highlight, controls, units and manual choice.

## How to use the scramble preview

1. Install/update Remapper and open it.
2. Check **Auto-Pick Scramble Shot (all profiles)**. Choose a delay; **15 seconds** is a useful starting point.
3. Check **Show chosen card highlight and countdown**, then return to GSPro and keep it active.
4. When the cards appear, the green outline shows the planned pick. You can still click any GSPro **USE** button before the automatic choice.

The rules stay **fewest strokes → GREEN among those → shortest distance**. Other lies are not ranked for strategy. `14′ 7″` means 14 feet 7 inches; FRINGE is not GREEN. Reading Cards means no readable preview; Checking at zero means it is confirming/re-reading. Turn off the highlight to hide visuals; turn off Auto-Pick itself to stop automatic choices. Button Mapping and Auto-Pick remain independent.

[Illustrated guide and screenshots](https://github.com/DiyGolfGuy/BA-Remapper/blob/main/docs/scramble-preview.md) · [Full how-to](https://github.com/DiyGolfGuy/BA-Remapper/blob/main/HOW_TO_USE.txt)

## Update/install

Exit the running app from its tray menu. Download and extract **BARemapper_Setup_v5.1.2.zip**, then run Setup over the installed version. Profiles and settings are kept. The portable alternative is **BARemapper_v5.1.2_portable.zip**. **SHA256SUMS.txt** lists download checksums.

## Verification

Windows verification covers 127 preview assertions, actual Windows OCR on drawn two/three/four-card scenes, 38 distance cases, focus/click-through/capture-exclusion and cleanup, FN/Camera Clip key events, existing UI/profile/reset/startup checks, official Unicode x64 compilation and an actual installer upgrade preserving settings/profiles. The release build also checks the bundled guide and explicit publication controls. Screenshots are real Windows captures over test cards; a live GSPro round, physical control box and physical multi-monitor acceptance were not performed by the AI.
