# BA Remapper release and development record

Current owner instruction, 2026-10-27: **publish v5.1.2 publicly** so Bruce can import it with his website Update button. The earlier hold is superseded for this version only. The owner withdrew the unrelated PIP request; it belongs to another chat.

- Version: **5.1.2**, AutoHotkey v1.1 Unicode x64.
- PR #3 on dev/v5.1.2 is being prepared for release, including a full offline how-to, installer Start menu shortcut, updated Quick Start/Help and illustrated scramble guide.
- Prior final development source 540274186e45e44c0194ad33d183dc23df2cdc9c passed Windows run 40615333461: all 127 preview assertions, 38 parser cases, existing UI/key tests, x64 compilation, and installer upgrade preservation. Its downloaded packages passed checksum/ZIP integrity and x64/version checks.
- This release preparation changes documentation/help and package contents; the runtime selection/click/key algorithms remain unchanged. Its final Windows/package checks and public publication are pending here.
- The website source was inspected read-only: scripts/sync-releases.js imports non-draft/non-prerelease public GitHub releases, and software-sources.json selects ^BARemapper_Setup_v.*\.zip$. Preserve that exact versioned installer asset and SHA256SUMS.txt.
- The connector can merge but does not expose manual workflow dispatch or release upload. Publication therefore adds a tested explicit commit-footer path alongside the existing manual path. An owner-approved main commit must contain exactly one standalone Publish-Remapper: 5.1.2 footer; mismatched versions and non-main refs are refused. Ordinary commits still build only.
- Do not run the website Update action or send customer emails as part of this release task: Bruce said he will update the website. Publishing the public release makes it importable.

Earlier candidate build details below are historical evidence; consult the latest handoff entry and PR check status for the release build.

## Implemented in the source

1. The terminal-feet-mark recovery now requires two numeric groups before treating the trailing tick as an inch mark. `100'` and `111'` keep their feet meaning; `291 71'` still follows the known 29-foot 7-inch recovery path.
2. Both letter-recovery returns pass through `ScrambleFtIn`, preserving the existing validation policy consistently.
3. `ScrambleRecoverCards` keeps a full read that already sees at least two USE buttons. Otherwise it retries the central 25–75% vertical strip of the current GSPro client rectangle and accepts only two to four USE buttons. The existing OCR lock, missing-card cancellation, voting, countdown, and sending logic are retained.
4. `ScrambleCardBand` derives all coordinates from that window, including negative desktop origins; it does not assume monitor 1 or desktop (0, 0).
5. Regression coverage includes 38 distance cases, strip geometry at a negative origin, required two/three/four-card OCR selection, zero/one-card non-trigger cases, and the prior hotkey/UI/reset/startup checks.
6. App, installer and package version metadata are 5.1.2. Ordinary workflow pushes build only; approved publication requires an exact version through manual confirmation or the guarded commit footer. Installer upgrade fixtures refuse an existing Documents configuration and a non-disposable runner.

## Scramble highlight implemented and Windows verified

Bruce approved the scramble feature and requested a highlight on the chosen card. The source now has a GSPro-relative green frame and a panel showing the vote-leading card, parsed distance/lie/shot, reason, and countdown. The existing countdown setting controls the visuals. There are no new default box mappings or Pick Now/Skip actions in this focused change. The vote/decision/deadline/send algorithms remain unchanged.

The repository and all tracked history contain no original GSPro photos. Reviewed the existing Windows OCR scene captures and the measured layout documented in the tests/source, plus GSPro's official UI guide and shortcut changelog. The frame is a visual bound around card contents derived from USE spacing/text height, not pixel-exact card-edge detection, and is never used to click. Live GSPro appearance still needs owner review.

Local preserved-source checks now cover 27 unchanged core functions, plus the watcher with explicitly visual hooks removed. Windows tests are prepared for negative-origin/scaled two/three/four-card geometry; real-OCR two/four-card previews; vote-leader changes; parsed units; capture exclusion; click-through; focus; and lifecycle cleanup. **Highlight verification passed:** [run 40614795112](https://github.com/DiyGolfGuy/BA-Remapper/actions/runs/40614795112) on application source `5a5d90d5684a2fcaf28c3abb13211597ee5d7cc7`. All 83 preview assertions passed, including actual Windows OCR with the two/four-card overlay visible, real clicks through the USE button and frame, focus retention, capture exclusion/fallback, vote changes and lifecycle cleanup. Existing parser/UI/hotkey checks, x64 compilation, installer upgrade preservation and packaging passed too. Follow-up changes add docs/screenshots and strengthen test assertions; the application source is unchanged. [View the screenshots and detailed behavior](docs/scramble-preview.md). Earlier runs below apply to the pre-highlight candidate.

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

These are Actions candidate artifacts, not a public release or the website update. Those artifacts predate the new highlight. The replacement highlight candidate passed [run 40614795112](https://github.com/DiyGolfGuy/BA-Remapper/actions/runs/40614795112); packages are artifact `12785190462`, and verification/screenshots are artifact `12783888357`.

Both new ZIPs were downloaded and passed integrity/SHA-256 checks. The portable executable is PE32+ x64 and contains version 5.1.2.

- Highlight installer ZIP SHA-256: `9764a52e01f25f11d37737370151f8959d450cccd8263141d8db074455b67f43`.
- Highlight portable ZIP SHA-256: `f1ae086f83e36a61f41372381b000e348bf4ce2854a5c9205b7d14f124cdec0e`.

These remain candidate Actions artifacts, not a public update.

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

The owner has now authorized merging and publishing v5.1.2 after verification. Further feature development still needs its own release instruction. Bruce will use his website Update button after publication. Repository write permissions control who can modify a GitHub repository; a branch name does not control who can read it.
