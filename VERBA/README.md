# VERBA — The Hollow Vale

Native Godot 4 first-person Latin-magic RPG development.

## Branch purpose
This `verba-godot` branch is the dedicated VERBA development workspace inside `gfp-games`. Existing website files on `main` are untouched.

## Current deliverable
**v1.2.1 local Godot package**: 8 authored 3D models, 18 bundled photo-derived maps, player movement, animal ecology and physics/navigation source. The local project ZIP is provided in the ChatGPT conversation. It contains the full project; **it has NOT been uploaded to this branch yet**. This repository currently tracks the integration plan and QA workflow rather than a runnable project.

The previous optional `INSTALL_VERBA_ASSETS.bat` is no longer required. The packaged project can be imported and run without downloading additional assets.

## Important requirements
- No assets may depend on running a Windows `.bat` or PowerShell installer.
- Imported meshes must have believable scale, physics collision, and Godot-compatible materials.
- Creatures must not walk through trees, cottage walls, or large rocks.
- WASD and raw mouse-look only. No drag-to-look.
- Use native first-person held-book animation, and world-space Latin effects.
- Release only after Godot engine importer and runtime acceptance tests pass.
- Differentiate original photo-derived placeholders from actual CC0 scanned PBR maps.

## GitHub migration
The complete Godot project is currently in the supplied archive, pending GitHub source/binary upload. Do not consider CI results valid until `VERBA/project.godot` and all bundled game assets are committed.
