# VERBA — Free Asset and Open-Source Shortcut Register
**Initial source check:** 2026-11-10. **Policy:** Before custom-building a common asset, shader, tool, or art pipeline, research at least two reliable existing free/open alternatives. Check version and license at the source; evaluate one in an **isolated import/preview scene** before altering the main game.

## Reuse-first rule and visual gate

1. **Look first:** Search maintainers' official free packs, engine addons, GitHub projects, and CC0 material libraries for the exact missing capability.
2. **Decide on style, not mere availability:** Preview the actual asset next to a player-sized reference and against the approved art bible. Do not ship plain prototype geometry because it imports cleanly.
3. **Check technical compatibility:** Godot **4.5.2 / GL Compatibility renderer**, true 3D geometry, scale in meters, texture UVs/alpha, animation rig/collision where relevant, performance and packaging on Windows. Avoid compiled extensions unless necessary.
4. **Pin provenance:** Store project/source URL, version/commit, asset identifiers, license, restrictions and hashes in the asset manifest. Preserve required MIT notices and any attribution obligations. Being personal/noncommercial is not license exemption.
5. **No manual installer:** Bundle approved models/textures/addons in the Godot project through GitHub; the user opens one extracted project.
6. **Review real screenshots:** Render before and after at identical player-eye positions and lighting; check silhouette, material hierarchy, visual consistency and clipping. Reject failed candidates. Reuse never excuses poor taste.
7. **Write custom content only for VERBA's unique needs** (Latin learning, specific hero-book design, world-state magic) or when available assets fail the test. Document why.

## Verified source shortlist (not all adopted)

| Source | Typical use | License / restrictions | VERBA decision |
|---|---|---|---|
| [Quaternius](https://quaternius.com) | Stylized 3D nature, architecture, animated characters; glTF | Check each pack's stated **CC0** | **Already in project** for some forest and wildlife models. Normalize scale/rig, recolor and review before keeping. Specific matching packs preferred to mixed sources. |
| [Poly Haven](https://polyhaven.com/our-api) | Real PBR ground, bark, stones, weathered timber; HDRI | **CC0** assets. Their free public API asks for 'Powered by Poly Haven' credit for apps built on the live API | **High priority.** Bundle curated texture files rather than needing the API at runtime. Source provenance must be kept. |
| [ambientCG](https://ambientcg.com) | CC0 PBR materials, normal/roughness maps | [CC0](https://docs.ambientcg.com/license/) | **High priority** material alternatives for parchment, wet rock, stucco, and soil; compare artistic coherence and texture density. |
| [KayKit Medieval Builder](https://kaylousberg.itch.io/kaykit-medieval-builder-pack) | Modular cottage/tower/village construction | **CC0**, FBX/OBJ/DAE/glTF; check exact pack | **Promising** for foundations or blockouts. Need a texture/material art pass; low-poly untouched assets may not meet the hero-building standard. |
| [Kenney Nature Kit](https://kenney.nl/assets/nature-kit) | Small stones, distant foliage, modular scenery | **CC0** | **Distant filler/blockout only.** Its simple materials and miniature scale conflict with the existing Quaternius trees at hero distance. |
| [Kenney Retro Fantasy Kit](https://kenney.nl/assets/retro-fantasy-kit) | Village/dungeon/ruin silhouettes and modular architecture | **CC0** | **Candidate** for authored landmark prototyping; do not confuse simplistic shapes with final art. |
| [ProtonScatter](https://github.com/HungryProton/scatter) | Editor-side procedural 3D foliage/prop scattering with modifier stack | **MIT addon**, include notice. Its demo textures contain additional terms; **do not redistribute demo textures blindly** | **Isolated test candidate.** Could replace ad hoc placement loops. Do NOT alter working MultiMesh/physics until tested in the GL Compatibility pipeline. |
| [Terrain3D](https://github.com/TokisanGames/Terrain3D) | Editable texture-painted terrain with multi-LOD vegetation | **MIT GDExtension** | **Later research only.** Compiled platform binaries and terrain migration may break existing saves/colliders. First attempt material and composition fixes on existing terrain. |
| [Godot Shaders](https://godotshaders.com) | Small free shader snippets e.g. atmospheric particles or wind | Source-specific. Most shared *code* snippets MIT; textures and preview media may not be | **Review individual shaders** for 3D/GL Compatibility. Do not copy a 2D canvas_item shader into 3D geometry by mistake. |

## Current aesthetic-phase priorities and shortcut decisions

| Work | Find first | Create only if necessary |
|---|---|---|
| Better terrain | Poly Haven / ambientCG CC0 PBR matched soil, moss, path and rock sets | Multi-texture blend implementation or corrected world-scale UVs |
| Foliage density | ProtonScatter and existing Quaternius/curated vegetation assets | Specialized procedural planting rules for the desired forest silhouette |
| Cottage and village | KayKit / Quaternius medieval packs + existing cottage authored source | Distinctive readable hero building/modeling, doors and collision |
| Books | CC0 leather/paper/metal PBR, source art references | VERBA-specific physical grimoire mesh and interactions |
| Wildlife | Already bundled Quaternius models; vetted animated free replacements | Corrected rigs/proportions and behavioral animation blending |
| Lighting and weather | Built-in Godot Environment and existing proven public techniques | Unique authored grading/VFX if it improves side-by-side screenshots |

**Not installed by writing this register:** Every item above is a prospect unless already marked bundled. Adoption requires a separate proof commit and visual test.
