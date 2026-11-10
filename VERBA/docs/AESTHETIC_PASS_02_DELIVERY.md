# VERBA — Aesthetic Pass 02 Delivery & QA
**November 10, 2026 · Godot 4.5.2 · `verba-godot`**

This is the delivered second art pass for the **existing starting valley**. It is a playable **alpha art iteration**, not the assertion that every future character, world tile, dungeon, tower or animation is finished.

## Authored changes that are actually in the game
- **Ground:** preserved previously sourced Poly Haven CC0 baked biome atlas and corrected low meadow detail. The old nine-blade triangular clump was rebuilt with twelve narrower tapered blades; vegetation distribution is denser, quieter and shorter. Grass types still use GPU MultiMesh batching, not thousands of independent Nodes.
- **Tree canopies:** expanded autumn variations across olive, ochre and weathered rust, rather than a wall of saturated salmon pink, and added three carefully placed first-glade framing trees.
- **First lesson:** replaced the visually anonymous cuboid `De Herbis` pedestal with a carved low stone lectern, wooden inscription and physically positioned book.
- **Scenery:** created a traversable thirteen-metre creek bridge (modeled planks, handrails, wood/stone materials and real collider), three carefully placed fallen tree trunks with collisions, and four hundred low, grouped wildflowers near appropriate landmarks.
- **Cottage:** added purposeful herb garden, labeled garden marker, rain barrel and compact framed oil lantern; retreated the lantern from the dominant camera foreground after comparing two actual renders. The herb bed was optimized to one MultiMesh rather than over one hundred separate leaves/stalk nodes.
- **Priory:** added a partially collapsed, physically collidable polygonal bell tower behind the ruined arch. It forms a distant landmark and gives the ruin vertical identity.
- **Previously completed in art pass 01:** photo-based continuous world terrain, daylight/night atmospheric blending, more physical serif grimoire with curved pages and hand supports, real first-person review camera locations, terrain provenance checks, and no default screen-sized help HUD.

## Objective technical and performance evidence
- GitHub Actions runs Godot's complete gameplay regression, source/license/asset consistency, forest interaction, Latin and save-state tests, and real OpenGL image capture for first-person meadow, cottage, priory, creek, night, book and wildlife.
- Benchmark in the baseline (before authored details): **2,179 nodes, 706 MeshInstance3Ds, 1,794 ms headless scene build, 0.911 ms mean ecology tick**.
- In the detailed scene before optimization: **2,454 nodes, 934 meshes, 2,057 ms headless scene build, 0.911 ms mean ecology tick**.
- After batching herb geometry: **2,335 nodes, 814 meshes, 1,891 ms headless scene build, 0.934 ms mean ecology tick**.
- Those timings come from GitHub-hosted Linux virtual machines: **not** laptop frame-rate claims. Mesh/node reduction versus the expensive intermediate: **119 nodes, 120 mesh instances**, roughly **166 ms** headless start improvement.
- The source art is CC0/locally authored and remains bundled; **no extra asset installer**.

### Visual QA interpretation
Actual Godot renders confirm the design moves in the intended direction: plant scale and forest palettes are less aggressive, the creek has a landmark, the cottage has signs of use, the priory has a stronger silhouette, and the book is legible. Automated screenshot success means the game renders — **not** that a professional artist has approved every corner.

## Explicit remaining art-quality debt
The terrain is still visually simple for a complete commercial RPG, including short sightlines and too little rock/ground variation. Cottage interior and roof construction need a much more detailed hand-art pass. The ruined tower and bridge are now grounded, but need asymmetrical handmade stone/timber details. The animals are recognizable and animated, but they do not yet have expressive custom creature animation quality. The grimoire is legible but has limited page-turn movement and rather simplified hand geometry.

Do not mislabel this alpha art milestone as a finished world or a production-shippable AAA/PBR look. These are honest **remaining product goals**, not blockers that invalidate completing a coherent, tested starter-area art pass.

## Reproduction
1. Use the extracted `verba-godot` branch project from GitHub, open `VERBA/game/project.godot` in Godot 4.5+ and run.
2. Navigate the starting clearing and physically approach the cottage and stream. Use G to review the grimoire and collect a book.
3. Review GitHub Actions *VERBA Godot source and engine tests* and *VERBA visual rendering QA* runs for the same revision; download the visual gallery artifact for screenshots and animal animations.
4. Compare identical scene camera angles, not differently framed concept art.

**Completed in this pass:** starting-valley composition, foliage shape, tree grade, visual details, bridge, cottage garden, priory tower, book presentation and several visually intrusive items. **Not added:** new quests, spells, survival mechanics or world regions.
