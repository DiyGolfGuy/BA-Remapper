BA Remapper 5.1.0 improves setup and fixes FN keyboard hotkeys, including **hold Reset Aim (A) + Club Down (K) → B, Camera Clip / Clear View**. Both club buttons work in Basic Secondary, with Swap Club Up/Down on or off.

### What changed

- Held FN no longer forgets a secondary was used when Windows repeats the FN key, preventing an extra Reset Aim on release.
- FN hotkeys focus GSPro and use a short held keypress so the game can register them.
- Button Mapping and Scramble Auto-Pick show their own independent status.
- **Customize a Copy** starts an editable profile with all of a preset's functions intact. The original preset stays visibly read only.
- The action editor selects one action type at a time and previews the exact FN combination before Save. Cancel keeps the previous action.
- Settings windows support scrolling and resizing on smaller screens, and recover when their previous monitor is unavailable.
- Clearer Windows Startup Profile controls and a short Quick Start guide.
- **Reset Smart Click Spots** clears learned OCR positions and temporary click caches so the next press reads the screen and learns again. Profiles, preferences, startup settings and taught clicks stay.
- Full factory reset is separate and offers a backup first.

Smart Click recognition, position learning, scramble selection and the existing diagnostic tools retain their working v5.0.9 logic.

### Downloads

- **BARemapper_Setup_v5.1.0.zip** — recommended. Unzip and run the installer over the existing version. Profiles and settings are retained.
- **BARemapper_v5.1.0_portable.zip** — the same app without an installer.
- **SHA256SUMS.txt** — checksums for both downloads.

Windows automated checks cover profile copying, Save/Cancel, reset behavior, startup, scrolling, exit, and actual secondary key events. A live GSPro check on the simulator PC remains the final confirmation of game behavior.

The application is not code-signed. If Windows SmartScreen appears: More info → Run anyway.
