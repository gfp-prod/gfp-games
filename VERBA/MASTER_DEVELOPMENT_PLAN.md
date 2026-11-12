# VERBA — Master Development Plan
Version: 2026-11-11 (reconciled to live Godot repository) | Engine: Godot 4.5.x | Platform: Windows PC, offline | Source: `verba-godot/VERBA/game`

## Live development truth — November 11, 2026

**Merged into the actual playable `verba-godot` branch (not whole-phase completion):** The authored gas-station/castle road district and a Latin-speaking station attendant; two-story collidable wizard tower and in-world book shelving; finite farm, bakery, forge and market workplaces with visibly performed NPC labor; persistent Latin-enhanced physical crops and paid wizard commissions; a single authoritative world calendar; real Latin reading, grammar and compositional spells; and a research-grounded, in-grimoire sequence of contextual typed retrieval, delayed in-world recall and corrective morphology. Earlier features include wildlife, familiars, survival, book collection, and social routines. These features were delivered in merged PRs #12–19 and prior milestones. The empirical field journal (PR #21) and the one-day immortal return (PR #22) have also merged after native and rendered tests. These are still alpha systems, not final art/content acceptance.

**Merged since the initial play slice:** PRs #21–#23 are now part of `verba-godot`: the empirical spell journal, one-day immortal recovery, and productive Latin NPC interactions. PR #25 repaired four compositional-verb lexicon references and added the missing validation gates.

**Still in review, not shipped:** PR #20's artisan professions remain a draft. PR #24's physical Latin-revealed forest waystone is undergoing visual acceptance. PR #26 tests transferable Latin questions, but is stacked behind PR #24 and is not merged.

**Still incomplete:** No complete streaming open world, generational inheritance/aging, comprehensive material simulation, multiple polished enemy families, fully emergent NPC dialogue, broad Latin morphology, or finished character/creature animation and environmental art. The playable base still mostly uses authored conversation choices. The playable branch includes a few **bounded, authored** typed Latin requests with correct morphology and flexible word order; it does not implement free-form Latin dialogue or a broad parser. A passing Godot build or a generated screenshot is not itself artistic sign-off.

**Immediate execution gates:** (1) complete native and rendered QA and integrate the outstanding draft features without breaking the playable loop; (2) verify the next language-to-world features preserve learned Latin, real trade, witness limits and save integrity; (3) play-test the complete book → recall → targeted spell → changed village livelihood → relationship/trade → tower → risk → world return loop; (4) inspect fixed-angle and real first-person captures for anatomy, proportions, readability, collision, and painterly/stylized art consistency. Expansion into new regions follows these gates, not vice versa.

The phase descriptions below define **desired acceptance criteria**, not a claim that all earlier milestones remain untouched or are finished. Reconcile them with the live branch and its test results before creating new work.

## Creative target

An open-ended 3D Latin-learning wizard-life survival RPG. Exploration feels like *Adventure Time*: a bright meadow can be funny or peaceful, the roadside gas station can sit beside a medieval castle, and the next path may lead into a village or an ancient ruin. Surrealism is treated as ordinary by the inhabitants. Cozy and eerie moods are interleaved, not confined to separate biomes.

A player can wander without accepting quests, read books, speak with people, study magic, fight/avoid mobs, keep a familiar, build and customize a wizard tower, or watch animals and natural phenomena change the world independently.

**The player becomes a powerful wizard by learning real Latin.** Vocabulary and grammar are actual player skills, not decorative spell names.

## The player experience that must work

Start at a small cottage or ruined tower. Look at a woodland full of grazing animals. Read a beginning Latin nature book and earn scholar XP and maximum mana for *real new comprehension*, not for repeatedly opening pages. Use `cresce` to grow plants. Talk to a gas-station clerk who initially mixes basic Latin with English. Walk past the castle, through a little village and on toward a ruin. Recover a book about animals, use `veni` / `venite` in context, survive a hostile encounter, acquire a familiar, return to base and build a library shelf. Save and exit. On return, both your work and the ecosystem's changed state remain.

This is an **example**, not a compulsory quest sequence. The loop must also work if the player chooses a different order.

## Production policy: innovate around constraints, not around visual or systemic quality

- No player-as-debugger. Use GitHub CI, Godot scripted input, true 3D renders and clips, and automated save/load assertions. Every new scene gets real first-person review images and a playable path.
- Reuse proven, license-appropriate open-source Godot libraries and public models, pinned to a tested revision and *committed into the game*; never send the player to run a separate asset installation script.
- An open-source dependency is adopted only after passing clean Godot 4.5 project import, renderer compatibility, gameplay regression, license preservation, and a specific sample interaction. Otherwise isolate the experiment; don't break the main build.
- Do not build an entire open world before we can make one village road, one cottage, one creature and one book look and behave beautifully.
- Do not mistake low-poly primitives for PS2 art. Materials, silhouette, anatomy, proportions, lighting, animation, ground contact, collision and readability must pass inspection.
- No generic LLM-generated Latin asserted as correct. Source lexemes, morphology, graded passages, explanations and inflected forms; a local deterministic parser accepts explicitly attested forms.
- Player-authority stays local and offline; dynamic AI is optional later, not required for reliable NPCs.

## Systems architecture

Keep existing `world.gd` playable while pulling code into independent modules, with tests BEFORE migrating:

1. `world/regions` — procedural seed, terrain/road/river chunks, landmark placement, coherent roads and compatible points-of-interest (POIs), stable entity IDs, chunk boundaries, local navmesh.
2. `simulation` — persistent world-state registry, materials/heat/wetness/growth/fire, fauna needs and memories, distance-tiered updates. Rendering and physics are views of this state, not the source of truth.
3. `books` — physical book prefabs, page turning, individually collectible volumes, authored graded Latin passages, comprehension/recall events, reading progress and shelf placement.
4. `language` — lexicon, verified imperatives, nouns/cases, dialogues with mastered-vocabulary thresholds, regional phrases, progressive comprehensible input.
5. `progression` — book reading XP, scholar level, maximum mana, mana regeneration, spell mana costs and grammatical complexity. XP gained once per newly completed passage; comprehension and later use award more.
6. `magic` — deterministic parsed intent -> target selection -> effects on shared physical/biological states. A spell can trigger emergent environmental chains.
7. `actors` — NPC schedules, conversations/trade/relationship memories, animal needs and behavior trees, hostile mob plans, faction or social reactions, familiar bonding and commands.
8. `construction` — grid/snap structure assembly, free movable furniture, stability/collision, upgrades, material inventory, interactive bookshelves, persist built parts with IDs.
9. `qa` — Godot runtime and graphical screenshots/videos, regression scripts, seeded scene review, source/credit manifests, performance and cold-import checks.

## Milestones — always finish the current acceptance gates before expansion

### Phase 0: Reliable production/art foundation

**Deliver:** Tested Godot GitHub automation, fresh clone/import, render-gallery for animals and environment, animated clips from actual Godot, a reference humanoid for scale, a certified first-person control/collision path, source/license manifest, one high-quality cottage/tree/animal/grimoire reference model. Set performance and screenshots at player eye height.

**Gate:** CI does not accept invisible geometry, huge deformed animals, missing textures, camera clipping, or parser errors. At least one real player-view captured path and a moving creature loop are visually reviewed, not just file-tested.

### Phase 1: A convincing small open district

**Deliver:** An authored-quality starter district (rough target 500–800 m across, tunable for performance), winding paths/roads, forest/meadow/stream, cottage or tower plot, a medieval castle beside an old gas station, a small village and an ancient ruin. Use authored POI stamps and a seed-based placement graph; not a single giant crowd of random meshes. Some areas feel funny, others melancholy or eerie. Cycle day/weather/night with creature responses. Two real interiors, navigable exterior, wildlife and passable roads.

**Gate:** Player can go from starter home to all four landmarks in arbitrary order, enter interiors, meet wanderers, return and save. Godot visual capture of the road/castle/station junction passes art review. No world-object collision failures.

### Phase 2: Books, language, scholar levels and mana

**Deliver:** Two real, physically legible beginner Latin books (`De Arboribus` / On Trees and `De Animalibus` / On Animals), each with illustrated text, page turning, knowledge categories and learnable spells. The grammar table and glossary are verified, not Latin-shaped inventions. Completing new passages and practicing new constructions gives Scholar XP; Scholar level increases max mana; spell costs and regen make mana meaningful. Reading progress stored per passage ID to prevent exploitation. Books can be found, collected, placed and shelved, not just a 2D menu list.

**Gate:** Retrieve book -> open and read -> answer/use a basic Latin expression -> gain one-time XP and mana -> cast a new state-changing spell -> return after save/load with both world and reading progress intact.

### Phase 3: People and gradual Latin conversations

**Deliver:** Three distinct NPCs: gas-station clerk, village resident, hermit/book trader. Dialogue branches based on learned vocabulary, basic social memory, relationship score and routine. English+Latin begins at learner level; more of each character's conversation becomes Latin as mastery rises. Trading, directions, exchanges of books and limited favors are present; typed phrases supported where grammatical coverage allows. The game never demands a particular story quest.

**Gate:** Converse with two NPCs, learn a phrase, get directions, bargain or trade for a book, improve a relationship and revisit to see a relevant memory response.

### Phase 4: Survival, mobs, animals and a familiar

**Deliver:** Coherent health/stamina/mana, 2–3 mob archetypes with habitats and behaviors (wander, notice, pursue, disengage, return), fight or flee through actual elemental physics, loot/recovery/death, creature movement/collision/navigation and predators grazing/hunting naturally. Choice of at least two pets, beginning with one polished common familiar controller (e.g. crow or cat) and then distinct species-specific features. Latin commands `veni`, `siste`, `dormi` can meaningfully address your familiar.

**Gate:** 10-minute unscripted survival session has a real ecological encounter, hostile threat, successful spell-based survival, creature-free collision, and an animal companion that remembers the player after restart.

### Phase 5: Modular customizable wizard tower

**Deliver:** Gather wood/stone, snap foundations/walls/doors/windows/floors/stairs/roof, free-place shelves/decor and interactive bookshelves, physically usable door/interior. Structures are collidable and persist; NPCs/creatures route around the building. Magic can assist construction and affect materials according to established world laws.

**Gate:** Build a valid two-level tower, walk through both floors, place retrieved books and furniture, save, quit, reopen, find the structure intact.

### Phase 6: Streaming wilderness and surreal expansion

**Deliver:** Deterministic chunk streaming and world-state deltas; regional event queues keep offscreen ecology running at lower frequency. Roads connect curated landmarks rather than random buildings sprayed onto a plane. Generator can mix architecture eras and tones coherently—gas station/castle, village/ruin, ordinary cottage/impossible grotto—without needing a single global narrative explanation. More biomes, migrating animals, mysterious structures, rare odd encounters.

**Gate:** Cross multiple regions; observe streaming without large frame spikes; return to a changed object and see its prior identity/history; generate two world seeds that are meaningfully different but recognizable as VERBA.

### Phase 7: Depth, polish and content

**Deliver:** Broader library with subject-specific magic (botany, animals, fire/water, metals, architecture, dreams), progression through more Latin grammar, new towns/ruins/mobs, rich NPC personalities, more familiars, tower upgrades, ambient sounds/music, accessibility aids and optional Latin learning difficulty controls.

**Gate:** Multiple viable playstyles (reader, explorer, builder, survivalist, social), with no compulsory main quest. Reading remains genuinely useful in all playstyles.

## Open-source reuse shortlist

Licenses must be retained with copies; verify exact versions before integrating. External code must be *vendored by CI*, tested, and committed, not run as an installer on the player's Windows machine.

| Candidate | Purpose | Decision |
|---|---|---|
| [Dialogue Manager](https://github.com/nathanhoad/godot_dialogue_manager) | Branching NPC dialogue, conditions/mutations | **Pilot** v3.x compatible with Godot 4.5; v4 needs Godot 4.6+. License MIT. Avoid plugin-native 2D balloon for normal gameplay; use its parser/runtime with in-world presentation. |
| [Beehave](https://github.com/bitbrain/beehave) | Behavior trees for NPC, mob, pet AI | **Pilot** 2.10+ on Godot 4.5, MIT; pathfinding/physical collisions remain Godot's responsibility. |
| [Terrain3D](https://github.com/TokisanGames/Terrain3D) | Terrain textures, LOD, foliage, sculpting | **Benchmark separately**. MIT, native GDExtension; confirm GL Compatibility pipeline and Windows 4.5 versions before replacing existing terrain. |
| [Voxel Tools](https://github.com/Zylann/godot_voxel) | Editable, chunked terrain, underground structures/caves | **Research prototype** for later; C++ binaries and streaming/save architecture increase deployment complexity. Don't migrate until terrain editing is required. |
| [gdUnit4](https://github.com/godot-gdunit-labs/gdUnit4) | Gameplay/interaction assertions and input tests | **Pilot** alongside current custom headless tests; maintain source-test independence. |
| [Godot official demos](https://github.com/godotengine/godot-demo-projects) | Established movement, navigation, 3D physics examples | **Consult/adapt** on need with explicit source and license record; don't replace the working FPS controller without tests. |

**Do not vendor everything at once.** Each plugin must justify its weight with a specific working game demo. The first integration target is Dialogue Manager for the station clerk, then Beehave for one NPC routine and one creature, then comparative terrain prototype.

## Production cadence / definition of done

Every change should be a small GitHub commit with:
- code and source/credit documentation;
- deterministic test for a real system behavior;
- screenshot, animation, or video showing the changed feature in Godot (not a generated concept image);
- no existing input, saving, movement, ecosystem, import, or graphical regression;
- a playable user-visible result, not just a test's success message.

No fake completed statuses: **planned**, **prototyped**, **engine-verified**, **visually-reviewed**, and **accepted in gameplay** are separate stages.

## First four GitHub work packets

1. **M0-PRODUCTION:** clean cold import, repeatable first-person video and asset quality gate; verified versions/license manifest.
2. **M1-WORLD:** authored gas station/castle road landmark pair + village and ruin blockout with high-quality textures/scale, then upgrade art in place.
3. **M2-BOOKS:** two graded physical books, passage completion, scholar XP/max mana, persistent inventory/book progress and spell costs.
4. **M3-DIALOGUE:** install verified Dialogue Manager in a test branch, then implement station clerk with graded Latin, merchant inventory and reputation.

Sequence can overlap only where tests and module boundaries avoid breaking the main game. Prefer one convincing, complete interactive chain to many partially working systems.
