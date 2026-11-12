extends SceneTree
## Four direct 1280x720 Godot render captures: attached limbs, exposed
## wounds, dressed patient and real-resource peg-leg rehabilitation.
func _initialize() -> void: call_deferred("_run")

func _fail(why: String) -> void:
	push_error("VERBA anatomy visual evidence: "+why)
	quit(1)

func _find(world: Node3D, person: String) -> Node3D:
	for citizen in world.npcs:
		if String(citizen.npc_id)==person: return citizen
	return null

func _frame(world: Node3D, lens: Camera3D, actor: Node3D,
		title: String, eye_offset: Vector3, look_height: float) -> bool:
	lens.global_position=actor.to_global(eye_offset)
	lens.look_at(actor.to_global(Vector3(0,look_height,0)),Vector3.UP)
	for i in range(5): await process_frame
	RenderingServer.force_draw()
	var picture: Image=root.get_texture().get_image()
	if picture==null or picture.get_size()!=Vector2i(1280,720): return false
	var destination: String=ProjectSettings.globalize_path(
		"res://tests/anatomy_screens/"+title+".png")
	if picture.save_png(destination)!=OK: return false
	print("REAL_ANATOMY_FRAME: "+title)
	return true

func _run() -> void:
	if DisplayServer.get_name()=="headless":
		_fail("Requires genuine render window")
		return
	var world: Node3D=load("res://main.tscn").instantiate()
	root.add_child(world)
	await process_frame
	root.get_window().size=Vector2i(1280,720)
	var path: String=ProjectSettings.globalize_path("res://tests/anatomy_screens")
	if DirAccess.make_dir_recursive_absolute(path)!=OK:
		_fail("Could not make frame directory")
		return
	var lens:=Camera3D.new()
	lens.fov=62.0
	lens.near=.05
	lens.name="RealAnatomyReviewCamera"
	world.add_child(lens)
	lens.current=true
	var ida: Node3D=_find(world,"ida")
	var daro: Node3D=_find(world,"daro")
	if ida==null or daro==null:
		_fail("Actual village people are missing")
		return
	ida.set_physics_process(false)
	daro.set_physics_process(false)
	if not await _frame(world,lens,ida,"01_attached_baker",
			Vector3(.5,1.5,-3.3),1.12):
		_fail("Could not save intact character frame")
		return
	var injury: Dictionary=ida.strike_limb("left_arm",90.0,"wizard")
	if not injury.get("severed",false):
		_fail("Real injury system did not detach a limb")
		return
	if not await _frame(world,lens,ida,"02_detached_arm_bleeding",
			Vector3(.8,1.5,-3.05),1.20):
		_fail("Could not save severance frame")
		return
	var supplies: Array=["herb"]
	var result: Dictionary=world.village_sim.player_help("ida",supplies)
	ida.refresh_anatomy_visuals()
	if not result.get("ok",false):
		_fail("Dressing from finite herb supply failed")
		return
	if not await _frame(world,lens,ida,"03_baker_treated_wound",
			Vector3(.8,1.5,-3.05),1.20):
		_fail("Could not save bandage frame")
		return
	var lost_leg: Dictionary=daro.strike_limb("right_leg",99.0,"environment")
	if not lost_leg.get("severed",false):
		_fail("Could not disable an individual leg")
		return
	world.village_sim.economy.stocks["herb"]=0
	world.village_sim.observe_wound("daro",["sela"])
	world.village_sim.nearby_care["sela"]=["daro"]
	if not world.village_sim._perform_neighbor_aid("sela","daro"):
		_fail("Spouse could not build the resource-funded peg")
		return
	daro.refresh_anatomy_visuals()
	if not await _frame(world,lens,daro,"04_farmer_with_peg_leg",
			Vector3(-.6,1.43,-3.65),1.0):
		_fail("Could not save prosthetic frame")
		return
	print("PASS: four genuine Godot limb/amputation/treatment/peg game photographs")
	quit(0)
