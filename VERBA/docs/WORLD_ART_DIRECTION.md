# VERBA — World Art Direction v0.6
**Updated:** 2026-11-10 | Branch: `verba-godot`

## North star
VERBA is a living, open-ended Latin-learning fantasy world that can turn from buoyant to eerie to dreamlike. A roadside gas station may sit beside a medieval castle without a lore dump. The player's sense of discovery takes priority over an encyclopedic, logically uniform world. Latin must feel like part of the physical reality: inscriptions, field guides, shops, creatures, and eventually conversation.

### Design rules
- **Shape before detail.** A house, beast, or shrine must read at 40 metres as a recognisable character. No more small procedural clutter to disguise weak silhouettes.
- **Strange but inhabitable.** Asymmetrical silhouettes and surprising adjacencies must coexist with navigable doorways, feet on ground, and legible player paths.
- **Three tonal registers.** Warm pastoral roads: sky, color, flowers, hospitality, playful animal proportions. The edges: old stones, shadowed groves and quiet interruptions. Night and dream: uncertainty of scale and reality, cooler sound/lighting, fewer predictable shapes. Keep continuity of ecology and player movement.
- **Materials by family.** Warm lime plaster, soot timber, green-grey slate and rain-dark stone for the hermitage; faintly oxidised metal and parchment elsewhere. The book is a physically readable artefact, not a detached HUD.
- **Focal cadence.** Each major route needs a far silhouette, mid-distance framing, and at least one near tactile detail. Avoid visible repetition of identical free models.
- **Performance is art direction.** Prefer one authored mesh + instancing to hundreds of independent draw calls. Avoid per-frame dynamic mesh rebuilds unless justified.
- **Latin readability outranks ornament.** Do not allow binding, hands, glare or camera pose to hide passage/quiz text.
- **Protect gameplay identity.** Any added ecological object must preserve stable saved IDs for existing entities. Collidable structures must have collision proportional to visible mass.

## Actual authored project work
- `scripts/storybook_house.gd`: first deliberate replacement for the former unmodified cottage prefab. Asymmetric roof, stone study turret, crooked chimney, hand-built entrance. It is still an **alpha** hero asset pending full rendered approval.
- `scripts/landmark_tree.gd`: original hanging-leaf creekbank silhouette rather than another repeated imported tree.
- `scripts/glove_art.gd`: shaped, modeled supporting grips on the physical grimoire.
- `scripts/scenic_details.gd`: low, dark rope footbridge.
- `tests/world_gallery.gd`: human review from cottage front, woodland, creek and day/night, instead of passing only abstract model checks.

## Research log: free external shortcuts worth using
**Verified upstream CC0 terms; not yet imported in this pass:**
1. [Quaternius Medieval Village MegaKit](https://quaternius.com/packs/medievalvillagemegakit.html): 300+ modular medieval pieces, Godot example available in the paid source tier; the free standard edition is CC0, with glTF/OBJ/FBX. Best for castle/village infrastructure once a coherent form is approved. Use direct geometries rather than copy/paste an entire assembled generic village.
2. [Kenney Fantasy Town Kit](https://kenney.nl/assets/fantasy-town-kit): CC0 coordinated fantasy town pieces. Useful for temporary blocking of future villages and to compare snap/grid dimensions.
3. Existing bundled Quaternius foliage and wildlife: maintain their license/asset provenance and rework their palettes and placement. Existing tree repetition remains a quality problem.

**Download status:** The upstream Kenney ZIP was identified, but could not be retrieved in the current environment. This source has **not** been integrated or represented as integrated.

## Approval gate
Pass all three: (1) actual Godot scene/gameplay tests with explicit error-log scanning, (2) actual OpenGL screenshot capture plus pixel regressions, and (3) human inspection of hero frame silhouette, scale, lighting and composition. Test success alone never means the art looks good.

## Remaining high-value art tasks
- Authored mossy, volumetric cottage roof material and silhouette polish if the new structure still reads flat/boxy.
- Distinctive foliage tree families with expression and nonidentical crowns.
- Redesign the far hills and atmospheric framing so the central valley is not a green empty plane.
- Begin a varied village/castle/gas-station horizon composition; do not put all three at spawn merely for novelty.
- Upgrade wildlife models/behavior for personality; keep day/night and interactions genuinely emergent.
