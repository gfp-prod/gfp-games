# VERBA — Aesthetic Pass 04: physical book and starter-valley presentation
**Date:** November 10, 2026 (America/New_York)  
**Branch:** `verba-godot`  
**Scope:** Existing first-person starter valley and held Latin grimoire. This is a reviewed *alpha art increment*, not completion of the world or aesthetic pipeline.

## Actual delivered source changes

### Physical book
- Resolved substantial separation between the glued leaf signatures, sculpted vellum and page-turn hinge.
- Replaced a flat `QuadMesh` turning sheet with a tessellated, curved double-faced parchment mesh, including edges and correct generated normals.
- Moved `Label3D` Latin ink closer to the real paper surface; added width-aware line breaking for lexicon **and** collected story volumes, preserving intact Latin sentences where they fit.
- Restored legible muted beige vellum under Godot's actual OpenGL light direction using a limited paper-surface lighting floor. Removed severe diagonal stripe shading caused by reversed normals.
- Reworked overly bright flat brass rectangles into smaller, subdued corner hardware; recessed central gutter, darkened the supporting gloves and reduced decorative rule thickness.
- Lowered/angled the camera-held book for an intentionally less screen-filling pose, while retaining passage, question and rewards as physically attached text.

### Environment and arrival
- Regraded daylight sky, ambient fill, sun energy and distance mist conservatively, preserving moonlit state and day/night transition.
- Reduced fluorescent canopy tint on imported birches, revised rust palette, and added purposeful silhouetted trees framing the spawn clearing without planting new obstruction near path.
- Reduced the count, scale and contrast of the bright cottage approach stepping stones. Existing ground atlas, physics, ecological behavior and buildings remain intact.

### QA and maintenance
- Added `tests/grimoire_geometry_test.gd` to `.github/workflows/verba-check.yml`: verifies paired curved parchment surfaces, normals, ink distance, adequate page thickness and page-turn hinge geometry.
- Added **real rendered PNG** parchment brightness and Latin ink-contrast checks to `tests/visual_pixel_gate.py` after the imported animal checks. These test actual Godot screenshots, not concept art.
- Fixed an intermediate wrapping regression discovered by `book_world_loop_test.gd`, then reran all checks.

## Verified evidence

At the final source revision `c6eb7e0483d831f87bba64a07359232cf09a7c14`:
- **Godot engine/gameplay tests: PASS** — [run #42937714714](https://github.com/gfp-prod/gfp-games/actions/runs/42937714714)
- **Actual Godot OpenGL camera renders and pixel gates: PASS** — [run #42937714645](https://github.com/gfp-prod/gfp-games/actions/runs/42937714645)
- The latter includes original-screen camera angles, the cottage and priory, day/night, animal poses/GIFs, passage/quiz/reward pages and the hinged page turn. Artifact: `verba-wildlife-visual-gallery`. CI success proves production of those actual frames and the defined quantitative checks, *not final art quality*.
- Measured in the matching first-person physical-book screenshot: paper median luminance **148.5 before / 163.4 after**, the post-pass ink contrast statistic **73.1**, above the regression gate of **48**. The initial correction briefly made the paper too dark; the final build solves that captured regression.

## Remaining artistic debt — DO NOT MARK FINISHED

Real-image review still shows these weaknesses:
- Cottage is still visibly simplified/blocky; roof, exterior craftsmanship and interior require authored hero-environment work.
- Tree silhouettes and materials remain strongly associated with their free source models; the scene's foliage still reads generic in portions of the valley.
- Book page surface still reads relatively flat; next stage requires actual bent leaf deformations/ink conforming to curvature, asymmetrical hand-made detailing and better human hand meshes/poses. The current supporting fingers are still crude.
- World-ground variation and landmark atmosphere require more than light regrading; arrival meadow is still open/visually sparse from some headings.
- Imported animals are technical animating assets, not approved emotionally expressive creatures.
- Future gas station, village, castle, tower building/customization, relationships/pets and expanded open-world adventures are intentionally outside this art-only pass.

**Professional verdict:** demonstrably improved actual grimoire readability and presentation with cleaner geometry and robust regression tests. This is an incremental technical/aesthetic success; it does not meet the complete commercial-quality art bible. The next art-production bottleneck is *authored hero assets and composition*, not adding more procedural props or code volume.

## Reproduce
[Download the current GitHub branch ZIP](https://github.com/gfp-prod/gfp-games/archive/refs/heads/verba-godot.zip). Open `VERBA/game/project.godot` in Godot 4.5.2+. Run the tests with the linked CI workflows. Inspect their real PNG/GIF artifacts.
