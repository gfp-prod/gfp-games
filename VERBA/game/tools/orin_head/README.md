# Orin — authored anatomical head prototype (V1)

**Status: experimental; visual sign-off withheld.** This prototype is NOT used by live village NPCs.

## Why this is separate

The old NPC system constructs faces from detached strips, sphere parts and cap-like hair. Technical tests passed while actual faces failed visually. This pilot starts from continuous anatomical topology with real eye and mouth loops, adds expressive deformations, and leaves live NPC meshes untouched.

## Source and rights

- Anatomical source: MakeHuman Community, core asset makehuman/data/3dobjs/base.obj
- Pinned commit: a8bc2d54ff0ac92e78ff71431b1023eda42bf482
- Source mesh asset license: CC0-1.0. MakeHuman application code is AGPL, but is NOT imported into this pipeline.
- A manifest records the source URL and checksum. All Blender authoring/morph/hair code is created for VERBA.

The CC0 head is the starting topology, not a claim that automated modifications are already a professional hand-sculpt.

## Rebuild

Requires Blender and one-time internet access for the pinned MakeHuman CC0 source.

From VERBA/game, run:

    blender -b -t 2 --python tools/orin_head/build_orin_head.py -- --out assets/models/authored/orin_head

Expected outputs:
- orin_head_editable.blend — Blender-editable head, materials, lights, sculpted hair and ten shape keys
- orin_authored_head.glb — Godot-compatible glTF with morph targets
- six Blender studio views, including neutral, profile, blink and speech
- manifest.json with dimensions, license and input-source checksum

Import this GLB with Godot 4.5.2, then capture the actual Godot viewport:

    xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 --rendering-method gl_compatibility --path . --script res://tests/orin_authored_head_gallery.gd

The standalone Godot test outputs seven 1280x720 PNGs, including open eyes, fully closed eyes, speaking, three-quarter and profile. The review adapter reads existing jaw_width, cheek_fullness, nose_width and lip_fullness loci without editing genetic storage or save files.

## Visual gates — do NOT merge until reviewed

1. Eyes are readable and anatomically seated at standard gameplay distance; blink physically covers them.
2. Mouth and lips have readable shape and contrast; speaking animates the real mouth.
3. Short tightly curled hair has clear rooted silhouette from front and profile.
4. Captures come from the actual Godot renderer at the correct source SHA.
5. Genetic inheritance, social simulation, physics, detachable limbs and existing live NPCs remain unchanged.

If the images fail art review, sculpt and improve the editable Blender model. Do not reintroduce detached facial decoration.

## First-pass limitations

The authored morph targets have not yet been artist-approved. The blink target and scalp groom are V1 trials; actual renders must prove whether they work. Passing tests is necessary but not sufficient.
