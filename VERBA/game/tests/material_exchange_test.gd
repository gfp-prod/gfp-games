extends SceneTree
const TRANSFER = preload("res://scripts/material_exchange.gd")

func _initialize() -> void:
	call_deferred("_check")

func _check() -> void:
	var world = load("res://main.tscn").instantiate()
	root.add_child(world)
	await process_frame
	var trees: Array = []
	for obj in world.sim_objects:
		if is_instance_valid(obj) and String(obj.kind) == "tree":
			trees.append(obj)
			if trees.size() >= 2: break
	if trees.size() < 2:
		_fail("Need two actual independent trees")
		return
	var source = trees[0]
	var victim = trees[1]
	source.burning = true
	source.dead = false
	victim.burning = false
	victim.water = 0.0
	victim.heat = 0.0
	victim.position = source.position + Vector3(1.2,0,0)
	world.raining = false
	for i in range(12):
		TRANSFER.transmit_heat(world,0.9)
		if victim.burning: break
	if not victim.burning:
		_fail("Nearby real tree never heated enough to catch naturally")
		return
	var fuel_before: float = float(victim.fuel)
	victim.apply_effect("water",2.0)
	if victim.burning or victim.water < 0.5 or victim.fuel < fuel_before-0.001:
		_fail("Water should quench the same tree without rewriting its history")
		return
	print("PASS: burning tree heated neighbor; second tree ignited; water quenched it with persistent fuel")
	quit(0)

func _fail(why: String) -> void:
	push_error(why)
	quit(1)
