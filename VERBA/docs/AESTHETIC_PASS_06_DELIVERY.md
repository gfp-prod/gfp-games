# VERBA — Aesthetic Pass 06: Storybook Hermitage
**Local date:** 2026-11-10 | **Branch:** `verba-godot` | **Status:** Alpha hero-asset replacement, not final game aesthetics.

## Delivered into the real Godot project
- The generic cottage GLB is no longer instantiated in the world. The former cottage's collision envelope, closed doorway, world position and rotation remain stable.
- `scripts/storybook_house.gd` authors a distinct steep, irregular 3D roof, tapered lime-plaster shell, exposed timber joinery, stone footing, five-plank doorway, shutters, painted panes and an apothecary herb sill. The old imported GLB remains in the repository history/asset folder, not in the live scene.
- A small seven-sided attached study turret now changes the skyline; it has its own physical collider, dark roof, narrow window and weather vane. A crooked chimney breaks the opposite roofline.
- A single batched roof mesh creates individually offset shingles over a separate continuous dark underlay; this prevents tiny gaps from revealing bright facade geometry.
- A CC0 photographic slate texture is reused at a restrained tint because an untextured, brightly sunlit roof was blown out on actual woodland camera views.
- The world uses the same physics and persistence path; this pass does not change Latin books, inventory, creatures, saves or spells.

## Real issues found and fixed, not just aesthetic notes
1. Initial imported-house replacement worked and passed the engine tests, but had a dark/over-textured roof and a turret hidden behind the main body from the player's approach.
2. Moved the turret to the more visible right-front side; increased its pitched cap height and added a real collider.
3. Caught a roof and turret normal-direction regression with actual mesh-array assertions. Godot considers **clockwise** triangle winding front-facing; the authored triangle order and the geometry tests now agree.
4. Redid roof texture UVs so the slate no longer inherits diagonal photographic streaks across the gable.
5. Added a continuous roof underlayment after the new roof revealed bright pinholes between irregular slate edges.
6. Rebalanced sunlit tile colors after a flat albedo model became pure white from the woodland camera.
7. Added an actual-world smoke assertion that the new cottage is rendered, its turret collider exists and the old imported GLB no longer appears.

## QA protocol
- `tests/hero_art_test.gd`: roof and underlay tessellation/extent, facade gable volume, outward roof/turret normals, detailed grip geometry and living creek tree silhouette.
- `tests/smoke_test.gd`: the actual world scene includes the new cottage and its collidable annex, with the legacy prefab absent.
- GitHub Actions engine/game tests with hidden GDScript error-log guards: [latest Pass 06 suite](https://github.com/gfp-prod/gfp-games/actions/runs/42952288017).
- The game camera frame capture and pixel gates run through [latest Pass 06 visual QA](https://github.com/gfp-prod/gfp-games/actions/runs/42952287856). An Actions workflow success validates the render/test pipeline, not subjective artistic completion.

## Assessment and open art debt
This is a substantial **silhouette** improvement over Pass 05, not an approved final art direction. The property now has two distinct roof heights and asymmetrical volumes, but its wall modeling is still deliberately simple and its proportions are quite game-like. The background biome remains sparse and repetitive, the vegetation is recognizable as repeated free source meshes, hand meshes still need higher-fidelity sculpting, and the animals do not yet have the expressive stylization that the eventual game demands.

Aesthetic priorities should remain: (1) distant landform/tree-shape compositions and valleys, (2) coherent regional visual language for village, ruin and gas station, (3) expressive animal designs and NPC silhouettes. Avoid trying to solve those with another layer of randomly scattered small objects.

## Free asset strategy
Verified upstream CC0 sources were investigated: [Quaternius Medieval Village MegaKit](https://quaternius.com/packs/medievalvillagemegakit.html) and [Kenney Fantasy Town Kit](https://kenney.nl/assets/fantasy-town-kit). Existing bundled CC0 materials are reused. The larger external packs were **not** downloaded or installed during this pass. The Kenney archive's download was blocked in the runtime and should not be counted as incorporated work.

**Reproduce:** download `https://github.com/gfp-prod/gfp-games/archive/refs/heads/verba-godot.zip`, import `VERBA/game/project.godot` in Godot 4.5.2+, inspect `world_cottage_front.png` and `world_cottage_woodland.png` in the visual workflow artifact, and run the guarded tests.
