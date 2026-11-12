# VERBA — Art Direction & World Composition

## Goal

**A believable retro RPG, not a bright mobile low-poly pack.** Make the player feel small in an old, inhabitable world. The world should have history before the player enters it.

### The Outer Vale visual identity (second pass)

Six world-coordinate-blended terrain surfaces, using existing committed images: meadow ground, shaded woodland humus, desiccated grass, packed/eroded earth, stream/lake silt, and broken stone. Transitions are soft and include tonal mineral variation. Keep all assets near the same low-contrast, worn natural palette; no cartoon neon, universal bright-green plane, or free-floating biome squares.

The lake is a depression in the **actual terrain collider**, not a decorative disk. Water is dark peat and cold slate, with an irregular shore, reed beds, rocky silt, a walkable wooden jetty and a half-drowned stone. Roads use the terrain as physics and follow the heightfield. The modern forecourt and distant castle are separated by roughly 60 m and connected by a legible worn route; this surrealism has travel distance and environmental history.

UI and the grimoire use the same low-key material language: oxidized iron (#171b1b), charcoal (#242727), bone chalk (#dbd0bb), dirty parchment (#c6b79f), old brass (#ad9270), bruised rust (#a96e67). Continuous floating status bars and bright generic dialogue windows are prohibited. Latin input must remain legible while longer NPC speech scrolls.

### Terrain aging and authored damage

The environment is not completed by assigning a different ground color. Every landform receives evidence of use: dirt rut intersections, dropped stones at road shoulders, chipped timber and concrete, plant growth through damaged surfaces, and distinct near-water sediments. Decorative props must align with world.height_at and must not block live social routes. The art pipeline is still early-PS2/PC fantasy; avoid a glossy photoreal automobile amid untextured primitive homes.

Public and owned textures already shipped with the project are preferred over fetching new assets. Subtle daylight and fog changes must preserve legible paths, visible NPCs and the original sunrise/night cycle. Scenic meshes must be batched or limited and must not create simulation or save-state work.

### Shape and hierarchy

1. **Primary:** chapel walls, a distant split arch, major dead tree, ridge, old cottage. Distinct silhouettes visible at walking distance.
2. **Secondary:** adult trees of genuinely different species and crown shapes, boulders, fallen log, shrines, stream bends.
3. **Tertiary:** sparse reeds, grass patches, mushrooms, weathering, leaf litter. Tertiary details should not drown out primary shapes.
4. **Negative space:** open glade on spawn, path corridor, stream crossings, vistas across slope; aim for landmarks separated by natural traversal time.

### Materials

- Original procedural parchment, oxblood leather, weathered stone, grooved bark, and rough timber maps are included.
- Historical texture feel: subdued color, noisy microdetail but preserved midtones, rough PBR, occasional golden magic.
- Avoid smooth plastic diffuse colors and repeating single-tone green forests.
- Art progression: re-topologized creature meshes in Blender, UV painting, ear/leg silhouettes, rigged locomotion; then environment material passes and LODs.

### Lighting and weather

Soft haze, warm raking sun through mist, slightly brighter distant horizons, readable fore- and mid-ground. Rain should darken/wet surfaces and influence fire/creatures. Avoid aggressive bloom that obscures Latin text.

### Village character readability

The first focused villager pass uses sculpted twelve-sided tapered tunics, anatomically proportioned heads and facial features seated against the skull rather than floating in space. The baker has a fitted four-triangle cloth apron, work pocket, head-covering and visible sash; different citizens retain their own skin and role materials. These are deliberately stylized early-PS2 placeholders, with normal world movement, ray interaction, physical employment and saved knowledge still owned by the existing systems. Review actual 720p first-person renders before artistic sign-off; no claim of finished human animation or sculpted skin.

### Animations

Grimoire should have a visible closed state, hand lift, jointed cover opening, page changes, and a gentle lower-back motion. Creatures need gait cycles, alert reactions, and fleeing, not sliding along the ground. The v0.5 creature rigs are procedural animations and placeholders for sculpted/rigged assets; the book is a procedural articulated mesh.

### Visual QA checklist

At spawn, can the player see at least two landmarks and a generous patch of clear ground? Do the priory and cottage look different in form, not just material? Are tree crowns asymmetrical? Can animals be identified by shape alone at twenty meters? Does the screen read as first-person RPG rather than mobile UI? Is grimoire text readable without a modal overlay? Are spell letters visibly embedded in the world?
