# VERBA — gameplay and art direction

## Experience

The player explores an immersive first-person fantasy ecosystem in which **knowing Latin grants power**. The magic system doubles as a naturalistic mnemonic tutor: the world's possibilities grow with the player's genuine vocabulary and understanding of grammar. No memorization quizzes disguised as combat; no autocast from a word list. The most successful player will eventually cast faster because the words have become second nature.

### Loop

Explore a richly modeled but compact vale → observe creatures / discover unusual interactions → find manuscripts/inscriptions → collect the word in the grimoire → raise the physical book, leaf through illustrated pages, study it → lower book → type Latin from memory → see the correct word materialize and rise in the actual world → watch environmental consequences → learn by experimenting.

### Core magic

Spells influence **properties and processes**, not scripted one-off cinematic scenes. Fire is ignition; rain adds wetness and dampens fire; growth changes plant cover and available food/fuel; command spells target individual living things, varying by grammar, temperament and distance. Rare wild-magic perturbations follow the simulation's rules and can cascade naturally. Preserve wonder and unpredictability; do not turn the system into mere particle effects.

### Creatures

Start with two grounded animal species (e.g. hare and fox) whose silhouettes and cycles are readable. They must have needs or behavior states (idle, wander, feed, flee, pursue). From here add deer, wolves, frogs, corvids, strange forest beings. They should react to fire, rain, light, noises, food sources, player movement, and one another. Avoid a million agents with no identity; a small ecology with systemic consequences is superior.

### Grimoire

Tangible, leather-bound object with visibly thick boards, clasp, embossed sigil, worn page edges, seams, cloth/page texture, handwritten/engraved headings, legible Latin and English glosses. A distinct hand animation raises the book from the lower frame, opens it, supports it, then flips real pages as the player reads. Pages should not look like floating UI planes detached from the book. Avoid occupying the whole screen with a flat overlay. Word entries should appear ONLY when learned/discovered (or guessed by accurate casting). Preserve a familiar reading cadence and an efficient page-flip interaction so regular references are painless but slower than recall.

### Spell visual

Correct Latin incantation forms letters/inscription in nearby 3D space, perhaps emanating from the player's hands/point of power, ascending in the world, passing in front of or behind geometry as physically appropriate, then fading. Use material/shader effects and 3D text/meshes; no browser overlay pretending to be world text. Test against camera movement and occlusion: the lettering must stay in world coordinates, not follow the HUD.

### Items

Pick up, equip, hold, inspect/use, drop. Lantern light casts actual illumination; stones can startle animals when thrown; herbs can help injured creatures; a wand/staff or spell focus may later serve as a tangible casting implement. Physical appearance should communicate materials and action, with restrained procedural animation/bobbing.

## Visual brief

- 3D first person. Retro RPG, early-2000s PC/PS2 atmospheric fantasy; **not bright flat mobile low-poly**.
- Authored naturalistic stylization: convincing bark/stone/earth, silhouettes, readable creature anatomy, tiny color variations, deliberate texture repetition, convincing object scale.
- Landscape: dense layered grass/ground cover, mature forest canopy with depth, roots and moss, stone ruins, old shrines, puddles/stream, wildlife paths, leaf litter.
- Palette: earth, muted moss, cold mist, tarnished metals, warm parchment and ember light. Mood is curiosity, old magic, desolation, quiet dread; sunlight still has room to be lovely.
- Cohesive low/medium-poly topology with deliberate UV mapping, texture filtering and limited resolution where aesthetically useful. 'Retro' is an artistic constraint, not permission for placeholder cubes.
- Game should feel like a small explorable RPG area, with atmosphere and visual discovery—not a flat feature-demo arena.
- Asset provenance must be recorded; use self-authored or permissively licensed assets, without imitating copyrighted models or textures exactly.

## Language system accuracy

Existing 28 spell strings include Latin nouns used as standalone invocations (`ignis` fire, `pluvia` rain, `aqua` water, etc.), actual singular imperatives (`cresce`, `muta`, `fuge`, `dormi`, `veni`), and phrase commands (`ignem exstingue`, `arbores crescite`). Do not claim all strings are imperatives. Build a lexicon with grammar metadata; verify Latin against reliable references before expanding. The eventual progression should teach nominative/accusative, imperatives, number and agreement through useful in-world actions. If interpreting a phrase, require the intended grammatical structure and provide helpful feedback for mistakes.

## Not requested yet

No monetization, social features, live service, online API dependency, procedural AI text generation, massive open-world map, RPG skill tree, linear tutorial or sprawling quest framework. Make the core activity richly interactive first.
