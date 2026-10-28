# Unreleased BA Remapper development

Current owner instruction, 2026-10-27: upload the code to the development branch for builds/tests, keep building the next version while more ideas are gathered, and do not publish a release yet. This supersedes the earlier local-only hold.

- Development branch: `dev/v5.1.2`, uploaded for a draft PR and Windows verification.
- Candidate version: **5.1.2**, 64-bit Unicode. It can be revised as features are added.
- Public base: `DiyGolfGuy/BA-Remapper`, main at `d53eef4fd50c03fa50df028624e2486844f04c45`, public app v5.1.1.
- Public main, releases, and the website update remain unchanged; development source is uploaded only on the development branch.
- No separate private Remapper GitHub repository was visible. After the distinction was explained, Bruce explicitly said: "Upload the code its fine. Nothing about this specific thing is really secret so Upload it to do what you need." The branch and draft PR are publicly readable.

## Implemented in the source

1. The terminal-feet-mark recovery now requires two numeric groups before treating the trailing tick as an inch mark. `100'` and `111'` keep their feet meaning; `291 71'` still follows the known 29-foot 7-inch recovery path.
2. Both letter-recovery returns pass through `ScrambleFtIn`, preserving the existing validation policy consistently.
3. `ScrambleRecoverCards` keeps a full read that already sees at least two USE buttons. Otherwise it retries the central 25–75% vertical strip of the current GSPro client rectangle and accepts only two to four USE buttons. The existing OCR lock, missing-card cancellation, voting, countdown, and sending logic are retained.
4. `ScrambleCardBand` derives all coordinates from that window, including negative desktop origins; it does not assume monitor 1 or desktop (0, 0).
5. Regression coverage includes 38 distance cases, strip geometry at a negative origin, required two/three/four-card OCR selection, zero/one-card non-trigger cases, and the prior hotkey/UI/reset/startup checks.
6. App, installer and package version metadata are 5.1.2. The staged workflow defaults to building only; actual publication is manual and requires an exact version confirmation. Installer upgrade fixtures refuse an existing Documents configuration and a non-disposable runner.

## Scramble highlight added for Windows verification

Bruce approved the scramble feature and requested a highlight on the chosen card. The source now has a GSPro-relative green frame and a panel showing the vote-leading card, parsed distance/lie/shot, reason, and countdown. The existing countdown setting controls the visuals. There are no new default box mappings or Pick Now/Skip actions in this focused change. The vote/decision/deadline/send algorithms remain unchanged.

The repository and all tracked history contain no original GSPro photos. Reviewed the existing Windows OCR scene captures and the measured layout documented in the tests/source, plus GSPro's official UI guide and shortcut changelog. The frame is a visual bound around card contents derived from USE spacing/text height, not pixel-exact card-edge detection, and is never used to click. Live GSPro appearance still needs owner review.

Local preserved-source checks now cover 27 unchanged core functions, plus the watcher with explicitly visual hooks removed. Windows tests are prepared for negative-origin/scaled two/three/four-card geometry; real-OCR two/four-card previews; vote-leader changes; parsed units; capture exclusion; click-through; focus; and lifecycle cleanup. **New highlight runtime/build validation is pending at this checkpoint.** Earlier successful runs below apply to the pre-highlight candidate.

## Verification completed here

- `python tests/verify_remapper.py`: passed preserved-source checks, including 23 unchanged core functions and original sections with the documented one-line watcher addition.
- The actual trailing-tick regex extracted from the source passes eight classification cases; the v5.1.1 pattern misclassifies the five feet-only cases in that set.
- Python syntax and `git diff --check`: passed.
- Workflow YAML parsing, publication opt-in defaults and version metadata checks: passed.
- Source review confirms `ScrambleDecide`, OCR recognition/learning/clicking, monitor discovery, mouse parking, and primary/FN key routing remain unchanged.

## Windows candidate build verified

[Draft PR #3](https://github.com/DiyGolfGuy/BA-Remapper/pull/3) remains unmerged. [Windows run 40598471990](https://github.com/DiyGolfGuy/BA-Remapper/actions/runs/40598471990) passed on source `0878d3ccfb5f4dc3d00a12a92a67309658f077f0`:

- Production AutoHotkey U64 parse and the full existing UI/profile/reset/startup/key-event checks.
- All 38 distance runtime cases, including `100'` -> 1200 inches, `111'` -> 1332 inches, and consistent letter-path validation.
- Real Windows en-US OCR: all ten two/three/four-card decision scenes, plus all three HUD scenes, no-card and one-card non-triggers. Three/four-card cases are required passes, not KNOWN exceptions.
- The negative-desktop-origin card-strip geometry check.
- Official Unicode 64-bit compilation and executable metadata validation.
- Actual v5.0.9-to-v5.1.2 installer upgrade: seeded profile/preferences unchanged and installed executable exactly matches the new binary.
- Candidate installer/portable ZIP creation and SHA-256 checksums. The verification workflow has read-only repository permission and no publication step.

Downloaded candidate artifact `12776293996` (`BARemapper_candidate_packages`), checked both ZIPs and checksums, and inspected the executable: PE32+ machine `0x8664`, ProductName BA Remapper, ProductVersion 5.1.2.

- Installer ZIP SHA-256: `8b0c356b46119ff66f925c9a07b8bbbf8f57423e1639c8c04246b7d2294dc355`.
- Portable ZIP SHA-256: `fc16be1ef4c6c970580ae63ffc86fe3d5a8d2184ad090369d6e9a0a96937cfde`.

These are Actions candidate artifacts, not a public release or the website update. Those artifacts predate the new highlight. The highlight needs its own Windows verification and replacement candidate packages before it is called tested.

A live GSPro session, physical control box, and physical multi-monitor acceptance remain unverified. The Windows build was verified on GitHub's disposable runner after the owner authorized source upload; no local Windows result is claimed.

Do not run `scripts/package-release.ps1` on the simulator PC. Its installer-upgrade fixture requires a disposable GitHub Windows runner, deliberately seeds test configuration, and refuses existing configuration folders.

## Access policy

Bruce permits public viewing/downloading and authorizes development by his own account and connected AI tools. He does not want anyone else changing or publishing in his public or private repositories. The connection confirms `DiyGolfGuy` has admin permission on BA-Remapper, but does not expose the complete collaborator list or collaborator administration. No access changes were performed, and owner-only existing access has not been fully audited. Do not claim that the absence of external writers was verified.

## Product direction for the next ideas

Bruce emphasized that this is BA Custom Products LLC's companion software for its physical control boxes. Judge features by how much easier they make GSPro operation at the mat, with future Remapper enhancements for PurePlay.

Priorities to discuss/build next, not claims of implemented features:

- Trigger useful controls from the box itself, such as scramble Pick Now/Skip This Pick, and verified menu/confirm/back actions.
- Organize simulator-specific actions/profiles so future PurePlay additions can be verified separately while preserving GSPro's working controls.
- Offer optional help that mirrors the physical box and can live on a data display.
- Keep customer setup simple: understandable presets, clear FN behavior, and easy preservation/transfer of custom profiles.

The prior five-item suggestion list is not blanket authorization to ship every proposed feature. No PurePlay Remapper integration or new hardware behavior is implemented by this direction note.

## Continuing this work

Use the development branch and draft PR to continue; the earlier local-only checkpoint is historical. Read `AGENTS.md` and `AI_HANDOFF.md` before editing. Keep collecting the owner's ideas and update the dated log after meaningful work.

Uploading fixes and tests to this development branch and draft PR is authorized. Do not merge to main, create/publish a release, or synchronize the website until Bruce explicitly changes the release hold. Repository write permissions control who can modify a GitHub repository; a branch name does not control who can read it.
