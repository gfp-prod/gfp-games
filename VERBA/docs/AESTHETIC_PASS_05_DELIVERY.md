# VERBA — Aesthetic Pass 05: landmark craft, held hands and creek identity
**Date:** November 10, 2026 (America/New_York)  
**Branch:** `verba-godot`  
**Scope:** In-engine hero-asset iteration on the existing Godot alpha. This is **not** the completed aesthetic overhaul.

## Changes made to real game source

1. `scripts/cottage_hero.gd`: a batch-built uneven slate shingle surface, dark timber ridge and gable detailing, small foundation stones, believable herb planter and porch woodwork. Called directly on the existing HermitCottage parent, leaving its separate collision shell intact. The screenshot still reads as a largely flat, blocky imported house; this is a finishing pass, **not** a satisfactory replacement hero building.
2. `scripts/glove_art.gd`: modeled, tapered palms, four bent fingers, opposed thumbs and wrist cuffs. `grimoire_visual.gd` now uses the modeled grips in first person; no change to the Latin reading state machine.
3. `scripts/landmark_tree.gd`: a unique crooked, weeping ash by the creek, using a low-draw-call foliage mesh and twisted bark/branch geometry. It is a `SIM_OBJECT` with a real trunk collision shape, rather than a nonreactive scenery-only object. Its authored UID `700001` and saved main RNG state protect the identity and placement of preexisting world objects across save loads.
4. `scripts/scenic_details.gd`: replaced bright ruler-straight bridge handrails with batched dark sagging ropes between posts, carved wood caps, unchanged physical deck.
5. `tests/hero_art_test.gd` and `verba-check.yml`: assert cottage roof topology and batched vegetation, bilateral modeled hand geometry, and the weeping-tree's nontrivial 3D silhouette. `world_gallery.gd` now includes the creek-side `world_willow_bank.png` framing shot. The visual workflow watches all new art source files.

## What real rendered reviews showed

- The physical grimoire remains readable; the glove fingers now curve against its lower leather binding, but look deliberately stylized and need further authoring.
- The cottage has more layered craftsmanship, but the existing house still feels too small, symmetrical and boxlike to carry the game's fantasy identity. This is the principal remaining deficit.
- In the first rendered weeping-tree shot, its leaves were oversized, saturated broad polygons. Reduced leaf dimensions, increased leaf count and quieted the palette after visual inspection. The goal is a hanging curtain, not bright square cards.
- The bridge was a weak visual focal point because of pale straight rails. Replaced rails with dark, suspended rope; the bridge is still physically traversable.
- The creek, grass coverage, distant tree repetition, hero cottage and broader environmental color language are still not cohesive enough. No claim of final art quality should follow from automated tests.

## Asset research to prevent needless reinvention

The next cottage rebuild should compare licensed, *actual downloaded models* before making another code-generated shell:
- [Witch Cottage and Apothecary](https://3dassets.dev/packs/witch-cottage-and-apothecary): CC0, 55 modular GLB models plus a starter cottage shell, timber framing, thatched roof, chimney, hearth and furnishings. Explicit AI-use disclosure. Manifest: https://3dassets.dev/api/v1/packs/witch-cottage-and-apothecary . **Researched, not installed.** Download/CDN availability must be checked in the working environment before integration.
- [Kenney Fantasy Town Kit](https://kenney.nl/assets/fantasy-town-kit): CC0 modular 3D fantasy architecture, useful for village extensions and consistent authored building silhouettes. **Not installed.**
- [Quaternius Medieval Village MegaKit](https://quaternius.itch.io/medieval-village-megakit): CC0 fantasy buildings and modular pieces; free Standard tier. This game's existing free Quaternius imports already establish asset provenance; do not treat one more unaltered model as automatically solving the style problem. **Not installed.**

Prefer an authored, coherent **shape language** over additional scattered props: nonuniform roof pitches, cottage-to-landscape material transition, tall and crooked silhouettes, clear daytime warmth, and moonlit eeriness. Retain real Latin vocabulary as world objects rather than turning all instruction into UI.

## Reproduction

Download the `verba-godot` branch, open `VERBA/game/project.godot` in Godot 4.5.2+, run `tests/hero_art_test.gd` and all tests in `.github/workflows/verba-check.yml`; examine the GIF/PNG artifact from `.github/workflows/verba-visual-qa.yml`, especially:
- `latin_book_passage.png`
- `world_cottage_front.png`
- `world_creek_bank.png`
- `world_willow_bank.png`

Passing test assertions proves technical integrity, **not** acceptable art direction. The visual pass remains in progress.
