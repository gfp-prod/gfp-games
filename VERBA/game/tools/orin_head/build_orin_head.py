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
    # Persistent source vertex IDs are essential: MakeHuman's hand-authored
    # CC0 expression targets address ORIGINAL OBJ vertex indices.
    # Save those indices BEFORE cropping/discarding helper components.
    bm.verts.ensure_lookup_table()
    bm.verts.index_update()
    source_id_layer = bm.verts.layers.int.new("mh_base_index")
    for source_v in bm.verts:
        source_v[source_id_layer] = source_v.index
    low = min(v.co.z for v in bm.verts)
    high = max(v.co.z for v in bm.verts)
    span = high - low
    if span < .5:
        raise RuntimeError("Source orientation/height is implausible")
    # Only upper 15% of body height: retain real skull and jaw, NOT
    # shoulder/chest helper drapes. Earlier .196 included shoulders.
    cut = high - .150 * span
    bmesh.ops.bisect_plane(
        bm, geom=list(bm.verts) + list(bm.edges) + list(bm.faces),
        dist=.00001, plane_co=Vector((0,0,cut)),
        plane_no=Vector((0,0,1)), clear_inner=True, clear_outer=False
    )
    loose = [v for v in bm.verts if v.co.z < cut-1e-4]
    if loose:
        bmesh.ops.delete(bm,geom=loose,context="VERTS")

    # The MakeHuman base.obj also contains many disconnected helper
    # meshes. Earlier we unknowingly rendered them as sheets hanging
    # over the eyes, nose and shoulders. Retain ONE continuous skin
    # shell; extract the two genuine eyeball components separately.
    components = []
    unvisited = set(bm.verts)
    while unvisited:
        seed = unvisited.pop()
        component = {seed}
        stack = [seed]
        while stack:
            v = stack.pop()
            for e in v.link_edges:
                other = e.other_vert(v)
                if other in unvisited:
                    unvisited.remove(other)
                    component.add(other)
                    stack.append(other)
        components.append(component)
    components.sort(key=len,reverse=True)
    if len(components[0])<2200:
        raise RuntimeError("Failed to find full continuous MakeHuman skin")
    eyes_raw = []
    for comp in components[1:]:
        n = len(comp)
        center = sum((v.co for v in comp),Vector((0,0,0))) / n
        if 69<=n<=78 and abs(center.x)>.03 and (
                center.z > cut+.43*(high-cut)):
            # Copy the eye faces NOW: deleting helper components from
            # BMesh will invalidate all BMVert/BMFace references.
            ordered = sorted(comp,key=lambda v:v.index)
            lookup = {v:i for i,v in enumerate(ordered)}
            triangles = []
            seen = set()
            for v in ordered:
                for f in v.link_faces:
                    if f in seen or not all(x in lookup for x in f.verts):
                        continue
                    seen.add(f)
                    triangles.append(tuple(lookup[x] for x in f.verts))
            eyes_raw.append(([v.co.copy() for v in ordered], triangles))
    # The 72-vertex CC0 eyeball pieces occur in a left/right pair.
    # If source topology ever changes, FAIL rather than synthesize
    # eyes from unrelated clothing helpers.
    if len(eyes_raw)!=2:
        raise RuntimeError("Expected two anatomical eye components, found "
                           + str([len(p) for p in eyes_raw]))
    main = components[0]
    to_remove = [v for comp in components[1:] for v in comp]
    bmesh.ops.delete(bm,geom=to_remove,context="VERTS")
    bm.to_mesh(obj.data)
    bm.free()
    obj.data.update()
    if obj.data.attributes.get("mh_base_index") is None:
        raise RuntimeError("Anatomical source-index layer lost during BMesh crop")
    if len(obj.data.vertices)<2000:
        raise RuntimeError("Head extraction lost facial edge loops")

    xmin = min(v.co.x for v in obj.data.vertices)
    xmax = max(v.co.x for v in obj.data.vertices)
    ymin = min(v.co.y for v in obj.data.vertices)
    ymax = max(v.co.y for v in obj.data.vertices)
    zmin = min(v.co.z for v in obj.data.vertices)
    zmax = max(v.co.z for v in obj.data.vertices)
    scale = .52/(zmax-zmin)
    def normalize(v):
        return Vector((
            (v.x-(xmin+xmax)*.5)*scale,
            (v.y-(ymin+ymax)*.5)*scale,
            (v.z-(zmin+zmax)*.5)*scale))
    for v in obj.data.vertices:
        v.co = normalize(v.co)
    obj.data.update()
    obj["makehuman_base_to_meters"] = scale

    # Build eye objects from their ORIGINAL anatomically seated topology,
    # not 2D cartoon decals. Assign a controlled separate iris/pupil.
    eyes = []
    for raw_points, faces in eyes_raw:
        points = [normalize(p) for p in raw_points]
        if len(faces)<50:
            raise RuntimeError("MakeHuman eye component lost its eye mesh")
        m = bpy.data.meshes.new("Orin_Eyeball_Anatomical")
        m.from_pydata(points, [], faces)
        m.update()
        o = bpy.data.objects.new(
            "Orin_Eyeball_Left" if sum(p.x for p in points)<0
            else "Orin_Eyeball_Right",m)
        bpy.context.collection.objects.link(o)
        eyes.append(o)
    if (len(eyes)!=2 or eyes[0].name==eyes[1].name):
        raise RuntimeError("Paired anatomically seated eyes not preserved")
    dimensions = {
        "mesh_vertices":len(obj.data.vertices),
        "mesh_polygons":len(obj.data.polygons),
        "body_crop_fraction":.150,
        "discarded_helper_components":len(components)-3,
        "head_height_m":.52,
        "head_width_m":(xmax-xmin)*scale,
        "head_depth_m":(ymax-ymin)*scale}
    if dimensions["head_width_m"]>.48:
        raise RuntimeError("Shoulder/helper geometry still attached to face")
    return dimensions, eyes



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


def _cc0_expression_target(filename):
    """Use the original authored, topology-specific MakeHuman expression."""
    cache = Path("/tmp") / ("verba_mh_cc0_"+filename)
    url = (f"https://raw.githubusercontent.com/makehumancommunity/makehuman/"
           f"{SOURCE_COMMIT}/makehuman/data/targets/expression/units/"
           f"african/{filename}")
    if not cache.is_file():
        urllib.request.urlretrieve(url, cache)
    data = cache.read_text("utf-8")
    if "explicitly released as CC0" not in data:
        raise RuntimeError("Unverified authoring license on "+filename)
    offsets = {}
    for line in data.splitlines():
        if not line.strip() or line.startswith("#"):
            continue
        parts = line.split()
        if len(parts)<4: continue
        idx = int(parts[0])
        dx,dy,dz = map(float,parts[1:4])
        # Original MakeHuman: X side, Y up, Z forward.
        # Blender head:       X side, Z up, Y=-source Z.
        offsets[idx] = Vector((dx,-dz,dy))
    if len(offsets)<45:
        raise RuntimeError("Authored expression shape lacks source data: "+filename)
    return offsets


def facial_shapes(head):
    """Retarget verified CC0 eye/mouth loops, NOT Gaussian eyebrow bands.

    The old procedural approximation tore across eyeballs on full blinks
    and pulled the entire chin down into a cardboard flap on speech.
    These morphs are authored on the exact same MakeHuman base topology.
    """
    head.shape_key_add(name="Basis", from_mix=False)
    baseline = [v.co.copy() for v in head.data.vertices]
    mesh_ids = head.data.attributes["mh_base_index"].data
    source_to_output = {}
    for dst_index, attr in enumerate(mesh_ids):
        source_to_output[int(attr.value)] = dst_index
    if len(source_to_output)<2000:
        raise RuntimeError("Lost original anatomical topology index map")
    scale = float(head["makehuman_base_to_meters"])
    target_map = {
        "Blink_L":["eye-left-closure.target"],
        "Blink_R":["eye-right-closure.target"],
        "MouthOpen":["mouth-open.target"],
        "Smile":["mouth-corner-puller.target"],
        "Frown":["mouth-depression.target"],
        "BrowRaise":["eyebrows-left-up.target","eyebrows-right-up.target"]
    }
    source_targets = {shape:[_cc0_expression_target(name) for name in files]
                      for shape,files in target_map.items()}
    # Old Gaussian morphs are retained ONLY for inherited morphological
    # differences, not for facial expression or eyelid animation.
    ys = [v.y for v in baseline]
    front = min(ys)
    back = max(ys)
    front_center = front+.33*(back-front)

    def frontal_weight(v):
        t = smoothstep(front_center,back,v.y)
        return 1.-t

    for name in SHAPES:
        key=head.shape_key_add(name=name,from_mix=False)
        moved=0
        if name in source_targets:
            sources = source_targets[name]
            accumulated = {}
            for original in sources:
                for src_id,vec in original.items():
                    if src_id not in source_to_output:
                        continue
                    dst=source_to_output[src_id]
                    # The source MouthOpen unit is an extreme theatrical jaw pose.
                    # Scale the *authored* offsets, rather than pulling
                    # arbitrary nearby vertices into a cardboard flap.
                    intensity=.46 if name=="MouthOpen" else 1.0
                    accumulated[dst]=accumulated.get(dst,Vector((0,0,0)))+vec*scale*intensity
            for i,base in enumerate(baseline):
                v=base.copy()
                if i in accumulated:
                    v+=accumulated[i]
                    if accumulated[i].length>1e-6: moved+=1
                key.data[i].co=v
        else:
            for i,base in enumerate(baseline):
                v=base.copy()
                front=frontal_weight(v)
                if name=="JawWidth":
                    w=(1.-smoothstep(-.155,.015,v.z))
                    v.x+=math.copysign(.014*w,v.x)
                elif name=="CheekWidth":
                    w=bell(abs(v.x),.095,.065)*bell(v.z,-.014,.055)
                    v.x+=math.copysign(.014*w,v.x)
                elif name=="NoseWidth":
                    w=bell(v.x,0,.045)*bell(v.z,-.017,.08)*front
                    v.x*=1.+.26*w
                elif name=="LipVolume":
                    w=bell(v.x,0,.052)*bell(v.z,-.137,.028)*front
                    v.y-=.012*w
                    v.z+=(.008 if v.z>-.137 else -.007)*w
                if (v-base).length>1e-6: moved+=1
                key.data[i].co=v
        if moved<25:
            raise RuntimeError(f"{name} barely deforms the anatomy: {moved}")
        # ShapeKey is not an IDProperty owner in Blender 5.
        print("ORIN_CC0_SHAPE",name,"authored facial vertices",moved)
        key.value=0.
        key.slider_min=0.
        key.slider_max=1.
    head["expression_source"]="MakeHuman CC0 authored expression units (pinned)"
    head["source_original_vertex_indices"]=True


def sculpt_curly_crop(head, hair_mat):
    # Grow the hair from the *existing cranial surface* so it follows
    # the forehead and crown. This has full 3-D silhouette, not cards.
    # Isolated cloth/hair geometry can be replaced by authored grooms
    # without touching the facial topology or animation.
    src = head.data
    scalp = bpy.data.meshes.new("Orin_RootedCurls")
    index_map, pts, faces = {}, [], []
    def above_hairline(point):
        # The former fixed Z>.092 crop excluded most of the back
        # and temples: it looked like a rigid front-half bowl cut.
        # Follow the forehead up and the rear occiput down.
        rearward = smoothstep(-.12, .09, point.y)
        threshold = .104 - .083*rearward
        threshold += .014*smoothstep(.105,.17,abs(point.x))
        return point.z > threshold

    for poly in src.polygons:
        inds = list(poly.vertices)
        if not all(above_hairline(src.vertices[j].co) for j in inds):
            continue
        for j in inds:
            if j not in index_map:
                index_map[j] = len(pts)
                pts.append(src.vertices[j].co.copy())
        faces.append(tuple(index_map[j] for j in inds))
    if len(faces) < 180:
        raise RuntimeError("No meaningful cranial surface for rooted hair")

    # Sculpt a mass of overlapping, low-poly CURL TUFTS directly into
    # this same authored hair mesh. The lobes penetrate the rooted
    # scalp: they do not float as rigid ribbons or card-shaped clumps.
    # Use deterministic spacing for stable renders and saved assets.
    base_roots = list(pts)
    lobes = 0
    for i, root in enumerate(base_roots):
        # Cover enough of the curved scalp for a genuinely textured,
        # tight crop; the sparse modulo-five layout yielded fewer than
        # fifty nodules and left a smooth bald-cap silhouette.
        if i%2 != 0 or root.z < .033:
            continue
        if len(base_roots) > 0 and lobes >= 180:
            break
        normal = root.normalized()
        phase = i * 2.399963229728653
        radius = .0085 + .002*math.sin(phase*1.8)**2
        center = root + normal*(.009+.001*math.sin(phase))
        # Round faceted tufts, not dozens of little pyramidal spikes.
        tip = normal*(radius*.37)
        first = len(pts)
        # Two poles and a hexagonal faceted ring; closed 12-triangle
        # nodules with a readable dark curly silhouette.
        tangent = normal.cross(Vector((0,0,1)))
        if tangent.length < .1:
            tangent = normal.cross(Vector((0,1,0)))
        tangent.normalize()
        bitangent = normal.cross(tangent).normalized()
        pts.extend([center+tip, center-tip])
        for j in range(6):
            angle = (j/6.0)*math.tau+phase
            pts.append(center+(tangent*math.cos(angle)
                +bitangent*math.sin(angle))*radius)
        for j in range(6):
            n=(j+1)%6
            faces.append((first,first+2+j,first+2+n))
            faces.append((first+1,first+2+n,first+2+j))
        lobes += 1
    if lobes < 50:
        raise RuntimeError("Curl crop lost its rooted faceted tufts")
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
    hair["rooted_curl_tuft_count"] = lobes
    return hair


def sculpt_mouth_interior():
    """A separately modeled anatomical oral lining, with its OWN morph.

    The CC0 lip target opens the face, but the trimmed MakeHuman base
    lacks a colored mouth interior. A visible skin-color oval is not a
    plausible oral cavity. The neutral oral lining has near-zero area;
    its MouthOpen shape unfurls *behind the lip contour* as the jaw opens.
    """
    vertices=[(0,-.177,-.147)]
    count=24
    for i in range(count):
        theta=math.tau*i/count
        vertices.append((.0003*math.cos(theta),-.177,
                         -.147+.0002*math.sin(theta)))
    faces=[(0,i+1,(i+1)%count+1) for i in range(count)]
    mesh=bpy.data.meshes.new("Orin_OralLining")
    mesh.from_pydata(vertices,[],faces)
    mesh.update()
    cavity=bpy.data.objects.new("Orin_MouthInterior",mesh)
    bpy.context.collection.objects.link(cavity)
    dark=make_material("Orin_InteriorDeepUmber",(.045,.012,.012))
    mesh.materials.append(dark)
    cavity.shape_key_add(name="Basis",from_mix=False)
    opened=cavity.shape_key_add(name="MouthOpen",from_mix=False)
    opened.data[0].co=(0,-.186,-.148)
    for i in range(count):
        theta=math.tau*i/count
        opened.data[i+1].co=(.040*math.cos(theta),-.186,
                            -.148+.014*math.sin(theta))
    opened.value=0.
    opened.slider_min=0.
    opened.slider_max=1.
    cavity["real_animated_oral_lining"]=True
    return cavity


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
    # The first Blender previews were nearly solid white because
    # 330/180/250W area lights overexposed a half-metre-wide head.
    light("Key_PaleWarm", (-.62,-.68,.76), 38, 1.3)
    light("Fill_WideCool", (.68,-.34,.28), 18, 1.5)
    light("Rim_Dim", (.24,.55,.6), 24, 1.0)
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


def render_studio(head, mouth_cavity, cam, folder):
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
        mouth_cavity.data.shape_keys.key_blocks["MouthOpen"].value = (
            shape_values.get("MouthOpen",0.))
        look(cam, camera)
        bpy.context.scene.render.filepath = str(folder / (name+".png"))
        bpy.ops.render.render(write_still=True)
    for key in head.data.shape_keys.key_blocks:
        if key.name != "Basis":
            key.value = 0.
    mouth_cavity.data.shape_keys.key_blocks["MouthOpen"].value=0.


def main():
    args = arg_parser()
    out = args.out.resolve()
    out.mkdir(parents=True, exist_ok=True)
    clear_scene()
    base = ensure_base(args.base_obj)
    source_digest = hashlib.sha256(base.read_bytes()).hexdigest()
    head, source_vertices, source_faces = read_human_base(base)
    dimensions, eyes = crop_and_normalize(head)
    skin = make_material("Orin_WarmUmberSkin", (.34,.185,.125))
    hair_mat = make_material("Orin_DarkCurls", (.026,.022,.019))
    head.data.materials.append(skin)
    ivory = make_material("Orin_ScleraSoftIvory",(.58,.54,.47))
    iris = make_material("Orin_IrisUmber",(.115,.082,.056))
    pupil = make_material("Orin_Pupil",(.012,.011,.012))
    for eye in eyes:
        eye.data.materials.append(ivory)
        pts=[v.co for v in eye.data.vertices]
        cx=sum(p.x for p in pts)/len(pts)
        cz=sum(p.z for p in pts)/len(pts)
        front=min(p.y for p in pts)
        # The CC0 globe is physically seated in its facial socket.
        # Iris/pupil are the only intentionally separate eye structures.
        for suffix, mat, size, advance in [
            ("Iris",iris,(.013,.0026,.013),.002),
            ("Pupil",pupil,(.006,.0017,.007),.005)]:
            bpy.ops.mesh.primitive_uv_sphere_add(segments=20,ring_count=12,
                location=(cx,front-advance,cz))
            disc=bpy.context.object
            disc.name=eye.name+"_"+suffix
            disc.scale=size
            disc.data.materials.append(mat)
    # Make the original topology's INTERNAL mouth wall dark.
    # Without this, the open-mouth target displays a fleshy disk
    # across the whole cavity instead of a readable opening.
    inner_mouth = make_material("Orin_OralCavity",(.070,.026,.021))
    head.data.materials.append(inner_mouth)
    oral_faces = 0
    for f in head.data.polygons:
        f.material_index = 0
        f.use_smooth = True
        middle = sum((head.data.vertices[j].co for j in f.vertices),
                     Vector((0,0,0))) / len(f.vertices)
        # In Blender -Y faces forward. Behind the external lip plane,
        # only central mouth topology should receive cavity pigment.
        if (abs(middle.x)<.058 and -.171<middle.z<-.106
                and -.144<middle.y<-.027):
            f.material_index = 1
            oral_faces += 1
    if oral_faces < 20 or oral_faces > 1200:
        raise RuntimeError("Oral cavity material mask missed inner topology: "
                           + str(oral_faces))
    print("ORIN_ORAL_CAVITY_FACES",oral_faces)
    facial_shapes(head)
    hair = sculpt_curly_crop(head, hair_mat)
    mouth_cavity = sculpt_mouth_interior()
    cam = light_and_camera()
    render_studio(head, mouth_cavity, cam, out)
    bpy.ops.wm.save_as_mainfile(filepath=str(out / "orin_head_editable.blend"))
    bpy.ops.object.select_all(action="DESELECT")
    for o in [head,hair,mouth_cavity]+eyes+[
            ob for ob in bpy.context.scene.objects if (
                ob.type=="MESH" and ("_Iris" in ob.name or "_Pupil" in ob.name))]:
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
