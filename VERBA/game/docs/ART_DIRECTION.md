# VERBA — Art Direction & World Composition

## Goal

**A believable retro RPG, not a bright mobile low-poly pack.** Make the player feel small in an old, inhabitable world. The world should have history before the player enters it.

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
