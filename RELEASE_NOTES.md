BA Remapper 5.1.2 — draft release notes, unreleased development.

This version is being built with the owner while more features are considered. It has not been published. Public downloads and the BA website update remain at v5.1.1.

### Changes prepared

- **Feet-only readings stay feet.** A reading such as `100'` retains 100 feet instead of being split into 10 feet. Recovery of the known Windows OCR form `291 71'` for 29 feet 7 inches is preserved.
- **Consistent green-distance validation.** Letter-recovery paths now use the same validation as numeric readings. The existing 199-foot OCR guard is retained.
- **Scramble card recovery.** When the normal GSPro window read misses the cards, the watcher retries a smaller central strip of that same client area. Monitor position and Windows scaling remain in physical desktop coordinates.
- **Stronger regression coverage.** Three/four-card scenes now have to select correctly. Feet-only, curly/prime marks, negative desktop origins, no-card and one-card scenes have explicit cases. The existing fewest-strokes, green preference, and distance ordering remain.
- **Controlled publication.** The staged release workflow builds without publishing by default. Public publication requires an explicit manual run and the exact version. Upgrade fixtures refuse an existing configuration and require a disposable Windows runner.

### Validation status

Local preserved-core checks, the production trailing-tick regex cases, Python syntax, workflow YAML parsing, publication defaults, and version consistency have passed.

New Windows runtime/OCR tests, portable compilation, and installer upgrade verification are **pending for this candidate**. This workspace blocks the Windows runtime; development code is staged on a draft PR for Windows verification. Results from v5.1.1 are historical evidence, not a pass for v5.1.2.

See [DEVELOPMENT.md](DEVELOPMENT.md) and the latest entry in [AI_HANDOFF.md](AI_HANDOFF.md) before continuing or releasing. A live GSPro session and physical control-box/multi-monitor acceptance are also unverified.

### Expected assets after validation

- `BARemapper_Setup_v5.1.2.zip`
- `BARemapper_v5.1.2_portable.zip`
- `SHA256SUMS.txt`

These are intended asset names, not downloads available now. Keep the 64-bit Unicode build and existing profiles/settings compatibility.
