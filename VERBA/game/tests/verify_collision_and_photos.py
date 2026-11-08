"""Static contract tests. Requires separate Godot engine run for gameplay validation."""
from pathlib import Path
from PIL import Image
root=Path(__file__).resolve().parents[1]
player=(root/'scripts/player.gd').read_text()
creature=(root/'scripts/creature.gd').read_text()
world=(root/'scripts/world.gd').read_text()
assert 'extends CharacterBody3D' in player
assert 'extends CharacterBody3D' in creature
assert 'move_and_slide()' in player and 'move_and_slide()' in creature
assert 'NavigationAgent3D' in creature
assert 'navigation_region = NAV_BUILDER.install(self)' in world
assert 'PhysicsRayQueryParameters3D.create' in creature
assert 'collision_mask=16' in player
assert 'collision_mask = 16 | 32' in creature
assert 'collider.collision_layer=4|16' in world
for x in ('WestCottageWall','EastCottageWall','BackCottageWall','ClosedWoodenDoor','PrioryWestWall','StoneShrineBlock','RidgeArchPillarWest','FallenOakSolid','RockOutcropSolid'):
    assert x in world, x
for name in ('meadow_ground','woodland_ground','amber_ground','river_silt','earth_path','stone','moss','cottage_plaster','cottage_roof'):
    for ending in ('diffuse','normal'):
        p=root/f'assets/textures/real/{name}_{ending}.jpg'
        assert p.exists() and p.stat().st_size>50000, p
        with Image.open(p) as img:
            assert img.size==(1024,1024) and img.mode=='RGB'
print('STATIC PASS: solid creature and player movement, collision obstacles, photo maps')
print('ENGINE RUN STILL REQUIRED: Godot import, walking around cottage, animal steering, FPS')
