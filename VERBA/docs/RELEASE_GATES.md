# VERBA release gates and current verification

**GitHub source:** `VERBA/game/` on branch `verba-godot`, with all authored models and photo-derived textures in the repository. No asset-fetch script required.

## Automated gates

1. **Complete source and bundled assets:** PASS — project.godot, main.tscn, source, 8 authored GLB models and 18 photo-derived texture JPEG files.
2. **Godot cold import and parse:** PASS — CI with Godot 4.5.2 headless.
3. **Runtime smoke test:** PASS — main scene, world, player, grimoire, wildlife and lexicon instantiated.
4. **Ecology states:** PASS — 270 independent objects, growth/wetness/fire/rock state, grazing and tick update.
5. **Physics movement:** PASS — simulated WASD forward moved ~2.49 m while grounded.
6. **Navigation setup:** PASS — navigation region and animal route planners available.
7. **No installer requirement:** PASS — fallback textures, art, and game source are bundled.

See the [successful test run](https://github.com/gfp-prod/gfp-games/actions/runs/42492659782).

## Not verified by automation

- Actual mouse-look and input on the user's PC
- Full physics collision with every building wall and every tree
- Unstuck cases involving interacting animals or complex obstacles
- Graphical quality of cottage, creatures, and grimoire in the Windows Godot renderer
- Framerate/graphics performance on user hardware
- Authentic scanned PBR assets; bundled JPEGs are photo-derived and may need replacement

**Release status:** engineering baseline verified, art and PC gameplay acceptance pending. Do not call this a final-quality RPG build.

## Future acceptance tests

- Windows gameplay capture covering mouse-lock, WASD, spellcasting, grimoire and creature interactions
- Collider test around cottage, rocks, and representative trees
- Navigation tests with animals routing between world regions
- 60-second in-engine visual performance and rendering inspection
