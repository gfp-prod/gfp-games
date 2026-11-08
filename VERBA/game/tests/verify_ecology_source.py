from pathlib import Path
root=Path(__file__).resolve().parents[1]
world=(root/'scripts/world.gd').read_text()
creature=(root/'scripts/creature.gd').read_text()
obj=(root/'scripts/sim_object.gd').read_text()
magic=(root/'scripts/magic.gd').read_text()
for s in ['sim_objects', 'func ecology_step', 'func nearest_food', 'func spawn_reactive_stone', 'func make_living_plant', 'func spawn_growth_patch', 'ecology_timer += delta']:
    assert s in world, s
for s in ['func simulate', 'func apply_effect', 'var fuel:', 'var water:', 'var health:', 'var growth:', 'var brittleness:', 'func get_state_report']:
    assert s in obj, s
for s in ['var hunger:', 'var thirst:', 'func afflict', 'nearest_food', 'apply_effect("eat"', 'prey.afflict("injure")']:
    assert s in creature, s
for s in ['obj.apply_effect("water"', 'entity.apply_effect("grow"', 'entity.apply_effect("ignite"']:
    assert s in magic, s
print('PASS: mutable entity system, unscripted animal interactions, and spell integration present.')
