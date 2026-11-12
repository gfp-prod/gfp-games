# VERBA — Blender Asset Foundry (free production pipeline)

## Purpose

This is an **art-production workflow**, not a second game engine or a pile of
procedural Godot boxes. It produces an editable Blender scene, portable glTF
2.0 model, provenance manifest and visual proof for **one hero asset** before
the same method is extended to structures and creatures.

Pilot: **Hermit Cottage V2**, authored at the existing building's physical
scale and unchanged doorway. It is a **review-only art candidate** until
side-by-side screenshots, gameplay and performance have been approved.

Source: tools/art_foundry/forge_cottage.py. There are no paid services, API
keys, cloud inference endpoints or new third-party downloads during baking.

## Tools and ownership

- **Blender**: authored geometry, UVs, packed PBR materials, editable source,
  GLB export and four lit review camera angles.
- **Textures**: bundled Poly Haven CC0 photographs in assets/textures/real.
  Sources are documented in that directory's SOURCES_MANIFEST.json; every
  baked asset also records a SHA256 for its input materials.
- **Godot 4.5.2**: imports the packed model, checks scale and textures, and
  captures matching before/after screenshots in the *actual world scene*.
- **GitHub Actions**: automates the work on the dedicated feature branch.
  Public repository runners don't require purchasing a service, but normal
  GitHub usage policies and quotas still apply.

## Reproducible local run

Run from VERBA/game with Blender, Python 3, Pillow and Godot installed:

    python3 -m py_compile tools/art_foundry/forge_cottage.py
    mkdir -p ../foundry_build
    blender -b -t 2 --python tools/art_foundry/forge_cottage.py -- \
        --output ../foundry_build
    python3 tools/art_foundry/validate_foundry.py \
        --out ../foundry_build
    mkdir -p assets/models/foundry
    cp ../foundry_build/hermit_cottage_v2.glb \
       assets/models/foundry/hermit_cottage_v2.glb
    godot --headless --path . --editor --import --quit
    godot --rendering-method gl_compatibility --path . \
       --script res://tests/foundry_review.gd

The editable .blend and lit studio images are deliberately baked in VERBA/foundry_build, **outside** the Godot game directory, so Godot never attempts to import .blend headlessly. The last step needs a display. In Linux CI it runs under xvfb-run with a real
1280x720 OpenGL-compatible viewport.

## Generated outputs

The workflow .github/workflows/verba-blender-foundry.yml builds on source
changes on the dedicated verba/blender-asset-foundry branch. It produces:

- hermit_cottage_v2.blend — editable Blender source, packed textures,
  asset geometry, studio lights and cameras.
- hermit_cottage_v2.glb — packed glTF 2.0 model with UVs, normals,
  metric scale and grouped material-specific mesh sections.
- 01_front_entry.png, 02_riverside_side.png, 03_moss_slate_roof.png,
  04_back_and_chimney.png — Blender material-lit asset reviews.
- 01_front_old_cottage.png, 01_front_new_blender.png,
  02_west_old_cottage.png, 02_west_new_blender.png — actual Godot
  same-lens, same-lighting comparisons inside the playable scene.
- provenance.json — Blender version, source ID, textures and SHA256,
  generated model hash, license and mesh/face counts.

Outputs live in the verba-blender-cottage-studio Actions artifact. After
successful validation, the workflow commits the packed GLB and provenance to
assets/models/foundry on the **feature branch only**. The playable mainline
isn't silently modified. The editable .blend and all screenshots remain in
the downloadable Actions artifact, to keep Git history reasonably small.

## Asset contract

The cottage must remain 5–10m wide, 5–9m tall and 4.8–9m deep. The canonical
entry is local (-0.69, 2.55) in X/Z, under the existing HermitCottage parent.
The Godot wall, floor and door colliders remain authoritative; visual import
does not invent physics or change old save IDs.

The build validates UVs, normals, packed imagery, 7+ materials, meaningful
mesh topology, meter-scale extents, PNG variation, original Blender source
and the SHA256 provenance manifest. The in-world review must retain the
original cottage, and compare original/new model from the same two cameras.

## Not yet done

This pilot does not install Terrain3D, replace every villager, or declare
procedural geometry to be 'finished'. It does not automatically switch the
playable cottage facade. Following visual approval, a separate integration
can swap **only the visual facade** while preserving the existing cottage
interior, physics, books, NPC interactions and previous saves.

The system then becomes the reusable blueprint for timber-frame wall modules,
roof tiles, stone ruins, trees and eventually clothed and rigged inhabitants.
