# BA Remapper: AI handoff and development conversation

Updated **2026-10-27**. Read alongside [AGENTS.md](AGENTS.md), the current source, [README.md](README.md), and [RELEASE_NOTES.md](RELEASE_NOTES.md). This is a dated decision record, not a verbatim chat transcript.

## State at this handoff

- Public release: [v5.1.0](https://github.com/DiyGolfGuy/BA-Remapper/releases/tag/v5.1.0), published as a full release, not a draft/prerelease.
- Released source: `0352465ded92bbd71ab20e919c982233cf3ed424`.
- Working baseline before these changes: v5.0.9, `a5f762113cc2645a385277b4e4941453c8527b63`.
- UI/hotkey work: [PR #1](https://github.com/DiyGolfGuy/BA-Remapper/pull/1), merged as `eb8f46a74ec882a15ee9dbec30069a4f5ad5c7e8`.
- Packaging commits: `241fec86963a993b77ebbc080b5b7903488d3d34` and `0352465ded92bbd71ab20e919c982233cf3ed424`.
- No additional application change is pending from this conversation. The latest request is to preserve context and keep future development conversational.
- Re-check current branch/release state before future work; later documentation commits do not change the v5.1.0 release tag.

## What changed and why

| Area | Implementation | Reason |
|---|---|---|
| Status | Separate Button Mapping and Scramble Auto-Pick status | Auto-Pick is independent; mapping OFF must not imply both are off. |
| Profiles | Separate current and Windows Startup Profile wording; Customize a Copy retains all actions and FN; New Blank remains blank | Make experimentation easy without changing the preset or startup choice. |
| Preset/Builder | Basic Secondary is visibly read only; editing controls disabled; Restore label; physical box layout and yellow labels retained | Match the printed hardware and explain how to customize safely. |
| Action editor | Exactly one of GSPro Hotkey, Smart Click OCR, Taught Screen Click, or None; only relevant controls enabled; combination preview; Save/Cancel; parent windows disabled during editing | Make the result clear and prevent saving to the wrong profile after a context change. |
| FN button in editor | Explains the modifier's role instead of offering a self-secondary | That secondary cannot be triggered. |
| Window usability | Scroll/resize support and recovery of windows left on a disconnected display | Keep controls reachable on smaller screens and changed desktop layouts. |
| Help | Quick Start and updated Help/README | Explain the normal tap/FN workflow and startup choices. |
| OCR reset | Reset Smart Click Spots clears saved spots and temporary repeat/scan/verification state | An incorrect click must be re-read and learned again immediately, rather than reused from a transient cache. |
| Factory reset | Separate explicit operation; backup enabled by default outside the folder being reset; abort on backup failure | Preserve the everyday reset's narrow meaning while keeping full reset available. |
| Secondary keyboard input | Ignore repeated FN-down events while FN is already held; focus GSPro and use SendEvent with a 60 ms key duration | Preserve the fact that FN was used and give the game time to register the secondary key. |

The exclusive radio-mode logic and the factory-reset confirmation were corrected during Windows validation. A native radio grouping issue allowed two action types to appear selected; `SelectConfigType` now sets each explicitly. The legacy MsgBox option expression was replaced with numeric options so the destructive confirmation actually has Yes/No and defaults to No.

### Camera Clip / Clear View details

Bruce's reported case was **hold Reset Aim (A), press Club Down (K), expect B**. GSPro calls B **Camera Clip**; the box uses **Clear View**.

- Basic Secondary already assigned B to both club buttons in v5.0.9; that mapping remains.
- `HandleBoxKeyDown` now ignores FN auto-repeat without resetting `FnUsedAsModifier`. Otherwise an extra A could be sent when FN was released after using a secondary.
- `SendSecondaryKey` finds the existing GSPro game window, activates it and waits up to 0.6 seconds, then uses `SetKeyDelay, 15, 60` with explicit `SendEvent`. It restores the previous timing afterward.
- If GSPro cannot be found/activated, the secondary is not sent to an unrelated application.
- Primary key forwarding and scramble key output retain their prior send mode.
- The repeat-state bug is established; input timing/focus changes address plausible game-delivery problems. Do not claim the exact cause on Bruce's simulator was conclusively reproduced.

### Reset semantics

Reset Smart Click Spots refuses while OCR is busy or FN is held. It stops the pending OCR/verification/parking timers and clears saved spots, window binding, pending action, last scan, last click/repeat state, and verification state before saving the cleared spots.

It keeps profiles, preferences, startup selection, and Taught Screen Click coordinates. Factory Reset remains a separate operation that backs up profiles/preferences when selected, clears configuration/startup, and exits; diagnostic logs and the installed program remain.

### Multiple screens and cursor parking

The owner requires **1–4 displays**, correct clicks on the GSPro display, and the mouse moved out of the way afterward. The original coordinate and parking logic was preserved, not rewritten.

- `GsproWinRect` selects the largest qualifying GSPro game window, excluding the configuration window. `ClientRectByTitle` converts client coordinates to desktop coordinates.
- `ScanScreen` enumerates all Windows monitors, including negative desktop origins. The logic is not hardcoded to screen 1 or capped at two monitors.
- Taught clicks use the physical desktop position captured by the user. Moving GSPro or rearranging displays can require teaching those positions again.
- `ParkMouse` moves to the top-left of the **last scanned GSPro client area**. In fullscreen, that is the game screen's top-left corner. If no GSPro scan position is known, it falls back to desktop **(0, 0)**.
- The pointer is moved, not made invisible. Taught clicks call parking after the click completes. Smart Clicks generally park about **1.2 seconds after a burst** so rapid repeats stay fast; the timer can defer while OCR is busy.
- The fast repeat path can reuse the previous point for up to four seconds before resolving the window again. This existing behavior was retained.
- A separate source comparison confirmed `ParkMouse`, `ParkTick`, DPI cursor/click functions, window-coordinate helpers, `ScanScreen`, `MonitorOf`, and `RunOcrAction` were unchanged from v5.0.9. This was not a physical four-monitor test.

## Verification evidence

Passed on actual Windows GitHub Actions at the released source:

- [Verification run 40541379656](https://github.com/DiyGolfGuy/BA-Remapper/actions/runs/40541379656).
- [Build, upgrade verification and release run 40541379757](https://github.com/DiyGolfGuy/BA-Remapper/actions/runs/40541379757).

Coverage included:

- Exact comparison of 25 preserved core functions plus diagnostic, hotkey-binding, scramble-timer, and exit sections against v5.0.9.
- Production-source parsing with official AutoHotkey v1.1.37.02 Unicode 64-bit.
- Isolated UI/profile tests: independent status, copy retains actions/FN and preserves preset/startup, locked preset controls, exclusive action types, preview, Save/Cancel persistence, FN editor guard.
- OCR reset clears saved/transient caches while preserving profiles/preferences; small-window scrolling and offscreen recovery.
- Hidden startup profile/mapping behavior; factory-reset cancel, actual backup/reset, and exit.
- A separate Windows key-event receiver titled as a GSPro regression target: A held with I/K, repeated FN-down, and Swap Club Up/Down both ways produced four B taps held approximately 60 ms, with no A/I/K leakage. Arrow and Ctrl+M delivery also passed.
- Portable compilation and executable branding/version checks.
- Actual installer upgrade from v5.0.9: seeded profile/preferences hashes unchanged; installed executable matches the new binary; uninstaller exists.
- Public installer and portable ZIP downloads, ZIP integrity, and SHA-256 checksums.

**Limits:** no live GSPro game session, physical control-box test, or physical 1–4-monitor test was performed by the AI. Do not label those as passed. Bruce said the app was all set, but no detailed live test report was captured.

Runtime tests use a temporary app/data copy with startup repair and migration disabled. Do not run destructive test flows against a user's real Documents configuration.

## Release and website update path

The release contains `BARemapper_Setup_v5.1.0.zip`, `BARemapper_v5.1.0_portable.zip`, and `SHA256SUMS.txt`. The original green BA icon was extracted from the previous executable and preserved.

The BA website updater reads public GitHub releases and selects the versioned installer ZIP named `BARemapper_Setup_v<version>.zip`; it excludes drafts and prereleases. Public v5.1.0 meets that contract. The website Update button was not clicked by the AI.

`scripts/package-release.ps1` builds, validates, tests upgrade, and packages. The release workflow uploads all assets to a draft before publishing it and refuses to replace an already public release. Ordinary app/docs commits do not publish a new version; the workflow is triggered by changes to its listed release files. Keep release metadata and installer naming aligned when preparing a future release.

## Development conversation and decisions

The entries below summarize the actual back-and-forth on **2026-10-27**.

1. **Owner:** The app works great; review UI/UX. Implement the suggestions except item 6, which was for building/debugging.
   **Response/change:** Improved status, profile copying/locking, action editing, window usability, startup wording, and help. Kept existing diagnostic tools.
   **Why:** Improve everyday use while preserving working game logic.

2. **Owner:** Cleanup/reset is for when OCR clicks the wrong spot and needs to learn again.
   **Response/change:** Added Reset Smart Click Spots with saved and transient cache clearing; separated Factory Reset with backup.
   **Why:** A routine correction must not erase profiles or keep reusing the bad cached point.

3. **Owner:** Screen clicks work, but FN plus another button assigned to a keyboard hotkey does not; A + K should send B / Cam Clip.
   **Response/change:** Fixed held-FN repeat state and secondary key delivery; verified actual Windows key events and preserved OCR paths.
   **Remaining confirmation:** Live GSPro behavior on the owner's simulator was not tested by the AI.

4. **Owner:** Verify before making the version publicly available so the BA website Update button can pick it up.
   **Response/change:** Ran Windows checks and real installer upgrade verification, then published v5.1.0 with matching installer ZIP and checksums.
   **Why:** An Actions preview or source commit alone is not an update the website consumes.

5. **Owner:** Show screenshots and explain why the UI is easier and how the Action Editor works.
   **Response/change:** Captured actual Windows test UI and explained the four action modes, preview, Save/Cancel, and Customize a Copy.
   **Context:** The editor screenshot demonstrates a custom Aim Left → B assignment, not the factory mapping. Basic Secondary still uses either club button for B. Inline pictures did not display on the owner's Android app; direct saved-image links were provided.

6. **Owner:** Confirm 1–4-screen handling and top-left mouse parking are still intact.
   **Response/check:** Compared the relevant functions to v5.0.9; unchanged. Explained GSPro-relative coordinates, taught-position limitations, delayed parking between rapid repeats, and the (0, 0) fallback.
   **Why:** Preserve working simulator behavior and describe the actual implementation accurately.

7. **Owner:** Leave a note for the next AI explaining what was done and why; keep building through back-and-forth chat in this repo.
   **Response/change:** Added this handoff and root AGENTS.md so future AIs can find the decisions and collaboration expectations.
   **Validation:** Documentation links/content reviewed; application and release files unchanged. Continue this dated log after meaningful future work.

## Continuing the conversation

Begin with the owner's new request and this recorded context. Explain the next step, discuss genuine product choices with Bruce, and keep him informed while completing authorized work. Preserve what already works. Update this file with the new request, response, rationale, evidence, and open questions so the next AI can continue without guessing.
