# VERBA — Visual Identity and Art Bible v1
**Art direction lock: November 10, 2026.** Applied to the existing `verba-godot` project. This is a production contract, not a claim that the game already meets it.

## The visual thesis
**A tactile, slightly weathered storybook world rendered with late-PS2/early-PS3 readability.** Whimsical daylight can coexist with a desolate fluorescent gas station, a strange medieval village, or ancient unexplainable ruins. VERBA is not a joke universe or an unbroken horror experience. It must have recognizable life, warmth, and genuine ambiguity.

**Artistic anchors:** the strange authored geography of Morrowind; the everyday coexistence of genres in Adventure Time; the physical books, masonry and domestic craft of old European folklore illustration; the stylization and legibility of a carefully art-directed early-2000s RPG.

**Non-negotiables:** silhouette over polycount; coherent authored shapes over random asset packs; surface-specific materials; rich midtones with readable shadows; expressive inhabitants; no yellow/green blown-out terrain; no floating paper panels as a grimoire; no gigantic or deformed wildlife assets.

## Palette system
Colors are reference sRGB values, not a global multiply on every asset.

| Material/environment | Midtone | Shadow | Highlight | Note |
|---|---|---|---|---|
| Meadow turf | #586b50 | #394a42 | #9ba578 | Different from woodland ground |
| Cool understory | #465d52 | #283b36 | #778b6d | Moss, fern, stream shade |
| Autumn trees | #8d6a58 | #5f4745 | #c19a70 | Rust, muted coral, amber; no solid orange canopies |
| Soil/path | #6d5645 | #46392f | #a38868 | Muddy pressure/wear, soft road edges |
| Stone/masonry | #87867a | #555a56 | #c1b9a1 | Carved, mossed, varied courses |
| Weathered timber | #6e5440 | #382d2b | #ac8963 | The timber grain remains visible |
| Oxblood leather | #563a35 | #281f20 | #896b57 | Handled/rounded cover edges |
| Vellum | #c8b394 | #9c866f | #e0cfad | Curved, textured, volumetric pages |
| Aged brass | #a88b59 | #63503a | #d0b177 | Restrained fittings, not neon gold |
| Dusk | #647987 | #354b57 | #c5a78b | Luminosity from warm focal sources |

**Dramatic moods:** meadow/curiosity (warm but restrained), woodland (cool, sheltered), cottage (amber practicality), ruin (chalky stone and blue shadow), gas station (unnatural warm-cold fluorescent contrast). Lighting changes mood without remapping everything to a single tinted fog.

## Geometry and asset hierarchy
**Hero (must withstand arm's-length viewing):** the held grimoire, pickup books, cottage door/interior, tower's first buildable wall, familiar. These require multiple materials, recognizable thickness, real 3D joints, UV discipline, collision, animation/interaction checks.

**Midground:** trees, vegetation, wolves/deer/foxes, rubble, boundary walls, roofs. These require silhouette variation, correct relative scale and camera-tested LOD.

**Background:** distant ridges, skyline pines, ruins and landmark silhouettes. Their detail is concentrated in shape, rhythm, and color, not tiny repeated props.

**Texture scale:** ground diffuse repeats in world units consistently across separate biome meshes. Leaf and bark materials stay distinct and alpha is tested in the renderer. No blanket white albedo over gray color maps, no harsh high-frequency noise, no obviously repeated huge procedural patches. Existing bundled `assets/textures/real/` photo-based textures are preferred where physically credible, with real source notes retained. Original authored textures may be used where more coherent.

## Composition rules
- An arrival view should have foreground shape, one midground focal landmark, and a distant question or silhouette. No fixed global “clutter density.”
- Road/trail edges accumulate little stones, moss and short grass; the center is worn and traversable. Roads bend to reveal landmarks slowly.
- Dense canopy forms *rooms* with windows of visibility; glades are truly open.
- Clusters should have small/medium/large size rhythm; avoid every bush having the same height/angle.
- The starting stone/book should look like a deliberate discovery and never be obscured by grass.
- A large tree should read at five paces; the grimoire at half a meter; the cottage at a hundred paces.

## Lighting / atmosphere
- Outdoor key is a single directional sun with shadow; fill is controlled ambient sky. Dusk and night add controlled motivated sources.
- Use fog for depth separation, not to hide silhouettes; preserve readable foreground material.
- Shadows must survive the GL Compatibility renderer and remain usable on an NVIDIA laptop GPU.
- Do not fake good art by simply increasing glow or saturating the whole sky.

## The grimoire specification
- A physical leather binding with an actual rounded spine, boards proud of the page stack, individually readable paper edges, curved parchment with a center gutter, restrained aged brass guards, ink on page surfaces.
- No flat yellow rectangles, screen-space overlay, huge bevelled gold icons or legibility-ruining embellishment.
- The existing vocabulary/study content remains, with no separate HUD panel. The cover rises and closes smoothly under player control.

## Animal visual requirements
Scale in meters, no imported boar-in-hare disguise, no skeleton mismatch. One character per species in a neutral gallery, plus walk-cycle and actual first-person world view. Inspect stance, hoof/paw contact, rig motion, color/shadow, and size next to a 1.75 m reference. No animal passes solely because a GLB imports or bone transforms change.

## Texture/material tests
Render at 10:00, sunset and night for one hero material, one trunk, a boulder, cottage wall, vellum and brass. Source/origin/rights metadata stays in the repository. Model provenance is not sufficient without visual approval.

## Approval gates (must be shown, not asserted)
1. Baseline and new screenshots from the *same camera and lighting*. Store baseline artifacts; note changes.
2. Physical-book passage/question/reward at first-person scale.
3. Home clearing looking toward road, forest, ruin; three lighting states.
4. Creature idle and full walking cycle for all five existing species.
5. Reject broken faces, clipping, unreadable text, oversized items, floating props and obvious seams.
6. Run existing physics, Latin, saving and ecology regression tests after any world/model change.

## Release boundaries
**Aesthetic freeze:** no new magic verbs, mobs, regions, tower mechanics, or NPC features until the starter forest, cottage, book and existing creatures look convincingly part of the same game. Later gas station/castle/village/ruin designs share this art bible, but are not built during the initial aesthetic sprint.

**Definition of “finished starter aesthetic”:** four consistent first-person views; a readable, attractive open grimoire; a home that looks intentional from outside and inside; terrain without severe hard seams; animal sizes/movement credible; visual QA passes. An automated pixel gate is not a substitute for looking at the images.
