# BA Remapper: AI handoff and development conversation

Updated **2026-10-27**. Read alongside [AGENTS.md](AGENTS.md), the current source, [README.md](README.md), and [RELEASE_NOTES.md](RELEASE_NOTES.md). This is a dated decision record, not a verbatim chat transcript.

## State at this handoff

- **Current owner direction, 2026-10-27:** publish v5.1.2 so the BA website Update button can import it. This supersedes the earlier hold for this version. Prepare the complete how-to, verify and publish; future features are not automatically approved for release.
- **Scope correction:** PIP was for another chat; Bruce explicitly withdrew it. This is the Remapper scramble-highlight/control-box release.
- **Previously verified:** development head 540274186e45e44c0194ad33d183dc23df2cdc9c passed Windows run 40615333461 with 127 preview assertions, 38 distance cases, existing UI/hotkeys, x64 build and upgrade preservation; downloaded package integrity/checksums were verified.
- **In progress:** public how-to and offline guide packaging, updated in-app Help/Quick Start, explicit version-specific publication gate and final release verification. Read entry 16, DEVELOPMENT.md and current GitHub state before calling the release published.
- Main was d53eef4fd50c03fa50df028624e2486844f04c45 and latest public release v5.1.1 at the start of this release request. Verify the final release assets after publication.
- Earlier entries below are historical conversations and superseded holds. Product direction remains physical BA Custom Products LLC control boxes, GSPro now and separately verified future PurePlay enhancements. The owner redirected away from access audits; do not resume them unprompted.

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

8. **Owner (2026-10-27, to Claude Code):** Check the repo notes; then: "Find out which is better. 64 or 32 ... for forward progress. Verify as best you can that the reading on the green, around the green, and feet and yards still work. I have not tested it yet so if we need a new version that's fine."
   **Finding:** v5.1.0 changed the release build from 32-bit ANSI (every release through v5.0.9, built with the ANSI 32-bit base) to Unicode 64-bit. Decision: keep 64-bit Unicode. Reasons: Windows 11 is 64-bit only; Unicode keeps OCR text exact (ANSI converted it to cp1252); AutoHotkey v2 is Unicode-only; the CI here is built on U64. Requirement: the code must be clean for it, so it was audited.
   **Audit:** every DllCall/NumGet/NumPut checked; handles and pointers are pointer-sized throughout (OCR library uses A_PtrSize; PICTDESC layout correct for 64-bit). The one difference: `Chr(145)`-`Chr(148)` in the distance parser are cp1252 curly quotes only in the ANSI build. In U64, OCR curly marks are real Unicode, so `141 7` + curly inch mark (14' 7" with ' misread as 1) parsed as 141 ft and could flip a green pick (reproduced in U64, D3 in the local test).
   **Changes (v5.1.1):** `ScrambleNormQuotes` maps curly/prime quote marks before `ScrambleParseDistance` and `FeetInches`. `FeetInches`: a lone trailing `'` with no inch mark is the inch mark; every result goes through `ScrambleFtIn` (a trailing 1 past 11 inches is dropped; inches above 11 or feet above 199 return -1 = unreadable). The `291 71'` case (29' 7" with " read as `1'`) came from the real Windows OCR in CI and parsed as 29171 ft in every earlier version, 32- or 64-bit. Installer: `${RunningX64}` check with a plain message (silent installs abort with exit code 2). Workflows: generic release title; verify timeout 20 min.
   **Tests:** `verify_remapper.py` no longer requires `FeetInches` to equal v5.0.9 (intentional change; it now asserts the quote normalization and that every result goes through `ScrambleFtIn`). New Windows `ScrambleSmoke` mode in the real U64 runtime: 23 distance-parse cases, then (when PowerShell finds a Windows OCR engine; windows-latest has en-US) drawn GSPro-style scramble cards read through the production `ScanWinClient` → `ScrambleDecide` with three reads and voting. Results go to check-run annotations because Actions logs/artifacts are on blob storage this cloud session cannot reach. Locally (wine): 99 + 42 earlier harness checks and 40 new green/fringe/yards checks pass identically in ANSI 32-bit and Unicode 64-bit; the close-up image pipeline on Bruce's photo crops produces bit-identical images in both.
   **Windows OCR results:** green 28' 0" vs 29' 7" (full read skipped both distances, as at the sim; close-up read recovered them; `291 71'` → 29' 7"), 14' 7" vs 9' 11" (`141 7"` → 14' 7"), lone 8 yd fringe vs 13 yd rough, green 9' 2" beating fringe 3 yd (`91 2"` → 9' 2"), 2nd-shot 179 yd beating 3rd-shot 363 yd: all picked correctly.
   **Open question (not changed, owner's call):** with 3 or 4 cards side by side, a whole-window read returned none of the card text (0 lines; with HUD text, only the HUD), while reads of just the card strip, or the window in halves/thirds/quarters, found every card. Two cards read fine. Test scene only, not confirmed on live GSPro. If real, 3-4 player scrambles never arm. A fix would be an extra read of the card strip when the full read sees fewer than 2 USE buttons, at the cost of one more (smaller) OCR read per 2 s watcher tick. Recorded as KNOWN in the Windows test so a change shows up.
   **Not verified:** live GSPro session, physical box, physical multi-monitor.

9. **Owner (2026-10-27, to Codex):** Review the other AI's work; keep the 64-bit build and make sure feet, yards, green status, and the feet mark are understood.
   **Review/check:** Read PR #2 and the updated source/handoff. Kept the 64-bit Unicode decision. Re-ran local preserved-core checks (23 functions plus original sections passed) and inspected the actual Windows verification/release logs for runs [40576044679](https://github.com/DiyGolfGuy/BA-Remapper/actions/runs/40576044679) and [40575729850](https://github.com/DiyGolfGuy/BA-Remapper/actions/runs/40575729850). The release and verification jobs succeeded; real Windows OCR was available as en-US.
   **Unit contract:** `'`, `’`, and `′` denote feet; `"`, `”`, and `″` denote inches. For example, `14' 7"` means 14 feet 7 inches (175 inches), not 147 yards or 141 feet. An unmarked distance is feet on a GREEN card and yards off the green; explicit feet/inch punctuation is recognized off the green too. Distances are normalized to inches (one yard = 36 inches). Proximity and units do not establish GREEN: the lie row does. A fringe ball remains off-green even if its distance has feet marks.
   **Decision contract:** Fewest strokes first; among those, prefer GREEN; among remaining eligible balls, shortest distance. The real-OCR test deliberately picked green `9' 2"` over fringe 3 yards even though the green ball is two inches farther away. Green `28' 0"` beat `29' 7"`; curly/prime mark cases, close-up recovery of `291 71'`, and 8-yard fringe vs 13-yard rough passed.
   **New source-level finding (not yet changed or separately executed in Windows):** The new lone-trailing-apostrophe heuristic treats a feet-only string such as `100'` as `100"` internally; the compact-digit branch then splits it as 10 feet 0 inches. The added test covers `28'`, but not three-digit feet-only strings. A missing inches field should not silently change the distance by a factor of ten. Discuss a focused correction/re-read rule before altering the public app.
   **Additional source-level limitation:** The 199-foot guard is a software validation policy, not a unit conversion. The two letter-recovery branches in `ScrambleParseDistance` return inches directly rather than through `ScrambleFtIn`, so they do not consistently enforce that guard. No new runtime result is claimed for these review findings.
   **Existing open question:** Confirmed the Windows logs mark three-/four-card whole-window recognition as KNOWN, not passed; cropped strip/tiled reads find the cards in that synthetic scene. This remains unverified on live GSPro and unchanged in production.
   **Delivery:** Review/handoff update only. No application, installer, version, or release change; no live GSPro/physical hardware test.

10. **Owner (2026-10-27):** Fix the issues found, fully prepare the next version, but do not push public changes or release yet; more features/ideas are coming. Asked whether there was a private or developer branch and who could develop there.
    **Response/placement:** Explained that an unpublished branch in a public GitHub repo remains publicly readable; only write-authorized accounts/apps can modify that repository. No separate private Remapper repo was found. Owner selected "Keep private here". Created local branch `dev/v5.1.2-private`; no GitHub writes, branches, PRs, release, or website sync for this work.
    **Changes:** Candidate metadata is 5.1.2 (64-bit Unicode). A lone trailing feet mark is reinterpreted as an inch mark only after two numeric groups, preserving `100'`/`111'` while retaining `291 71'` recovery. Both letter-based green-distance branches now use the existing `ScrambleFtIn` guard. Added `ScrambleRecoverCards` and a GSPro-relative central card-strip retry when the full read sees fewer than two USE buttons. The strip retains negative desktop coordinates; accept only 2–4 USE buttons. Existing decision/voting/countdown/cancel/send logic is retained, with one recovery call added to the watcher.
    **Regression coverage prepared:** 38 distance cases, negative-origin strip geometry, required two/three/four-card OCR selection with/without HUD, fewest-strokes-over-green precedence, and no/one-card non-trigger cases. The former three/four-card KNOWN exceptions now fail the suite instead of silently passing.
    **Release preparation:** Updated draft notes and app/installer/package versions. The staged workflow builds without publishing by default; public publication now requires manual dispatch, the publish input, main, and an exact version match. Packaging upgrade fixtures require a disposable Windows runner and refuse an existing configuration folder so they cannot overwrite a simulator PC's settings.
    **Local evidence:** Preserved-core checks passed. Comparing every declared function to v5.1.1 found 140 unchanged existing functions, only `FeetInches`/`ScrambleParseDistance` modified, and two new recovery helpers. Testing the actual production regex reproduced five wrong feet-only classifications in v5.1.1; the candidate passes all eight classification cases. Python syntax, workflow YAML parsing/publication defaults, version consistency, and whitespace checks passed.
    **Explicit limit:** A direct attempt to start official AutoHotkey U64 through Wine failed before parsing with `wineserver: socket: Operation not permitted`. No new Windows runtime/OCR or compiled-binary pass is claimed. No installer/portable binary was produced here. Run those prepared checks on a permitted disposable Windows runner before calling the candidate release-ready; do not publish it just to obtain a test run.
    **Checkpoint:** Save the local committed branch, source tree, Git bundle/history, base-relative patch, and validation status as one private development package. Continue the back-and-forth here and update these notes as the owner adds ideas.

11. **Owner (2026-10-27, after the local checkpoint):** "Upload the code its fine. Nothing about this specific thing is really secret so Upload it to do what you need."
    **Response/authorization:** Upload v5.1.2 development source to `dev/v5.1.2` and open a draft PR so actual GitHub Windows runtime/OCR/compile/installer checks can run. This overrides the prior local-only restriction, not the release hold. Do not merge, publish, or synchronize the website.
    **Workflow preparation:** The PR verification workflow runs the complete package script on a disposable Windows runner and retains candidate installer/portable ZIPs plus test evidence as Actions artifacts. It contains no publication step. Final Windows outcomes will be added after the run.

12. **Owner (2026-10-27):** Public viewing/downloading is fine; only the owner and his authorized AI tools should change/publish in any of his public or private repositories.
    **Access findings:** GitHub confirms `DiyGolfGuy` has admin permission on BA-Remapper. Public read access does not grant write access; invited collaborators/authorized apps are a separate access setting. This connection rejects the collaborator-list endpoint and provides no collaborator-administration tools. No access changes were made and a complete existing-writer audit has not been performed; do not claim otherwise. A browser fallback needs the user's approval under the available browser tool rules.
    **Build completed:** [Draft PR #3](https://github.com/DiyGolfGuy/BA-Remapper/pull/3), head `0878d3ccfb5f4dc3d00a12a92a67309658f077f0`, passed [run 40598471990](https://github.com/DiyGolfGuy/BA-Remapper/actions/runs/40598471990). Actual Windows U64 parsing and all 38 distance cases passed. Real Windows OCR selected correctly in ten card scenarios, including three/four players and `100'` vs `99'`, all three HUD scenes, no/one-card non-triggers, and the fewest-strokes-over-green case. The existing UI/profile/reset/startup/key-event checks passed; four B taps arrived with no A/I/K leakage. Negative-origin strip geometry passed.
    **Installer/build evidence:** Official Unicode 64-bit compilation/version checks, actual v5.0.9 upgrade preserving profiles/preferences and installing the exact new binary, package generation and checksums all passed. Downloaded artifact `12776293996` and verified ZIP integrity/checksums, x64 PE machine `0x8664`/PE32+, ProductName BA Remapper, ProductVersion 5.1.2. Installer ZIP hash `8b0c356b46119ff66f925c9a07b8bbbf8f57423e1639c8c04246b7d2294dc355`; portable ZIP hash `fc16be1ef4c6c970580ae63ffc86fe3d5a8d2184ad090369d6e9a0a96937cfde`.
    **Held:** These are candidate Actions artifacts only. No merge, tag, release publication, or website sync. Continue collecting features and keep the PR in draft. Physical GSPro/control-box/multi-monitor acceptance remains unverified. This follow-up changes only documentation; app source is the source already tested above.

13. **Owner (2026-10-27):** In response to the request to inspect GitHub access settings through the browser: "Yes do what you want in git."
    **Authorization:** The owner has approved the GitHub access-settings/browser fallback and wants write/publication access limited to his own account and authorized AI tools across his public/private repositories. Do not ask for this same approval again. Preserve the earlier release hold; this approval is not an instruction to merge or publish v5.1.2.
    **Current blocker:** The environment/browser became unavailable in this session and the browser tools were removed. Available GitHub tools still cannot list/administer collaborators. Permission has been granted, but the complete writer audit and access-setting changes have NOT been performed. Do not claim owner-only access has been verified or enforced. Continue the authorized audit when browser/admin tooling is available.
    **Development confirmation:** The follow-up documentation head `239fed58723ae365c610601f4caf9751f9e1eb05` also passed Windows [run 40599046241](https://github.com/DiyGolfGuy/BA-Remapper/actions/runs/40599046241). PR #3 is still draft/unmerged and public release remains v5.1.1. This entry changes only the handoff; the tested app is unchanged.

14. **Owner (2026-10-27):** Redirected the conversation from the access concern to new product ideas, then emphasized: "Remember what I am ba custom products llc and my control boxes. So what ever makes it easier to run gspro and pureplay in the future."
    **Product direction:** BA Remapper is the companion for BA Custom Products LLC's physical control boxes. The practical goal is operating the simulator from the mat with fewer trips to keyboard/mouse. Put useful box/FN actions, dependable game controls, simple customer setup, and optional physical-panel help ahead of generic remapping/editor features.
    **Future PurePlay work:** Keep simulator action definitions/profiles distinct so future Remapper enhancements can be verified against PurePlay's actual controls. Do not assume GSPro hotkeys, menus, OCR recognition, or timing apply there. This is a design direction, not a claim that a PurePlay Remapper integration has been implemented/tested.
    **Ideas, not shipped features:** Candidate next features include scramble preview with Pick Now/Skip This Pick triggered from the box, optional FN help on a data display, and simpler profile preservation/transfer. Discuss exact behavior as we build; the earlier suggestion list was not an approval to implement every item.
    **Scope/hold:** Return to product development; do not keep initiating permission audits/browser setup unless the owner reopens that task. Updated AGENTS.md and DEVELOPMENT.md so future AIs retain the business/hardware focus. Documentation only; no app behavior, version, main branch, release or website update changed.

15. **Owner (2026-10-27):** "Yes lets do the scramble thing have it highlighted what card it decided to chose. Use the pictures the repo should have and gspro to really figure out how to do that in the right way and meaningful way."
    **Implementation:** Added a bright green frame and a panel with the vote-leading card number, normalized distance units, lie, shot, reason, and remaining countdown. The existing countdown preference controls both. The preview follows the same highest-card-count vote/tie-breaker as the actual pick, uses current detected USE geometry on the same GSPro client, and hides for unreadable/partial/stale geometry, focus loss, window movement/resize, missing cards, cooldown, disabled settings, and reset. It does not change physical printed mappings, add Pick Now/Skip bindings, or change voting/ranking/deadline/key delivery.
    **UI/OCR safeguards:** Border-only, layered transparent/no-activate owned windows keep the USE buttons usable and GSPro focused. Display-affinity capture exclusion is checked; if unavailable, the existing OCR lock hides visuals and flushes composition before scanning. Font/frame sizes follow physical game pixels. Negative desktop origins are retained. The outline bounds card contents from measured GSPro proportions and neighboring USE centers; it is not an exact visual card-edge detector and never drives a click.
    **References:** No original GSPro photos were found in any tracked repository history. Inspected the prior Windows test scene screenshots from artifact 12776009510 and the recorded field layout ratios in the source/tests. Read the official GSPro UI guide (https://gspro.gitbook.io/gspro-knowledge-base/in-game-information/in-game-user-interface) and shortcut changelog (https://gsprogolf.com/change-log.html), AutoHotkey v1 Gui documentation and Microsoft SetWindowDisplayAffinity documentation. Do not present drawn-card scenes as actual live GSPro screenshots.
    **Validation at upload:** Local source checks passed: 27 core functions unchanged, and the watcher/reset/lock retain their original non-visual logic. Python syntax and whitespace checks passed. New actual Windows preview/OCR/click-through/focus/lifecycle tests and screenshots are prepared; results are pending here. Prior successful artifacts predate the highlight.
    **First Windows review:** Run 40614507511 passed all existing regression checks, geometry checks, and the two-card preview focus/click-through/capture-exclusion/OCR/vote/lifecycle checks. Its new four-card units assertion caught a cosmetic whole-yard trailing decimal; trimmed it without changing parsed distances. Inspecting the captured two-card UI also found that applying a new font reset label colors to black. Set explicit high-contrast colors on every label font update. New full verification is required after these corrections.
    **Completed Windows validation:** [Run 40614795112](https://github.com/DiyGolfGuy/BA-Remapper/actions/runs/40614795112) passed on application source `5a5d90d5684a2fcaf28c3abb13211597ee5d7cc7`. All 83 new preview assertions passed, including two/four-card real OCR under visible overlays, original USE and border click-through, retained focus, checked capture affinity, fallback hiding during the OCR lock, vote/tie changes, partial-card protection, move/minimize/focus/pref/cooldown/miss/stale/reset cleanup, and scaled negative-origin geometry. The 38 distance cases, existing UI/profile/reset/startup/key-event checks, x64 compilation, actual upgrade preserving settings/profiles, and packaging passed. Downloaded artifact 12785190462, checked ZIP integrity/SHA-256 and PE32+ x64/version. New installer hash `9764a52e01f25f11d37737370151f8959d450cccd8263141d8db074455b67f43`; portable hash `f1ae086f83e36a61f41372381b000e348bf4ce2854a5c9205b7d14f124cdec0e`.
    **Visual review/handoff:** Inspected corrected two/four-card screenshots from verification artifact 12783888357; labels are now high-contrast, the chosen card's content is framed, and the panel sits beneath the cards. Saved unedited PNG conversions plus `docs/scramble-preview.md` to the repo so future AIs have actual UI evidence. These are drawn-card Windows fixtures, not live GSPro. Follow-up source is unchanged; test-only strengthening pins the outer card index (AHK for-loops change A_Index), exercises neighboring-card exclusion, and checks the Fewest strokes/Green preferred explanation and explicit off-green feet display. Its Windows result will be visible on the draft PR.
    **Hold:** Continue on dev/v5.1.2, PR #3 stays draft. No merge, release or website update. Record the new Windows results when completed; physical GSPro/box/multi-monitor review remains unverified.

16. **Owner (2026-10-27):** First requested a download for home testing; then explicitly changed direction: "Do the public one lets get it out there on the public one and so I can update it on my website. Make sure the pip is explained and we have a good how to. And it works." He immediately corrected that PIP was for another chat and should be ignored.
    **Authorization/scope:** The v5.1.2 hold is lifted. Finish Remapper documentation and verification, merge PR #3 and publish a complete public release. Do not add a video/PIP feature, change the website directly or send customer notices; Bruce intends to press his website Update button.
    **Preparation:** Added HOW_TO_USE.txt covering upgrade, printed box/FN controls, Smart Click learning/reset, scramble setup, panel fields/reasons/units/manual choice, screen behavior, profile editing/startup and troubleshooting. Bundle it in installer/portable and add BA Remapper How To to Start menu. Expanded Quick Start, in-app Help, README and illustrated guide; removed development-only release wording. The selection/key/click algorithms are unchanged.
    **Publication path:** The connector exposes merge but not workflow dispatch/release upload, and no local authenticated gh is available. Added a shared publication gate supporting an exact standalone Publish-Remapper: <version> main-commit footer alongside the existing manual confirmation. Ordinary pushes still only build; non-main refs, wrong/stale versions and duplicate footers are refused. Fourteen PowerShell cases run in the package script before compiling. The release merge will use the owner-authorized exact v5.1.2 footer only after PR checks pass.
    **Website contract inspected:** Read-only ba-site scripts/sync-releases.js and data/content/software-sources.json confirm non-draft/non-prerelease GitHub releases are imported and BARemapper_Setup_v*.zip is the main download. Keep v5.1.2 installer ZIP, portable ZIP and SHA256SUMS.txt public; release notes use absolute public how-to links so the website can display them. The AI will verify import eligibility/downloads but will not click Update or send emails.
    **Validation before this upload:** Preserved-source checks (27 core functions plus watcher/reset/lock behavior), Python syntax and whitespace passed. Prior head 5402741 passed final Windows run 40615333461. New Help/guide/installer/gate changes require their own Windows checks; record the result and public release evidence when done. No live GSPro or physical-box/multi-monitor acceptance is claimed.

## Continuing the conversation

Begin with the owner's new request and this recorded context. Explain the next step, discuss genuine product choices with Bruce, and keep him informed while completing authorized work. Preserve what already works. Update this file with the new request, response, rationale, evidence, and open questions so the next AI can continue without guessing.
