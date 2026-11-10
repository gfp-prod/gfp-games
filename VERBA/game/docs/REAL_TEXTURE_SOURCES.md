# VERBA photographic materials — bundled CC0 sources

**Updated November 10, 2026.** Previous instructions suggesting users must run `GET_REAL_TEXTURES.bat` are obsolete. The texture files are now downloaded, validated, bundled and imported directly within the Godot project through GitHub Actions. The game has no texture network dependency and requires no asset installer.

## Source and license

Original photographic surface maps: [Poly Haven](https://polyhaven.com), CC0 1.0. Source asset identifiers, original downloadable URLs, local paths, byte counts and SHA256 checksums are stored alongside the files in `assets/textures/real/SOURCES_MANIFEST.json`. All download and conversion happens at build time via `tools/fetch_polyhaven_cc0.py` and `.github/workflows/verba-cc0-materials.yml`.

| In-game surface | Poly Haven asset ID | Current role |
| --- | --- | --- |
| Meadow | `sparse_grass` | Grass/turf segments in baked terrain atlas |
| Woodland soil | `forrest_ground_01` | Damp earth and leaf shadows |
| Autumn/leaf litter | `forest_leaves_04` | Weathered orange grove terrain |
| Creek/riverbank | `rocks_ground_01` | Stony wetland |
| Worn road | `dirt_floor` | Baked physically flat trail |
| Stone | `rock_surface` | Rocks, walls, masonry |
| Moss | `concrete_moss` | Mossy boulders |
| Plastered wall | `plastered_wall` | Cottage plaster |
| Wood | `wood_planks` | Cottage joinery |
| Roof | `roof_slates_02` | Cottage slate |

The five terrain materials are blended via the offline `tools/bake_vale_terrain.py` at 3072×3072 pixels into `assets/textures/real/vale_terrain_blend.jpg`, used by the single continuous world ground mesh. Baked-atlas hashes, world extent and individual input SHA256s live in `VALE_TERRAIN_BAKE.json`. The collision heightmap remains independent and unchanged.

**Normal maps:** eight valid source normal maps are bundled. Woodland and creek source normal maps produced unusable zero-byte files in the external asset service; those are absent by design (no fake successful imports). Albedo still works.

**Quality disclaimer:** Source-photo realism does not guarantee a beautiful landscape. Texture placement, foliage, composition, light, building and creature art require separate review. Screenshot CI checks actual Godot renders.

**Credits:** Powered by Poly Haven, https://polyhaven.com/. API used only to source assets; runtime is entirely offline.
