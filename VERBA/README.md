# VERBA — The Hollow Vale

This branch contains the **complete Godot 4 project** at [VERBA/game](./game), with the eight authored GLB assets and eighteen photo-derived maps already bundled. No Windows asset installer is required.

## Open the game

1. Download this branch as a ZIP from GitHub, or clone using:
   `git clone --branch verba-godot https://github.com/gfp-prod/gfp-games.git`
2. Open Godot 4.5 or newer. Import **`VERBA/game/project.godot`** and click **Edit** to let Godot import its assets.
3. Run the scene with F5.

The only first-run processing required is Godot's normal internal asset import. **Do not run any asset download scripts.**

## Controls

WASD move; mouse look (click in game to capture); Shift sprint; Space jump; G raise the grimoire; Enter type/cast a Latin incantation; E collect an object; Esc release mouse.

## What's present, and what's not

- Project source is checked into GitHub under `VERBA/game`; original full ZIP is reconstructed by `verba-expand.yml` from the stored packed archive segments.
- Eight original modeled assets include cottage, deer, wolf, fox, crow, hare, and open/closed books.
- Eighteen **photo-derived** material JPEGs were included in v1.2 and remain bundled. They are not claimed to be externally downloaded Poly Haven PBR scans.
- Native Godot automated validation is configured in `.github/workflows/verba-check.yml` and must pass before calling the engine build verified.

## Notes

This is still an early development build, not an art-complete RPG. Animal navigation, collision, first-person movement and game feel require native in-engine QA. Please report Godot error logs and screenshots for any failing gates.

The existing web project on `main` has not been changed. This `gfp-games` repository is public; the `verba-godot` branch is public as well.
