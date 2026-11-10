VERBA: Bundled CC0 photographic surfaces, sourced November 10 2026

These are ACTUAL 1K Poly Haven photographic textures fetched by a reproducible
GitHub Actions build, resized and saved to stable paths. No user-side installer
or runtime HTTP calls are required. The provenance manifest contains per-file
source URLs, asset IDs, license and SHA256:
    SOURCES_MANIFEST.json

Base material categories:
 meadow_ground: Poly Haven sparse_grass
 woodland_ground: Poly Haven forrest_ground_01
 amber_ground: Poly Haven forest_leaves_04
 river_silt: Poly Haven rocks_ground_01
 earth_path: Poly Haven dirt_floor
 stone: Poly Haven rock_surface
 moss: Poly Haven concrete_moss
 cottage_plaster: Poly Haven plastered_wall
 cottage_wood: Poly Haven wood_planks
 cottage_roof: Poly Haven roof_slates_02

vale_terrain_blend.jpg is an OFFLINE generated, smooth, world-aligned mix of
the five CC0 photo textures used as terrain surface materials, produced by
tools/bake_vale_terrain.py. See VALE_TERRAIN_BAKE.json for inputs and hashes.

2 invalid / missing photographic normal files were rejected:
 woodland_ground_normal.jpg and river_silt_normal.jpg. The game uses the
diffuse source maps normally without those normal maps. This is intentional;
zero-byte images are not accepted.

Texture assets: Creative Commons Zero 1.0 (CC0) - source https://polyhaven.com
Source API: https://api.polyhaven.com
VERBA includes attribution to preserve clear source provenance; CC0 doesn't
require copyright attribution. The API was only used at authoring/build time.
