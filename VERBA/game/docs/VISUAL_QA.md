# VERBA visual-quality gate (not optional)

Source: `.github/workflows/verba-visual-qa.yml` and `tests/visual_gallery.gd`, `tests/world_gallery.gd`.

## How the pipeline works

On every wildlife/model/test code update, GitHub Actions:
1. Checks out the actual `verba-godot` project and installs Godot 4.5.2.
2. Imports all assets headlessly.
3. Launches **real OpenGL rendering under Xvfb**, not Godot's no-render headless display.
4. Renders six imported wildlife models; spawns each in-game actor for five species and records idle / walk / run states.
5. Records matching **empty-stage baseline** screenshots. `tests/visual_pixel_gate.py` rejects giant screen-filling or invisible geometry.
6. Captures ten frames of a walking cycle per animal, assembles genuine animated GIFs, and rejects apparently frozen animations.
7. Launches the complete first-person game scene and saves four camera directions at player eye height.
8. Uploads results in the `verba-wildlife-visual-gallery` GitHub Actions artifact. This is downloadable by the connected GitHub tool directly into the assistant's working container; the user does **not** need to install the game for visual inspection.

## Rules before shipping

- **Do not call a model good merely because glTF import, model height or skeletal bone rotation passes.** The prior `Hare.glb` was actually a scaled boar skin, consumed the whole camera and passed the old checks.
- Inspect actual exported PNGs and GIFs. Assess silhouette, proportions, poses, foot contact, texture quality, material parity, scale and ground placement.
- Inspect first-person world screenshots for clipping, overexposure, horizon, harsh palette discontinuities, foliage density, and intrusive HUD.
- A numeric pass catches blatant errors; aesthetic quality remains a human visual judgment. Treat that separately.
- Failed graphics/visibility inspections block the release. Keep asset replacements quarantined until inspected.

## Reusable files

- `visual-reports/<species>_<pose>.png` (5 species × 3 poses)
- `visual-reports/<species>_baseline.png` (matched empty frame)
- `visual-reports/motion_<species>_XX.png` (10 frames per species)
- `visual-reports/motion_<species>.gif` (actual Godot-rendered animation)
- `visual-reports/world_spawn_*.png` (four camera headings)

The game is **still a rough art prototype** until rendered images match the agreed retro-RPG style; passing the pipeline does not imply polished art.
