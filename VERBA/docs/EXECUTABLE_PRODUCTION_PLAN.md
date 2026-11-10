# VERBA — Executable Production Plan
**Planning baseline:** November 10, 2026  
**Repository:** [gfp-prod/gfp-games, `verba-godot`](https://github.com/gfp-prod/gfp-games/tree/verba-godot/VERBA)  
**Engine currently tested in CI:** Godot 4.5.2  
**Document status:** Plan and acceptance contract, NOT a claim that these milestones have been completed.

## 1. The game we're building

**VERBA is an open-ended, first-person Latin-learning fantasy survival sandbox.** Reading Latin books develops scholarly level, maximum mana, and access to different schools of magic. NPC conversations become increasingly Latin. You find and collect books, build and customize a wizard tower, survive mobs, establish simple relationships, and choose a pet/familiar. The explorable world juxtaposes the playful, eerie, mundane, and surreal: a gas station beside a castle, a village past the castle, then ancient ruins. The world is free to wander; there is no compulsory linear quest or one correct career.

A good five-minute session might be: walk through a meadow, greet a merchant, read a simple Latin passage, learn a verb, cast it on a real plant, and watch an animal react. Another might be defending a tower from a roaming monster or discovering a disturbing ruin beyond a cheerful village. Magic alters persistent material/creature state rather than summoning arbitrary effects unrelated to the world.

### Constraints to protect
- **Learning is power.** Books/reading comprehension grant scholar XP and increase mana capacity; practicing and retaining real Latin unlocks more sophisticated magic. Never reward endlessly opening the same page.
- **Physical world first.** Colliders, scale, terrain, navigation, held book, materials, creature animation, and real-world object states must be credible.
- **Wandering is the game.** Places are discovered rather than automatically announced as quests. No hard-coded sequence from happy to dark; any region can vary by circumstance.
- **No meaningless random world spam.** Use authored location templates and intentional road/landmark grammar over seeded terrain.
- **Independent ecology.** Objects keep identity and relevant state, with level-of-detail simulation for distant regions.
- **Art quality is a release criterion.** A file that imports or plays an animation can still be visually broken.
- **Content is not dependent on online generative AI.** Runtime logic and Latin text function offline.

## 2. What actually exists already

The current GitHub branch contains one Godot valley with physics-based first-person controls, physical grimoire, a small Latin imperative + vocative grammar, 24 entries in `data/lexicon.json`, world-space incantations, a modest mutable ecology with animals and plants, fire/moisture interactions, basic wildlife, a prototype building/interior, and JSON persistence for current region objects, animals, weather, and player state.

GitHub Actions already run actual Godot engine import, gameplay/Latin/ecology/persistence tests, animal asset checks, and OpenGL screenshot/motion previews. Those tests have passed on prior commits. This project is **not** presently a full RPG, a seamless open world, a fully procedurally streamed game, or a finished environment.

## 3. What I can execute without additional plugins

- Read, edit, commit, and organize the connected **GitHub** repository and its `verba-godot` branch.
- Create Godot GDScript scenes, JSON book/creature/region data, tests, original models/textures and build tools.
- Integrate verifiable open-source code and assets from GitHub, respecting their actual licenses and attribution requirements.
- Use **GitHub Actions** to run Godot headlessly for parser/runtime/physics tests, run Godot under a virtual OpenGL display for visual reviews, and publish build artifacts when CI proves that they work.
- Review actual CI screenshots and animations before approving a replacement.

**Not presently possible remotely:** directly operate the user's Windows Godot/Blender editor or install files on their PC. Do not include it as a required step. A local Windows runner is optional, separate, and would require one explicit user install/authorization. Windows GitHub Actions provides an alternative test environment without access to the user's PC.

**New plugins required for this plan: NONE.** GitHub access is already connected. Avoid treating unknown plugins as future prerequisites.

## 4. Reuse-first policy (code and assets)

Stop reimplementing ordinary game infrastructure without a reason. Adopt an external package only if it (a) solves a defined missing task, (b) is compatible with the project's tested Godot version, (c) has clear source/license, (d) can be vendored/pinned in GitHub, and (e) passes a Godot compatibility scene + regression suite. Keep a LICENSE/ATTRIBUTION ledger for every dependency and copied asset. Attribution and license terms still apply to private games.

**Concrete candidates inspected November 10, 2026:**

| Project | Candidate use | Evidence/status | Action |
|---|---|---|---|
| [Dialogic 2](https://github.com/dialogic-godot/dialogic) | Character dialogue, branches, flags, dialogue events | MIT, project README advertises Godot 4.5+ | **First candidate** for NPC dialogue. Test in an isolated scene before integration; keep authored Latin text ours. |
| [Beehave](https://github.com/bitbrain/beehave) | Reusable animal/NPC behavior trees | MIT, Godot 4.x addon | Prototype one deer and one villager schedule, then adopt only if better than current simple state machine. |
| [GdUnit4](https://github.com/godot-gdunit-labs/gdUnit4) | Test infrastructure for scene interactions/mocks | MIT, Godot 4 test framework | Optional augmentation; current plain SceneTree tests already work, so **do not block milestones** on migrating them. |
| [Godot Demo Projects](https://github.com/godotengine/godot-demo-projects) | Vetted snippets and reference implementations | MIT repository | Reuse small compatible controller/physics/navigation patterns rather than replacing the working FPS controller gratuitously. |
| [Voxel Tools](https://github.com/Zylann/godot_voxel) | Possibly chunked/streaming terrain later | C++ module/GDExtension, nontrivial adoption/compatibility | **Research spike only**, not a planned dependency. Use native segmented terrains/region loading first; don't replace working terrain with a compiled extension without measured benefit. |
| [Dialogue Manager](https://github.com/nathanhoad/godot_dialogue_manager) | Alternative branching dialogue runtime | MIT; latest README targets **Godot 4.6+** | **Do not adopt main branch on our Godot 4.5.2 baseline**. Use Dialogic 2 or a verified older compatible tag. |

The dependency choices are candidates, not installed packages. Future asset kits can be sourced from verified CC0/compatible libraries and converted/scale-normalized in CI; no untested external installers. No copying proprietary commercial packs or code that doesn't permit reuse.

## 5. Milestones — all are tasks feasible with GitHub + Godot CI

### M0 — Reliable playable release and visual pipeline
**Build:** add player-eye-view interaction trace for movement, held book opening, real text casting, item pickup, and autosave. Maintain golden screenshots at representative weather/locations. Establish tested Windows export ZIP through a Windows GitHub Actions job only after import and export templates pass; source ZIP remains the fallback. Add an asset quality/scale checklist to PR/release records.

**Definition of done:** clean import, playable movement, grimoire, reading interaction smoke scene, item use, no visible giant animal; logs, screenshots and downloadable artifact from passing commit. If export fails, do not promise an executable.

### M1 — A complete book/Latin/mana loop (FIRST PLAYABLE VERTICAL SLICE)
**Build:** a data-driven `BookDefinition` JSON format (id, subject, pages, correct Latin passage, glossary, difficulty, validated comprehension prompts, effects, find location), physical book pickups, reader interaction in the existing grimoire/book scene, explicit scholar XP/level/current and maximum mana, mana consumption/recovery and study-based progression. Create **three short, edited books**: plants, animals, fire/water. Establish distinct words/skills per subject. New vocabulary is learned by reading; recasting without comprehension does not produce unlimited XP.

**Definition of done:** new game → discover/read book → recognize/answer a contextual Latin prompt → receive measured XP and increased maximum mana → cast an appropriately learned, mana-consuming spell → save/reload with progress intact. Automated Godot integration test and actual page screenshots prove this. No online model or API required during play.

### M2 — Conversation and relationships, starting small
**Build:** test/possibly vendor Dialogic 2; dialogue state with trust/relationship values, NPC schedules (shopkeeper, hermit, one villager), transactions and book rumors, authored English-to-Latin gradual speech with multiple accepted replies. An NPC's schedule and relationship state persist.

**Definition of done:** talk to a bookseller, correctly respond with beginner Latin, obtain a book clue/trade, and later receive a slightly more advanced Latin exchange when comprehension increases. Persist conversation flags, disposition, and inventory; one automated branch test verifies both outcomes.

### M3 — Tower construction as a real sandbox
**Build:** simple **snap-to-grid construction kit** with stone wall, wood floor, stair, door, roof, bookcase, and lamp; 3D ghost placement, rotation, collision checks, removal, materials and saved per-piece positions; player can carry books and shelve them. Start on a fixed plot in the current valley. This is a modular build system, not an unbounded physics-destruction engine.

**Definition of done:** build a tower room, add a door, stair, shelf and lamp; enter it; place a book; close and reopen game and retain structure, materials, positions and collision. CI checks invalid overlapping pieces and renders interior/exterior screenshots.

### M4 — Survival, mobs, and familiar
**Build:** health/damage, danger telegraphs, respawn/return point and recoverable items; **two distinct mob archetypes** with real nav/collision and different reactions to fire, sleep, and water, plus patrol/rest times and night variant. Pet choice begins with **cat or crow**, each with follow, stay and one additional Latin command. Relationship/affection stored as small persistent values.

**Definition of done:** survive night encounter using either magic or avoidance; enemies path around actual obstacles, deal/receive damage and persist appropriate consequences; choose a pet, summon/follow/stay using Latin and keep that choice after reload. Test mobility, hits, and state transitions; visual animation previews required.

### M5 — Five authored places and exploratory weirdness
**Build:** a small, continuously traversable *strange road* connecting a wizard home plot, cheerful village, working gas station, castle, and ancient ruin. Use authored modular buildings + region data, not a kilometer-wide random test plane. Physically enter at least two interiors. Include one optional eerie phenomenon that changes with circumstances, and one harmless surreal creature. Place subject-specific books across these locations; make them accessible in a non-linear order.

**Definition of done:** start at tower, walk to gas station, village, castle and ruin without teleporting, observe wildlife and NPCs en route, enter selected interiors, acquire a book, return home, and save/reload. Four player-view screenshots plus a full automated navigation trace, real colliders and stable performance baseline. Every world landmark visibly distinct at eye level.

### M6 — Repeatable procedural exploration beyond the authored core
**Build:** a deterministic world seed, **region tiles/chunks** with authored location sockets, weighted world-layout grammar and rules for roads, rivers, settlements, landmarks and ruins; periodic state simulation with saved durable changes for offscreen regions. Generate locations from a curated pool, so modern/medieval/surreal neighbors are permitted but interiors and placement are intentional. Do not promise infinite procedural towns; add content templates over time.

**Definition of done:** two seeds generate distinct but coherent worlds; revisiting a region reconstructs its same buildings, books, changed ecology, NPC and pet states; walking across adjacent region boundaries does not crash or wipe progress. Benchmarks for runtime memory/frame time and persisted region file size. If a voxel extension is unnecessary, don't add one.

### M7 — Content growth through a data pipeline
**Build:** more book subjects (architecture, flora, bestiary, metallurgy, astronomy), accurate graded Latin excerpts and grammatical review, NPC dialogue packs, region templates and creature types. Create authoring/validation tools to check duplicate IDs, malformed Latin forms and asset references before any new book or region enters the game.

**Definition of done:** contributors can add one valid new Latin book, NPC exchange or region from a data file without modifying the main world script. Automated authoring checks catch malformed/missing assets and identifiers.

## 6. Release gates and stop rules

**No ten-hour blind coding passes.** Each milestone splits into small commits that produce a visible or testable improvement. If a third-party add-on introduces import errors, isolate it in a spike, revert it and keep the current working game. If two asset candidates fail the actual Godot visual test, stop randomly searching and make an intentional custom asset or choose a different source pipeline.

**Never call these "done" merely because code exists:** real character animation, usable physical books, NPC dialogue progression, tower building, multi-region survival, local Windows running, or art quality. Tests have to exercise the behavior; screenshots need human visual review.

**Release criteria for a milestone:** CI success for that commit, concrete playable example, bundled assets, no extra manual asset installers, documented controls, and a brief evidence report with known issues. Engine tests are necessary, never sufficient, for approving artistic quality.

## 7. Implementation order and first task

Start with **M0 + M1**, not five regions or a complete tower. They unlock the core learning loop and make everything else meaningfully useful. The first commit should introduce a book schema, validation tool and three authored example book definitions, without affecting the current running scene. Then layer reading, XP/mana, interaction, saves and visuals in separate testable commits. After one complete loop works, evaluate Dialogic 2 in an isolated project and move to M2.

Optional later: a small local Windows development runner could synchronize GitHub, execute Godot/Blender on the user's PC, capture footage and upload artifacts. This would require explicit one-time user setup; **none of the milestones above depend on it**.
