# VERBA wildlife replacement — 2026-11-08

**Bundled and imported:** `Deer.gltf`, `Stag.gltf`, `Fox.gltf`, and `Wolf.gltf`.

These are distinct skinned Quaternius animals with authored bone animation clips. Their complete geometry and animations are committed under `assets/models/cc0/wildlife/`, **not downloaded at runtime**. The models are rigged rather than convincing photoreal animals, and are intentionally modest-poly. Source and license in `assets/models/cc0/wildlife/SOURCES.md`.

`scripts/creature.gd` now loads these models first and plays native AnimationPlayer clips (idle/walk/run/eat/death). Source models `Hare_Brown.glb` and `Crow_Black.glb` remain legacy until suitable animated replacements are found.

**Acceptance requirement:** The Godot validation job must run `tests/wildlife_asset_test.gd` after import and verify four scene imports with multiple animation clips. This must not be counted as a visual quality review; the next in-editor pass should verify appearance, scale, rig movement, floor contact and camera distance.

**User workflow:** Download the entire `verba-godot` branch, open `VERBA/game/project.godot`, import and press F5. No asset installer and no separate steps.
