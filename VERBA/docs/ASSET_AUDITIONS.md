# VERBA — Asset audition results (before integration)

A free asset isn't automatically an appropriate asset. Record actual Godot screenshot comparisons before bundling a model in the live game.

## KayKit Forest Nature Pack (packed by Station Sciences) — REJECTED
- **Date:** November 10, 2026.
- **Source:** [Station-Sciences/bot-crossing](https://github.com/Station-Sciences/bot-crossing/tree/9f7dc6536aacbce2203bb705e3f0cf1772ea3fb7/public/assets). KayKit's original free *Forest Nature Pack*, CC0 1.0. Valid provenance and geometry; no license objection.
- **Audition:** [Godot real-OpenGL preview CI](https://github.com/gfp-prod/gfp-games/actions/runs/42886741608). Generated seven actual 3D captures of named bushes, grass, rocks and a tree. Model itself imported without error.
- **Art verdict:** Reject. Bush silhouettes are round neon-green blobs, rocks have flat simplistic faces, and the short tree has disproportionate trunk/canopy. The appearance resembles a bright mobile game, which conflicts with the weathered storybook late-PS2/early-PS3 style.
- **Decision:** Do **not** integrate meshes into the runtime world, and **remove** the unused audition asset from the working game. This is a test of quality gating, not a reason to add more props.
- **Next source direction:** more physically detailed foliage and low evergreen undergrowth from compatible Quaternius models or an established forest kit, with material tinting and actual player-eye previews, not raw bright gradient atlases.

## Poly Haven photographic ground materials — ACCEPTED FOR TERRAIN
- **Source:** [Poly Haven](https://polyhaven.com/our-api), CC0, source URLs and SHA256 in `game/assets/textures/real/SOURCES_MANIFEST.json`.
- **Integration:** Ten real photographic material diffuse maps, available normal maps, and offline-baked terrain color atlas, all bundled in Godot. No manual installer.
- **Audition:** [Godot OpenGL screenshots](https://github.com/gfp-prod/gfp-games/actions/runs/42885854817). The seam removal worked, but the first version was too dark and underwent a second source-asset color grade.
- **Limitations:** This repairs terrain material continuity; it does not yet create beautiful foliage, art-directed landmarks or a complete game-quality world. Further staging remains necessary.

## Physical grimoire — IN REVISION
- **Source:** original in-project articulated geometry, original textured parchment revised through `tools/grade_vellum.py`.
- **Observed issue:** Previous gold-yellow page wash and oversized full-screen panels were aesthetically poor.
- **Adjustment:** smaller in-hand silhouette, muted cream paper, visible linen gutter, serif ink labels; approve only after actual Godot camera review.
