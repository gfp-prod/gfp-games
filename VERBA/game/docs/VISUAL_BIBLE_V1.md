# VERBA — v1.0 visual bible

**Art direction:** late-1990s to early-2000s PC/PS2 dark-fantasy RPG, not flat mobile-game low-poly. Atmospheric rather than noisy, textured rather than glossy, subdued rather than monochrome, deliberately modeled rather than primitive spam.

## Spatial composition

1. A visually comprehensible path between first-words cairn, cottage and priory.
2. One large silhouette and several breathing spaces per area, rather than equal-sized repeated models.
3. Elevation changes must be traversable and visually obvious; keep camera-height sightlines.
4. Tree clusters should frame rather than hide landmarks. Creature silhouettes must read at middle distance.
5. No large white or untextured ground areas. Ensure texture and shading under GL Compatibility renderer.

## Architectural rules

- Cottage wall bays have actual door/window openings; don't stamp doors onto uninterrupted cubes.
- Material identity: pale chipped plaster, weathered dark oak, irregular stone plinth, dark staggered slate, tarnished forged metal.
- Visible roof underside/ridge and physical tiled edge, solid roof underlayer, lintels, shutters, and architectural joints.
- Interiors must eventually support physical interaction. Until collision is stabilized, maintain basic enterable sightlines.

## Creature rules

- At 10 meters, antlered stag, long-tailed wolf, pointed-eared fox, long-eared hare and black crow must all distinguish clearly.
- Articulate limbs/wings independently from toros and heads, not object-wide wobble.
- Paws, hooves, ears, jaw planes and undercoats create visual information without overdraw.
- Creature state should remain independent of its render: hunger, health, fear, growth and wetness must work if its model is replaced.

## Grimoire

- Physical closed/on-open states with leather grain, brass corners, spine, stitched page blocks and a clasp.
- Raise when selected, open in-hand, physical page surfaces carry the Latin, lower when deselected.
- The player is rewarded for *remembering* spells: minimal interaction cost outside the grimoire.

## Materials and light

- Real 1K+ diffuse and OpenGL normal textures from CC0 sources where available. Bundled art retains fallback materials.
- Avoid blown-out white terrain: restrained direct light, cooler shadows, moderate atmospheric fog, texture albedo near middle values.
- Favor readability over expensive or unrealistically detailed shaders. World must remain playable with Godot GL Compatibility on modest hardware.

## Next art acceptance test

Take in-game screenshots (1) approach to cottage, (2) inside cottage, (3) deer and wolf at conversational distance, (4) open grimoire, (5) riverbank. Evaluate silhouettes, proportion, textures, frame rate and interactions before considering artwork approved.
