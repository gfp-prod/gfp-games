# VERBA — The Living World Simulation Contract

## Non-negotiable principle

The player should never feel that spells activate prefabricated animations. A spell must alter an entity's actual state, and the rest of the world must respond to the consequences, whether or not the player is looking. **Unpredictable does not mean arbitrary**: events emerge from consistent local rules and independently changing conditions.

## Identity and per-object state

The slice assigns a stable runtime ID to every interactive tree, stone, fallen log, fern and large grass clump. Their `sim_object.gd` scripts own these independent properties:

| Property | Used for |
| --- | --- |
| Wetness | Resists ignition, accelerates cooling, lets plants recover |
| Heat | Raises ignition risk, can crack waterlogged stone |
| Fuel | Fire consumes a limited resource rather than playing indefinitely |
| Health | Flora may lose foliage, become dying or spent |
| Growth | Alters visible physical size without affecting neighbors |
| Food/biomass | Grazing reduces edible biomass; grass and ferns slowly recover |
| Brittleness | Stones crack when struck or subjected to temperature changes |
| Burning/dead flags | Persistent state changes, rather than one-off visual effects |

Wildlife (`creature.gd`) independently keeps hunger, thirst, energy, health, sleep, panic, wetness, and AI intentions.

## Behavior that happens without player input

- Hares and deer can seek edible foliage, graze it and reduce that individual plant's food state.
- Foxes pursue hares; wolves pursue deer; an attack injures prey and reduces the predator's hunger. Prey can die and remain as a body, which crows may visit.
- Animals approach the stream and drink. Rain independently reduces thirst but soaks fur.
- Wind shifts and rain may begin without player intervention; creek-bank plants are locally moistened by their position. Rain wets exposed objects. Fire radiates heat to adjacent objects. A dry, heated living thing may catch fire and spread it further. Wet wood resists ignition. Flame consumes fuel and damages health. Ice/frost dissipates heat.
- Grazed vegetation regrows in moist conditions. Scorched trees can lose their crown.
- Stones accumulate damage independently, but cannot burn.

## Player interactions (same rules as nature)

| Player act | Simulation effect |
| --- | --- |
| `ignis` on dry wood | Ignite its own fuel source |
| `ignis` on wet wood | Resist ignition until dry |
| `ignis` on stone | Heat the stone; do not burn |
| `aqua` | Wet all nearby objects and refresh animal hydration |
| `pluvia` | Global weather feeds into every object's wetness/heat tick |
| `cresce` | Grow one living target or create a new interactive grass patch |
| `gelu` | Cool nearby objects and stop flames |
| Predator encounters prey | Actual damage and hunger change, not a visual-only chase |

## Architecture

- `scripts/sim_object.gd`: independent mutable state, damage and environmental effects.
- `scripts/world.gd`: central time step (`ecology_step`), weather, fire sources, spatial lookup, world construction.
- `scripts/creature.gd`: autonomous needs, predation, grazing, scavenging and spell reactions.
- `scripts/magic.gd`: maps Latin into shared world effects; avoid one-off spell-only exceptions.
- `tests/ecology_smoke_test.gd`: verifies that altering one object does not alter another and that materials react differently.

## Performance and honesty

Rendering every one of roughly 5,400 grass blades as a full Godot physics node would be counterproductive. For this slice, **individually interactive grass clumps** own state, while tiny decorative blades are batched with `MultiMesh`. The same distinction should apply to leaves in a tree: the tree is a gameplay object and may shed or burn leaves; each polygon is not an AI agent. Future versions should use chunked state arrays when individual blades/tiles need fine-grained damage.

Walls, doors, water volumes, movable stones, richer creature/plant ecosystems, persistence across game saves, multiplayer synchronization, and cross-species food webs remain later work. This version must not be described as a complete biological simulation.

## Acceptance criteria for Godot runtime validation

1. Two trees have unique IDs. Cast growth on A; B retains its exact scale and health.
2. Drench A and try to burn it; A resists. B ignites if dry.
3. Hit a rock and confirm only that rock's brittleness changes. Fire does not burn it.
4. Observe a hare graze on a grass clump without casting any spell. Its hunger decreases; the plant's food value decreases. A second plant is unchanged.
5. Observe a predator encounter prey; prey health decreases. The predator's hunger decreases.
6. Ignite a dry tree, let the game run, then rain; the fire should extinguish and the tree retain damage.
7. Verify player movement (WASD + mouse) and textured terrain independently before judging atmosphere.

All above require actual native-engine verification. Source-level checks do not satisfy them.
