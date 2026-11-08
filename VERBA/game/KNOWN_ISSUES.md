# VERBA 1.1 known limitations

- Godot was unavailable here; script import, physics behavior, rendering and actual frame rate require in-engine verification on Windows.
- No baked navigation mesh yet; animals steer and slide around colliders, but may wander inefficiently into narrow dead ends. True NavigationRegion3D plus NavigationAgent3D should follow once obstacle meshes are stable.
- The cottage door currently has a collider and cannot yet be opened.
- Roof-level architectural collision is approximate; walls are simplified boxes matching the physical footprint, not per-triangle mesh collisions.
- Photographic sample maps are real CC0 photograph-derived but do not replace a complete artist-produced UV/material pipeline for the animals, trees and cottage.
- Do not claim this is a tested release until the new native Godot build is checked.
