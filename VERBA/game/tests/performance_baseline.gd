extends SceneTree
## Repeatable CPU/node-count telemetry, not a fake GPU FPS score.
## GitHub headless VM timings do not represent the user's RTX laptop.
func _initialize() -> void:
	call_deferred("_measure")

func _measure() -> void:
	var start_us: int = Time.get_ticks_usec()
	var game: Node3D = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	await physics_frame
	var load_ms: float = float(Time.get_ticks_usec()-start_us)/1000.0

	var scenes: Array[int] = [0,0,0,0,0]
	var stack: Array[Node] = [game]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		scenes[0] += 1
		if node is MeshInstance3D: scenes[1] += 1
		if node is StaticBody3D: scenes[2] += 1
		if node is OmniLight3D or node is DirectionalLight3D: scenes[3] += 1
		if node is CollisionShape3D: scenes[4] += 1
		for child in node.get_children():
			stack.append(child)

	var timings: Array[float] = []
	for i in range(32):
		var begin_us: int = Time.get_ticks_usec()
		game.ecology_step(.5)
		timings.append(float(Time.get_ticks_usec()-begin_us)/1000.0)
	timings.sort()
	var total: float = 0.0
	for sample in timings:
		total += sample
	var result: Dictionary = {
		"scene_build_ms_headless":snappedf(load_ms,.001),
		"node_count":scenes[0],
		"mesh_instances":scenes[1],
		"static_colliders":scenes[2],
		"lights":scenes[3],
		"collision_shapes":scenes[4],
		"simulated_ecology_objects":game.sim_objects.size(),
		"animals":game.creatures.size(),
		"ecology_0_5s_mean_ms":snappedf(total/float(timings.size()),.001),
		"ecology_0_5s_p95_ms":snappedf(timings[30],.001),
		"ecology_0_5s_max_ms":snappedf(timings[31],.001),
		"runner":"GitHub Actions headless CPU only; NOT player device FPS"
	}
	if scenes[0] < 100 or game.sim_objects.is_empty():
		push_error("No real active world was profiled")
		quit(1)
		return
	print("VERBA_PERFORMANCE_BASELINE ",JSON.stringify(result))
	print("PASS: profiler measured real loaded scene, colliders and repeated ecology ticks")
	quit(0)
