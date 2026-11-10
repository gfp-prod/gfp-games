extends SceneTree
## A Latin spell is a real-world operation, not an unconditionally-successful
## button. Suppressed magic never spends mana or secretly mutates its target.

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var world: Node3D = load("res://main.tscn").instantiate()
	root.add_child(world)
	await process_frame
	var plant: Node3D = null
	for obj in world.sim_objects:
		if obj.kind in ["grass","fern"] and not obj.dead:
			plant = obj
			break
	if plant == null:
		_fail("Missing wettable living ecology for spell test")
		return
	var target: Dictionary = {"position":plant.global_position,"entity":plant}
	var mana_at_start: float = world.scholar.mana
	var heat_at_start: float = plant.heat
	world.set_rain(20.0)
	var rain_result: Dictionary = world.player.cast_latin("ignis",target)
	if bool(rain_result.get("ok",true)) or plant.burning:
		_fail("Rain-suppressed ignition incorrectly succeeded or burned the plant")
		return
	if world.scholar.mana != mana_at_start or plant.heat != heat_at_start:
		_fail("Rain suppression nevertheless consumed mana or changed plant heat")
		return
	world.raining = false
	world.rain_remaining = 0.0
	plant.water = .99
	var wet_result: Dictionary = world.player.cast_latin("ignis",target)
	if bool(wet_result.get("ok",true)) or plant.burning or world.scholar.mana != mana_at_start:
		_fail("Saturated living object burned or failed magic charged mana")
		return
	var empty_target: Dictionary = {"position":Vector3(130,1,130),"entity":null}
	var missed: Dictionary = world.player.cast_latin("dormi",empty_target)
	if bool(missed.get("ok",true)) or world.scholar.mana != mana_at_start:
		_fail("An unheard sleep command consumed mana or reported success")
		return
	print("PASS: rainy ignition, waterlogged fuel and unanswered Latin commands cannot fake effects or consume mana")
	quit(0)

func _fail(msg: String) -> void:
	push_error(msg)
	quit(1)
