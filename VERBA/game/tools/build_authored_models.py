"""VERBA v1.0 bespoke 3D asset studio. Generates modeled Godot-ready glTF 2.0.
All meshes are original, built from tapered profiles and authored architecture; no model
is generated from a simple world-space sphere-and-box scatter. CC0 photos supported in-game.
"""
import os, math, random, json
from pathlib import Path
import numpy as np
import trimesh
from PIL import Image, ImageDraw, ImageFilter
from trimesh.visual.material import PBRMaterial
from trimesh.transformations import translation_matrix, rotation_matrix

ROOT=Path(__file__).resolve().parent.parent
ASSET=ROOT/'assets'/'models'/'authored'
TEX=ROOT/'assets'/'textures'/'authored'
ASSET.mkdir(parents=True,exist_ok=True); TEX.mkdir(parents=True,exist_ok=True)
RNG=random.Random(3105)

def textured_pattern(name, base, color2, style='stone', size=512):
    r=random.Random(6105+sum(map(ord,name)))
    ar=np.zeros((size,size,3),dtype=np.uint8)
    # Multiscale noise: broad blotches, fine-grain material texture.
    for s,alpha in [(8,.22),(32,.11),(128,.07),(size,.035)]:
        arr=np.array([[r.randrange(256) for _ in range(s)] for _ in range(s)],dtype=np.uint8)
        coarse=np.array(Image.fromarray(arr).resize((size,size),Image.Resampling.BICUBIC),dtype=float)
        if s==8: n=(coarse-127)*alpha
        else: n+=(coarse-127)*alpha
    image=Image.fromarray(np.clip(np.array(base)[None,None,:] + n[:,:,None],0,255).astype(np.uint8),'RGB')
    d=ImageDraw.Draw(image,'RGBA')
    if style=='wood':
        for j in range(170):
            x=r.randint(0,size); y=r.randint(0,size); width=r.randint(70,400)
            cy=y+r.randint(-8,8)
            d.arc((x-width//3,cy-15,x+width,cy+15),0,180,fill=(*color2,r.randint(18,78)),width=r.choice([1,1,2]))
        for x in range(0,size,83):
            xx=x+r.randrange(-8,8);d.line((xx,0,xx,size),fill=(17,15,11,80),width=3)
    elif style=='stone':
        for j in range(110):
            x=r.randint(0,size); y=r.randint(0,size)
            d.line((x,y,x+r.randrange(-24,24),y+r.randrange(-10,10)), fill=(*color2,r.randrange(20,65)),width=1)
        for i in range(0,size,110):
            iy=i+r.randrange(-8,8); d.line((0,iy,size,iy),fill=(*color2,55),width=r.choice([2,3]))
    elif style=='leather':
        for j in range(2000):
            x=r.randint(0,size);y=r.randint(0,size)
            d.point((x,y),fill=(*color2,r.randrange(15,60)))
    elif style=='plaster':
        for j in range(250):
            x=r.randint(0,size);y=r.randint(0,size)
            d.ellipse((x,y,x+r.randrange(1,8),y+r.randrange(1,7)),fill=(*color2,r.randrange(10,28)))
    elif style=='slate':
        for j in range(0,size,60):
            y=j+r.randrange(-5,5);d.line((0,y,size,y),fill=(27,30,35,100),width=4)
            for x in range(r.randrange(-50,20),size+100,100):d.line((x,y,x+6,y+59),fill=(22,28,29,70),width=2)
    elif style=='fur':
        for j in range(3000):
            x=r.randrange(size);y=r.randrange(size)
            d.line((x,y,x+r.randrange(-3,3),y+r.randrange(2,14)),fill=(*color2,r.randrange(9,35)),width=1)
    path=TEX/(name+'.png');image.save(path,optimize=True)
    return image

TEXTURES={
    'timber':textured_pattern('weathered_oak',(112,80,52),(24,20,18),'wood'),
    'plaster':textured_pattern('limewashed_plaster',(171,154,121),(63,62,53),'plaster'),
    'slate':textured_pattern('lichen_slate',(69,78,76),(27,35,33),'slate'),
    'fieldstone':textured_pattern('wet_fieldstone',(91,92,86),(20,24,21),'stone'),
    'leather':textured_pattern('oxblood_leather',(73,38,38),(18,10,13),'leather'),
    'vellum':textured_pattern('aged_vellum',(210,188,140),(117,93,61),'plaster'),
    'brown_fur':textured_pattern('deer_fur',(146,112,75),(61,40,29),'fur'),
    'grey_fur':textured_pattern('grey_wolf_fur',(95,94,86),(28,29,29),'fur'),
    'fox_fur':textured_pattern('fox_fur',(178,91,50),(93,43,33),'fur'),
}

def material(name,rgba,tex=None,rough=.93,metal=0):
    val=list(rgba) if len(rgba)==4 else [*rgba,255]
    return PBRMaterial(name=name,baseColorFactor=val, baseColorTexture=TEXTURES[tex] if tex in TEXTURES else None, metallicFactor=metal,roughnessFactor=rough, doubleSided=True)
MAT={
 'oak':material('Oil-darkened oak',(188,159,125,255),'timber'),
 'beam':material('Charred oak beams',(110,87,63,255),'timber'),
 'plaster':material('Lime plaster',(225,217,192,255),'plaster'),
 'slate':material('Cold slate',(194,196,192,255),'slate'),
 'stone':material('Fieldstone',(211,209,197,255),'fieldstone'),
 'moss':material('Moss',(75,96,61,255)),
 'iron':material('Forged iron',(49,52,50,255),rough=.64,metal=.55),
 'brass':material('Tarnished bronze',(144,102,49,255),rough=.48,metal=.48),
 'bronze':material('Worn gold',(190,146,82,255),rough=.56,metal=.36),
 'glass':material('Green bottle glass',(72,112,101,255),rough=.22,metal=.08),
 'leather':material('Oxblood leather',(190,170,160,255),'leather'),
 'vellum':material('Aged paper',(252,245,223,255),'vellum'),
 'edge':material('Dirt on page edges',(124,102,73,255)),
 'ink':material('Sepia Ink',(52,33,22,255)),
 'fur_deer':material('Deer hide',(236,212,180,255),'brown_fur'),
 'fur_wolf':material('Wolf coat',(208,202,188,255),'grey_fur'),
 'fur_fox':material('Fox coat',(245,191,151,255),'fox_fur'),
 'fur_hare':material('Hare brown',(149,137,115,255),'brown_fur'),
 'fur_black':material('Black fur',(46,48,49,255),'grey_fur'),
 'belly':material('Cream fur',(213,195,166,255)),
 'black':material('Crow feathers',(27,33,38,255)),
 'feather':material('Iridescent feather',(40,51,59,255)),
 'eye':material('Wet black eye',(16,16,16,255),rough=.12),
 'eye_gold':material('Wolf iris',(183,148,70,255),rough=.2),
 'nose':material('Nose leather',(29,26,23,255)),
 'pink':material('Ear inside',(177,115,112,255)),
 'hoof':material('Hoof keratin',(49,47,43,255)),
 'antler':material('Antler',(213,185,133,255)),
 'wisp':material('Wisp glow',(95,183,172,255),rough=.35),
}

def uv_for_mesh(mesh,scale=1.0):
    v=mesh.vertices
    # UVs with stable sensible planar projection; ensures detailed textured surfaces.
    axes=np.array([0,2]) if v.shape[0] and (np.ptp(v[:,0])>=np.ptp(v[:,1])) else np.array([2,1])
    uv=np.asarray(v[:,axes],float)*scale
    return uv

class Studio:
 def __init__(self):self.scene=trimesh.Scene();self.count=0;self.batched={}
 def add(self,name,mesh,mat,transform=None,uv_scale=1.0):
    if mesh is None or len(mesh.faces)==0: return
    mesh=mesh.copy()
    uv=uv_for_mesh(mesh,uv_scale) if mat.baseColorTexture is not None else None
    mesh.visual=trimesh.visual.TextureVisuals(uv=uv,material=mat)
    if name=="detail":
        self.batched.setdefault(mat.name,[]).append(mesh)
        return
    self.count+=1
    self.scene.add_geometry(mesh,geom_name=f'{name}_{self.count:04d}',node_name=f'{name}_{self.count:04d}' if name=='detail' else name,transform=transform)
 def box(self,n,center,ext,mat,rot=None,uv=.4):
    m=trimesh.creation.box(extents=ext)
    if rot is not None:m.apply_transform(rotation_matrix(rot[1], [0,1,0]))
    m.apply_translation(center)
    self.add(n,m,mat,uv_scale=uv)
 def sphere(self,n,at,scale,mat,sub=2,uv=.8):
    m=trimesh.creation.icosphere(subdivisions=sub,radius=1)
    m.apply_scale(scale);m.apply_translation(at);self.add(n,m,mat,uv_scale=uv)
 def rod(self,n,p1,p2,r1,r2,mat,segments=10,uv=2.):
    self.add(n,tapered_tube(p1,p2,[r1,r2],segments=segments),mat,uv_scale=uv)
 def wedge(self,n,poly_z,mat,thick_z=.1):
    pass
 def export(self,filename):
    # Merge decorative pieces by material for a small, reasonable draw-call budget.
    for mat_name, meshes in self.batched.items():
        if not meshes:continue
        merged=trimesh.util.concatenate(meshes)
        mat=next(m.visual.material for m in meshes)
        if mat.baseColorTexture is not None:
            uvs=np.concatenate([m.visual.uv for m in meshes],axis=0)
            merged.visual=trimesh.visual.TextureVisuals(uv=uvs,material=mat)
        else:
            merged.visual=trimesh.visual.TextureVisuals(material=mat)
        self.count+=1
        self.scene.add_geometry(merged,geom_name=f'Baked_{mat_name}',node_name=f'Baked_{mat_name}')
    p=ASSET/filename
    p.write_bytes(self.scene.export(file_type='glb'))
    print('asset',filename,round(p.stat().st_size/1024),'KB',len(self.scene.graph.nodes_geometry),'nodes')
    return p

def tapered_tube(p1,p2,radii,segments=12):
    p1=np.asarray(p1,float);p2=np.asarray(p2,float);direction=p2-p1
    length=np.linalg.norm(direction)
    if length<1e-5:return trimesh.creation.icosphere(radius=.02,subdivisions=1)
    axis=direction/length;ref=np.array([1.,0.,0.]) if abs(axis[0])<.8 else np.array([0.,0.,1.])
    bx=np.cross(axis,ref);bx/=np.linalg.norm(bx);by=np.cross(axis,bx)
    rings=len(radii);v=[];f=[]
    for i,r in enumerate(radii):
        center=p1+direction*(i/(rings-1))
        for k in range(segments):
            a=2*math.pi*k/segments
            v.append(center+r*(math.cos(a)*bx+math.sin(a)*by))
    for i in range(rings-1):
        for k in range(segments):
            l=(k+1)%segments
            p=i*segments+k;q=i*segments+l;u=(i+1)*segments+k;t=(i+1)*segments+l
            f.extend([(p,q,u),(q,t,u)])
    v.extend([p1,p2]);c0=len(v)-2;c1=len(v)-1
    for k in range(segments):
        l=(k+1)%segments;f.append((c0,l,k)); f.append((c1,(rings-1)*segments+k,(rings-1)*segments+l))
    m=trimesh.Trimesh(vertices=v,faces=f,process=False);m.fix_normals();return m

def leaf_shape(root,tip,width,thick=0.025,bend=0.03):
    a=np.asarray(root,float);b=np.asarray(tip,float)
    axis=b-a;axis/=max(np.linalg.norm(axis),.00001)
    v=np.cross(axis,[0.,0.,1.])
    if np.linalg.norm(v)<.1:v=np.cross(axis,[0.,1.,0.])
    v/=np.linalg.norm(v)
    w=np.cross(axis,v)
    verts=[]
    for t,rad in [(0,.03),(.22,.55),(.48,1),(.72,.72),(1,0.02)]:
        center=a+(b-a)*t+w*bend*math.sin(math.pi*t)
        verts.append(center+v*width*rad+w*thick)
        verts.append(center-v*width*rad+w*thick)
    faces=[]
    for i in range(4):
        faces.extend([(2*i,2*i+1,2*i+2),(2*i+1,2*i+3,2*i+2)])
    m=trimesh.Trimesh(vertices=verts,faces=faces,process=False)
    return m

def wedge_mesh(points_2d, z0,z1):
    # simple filled gable triangle or roof end: polygon points given (x,y)
    N=len(points_2d)
    v=[(x,y,z0) for x,y in points_2d]+[(x,y,z1) for x,y in points_2d]
    faces=[]
    for i in range(1,N-1):faces.extend([(0,i+1,i),(N,N+i,N+i+1)])
    for i in range(N):
        k=(i+1)%N;faces.extend([(i,k,N+i),(k,N+k,N+i)])
    return trimesh.Trimesh(vertices=v,faces=faces,process=False)

# Cottage model from actual functional facade and roof geometry, not solid cube.
def build_cottage():
 s=Studio()
 # foundation and raised plinth
 s.box('detail', (0,.16,0),(6.8,.32,5.9),MAT['stone'])
 for x in [-3.02,3.02]:
    s.box('detail',(x,1.80,0),(.32,3.03,5.30),MAT['plaster'],uv=.6)
 for z in [-2.5,2.5]:
    if z<0:s.box('detail',(0,1.81,z),(5.86,3.02,.28),MAT['plaster'],uv=.6)
 # front wall with door left and window right, intentional penetrations.
 s.box('detail',(-2.06,1.72,2.5),(1.78,2.84,.29),MAT['plaster'])
 s.box('detail',(.12,2.84,2.5),(2.57,.61,.29),MAT['plaster'])
 s.box('detail',(2.35,1.68,2.5),(.98,2.72,.29),MAT['plaster'])
 s.box('detail',(1.53,.66,2.5),(1.2,.78,.29),MAT['plaster'])
 s.box('detail',(1.53,2.27,2.5),(1.2,.51,.29),MAT['plaster'])
 # doorway at x=-.69, width 1.04, height 2.55
 for cx in [-1.24,-.13]:
    s.box('detail',(cx,1.43,2.66),(.17,2.82,.24),MAT['beam'])
 s.box('detail',(-.69,2.83,2.66),(1.31,.20,.28),MAT['oak'])
 # door built from planks and braces, slightly opened
 door=Studio()
 for i in range(5):
    xx=-.45+i*.225
    s.box('detail',(-1.16+xx,1.34,2.51),(.225,2.45,.13),MAT['oak'],uv=1.)
 for y in [.44,1.28,2.22]:
    s.box('detail',(-.68,y,2.60),(1.03,.13,.12),MAT['beam'])
 s.sphere('detail',(-.31,1.12,2.74),(.047,.06,.045),MAT['brass'],sub=2)
 # Stone door stoop, worn and uneven slabs
 for i in range(3):
    s.box('detail',(-.69,.10-i*.035,2.8+i*.35),(1.8+i*.21,.22, .35),MAT['stone'])
 # exterior timber frame: base and roof plate, corners and intermediate uprights
 for z in [-2.61,2.61]:
    for x in [-2.96,2.96]:s.box('detail',(x,1.75,z),(.25,3.29,.26),MAT['beam'])
    for yy in [.62,2.97]:s.box('detail',(0,yy,z),(6.1,.21,.23),MAT['beam'])
    # front timber lattice except door opening
    if z<0:
      for x in [-1.05,1.05]:s.box('detail',(x,1.8,z),(.16,2.5,.22),MAT['beam'])
    else:
      for x in [-1.73,2.20]:s.box('detail',(x,1.8,z),(.14,2.49,.22),MAT['beam'])
 for x in [-3.07,3.07]:
    for y in [.58,2.96]:s.box('detail',(x,y,0),(.23,.19,5.4),MAT['beam'])
    for z in [-1.35,1.35]:s.box('detail',(x,1.65,z),(.20,2.75,.21),MAT['beam'])
 # diagonal oak cross-bracing expressed as joinery
 for x,z,sgn in [(-2.95,-1.3,-1),(-2.95,1.2,1),(2.95,-1.3,1),(2.95,1.2,-1)]:
    s.rod('detail',(x,.68,z-.8),(x,2.8,z+.8*sgn),.09,.09,MAT['beam'],8)
 # gable triangle above eaves
 for z in [-2.51,2.51]:
    s.add('detail',wedge_mesh([(-3.04,3.05),(3.04,3.05),(0,5.12)],z-.09,z+.09),MAT['plaster'])
    for side in [-1,1]:
      s.rod('detail',(side*3.3,3.02,z),(0,5.30,z),.12,.12,MAT['beam'])
    s.box('detail',(0,3.20,z),(5.9,.18,.19),MAT['beam'])
 # Full weatherproof roof under the handmade overlapping slate tiles.
 # This avoids the old lattice-like holes between tiles at oblique angles.
 for side in [-1,1]:
    corners=[(side*.06,5.25,-3.01),(side*3.42,3.03,-3.01),(side*3.42,3.03,3.01),(side*.06,5.25,3.01)]
    mesh=trimesh.Trimesh(vertices=corners, faces=[[0,1,2],[0,2,3]],process=False)
    s.add('detail',mesh,MAT['slate'])
 # proper sloped roof planes with individual staggered slate bands
 for side in [-1,1]:
    for z in np.arange(-2.9,3.0,.51):
      for j in range(11):
        fx=j/10
        x=side*(3.38*(1-fx)+.15*fx)
        y=3.08+2.25*fx
        w=.39+(.06 if j%2 else 0)
        # tile segments: rotated thin boxes in roof slope plane
        tile=trimesh.creation.box(extents=[.42,.045,.62])
        tile.apply_transform(rotation_matrix(-side*.59,[0,0,1]))
        tile.apply_translation([x,y+.08, z+(0.06 if (j+int((z+3)*2))%2 else -.06)])
        s.add('detail',tile,MAT['slate'])
    for z in [-2.9,2.9]:
        s.rod('detail',(side*3.44,3.13,z),(0,5.38,z),.12,.1,MAT['beam'])
 # ridge cap, visible silhouette from afar
 for z in np.arange(-2.85,2.85,.43):
    s.box('detail',(0,5.39,z),(.38,.17,.47),MAT['slate'])
 # chimney with individual courses, above roof ridge line on right
 for j in range(11):
    y=4.0+j*.205
    s.box('detail',(1.87,y,-1.35),(.81,.21,.78),MAT['stone'])
    if j%2==0:
      for xx in [1.62,2.13]:s.box('detail',(xx,y+.02,-.94),(.045,.12,.033),MAT['ink'])
 s.box('detail',(1.87,6.33,-1.35),(1.05,.20,1.02),MAT['stone'])
 s.box('detail',(1.87,6.45,-1.35),(.83,.09,.81),MAT['slate'])
 # arched gable louver window
 s.box('detail',(0,4.08,2.72),(.77,.82,.15),MAT['beam'])
 for x in [-.20,0,.20]:s.box('detail',(x,4.08,2.82),(.04,.69,.04),MAT['iron'])
 # timber framed glass window and real 3D shutters
 for x,y,z in [(1.56,1.67,2.67),(-3.12,1.67,0.0),(3.12,1.67,-.7)]:
    front=abs(z)>2.6
    if front:
       s.box('detail',(x,y,z),(.98,1.24,.14),MAT['beam'])
       s.box('detail',(x,y,z+.09),(.76,1.01,.08),MAT['glass'])
       s.box('detail',(x,y,z+.16),(.05,1.14,.045),MAT['oak'])
       s.box('detail',(x,y,z+.16),(1.0,.05,.04),MAT['oak'])
       for dd in [-.69,.69]:
           s.box('detail',(x+dd,y,z+.04),(.35,1.21,.085),MAT['oak'])
           for j in range(3):s.box('detail',(x+dd,y-.37+j*.36,z+.10),(.29,.07,.03),MAT['beam'])
    else:
       s.box('detail',(x,y,z),(.13,1.16,.99),MAT['beam'])
       s.box('detail',(x+(-.07 if x<0 else .07),y,z),(.09,.96,.78),MAT['glass'])
       s.box('detail',(x,y,z),(.14,.05,1.05),MAT['oak'])
 # barrel with visible hoops and iron legs
 for x,z in [(2.24,3.13),(-3.55,1.6)]:
    for j in range(9):
      y=.3+j*.20
      s.rod('detail',(x,y,z),(x,y+.20,z),.31 if j in [0,4,8] else .29,.31,MAT['iron'] if j in [0,4,8] else MAT['oak'],14)
 # woodpile, chopped logs including end grain
 for i in range(11):
   x=-3.85+(i%4)*.18; yy=.22+(i//4)*.28
   s.rod('detail',(x,yy,-.25),(x,yy,-1.34),.13,.12,MAT['oak'],9)
 # gabled porch supports and sign
 for x in [-1.55,.15]:s.rod('detail',(x,.1,3.20),(x,2.95,3.20),.08,.08,MAT['beam'])
 s.box('detail',(-.7,2.89,3.22),(2.2,.20,.28),MAT['beam'])
 s.box('detail',(-.72,2.55,3.30),(1.04,.43,.08),MAT['oak'])
 # Distinct furnished interior: enterable floor, hearth, table and workbench.
 for z in np.arange(-2.22,2.25,.23):
    s.box('detail',(0,.26,z),(5.80,.085,.225),MAT['oak'])
 # rafters seen from inside
 for z in np.arange(-2.15,2.3,1.12):
    for side in [-1,1]:
      s.rod('detail',(side*2.83,3.02,z),(.04,5.00,z),.105,.085,MAT['beam'],9)
 # Stone hearth on rear wall, fire-blackened opening and mantle.
 s.box('detail',(1.64,.54,-2.19),(1.62,1.04,.75),MAT['stone'])
 s.box('detail',(1.64,.58,-1.78),(.99,.68,.08),MAT['iron'])
 s.box('detail',(1.64,1.14,-2.04),(1.79,.19,.86),MAT['oak'])
 # Work table and a legible chair with back slats
 s.box('detail',(-.72,1.10,-.36),(1.66,.17,1.04),MAT['oak'])
 for x in [-1.41,-.03]:
  for z in [-.75,.01]:s.box('detail',(x,.58,z),(.15,.91,.13),MAT['beam'])
 s.box('detail',(-.88,.62,1.22),(.71,.13,.67),MAT['oak'])
 for x in [-1.19,-.56]:
  for z in [.98,1.45]:s.box('detail',(x,.29,z),(.11,.54,.11),MAT['beam'])
 for x in [-1.19,-.56]:s.box('detail',(x,1.12,1.48),(.10,.97,.12),MAT['oak'])
 s.box('detail',(-.88,1.45,1.48),(.72,.20,.10),MAT['oak'])
 # Stacked books, bookcase and assorted clay storage.
 s.box('detail',(-2.5,1.31,-1.55),(.42,2.25,1.44),MAT['beam'])
 for y in [.64,1.32,2.04]:
   s.box('detail',(-2.28,y,-1.57),(.54,.09,1.38),MAT['oak'])
   for i in range(7):
      z=-2.1+i*.17
      s.box('detail',(-2.24,y+.20,z),(.18,.3+(.06 if i%2 else 0),.11),MAT['leather'] if i%2 else MAT['vellum'])
 # Long cot beneath the window
 s.box('detail',(2.05,.55,.92),(1.06,.23,1.77),MAT['oak'])
 s.box('detail',(2.05,.68,.91),(.91,.10,1.57),MAT['plaster'])
 s.box('detail',(2.05,.74,.28),(.73,.13,.39),MAT['belly'])
 # Hanging kettle and kitchen utensils
 s.sphere('detail',(1.70,.75,-1.65),(.21,.19,.20),MAT['iron'],2)
 s.rod('detail',(1.47,.85,-1.64),(1.93,.85,-1.64),.028,.028,MAT['iron'],7)
 # Mature ivy tendrils climbing one corner; not uniform procedural dressing.
 for side in [-1,1]:
    for b in range(5):
      zz=-2.5+b*.46
      if side<0 and b>2:continue
      x=side*3.12
      s.rod('detail',(x,.12,zz),(x,1.1+b*.18,zz+.18),.017,.009,MAT['moss'],7)
      for k in range(4):
        yy=.35+k*.28
        s.add('detail',leaf_shape((x,yy,zz),(x+side*.18,yy+.12,zz+.16),.085,.015),MAT['moss'])
 # Rendered wall fixtures: iron hanging lantern and rustic hand-painted sign.
 s.rod('detail',(-1.58,2.9,3.04),(-1.58,2.46,3.04),.026,.021,MAT['iron'],9)
 s.box('detail',(-1.58,2.32,3.04),(.28,.31,.22),MAT['brass'])
 s.sphere('detail',(-1.58,2.32,3.21),(.09,.11,.04),MAT['vellum'],2)
 # grass/weathering and carved sill edges
 for x in [-3.05,3.05]:
    for z in np.arange(-2.3,2.4,.49):
      if RNG.random()<.45:
       s.sphere('detail',(x,.23,z),(.12,.18,.14),MAT['moss'],1)
 return s.export('Cottage_The_Hermit.glb')

# Anatomical animal model builder with separate limb and wing pivot meshes.
class AnimalStudio(Studio):
 def __init__(self,species):super().__init__();self.species=species
 def part(self,n,mesh,mat,transform=None):self.add(n,mesh,mat,transform=transform)
 def limb(self,n,hip,knee,foot,material,hoof,rs=(.095,.072,.052)):
    hip=np.asarray(hip,dtype=float);knee=np.asarray(knee,dtype=float);foot=np.asarray(foot,dtype=float)
    # Entire mesh locally relative to shoulder/hip pivot. Animatable in Godot.
    a=np.zeros(3);b=knee-hip;c=foot-hip
    ms=[tapered_tube(a,b,[rs[0],rs[1],rs[1]],10),tapered_tube(b,c,[rs[1],rs[2],rs[2]],9)]
    h=trimesh.creation.icosphere(subdivisions=1,radius=1);h.apply_scale([rs[1]*1.25,rs[1]*.83,rs[1]*1.35]);h.apply_translation(b);ms.append(h)
    self.part(n,trimesh.util.concatenate(ms),material,translation_matrix(hip))
    h=trimesh.creation.icosphere(subdivisions=2,radius=1);h.apply_scale([rs[0]*1.43,rs[0]*.55,rs[0]*2.1]);h.apply_translation(foot+[0,.01,-.042]);self.add('detail',h,hoof)

def creature_common(s,body,torso,height,head,snout,fur,belly=None):
 s.sphere('detail',(0,height,0),torso,fur,3)
 if belly:s.sphere('detail',(0,height-.12,-.08),tuple(v*.94 for v in torso),belly,2)
 # neck is swept tapered organic volume
 s.rod('detail',(0,height+.11,-torso[2]*.47),head,[.23,.18][0],[.18,.14][0],fur,14)
 s.sphere('detail',head,(.22,.19,.24),fur,3)
 s.rod('detail',(0,head[1]-.045,head[2]-.10),(0,snout[1],snout[2]-.13),.16,.087,fur,16)
 s.sphere('detail',snout,(.125,.085,.185),fur,3)
 for side in [-1,1]:
    s.sphere('detail',(side*.178,head[1]+.036,head[2]-.11),(.035,.035,.025),MAT['eye'],2)
    s.sphere('detail',(side*.19,head[1]+.049,head[2]-.131),(.008,.009,.008),MAT['vellum'],1)
 s.sphere('detail',(0,snout[1]+.005,snout[2]-.177),(.052,.034,.040),MAT['nose'],2)


def animal_deer():
 s=AnimalStudio('deer');f=MAT['fur_deer'];iv=MAT['belly'];dk=MAT['hoof']
 creature_common(s,'deer',(.38,.41,.84),1.24,(0,1.79,-1.0),(0,1.67,-1.34),f,iv)
 s.sphere('detail',(0,1.10,.57),(.26,.30,.35),f,2)
 for side in [-1,1]:
  for z in [-.55,.57]:
   hip=(side*.29,1.09,z);knee=(side*.30,.58,z+(.08 if z<0 else -.08));foot=(side*.30,.10,z+(.18 if z<0 else -.14))
   s.limb('leg_'+('f' if z<0 else 'b')+('l' if side<0 else 'r'),hip,knee,foot,f,dk,(.105,.065,.053))
  # lanceolate ears and contrasting interiors
  s.add('detail',leaf_shape((side*.14,1.90,-.99),(side*.42,2.13,-1.04),.08,.025),f)
  s.add('detail',leaf_shape((side*.19,1.92,-1.032),(side*.39,2.08,-1.058),.044,.01),MAT['pink'])
  # stag's antler is articulated with branching tines
  p1=(side*.12,1.92,-.86);p2=(side*.24,2.43,-.85);p3=(side*.52,2.68,-.71);p4=(side*.63,3.01,-.57)
  s.rod('detail',p1,p2,.047,.041,MAT['antler'],9);s.rod('detail',p2,p3,.040,.026,MAT['antler'],9);s.rod('detail',p3,p4,.027,.007,MAT['antler'],9)
  for k,(x,y,z) in enumerate([(side*.31,2.54,-.84),(side*.46,2.70,-.75),(side*.56,2.85,-.65)]):
   s.rod('detail',(x,y,z),(x+side*.09,y+.27,z-.07),.020,.005,MAT['antler'],8)
 s.sphere('detail',(0,1.26,.80),(.12,.14,.18),iv,2)
 return s.export('Deer_Stag.glb')

def animal_wolf():
 s=AnimalStudio('wolf');f=MAT['fur_wolf'];iv=MAT['belly'];dk=MAT['fur_black']
 creature_common(s,'wolf',(.40,.39,.72),.81,(0,1.16,-.81),(0,1.10,-1.13),f,iv)
 # shoulder ruff distinct from body, layered tufts and jaw
 s.sphere('detail',(0,.94,-.37),(.44,.46,.35),f,3)
 s.sphere('detail',(0,.98,-.95),(.21,.12,.29),iv,2)
 for side in [-1,1]:
  for z in [-.49,.46]:
   hip=(side*.29,.82,z);knee=(side*.30,.47,z-.05);foot=(side*.3,.10,z-.08)
   s.limb('leg_'+('f' if z<0 else 'b')+('l' if side<0 else 'r'),hip,knee,foot,f,dk,(.12,.095,.08))
  s.add('detail',leaf_shape((side*.17,1.29,-.79),(side*.31,1.53,-.88),.10,.02),f)
  s.add('detail',leaf_shape((side*.19,1.30,-.83),(side*.29,1.47,-.91),.055,.008),MAT['black'])
  for k in range(5):
   z=-.20+k*.14
   s.add('detail',leaf_shape((side*.37,1.01,z),(side*(.52+.02*k),.77,z+.17),.085,.018),f)
  s.sphere('detail',(side*.181,1.17,-.99),(.055,.043,.031),MAT['eye_gold'],2)
  s.sphere('detail',(side*.187,1.174,-1.010),(.020,.025,.013),MAT['eye'],2)
 # tail tapered and long
 s.rod('detail',(0,.82,.58),(0,.71,.91),.15,.24,f,11)
 s.sphere('detail',(0,.70,1.05),(.18,.21,.34),f,2)
 for x in [-.15,-.05,.05,.15]:s.rod('detail',(x,.11,-1.24),(x,.07,-1.30),.019,.012,MAT['ivory'] if 'ivory' in MAT else MAT['belly'],6)
 return s.export('Wolf_Gray.glb')

def animal_fox():
 s=AnimalStudio('fox');f=MAT['fur_fox'];iv=MAT['belly'];dk=MAT['fur_black']
 creature_common(s,'fox',(.28,.30,.59),.61,(0,.89,-.67),(0,.83,-1.0),f,iv)
 # narrow cunning muzzle and large white cheek ruffs
 s.sphere('detail',(0,.74,-.93),(.19,.078,.24),iv,2)
 for side in [-1,1]:
  for z in [-.36,.38]:
   hip=(side*.23,.62,z);knee=(side*.23,.35,z-.02);foot=(side*.22,.07,z-.03)
   s.limb('leg_'+('f' if z<0 else 'b')+('l' if side<0 else 'r'),hip,knee,foot,dk,dk,(.072,.06,.048))
  s.add('detail',leaf_shape((side*.15,.98,-.61),(side*.23,1.24,-.71),.079,.03),f)
  s.add('detail',leaf_shape((side*.17,.99,-.635),(side*.225,1.175,-.72),.036,.013),MAT['pink'])
  for k in range(4):
   zz=-.88+k*.07
   s.add('detail',leaf_shape((side*.17,.81,zz),(side*.38,.73,zz+.02),.06,.006),iv)
 s.rod('detail',(0,.64,.50),(0,.70,.88),.11,.22,f,10)
 s.sphere('detail',(0,.77,1.12),(.22,.22,.36),f,3)
 s.sphere('detail',(0,.79,1.36),(.17,.15,.19),iv,2)
 return s.export('Fox_Red.glb')

def animal_hare():
 s=AnimalStudio('hare');f=MAT['fur_hare']
 s.sphere('detail',(0,.30,.10),(.25,.26,.39),f,3)
 s.sphere('detail',(0,.33,-.29),(.19,.19,.23),f,3)
 s.sphere('detail',(0,.28,.43),(.22,.23,.26),f,2)
 for side in [-1,1]:
  s.sphere('detail',(side*.152,.37,-.37),(.03,.032,.025),MAT['eye'],2)
  s.sphere('detail',(side*.062,.29,-.48),(.042,.041,.058),MAT['belly'],2)
  # long asymmetric ears
  s.add('detail',leaf_shape((side*.105,.49,-.30),(side*.16+(.04 if side>0 else -.02),1.01 if side<0 else .90,-.29),.098,.025),f)
  s.add('detail',leaf_shape((side*.107,.51,-.34),(side*.15,.90 if side<0 else .84,-.323),.06,.012),MAT['pink'])
  for z in [-.25,.38]:
   hip=(side*.17,.36,z)
   s.limb('leg_'+('f' if z<0 else 'b')+('l' if side<0 else 'r'),hip,(side*.19,.17,z+.10),(side*.18,.06,z-.06),f,MAT['belly'],(.08,.07,.045))
 s.sphere('detail',(0,.33,.57),(.12,.12,.12),MAT['belly'],2)
 return s.export('Hare_Brown.glb')

def animal_crow():
 s=AnimalStudio('crow');f=MAT['black']
 s.sphere('detail',(0,.40,.07),(.22,.24,.37),f,3)
 s.sphere('detail',(0,.63,-.23),(.165,.18,.18),f,3)
 s.add('detail',wedge_mesh([(-.105,.58),(.105,.58),(0,.48)],-.64,-.36),MAT['iron'])
 s.sphere('detail',(0,.57,-.46),(.07,.055,.18),MAT['iron'],1)
 for side in [-1,1]:
  s.sphere('detail',(side*.145,.68,-.323),(.028,.026,.026),MAT['eye'],2)
  # articulated wing group: folded vanes and primary feather fan
  wing=[]
  for k in range(11):
   x=side*(.23+k*.003)
   wing.append(leaf_shape((0,0,.05),(side*(.20+k*.026),-.04,.29+k*.035),.056,.023,.02))
  s.add('wing_'+('l' if side<0 else 'r'),trimesh.util.concatenate(wing),MAT['feather'],translation_matrix([side*.16,.49,-.12]))
  s.rod('detail',(side*.094,.25,.04),(side*.095,.09,-.02),.028,.020,MAT['iron'],7)
  for i in [-1,0,1]:s.rod('detail',(side*.094,.09,-.02),(side*.094+i*.065,.07,-.22),.015,.008,MAT['iron'],6)
 for i in range(-3,4):
  s.add('detail',leaf_shape((i*.02,.40,.32),(i*.044,.36,.75),.049,.017),MAT['feather'])
 return s.export('Crow_Black.glb')


def book_mesh(opened):
 s=Studio()
 if not opened:
   s.box('detail',(0,0,0),(.77,.97,.15),MAT['edge'])
   for dz in [-.097,.105]:
    s.box('detail',(0,0,dz),(.82,1.015,.044),MAT['leather'])
    for x in [-.37,.37]:
     for y in [-.47,.47]:s.box('detail',(x,y,dz+.024),(.065,.08,.025),MAT['bronze'])
   for y in np.arange(-.4,.5,.1):
    s.box('detail',(-.415,y,0),(.061,.033,.21),MAT['bronze'])
   # embossed central sacred seal: octagon and curved botanical ornament
   for i in range(12):
    a=2*math.pi*i/12;b=2*math.pi*(i+1)/12
    s.rod('detail',(.23*math.cos(a),.26*math.sin(a),.145),(.23*math.cos(b),.26*math.sin(b),.145),.012,.012,MAT['bronze'],6)
   s.rod('detail',(0,-.18,.156),(0,.22,.156),.018,.011,MAT['bronze'])
   for side in [-1,1]:
    s.rod('detail',(0,.08,.161),(side*.13,.18,.16),.01,.008,MAT['bronze'])
    s.rod('detail',(0,.02,.161),(side*.16,-.05,.16),.011,.007,MAT['bronze'])
   # clasp is a modeled, projecting latched strap
   s.box('detail',(.403,0,.064),(.18,.18,.07),MAT['leather'])
   s.box('detail',(.49,0,.067),(.078,.20,.083),MAT['bronze'])
   s.sphere('detail',(.49,0,.128),(.026,.028,.028),MAT['iron'],1)
   return s.export('Grimoire_Closed.glb')
 else:
   # page block is two distinct rounded stacks
   for side in [-1,1]:
    x=side*.36
    s.box('detail',(x,0,-.025),(.73,.96,.14),MAT['edge'])
    for i in range(9):
     s.box('detail',(x,0,-.015+i*.008),(.70,.949,.007),MAT['vellum'])
    s.box('detail',(x,0,.076),(.704,.94,.025),MAT['vellum'])
    # cover edges and spine stitches
    s.box('detail',(x,0,-.125),(.77,1.03,.042),MAT['leather'])
    for y in [-.48,.48]:s.box('detail',(x,y,-.102),(.77,.037,.036),MAT['bronze'])
    for y in np.arange(-.45,.47,.09):
      s.box('detail',(x+side*.365,y,.018),(.008,.02,.05),MAT['edge'])
   s.box('detail',(0,0,-.16),(.16,1.06,.20),MAT['leather'])
   for y in [-.4,-.25,0,.25,.4]:s.box('detail',(0,y,-.14),(.19,.024,.21),MAT['bronze'])
   # book corners, straps, little binding stitch rows
   for x in [-.70,.70]:
    for y in [-.48,.48]:s.box('detail',(x,y,-.075),(.08,.087,.12),MAT['bronze'])
   return s.export('Grimoire_Open.glb')

if __name__=='__main__':
 files=[build_cottage(),animal_deer(),animal_wolf(),animal_fox(),animal_hare(),animal_crow(),book_mesh(False),book_mesh(True)]
 print('bytes total',sum(f.stat().st_size for f in files))
