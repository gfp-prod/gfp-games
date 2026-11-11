# VERBA — Aesthetic Pass 07: solid cottage walls and inhabited hermitage

**Local date:** November 10, 2026 · **Branch:** `verba-godot` · **Status:** Gameplay tests passing; visual QA produced from actual Godot scene.

## Root cause: apparently transparent cottage walls
The Pass 06 replacement building used `SurfaceTool` to create a thin single-mesh exterior plaster facade. Its material kept the Godot default back-face culling. From the player's approach angle, several polygons were invisible despite the physics-only wall colliders remaining solid. This visually exposed the terrain and background right through the cottage.

This was **not** an alpha/transparency effect. The wall mesh was being backface-culled. The roof and turret had normals regression tests but the facade did not.

### Fix in production code
- `scripts/storybook_house.gd`: `make_opaque_plaster()` creates a clearly opaque wall material with `CULL_DISABLED` and `TRANSPARENCY_DISABLED`, so the intentionally thin shell is visible from both outside and inside. The same actual wall mesh and collision geometry remain in place; prior save positions and doorway dimensions have not been moved.
- `tests/hero_art_test.gd`: asserts double-sided, truly opaque plaster and presence of all four wall panels.
- `tests/smoke_test.gd`: checks the material on the **instantiated actual game cottage**, not only the factory function.
- `tests/world_gallery.gd`: captures front, woodland flank, rear, and interior views of the cottage.

The first fixed real-engine screenshot visibly restored continuous plaster behind the door and window. The rear and interior frames also show solid walls.

## Continue: do more than cure the missing polygons
The newly added interior photo uncovered a second weakness: the old cottage's `StoneCottageFloor` was **collision-only**. Grass and pebbles were visible underfoot inside an apparently solid building.

- `scripts/cottage_interior.gd` authors a batched 14-board wooden floor placed at the existing physics floor height, one renderer mesh instead of many planks.
- It places a collidable writing desk with field notes/inkwell, a shelf with environmental book props, and a small stool. Their collision boxes are separate from the visual props. The center of the room stays navigable.
- `storybook_house.gd` installs the interior into the live cottage; `hero_art_test.gd` asserts the rendered floor covers the cottage footprint, and `smoke_test.gd` checks the live scene contains a visible floor and a physical desk.
- `world_gallery.gd` adds `cottage_interior_study`, a camera aimed at the new furnishing arrangement.

## Ground-clearance follow-up after inspecting the actual furnished interior
The new cottage study rendered, but revealed grass blades and terrain breaking through the boards near the bookshelf. More furniture was **not** the fix. The world terrain was never flattened under the built footprint, and decorative grass was still distributed there.

- `world.gd` now distinguishes `_raw_height_at()` from `height_at()`, flattening only the oriented cottage footprint to its original center elevation. A short smooth transition retains the surrounding terrain. Outside the cottage plot the height function is identical to its old result.
- `world.gd` adds authoritative cottage-local coordinates and a deterministic vegetation-exclusion function. `foliage.gd` and `ground_dressing.gd` relocate otherwise obstructing static grass/litter/pebbles outside the structure. Living grass patches use the same object IDs and are relocated rather than changing object count.
- `cottage_interior.gd` includes a continuous dark subfloor beneath the wood planks. It blocks green terrain color from showing as narrow stripes through the board seams, without changing the original floor collider.
- `tests/cottage_footprint_test.gd` samples the level interior, the turret area, the unchanged outer valley, and vegetation relocation. The test runs in the real Godot game.
- The `world_cottage_interior_study.png` screenshot is retained specifically to catch this regression visually.

## Final visual inspection and regression closeout

The floorboard underlay removed the grassy seam color, but a separate **curated fern batch** in `home_dressing.gd` still placed a full plant inside the writing room. That batch had its own placement logic and bypassed the general grass-exclusion function. Fixed the source placement, retaining the exact 128-instance batch size and deterministic seed. The rain barrel was also moved clear of the attached study turret.

The actual post-fix `world_cottage_interior_study.png` now shows the clean wood floor, desk, stool and bookshelf without the previous fern intersecting the room. Front, rear and woodland angles show continuous opaque plaster. The moonlight cottage render remains available for checking that daytime work did not break darkness.

**Verified build runs:**
- [Godot gameplay, geometry, ecological clearance and regression suite — PASS](https://github.com/gfp-prod/gfp-games/actions/runs/42959462419)
- [Actual Godot OpenGL screenshot and visual pixel QA — PASS](https://github.com/gfp-prod/gfp-games/actions/runs/42959404031)

The new ecological regression scans every instance in the key grass, foliage, pebble and curated fern batches for unauthorized placement in the building footprint. This corrects an earlier blind spot where asset geometry tests passed while the rendered room was still physically full of weeds.

## Daytime exterior palette
The former world sky was a nearly uniform pale gray. `scripts/world.gd` now uses a slightly bluer clear-day gradient and a warmer horizon, reduces daylight haze density, and preserves distinct moonlit values. The existing day/night regression is retained. This is a **lighting and composition adjustment**, not a substitute for more distinctive world-scale assets.

## Engineering and art acceptance
- Godot engine suite: [wall/scene test](https://github.com/gfp-prod/gfp-games/actions/runs/42956962235), [clear-day atmosphere](https://github.com/gfp-prod/gfp-games/actions/runs/42957674537), and the newest interior smoke tests via the branch's GitHub Actions.
- Visual QA runs and screenshot downloads are at [GitHub Actions](https://github.com/gfp-prod/gfp-games/actions/workflows/verba-visual-qa.yml). Check `world_cottage_front.png`, `world_cottage_rear.png`, `world_cottage_interior.png`, `world_cottage_interior_study.png`, and `world_moonlight_cottage.png`.
- Continue enforcing the hidden-GDScript-error guard and actual human inspection; workflow success by itself is not proof of aesthetic excellence.

## Remaining major deficits
**Do not call the game finished**: the grass, terrain relief, tree silhouettes and repeating grove forms still look too generic. The new cottage should be evaluated in a larger world with village / ruin / surreal roadside transitions, not only in a hero close-up. Questless exploration must stay open-ended and Latin must progress through tangible world objects and natural conversation rather than a menu-only language course. The study books in this pass are *environmental props*, not new readable book interactions; don't imply otherwise.

## Free-resource direction
Reassess already bundled CC0 Quaternius trees and real photographic textures for deeper variation before commissioning/importing more assets. The sources previously identified—Kenney Fantasy Town Kit and Quaternius Medieval Village MegaKit—have not been installed in this pass. Do not report unused online resources as integrated.
