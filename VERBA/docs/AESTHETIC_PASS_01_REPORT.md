# VERBA — Aesthetic Pass 01: Rendered and Critiqued
**Date:** November 10, 2026
**Branch:** `verba-godot`
**Scope:** No new game mechanics. Environmental surface unification, material provenance, grimoire readability and controlled first-person visual QA.

## Actual authored changes

### Terrain / creek
- Downloaded and **bundled** 10 genuine Poly Haven CC0 1K photo materials, plus valid normal maps. Inputs and SHA256 in `game/assets/textures/real/SOURCES_MANIFEST.json`. No local user install and no game-time HTTP.
- Replaced rigid four-biome segmented ground with a **single continuous surface** driven by `game/assets/textures/real/vale_terrain_blend.jpg`. A build-time Python bake combines meadow grass, woodland soil, autumn leaves, gravel creek and dirt path with soft transitions and world-space UVs. Kept original single heightfield collision unchanged.
- The first rendition was **visibly too dark** in player-eye screenshots, so an independent grade was baked and rechecked. Further terrain detail/scenic dressing still necessary.
- Replaced saturated cyan test-water shader with translucent deeper woodland-water color and more restrained ripples. **This latest shader still requires new image review.**

### Physical grimoire
- Regraded saturated neon-yellow aged paper to a muted parchment with retained stains, replaced generic sans ink with OS-available serif fonts.
- Adjusted player-eye held position and size; modeled a fabric gutter and kept full 3D curved parchment.
- Actual Godot screenshot review rejected the original too-white first recolor. Re-tinted it, increased text legibility, and re-rendered successfully.
- **Unresolved:** book still reads visually flat/rectangular, with stiff corners, weak hand interaction and relatively little modeled thickness. Do not label the hero prop finished.

### Art/UX choices
- Initial huge automatic help HUD hidden; H opens it when wanted. Mouse-look tutorial overlay removed. Reticle and context interaction remain.
- Added real player-eye screenshots at `world_cottage_front`, `world_cottage_woodland`, `world_priory_approach`, `world_creek_bank`.
- Auditioned seven actual free KayKit forest meshes in Godot. **Rejected** generic bright green bushes, flat rocks and simple tree. The downloaded audition files and workflows were removed. See `ASSET_AUDITIONS.md`.
- Added material integrity checks to the complete Godot CI suite: verify every present photo map's source URL, SHA256 and nonzero size and the 3072px terrain bake's source and output hashes. Initial test had one mismatch of *biome nicknames* to source filenames; corrected and CI passed.

## Test evidence
- [Godot complete engine and art source integrity suite](https://github.com/gfp-prod/gfp-games/actions/runs/42888668793) — **PASS**.
- [Godot first-person visuals + animal views](https://github.com/gfp-prod/gfp-games/actions/runs/42887756162) — **PASS** on clean-HUD environment revision.
- [Godot physical grimoire visual revision](https://github.com/gfp-prod/gfp-games/actions/runs/42888244042) — **PASS** on new held pose, serif and vellum revision.
- [Screenshot-backed rejection of free candidate forest kit](https://github.com/gfp-prod/gfp-games/actions/runs/42886741608) — visual audition, no integration.

Passing builds prove source import and selected scenes execute. They **do not certify that the game is visually attractive**. Art approval requires real screenshot review at player scale.

## What I still wouldn't approve as a finished aesthetic
1. Ground lacks microgeometry: grass, roots and stones aren't yet composed convincingly; foliage size and placement feel artificial.
2. Ruined priory is a handful of obvious rectangular walls and an arch, with no credible broken masonry.
3. Cottage silhouette and windows are decent for a placeholder, but still lack appealing architectural detail, material segmentation and environmental context.
4. Wildlife models share a mismatched style with our art bible; animal idle/walk animation is not yet a full art-quality pass.
5. Grimoire is readable but not yet convincingly thick, hinged, and hand-held.
6. World lacks tonal variance, atmospheric particles, scattered props, and a location with a genuinely authored composition.

## Next aesthetic milestones (no feature creep)
- **A02: Cottage and entrance composition:** verify source quality, source a compatible medieval timber/stone set, and remodel/texture only the home clearing first. Add close-range camera test; retain physical collision.
- **A03: Woodland microgeometry:** start from compatible CC0 assets with textured realism; clusters of rooted plants, logs, dead leaves, asymmetrical rocks. Review terrain ground contact in five camera shots.
- **A04: Hero grimoire:** better hand placement, thickness, page-turn animation, subject book cover variations; revise until legible and beautiful under both day/night lighting.
- **A05: Ruin:** replace primitive rectangular test-wall silhouette with authored broken masonry and real weathered rock kit.
- **A06: Wildlife presentation:** five species with compatible material grade, convincing paw/hoof contact and idle variation; reject anything distorted.

**Release rule:** one approved scene or hero asset per stage. Never treat many successfully imported generic assets as a visual milestone.
