# VERBA — Godot development build v1.2.1 (bundled, no installer)

**No asset installation required.** All models and textures required by this project are included in its `assets/` directory. Open `project.godot` in Godot 4.5 or later, click Edit, allow resource import, then F5 to run.

## Controls
Click the game window for captured mouse look; W/A/S/D walk; Shift sprint; Space jump; Enter to enter a spell; G grimoire; E pick up; Esc release mouse.

## What's actually included
- 8 modeled GLB assets (cottage, 5 animals, open/closed grimoire)
- 18 photo-derived JPG materials in `assets/textures/real/`, with their diffuse and normal channels.
- Locally generated PNG materials, procedural trees and foliage as fallback visuals.
- Physics-based player and animal collision, ecology and preliminary navigation scripts.

## Important art limitation
This package does **not** include externally downloaded Poly Haven material scans or the Quaternius/third-party tree models. The 18 existing photo-derived materials were already inside v1.2; they are NOT falsely presented as Poly Haven scans. Public-asset acquisition must be handled through a verified automated asset-publishing pipeline, rather than a Windows `.bat` installer that may fail on the user's machine.

## Validation
Python static checks pass; Godot parser and runtime performance have not been verified in this environment. Native Godot import/runtime may surface additional errors.

## GitHub
The GitHub integration work is isolated on the `verba-godot` branch of `gfp-prod/gfp-games`. That branch currently contains tracked project documentation and build infrastructure; this local archive remains the complete playable-source bundle until the verified full project is published there. Do not confuse documentation on GitHub with uploaded engine assets.
