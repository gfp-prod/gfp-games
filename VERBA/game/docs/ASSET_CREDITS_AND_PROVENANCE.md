# VERBA v0.7 — Art provenance and material rights

The v0.7 terrain, grass, foliage, moss, stone, bark, roof and leaf imagery is generated **by the code shipped with this project** (`tools/paint_textures.py`) using deterministic palettes and mathematical shapes. These assets require no external attributions and may be modified or redistributed as part of the game. The pre-existing original `wood.png`, `leather.png`, `vellum.png` remain from the earlier VERBA project.

The project does **not** include downloaded ambientCG or Poly Haven textures. We investigated both for potential CC0 assets, but their archive servers were not accessible from the build environment. Future production use may replace individual original textures with verified CC0 licensed PBR maps from:
- https://ambientcg.com/ — CC0 texture library
- https://polyhaven.com/textures — CC0 texture library

**Art intent:** restrained stylized late-PS1 / early-PS2 dark-fantasy setting with visible painted surface detail, sharp silhouettes, multi-layered plant shapes and credible terrain zones. Not hyperreal photogrammetry. The grass, leaf and stone models are implemented as actual geometry in `scripts/foliage.gd`, `scripts/art.gd`, and `scripts/world.gd`.

No AI-generated third-party mesh assets have been silently inserted. All meshes in this release are native Godot procedural meshes.

## New authored v1.0 asset workshop

All eight `assets/models/authored/*.glb` models and nine new `assets/textures/authored/*.png` surfaces were produced specifically for VERBA with the included Python 3D geometry/texture source at `tools/build_authored_models.py`; no third-party downloaded animal or building mesh was passed off as original. Original generated textures are not photographs. Optional photographic material downloads for cottage plaster, timber and slate are sourced from the Poly Haven CC0 pages identified in REAL_TEXTURE_SOURCES.md. For gameplay art acceptance, compare the included offline render contact sheet with screenshots from the native Godot engine.
