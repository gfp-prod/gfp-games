# Photographic material provenance — v1.1

**Included in the build, no download required**

Input photos:
- `scikit-image/skimage.data.grass()` (original CC0 photograph, grayscale grass patch) → `meadow_ground`, `woodland_ground`, `amber_ground`, `moss`.
- `scikit-image/skimage.data.gravel()` (original from CC0Textures, CC0 gravel image) → `stone`, `river_silt`, `earth_path`.
- `scikit-image/skimage.data.brick()` (original from CC0Textures, CC0 brick masonry image) → `cottage_plaster`, `cottage_roof`.

Each output has `*_diffuse.jpg` and `*_normal.jpg` in `assets/textures/real/`. The normal map is derived from the source photograph's intensity gradient; it is **not** a measured displacement scan. The grayscale photo is color-graded to fit the environment. All diffuse images are 1024×1024 (mirrored tile). This is a meaningful step up from a single colored face, but more sophisticated 2K PBR assets will improve final results.

Official original documentation and CC0 provenance: https://scikit-image.org/docs/stable/api/skimage.data.html

Real PBR alternatives for later art work (not included here): https://polyhaven.com/textures and https://ambientcg.com/

IMPORTANT: The older `INSTALL_CC0_TEXTURES.ps1` is an **optional** external downloader, not part of the required game setup. You do not have to run it. The photo maps we installed take priority over the old authored fallback maps on launch.
