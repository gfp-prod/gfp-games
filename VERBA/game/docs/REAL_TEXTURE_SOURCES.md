# Real photographic texture sources

The Windows installer `GET_REAL_TEXTURES.bat` uses [Poly Haven's public API](https://polyhaven.com/our-api) to download actual **CC0** textures. These are photographic/photogrammetry-based assets, not AI-created texture approximations. The files are **not yet bundled in the ZIP** because the build environment cannot download their binary images. They are installed locally when the user runs the included installer and Godot imports them.

| VERBA material | Source asset | License |
| --- | --- | --- |
| Meadow | [Sparse Grass](https://polyhaven.com/a/sparse_grass) | CC0 |
| Woodland | [Forest Ground 01](https://polyhaven.com/a/forrest_ground_01) | CC0 |
| Autumn grove | [Forest Leaves 04](https://polyhaven.com/a/forest_leaves_04) | CC0 |
| Creek stone | [Rocks Ground 01](https://polyhaven.com/a/rocks_ground_01) | CC0 |
| Dirt path | [Dirt Floor](https://polyhaven.com/a/dirt_floor) | CC0 |
| Stone | [Rock Surface](https://polyhaven.com/a/rock_surface) | CC0 |
| Tree bark | [Bark Brown 01](https://polyhaven.com/a/bark_brown_01) | CC0 |
| Moss-covered stones | [Concrete Moss](https://polyhaven.com/a/concrete_moss) | CC0 |

Downloads install 1K JPEG albedo and OpenGL normal maps (where provided) using the API's download URLs and MD5 hashes. Users can re-run the downloader safely. All 3D visuals retain fallback materials if a download fails. **Powered by Poly Haven** — https://polyhaven.com/

**Note:** photographic materials improve surfaces, but models, UV mapping, foliage silhouettes, lighting and character anatomy require separate artistic improvements. This release is primarily a critical locomotion/ground-rendering correction with actual materials integration, not finished art.

## Added in v1.0 (verified source pages)

| Authored cottage material | Source | License |
| --- | --- | --- |
| Exterior plaster | [Plastered Wall](https://polyhaven.com/a/plastered_wall) | CC0 |
| Timber beams / boards | [Wood Planks](https://polyhaven.com/a/wood_planks) | CC0 |
| Roof cladding | [Roof Slates 02](https://polyhaven.com/a/roof_slates_02) | CC0 |

The optional installer now downloads these three extra photo-material pairs, and the cottage asset's Godot mesh instances select them if present. The model **ships with generated textures for offline play**; no photos are misrepresented as bundled. Poly Haven credit: https://polyhaven.com — Powered by Poly Haven.
