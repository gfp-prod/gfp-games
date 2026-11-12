# VERBA — The Outer Vale / visual system v2

## Art thesis

**A weathered place with strange histories, not a brightly colored low-poly kit.** This pass is deliberately restrained early-PS2/PC fantasy: quiet silhouette, natural material wear, mineral hues, directional light and ample negative space. The language system is still physical and diegetic. The gas station's strangeness is more effective when the traveler has to *discover* it.

The world is 256 m square (±128 m from origin). Regions are linked by walking paths and recognizable landmarks rather than a minimap or teleport lobby.

## Canonical geographic anchors

| Region | World X,Z | Use |
|---|---:|---|
| First Words clearing | 0,26 | Arrival, early reading, first language |
| Village and working market | 12,15 | Baking, forge, farming, real social speech |
| Hermit's cottage | 29,8 | Textured domestic architecture |
| Broken priory | 4,-35 | Ruin, learning and eerie weathering |
| Medieval castle/archive | -49,44 | Stone mass and old manuscript |
| Vale Fuel | -102,77 | Modern roadside oddity, separated by ~62m |
| Stillwater Lake | 79,-60 | New terrain depression, lake and fishing jetty |
| Hunter's blind | 83,-27 | Raised timber silhouette |
| Tumbled tollgate | 51,-47 | The old eastern route |
| Charcoal kiln | 50,-21 | Burned stone and abandoned labor |
| Seven Witness Stones | 76,49 | Quiet northern landmark |
| Windbroken orchard | approximately 100,-8 | Weather history and dry deadwood |
| Last Measured Mile | -79,68 | Road sign without a quest arrow |

The castle, market, priory, cottage and old player spawn have **not** moved. Existing saved spell targets, social IDs and ecological UID order remain authoritative. Decorative additions do not mint new simulation IDs.

## Terrain / material grammar

- **Meadow:** muted mixed grasses with dusty warm soil showing in open patches.
- **Woodland:** darker humus, leaves, moss and cool greens; avoid a solid green carpet.
- **Dry heath:** pale ochre grasses, exposed soil, weather-worn stems.
- **Village:** compressed earth, wheel ruts, grit and dark footfall near actual buildings.
- **Old road:** low-saturation stone-black, worn shoulders, no gleaming modern asphalt.
- **Priory/castle:** desaturated limestone, broken shale, moss-in-grooves.
- **Stillwater:** dark silt at shore, grey wet stones, reed crowns, peaty slate water.

Ground is one physical mesh and one height-map collider, with a six-sampler shader for seamless blends and a material pigment variation measured in *subtle* percentages. It must not place different colored square planes next to one another. Water is a surface above a carved floor. Wildlife navigation excludes deep water.

## UI material grammar

Palette, as actually implemented in `scripts/visual_language.gd`:

| Material | Hex | Role |
|---|---|---|
| Cold iron | #171b1b | Panel background |
| Charcoal | #242727 | Secondary help/surface |
| Aged brass | #ad9270 | Trim, names, manuscript headings |
| Bone chalk | #dbd0bb | Primary readable text |
| Smoked vellum | #c6b79f | Quiet text and grimoire |
| Bruised rust | #a96e67 | Injury/irreversible harm |
| Moss patina | #7e9183 | Natural accent, not success badges |

- Conversation is a low-lying weathered plaque with a **scrolling speech area**, compact choices and a **pinned Latin text footer**. Mouse wheel and up/down keys scroll longer lines without breaking FPS mouse capture.
- Interaction prompts use a small, contextual centered iron plaque, hidden when unneeded.
- Status indicators are bottom-anchored and appear on health/stamina change; not always visible.
- Introductory help appears on demand. No screen-filling level/tutor overlay.
- The real 3D grimoire uses worn oxblood leather, bronze hinges and dull vellum illumination with dark serif ink. Its recall, manuscripts, journal and experimentation use one object, not separate UI skins.
- Text may be rough in texture, but never low in contrast. Legibility outranks decoration.

## Regional art QA

The acceptance artifact is **actual Godot GL Compatibility capture**, not a mood board. `tests/outer_vale_gallery.gd` captures 13 views at 1280×720: lake overlook, reed shore, physical jetty, station approach, forecourt, old road, stone circle, orchard, tollgate, worn help, survival, typed conversation, and physical grimoire.

The release gate also tests the 256m render/collision bounds, six material uniforms, station separation, attendant position, physical jetty, actual lake depth, wildlife water exclusion, landmark presence, and old save continuity in `tests/outer_vale_test.gd`. The UI test checks bounded panels, bottom-anchored status, readable typed Latin and consistent grimoire ink.

A passing script is *necessary but not sufficient* for visual sign-off. Inspect the final PNGs for clipped labels, overly uniform terrain, exposed lake walls, impossible shoreline heights, flat road intersections, texture aliasing and scenery that looks unrelated to its neighbor. Do not claim this alpha is finished conceptually because 13 screenshots rendered.
