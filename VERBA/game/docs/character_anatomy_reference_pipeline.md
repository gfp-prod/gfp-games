# VERBA NPC anatomy — reference-backed modeling standards
Updated 2026-11-13. Research specification; a Blender/MakeHuman replacement pipeline has not yet been installed.

## Verified references
- Figure drawing: a conventional adult construction is 7–8 head heights, with crotch near mid-height, elbows near the waist and fingertips toward mid-thigh. These are working guides, not compulsory biological ratios. https://applesforartists.org/content/tutorials/proportions/ and https://www.anatomydrawing.com/guides/human-proportions-rules-of-thumb
- Blender: edge loops should follow muscle contours and deforming regions, particularly shoulder, elbow, knee and pelvis. Retopology is needed to turn sculpted shapes into clean animation meshes. https://docs.blender.org/manual/en/5.2/modeling/meshes/structure.html and https://docs.blender.org/manual/en/3.0/modeling/meshes/retopology.html
- Godot: SurfaceTool builds ArrayMesh data with per-vertex UV and normals. https://docs.godotengine.org/en/stable/tutorials/3d/procedural_geometry/surfacetool.html
- MPFB2 (MakeHuman plugin for Blender): free parametric human reference/base meshes, rigging and morph targets. Official system assets and generated outputs are CC0, while plugin code is GPLv3. Do not bundle its GPL code into the game; check licenses of third-party assets separately. https://extensions.blender.org/add-ons/mpfb/ and https://github.com/makehumancommunity/mpfb2/blob/master/LICENSE.md and https://www.makehumancommunity.org/about/license.html

## Current working architecture (retain)
Keep genetic two-parent alleles, age progression, profession, NPC simulation, social care, detachable limbs and saved injury state. The current procedural fallback uses folk_portrait_finish.gd, npc_body_morph.gd, folk_costume_finish.gd and npc_actor.gd. It remains usable while a better artist-modeled base is developed.

## Mandatory review frames
Capture the actual living NPC in an **orthographic front**, **orthographic profile**, **3/4 gameplay camera**, and a **bending-knee / raised-arm motion test**. Review in silhouette without textures first, then as a rendered costume. The figure-drawing canon is an anatomical reference; consciously choose stylization rather than cloning an eight-head human for every person. Test that child heads are proportionally larger and sex-averaged body profiles overlap across bloodlines.

## Procedural anatomy practice
- Block out ribcage and pelvic masses before costumes. Place skull, throat, clavicles, shoulder sockets, elbows, wrists, femoral heads, knees and feet using a documented landmark table.
- Replace uniformly circular limbs with radial contour changes and side-view bowing. Shoulder-to-deltoid and upper/thigh-to-knee transitions need support loops and underlap, never disconnected rings or visible pale cylinders.
- Concentrate enough low-poly cross sections at bending zones to preserve volume. Do not waste polygons smoothing a straight tube.
- Model palms as a wrist-continuous plane with tapered, curved fingers and an opposing thumb. Avoid sphere hands and four equal cylinder fingers.
- A fitted apron must follow inherited waist, chest and hips. Skirts may differ by fashion, not by forcing one body silhouette or obscuring a genetic mesh with a rigid second shell.
- Record proportion ranges using real measured silhouette and orthographic captures; never claim the mesh looks good because unit tests pass.

## Free Blender upgrade path (research candidate; NOT YET DONE)
1. Export three CC0 MPFB-based neutral body references using Blender: lean feminine adult, lean masculine adult and high-variance bloodline adult. Record Blender/MPFB version, source license and 3-view images.
2. Build a stylized, low-poly sculpt **against** those anatomically grounded references. Retopologize joint loops by hand and keep broad, confident facial/torso planes. Bake wear/color detail into small texture atlases.
3. Add compatible morph targets for skull/face, shoulders, chest, waist, hips, stature and body depth. Use existing VERBA genotype for values, never introduce another unrelated appearance RNG.
4. Partition visual arms/legs with concealed seams and caps so existing injury states and detached modules remain viable. Keep collision/hitboxes independent of decorative geometry.
5. Import one GLB NPC into Godot with procedural fallback. Validate parenting, animation, ancestry, conversations and injury tests before any full-population rollout.

Acceptance is a coherent full-body silhouette across face, torso, legs and clothing—not another accessories pass. Preserve exact source/license notes in the asset manifest.
