#!/usr/bin/env python3
"""Rebuildable VERBA Blender Asset Foundry: sculpted hermit's cottage hero mesh.

Run: blender -b -t 2 --python tools/art_foundry/forge_cottage.py -- --output DIR
Outputs: editable .blend, packed .glb, four material-lit PNGs, provenance JSON.
Only authored geometry and CC0 textures already committed to the game.
No downloads, cloud-model inference, proprietary 3D models or API keys.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import math
import os
import random
import sys
from pathlib import Path

import bpy
import numpy as np
from mathutils import Vector, Matrix

ROOT = Path(__file__).resolve().parents[2]
TEX = ROOT / "assets" / "textures" / "real"
RNG = random.Random(614206)
BLENDER_VERSION = bpy.app.version_string

def material(name, texture, tint, roughness=.94):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    m.diffuse_color = (*tint, 1.0)
    m.use_backface_culling = False
    bsdf = m.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (*tint, 1.0)
    bsdf.inputs["Roughness"].default_value = roughness
    source = TEX / texture
    if not source.is_file():
        raise FileNotFoundError(f"Missing committed CC0 material: {source}")
    # Pack a separately graded copy. A texture wired directly into Base
    # Color OVERRIDES Blender's material color, which made the first cottage
    # brilliant white and detached from VERBA's old timber/moss palette.
    # Pack these pixels as images so both Blender and Godot show the SAME art.
    source_image = bpy.data.images.load(str(source), check_existing=True)
    arr = np.empty(len(source_image.pixels), dtype=np.float32)
    source_image.pixels.foreach_get(arr)
    arr = arr.reshape((-1,4))
    pigment = np.array(tint, dtype=np.float32)
    arr[:,:3] *= pigment
    graded = bpy.data.images.new(name + " graded albedo",
        width=source_image.size[0], height=source_image.size[1], alpha=True)
    graded.pixels.foreach_set(arr.reshape(-1))
    # Blender 5.x removed the as_png argument from Image.pack(). Save a
    # real PNG to the runner's temp folder first, then pack that exact
    # authored albedo into both the .blend source and glTF model.
    tint_dir=Path(os.environ.get("RUNNER_TEMP", "/tmp"))/"verba_graded_materials"
    tint_dir.mkdir(parents=True,exist_ok=True)
    graded.filepath_raw=str(tint_dir/(name.replace(" ","_")+".png"))
    graded.file_format="PNG"
    graded.save()
    graded.pack()
    node = m.node_tree.nodes.new("ShaderNodeTexImage")
    node.label = "graded CC0: " + source.name
    node.image = graded
    m.node_tree.links.new(node.outputs["Color"], bsdf.inputs["Base Color"])
    return m

class Geometry:
    """One mesh per source material, UVed triangles with genuine apertures."""
    def __init__(self, name, material):
        self.name = name
        self.material = material
        self.verts = []
        self.faces = []
        self.uv = []
    def polygon(self, corners, uv=None):
        if uv is None:
            uv = [(0,0),(1,0),(1,1),(0,1)]
        start = len(self.verts)
        self.verts.extend(tuple(p) for p in corners)
        for ids in [(0,1,2),(0,2,3)] if len(corners)==4 else [(0,1,2)]:
            self.faces.append(tuple(start+i for i in ids))
            self.uv.append([uv[i] for i in ids])
    def box(self, center, dimensions, uv_scale=1.0):
        x,y,z = center
        sx,sy,sz = (n*.5 for n in dimensions)
        c = [(x-sx,y-sy,z-sz),(x+sx,y-sy,z-sz),
             (x+sx,y+sy,z-sz),(x-sx,y+sy,z-sz),
             (x-sx,y-sy,z+sz),(x+sx,y-sy,z+sz),
             (x+sx,y+sy,z+sz),(x-sx,y+sy,z+sz)]
        for side in [(0,1,2,3),(5,4,7,6),(4,0,3,7),
                     (1,5,6,2),(3,2,6,7),(4,5,1,0)]:
            self.polygon([c[i] for i in side],
              [(0,0),(uv_scale,0),(uv_scale,uv_scale),(0,uv_scale)])
    def beam(self, a, b, width, depth=None):
        a,b = Vector(a),Vector(b)
        length = (b-a).length
        if length < .001:
            return
        depth = width if depth is None else depth
        basis = (b-a).to_track_quat("Z","Y").to_matrix().to_4x4()
        origin = Matrix.Translation((a+b)*.5)
        local = [(-width*.5,-depth*.5,-length*.5),
                 ( width*.5,-depth*.5,-length*.5),
                 ( width*.5, depth*.5,-length*.5),
                 (-width*.5, depth*.5,-length*.5),
                 (-width*.5,-depth*.5, length*.5),
                 ( width*.5,-depth*.5, length*.5),
                 ( width*.5, depth*.5, length*.5),
                 (-width*.5, depth*.5, length*.5)]
        transform = origin @ basis
        c = [tuple(transform @ Vector(v)) for v in local]
        for ids in [(0,1,2,3),(5,4,7,6),(4,0,3,7),
                    (1,5,6,2),(3,2,6,7),(4,5,1,0)]:
            self.polygon([c[i] for i in ids],
                [(0,0),(1,0),(1,length*.4),(0,length*.4)])
    def stone(self, center, size, seed=0):
        x,y,z = center
        sx,sy,sz = (v*.5 for v in size)
        wobble = .06*(1+(seed%5)*.12)
        a = [(-sx,-sy,-sz),(sx,-sy,-sz),(sx,sy,-sz),(-sx,sy,-sz),
             (-sx,-sy,sz),(sx,-sy,sz),(sx,sy,sz),(-sx,sy,sz)]
        pts = [(x+v[0]+RNG.uniform(-wobble,wobble),
                y+v[1]+RNG.uniform(-wobble*.35,wobble*.35),
                z+v[2]+RNG.uniform(-wobble,wobble)) for v in a]
        for face in [(0,1,2,3),(5,4,7,6),(4,0,3,7),
                     (1,5,6,2),(3,2,6,7),(4,5,1,0)]:
            self.polygon([pts[i] for i in face])
    def emit(self, root):
        if not self.faces:
            return None
        mesh=bpy.data.meshes.new(self.name+"Mesh")
        # Godot's Y-up world authoring coordinates differ from Blender Z-up.
        # Blender glTF exporter maps (x, by, bz) -> (x, bz, -by).
        # Author in world XYZ with Y-up, then convert BEFORE mesh export.
        # This also makes the source .blend stand upright in Blender.
        blender_verts=[(x,-z,y) for x,y,z in self.verts]
        mesh.from_pydata(blender_verts,[],self.faces)
        mesh.update()
        uv_layer=mesh.uv_layers.new(name="UVMap")
        for poly,texcoords in zip(mesh.polygons,self.uv):
            for corner,coord in zip(poly.loop_indices,texcoords):
                uv_layer.data[corner].uv=coord
        mesh.materials.append(self.material)
        obj=bpy.data.objects.new(self.name,mesh)
        root.objects.link(obj)
        return obj

def build_cottage():
    mats = {
      "lime":material("01 dirty lime plaster","cottage_plaster_diffuse.jpg",
                      (.76,.69,.59)),
      "oak":material("02 smoked timber","cottage_wood_diffuse.jpg",
                     (.52,.42,.32)),
      "charred":material("03 blackened oak","cottage_wood_diffuse.jpg",
                         (.28,.26,.24)),
      "slate":material("04 moss slate roof","cottage_roof_diffuse.jpg",
                      (.54,.59,.54)),
      "slate_dry":material("05 weathered grey slate","cottage_roof_diffuse.jpg",
                          (.65,.63,.56)),
      "foundation":material("06 wet fieldstone","stone_diffuse.jpg",
                             (.56,.55,.49)),
      "lichen":material("07 mossy fieldstone","moss_diffuse.jpg",
                        (.54,.60,.48)),
      "earth":material("08 soil and planters","earth_path_diffuse.jpg",
                       (.44,.39,.32)),
    }
    root=bpy.data.collections.new("EXPORT__HermitCottage")
    bpy.context.scene.collection.children.link(root)
    geo={k:Geometry(k,m) for k,m in mats.items()}
    p,o,d,s,f,lichen,soil=(geo[n] for n in
                      ["lime","oak","charred","slate","foundation","lichen","earth"])
    dry=geo["slate_dry"]

    # Walls use four real mesh openings in the front facade: the door and
    # the main glazing are NOT photographed onto a square box.
    # The physical canonical gameplay doorway is centered x=-.69 at z=2.55.
    for x1,x2 in [(-2.84,-1.28),(-.1,2.84)]:
        p.box(((x1+x2)*.5,1.62,2.55),(x2-x1,2.96,.20))
    p.box((-.69,2.93,2.55),(1.18,.32,.20))
    # Behind windows, leave dark stone cavity rather than bright false glass.
    for z in [-2.57]:
        p.box((0,1.69,z),(5.68,3.03,.23))
    for x in [-2.86,2.86]:
        for z1,z2 in [(-2.55,-1.28),(.06,2.55)]:
            p.box((x,1.70,(z1+z2)*.5),(.19,3.0,z2-z1))
        p.box((x,.66,-.61),(.19,.85,1.34))
        p.box((x,2.71,-.61),(.19,.92,1.34))
    # True plaster gables, with the crooked roof crest offset from center.
    for z in [-2.61,2.61]:
        p.polygon([(-2.73,3.16,z),(2.73,3.16,z),
                   (-.20,5.66,z)],[(0,0),(1,0),(.47,1)])

    # Fieldstone foundations with nonidentical silhouettes and small mortar
    # losses. Multiple courses, NOT a perfect row of uniform cubic blocks.
    for side in [-1,1]:
        for j in range(11):
            x=-2.69+j*.54
            for course in range(2):
                g=f if (j+course)%4 else lichen
                g.stone((x+RNG.uniform(-.04,.04),.18+course*.23,side*2.62),
                        (.57,.22,.34),j+course)
        for j in range(10):
            z=-2.41+j*.51
            f.stone((side*2.91,.14,z),(.31,.24,.53),j)
    # Fitted timber frame connects where real walls and gables meet.
    for side in [-1,1]:
        for z in [-2.57,2.61]:
            o.beam((side*2.71,.17,z),(side*2.67,3.11,z),.19,.17)
            o.beam((side*2.65,.42,z),(side*1.63,2.83,z),.115,.10)
        o.beam((side*2.68,3.08,-2.65),(side*2.68,3.08,2.70),.15,.13)
        o.beam((side*2.72,.45,-2.56),(side*2.72,.45,2.56),.14,.11)
        for z in [-2.59,2.63]:
            o.beam((side*2.64,3.13,z),(-.20,5.68,z),.14,.11)
    for z in [-2.64,2.65]:
        o.beam((-2.72,3.07,z),(2.72,3.07,z),.16,.14)
    d.beam((-.20,5.75,-3.13),(-.20,5.76,3.17),.16,.14)

    # 480 hand-laid slates: staggered overlapping profile and irregular
    # edges. Generated into two GLB mesh batches, not 480 draw calls.
    n_across,n_along=13,19
    def roof_position(side,u,z,jitter=0):
        x=-.20+side*3.22*u
        y=5.82-2.84*u**.91
        return (x,y+.025+jitter,z)
    for side in [-1,1]:
        for i in range(n_across):
            for j in range(n_along):
                u0=i/n_across
                u1=(i+1)/n_across+.015
                z0=-3.02+j*6.07/n_along
                z1=-3.02+(j+1.07)*6.07/n_along
                wave=.012*math.sin(i*1.8+j*.51)
                ripple=RNG.uniform(-.018,.018)
                tile=(dry if (i*3+j)%11 in [0,5] else s)
                tile.polygon([roof_position(side,u0,z0,wave),
                              roof_position(side,u1,z0,wave+ripple),
                              roof_position(side,u1,z1,wave+ripple-.01),
                              roof_position(side,u0,z1,wave)],
                             [(0,0),(1,0),(1,1),(0,1)])
                if (i*13+j*3+int(side))%43==0:
                    # Moss and chipped slate are concentrated, not everywhere.
                    lichen.stone(roof_position(side,(u0+u1)*.5,
                         (z0+z1)*.5,.06),(.23,.036,.15),i+j)
    # A chunky roof trim follows the pitch, so the tiled skin cannot read
    # as two disconnected floating planes.
    for side in [-1,1]:
        for z in [-3.04,3.10]:
            o.beam(roof_position(side,0,z),roof_position(side,1,z),.10,.10)

    # Door alignment follows original collision, so the exported mesh can
    # eventually replace facade ART without breaking save files.
    for x in [-1.21,-.18]:
        d.beam((x,.18,2.77),(x,2.49,2.77),.095,.10)
    for y in [.19,2.52]:
        d.beam((-1.24,y,2.77),(-.16,y,2.77),.105,.11)
    for i in range(5):
        x=-1.11+i*.214
        o.box((x,1.28,2.62),(.186,2.34,.095),.42)
        if i%2==0:
            d.beam((x-.07,.26,2.70),(x+.07,2.33,2.70),.025,.03)
    # Hinge straps, rectangular latch and real window recess.
    d.box((-.26,1.42,2.76),(.125,.08,.065))
    for y in [.47,2.10]:
        d.box((-1.07,y,2.72),(.39,.09,.045))
    # Front window: aged horizontal casement; dark cavity is geometry.
    d.box((1.61,1.77,2.685),(1.24,1.23,.06))
    for x in [.95,2.27]:
        o.beam((x,1.11,2.82),(x,2.47,2.82),.13,.13)
    for y in [1.12,2.48]:
        o.beam((.86,y,2.82),(2.35,y,2.82),.13,.13)
    o.beam((1.61,1.14,2.83),(1.61,2.47,2.83),.07,.07)
    o.beam((.88,1.79,2.83),(2.32,1.79,2.83),.07,.07)
    # Three supporting side windows, all framed and recessed.
    for side in [-1,1]:
        x=side*2.94
        for z in [-1.32,.61]:
            for yy in [1.3,2.23]:
                o.beam((x,yy,z-.47),(x,yy,z+.47),.09,.10)
            for zz in [z-.47,z+.47]:
                o.beam((x,1.30,zz),(x,2.23,zz),.10,.09)
            d.beam((x,1.76,z-.40),(x,1.76,z+.4),.055,.075)

    # Chimney is intentionally offset so the house is recognizable from
    # a far first-person hillside camera, with real soot/damaged cap stones.
    for i in range(6):
        x=-1.97
        y=3.74+i*.39
        f.stone((x+RNG.uniform(-.04,.04),y,-1.53),
                (.78,.42,.75),i)
    d.box((-1.97,6.13,-1.53),(.73,.20,.72))
    for k in range(4):
        x=-2.28+(k%2)*.60
        z=-1.84+(k//2)*.60
        d.stone((x,6.23,z),(.16,.08,.19),k)

    # A true secondary turret makes the art replace the fantasy silhouette
    # rather than flattening it into a suburban house. Stone courses join
    # the main wall without obstructing the existing first-floor door.
    tower_x,tower_z = 3.49,-.58
    tower_radius = .96
    sections = 12
    for j in range(sections):
        a = math.tau*j/sections
        b = math.tau*(j+1)/sections
        bottom_a = (tower_x+math.cos(a)*tower_radius,
                    .20,tower_z+math.sin(a)*tower_radius)
        bottom_b = (tower_x+math.cos(b)*tower_radius,
                    .20,tower_z+math.sin(b)*tower_radius)
        top_a = (bottom_a[0]*1.0,4.64,bottom_a[2])
        top_b = (bottom_b[0]*1.0,4.64,bottom_b[2])
        f.polygon([bottom_a,bottom_b,top_b,top_a],
                  [(j*.4,0),(j*.4+.4,0),
                   (j*.4+.4,2.7),(j*.4,2.7)])
        for course in range(9):
            y = .32+course*.44
            if (j*5+course)%7 in [0,2]:
                lichen.stone((tower_x+math.cos(a+.24)*.99,
                              y,tower_z+math.sin(a+.24)*.99),
                             (.23,.12,.14),j+course)
        dry.polygon([ (tower_x+math.cos(a)*1.31,4.65,
                        tower_z+math.sin(a)*1.31),
                      (tower_x+math.cos(b)*1.31,4.65,
                        tower_z+math.sin(b)*1.31),
                      (tower_x-.11,6.72,tower_z+.06)],
                    [(0,0),(1,0),(.49,1)])
        o.beam((tower_x+math.cos(a)*1.31,4.65,
                tower_z+math.sin(a)*1.31),
               (tower_x+math.cos(b)*1.31,4.65,
                tower_z+math.sin(b)*1.31),.10,.095)
    # Turret windows have actual timber surrounds and dark recesses.
    d.box((tower_x,2.67,tower_z+1.00),(.40,.61,.045))
    for x in [tower_x-.25,tower_x+.25]:
        o.beam((x,2.26,tower_z+1.075),
               (x,3.06,tower_z+1.075),.105,.08)
    for y in [2.28,3.06]:
        o.beam((tower_x-.31,y,tower_z+1.075),
               (tower_x+.31,y,tower_z+1.075),.105,.08)
    o.beam((tower_x,2.35,tower_z+1.105),
           (tower_x,3.01,tower_z+1.105),.045,.045)

    # Workshop trade goods and planter ledge reinforce readable scale.
    o.box((1.62,.98,2.99),(1.20,.23,.36))
    soil.box((1.62,1.12,2.99),(1.06,.11,.28))
    for i in range(23):
        x=1.14+(i%8)*.133
        z=2.98+(i//8)*.09-.11
        d.beam((x,1.17,z),
            (x+RNG.uniform(-.12,.12),1.36+RNG.random()*.30,z+.09),
            .011,.009)

    created=[group.emit(root) for group in geo.values()]
    created=[obj for obj in created if obj]
    if len(created)!=len(mats):
        raise RuntimeError("Lost a material or accidentally emitted zero geometry")
    return created

def setup_camera(scene,camera,eye,look_at):
    # All four cameras are specified in the same Y-up coordinates as Godot.
    def to_blender(p): return Vector((p[0],-p[2],p[1]))
    camera.location=to_blender(eye)
    direction=to_blender(look_at)-camera.location
    camera.rotation_euler=direction.to_track_quat("-Z","Y").to_euler()
    scene.camera=camera

def stage_and_render(out,assets):
    scene=bpy.context.scene
    stage=bpy.data.collections.new("STUDIO_REVIEW_ONLY")
    scene.collection.children.link(stage)
    ground=bpy.data.meshes.new("matteGroundMesh")
    ground.from_pydata([(-12,-12,-.075),(12,-12,-.075),
                       (12,12,-.075),(-12,12,-.075)],[],
                      [(0,1,2),(0,2,3)])
    floor=bpy.data.objects.new("ReviewGroundNotInGLB",ground)
    stage.objects.link(floor)
    fm=bpy.data.materials.new("NeutralReviewMatte")
    fm.diffuse_color=(.19,.22,.20,1)
    fm.use_nodes=True
    fm.node_tree.nodes.get("Principled BSDF").inputs["Base Color"].default_value=(.19,.22,.20,1)
    floor.data.materials.append(fm)
    world=bpy.data.worlds.new("Slate Ambient Sky")
    world.use_nodes=True
    world.node_tree.nodes["Background"].inputs["Color"].default_value=(.45,.50,.51,1)
    world.node_tree.nodes["Background"].inputs["Strength"].default_value=.55
    scene.world=world
    def area(name,position,energy,size,color):
        datablock=bpy.data.lights.new(name,"AREA")
        datablock.energy=energy
        datablock.shape="DISK"
        datablock.size=size
        datablock.color=color
        lamp=bpy.data.objects.new(name,datablock)
        stage.objects.link(lamp)
        lamp.location=position
        lamp.rotation_euler=(Vector((0,0,2.5))-lamp.location).to_track_quat("-Z","Y").to_euler()
    area("Soft Overcast Key",(1,-5,11),1400,9,(.90,.94,1.0))
    area("Late Day Warm Fill",(-7,4,7),800,8,(1.0,.84,.64))
    cam_data=bpy.data.cameras.new("Asset Quad Review Lens")
    cam=bpy.data.objects.new("Asset Quad Review Lens",cam_data)
    stage.objects.link(cam)
    cam_data.type="ORTHO"
    cam_data.ortho_scale=12.5
    cam_data.lens=40
    try:
        scene.render.engine="CYCLES"
        scene.cycles.samples=20
        scene.cycles.use_denoising=True
    except AttributeError:
        scene.render.engine="BLENDER_EEVEE"
    scene.render.resolution_x=760
    scene.render.resolution_y=570
    scene.render.resolution_percentage=100
    scene.render.image_settings.file_format="PNG"
    scene.render.film_transparent=False
    scene.render.engine="CYCLES"
    views = [
        ("01_front_entry",(10.2,7.6,13.2),(-.25,2.7,0)),
        ("02_riverside_side",(-11.8,8.9,6.1),(0,2.7,0)),
        ("03_moss_slate_roof",(7.8,12.6,-8.2),(0,3.2,0)),
        ("04_back_and_chimney",(-7.7,8.6,-12.5),(0,2.9,0)),
    ]
    for name, eye, target in views:
        setup_camera(scene,cam,eye,target)
        scene.render.filepath=str(out / (name+".png"))
        bpy.ops.render.render(write_still=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(out/"hermit_cottage_v2.blend"))
    return views

def main():
    parser=argparse.ArgumentParser()
    parser.add_argument("--output",required=True)
    args=parser.parse_args(sys.argv[sys.argv.index("--")+1:] if "--" in sys.argv else [])
    out=Path(args.output).resolve()
    out.mkdir(parents=True,exist_ok=True)
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for old in list(bpy.data.collections):
        if old.name=="Collection":
            continue
    assets=build_cottage()
    # Export SELECTED asset geometry only, never studio lights/plinth/cameras.
    for obj in bpy.context.selected_objects:
        obj.select_set(False)
    for obj in assets:
        obj.select_set(True)
    bpy.context.view_layer.objects.active=assets[0]
    glb=out/"hermit_cottage_v2.glb"
    bpy.ops.export_scene.gltf(filepath=str(glb),export_format="GLB",
                              use_selection=True,export_yup=True)
    for obj in assets:
        obj.select_set(False)
    views=stage_and_render(out,assets)
    provenance = {
        "asset_id":"hermit_cottage_v2",
        "model":"assets/models/foundry/hermit_cottage_v2.glb",
        "authoring_file":"hermit_cottage_v2.blend",
        "source_script":"tools/art_foundry/forge_cottage.py",
        "blender":BLENDER_VERSION,
        "units":"meters",
        "scale":"one Blender meter = one Godot meter",
        "door_local":{"x":-.69,"z":2.55},
        "mesh_count":len(assets),
        "faces":sum(len(o.data.polygons) for o in assets),
        "textures":{p.name:hashlib.sha256(p.read_bytes()).hexdigest()
            for p in sorted(TEX.glob("*_diffuse.jpg"))
            if p.name.startswith(("cottage_","stone_","moss_","earth_"))},
        "license":"Original scripted geometry; bundled Poly Haven CC0 images",
        "camera_views":[n for n,_,_ in views],
        "glb_sha256":hashlib.sha256(glb.read_bytes()).hexdigest()
    }
    (out/"provenance.json").write_text(json.dumps(provenance,indent=2)+"\n")
    print("FOUNDRY PASS",json.dumps({k:provenance[k] for k in
          ["asset_id","blender","mesh_count","faces","glb_sha256"]}))
if __name__=="__main__":
    main()
