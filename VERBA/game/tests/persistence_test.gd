extends SceneTree
const PERSIST = preload("res://scripts/world_persistence.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var world = load("res://main.tscn").instantiate()
	root.add_child(world)
	await process_frame
	if world.sim_objects.is_empty() or world.creatures.is_empty():
		_fail("No persistent ecosystem to test")
		return
	var obj = world.sim_objects[0]
	var creature = world.creatures[0]
	var original_pos: Vector3 = world.player.position
	obj.growth = 1.63
	obj.water = 0.78
	obj.health = 0.39
	creature.hunger = 0.91
	creature.energy = 0.24
	world.wind = -2.1
	world.player.position += Vector3(3,0,-2)
	var record: Dictionary = PERSIST.snapshot(world)
	obj.growth = 1.0
	obj.water = 0.0
	obj.health = 1.0
	creature.hunger = 0.1
	creature.energy = 1.0
	world.wind = 0.0
	world.player.position = original_pos
	if not PERSIST.apply_snapshot(world,record):
		_fail("Could not restore memory")
		return
	if absf(obj.growth-1.63)>0.001 or absf(obj.water-0.78)>0.001 or absf(obj.health-0.39)>0.001:
		_fail("Individual tree/rock state did not survive")
		return
	if absf(creature.hunger-.91)>0.001 or absf(creature.energy-.24)>0.001:
		_fail("Animal needs didn't survive")
		return
	if absf(world.wind+2.1)>0.001 or world.player.position.distance_to(original_pos+Vector3(3,0,-2))>.01:
		_fail("Weather or player position didn't survive")
		return
	var path := "user://verba_persistence_regression.json"
	if not PERSIST.save_world(world,path):
		_fail("Could not write independent file")
		return
	obj.water = 0.0
	if not PERSIST.load_world(world,path) or absf(obj.water-0.78) > .001:
		_fail("Independent saved world did not reload from file")
		return
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("PASS: individual object growth, moisture, health, animal needs, climate and player location persisted")
	quit(0)

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
