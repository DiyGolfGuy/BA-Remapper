# Working on BA Remapper

**Released — 2026-10-28:** Owner-approved **v5.1.3 is public** (Claude Code, PR #4, source `48db0b5da06f715d14acdc1c63b4c924ee0e7d07`, public downloads verified) and supersedes v5.1.2: card-strip retry reads 45%-92% of the game height, the chosen-card frame fits real card edges, preview windows are not owned by GSPro. Checked against Bruce's real GSPro 2/3/4-player screenshots in `tests/fixtures/gspro/` with the real Windows OCR on every build. See AI_HANDOFF.md entries 17-18 for what changed and why, and the release record. Future feature releases need another owner instruction. PIP belonged to another chat and was withdrawn.

**Real screens beat drawn cards:** geometry (where cards sit, how big the frame is, which strip to read) must be checked against the real screenshots in `tests/fixtures/gspro/`. The drawn test cards are useful for OCR/parsing/UI behavior but are not laid out like GSPro.

Read [AI_HANDOFF.md](AI_HANDOFF.md) before changing the app. It records the owner's decisions, implementation reasons, release state, and evidence from prior work. Check the current source and GitHub state when continuing; dated notes are historical context.

## Product direction

- BA Remapper is companion software for **BA Custom Products LLC's physical control boxes**. The goal is easier simulator operation from the hitting mat, with fewer trips to the keyboard or mouse.
- Prioritize useful actions customers can trigger from the box/FN layer: gameplay, camera/view controls, relief/menu operation, and scramble control. Optional on-screen help should explain the physical buttons and current profile.
- Preserve the printed white/yellow functions, familiar panel arrangement, native primary-key operation, and the working GSPro defaults.
- GSPro is the current implementation target. Prepare future Remapper enhancements for PurePlay with separate simulator-specific action definitions/profiles; verify its actual controls rather than assuming GSPro keys, OCR text, menus, or timing carry over.
- Prefer simple setup and reliable button response over adding settings or unrelated desktop-automation features. Proposed features remain ideas until their behavior and implementation are agreed; do not claim PurePlay Remapper support has been built or tested.
- The owner redirected the conversation to product ideas. Do not keep pursuing access audits/browser setup unless he reopens that task.

## Work with the owner

- Public readers may view/download; only Bruce and his authorized accounts/apps should have write or publish access. Do not invite collaborators or grant new write access. A full collaborator/admin audit has not been completed through this connection.
- Keep development a back-and-forth conversation with Bruce. Explain your understanding and the next useful step, give concise progress updates, and explain the result in plain language.
- Ask when a missing answer changes the requested behavior or scope. Continue routine work already authorized; do not repeatedly request permission for the same work.
- Surface unexpected behavior, meaningful tradeoffs, and uncertain assumptions. Do not silently redesign working features or expand an agreed change.
- After meaningful work, update the dated decision log in AI_HANDOFF.md with the request, response/change, why, validation, and remaining questions. Summarize actual exchanges; never invent dialogue or test results.
- When a prior contributor leaves an open question, answer it in the next dated entry when you have evidence or an owner decision; keep unresolved questions visible.
- Keep the handoff useful to the next AI: distinguish implemented, locally checked, Windows-tested, publicly released, and owner-confirmed behavior.

## Preserve the working product

- This is AutoHotkey **v1.1**, not v2. Keep the physical control-box layout, printed white/yellow functions, and existing profile compatibility.
- Smart Click OCR recognition, learned positions, fast repeat clicks, scramble picking, multi-monitor coordinates, and cursor parking already worked well. Keep changes focused; explain any proposed behavior change.
- Reset Smart Click Spots is the everyday reset for an incorrect OCR-learned click. Preserve profiles, preferences, startup selection, and taught coordinates. Factory Reset is separate.
- FN + Club Down/Up in Basic Secondary sends B (Camera Clip / Clear View). Preserve held-FN repeat handling and reliable secondary key delivery.
- Support the owner's 1–4-screen setup. Cursor parking currently moves the pointer; it does not make the Windows cursor invisible. See the precise behavior and fallback in the handoff.
- The owner excluded the diagnostics redesign from the UI work. Do not treat it as an unfinished authorized task.

## Verification and delivery

- Run `python tests/verify_remapper.py` for preserved-core checks when changing application code. Windows UI/input checks require the official AutoHotkey v1.1.37.02 Unicode 64-bit runtime; use the existing Windows workflow.
- Preserve meaningful regression checks. If an intentional core change requires updating a baseline assertion, explain why and verify the resulting behavior.
- For releases, also run the installer-upgrade/package checks in the release workflow. Keep version metadata, release notes, and asset names consistent.
- Packaging/installer upgrade fixtures require a disposable Windows runner. Never seed them over an existing Remapper configuration on a simulator PC.
- Ordinary main pushes build without publishing. After an explicit owner release instruction, publication can use manual dispatch with the exact confirmed version, or an exact standalone commit footer `Publish-Remapper: <version>` on main. The footer must match release-version.txt; PR/development events cannot publish. Never add that footer for an unapproved release. The shared gate and its refusal/default cases are tested in tests/verify_release_request.ps1.
- A Windows event-receiver test is not a live GSPro test. Source comparison is not a physical multi-monitor test. State what was actually verified.
- A GitHub source commit or Actions preview is not a public update. The BA website updater consumes a public release installer ZIP; see the handoff.
- Documentation-only changes do not need an app version bump or a new installer release.
