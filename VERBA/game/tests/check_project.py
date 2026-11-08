from pathlib import Path
import json,struct
P=Path(__file__).resolve().parents[1]
assert (P/'project.godot').is_file()
assert (P/'main.tscn').is_file()
for name in ['player.gd','creature.gd','world.gd','navigation_builder.gd','external_art.gd']:
    assert (P/'scripts'/name).is_file(),name
for p in (P/'assets/models/authored').glob('*.glb'):
    raw=p.read_bytes()
    assert len(raw)>100 and raw[:4]==b'glTF',p
    assert struct.unpack('<I',raw[8:12])[0]==len(raw),p
assert json.loads((P/'data/lexicon.json').read_text())
assert 'move_and_slide()' in (P/'scripts/player.gd').read_text()
assert 'NavigationAgent3D.new()' in (P/'scripts/creature.gd').read_text()
assert 'body.collision_layer = 16' in (P/'scripts/world.gd').read_text()
print('PASS static asset headers + mandatory modules + world collision mask')
