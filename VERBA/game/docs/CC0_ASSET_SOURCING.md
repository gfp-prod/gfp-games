# VERBA: verified free CC0 asset intake — 2026-11-12

This is a **source shortlist**, not a record of imported/downloaded assets. Keep a
pack marked `candidate` until its actual file, included license, scale, UVs,
face counts and visual fit have been inspected. Do not mistake "free to view"
or "free to download" for CC0 unless the creator's page verifies it.

The project's art direction is `docs/VERBA_ART_BIBLE.md`: grounded retro
painterly fantasy, physically credible buildings, varied ecology, rich but
restrained weathering, deliberate normality broken by rare surreal landmarks.
**No generic toy-palette assets in the hero area.**

## Priority 0 — highest art/effort payoff

| Source (official pack page) | License | Verified offering | Where to test first | Conversion / art rules |
|---|---|---|---|---|
| [Chilly Durango Retro Medieval/Fantasy Building Kit](https://chilly-durango.itch.io/medieval-building-parts) | CC0 on page | Free ZIP (912 kB): modular walls, floors, beams, windows, doors, stoves, tables, books, bottles; 256×256 PNG photo textures compressed to 16 colors | Cottage/village interior, bakery shelf, bedroom, in-world bookcase | Prime VERBA style reference. Examine prefab wall dimensions and surface normals; keep geometry, balance material temperature with existing moss/slate palette |
| [Kenney Retro Medieval Kit](https://kenney-assets.itch.io/retro-medieval-kit) | CC0 | Free ZIP (1.9 MB), >100 textured PSX/early-3D OBJ/FBX/glTF props | Castle infill, bridge repair objects, village structural details | Use only the retro *textured* pack, not untextured blockout models for hero assets |
| [Kenney Retro Urban Kit](https://kenney-assets.itch.io/retro-urban-kit) | CC0 | Free ZIP (2 MB), >120 textured OBJ/FBX/glTF pieces | Gas station, signs, service road, garage interior | Apply oxidized metal, grime and restrained green/iron palette; don't convert station into generic medieval architecture |
| [Kenney Retro Fantasy Kit](https://kenney.nl/assets/retro-fantasy-kit) | CC0 | 100 models (creator page) | Stone arches, walls and towers | Test against Chilly kit and existing castle: reject style mismatch |

## Priority 1 — coherent living landscape and characters

| Source (official page) | License | Free offering | Candidate use | Notes |
|---|---|---|---|---|
| [Quaternius Stylized Nature MegaKit](https://quaternius.com/packs/stylizednaturemegakit.html) | CC0 | ~60–70% in free Standard, OBJ/FBX/glTF; full pack 116 models | Groves, foreground trunks, varied canopy silhouettes, reeds, flowers and rocks | Needs material grading: the complete original pack is **not** entirely free. Avoid cartoon-bright vegetation and 1:1 kit mixing with very low-poly Kenney trees |
| [Quaternius Medieval Village MegaKit](https://quaternius.com/packs/medievalvillagemegakit.html) | CC0 | ~60–70% Standard; 300+ models refers to entire set | House roof, gable, steps, doors and modular occupancy | Never claim full Godot/source project included free; Source tier is paid |
| [Quaternius Ultimate Animated Animal Pack](https://quaternius.com/packs/ultimateanimatedanimals.html) | CC0 | 12 animals with >12 animations each, FBX/OBJ/glTF/Blend | Deer/wolf/horse and wildlife prototypes to replace sliding primitive creatures | Retarget, size and collision audit; original animations not automatically compatible with existing VERBA skeletons |
| [Quaternius Universal Animation Library](https://quaternius.com/packs/universalanimationlibrary.html) | CC0 | Free Standard *subset* of 120+ animation library | Walks, turns, interactions and reactions for humanoid NPCs | Retarget to consistent humanoid armature and verify actual movement in Godot |
| [Avramania Free Medieval Collection](https://avramania.itch.io/free-collection) | CC0 | Creator page at verification says 189 assets from 8 packs; index may describe newer larger total | The low-poly library includes modular castle, village, farming, food, fencing, stones, interiors in one palette and meter scale | Very flat 256×256 color atlas. Use as construction prototypes, under texture grade or in far distance, not unaltered hero village. Creator reports AI assistance on some meshes |

## Priority 1 — actual photosourced texture families

| Source (exact asset) | License | VERBA surface | Rules |
|---|---|---|---|
| [Poly Haven Mossy Stone Wall](https://polyhaven.com/a/mossy_stone_wall) | CC0 | Castle, shrine, footbridge piers, cottage foundations | Download only 1K/2K maps; blend restrained lichen where rain collects; preserve coursed geometry |
| [Poly Haven Mossy Cobblestone](https://polyhaven.com/a/mossy_cobblestone) | CC0 | Stone footpaths and cobble transitions | Use 1K/2K diffuse + OpenGL normal, blend with mud; don't tile a single photograph across the whole village |
| [Poly Haven Brown Planks 08](https://polyhaven.com/a/brown_planks_08) | CC0 | Doors, interior floors, mill, old tables | Align UV grain with length of boards; darken under roof rather than everywhere |
| [Poly Haven Forest Ground 03](https://polyhaven.com/a/forrest_ground_03) | CC0 | Woodland carpet and undergrowth | Mix with existing gravel, earth, fern stands, don't overwrite all terrain |
| [ambientCG Rust 007](https://ambientcg.com/view?id=Rust007) | CC0 | Abandoned fuel pumps, canopies, truck and sheet metal | Corrosion localized at joints; 1K JPG maps first |
| [ambientCG Bark 005](https://ambientcg.com/view?id=Bark005) | CC0 | Imported deciduous trees and cut timber | Preserve bark direction and canopy alpha; don't shade the tree uniformly white |
| [ambientCG Rock 002](https://ambientcg.com/view?id=Rock002) | CC0 | Wet shoreline, ruin faces | Stone texture scale in real meters |
| [ambientCG Paper 001](https://ambientcg.com/view?id=Paper001) | CC0 | Grimoire pages, in-world notices, diegetic scholar props | Must be readable at 1280×720 and under low light |
| [Kenney Retro Textures Fantasy](https://kenney.nl/assets/retro-textures-fantasy) | CC0 | Shared hand-graded low-res tile set for stone/wood/ground | 115 textures; compare against photosourced retro textures and restrict palettes |

Official licensing evidence:
- Poly Haven: https://polyhaven.com/license (all textures/models CC0).
- ambientCG: https://docs.ambientcg.com/license/ (assets CC0 including files redistributed in games).
- Quaternius: https://quaternius.com/faq.html (all models CC0, Standard vs paid Source different).
- Kenney: https://kenney.nl/support (asset pages CC0).
- Chilly Durango: individual pack page above, original kit explicitly CC0.

## Concrete integration sequence

1. **Download locally and quarantine**: `VERBA/asset_inbox/` (gitignored). Retain original ZIP and the included license. Do not upload an unpacked 400 MB texture bundle to the public repository.
2. **Inspect one pack at a time** in Blender: count tris, inspect flipped normals, UVs and axis, determine dimensions in meters, check whether alpha and animations actually work.
3. **A/B one actual asset** against the existing model from the same 70-degree FOV first-person camera. In the Foundry, save original/new `1280×720` frames. Reject improvements that lose atmosphere or place doors through collision.
4. **Texture authoring**: use 256–512 px for PSX interiors/props, 512–1024 px for main buildings, generally 1024–2048 px max for large tiling PBR surfaces. Use linear/mipmap/normal-map conventions appropriate to Godot 4 (OpenGL/Y+ normals).
5. **Bake and batch**: atlas and UV-pack material families, simplify 3D pieces, instance repeated grass/rocks. Preserve original animated rig; do not duplicate imported photos per tree instance.
6. **Provenance for each final asset**: source URL, source license, exact downloaded asset name/version, source SHA256, modifications, export SHA256, 1m scale, Blender/Godot versions, screenshot/test log. CC0 doesn't require credit, but documenting sources prevents accidental later contamination.
7. **Only then enable in-world**: visual-only replacement on existing colliders if the source is a facade/prop; new colliders + navigability check if a genuinely new building is placed. Never silently swap NPC work goals, book UIDs or economic save IDs.

## Risk / non-goals

- **Do not buy Source/Pro tiers** just to gain a .blend file. Blender can import the free glTF/FBX; keep our authored edits as new .blend source.
- **Do not mix an entire Quaternius bright forest and Kenney minimalist woods** in one visual layer. Treat natural species as a coherent bioregion; repaint/retopologize when mixing.
- **Do not use unknown-license Sketchfab, Pinterest or random Google image models** just because download is possible.
- Some downloadable non-CC0 "free game assets" cannot be republished as an asset library. We can safely prioritize the specifically verified CC0 packs above.
- Sources have been researched, **not downloaded into VERBA** by the creation of this catalog.
