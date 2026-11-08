"""Static checks only. Not a substitute for Godot import/GUI testing."""
import json
from pathlib import Path
root = Path(__file__).resolve().parents[1]
needed = ['project.godot','main.tscn','scripts/player.gd','scripts/grimoire.gd','scripts/magic.gd',
'scripts/world.gd','scripts/creature.gd','scripts/pickup.gd','scripts/incantation.gd',
'assets/textures/leather.png','assets/textures/vellum.png','assets/textures/stone.png',
'assets/textures/bark.png','data/lexicon.json']
for rel in needed:
    assert (root/rel).exists(), f'Missing: {rel}'
lex = json.loads((root/'data/lexicon.json').read_text())
words = [w['word'] for w in lex]
assert len(set(words)) == len(words) and len(words)>=16
for key in ['ignis','pluvia','cresce','dormi','muta','lux']:
    assert key in words
p=(root/'scripts/player.gd').read_text()
for marker in ['Input.MOUSE_MODE_CAPTURED','event.relative.x','event.relative.y','KEY_W','KEY_S','KEY_A','KEY_D','book.toggle()','finish_cast()']:
    assert marker in p, marker
assert 'MOUSE_BUTTON_LEFT' in p and 'dragging' not in p.lower()
b=(root/'scripts/grimoire.gd').read_text()
for marker in ['apply_pose','turn_page','Label3D','persist','restore','Grimoire_Open.glb','ClosedBindingAndClasp']:
    assert marker in b, marker
w=(root/'scripts/world.gd').read_text()
for marker in ['height_at','stream_x','build_landmarks','spawn_tree','rain_remaining','nearest_fire_distance']:
    assert marker in w, marker
print('STATIC PASS: source paths, vocabulary, expected components and control code found.')
print('NOTE: Godot parser, native gameplay, graphics and actual frame rate remain UNTESTED.')
