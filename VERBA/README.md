# VERBA — The Hollow Vale
A first-person Latin magic and living-world RPG built in Godot 4.

**This is an early, playable development project, not a finished RPG.** The single valley and interaction systems are under active construction.

## Open the current game
The full project is committed directly to this GitHub branch. Download the `verba-godot` branch ZIP, **extract it to a permanent folder**, then open `VERBA/game/project.godot` in Godot 4.5+. Allow the initial Godot import and press **F5**. Do not open directly out of a ZIP or a temporary folder. No external texture/model installer is required.

## Controls
- WASD + mouse: first-person movement and look (click the game window once to capture the mouse)
- Shift sprint, Space jump, E interact/collect, F use held item
- Enter: type an incantation and press Enter again to cast it
- G: raise/lower the *physical* grimoire; A/D or mouse wheel to turn pages
- While the grimoire is open: **B cycles found Latin books, N begins a reading-comprehension question, 1/2/3 answer it, S saves the persistent world, L restores it**
- Esc: close the book or release mouse, H: contextual guidance, F3: optional movement diagnostics

## Begin your education

Find the physical book **De Herbis** on an inscribed stone near the starting clearing. Press **E** to take it. Read the Latin on the raised grimoire, press **N** to answer a Latin comprehension question using **1/2/3**. A first correct answer earns one-time scholar XP, increases mana on leveling, and teaches efficient botany magic. Two further books cover animals and fire/water. They are discoverable at separate locations. Review the [implemented book progression](game/docs/BOOKS_AND_SCHOLAR_PROGRESSION.md).

## Verified development changes
- Real 3D animal assets: deer/stag, wolf, fox, rabbit and crow; animated asset renders, motion previews and visual-size checks are produced by GitHub Actions
- A continuous heightmap collider and physical first-person / animal bodies
- Interactive flora, stones and wildlife with independently mutable states; animal hunger, hunting, grazing, wetness, health and ecological responses
- An **attested Latin grammar starter**, recognizing singular and plural imperatives plus optional vocative address: `cresce arbor`, `crescite arbores`, `dormi lupe`, `dormite lupi`
- Multi-target casts routed through the same ecological objects as natural events, not a separate scripted visual effect table
- Deterministic local heat transfer from burning objects; rain/moisture can quench fire
- Living-world persistence for individual object histories, animals, weather and player position; autosave every 45 seconds in a live graphical game
- Six positioned forest groves rather than a mostly empty procedural field, and a physical Latin number-agreement inscription near the starting cairn

## What is not complete
- The Latin grammar is a **small explicitly checked subset**, not a full parser for classical Latin.
- The landscape, animals, cottage, UI, and grimoire require further artistic refinement. A passing automation test is not proof that the whole game looks good.
- Persistent world history is currently for the single valley; a streamed, offscreen regional ecosystem remains architectural work.
- Godot CI validates code, movement, persistence, ecology and asset rendering. It cannot reproduce all Windows GPU behaviors; visual review and in-game playtesting remain necessary.

## Automated verification
- [Native Godot tests](../../actions/workflows/verba-check.yml) validate startup, movement/navigation, Latin effects, ecosystem persistence, fire propagation and animated animal models.
- [Godot-rendered visual QA](../../actions/workflows/verba-visual-qa.yml) captures actual first-person 3D screenshots and animal animation frames/GIFs on GitHub, so broken models can be caught without the player acting as QA.
- CI runs on commits. Downloadable image/video artifacts belong to the workflow runs.

## Asset origin
See `game/assets/models/cc0/wildlife/SOURCES.md`, `SOURCES_EXTRA.md`, `RABBIT_SOURCE.md`, and the nature model source notes for licenses and attribution. The pre-existing real-texture material maps are included directly. Asset licenses still apply to a personal project.

GitHub's `main` branch remains separate. This development branch is public because the `gfp-games` repository is public.
