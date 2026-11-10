# VERBA — The Hollow Vale (Godot source)

Open `project.godot` in Godot 4.5+ from an **extracted permanent folder**. The project's imported 3D models, tree textures and photographic ground materials are bundled. Do not use a separate asset installer.

## Working gameplay
- WASD/mouse FPS controls, collision, jumping, physical held grimoire and usable inventory.
- Enter → type → Enter casts Latin spells. The grimoire records recognized forms for later recall.
- Singular/plural imperative grammar: `cresce/crescite`, `veni/venite`, `dormi/dormite`, `fuge/fugite`, `siste/sistite`, `muta/mutate`, `arde/ardete`, `surge/surgite`.
- Optional vocative addressees: `cresce arbor`, `crescite arbores`, `veni lupe`, `venite lupi`. Incorrect number agreement is rejected.
- Several nearby objects/creatures can respond to plural speech. Fire and water operate on the same object moisture/heat as weather.
- Independent objects and animals persist via `user://verba_living_world_v1.json`. Automatic saving happens in the graphical game about every 45 seconds. Open the grimoire (G), then S save or L reload.
- Physical inscribed Latin tablet beside the starting cairn encourages discovery.
- Forests are grouped into curated stands around roads, structures and a visible clearing.

## Validation
GitHub Actions runs the real Godot engine headlessly for startup, ecology, movement/navigation, Latin grammar, world state persistence and deterministic material exchange. A second workflow starts Godot in an OpenGL virtual display and produces *actual* world/animal screenshots and animation previews, with a pixel-based distortion gate.

**Known limitations:** This is an early vertical slice. Visual fidelity, creature animation quality, house geometry and structural destruction still require substantial work. A first-person screenshot review is evidence, not approval of the final art direction.

See `../README.md` for complete usage and links to workflows.
