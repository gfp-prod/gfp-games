#!/usr/bin/env python3
"""VERBA regional asset foundry. Blender-only, deterministic, CC0-image-based.
Run: blender -b -t 2 --python tools/art_foundry/forge_regions.py -- --output ../regional_build
All exported meshes use meter coordinates and authored per-face UVs.
"""
from __future__ import annotations
import argparse, hashlib, json, math, random, sys
from pathlib import Path
import bpy
import numpy as np
from mathutils import Vector, Matrix

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "assets" / "textures" / "real"
R = random.Random(100937)
MATERIALS = {}

def mat(name, jpg, rgb, rough=0.91):
    if name in MATERIALS: return MATERIALS[name]
    p = SOURCE / jpg
    if not p.exists(): raise FileNotFoundError(p)
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    bsdf = m.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Roughness"].default_value = rough
    source = bpy.data.images.load(str(p), check_existing=True)
    pixels = np.empty(len(source.pixels), dtype=np.float32)
    source.pixels.foreach_get(pixels)
    pixels = pixels.reshape((-1,4))
    pixels[:,:3] *= np.array(rgb, dtype=np.float32)
    graded = bpy.data.images.new(name+"_pigment", width=source.size[0], height=source.size[1], alpha=True)
    graded.pixels.foreach_set(np.clip(pixels,0,1).reshape(-1))
    # Packing a PNG, not a floating-point generated bitmap, preserves color in Godot.
    cache=Path("/tmp/verba_regional_grades");cache.mkdir(parents=True,exist_ok=True)
    graded.filepath_raw=str(cache/(name+".png"))
    graded.file_format="PNG"
    graded.save()
    graded.pack()
    node=m.node_tree.nodes.new("ShaderNodeTexImage")
    node.image=graded
    node.label="CC0 source: "+jpg
    m.node_tree.links.new(node.outputs["Color"],bsdf.inputs["Base Color"])
    MATERIALS[name]=m
    return m

class Geometry:
    def __init__(self, name, material):
        self.name, self.material = name, material
        self.v, self.f, self.uv = [], [], []
    def face(self, corners, texture_repeat=1.0):
        s=len(self.v); self.v.extend(tuple(c) for c in corners)
        uvs=[(0,0),(texture_repeat,0),(texture_repeat,texture_repeat),(0,texture_repeat)]
        for inds in ([(0,1,2),(0,2,3)] if len(corners)==4 else [(0,1,2)]):
            self.f.append(tuple(s+i for i in inds))
            self.uv.append([uvs[i] for i in inds])
    def box(self, center, dimensions, repeat=1.0):
        x,y,z=center; a,b,c=[s*.5 for s in dimensions]
        points=[(x-a,y-b,z-c),(x+a,y-b,z-c),(x+a,y+b,z-c),(x-a,y+b,z-c),
                (x-a,y-b,z+c),(x+a,y-b,z+c),(x+a,y+b,z+c),(x-a,y+b,z+c)]
        for face in [(3,2,1,0),(4,5,6,7),(0,4,7,3),(5,1,2,6),(7,6,2,3),(0,1,5,4)]:
            self.face([points[i] for i in face],repeat)
    def beam(self,a,b,width,depth=None):
        a,b=Vector(a),Vector(b);d=b-a
        if d.length < .001:return
        depth=width if depth is None else depth
        t=Matrix.Translation((a+b)*.5) @ d.to_track_quat("Z","Y").to_matrix().to_4x4()
        x,y,z=width*.5,depth*.5,d.length*.5
        p=[tuple(t @ Vector(v)) for v in [(-x,-y,-z),(x,-y,-z),(x,y,-z),(-x,y,-z),
                                         (-x,-y,z),(x,-y,z),(x,y,z),(-x,y,z)]]
        for ids in [(3,2,1,0),(4,5,6,7),(0,4,7,3),(5,1,2,6),(7,6,2,3),(0,1,5,4)]:
            self.face([p[i] for i in ids],max(1.0,d.length*.34))
    def rock(self,xyz,scale,seed=1):
        # Asymmetric tapered 10-sided cut rock, faceted rather than sphere-based.
        rng=random.Random(seed); x,y,z=xyz; sx,sy,sz=scale; n=10
        lower=[]; mid=[]; upper=[]
        for i in range(n):
            a=2*math.pi*i/n
            r=rng.uniform(.79,1.11)
            lower.append((x+math.cos(a)*sx*r*.56,y-sy*.43,z+math.sin(a)*sz*r*.54))
            mid.append((x+math.cos(a)*sx*r*.62,y+sy*.03+rng.uniform(-.08,.08),z+math.sin(a)*sz*r*.58))
            upper.append((x+math.cos(a)*sx*r*.35,y+sy*.44+rng.uniform(-.11,.08),z+math.sin(a)*sz*r*.34))
        for i in range(n):
            j=(i+1)%n
            self.face([lower[i],lower[j],mid[j]])
            self.face([lower[i],mid[j],mid[i]])
            self.face([mid[i],mid[j],upper[j]])
            self.face([mid[i],upper[j],upper[i]])
            self.face([upper[i],upper[j],(x,y+sy*.52,z)])
    def finish(self):
        if not self.f:return None
        mesh=bpy.data.meshes.new(self.name)
        mesh.from_pydata(self.v,[],self.f);mesh.update()
        uv=mesh.uv_layers.new(name="Authored UV")
        for i,poly in enumerate(mesh.polygons):
            for j,loop_id in enumerate(poly.loop_indices):
                uv.data[loop_id].uv=self.uv[i][j]
            poly.use_smooth=False
        obj=bpy.data.objects.new(self.name,mesh)
        bpy.context.collection.objects.link(obj)
        mesh.materials.append(self.material)
        return obj

def authors():
    return dict(
        oak=Geometry("oak_planks_and_supports",mat("smoked_oak","cottage_wood_diffuse.jpg",(.61,.54,.43))),
        timber=Geometry("dark_timber_and_frame",mat("dark_timber","cottage_wood_diffuse.jpg",(.39,.35,.31))),
        stone=Geometry("broken_fieldstone",mat("wet_fieldstone","stone_diffuse.jpg",(.60,.62,.60))),
        lichen=Geometry("lichened_edges",mat("lichen_stone","moss_diffuse.jpg",(.53,.60,.49))),
        rust=Geometry("oxide_sheet_metal",mat("rusted_panels","cottage_roof_diffuse.jpg",(.47,.31,.25))),
        steel=Geometry("cold_galvanized_metal",mat("oxidized_steel","cottage_roof_diffuse.jpg",(.45,.49,.48))),
        dark=Geometry("char_and_rubber",mat("rubber_char","woodland_ground_diffuse.jpg",(.22,.24,.23))),
        rope=Geometry("weathered_rope",mat("hemp","earth_path_diffuse.jpg",(.70,.61,.43)))
    )

def bridge(g):
    # Existing collision deck: x -6.4..+6.4, y -.29..+.03, z +/-1.1.
    oak,timber,stone,rope=g["oak"],g["timber"],g["stone"],g["rope"]
    for i in range(19):
        x=(i-9)*.68
        zoffset=R.uniform(-.03,.03)
        oak.box((x,R.uniform(-.045,.026),zoffset),(.65,.13,2.09+R.uniform(-.09,.06)),1.2)
        if i%5==0:
            for sign in [-1,1]:
                timber.beam((x,-.15,sign*1.10),(x+R.uniform(-.07,.07),.97,sign*1.10),.13)
                stone.rock((x,-.19,sign*1.12),(.35,.34,.43),i*3+sign)
    for sign in [-1,1]:
        timber.beam((-6.45,-.24,sign*.92),(6.45,-.24,sign*.92),.26,.17)
        for k in range(4):
            a=-6.12+3.06*k;b=a+3.06
            for seg in range(9):
                t=seg/9;t2=(seg+1)/9
                def p(u):return (a+(b-a)*u,.79-.16*math.sin(u*math.pi),sign*1.12)
                rope.beam(p(t),p(t2),.043,.04)
        for xx in [-5.95,5.95]:
            timber.beam((xx,-.15,sign*1.14),(xx+.12,.94,sign*1.14),.18)
    # Cross-braces visibly explain load-bearing structure.
    for xx in [-5.5,-1.5,2.5,5.5]:
        timber.beam((xx,-.35,-1.10),(xx+1.2,-.35,1.10),.10)
    for x in [-6.30,6.30]:
        for z in [-1.10,1.10]:
            stone.rock((x,-.38,z),(.79,.47,.60),int((x+7)*100+(z+2)*19))

def jetty(g):
    oak,timber,stone,rope=g["oak"],g["timber"],g["stone"],g["rope"]
    # Existing collision planks x 0..8.4, y -.17..+.01.
    for i in range(13):
        x=i*.70
        oak.box((x,R.uniform(-.11,-.065),R.uniform(-.02,.02)),(.64,.16,2.28+R.uniform(-.07,.04)),1.3)
    for side in [-1,1]:
        for i in [0,3,6,9,12]:
            x=i*.70
            timber.beam((x,-1.78,side*1.07),(x+R.uniform(-.05,.04),.55,side*1.06),.19)
            stone.rock((x,-1.51,side*1.07),(.48,.34,.48),i*41+side)
        timber.beam((0,-.32,side*.90),(8.42,-.32,side*.90),.22)
    # Deliberately asymmetrical mooring cleats and old rope.
    for x in [1.40,7.55]:
        timber.beam((x,.02,-.89),(x,.28,-.89),.10)
        timber.beam((x-.18,.25,-.89),(x+.18,.25,-.89),.07)
    for i in range(11):
        t=i/10; a=2*math.pi*t
        rope.beam((7.6+.16*math.cos(a),.01,1.02+.16*math.sin(a)),
                  (7.6+.16*math.cos(a+.55),.01,1.02+.16*math.sin(a+.55)),.03)

def standing_stones(g):
    stone,lichen=g["stone"],g["lichen"]
    for i in range(7):
        a=2*math.pi*i/7
        x=math.cos(a)*4.8;z=math.sin(a)*4.8
        h=1.6+(i%3)*.34
        # Existing stone body centered at h*.46. Place new silhouette same scale.
        stone.rock((x,h*.47,z),(.86,h,.71),i*71+5)
        lichen.rock((x-.09,h*.57,z+.06),(.62,h*.36,.53),i*91+7)
        for j in range(3):
            dx=R.uniform(-.8,.8);dz=R.uniform(-.8,.8)
            stone.rock((x+dx,.06,z+dz),(.28,.18,.35),i*50+j)
    stone.rock((0,.23,0),(2.25,.49,1.78),40)
    lichen.rock((.09,.42,-.09),(1.02,.22,.82),41)

def wreck(g):
    rust,steel,dark,stone=g["rust"],g["steel"],g["dark"],g["stone"]
    # x -1.5..+1.5 z +/-0.74; preserve old collision volume and wheelbase.
    steel.box((.52,.77,0),(1.70,.92,1.47))
    rust.box((.52,1.29,0),(1.65,.13,1.48))
    rust.box((-.95,.85,0),(1.03,.55,1.35))
    steel.box((-1.04,1.20,0),(.90,.13,1.36))
    dark.box((-1.19,1.10,0),(.08,.27,1.05))
    steel.box((-1.50,.73,0),(.09,.32,1.28))
    for z in [-.77,.77]:
        for x in [-.97,.98]:
            # 12-sided horizontal tire made from short faceted rim sections.
            for i in range(12):
                a=2*math.pi*i/12; b=2*math.pi*(i+1)/12
                p=(x+.38*math.cos(a),.37+.38*math.sin(a),z)
                q=(x+.38*math.cos(b),.37+.38*math.sin(b),z)
                dark.beam(p,q,.18,.21)
            steel.rock((x,.37,z+(.027 if z>0 else -.027)),(.30,.27,.15),int(x*700+z*1000))
    # Broken side window, uneven bonnet and workshop dents.
    dark.box((-.57,1.06,-.694),(.48,.29,.025))
    dark.box((-.57,1.06,.694),(.48,.29,.025))
    rust.beam((-.43,1.25,-.71),(-.65,1.52,-.71),.05)
    rust.beam((-.65,1.52,-.71),(-1.06,1.32,-.71),.05)
    rust.box((.12,.88,-.752),(.41,.20,.027))
    dark.box((1.41,.73,0),(.035,.16,1.19))
    for z in [-.48,.48]:
        stone.box((-1.53,.70,z),(.028,.12,.17))

def dead_tree(g):
    timber,dark,lichen=g["timber"],g["dark"],g["lichen"]
    trunk=[(0,0,0),(.12,1.1,.05),(-.13,2.35,0),(.20,3.65,.14),(-.29,5.15,.19),(-.21,6.75,.25)]
    thickness=[.92,.76,.60,.43,.29,.12]
    for i in range(len(trunk)-1):
        timber.beam(trunk[i],trunk[i+1],thickness[i])
    for i in range(8):
        a=2*math.pi*i/8
        dark.beam((.02,.51,0),(math.cos(a)*1.04,.10,math.sin(a)*1.02),.22,.14)
    for i in range(12):
        a=2*math.pi*i/12
        h=3.1+(i%5)*.56; radius=1.9+(i%4)*.35
        start=(.09,h,.10)
        mid=(math.cos(a)*radius*.56,h+.66,math.sin(a)*radius*.56)
        end=(math.cos(a)*radius,h+.2-(i%3)*.28,math.sin(a)*radius)
        timber.beam(start,mid,.23-(i%4)*.016)
        dark.beam(mid,end,.12)
        if i%3==0:
            dark.beam(end,(end[0]+math.cos(a)*.46,end[1]+.55,end[2]+math.sin(a)*.43),.06)
    for i in range(8):
        a=2*math.pi*i/8
        lichen.rock((math.cos(a)*.35,1.2+i*.43,math.sin(a)*.32),(.24,.30,.23),190+i)

BUILDERS={
    "old_creek_footbridge":bridge,
    "old_fishing_jetty":jetty,
    "witness_stone_circle":standing_stones,
    "rusting_delivery_wreck":wreck,
    "dead_ash_tree":dead_tree
}

def export_asset(out,name,builder):
    bpy.ops.object.select_all(action="SELECT");bpy.ops.object.delete(use_global=False)
    r=random.Random(17)
    # Stable per-asset seed means each asset can be rebuilt independently.
    global R; R=random.Random(71022+list(BUILDERS).index(name)*101)
    geom=authors();builder(geom)
    objects=[o for o in (g.finish() for g in geom.values()) if o is not None]
    if not objects:raise RuntimeError("Asset has no geometry: "+name)
    bpy.ops.object.select_all(action="DESELECT")
    for obj in objects:obj.select_set(True)
    bpy.context.view_layer.objects.active=objects[0]
    glb=out/(name+".glb")
    bpy.ops.export_scene.gltf(filepath=str(glb),export_format="GLB",
                              use_selection=True,export_yup=True)
    mesh_faces=sum(len(x.data.polygons) for x in objects)
    payload={"name":name,"source":"Original authored geometry; photographic CC0 textures already bundled",
             "license":"Original VERBA geometry and bundled CC0 photographs",
             "meters":True,"mesh_count":len(objects),"faces":mesh_faces,
             "sha256":hashlib.sha256(glb.read_bytes()).hexdigest(),
             "size_bytes":glb.stat().st_size}
    # The .blend sources remain editable without any special add-on.
    bpy.ops.wm.save_as_mainfile(filepath=str(out/(name+".blend")))
    return payload

def main():
    parser=argparse.ArgumentParser();parser.add_argument("--output",required=True)
    args=parser.parse_args(sys.argv[sys.argv.index("--")+1:] if "--" in sys.argv else [])
    out=Path(args.output).resolve();out.mkdir(parents=True,exist_ok=True)
    records=[export_asset(out,name,builder) for name,builder in BUILDERS.items()]
    (out/"regional_provenance.json").write_text(json.dumps({"assets":records},indent=2)+"\n")
    print("REGIONAL FOUNDRY PASS",json.dumps({r["name"]:r["faces"] for r in records}))
if __name__=="__main__":
    main()
