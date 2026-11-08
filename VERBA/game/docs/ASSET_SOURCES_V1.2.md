# VERBA asset sources — v1.2

The optional external art script downloads assets from verified public sources.

## Geometry
Quaternius, *Stylized Nature MegaKit* — CC0 1.0. Four individually converted GLB files (tree1.glb, tree2.glb, tree3.glb, bush.glb) are mirrored with source credit and a license in [anshaneja5/skyline-run](https://github.com/anshaneja5/skyline-run/blob/main/CREDITS.md); original pack at [Quaternius](https://quaternius.com/packs/stylizednaturemegakit.html). The installer fetches the actual `.glb` bytes from GitHub via static HTTPS URLs. v1.2 uses the three trees when installed, normalizing each to a specific scene height. Other assets are retained for a later art pass.

## Textures
[Poly Haven](https://polyhaven.com) — CC0 photographic texture maps served through its [public API](https://api.polyhaven.com): `forrest_ground_01`, `forest_floor`, `bark_brown_01`, and `wood_planks`. The installer fetches 1K JPEG `Diffuse` and `nor_gl` maps from the API and replaces the existing sample textures only after a validated download. The textured terrain, bark and cottage wood then use those files at runtime. Files remain local, no API calls are made while playing. **Powered by Poly Haven.**

## Constraints
The art resources above are downloaded **on the player's machine**, not bundled in the ZIP. If external URLs change or Internet access is restricted, the installer prints failures and preserves the bundled fallbacks. Avoid presenting optional files as already downloaded or inspected in Godot.
