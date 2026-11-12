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
        # We design these landmarks in Godot's Y-up coordinates.
        # Blender is Z-up and its glTF exporter rotates into Y-up.
        # Convert first so the finished GLBs and editable .blends stand upright.
        # Without this, the water bridge, trees, and standing stones lie sideways.
        blender_vertices=[(x,-z,y) for x,y,z in self.v]
        mesh.from_pydata(blender_vertices,[],self.f);mesh.update()
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
        rope=Geometry("weathered_rope",mat("hemp","earth_path_diffuse.jpg",(.70,.61,.43))),
        plaster=Geometry("faded_facade",mat("pitted_concrete","cottage_plaster_diffuse.jpg",(.67,.66,.57))),
        glass=Geometry("smoky_window_glass",mat("smoked_window","cottage_roof_diffuse.jpg",(.22,.27,.27),.28)),
        sign=Geometry("old_green_enamel",mat("faded_enamel","cottage_roof_diffuse.jpg",(.37,.45,.38),.68)),
        canvas=Geometry("natural_dyed_canvas",mat("stained_canvas","cottage_plaster_diffuse.jpg",(.72,.68,.56),.99)),
        brick=Geometry("firebrick_and_clay",mat("burnt_firebrick","stone_diffuse.jpg",(.65,.44,.33),.96)),
        soot=Geometry("kiln_soot_and_embers",mat("kiln_soot","woodland_ground_diffuse.jpg",(.18,.20,.17),.99))
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

def ridge_arch(g):
    stone,lichen=g["stone"],g["lichen"]
    # Walkthrough gap from x -0.85 to +0.85 and original pillars +/-1.2.
    for side in [-1,1]:
        x=side*1.22
        for course in range(6):
            h=.24+course*.45
            stone.rock((x+R.uniform(-.05,.05),h,R.uniform(-.07,.07)),
                       (.83,.47,.90),1000+course*11+(side+1))
        stone.rock((x,2.66,0),(.97,.47,.98),1005+side)
        # Crumbling springer arches, intentionally missing a few units.
    for i in range(11):
        t=math.pi*float(i)/10.0
        if i in [1,8]: continue
        x=math.cos(t)*1.23
        y=2.82+math.sin(t)*1.29
        stone.rock((x,y,.02),(.53,.54,.86),1100+i)
        if i%3==0:
            lichen.rock((x+.05,y+.22,.02),(.33,.18,.52),1300+i)
    for i in range(11):
        x=R.uniform(-2.55,2.55); z=R.choice([-1,1])*R.uniform(.65,2.10)
        stone.rock((x,.12,z),(R.uniform(.25,.72),.22,R.uniform(.25,.52)),1400+i)

def prayer_shrine(g):
    stone,lichen,timber=g["stone"],g["lichen"],g["timber"]
    # Base shares original 1.8m altar collision; keep its exposed top reachable.
    for x in [-.53,0,.53]:
        for z in [-.4,.37]:
            stone.rock((x,.28,z),(.68,.59,.69),1500+int((x+2)*100+(z+2)*80))
    stone.box((0,.72,0),(1.75,.26,1.37))
    # Split low standing tablet above the altar; deliberately not generic cross.
    stone.rock((0,1.56,-.31),(1.20,1.58,.50),1559)
    lichen.rock((.35,1.76,-.34),(.29,.52,.22),1560)
    for side in [-1,1]:
        timber.beam((side*.38,.90,.30),(side*.38,1.20,.30),.06)
    # A scattering of old offerings at ground level.
    for i in range(8):
        a=2*math.pi*i/8
        stone.rock((math.cos(a)*1.3,.12,math.sin(a)*1.09),
                   (.27,.18,.25),1570+i)

def charcoal_kiln(g):
    stone,lichen,dark=g["stone"],g["lichen"],g["dark"]
    # Original cold kiln footprint is 2.1m square. Cracked concentric masonry
    # with an open dark firemouth instead of an intact toy pyramid.
    for course in range(6):
        y=.20+course*.37
        radius=1.55-.16*course
        for i in range(13):
            if course<4 and i in [0,1,12]:continue
            if course==5 and i in [5,6,7]:continue
            a=2*math.pi*i/13+course*.08
            b=2*math.pi*(i+.83)/13+course*.08
            p=(math.cos(a)*radius,y,math.sin(a)*radius)
            q=(math.cos(b)*radius,y,math.sin(b)*radius)
            stone.beam(p,q,.40,.38)
            if course>2 and i%4==0:
                lichen.rock((math.cos(a)*radius,y+.18,math.sin(a)*radius),
                            (.28,.18,.28),2000+course*19+i)
    dark.box((1.23,.36,0),(.15,.54,.85))
    for i in range(14):
        a=2*math.pi*i/14
        stone.rock((math.cos(a)*1.86,.09,math.sin(a)*1.80),
                   (.45,.18,.47),2400+i)



def roadside_station(g):
    """Lived-in, 1960s rural roadside station that is visually incompatible
    with the medieval keep but physically plausible at first-person distance.
    Dimensions and doors match scripts/strange_road.gd exactly.
    Existing Godot solids, signs, lights and quest markers are preserved.
    """
    limestone=g["plaster"]; concrete=g["stone"]; oak=g["oak"]
    steel=g["steel"]; rust=g["rust"]; dark=g["dark"]
    frame=g["timber"]; pane=g["glass"]; faded=g["sign"]
    # Worn apron and wooden interior: preserve original collision elevations.
    concrete.box((2,-.015,0),(14.9,.19,9.64),4)
    oak.box((-2.15,.182,0),(7.08,.19,6.97),2)
    # Genuine open-sided east entrance, not a textured door.
    limestone.box((-5.70,1.82,0),(.36,3.42,7.20),2)
    for sign in [-1,1]:
        limestone.box((-2.10,1.82,sign*3.48),(7.5,3.42,.38),2)
        limestone.box((1.45,1.82,sign*2.35),(.38,3.42,2.30),2)
    limestone.box((1.45,3.08,0),(.38,.88,2.40),1)
    # Vertical clapboard strips with half the boards missing and discoloration.
    for z in [-3.68,3.68]:
        for i in range(14):
            x=-5.42+i*.48
            if i in [2,9,12]:continue
            frame.box((x,2.66,z),(.055,.15,.052))
    for x in [-5.89,1.67]:
        for z in [-3.17,3.17]:
            frame.beam((x,.29,z),(x,3.34,z),.12,.12)
    # The flat roof is layered with a stepped corroded cornice, not a cube.
    dark.box((-2.15,3.72,0),(7.91,.16,7.70),2)
    steel.box((-2.15,3.91,0),(8.26,.11,7.99),2)
    rust.box((-2.15,4.00,0),(8.43,.04,8.07),3)
    for z in [-3.75,3.75]:
        rust.box((-2.15,3.75,z),(8.0,.22,.09),2)
    for x in [-5.99,1.67]:
        rust.box((x,3.75,0),(.095,.22,7.66),2)
    # Shop-front windows, dark real-looking glass, muntins and corroded sills.
    for z in [-2.25,2.25]:
        pane.box((1.672,2.02,z),(.048,1.16,.98),1)
        frame.box((1.719,1.39,z),(.11,.13,1.16))
        frame.box((1.719,2.66,z),(.11,.13,1.16))
        for zz in [z-.54,z+.54]:
            frame.beam((1.72,1.40,zz),(1.72,2.63,zz),.068)
        frame.beam((1.725,2.025,z-.55),(1.725,2.025,z+.55),.057)
        for y in [1.52,2.59]:
            rust.box((1.733,y,z),(.017,.052,.81),1)
    # Shop interior: real shelved objects visible through opening.
    for z in [-2.57,2.57]:
        frame.box((-3.78,.77,z),(2.46,1.1,.60),2)
        for y in [.44,1.09,1.54]:
            oak.box((-3.76,y,z),(2.52,.095,.66),2)
            for i in range(5):
                if R.random()<.28:continue
                x=-4.75+i*.46
                faded.box((x,y+.16,z),(.23,.30,.21))
    oak.box((-.70,.71,1.66),(.69,1.18,2.58),2)
    dark.box((-.70,1.32,1.66),(.79,.10,2.67),2)
    steel.box((-.66,1.42,1.9),(.18,.14,.25))
    # Frayed awning, low canopy and head-bracing visibly carry the roof load.
    dark.box((5,4.09,0),(6.65,.30,8.60),3)
    faded.box((5.00,3.87,0),(6.61,.22,8.65),3)
    rust.box((5.00,4.29,0),(6.82,.10,8.75),2)
    for x in [1.66,8.33]:
        rust.box((x,4.11,0),(.14,.19,8.68),2)
    for z in [-3.52,3.52]:
        steel.beam((6.68,.14,z),(6.68,4.02,z),.26,.26)
        for zz in [z-.27,z+.27]:
            rust.beam((6.61,.10,zz),(6.61,3.83,zz),.04)
        frame.beam((6.70,3.02,z),(5.46,3.87,z),.16)
        frame.beam((6.70,3.02,z),(7.79,3.88,z),.16)
    # Two tactile, mechanically legible petrol pumps in their original spots.
    for z in [-2.27,2.27]:
        dark.box((4.61,.075,z),(1.01,.15,.93))
        faded.box((4.60,.77,z),(.80,1.39,.78),1)
        steel.box((4.60,1.52,z),(.92,.12,.96))
        rust.box((4.60,.82,z+.40),(.70,1.00,.055))
        pane.box((5.03,1.11,z),(.045,.48,.49))
        dark.box((5.065,1.20,z),(.052,.24,.31))
        for side in [-1,1]:
            steel.beam((4.72,1.12,z+side*.41),
                       (4.88,.82,z+side*.62),.055)
            dark.beam((4.88,.82,z+side*.62),
                      (4.99,.53,z+side*.60),.055)
        steel.box((4.58,.45,z),(.31,.10,.88))
        rust.box((4.60,.58,z-.43),(.48,.035,.05))
    # Distinctive roadside pole sign; actual Label3D remains owned by Godot.
    steel.beam((9.12,0,-2.68),(9.12,6.98,-2.68),.20)
    faded.box((9.12,6.22,-2.68),(.31,1.52,3.56),2)
    for z in [-4.43,-.93]:
        rust.beam((9.30,5.51,z),(9.30,6.97,z),.08)
    for y in [5.49,6.98]:
        rust.beam((9.30,y,-4.43),(9.30,y,-.93),.08)
    # Ragged foundation stones and local stains, not scattered object spam.
    for i in range(45):
        x=R.uniform(-5.55,8.15);z=R.choice([-1,1])*R.uniform(3.72,4.68)
        concrete.rock((x,.09,z),
                      (R.uniform(.18,.48),R.uniform(.10,.21),R.uniform(.18,.43)),9000+i)
    for i in range(17):
        x=R.uniform(1.86,8.12);z=R.uniform(-4.52,4.46)
        if 3.4<x<5.4 and abs(z)<3.0:continue
        dark.box((x,.10,z),(R.uniform(.12,.64),.007,R.uniform(.08,.48)))


def castle_gatehouse(g):
    """Stone-led architecture, not scaled cylinders and wall slabs.
    Matches the existing enterable castle and archive collision hulls.
    Keeps a >4.0m physical eastern gate and a real archive door.
    """
    stone,lichen,oak=g["stone"],g["lichen"],g["oak"]
    dark,metal,plaster,roof=g["dark"],g["steel"],g["plaster"],g["rust"]
    # Scored, chipped curtain-wall courses around the actual walkable court.
    # Each wall uses a recessed stone core and irregular facing courses,
    # so stone texture and mortar joints have real depth.
    for wall in [
        # Horizontal curtains, the opening on the eastern side stays real.
        {"axis":"z","at":-7.45,"start":-7.8,"stop":7.8},
        {"axis":"z","at":7.45,"start":-7.8,"stop":7.8},
        {"axis":"x","at":-7.45,"start":-7.72,"stop":7.72},
        {"axis":"x","at":7.45,"start":-7.72,"stop":-2.52},
        {"axis":"x","at":7.45,"start":2.52,"stop":7.72},
    ]:
        along=wall["stop"]-wall["start"]
        if wall["axis"]=="x":
            stone.box((wall["at"],2.15,(wall["start"]+wall["stop"])*.5),
                      (.57,4.25,along),3)
        else:
            stone.box(((wall["start"]+wall["stop"])*.5,2.15,wall["at"]),
                      (along,4.25,.57),3)
        # Staggered hewn blocks instead of polygonal boulders pasted to a
        # perfectly flat wall. Shadowed 0.05m mortar joints and slight
        # projecting stones give genuine coursed-masonry construction.
        for course in range(8):
            y=.32+course*.515
            step=1.07
            start_offset=.48 if course%2 else 0.0
            segments=int(math.ceil(along/step))+1
            for i in range(segments):
                center=wall["start"]+i*step+step*.5+start_offset
                if center<wall["start"]+.25 or center>wall["stop"]-.25:
                    continue
                length=min(step*R.uniform(.89,.96),
                           2.0*(center-wall["start"]-.05),
                           2.0*(wall["stop"]-.05-center))
                if length<.27:continue
                protrusion=R.uniform(.012,.055)
                height=R.uniform(.455,.487)
                for face_sign in [-1,1]:
                    pigment=lichen if course in [0,1] and i%8==3 else stone
                    offset=face_sign*(.345+protrusion*.4)
                    if wall["axis"]=="x":
                        pigment.box((wall["at"]+offset,y,center),
                                   (.095+protrusion,height,length),1.4)
                    else:
                        pigment.box((center,y,wall["at"]+offset),
                                   (length,height,.095+protrusion),1.4)
        # Subtly irregular corner quoins hold the bonded walls together.
        for end in [wall["start"]+.32,wall["stop"]-.32]:
            for course in range(5):
                y=.34+course*.78
                if wall["axis"]=="x":
                    stone.box((wall["at"],y,end),(.83,.72,.68),2)
                else:
                    stone.box((end,y,wall["at"]),(.68,.72,.83),2)
        # Continuous weathered crest/coping and occasional displaced blocks.
        if wall["axis"]=="x":
            stone.box((wall["at"],4.33,(wall["start"]+wall["stop"])*.5),
                      (.81,.16,along),2)
        else:
            stone.box(((wall["start"]+wall["stop"])*.5,4.33,wall["at"]),
                      (along,.16,.81),2)
    # Recessed arched gate header: masonry keystone and an unmistakably open
    # passage; no visible mesh seals the collision opening.
    stone.box((7.45,4.47,0),(.73,.73,5.12),3)
    for side in [-1,1]:
        for i in range(5):
            z=side*2.75
            y=.40+i*.79
            stone.box((7.45,y,z),(.79,.69,.48),2)
    for i in range(12):
        z=-2.38+(i+.5)*.405
        stone.box((7.45,4.47,z),(.81,.64,.368),1.5)
    # Carved keystone framing the lintel, with the entire gate below open.
    stone.box((7.45,4.64,0),(.89,.70,.46),2)
    # Four tapered actual stone towers, broken ring parapets and dark slits.
    for tx in [-7.25,7.25]:
        for tz in [-7.25,7.25]:
            height=6.35 if tx<0 else 5.75
            segments=16
            tiers=18
            for tier in range(tiers):
                y0=.04+tier*(height/tiers)
                y1=.04+(tier+1)*(height/tiers)
                r0=1.80-.15*tier/tiers
                r1=1.80-.15*(tier+1)/tiers
                for a in range(segments):
                    theta=2*math.pi*a/segments
                    theta_next=2*math.pi*(a+1)/segments
                    def p(angle,r,y):
                        return (tx+math.cos(angle)*r,y,tz+math.sin(angle)*r)
                    stone.face([
                        p(theta,r0,y0),
                        p(theta_next,r0,y0),
                        p(theta_next,r1,y1),
                        p(theta,r1,y1)
                    ],1.0)
                    if tier in [2,8,14] and a%4==1:
                        lichen.rock((tx+math.cos(theta)*1.83,y1-.09,
                                     tz+math.sin(theta)*1.83),
                                    (.28,.17,.26),4100+tier*30+a)
            # Black narrow arrowslits inset in existing tower geometry.
            for y in [2.0,3.55]:
                dark.box((tx,y,tz+1.783),(.12,.56,.035))
                stone.box((tx,y+.31,tz+1.821),(.27,.063,.068))
                stone.box((tx,y-.31,tz+1.821),(.27,.063,.068))
            # Low mortar-backed coping with genuine merlons and narrow
            # crenels. Earlier rock spheres looked like floating rubble.
            for a in range(16):
                theta=2*math.pi*a/16
                x=tx+math.cos(theta)*1.77
                z=tz+math.sin(theta)*1.77
                stone.box((x,height+.08,z),(.55,.24,.55),1.2)
                if a%3!=1:
                    stone.box((x,height+.46,z),(.49,.56,.50),1.3)
            # A worn, central walking cap supports the parapet. No bright
            # slate roof dish floating between towers.
            stone.box((tx,height-.09,tz),(2.82,.12,2.82),2)
            for i in range(4):
                t=(i-1.5)*.35
                lichen.rock((tx+t,height+.08,tz+1.58),(.24,.10,.19),4700+i)
    # Real archive remains enterable and properly roofed.
    # Relative archive center (-2.5,.13,0), using the original coordinates.
    ax=-2.5
    stone.box((ax,.21,0),(5.45,.17,5.7),2)
    plaster.box((ax-2.65,1.98,0),(.43,3.42,5.48),2)
    for side in [-1,1]:
        plaster.box((ax,1.98,side*2.74),(5.50,3.42,.42),2)
        plaster.box((ax+2.65,1.98,side*2.0),(.41,3.42,1.58),2)
    plaster.box((ax+2.65,3.25,0),(.43,.74,2.88),2)
    # Dark moss slate eaves, cap stones and exposed structural rafters.
    roof.box((ax,3.90,0),(6.1,.33,6.45),3)
    dark.box((ax,4.085,0),(6.25,.055,6.56),3)
    for z in [-2.83,2.83]:
        oak.beam((ax-2.95,3.52,z),(ax+2.98,3.52,z),.20,.18)
    for x in [ax-2.1,ax-.5,ax+1.3]:
        for z in [-2.2,2.2]:
            oak.beam((x,3.59,z),(x,3.95,z),.17,.15)
    # Functional scribe's racks: reserve original table/collision positions.
    for z in [-1.78,1.78]:
        for y in [.83,1.62,2.35]:
            oak.box((ax-1.72,y,z),(.98,.13,.51),2)
    # Low repair scar at gate threshold, not another arbitrary glowing prop.
    for i in range(32):
        x=R.uniform(5.7,9.0)
        z=R.uniform(-4.0,4.0)
        if abs(z)<2.20 and x>7.0: continue
        stone.rock((x,.10,z),
                   (R.uniform(.17,.48),R.uniform(.09,.22),R.uniform(.20,.50)),5100+i)


def village_bakery(g):
    """An open-front, physically credible stone oven with an old bread peel rack.
    Replaces bakery visuals, not PhysicalBakeOven, coal glow or village inventory.
    The active oven bounds in village_workplaces.gd remain authoritative.
    """
    stone,brick,lichen,oak=g["stone"],g["brick"],g["lichen"],g["oak"]
    frame,soot,steel,rope=g["timber"],g["soot"],g["steel"],g["rope"]
    # Raised fieldstone hearth, staggered brick and a proper dressed foundation.
    stone.box((.04,.27,.29),(2.49,.54,2.24),1.7)
    for course in range(3):
        y=.095+course*.175
        for face_z in [-.875,1.46]:
            for index in range(5):
                x=-1.02+index*.51+(course%2)*.13
                if x>1.12:continue
                brick.box((x,y,face_z),(.44,.154,.065),1.0)
        for face_x in [-1.21,1.29]:
            for index in range(4):
                z=-.60+index*.55+(course%2)*.17
                if z>1.23: continue
                stone.box((face_x,y,z),(.065,.16,.47),1.1)
    # Low domed kiln: 12 tiers and 24 segments. Actual shaped vaulted
    # masonry rather than a giant grey sphere or geometric cone.
    n=24
    levels=12
    for ring in range(levels):
        t0=ring/levels*math.pi*.5
        t1=(ring+1)/levels*math.pi*.5
        r0=1.15*math.cos(t0)
        r1=1.15*math.cos(t1)
        y0=.57+1.47*math.sin(t0)
        y1=.57+1.47*math.sin(t1)
        for i in range(n):
            a=i*2*math.pi/n
            b=(i+1)*2*math.pi/n
            def pt(angle,r,y):
                return (.04+math.cos(angle)*r,y,.32+math.sin(angle)*r)
            (lichen if ring in [0,1] and i%17==1 else stone).face(
                [pt(a,r0,y0),pt(b,r0,y0),pt(b,r1,y1),pt(a,r1,y1)],1.3)
            # Deep, incomplete brick bands create plausible repairs around
            # the weather-exposed lower dome instead of pasted on boulders.
            if ring in [1,4] and i%4!=0:
                a_mid=(a+b)*.5
                radius=1.15*math.cos(t0)+.023
                x=.04+math.cos(a_mid)*radius
                z=.32+math.sin(a_mid)*radius
                if z>- .62:
                    continue # keep firebox aperture readable
                brick.beam(pt(a,r0+.031,y0),pt(b,r0+.031,y0),.045,.055)
    # Proper front arch; soot sits behind retained real working embers.
    soot.box((0,1.00,-.876),(.90,.64,.055),1.0)
    for i in range(13):
        angle0=i*math.pi/13
        angle1=(i+1)*math.pi/13
        p0=(math.cos(angle0)*.59,.96+math.sin(angle0)*.45,-.991)
        p1=(math.cos(angle1)*.59,.96+math.sin(angle1)*.45,-.991)
        brick.beam(p0,p1,.113,.105)
    for sign in [-1,1]:
        stone.box((sign*.635,.89,-.982),(.18,.42,.20),1.0)
    # Purpose-built chimney, bonded to rear, held by iron collars.
    frame.beam((.64,1.53,.92),(.69,3.04,.94),.27,.22)
    for y in [2.35,2.81]:
        steel.box((.68,y,.94),(.40,.07,.37),1.2)
    soot.box((.69,3.03,.94),(.25,.06,.19))
    # Two hand-worn kitchen tools and stacked repair blocks.
    for dy in [.28,.90]:
        oak.beam((-1.60,dy,-.35),(-2.03,dy,-.35),.049,.041)
    oak.beam((-1.60,.08,-.26),(-1.60,1.70,-.26),.067)
    oak.beam((-2.02,1.12,-.34),(-1.61,1.40,-.34),.032)
    for i in range(6):
        x=.84+.12*(i%2)
        z=1.55+.27*(i//2)
        brick.box((x,.12,z),(.27,.18,.24),1.0)
    # A stonework ash shelf with realistic iron binding, away from the
    # preserved finite working ember visual.
    steel.box((0,.55,-1.02),(.90,.045,.17))
    for sign in [-1,1]:
        steel.beam((sign*.43,.51,-1.04),(sign*.43,.72,-1.04),.032)


def village_forge(g):
    """Forge furnace with metal hood, laid refractory stone and riveted flue.
    The glowing coal stock, functional light and collision stay in Godot.
    """
    stone,brick,lichen=g["stone"],g["brick"],g["lichen"]
    steel,rust,oak,soot=g["steel"],g["rust"],g["oak"],g["soot"]
    # Hearth fits PhysicalCoalForge 2.19x1.75x1.25: no visual physics inflation.
    stone.box((0,.44,.47),(2.26,.84,1.33),1.8)
    for y in [.24,.61,.91]:
        for i in range(5):
            x=-.93+i*.48+(0.16 if y==.61 else 0)
            if x>1.0:continue
            brick.box((x,y,-.224),(.41,.25,.08),1.5)
    for x in [-1.12,1.12]:
        for z in [-.05,.47,.99]:
            stone.box((x,.60,z),(.11,.44,.46),1.3)
    # Arch opening recessed *behind* the original animated, finite coal.
    soot.box((0,.87,-.216),(1.18,.55,.042))
    for i in range(11):
        a=i*math.pi/11; b=(i+1)*math.pi/11
        p=(math.cos(a)*.69,.85+math.sin(a)*.37,-.275)
        q=(math.cos(b)*.69,.85+math.sin(b)*.37,-.275)
        brick.beam(p,q,.106,.098)
    for sign in [-1,1]:
        steel.box((sign*.70,.67,-.29),(.095,.49,.08))
        steel.box((sign*.72,1.04,.11),(.046,.09,.73),1.1)
    # Faceted raised forge throat and mechanically anchored hood.
    steel.box((0,1.35,.54),(2.05,.13,1.36),2)
    for i in range(14):
        a=math.pi*2*i/14
        b=math.pi*2*(i+1)/14
        def p(theta,r,y):
            return (math.cos(theta)*r,y,.51+math.sin(theta)*r*.65)
        rust.face([p(a,1.06,1.41),p(b,1.06,1.41),
                   p(b,.38,2.29),p(a,.38,2.29)],2)
    # A proper flue and rivet lines, not a free-floating chimney.
    steel.box((.17,2.63,.64),(.64,.91,.60),2)
    soot.box((.17,3.11,.64),(.47,.065,.43),1)
    rust.box((.17,3.17,.64),(.78,.12,.76),2)
    for y in [2.36,2.76]:
        rust.box((.17,y,.34),(.65,.085,.035))
    for x in [-.12,.42]:
        for y in [2.36,2.77]:
            steel.box((x,y,.313),(.038,.044,.022))
    for z in [.17,.83]:
        oak.beam((-1.22,.16,z),(-1.22,1.78,z),.115,.10)
        oak.beam((1.22,.16,z),(1.22,1.78,z),.115,.10)
    for y in [1.58,1.90]:
        rust.box((0,y,1.16),(2.55,.075,.11),1.4)
    # The human-maintained footprint has the soot and repair scars implied
    # by welding and working steel, but isn't cluttered with fake loot.
    for i in range(13):
        x=R.uniform(-1.0,1.0)
        z=R.uniform(.74,1.16)
        if i%4==0:
            lichen.rock((x,.12,z),(.15,.12,.18),7100+i)


def village_market_stall(g):
    """Worn pitched cloth canopy, braced framing, legible walk-through stall.
    This overlays only visual geometry; citizens still reach the market.
    """
    oak,frame,cloth,rope=g["oak"],g["timber"],g["canvas"],g["rope"]
    stone,rust=g["stone"],g["rust"]
    # Irregular handmade ground frame of four real posts and supports.
    for x in [-1.14,1.14]:
        for z in [-.73,.73]:
            stone.box((x,.08,z),(.29,.16,.29),1.1)
            frame.beam((x,.13,z),(x+(.025 if z<0 else -.025),2.56,z),.105,.094)
            for sign in [-1,1]:
                if sign*x>0:
                    frame.beam((x,2.09,z),(x-sign*.42,2.47,z),.063)
    # Two thick sill beams and braced carpentry support the overhead cloth.
    for z in [-.82,.82]:
        oak.beam((-1.22,2.55,z),(1.22,2.55,z),.12,.095)
    for x in [-1.16,1.16]:
        oak.beam((x,2.55,-.87),(x,2.55,.87),.108,.09)
    frame.beam((0,3.05,-1.01),(0,3.05,1.01),.08,.07)
    # Cloth is a pitched ridge with layered panels and slightly ragged
    # seams. Real fabric texture from CC0 plaster photo pigment.
    for side in [-1,1]:
        for i in range(6):
            z0=-1.02+i*.34
            z1=z0+.34
            outside=side*1.38
            sag=.045+R.uniform(-.023,.028)
            h0=3.07-abs(side)*.06
            cloth.face([(0,h0,z0),(outside,2.52-sag,z0),
                        (outside,2.52-sag,z1),(0,h0,z1)],1.25)
            # Stitched hems make a readable edge instead of a bald triangle.
            rope.beam((outside,2.53-sag,z0),(outside,2.53-sag,z1),.030)
            if i in [1,4]:
                patch_side=side*(.61+.09*i)
                rust.box((patch_side,2.78-.045*i,z0+.17),
                         (.18,.018,.29),1.2)
        # Ragged valance sways visually but no physics or animated rig added.
        for i in range(8):
            z=-1.0+i*.29
            edge=side*1.38
            w=.24
            cloth.face([(edge,2.53,z),(edge,2.34+R.uniform(-.04,.06),z+.035),
                        (edge,2.39+R.uniform(-.03,.05),z+w),
                        (edge,2.53,z+w)],.8)
    # Worktop is not a cube. Individual short weathered boards and legs.
    for i in range(8):
        z=-.56+i*.155
        oak.box((0,.99,z),(2.53,.09,.15),1.4)
    for x in [-1.0,1.0]:
        for z in [-.45,.45]:
            frame.beam((x,.13,z),(x,.94,z),.10)
        frame.beam((x,.48,-.49),(x,.48,.49),.055)
    # Existing MERCATUS Label3D is kept; a believable wooden fascia now
    # actually carries it at the original position (z=-.96).
    frame.box((0,2.13,-.85),(2.16,.46,.11),1.8)
    for x in [-1.13,1.13]:
        rust.box((x,2.13,-1.0),(.045,.40,.025))
    # Worn split shelf, few repeated basket frames. Do not mint stock items.
    for x in [-.84,.84]:
        oak.box((x,.57,.47),(.63,.07,.39),1.2)
        rope.beam((x-.27,.52,.64),(x+.27,.52,.64),.029)

BUILDERS={
    "old_creek_footbridge":bridge,
    "old_fishing_jetty":jetty,
    "witness_stone_circle":standing_stones,
    "rusting_delivery_wreck":wreck,
    "dead_ash_tree":dead_tree,
    "ridge_arch":ridge_arch,
    "stone_prayer_shrine":prayer_shrine,
    "cold_charcoal_kiln":charcoal_kiln,
    "roadside_station":roadside_station,
    "castle_gatehouse":castle_gatehouse,
    "village_bakery":village_bakery,
    "village_forge":village_forge,
    "village_market_stall":village_market_stall
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
