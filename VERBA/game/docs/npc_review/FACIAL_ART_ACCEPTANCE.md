# VERBA – facial art acceptance gate

**Status: NOT ACCEPTED.** Automated engine tests and screenshot completion are evidence of functioning code, **not** evidence that NPCs look good.

## Current failure report (Nov 13, 2026)

The real Godot portraits show pinhole or bead-like eyes, apparent immobile eyelids, mouths and lips too faint to read, and hairstyles that mainly resemble helmets or hanging cards. The output misses the game's intentional grounded, low-poly dark-fantasy art direction. Do not call minor mesh or lighting corrections an aesthetic solution.

## Visual acceptance before merging

1. **Eyes readable:** all adult NPCs have recognizable sclera, iris, pupil and upper/lower eye boundaries at neutral third-person distance. Distinct inherited eye shape is visible without extreme shine, pinhole pupils or floating eyelashes.
2. **A blink you can see:** use the same live NPC, head pose, camera, and lighting for open and fully closed frames; skin-colored eyelid surfaces must actually obscure **both pupils**, then expose them again when reopened. Merely moving a node or changing an animation flag is not sufficient.
3. **Mouth readable:** a neutral expression clearly displays upper and lower lips and the resting oral crease, with restrained but visible skin-relative pigmentation. Talking produces a visibly changing mouth opening and lower lip; smiles and frowns change expression without tearing the face.
4. **Hair readable:** from front, three-quarter and profile, a stranger can recognize the intended style (crop/curls, braids, swept, loose/wavy, tied hair) **without reading the mesh node name**. Parting and hairline must appear rooted in the head, not smooth scalp caps with floating plates or cables.
5. **Anatomical variety:** at least one dark-skinned adult man, two visibly different adult women, and two children show independent inherited eyes, mouth, nose, skull and hairstyle differences; no disproportionate mannequin or overbuilt torso regression.
6. **Actual game proof:** use real 1280×720 Godot game-frame screenshots, not concept images. Capture neutral, blink open, blink fully closed, and talking expressions for Ida, Orin, Sela and Lena; inspect real world light as well as the controlled diagnostic fill.
7. **Protection:** maintain the inherited genotype/phenotype mapping, joint and gaze controls, modular severable limbs, social care, bloodline behavior, and all physical-world collisions.

## Required procedure

- Start by reviewing screenshots. Write down **visible** failures, not just broken tests.
- Improve one readable character head and its expression mechanics; prove it in the front/profile/three-quarter and animation frames.
- Only then apply the same system across the rest of the NPC gene ranges.
- Reject the build if the character is not convincingly human and stylistically consistent even when all automated tests are green.
- Keep the work on draft PR #36, unmerged, until actual visual sign-off.

## Production direction

The existing procedural face system needs a real design/animation-quality baseline. Long-term, use a stylized **authored** base head with deformation-friendly eye and mouth topology and a handful of artist-readable morph controls. The hereditary genome should drive those controls; it should not generate independent decorative facial parts forever. Such a replacement must be piloted separately and may not discard the working genetics, life simulation, or physical body systems.
