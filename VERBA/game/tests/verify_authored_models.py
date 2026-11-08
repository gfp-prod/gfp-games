"""Validate the still-used authored cottage and book, and ensure old animal art is absent."""
from pathlib import Path
import trimesh
p=Path(__file__).resolve().parents[1]
expected={'Cottage_The_Hermit.glb':(5000,6),'Grimoire_Open.glb':(300,3),'Grimoire_Closed.glb':(400,3)}
for name,(min_faces,min_meshes) in expected.items():
    file=p/'assets/models/authored'/name
    assert file.is_file(),name
    scene=trimesh.load(file,force='scene')
    assert len(scene.geometry)>=min_meshes,(name,'meshes')
    assert sum(len(g.faces) for g in scene.geometry.values())>=min_faces,(name,'faces')
for name in ['Deer_Stag.glb','Wolf_Gray.glb','Fox_Red.glb','Hare_Brown.glb','Crow_Black.glb']:
    assert not (p/'assets/models/authored'/name).exists(),name+' legacy animal not removed'
for name in ['Deer.gltf','Stag.gltf','Wolf.gltf','Fox.gltf','Hare.glb','Crow.glb']:
    assert (p/'assets/models/cc0/wildlife'/name).is_file(),name
creature=(p/'scripts/creature.gd').read_text()
assert 'Hare_Brown.glb' not in creature and 'Crow_Black.glb' not in creature
print('PASS: only the three active authored cottage/grimoire models remain; six rigged wildlife sources available')
