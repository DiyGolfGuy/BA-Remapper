BA Remapper 5.1.2 — draft release notes, unreleased development.

This version is being built with the owner while more features are considered. It has not been published. Public downloads and the BA website update remain at v5.1.1.

### Changes prepared

- **See the scramble choice.** A green click-through frame follows the vote-leading card. The panel shows card number, parsed distance/lie/shot, selection reason and countdown without taking focus or covering USE with a clickable control. The existing countdown setting controls the visuals.

- **Feet-only readings stay feet.** A reading such as `100'` retains 100 feet instead of being split into 10 feet. Recovery of the known Windows OCR form `291 71'` for 29 feet 7 inches is preserved.
- **Consistent green-distance validation.** Letter-recovery paths now use the same validation as numeric readings. The existing 199-foot OCR guard is retained.
- **Scramble card recovery.** When the normal GSPro window read misses the cards, the watcher retries a smaller central strip of that same client area. Monitor position and Windows scaling remain in physical desktop coordinates.
- **Stronger regression coverage.** Three/four-card scenes now have to select correctly. Feet-only, curly/prime marks, negative desktop origins, no-card and one-card scenes have explicit cases. The existing fewest-strokes, green preference, and distance ordering remain.
- **Controlled publication.** The staged release workflow builds without publishing by default. Public publication requires an explicit manual run and the exact version. Upgrade fixtures refuse an existing configuration and require a disposable Windows runner.

### Validation status

The new highlight has passed local source checks; its Windows preview/focus/click-through/OCR checks and rebuilt packages are pending. The older successful run below predates this feature.

Local preserved-core checks, the production trailing-tick regex cases, Python syntax, workflow YAML parsing, publication defaults, and version consistency have passed.

[Windows verification run 40598471990](https://github.com/DiyGolfGuy/BA-Remapper/actions/runs/40598471990) passed: production parsing; all 38 distance cases; actual Windows OCR two/three/four-card selection and non-trigger cases; the existing UI, hotkey, reset, startup and profile checks; Unicode 64-bit compilation; and an actual upgrade preserving settings/profiles. Both candidate ZIPs were downloaded and their checksums and architecture/version inspected.

See [DEVELOPMENT.md](DEVELOPMENT.md) and the latest entry in [AI_HANDOFF.md](AI_HANDOFF.md) for evidence. The work remains in a draft PR and is not published as a release. A live GSPro session and physical control-box/multi-monitor acceptance are still unverified.

### Candidate build assets (Actions only)

- `BARemapper_Setup_v5.1.2.zip`
- `BARemapper_v5.1.2_portable.zip`
- `SHA256SUMS.txt`

These files are held as Actions artifacts, not release downloads or the website update. Keep the 64-bit Unicode build and existing profiles/settings compatibility.
