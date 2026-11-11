# Emergent Village: isolated implementation slice

Branch: `verba-emergent-village`. This is an **unintegrated, testable prototype**, not a completed village.

## Included
- Seeded utility action selection, personality drives, needs, social relationship values
- Witness-only crime knowledge and event log
- Versioned snapshots including RNG state
- Headless deterministic regression script

## Run
`godot --headless --path VERBA/game --script res://simulation/test_village_sim.gd`

## Deliberately not yet claimed
- Scene integration, navigation, occupation-specific production, full justice, reciprocal relationships, marriage, pregnancy, pets, or spells
- Godot test execution in CI; this branch has not been engine-tested here
- LimboAI or gdUnit4 installation; versions and compatibility must be pinned and verified before introducing binary/plugin dependencies

## Adversarial defects and next actions
1. NPCs can currently generate theft events without selecting a victim or checking witnesses. Implement transaction targets and perception radius before integrating theft into gameplay.
2. Social links are directional. Implement consent, reciprocity, existing partnerships, jealousy and memory-based consequences.
3. No resource economy or location model. Add workplaces, inventory, travel time and action reservations.
4. Event arrays grow indefinitely. Introduce rolling event windows and archival persistence.
5. Invalid snapshot shape validation is shallow. Add schema checks and migration tests.
6. Decision scoring is intentionally small and will become repetitive. Add opportunity/context scoring and choice telemetry.
7. Visual quality cannot be evaluated without scene integration and actual captures. Do not mark aesthetic work done.
8. Build compatibility gate before adopting LimboAI: https://github.com/limbonaut/limboai
9. Add gdUnit4 only after a passing standalone engine test: https://github.com/godot-gdunit-labs/gdUnit4

## Release gates
- Headless script passes on actual Godot engine
- 100 seeded simulations and save/reload round trips
- No NPC knowledge leakage, invalid actions, stuck reservations or missing resources
- Existing gameplay smoke test and screenshot comparisons
- Human review of novel behavior and aesthetic consistency
