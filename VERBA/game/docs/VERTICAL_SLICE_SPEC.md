# VERBA — Vertical Slice Design Specification

**Codename:** Hollow Vale | **Engine:** Godot 4.x | **Genre:** first-person systemic sandbox RPG and language-learning experience | **Perspective:** embodied first person | **Offline:** yes | **Platform:** Windows first

## The thesis

Knowledge of Latin is a real player skill. A player who can remember `cresce` need not lift the book; one who forgets must physically raise it, read, lower it, and try. Learning is not separated from the fantasy: literacy makes the magician more capable.

The world is not a word-to-effect slideshow. It contains persistent traits and entities which change one another. Magic alters objects and behavior, often provoking new interactions. Consequences can surprise without becoming incoherent.

## Non-negotiable controls

- Keyboard movement: W forward, S backward, A/D strafe. Shift sprint; Space jump.
- Pointer-lock mouse-look: relative X = yaw, relative Y = pitch. No drag-look, no arrow-key view rotation, no camera split across keyboard keys.
- Esc releases cursor; click once to recapture; book and casting intentionally block locomotion, not camera-control bugs.
- Contextual interactions: E take/study, F use, Q drop, number keys select inventory.
- G raises and opens a **modeled book in the hand**; G/Esc lowers and closes it; pages can be turned physically while reading.
- Enter opens typographic casting state. Typed letters should appear as suspended marks beside the hand; Enter confirms. No clickable spell icon list.

## Diegetic interface

The ordinary view is almost empty: small reticle and interaction prompt at most. The grimoire contains the spell encyclopedia, spell meaning, lemma/form, the record of learned words, and eventually field notes. Inventory objects have visible held models; a richer inventory could become a belt/pouch rather than a HUD. **World-spatial text has depth and can be occluded**; successful Latin appears near the target, rises, and fades under the world's light and perspective.

## Starter geography: Hollow Vale

One cohesive region, not a uniform lawn. Spawn on the upper glade looking toward a broken priory. A winding path introduces proximity of ruins, then opens into a western stream and cooler lowland. The eastern slope leads into an amber grove and a hermit's cottage; a separate ridge arch gives an optional destination. A dead tree anchors the meadow edge. Sparse foreground flora, midground animals, and distant landmarks establish scale. Each region has color and texture identity without changing to an unrelated art style.

**Blocking:** maintain empty ground around the player, path, and each landmark; use clusters, not carpet-scatter. Tall trees must have recognizable crowns and branches, trunks with shape and bark; animals should use readable anatomy rather than cubes.

## Ecological model — first version

Traits: wetness, growth, burning, fear, sleep, stop, movement intent, type/species. Deer and hares flee close players, predators, and fire; foxes pursue hares; wolves pursue deer; crows wander faster; wisps drift. Plants can grow; wetness makes ignition difficult. Rain extinguishes fires and wets creatures and plants. Fires create bright hot sources that frighten nearby creatures and can spread to nearby dry trees. Growth creates fodder/cover and fuel. Magic can redirect animal intent and alter sizes/forms.

Wild magic begins with a bounded ~14% chance after valid casts, e.g. local wind reversal, unrelated creature transformation, short shower, distant animal flight, or brief dimming. Each anomaly obeys a world rule and does not replace the requested spell. Next iterations should add effect provenance, material trait graph, and reproducible seeds in dev settings.

## Latin learning and progression

- Nouns such as `ignis` and `pluvia` are *invocation names*, explicitly described as nouns; they are not misrepresented as imperatives.
- Singular commands such as `cresce`, `dormi`, `fuge`, `veni` and `muta` use actual singular imperative morphology.
- Collect torn manuscript leaves with Latin entries and consult them within the grimoire.
- Spells are typed, never clicked; valid words from outside the player's book also work, reinforcing authentic language study.
- Word entry records lexical lemma, form, literal meaning, effect, and a short educational note in data.
- Book study incurs time/attention. Independent casting (30+ seconds since consultation) grants recall credit; future mastery may change animation timing and spell variance rather than add artificial XP points.
- **Next grammar milestone:** `arborem move` for an accusative object + imperative, `arbores crescite` for plural command; only after accurate grammar parser and target binding exist. Do NOT fake grammar by guessing suffixes.

## Interactive object contract

Every interactable has material, state, pickup/target reference, and behavior. The target ray can hit creatures, trees, ground or objects; failures respond in-world instead of silently ignoring input. Inventory is limited to six slots and selected items visibly appear in the character's hand. Start with lantern; explore for torch, stones, herbs, and amber. Picking up a word leaf adds vocabulary. Stone is a throwable rigid body, herb calms animals, torch starts fires. Next slice adds physical placement, material breakage, climbing, and a satchel.

## 3D visual direction

Reference mood: early-2000s melancholic first-person fantasy RPGs; not a clone of any particular game. No neon spell UI. Stony gray, peat green, bruised umber, faded ochre, vellum, candle amber. Atmosphere combines mist, warm angled sunlight, deep cool forest recesses, and intermittent rain. Texture discipline: hand-authored and weathered surfaces with visible wear, restrained repeating frequency, varied specularity. Silhouettes and spacing matter more than raw polygons. Static architectural meshes should be revisited with actual modeled windows, joins, cracks, roof geometry and trim.

## Acceptance criteria — first playable release

1. Godot project imports and runs without script errors on Windows.
2. Mouse can continuously turn 360° horizontally and look up/down through a plausible constrained pitch, without dragging.
3. All movement is standard WASD in camera-relative yaw; book/cast modes reliably suspend movement.
4. Book visibly rises, opens, contains changing legible 3D page text, and lowers back into the hand; never a HUD menu.
5. Typed valid Latin triggers a world-space 3D incantation and an effect; invalid words always give visible feedback.
6. At least two kinds of animal move and react; a predator/prey dynamic exists; rain changes fire.
7. The world has topography, distinct zones, several landmarks, and unoccupied clearings.
8. Words survive game restarts and aren't automatically auto-cast from the book.
9. At least one item is visibly held and useable; a picked-up leaf disappears from the world.
10. Frame rate remains playable in native compatibility mode on ordinary Windows hardware.

## Current implementation status

**Code implemented for criteria 2–9, but in-engine integration and subjective visual acceptance are not verified in this environment.** The engine was not available in the build runtime; do not mark criterion 1 or 10 passed. Modeling remains procedural and should be rebuilt into higher quality original meshes as the art pipeline matures.
