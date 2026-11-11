# VERBA — Gameplay Milestone 09: Gather, Build, Preserve, Play

**Completed:** November 11, 2026 · **Branch:** `verba-godot` · **Engine:** Godot 4.5.2

## Why this milestone matters

The previous milestone connected Latin reading to people, animal companionship, and survival. This milestone gives inventory and exploration a **lasting physical purpose**: make a small piece of your own tower from materials gathered in the world, with actual collisions and permanent saved identity. This is only the beginning of Phase 5, **not** the promised two-level customizable wizard tower.

## What was actually implemented

- **Gather wood:** the existing physical cottage woodpile is now a harvestable object, with an interaction collider and a finite twelve-piece stock. Look at it and press **E**. Depletion persists, so reloading doesn't generate infinite lumber.
- **Gather stone:** physical stone objects in the environment supply up to three units per deposit. Both stone and timber occupy slots in the existing limited six-item inventory and have physical held/dropped objects.
- **Place pieces:** press **V** to enter building mode; aim at a world location to move a transparent snap preview. **1** selects foundation, **2** a wall, **3** a bookshelf, **R** rotates the wall, left-click commits, and **V/Esc** exits. The system uses a three-meter snapped grid, initially within a bounded reach of the first foundation. It's grounded in the existing first-person aiming system, not a detached craft menu.
- **Actual item costs:** foundation consumes 1 stone + 1 wood, wall consumes 2 wood, shelf consumes 1 wood. Insufficient, duplicated, too-distant, unsupported, or obstructed placements consume nothing.
- **Physical construction:** every floor, wall and shelf is added to the live Godot 3D world with a real static collision shape. The first floor has ground-reaching feet to accommodate rough terrain; walls require floors.
- **Save/load:** each part has a deterministic sanitized node identity and is serialized as kind, 3D grid coordinate and orientation, not an invalid engine pointer. Restoring the world recreates the visible meshes and collision shapes. Older world saves with no building/harvest history load without inventing constructions or material counts.
- **Portable Windows export:** a separate Godot 4.5.2 Windows x64 export preset and GitHub Actions workflow generated a real `VERBA.exe` alongside its `VERBA.pck`, packaged with a standalone README. Godot's Windows exporter explicitly supports a separate PCK; this avoids unnecessary PCK embedding (and reduces antivirus false-positive risks). The unsigned package is an **alpha** and must not be represented as a code-signed Windows installer.

## Verified gates

- [Construction gameplay end-to-end test run](https://github.com/gfp-prod/gfp-games/actions/runs/43013574413): **passed**, including source extraction, correct inventory cost, physical collision, save/reload and old save compatibility. This test also found a real Godot node-name normalization issue (`:` in collision names) that was fixed by changing constructed IDs to underscore-delimited names.
- [Full Godot regression after adding export preset](https://github.com/gfp-prod/gfp-games/actions/runs/43013607208): **passed**.
- [Full Godot regression after new tower visual test](https://github.com/gfp-prod/gfp-games/actions/runs/43014107856): **passed**.
- [Windows portable build](https://github.com/gfp-prod/gfp-games/actions/runs/43013685164): **passed**, with valid PE32+ Windows `.exe`, separate `.pck`, checksummed ZIP artifact.
- [Visual rendering workflow](https://github.com/gfp-prod/gfp-games/actions/workflows/verba-visual-qa.yml): creates actual `tower_first_room.png` and `tower_moonlight.png` screenshots from live Godot parts in the world. Do not claim aesthetic approval without inspecting both.

## Known limits / next production work

1. **Construction depth:** roofs, windows, doors, stairs, stacked levels, book placement, and arbitrary decorations. A bookshelf currently exists as a collidable furnishing, but a book cannot yet be visibly shelved.
2. **Harvester realism:** a finite salvage interaction currently doesn't require an axe or play a full animation. That is a conscious prototype choice, not a final design. Future resource economy should tie wood and stone to physical ecological object damage and time.
3. **Tower site freedom:** players may begin a tower in multiple open locations on the valley grid, but adjacent cells are limited to the same plot and streamed regions are not available. Validate overlap and site grading in more varied terrain.
4. **World adventure:** the medieval castle/gas station/village/ruin loop from the main plan is still incomplete. This remains a starter valley with one hermitage and existing ruins.
5. **NPCs/familiars/hostiles:** two dialogue NPCs, two familiar options, one new wolf player-threat behavior. Their artistic/behavioral depth remains limited.

**Priorities:** extend first floor into a multi-story tower → physically place found books on shelves → build the station/castle crossroad and inhabitable village → broaden verified Latin beyond the three starter books and implement new subject-specific spells → add NPC schedules and richer threats. Avoid another decorative cottage pass until the new building loop is real enough to matter.
