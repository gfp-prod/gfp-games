#!/usr/bin/env python3
"""VERBA Orin V1: isolated, editable anatomical-head pilot.

Source mesh: MakeHuman community *base mesh* (CC0-1.0, not the AGPL source).
This is deliberately a separate asset pipeline; it NEVER replaces a live NPC.
Run: blender -b -t 2 --python build_orin_head.py -- --out /tmp/orin-head
"""
import argparse
import hashlib
import json
import math
from pathlib import Path
import sys
import urllib.request

import bpy
import bmesh
from mathutils import Vector

SOURCE_COMMIT = "a8bc2d54ff0ac92e78ff71431b1023eda42bf482"
SOURCE_URL = (
    "https://raw.githubusercontent.com/makehumancommunity/makehuman/"
    + SOURCE_COMMIT + "/makehuman/data/3dobjs/base.obj"
)
SOURCE_LICENSE = "CC0-1.0 (MakeHuman bundled base-mesh asset)"
SHAPES = (
    "Blink_L", "Blink_R", "MouthOpen", "Smile", "Frown",
    "BrowRaise", "JawWidth", "CheekWidth", "NoseWidth", "LipVolume"
)


def arg_parser():
    args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    p = argparse.ArgumentParser()
    p.add_argument("--out", required=True, type=Path)
    p.add_argument("--base-obj", type=Path, default=None)
    return p.parse_args(args)


def clear_scene():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for datablock in list(bpy.data.meshes):
        if datablock.users == 0:
            bpy.data.meshes.remove(datablock)


def ensure_base(path):
    if path is not None:
        if not path.is_file():
            raise FileNotFoundError(path)
        return path
    cached = Path("/tmp/verba_makehuman_cc0_head_base.obj")
    if not cached.is_file() or cached.stat().st_size < 300000:
        urllib.request.urlretrieve(SOURCE_URL, cached)
    if cached.stat().st_size < 300000:
        raise RuntimeError("MakeHuman CC0 OBJ is absent or truncated")
    return cached


def read_human_base(path):
    vertices, faces = [], []
    # Parse the data file, not the AGPL MakeHuman implementation.
    with path.open("r", encoding="utf8", errors="replace") as fh:
        for line in fh:
            if line.startswith("v "):
                _, x, y, z, *_ = line.split()
                # MakeHuman Y-up/depth Z -> Blender Z-up/depth -Y.
                vertices.append((float(x), -float(z), float(y)))
            elif line.startswith("f "):
                indices = []
                for token in line.split()[1:]:
                    index = int(token.split("/")[0])
                    indices.append(index - 1 if index > 0 else len(vertices) + index)
                if len(indices) >= 3:
                    faces.append(tuple(indices))
    if len(vertices) < 10000 or len(faces) < 7000:
        raise RuntimeError("Anatomical source OBJ is not the full MakeHuman base")
    mesh = bpy.data.meshes.new("ORIN_CC0_FacialTopology")
    mesh.from_pydata(vertices, [], faces)
    mesh.update()
    obj = bpy.data.objects.new("Orin_AnatomicalHead", mesh)
    bpy.context.collection.objects.link(obj)
    return obj, len(vertices), len(faces)


def crop_and_normalize(obj):
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    low = min(v.co.z for v in bm.verts)
    high = max(v.co.z for v in bm.verts)
    span = high - low
    if span < .5:
        raise RuntimeError("Source orientation/height is implausible")
    # Retain the head, ears, jaw and upper neck; never leave the full torso.
    cut = high - .196 * span
    bmesh.ops.bisect_plane(
        bm, geom=list(bm.verts) + list(bm.edges) + list(bm.faces),
        dist=.00001, plane_co=Vector((0, 0, cut)),
        plane_no=Vector((0, 0, 1)), clear_inner=True, clear_outer=False
    )
    loose = [v for v in bm.verts if v.co.z < cut - 1e-4]
    if loose:
        bmesh.ops.delete(bm, geom=loose, context="VERTS")
    bm.to_mesh(obj.data)
    bm.free()
    obj.data.update()
    if len(obj.data.vertices) < 700:
        raise RuntimeError("Head crop lost its anatomical topology")
    xmin = min(v.co.x for v in obj.data.vertices)
    xmax = max(v.co.x for v in obj.data.vertices)
    ymin = min(v.co.y for v in obj.data.vertices)
    ymax = max(v.co.y for v in obj.data.vertices)
    zmin = min(v.co.z for v in obj.data.vertices)
    zmax = max(v.co.z for v in obj.data.vertices)
    scale = .52 / (zmax - zmin)
    # Orin head pivot at the cranium's centre; local Z is up.
    for vert in obj.data.vertices:
        vert.co.x = (vert.co.x - (xmin + xmax) * .5) * scale
        vert.co.y = (vert.co.y - (ymin + ymax) * .5) * scale
        vert.co.z = (vert.co.z - (zmin + zmax) * .5) * scale
    obj.data.update()
    return {"mesh_vertices": len(obj.data.vertices),
            "mesh_polygons": len(obj.data.polygons),
            "body_crop_fraction": .196, "head_height_m": .52,
            "head_width_m": (xmax - xmin) * scale,
            "head_depth_m": (ymax - ymin) * scale}


def make_material(name, rgba, roughness=.86):
    m = bpy.data.materials.new(name)
    m.diffuse_color = (*rgba[:3], 1)
    m.use_nodes = True
    bsdf = m.node_tree.nodes.get("Principled BSDF")
    if bsdf:
        bsdf.inputs["Base Color"].default_value = (*rgba[:3], 1)
        bsdf.inputs["Roughness"].default_value = roughness
    return m


def smoothstep(a, b, x):
    t = max(0., min(1., (x - a) / (b - a)))
    return t * t * (3. - 2. * t)


def bell(x, center, radius):
    return math.exp(-((x - center) / radius) ** 2)


def facial_shapes(head):
    # A single continuous *anatomical* skin mesh retains the original
    # MakeHuman eye, lip, jaw and nasolabial edge loops. Shape keys
    # deform that same mesh rather than moving detached decorative props.
    head.shape_key_add(name="Basis", from_mix=False)
    baseline = [v.co.copy() for v in head.data.vertices]
    xs = [v.x for v in baseline]
    ys = [v.y for v in baseline]
    zs = [v.z for v in baseline]
    width = max(xs) - min(xs)
    front = min(ys)
    back = max(ys)
    # Blend the deformation over the visible front hemisphere only.
    front_center = front + .33 * (back - front)
    eye_x = .205 * width
    eye_z = .054
    mouth_z = -.090
    brow_z = .108

    def weight_face(v):
        return 1. - smoothstep(front_center, back, v.y)

    for name in SHAPES:
        key = head.shape_key_add(name=name, from_mix=False)
        for i, base in enumerate(baseline):
            v = base.copy()
            frontal = weight_face(v)
            if name.startswith("Blink_"):
                side = -1 if name.endswith("L") else 1
                influence = (bell(v.x, side * eye_x, .085)
                             * bell(v.z, eye_z, .034) * frontal)
                if v.z >= eye_z:
                    v.z -= .022 * influence
                else:
                    v.z += .013 * influence
                # Eyelid skin moves over the eye, not the globe.
                v.y -= .003 * influence
            elif name == "MouthOpen":
                w = bell(v.x, 0, .074) * bell(v.z, mouth_z, .060) * frontal
                if v.z < mouth_z:
                    v.z -= .036 * w
                    v.y -= .004 * w
                elif v.z >= mouth_z:
                    v.z += .005 * w
            elif name in ("Smile", "Frown"):
                w = bell(abs(v.x), .050, .033) * bell(v.z, mouth_z, .038) * frontal
                v.z += (.022 if name == "Smile" else -.018) * w
                if name == "Smile":
                    v.x *= 1. + .045 * w
            elif name == "BrowRaise":
                w = bell(abs(v.x), eye_x, .075) * bell(v.z, brow_z, .030) * frontal
                v.z += .023 * w
            elif name == "JawWidth":
                w = (1. - smoothstep(-.155, .015, v.z))
                v.x += math.copysign(.014 * w, v.x)
            elif name == "CheekWidth":
                w = bell(abs(v.x), .095, .065) * bell(v.z, -.014, .055)
                v.x += math.copysign(.014 * w, v.x)
            elif name == "NoseWidth":
                w = bell(v.x, 0, .045) * bell(v.z, -.017, .08) * frontal
                v.x *= 1. + .26 * w
            elif name == "LipVolume":
                w = bell(v.x, 0, .052) * bell(v.z, mouth_z, .028) * frontal
                v.y -= .012 * w
                v.z += (.008 if v.z > mouth_z else -.007) * w
            key.data[i].co = v
        key.value = 0.
        key.slider_min = 0.
        key.slider_max = 1.


def sculpt_curly_crop(head, hair_mat):
    # Grow the hair from the *existing cranial surface* so it follows
    # the forehead and crown. This has full 3-D silhouette, not cards.
    # Isolated cloth/hair geometry can be replaced by authored grooms
    # without touching the facial topology or animation.
    src = head.data
    scalp = bpy.data.meshes.new("Orin_RootedCurls")
    index_map, pts, faces = {}, [], []
    for poly in src.polygons:
        inds = list(poly.vertices)
        if not all(src.vertices[j].co.z > .092 for j in inds):
            continue
        for j in inds:
            if j not in index_map:
                index_map[j] = len(pts)
                pts.append(src.vertices[j].co.copy())
        faces.append(tuple(index_map[j] for j in inds))
    if len(faces) < 120:
        raise RuntimeError("No meaningful cranial surface for rooted hair")
    scalp.from_pydata(pts, [], faces)
    scalp.update()
    hair = bpy.data.objects.new("Orin_SculptedCurlyCrop", scalp)
    bpy.context.collection.objects.link(hair)
    hair.data.materials.append(hair_mat)
    # Large-scale waves and small dense curls are geometric, not a
    # smooth dark helmet plus floating strands.
    for vert in scalp.vertices:
        p = vert.co
        rad = math.sqrt(p.x*p.x+p.y*p.y)
        angular = math.atan2(p.y,p.x)
        curl = (math.sin(angular*19.0+p.z*92.)
                * math.cos(angular*10.5-p.z*77.))
        normal = p.normalized() if p.length > .01 else Vector((0,0,1))
        thickness = .014 + .005 * curl + .004 * math.sin(p.x*103.0+p.y*71.)
        p += normal * thickness
        # No long pointed curls over eyebrows.
        if p.z < .107:
            p.z += .003
    mod = hair.modifiers.new("ActualCrownVolume", "SOLIDIFY")
    mod.thickness = .018
    mod.offset = 0
    hair["style"] = "short tightly curled crop"
    hair["rooted_on_cc0_cranium"] = True
    return hair


def light_and_camera():
    world = bpy.context.scene.world or bpy.data.worlds.new("StudioWorld")
    bpy.context.scene.world = world
    world.color = (.09, .105, .12)
    def light(name, loc, power, size):
        data = bpy.data.lights.new(name, "AREA")
        data.energy = power
        data.shape = "DISK"
        data.size = size
        obj = bpy.data.objects.new(name, data)
        bpy.context.collection.objects.link(obj)
        obj.location = loc
        obj.rotation_euler = (Vector((0,0,0)) - obj.location).to_track_quat("-Z","Y").to_euler()
    light("Key_PaleWarm", (-.62,-.68,.76), 330, 1.3)
    light("Fill_WideCool", (.68,-.34,.28), 180, 1.5)
    light("Rim_Dim", (.24,.55,.6), 250, 1.0)
    cam_data = bpy.data.cameras.new("OrinReviewCamera")
    cam = bpy.data.objects.new("OrinReviewCamera", cam_data)
    bpy.context.collection.objects.link(cam)
    bpy.context.scene.camera = cam
    cam_data.type = "ORTHO"
    cam_data.ortho_scale = .76
    scene = bpy.context.scene
    scene.render.resolution_x = 900
    scene.render.resolution_y = 900
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.film_transparent = False
    try:
        scene.render.engine = "BLENDER_EEVEE_NEXT"
    except TypeError:
        scene.render.engine = "BLENDER_EEVEE"
    scene.render.image_settings.color_mode = "RGBA"
    return cam


def look(cam, xyz):
    cam.location = Vector(xyz)
    cam.rotation_euler = (Vector((0,0,0)) - cam.location).to_track_quat("-Z","Y").to_euler()


def render_studio(head, cam, folder):
    poses = [
        ("front_neutral", (0,-1.25,.02), {}),
        ("three_quarter", (.68,-1.0,.09), {}),
        ("left_profile", (1.18,0,.06), {}),
        ("blink_closed", (0,-1.25,.02), {"Blink_L":1., "Blink_R":1.}),
        ("mouth_open", (0,-1.25,.02), {"MouthOpen":1.}),
        ("smile", (0,-1.25,.02), {"Smile":1.})
    ]
    for name, camera, shape_values in poses:
        for key in head.data.shape_keys.key_blocks:
            if key.name != "Basis":
                key.value = shape_values.get(key.name, 0.)
        look(cam, camera)
        bpy.context.scene.render.filepath = str(folder / (name+".png"))
        bpy.ops.render.render(write_still=True)
    for key in head.data.shape_keys.key_blocks:
        if key.name != "Basis":
            key.value = 0.


def main():
    args = arg_parser()
    out = args.out.resolve()
    out.mkdir(parents=True, exist_ok=True)
    clear_scene()
    base = ensure_base(args.base_obj)
    source_digest = hashlib.sha256(base.read_bytes()).hexdigest()
    head, source_vertices, source_faces = read_human_base(base)
    dimensions = crop_and_normalize(head)
    skin = make_material("Orin_WarmUmberSkin", (.34,.185,.125))
    hair_mat = make_material("Orin_DarkCurls", (.052,.046,.041))
    head.data.materials.append(skin)
    for f in head.data.polygons:
        f.material_index = 0
        f.use_smooth = True
    facial_shapes(head)
    hair = sculpt_curly_crop(head, hair_mat)
    cam = light_and_camera()
    render_studio(head, cam, out)
    bpy.ops.wm.save_as_mainfile(filepath=str(out / "orin_head_editable.blend"))
    bpy.ops.object.select_all(action="DESELECT")
    for o in (head, hair):
        o.select_set(True)
    bpy.context.view_layer.objects.active = head
    bpy.ops.export_scene.gltf(
        filepath=str(out / "orin_authored_head.glb"),
        export_format="GLB", use_selection=True,
        export_morph=True, export_morph_normal=True,
        export_materials="EXPORT"
    )
    summary = {
        "status": "art prototype; not integrated or artistically approved",
        "asset": "orin_authored_head.glb",
        "editable_source": "orin_head_editable.blend",
        "source_url": SOURCE_URL,
        "source_license": SOURCE_LICENSE,
        "base_source_sha256": source_digest,
        "base_source_vertices": source_vertices,
        "base_source_faces": source_faces,
        "origin": "CC0 MakeHuman base mesh; original VERBA authored modifications",
        "blend_shapes": list(SHAPES),
        "facial_mesh": dimensions,
        "integration": "Opt-in review only; no NPC replacement."
    }
    (out / "manifest.json").write_text(json.dumps(summary,indent=2)+"\n")
    print("PASS: ORIN authored head Blender source, morphs and GLB exported")


if __name__ == "__main__":
    main()
