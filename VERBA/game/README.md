# VERBA — The Hollow Vale (Godot source)

Open `project.godot` in Godot 4.5+ from an **extracted permanent folder**. The project's imported 3D models, tree textures and photographic ground materials are bundled. Do not use a separate asset installer.

## Play the first reading loop

Find **De Herbis** on a labeled stone near spawn and press **E** to collect. G opens/closes the grimoire; B cycles books; N asks a Latin comprehension question; 1/2/3 answer. Correct understanding earns one-time XP, raises scholarly level/max mana, and reduces the mana cost of book-taught incantations. The two other subject books lie elsewhere in the world. Full instructions: [Books and Scholar Progression](docs/BOOKS_AND_SCHOLAR_PROGRESSION.md).

## Working gameplay
- WASD/mouse FPS controls, collision, jumping, physical held grimoire and usable inventory.
- Enter → type → Enter casts Latin spells. The grimoire records recognized forms for later recall.
- Singular/plural imperative grammar: `cresce/crescite`, `veni/venite`, `dormi/dormite`, `fuge/fugite`, `siste/sistite`, `muta/mutate`, `arde/ardete`, `surge/surgite`.
- Optional vocative addressees: `cresce arbor`, `crescite arbores`, `veni lupe`, `venite lupi`. Incorrect number agreement is rejected.
- Several nearby objects/creatures can respond to plural speech. Fire and water operate on the same object moisture/heat as weather.
- Independent objects and animals persist via `user://verba_living_world_v1.json`. Automatic saving happens in the graphical game about every 45 seconds. Open the grimoire (G), then S save or L reload.
- Physical inscribed Latin tablet beside the starting cairn encourages discovery.
- Forests are grouped into curated stands around roads, structures and a visible clearing.

## Play the next sandbox systems

**Talk to people:** Mara, the roadside scribe, stands by the starting path near the first Latin tablet. Tomas, the hermitage keeper, waits farther along the road near the cottage. Walk up, aim at a person and press **E**. Choose **1 / 2 / 3**, and use **E** or **Escape** to leave. Dialogue starts with English assistance, then contains progressively more Latin as you successfully study books. Familiar topics are remembered; repeating lines does not farm rapport. Carry a **herb** to trade with Tomas for the real *De Igne et Aqua* volume.

**Choose a familiar:** Take a **herb** to a wild hare or **amber** to a wild crow. Approach, aim and press **E** to offer it. You may have one familiar at a time. The animal is the actual existing creature, not a spawned duplicate. Press **C** to cycle follow / stay / rest. You may also address it with correct Latin (for example `veni corve`, `siste corve`, `dormi corve`) while aiming; successful spells update its persistent behavior. The gift, species, bond and command survive world saves.

**Survive:** Sprinting and jumping spend stamina, which recovers while walking or resting. The wolf in the distant wilderness now pursues and injures a player who comes within range, but cannot bite through physical walls. **F** while holding a herb restores vitality. Being defeated returns you to the starting cairn with partial health and drops one carried item at the defeat location; your books, spell knowledge and scholarship are retained. Actual health, stamina and defeats are saved.

**Build the beginning of a wizard tower:** Salvage **wood** from the physical woodpile beside the cottage; look at loose stone outcrops and press **E** to gather **stone**. Deposits have limited persistent stock, and collected materials occupy real inventory slots. Press **V** for construction mode; aim at the earth to position a translucent grid-snapped preview. Select **1** for a stone-and-wood foundation, **2** for a timber wall, **3** for a bookshelf, and press **R** to rotate the wall to another side. Left-click to place and spend materials; **V** or Escape exits. The pieces are solid, collision-safe objects with stable saved identities. Failed/duplicate placements do not consume supplies. This is only the **first one-story construction slice**; roofs, stairs, doors, multiple tower stories and moving actual books onto shelves are still to come.

**Windows playable export:** The repository has a dedicated [Windows alpha build workflow](https://github.com/gfp-prod/gfp-games/actions/workflows/verba-windows-playable.yml), verified with the Godot 4.5.2 64-bit Windows templates. Download its `VERBA-Windows-Playable` artifact, extract the contained `VERBA-Windows-Alpha.zip`, then keep `VERBA.exe` and `VERBA.pck` together. This is an unsigned standalone alpha and not a finished installer. Preserve Windows security controls and run software only when you trust the source.

This is a deliberately small playable milestone, not yet a complete survival game: there are no two-story tower construction controls, full village/station, NPC schedules, or diverse hostile mobs. Those remain in the master plan.

**Record experiments:** Every Latin casting attempt, successful or not, leaves evidence in your world-saved grimoire. Open it with **G**, press **J** for *Liber Experimentorum*, use **A/D** to compare observations, and **J** or **Tab** to return. The journal tells you what actually happened to materials, creatures and spells without treating failed attempts as mastery or generating XP.

## Validation
GitHub Actions runs the real Godot engine headlessly for startup, ecology, movement/navigation, Latin grammar, world state persistence and deterministic material exchange. A second workflow starts Godot in an OpenGL virtual display and produces *actual* world/animal screenshots and animation previews, with a pixel-based distortion gate.

**Known limitations:** This is an early vertical slice. Visual fidelity, creature animation quality, house geometry and structural destruction still require substantial work. A first-person screenshot review is evidence, not approval of the final art direction.

See `../README.md` for complete usage and links to workflows.
