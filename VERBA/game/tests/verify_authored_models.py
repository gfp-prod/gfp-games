"""VERBA v1 art import smoke checks using trimesh, without requiring Godot."""
from pathlib import Path
import trimesh
r=Path(__file__).resolve().parents[1]
expect={
 'Cottage_The_Hermit.glb':(5000, 6),
 'Deer_Stag.glb':(4000, 8),
 'Wolf_Gray.glb':(4000, 8),
 'Fox_Red.glb':(4000, 7),
 'Hare_Brown.glb':(2500, 6),
 'Crow_Black.glb':(1200, 4),
 'Grimoire_Open.glb':(300, 3),
 'Grimoire_Closed.glb':(400, 3),
}
for name,(min_faces,min_nodes) in expect.items():
 path=r/'assets/models/authored'/name
 assert path.is_file(),name
 scene=trimesh.load(path,force='scene')
 assert len(scene.geometry)>=min_nodes,(name,'parts',len(scene.geometry))
 faces=sum(len(g.faces) for g in scene.geometry.values())
 assert faces>=min_faces,(name,'triangles',faces)
 print('MODEL OK:',name,'triangles=',faces,'separate meshes=',len(scene.geometry))
for name in ['Deer_Stag','Wolf_Gray','Fox_Red','Hare_Brown']:
 nodes=trimesh.load(r/'assets/models/authored'/(name+'.glb'),force='scene').graph.nodes_geometry
 for leg in ['leg_fl','leg_fr','leg_bl','leg_br']:
  assert leg in nodes,(name,leg,nodes)
for wing in ['wing_l','wing_r']:
 assert wing in trimesh.load(r/'assets/models/authored/Crow_Black.glb',force='scene').graph.nodes_geometry
for n in ['world.gd','creature.gd','grimoire.gd']:
 text=(r/'scripts'/n).read_text()
 assert '.glb' in text,(n,'missing live asset integration')
assert 'Cottage_The_Hermit.glb' in (r/'scripts/world.gd').read_text()
assert 'Grimoire_Open.glb' in (r/'scripts/grimoire.gd').read_text()
print('PASS: all authored GLB files load; named anatomy pivots and integration paths present.')
