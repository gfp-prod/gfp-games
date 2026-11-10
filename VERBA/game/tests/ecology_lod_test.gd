extends SceneTree
func _initialize() -> void:
	call_deferred("_test")
func _test() -> void:
	var world = load("res://main.tscn").instantiate()
	root.add_child(world)
	await process_frame
	world.raining = false
	var distant: Node3D = null
	for object in world.sim_objects:
		if object.kind == "tree" and object.global_position.distance_to(world.player.global_position) > 50.0:
			distant = object
			break
	if distant == null:
		_fail("No distant persistent tree to test")
		return
	distant.water = 0.65
	var start_wetness: float = float(distant.water)
	for i in range(5):
		world.ecology_step(0.5)
	if absf(float(distant.water)-start_wetness) > 0.0001:
		_fail("Far tree ran high-cost tick rather than batching state")
		return
	world.ecology_step(0.5)
	if float(distant.water) >= start_wetness:
		_fail("Far tree failed to advance its full saved three seconds")
		return
	if not world.distant_object_elapsed.has(int(distant.uid)):
		_fail("Per-object simulation clock missing")
		return
	print("PASS: offscreen tree updated from accumulated elapsed time, without freezing history")
	quit(0)
func _fail(why: String) -> void:
	push_error(why)
	quit(1)
