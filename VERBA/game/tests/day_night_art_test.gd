extends SceneTree
## Night is a real visible sky/fog/ambient state, not merely a dim sun.
func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var w: Node3D = load("res://main.tscn").instantiate()
	root.add_child(w)
	await process_frame
	var env: Environment = w.ambient.environment
	var s: ProceduralSkyMaterial = env.sky.sky_material as ProceduralSkyMaterial
	if s == null:
		_fail("No actual sky material")
		return
	var day_color: Color = s.sky_top_color
	var day_fog: float = env.fog_density
	w.night_remaining = 20.0
	w._process(2.0)
	if w.night_visual_blend < .99:
		_fail("Night visual blend didn't reach moonlight")
		return
	if s.sky_top_color.b >= day_color.b*.75 or env.fog_density <= day_fog:
		_fail("Night spell left a bright daytime sky or daytime fog")
		return
	if w.light_node.light_energy >= .5:
		_fail("Sun was still strong during moonlit state")
		return
	w.night_remaining = 0.0
	w._process(2.0)
	if w.night_visual_blend > .01 or s.sky_top_color.distance_to(day_color) > .01:
		_fail("Returning sunlight didn't restore warm daytime atmosphere")
		return
	print("PASS: physically rendered sky, fog, moonlight and day restoration respond to night state")
	quit(0)

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
