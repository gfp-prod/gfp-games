extends SceneTree
## Real compatibility-rendered in-world portrait and house interior evidence.
## No concept images, synthetic backdrops or detached model-showroom scenes.
func _initialize() -> void: call_deferred("_capture")
func _fail(message: String) -> void:
	push_error("VERBA portrait frame QA: "+message)
	quit(1)

func _capture() -> void:
	if DisplayServer.get_name()=="headless":
		_fail("Portrait captures require an actual OpenGL display")
		return
	var world: Node3D=load("res://main.tscn").instantiate()
	root.add_child(world)
	await process_frame
	root.get_window().size=Vector2i(1280,720)
	var base_path: String=ProjectSettings.globalize_path(
		"res://tests/portrait_screens")
	if DirAccess.make_dir_recursive_absolute(base_path)!=OK:
		_fail("Could not create image review directory")
		return
	var camera:=Camera3D.new()
	camera.name="RealWorldVillagePortraitReviewCamera"
	camera.fov=57.0
	camera.near=.04
	world.add_child(camera)
	camera.current=true
	var seen: int=0
	for spec in [
		{"id":"ida","name":"01_baker_figure","distance":2.8,"focus":1.36},
		{"id":"ida","name":"02_baker_face","distance":1.5,"focus":1.74},
		{"id":"orin","name":"03_blacksmith_face","distance":1.55,"focus":1.74},
		{"id":"mara","name":"04_scribe_face","distance":1.60,"focus":1.74},
		{"id":"sela","name":"05_merchant_face","distance":1.60,"focus":1.74},
		{"id":"daro","name":"06_farmer_figure","distance":2.85,"focus":1.35}
	]:
		var actor: Node3D=null
		for citizen in world.npcs:
			if String(citizen.npc_id)==String(spec["id"]):
				actor=citizen as Node3D
				break
		if actor==null:
			_fail("Missing real citizen: "+String(spec["id"]))
			return
		# Freeze only the photo subject; actual game work and navigation
		# remain unchanged. Capture from its current genuine world position.
		actor.set_physics_process(false)
		# The scribe stands beside a massive solid landmark. The initial
		# frontal inspection camera ended up INSIDE that geometry and only
		# photographed its black wall. Shift to a documented side approach.
		var eye_local:=Vector3(0,1.53,-float(spec["distance"]))
		if String(spec["id"])=="mara":
			eye_local=Vector3(-float(spec["distance"])*.76,1.53,
				-float(spec["distance"])*.78)
		var eye: Vector3=actor.to_global(eye_local)
		var target: Vector3=actor.to_global(Vector3(0,float(spec["focus"]),0))
		camera.global_position=eye
		camera.look_at(target,Vector3.UP)
		for tick in range(3): await process_frame
		RenderingServer.force_draw()
		var img: Image=root.get_texture().get_image()
		if img==null or img.get_size()!=Vector2i(1280,720):
			_fail("Renderer did not provide a 1280x720 frame")
			return
		if img.save_png(base_path+"/"+String(spec["name"])+".png")!=OK:
			_fail("Failed saving first-person portrait")
			return
		print("PORTRAIT_REAL_FRAME: "+String(spec["name"]))
		seen+=1
	for shot in [
		{"house":"StonecutterHouse","name":"07_stonecutter_interior"},
		{"house":"MillwardHouse","name":"08_millward_interior"}
	]:
		var house: Node3D=world.get_node_or_null(
			"PhysicalVillageHomesteads/"+String(shot["house"])) as Node3D
		if house==null:
			_fail("Missing physically enterable house: "+String(shot["house"]))
			return
		camera.global_position=house.to_global(Vector3(.25,1.65,-1.65))
		camera.look_at(house.to_global(Vector3(-.25,1.34,1.70)),Vector3.UP)
		for tick in range(3): await process_frame
		RenderingServer.force_draw()
		var img: Image=root.get_texture().get_image()
		if img==null or img.get_size()!=Vector2i(1280,720):
			_fail("House interior capture failed")
			return
		if img.save_png(base_path+"/"+String(shot["name"])+".png")!=OK:
			_fail("Could not save interior evidence")
			return
		print("PORTRAIT_REAL_FRAME: "+String(shot["name"]))
		seen+=1
	if seen!=8:
		_fail("Did not capture all eight real game views")
		return
	print("PASS: eight actual Godot portrait and interior frames captured")
	quit(0)
