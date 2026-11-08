# VERBA — staged delivery / acceptance criteria

## Milestone 0: project setup and audit

- Inspect legacy source (do not merely restate this document). Check Godot availability locally; install only with user permission when necessary.
- Create `godot/project.godot`, main 3D scene and clean structure. Make it actually launch.
- Include `godot/README.md` with Windows launch steps, engine version and controls. Preserve legacy files unchanged.

## Milestone 1: tactile first-person vertical slice (priority)

- WASD+Shift movement; mouse turn left/right, look up/down; click capture; Escape releases; opening book/casting releases cursor intentionally then restores play. Player can move around meaningful geometry with stable collision.
- Raise a *physical* book into first person. Read a page containing at least six accurately labeled Latin spell words; close/turn pages, maintain readable legibility while walking stops; no static fullscreen book modal.
- Type `ignis` in a deliberate casting mode and press Enter. Cast occurs once, visibly succeeds, changes the world, and raises **IGNIS** in 3D coordinates. Type an invalid word: show useful failure, no effects. Repeated use without opening book becomes mechanically faster and visibly tracked.
- Hold/inspect/use at least one item with a recognizable textured model and visible hand/animation.
- World looks intentionally retro-stylized, with modeled trees/rocks/ruins and textured materials; no grid of featureless cubes.

## Milestone 2: ecological sandbox

- Two different animated animals, at least one predator-prey interaction, flee from flames, react to player and weather.
- Spells `ignis` (fire), `pluvia` (rain), `cresce` (growth) and `fuge` or `veni` (behavior) interact, producing at least two cascading emergent outcomes: e.g. rain suppresses fire, growth increases fuel/food, fire causes flight, flight changes predator encounters.
- Add deterministic random seed for testing, optionally exposed in debug-only tools. Ordinary game retains surprising outcomes.
- Log meaningful developer-facing state changes for debugging without cluttering the player's HUD.

## Milestone 3: language progression and polish

- Manuscript word pickup adds entry to grimoire and persists across restart. Never automatically casts from grimoire.
- More spells and grammar-rich commands, with validated Latin forms and accurate feedback.
- Improved animated page turns, rigged models, movement/sound/foliage/lighting, performance profile and input/accessibility controls.
- Export a Windows build **only after** confirming engine version and required export templates.

## Manual acceptance test matrix

1. Launch new game. Walk in all four directions. Move mouse both horizontally and vertically. Camera rotates smoothly, without stuck axes or drift. Pass through a door/around a tree; collisions behave.
2. Press G, see actual book/arms. Page-turn twice. Move camera: the book remains coherently in player's hands. Close, regain mouse-look.
3. Press Enter, type `ignis`, press Enter. One spell casts. World text appears near casting point, rises, and can be seen from a changed viewpoint; it is NOT pinned to the screen. Fire affects a world object.
4. Type a typo; show error feedback. Cast successful words again without consulting book; observe recall progression.
5. Pick up a stone/lantern; visible in hand. Use and drop/put away. Inventory updates correctly.
6. Cast `pluvia` onto/near fire. Wetness/rain changes fire survival. Cast `cresce`; vegetation changes. Startle an animal with `fuge` or fire; animal changes behavior coherently.
7. Find a loose folio, pick it up, open physical book and see it added. Quit/restart and verify saved entry.
8. Test alt-tab, window resize, mouse pointer release/re-capture, pause and low frame rate; no lost input or duplicate cast.
9. Visual pass: verify actual in-engine screenshots. No claims of high-quality visuals without inspecting rendered output. Avoid placeholder geometries as the final milestone visuals.

## Reporting standard

For each milestone provide (a) files changed, (b) how to run, (c) what was actually tested and results, (d) known defects, (e) next step. Update `CHANGELOG.md` and `KNOWN-ISSUES.md`. Do not use phrases like 'fully tested' without specific evidence. Do not ask for confirmation between obvious development steps unless installation/permission is required.
