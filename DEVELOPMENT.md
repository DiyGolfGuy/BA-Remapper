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

## Verification completed here

- `python tests/verify_remapper.py`: passed preserved-source checks, including 23 unchanged core functions and original sections with the documented one-line watcher addition.
- The actual trailing-tick regex extracted from the source passes eight classification cases; the v5.1.1 pattern misclassifies the five feet-only cases in that set.
- Python syntax and `git diff --check`: passed.
- Workflow YAML parsing, publication opt-in defaults and version metadata checks: passed.
- Source review confirms `ScrambleDecide`, OCR recognition/learning/clicking, monitor discovery, mouse parking, and primary/FN key routing remain unchanged.

## Pending before a release-ready binary

The AutoHotkey U64 runtime cannot start in this workspace: Wine's server reports `socket: Operation not permitted`. This prevented a fresh production AHK parse, runtime tests, and compilation. Do not treat the local source checks as Windows execution.

The owner has authorized public development-source staging. Run the draft PR workflow on its disposable Windows runner. It must pass:

- Production-source AutoHotkey parsing and the full isolated runtime/OCR suite, including the formerly KNOWN three/four-card scenes.
- Portable compilation with the official Unicode 64-bit base and executable metadata validation.
- Actual installer upgrade/profile preservation and package/checksum generation.
- Review of the central-strip fallback on live GSPro; the existing fields were tested synthetically in v5.1.1, not on the simulator here.

Do not run `scripts/package-release.ps1` on the simulator PC. Its installer-upgrade fixture is intended for a disposable GitHub Windows runner; it deliberately seeds test configuration and runs actual installers. The new guard refuses other environments and existing configuration folders.

## Continuing this work

Use the development branch and draft PR to continue; the earlier local-only checkpoint is historical. Read `AGENTS.md` and `AI_HANDOFF.md` before editing. Keep collecting the owner's ideas and update the dated log after meaningful work.

Uploading fixes and tests to this development branch and draft PR is authorized. Do not merge to main, create/publish a release, or synchronize the website until Bruce explicitly changes the release hold. Repository write permissions control who can modify a GitHub repository; a branch name does not control who can read it.
