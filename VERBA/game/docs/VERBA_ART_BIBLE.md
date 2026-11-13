# VERBA — Art Direction Bible and Acceptance Standard

**Project:** The Immortal Wizard / VERBA, a first-person open-world Latin-magic RPG.

**The target is not a realistic game wearing generic fantasy assets, and not a toy-like cartoon.** Its landscape should feel *lived in and physically true*, while its places can be as improbably juxtaposed as a gas station beyond a medieval castle. The fantasy comes from geography, architecture and consequences; the credibility comes from materials, light, anatomy and construction.

## Three non-negotiables

1. **Painterly, tactile and grounded.** Readable silhouettes, real architectural logic, weathered timber, mineral stone, aged stucco, slate, black water, imperfect soil, and believable vegetation. Source photography may be CC0 and heavily graded. Avoid stock-perfect, plastic-clean or aggressively saturated materials.
2. **Whimsy through discovery and contrast.** A village, deserted filling station, castle, orchard, lake and ruined shrine can coexist, but should not be compressed into a theme-park block. Travel, valleys, terrain silhouettes, roads and changes in ecological cover create the surprise. Locations must look like they have histories.
3. **Eeriness through alteration of normality.** A mundane place should remain mundane until a single detail or change makes it strange. Do not solve atmosphere by covering every shot with fog, glowing sigils, occult symbols, identical crooked trees or perpetual darkness.

## Failure patterns identified in actual Godot images

- Salmon-pink/yellow tree source pigments were not removed by simply multiplying textures by green. The shared alpha-preserving luminance grade in `scripts/tree_palette.gd` is the correction; verify the actual in-engine result.
- A square, visible world ending at 128 meters made the gas station overlook an apparent empty ocean. `scripts/distant_horizon.gd` adds **visual-only** distant ridges, without altering saves or map physics. In-game screenshots must verify it.
- Several early regional props became stacked boxes even when their GLBs were technically valid. The Foundry's import/scale QA is **engineering acceptance**, not artistic acceptance.
- The first cottage prototype looked flatter than the older playable structure. Do not replace a better asset solely because the new one comes from Blender.
- Bare grass, repeated bright leaf sprites, exposed hard-edged roads and overly uniform canopy values reduce perceived scale.

## Material and geometry rules

**Stone:** chamfers, varied courses and fractured edges, with dampness at bases and lichen where moisture would accumulate; no arbitrarily repeated evenly sized cubes.

**Timber:** actual load paths, joints and repairs. Wood grain follows the beam's length; UVs must not stretch the photographs across impossible spans.

**Metal:** controlled corrosion at seams, water traps, fasteners and damage points. Fuel-station sheet metal and medieval iron are distinct material families.

**Buildings:** meaningful roof thickness, drainage, windows and door openings; correctly attached foundations. Every entrance must match existing collision geometry.

**Vegetation:** subdued variation within botanical species, varied plant size and stand density, distinctive tree silhouettes and clearings; no spherical crowns, traffic-cone evergreens or lemon-yellow forests.

**Water:** dark, mineral and stratified by depth. Reeds, wet silt, driftwood, stones and soft edge transitions explain the shoreline. No bright blue swimming-pool surface.

**UI:** grained iron, parchment, aged brass and ink—subtle, legible, compact, responsive; Latin belongs to the grimoire, conversations and wizard training rather than an unrelated educational overlay. Preserve keyboard usability and readable contrast.

## Spatial composition

The world should not be one uninterrupted sheet of evenly colored grass. Design in overlapping ranges:

- **Foreground (0–12m):** convincing scale, worn props, varied soil, occlusion, planted landmarks. This is where crude boxes and floating surfaces are most visible.
- **Middle distance (12–80m):** distinctive architecture, roads, groves and water shapes. Alternating vegetation density makes routes readable.
- **Background (80–400m):** hills, forests, ridges and sky transitions. Avoid a hard square-map horizon or single blank fog wall.

Player height is the primary evaluation camera. A landmark must still read from a path leading toward it, from its threshold, and from an oblique angle; a beautiful isolated object rendered in a studio is insufficient.

## Foundry production tiers

**Tier A — hero architecture, village workshops, creatures:** editable Blender source, intentional silhouettes, physically anchored details, correct UV/material channels, interaction-safe integration and 4+ rendered game angles.

**Tier B — repeated architecture and vegetation:** modular parameterized source meshes, shared photo materials, 2+ variations and batched geometry where appropriate.

**Tier C — background forms:** low draw-call visual silhouettes from authored terrain/trees. Never change the 256m physics edge or persistent entity IDs as a shortcut to beautifying the far horizon.

Use **original authored geometry and provenance-tracked free CC0 assets** only. Do not use paid packs, hidden downloads at runtime, or unlicensed fonts.

## Art acceptance gates (distinct from automated build passing)

1. **Shape:** identifiable at gameplay distance and visually coherent in all four cardinal views; doors, supports, roof and joints make sense.
2. **Material:** no blank or warped UV surface, alpha bugs, overbright bark, glowing white foliage or cartoon-flat diffuse surfaces; all external sources and licensing documented.
3. **Environment:** silhouette and palette consistent with neighboring assets, no levitating scenery, no sudden material seam, no blatant repetition within 15 meters.
4. **Experience:** player can enter, walk, fight, study, talk, save and continue normally; existing collision, navigation, schedules and stable IDs remain intact.
5. **Performance:** Godot opens quickly; do not duplicate massive source textures in every instance; use lower-poly distance assets and measured mesh budgets.
6. **Proof:** actual Godot OpenGL and first-person views of the approved branch, not moodboards or Blender renders alone. Preserve screenshots and CI artifacts.

**Passing an automated import and screenshot test is necessary, but not sufficient to merge an aesthetic change.** Keep the Foundry PR draft until live comparisons show clearly better art and the project's full regressions pass.

## Work order

1. Fix pervasive palette, foliage and distant terrain: these dominate every screenshot.
2. Bring the cottage-to-lakeshore region to a polished, reusable baseline with navigable paths and believable shore.
3. Replace the station and keep/castle architectural shells without moving entrances or collisions.
4. Bring village homes, workshops and ruins into the same material families.
5. Improve character and animal proportions, rigging, animations, clothing and expression.
6. Review every HUD, conversation, book and construction control for tactile consistency and legibility.
7. Repeat all real-scene view gates. Revert or revise any model that loses to its predecessor.

*Source-of-truth:* this file controls future visual decisions; `ART_FOUNDRY.md` controls the export workflow. This is an artistic goal, not a statement that the finished game already meets it.
