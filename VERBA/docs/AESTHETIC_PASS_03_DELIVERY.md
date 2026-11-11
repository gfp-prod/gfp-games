# VERBA — Aesthetic Pass 03: Starter Valley Final Polish
**Date:** November 10, 2026  
**Engine baseline:** Godot 4.5.2 · Compatibility renderer  
**Working branch:** `verba-godot`  
**Release scope:** The **current playable starter valley**. This is **not** a finished open-ended RPG or a claim that all future art is complete.

## Shipped changes

### Layered outdoor materials
- Introduced `scripts/ground_dressing.gd` as a deliberately constrained, reusable outdoor scenic kit. It creates **2,100** varied, low-profile photo-textured pebbles distributed in meaningful groups along worn roads, ruins and forest boundaries; plus **580** flattened, moss-coated wetland islands along the creek.
- These **2,680 pieces use just two GPU MultiMesh draw batches**, with materials sourced from **bundled Poly Haven CC0 stone/moss photographs**, not individual physics nodes or random downloadable assets.
- Rebalanced grass blade vertex tint and switched nearest-neighbor sampling away from the grass layer; the prior combination of source colors, mesh vertex colors and instance colors produced very dark, distracting flecks across the meadow.
- Reduced and re-colored cottage stepping stones to blend with real photographed earth rather than looking like scattered white rectangular markers.

### Physical hero book
- Added a true 3D parchment leaf hinged at the book's central spine. The page rotates across the physical grimoire; ink changes after the leaf passes the gutter, not immediately when the player presses A/D.
- The non-turning page remains readable while the opposite page swings. Previously the animation sometimes showed two completely blank parchment panels.
- Added a dedicated Godot `grimoire_page_turn.png` first-person camera capture and a scene regression `tests/grimoire_page_turn_test.gd` verifying that pages turn, their text switches at the midpoint, and the turning leaf disappears correctly after settling.
- Maintained the same working Latin reading, book quizzes, mana and scholarly progression.
- Actual mid-turn screenshots revealed overlong Latin glosses spilling past the leaf edge; reflowed lexicon definitions to 22-character ink columns, reduced the reference-page type size, kept longer manuscript type readable, and added a scene regression rejecting over-wide physical page text.

### Scope and code quality
- Reused the existing physical book, existing CC0 materials and Godot native MultiMesh/QuadMesh. No extra external plugin, installer, or dependency was required.
- Did **not** add spells, quests, NPC behavior or more world regions during this art pass.
- Retained landscape collision and living-plant simulation. Ground detail is deliberately decorative and batched to avoid adding thousands of sim objects.
- The automated release checks still cover Latin, collected books, saves, animal locomotion, collision, and the same-camera OpenGL visual gallery.

## Visual acceptance requirements

All statements about render quality must be checked on **actual** Godot-rendered frames, never from concept art. Review the four first-person spawn camera angles, cottage, creek, priory, two moonlight frames, grimoire text, midpoint page flip and five animal poses. 
The workflow's green check means **the game imports, executes and produces frames**. It does **not** mean every asset passes a professional aesthetic evaluation.

## Remaining artistic debt / limits

This pass completes the **defined starter-valley art iteration**, not the full world art pipeline:
- Cottage interior and outer roof still need more artisanal detail; the current cottage reads well from walking distance but isn't a finished hero environment.
- Tree foliage still shows the visual language of its sourced 3D models. Custom painted/rigged assets would be required for a truly distinctive commercial look.
- Wildlife animations are recognizable but not yet the expressive authored interactions expected in a mature game.
- More distant settlements and the gas station, castle, and larger ruins are intentionally not part of this starter-valley art pass.
- The moving grimoire page is a physical sheet, but not yet a production-grade multibone deformation with ink that warps along the leaf.

**Art quality does not improve by declaring it complete.** This release signs off a coherent, test-checked **alpha area**, while keeping the broader world/hero-art objectives explicit. Finishing the entire visual identity requires additional asset production and real playtesting.

## Reproduce

Download the `verba-godot` branch ZIP, extract it, open `VERBA/game/project.godot` in Godot 4.5+ and start. No texture installer is required. The GitHub Actions workflows `VERBA Godot source and engine tests` and `VERBA visual rendering QA` verify technical continuity. All physical models and photos ship in the project.
