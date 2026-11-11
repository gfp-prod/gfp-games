# VERBA — Gameplay Milestone 08: People, Familiar, First Survival Loop
**Implemented on:** 2026-11-11  •  **Branch:** `verba-godot`  •  **Godot:** 4.5.2

## Why development changed emphasis
The seven prior passes focused heavily on artistic flaws. The main player goal remains an open-ended, whimsical-to-eerie Latin-learning wizard-life sandbox. A functioning reading system existed, but its knowledge did not yet affect a social world, and the player had almost no non-magic survival stakes. This milestone returns to the master sequence.

## Implemented and committed

### Graded, persistent conversations (Phase 3 entry milestone)
- `data/npcs.json` defines Mara (roadside scribe, near the starting path) and Tomas (hermitage keeper, by the cottage), including three authored response choices each and distinct staged English/Latin text.
- `scripts/npc_actor.gd` instantiates visible, physical human-size characters with colliders that the player's first-person ray can hit. Speaking with a character requires physical proximity and unobstructed line of sight.
- `scripts/dialogue_social.gd` changes the **ratio of Latin** based on the number of comprehension-completed books, never on mere page opening or repeated NPC clicks. Studying `De Herbis` unlocks Mara's botany conversation.
- Each topic increases that NPC's rapport at most once; revisits retain topic history. A correct one-time exchange with Tomas consumes one herb and grants `De Igne et Aqua`. It also retires the equivalent physical world pickup and records the existing book's collectible tombstone.
- The dialogue is an actual first-person bottom-screen conversation panel, opened with **E**, answered with **1-3**, closed with **E** or **Escape**. Mouse-look, movement, grimoire opening and spell typing are prevented from conflicting while talking.
- `world_persistence.gd` stores social data in the existing version-one world save; older saves with no social field continue to load.

### First real choice of familiar (Phase 4 entry milestone)
- An existing wild **crow** can bond when offered **amber**; an existing wild **hare** when offered a **herb**. This uses actual world creatures and their existing stable persistent IDs, models, physical navigation and ecological state.
- A single bonded familiar can **follow**, **stay** or **rest**. Press **C** to cycle. Correctly addressed and successfully cast Latin, e.g. `veni corve`, `siste corve`, `dormi corve`, updates that state as real magic, not UI flavor.
- Bonding consumes the offered item once; there's no pet-cloning exploit. Wild rabbit/crow avoidance is suppressed by their appropriate physical offering so they can actually be approached.
- Its species, identity and order are stored in the existing save and restored by stable ID. Old saves remain unbonded. A dead familiar cannot remain valid as a living companion.
- **Limitations:** only one bonded companion at a time; advanced flight, true pet skills, naming and changing companions are not finished.

### First tangible survival consequence (Phase 4 entry milestone)
- Player health and stamina resources; sprinting and jumping spend stamina; walking/rest lets it recover. Herb use restores vitality. Compact `VITA/VIGOR` feedback appears only when resources aren't full.
- Wild wolves now track and injure nearby players, with a real cooldown and an explicit physics ray stopping bites through stone/wood walls. Their existing animal hunting/ecological behavior remains for prey.
- Defeat returns the player to the starting cairn with partial vitality, dropping one real item at the defeat spot (its dropped pickup is saved). Acquired books, scholar level and learned Latin remain intact.
- Save/reload includes health, stamina, defeat count, and familiarity in a backward-compatible additive schema.

## Acceptance gates and actual automated tests
- `tests/social_dialogue_test.gd`: world NPC existence and hit collider, early/studied Latin text, relationship exploit prevention, exchange consuming exactly one herb/book, no world double, exact social+book save/reload, and physical conversation distance/line-of-sight.
- `tests/familiar_progression_test.gd`: requires real gift, both species choices, item consumption, stable creature count/identity, following/staying/resting, Latin vocative commands, no duplicate pet, save/load and legacy-save compatibility.
- `tests/survival_loop_test.gd`: damage with temporary immunity, herbal recovery, actual wolf pursuit/bite, physical wall bite occlusion, defeat drop/recovery, stats after save/load, and healthy defaults for old saves.
- GitHub Action `.github/workflows/verba-check.yml` requires all three along with existing 19+ Godot suites.
- `tests/social_visual_gallery.gd` captures real first-person dialogue with both residents. The existing visual workflow now requires both screenshots as a rendering gate.

**Passing tests prove implementation and regressions, not a fully polished social, survival, or pet experience.** Continue reviewing screenshots/player paths rather than relying on green CI as art approval.

## Free/open-source code diligence
The existing repository already vendors MIT-licensed Dialogue Manager (compatible with Godot 4.5). Its newer v4 line requires Godot 4.6+, so upgrading the game or copying that code would be a regression. This milestone keeps the initial tiny deterministic graded conversation in a data-driven JSON+GDScript layer to avoid an unnecessary new dependency. It can be mapped to the installed dialogue editor once dialogue branches become numerous. Source: https://github.com/nathanhoad/godot_dialogue_manager .

## What is **not** finished
- Tower construction (modular foundations/walls, building resources, furniture/bookcase placement and save IDs).
- NPC roaming, real trade economy, relationship events and more verified Latin conversations.
- Multiple hostile mob archetypes, enemy combat balance, progression after the first 3 books, alternative death handling.
- A 500-800 m authored explorable district with **castle, gas station, village, ruins**; the current world is the starter valley only.
- Robust familiar flight, pathfinding over difficult creek/bridge transitions and active pet skills.
- Mature character anatomy, ambience/audio and overall aesthetic approval.

## Next production tasks — ordered by unlocked player value
1. **Construction foundation:** collect stone/wood from the physically mutable world, place the first snap-to-grid collidable tower parts, then save/reload every piece with stable IDs. The milestone should end with a player genuinely able to build a small room—not just a decorative tower model.
2. **Exploration circuit:** connect the starter meadow to a recognizable station/castle junction, a hamlet and a ruin using authored POI maps. Verify there are arbitrary-order routes and at least two interiors.
3. **Expand survival:** two distinct mob behaviors, health/stamina tuning and clearer risk-recovery signals.
4. **Latin content pass:** separate books about architecture, trade and beasts with verified forms and no repeat XP; link the lessons to building and social choices.
5. **Social/familiar expansion:** NPC schedules and individual routines; second pet behavior, naming and recall when pathing strands it.

Do not mark Phase 3 or Phase 4 as fully complete because these are first vertical slices. Keep the existing master roadmap authoritative.
