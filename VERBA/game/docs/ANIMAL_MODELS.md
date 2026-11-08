# VERBA animal models — current (2026-11-08)

All regular animals load from `res://assets/models/cc0/wildlife/`. Old procedural animal meshes are deleted from the branch, not loaded. One supernatural wisp intentionally remains procedural.

| Animal | New file | Approximate visible height | Animated |
| --- | --- | ---: | --- |
| Doe | Deer.gltf | 1.72 m | Walk, Eating, Gallop, Idle, Death, etc |
| Stag | Stag.gltf | 1.72 m | Walk, Eating, Gallop, Idle, Death, etc |
| Wolf | Wolf.gltf | 0.88 m | Walk, Gallop, Eating, Idle, Death |
| Fox | Fox.gltf | 0.58 m | Walk, Gallop, Eating, Idle, Death |
| Hare | Hare.glb | 0.46 m | walk, idle, attack, dead |
| Crow | Crow.glb | 0.41 m | Walk, Run, Fly, Idle |

Imported model geometry is measured at spawn and uniformly resized; its bottom is grounded at the actor's feet. Physical collision capsules are defined per species, with dimensions independent of raw asset scales. The animation player receives actual movement-state commands. Do not rescale these assets manually in editor without reconsidering the species target heights.

Sources / licenses:
- Deer, Stag, Wolf, Fox: Quaternius animated animals CC0, source and checksums in `assets/models/cc0/wildlife/SOURCES.md`.
- Hare: Gobkit animal collection CC0, `assets/models/cc0/wildlife/SOURCES_EXTRA.md`.
- Crow: Polyfork crow (CC BY 4.0 for redistribution), credit **Crow by Polyfork**, https://polyfork.dev/asset/crow-base. More in SOURCES_EXTRA.md.

Verification:
- Godot CI test `tests/wildlife_asset_test.gd` opens every imported model and spawns every animal species with its actual runtime loader.
- It checks model height, walking clip selection, and numerical bone pose motion after advancing the animation.
- Passing headless tests DO NOT certify that the animals look beautiful. Visual inspection in the editor is still necessary.
