extends SceneTree
## Genuine engine screenshots of the *separate* Orin Blender-model pilot.
## No procedural NPC replacement, no screenshots from concept art.
const ADAPTER=preload("res://scripts/orin_authored_head_adapter.gd")
const GENES=preload("res://scripts/npc_genetics.gd")
const MODEL="res://assets/models/authored/orin_head/orin_authored_head.glb"

func _initialize() -> void:
	call_deferred("_run")

func _fail(reason: String) -> void:
	push_error("ORIN_AUTHORED_HEAD_FAIL: "+reason)
	quit(1)

func _run() -> void:
	if DisplayServer.get_name()=="headless":
		_fail("Need 1280x720 actual rendered viewport under Xvfb")
		return
	var packed: PackedScene=load(MODEL) as PackedScene
	if packed==null:
		_fail("Missing Blender-authored head GLB, build the asset first")
		return
	var studio:=Node3D.new()
	studio.name="OrinHeadArtReview_Only"
	root.add_child(studio)
	root.get_window().size=Vector2i(1280,720)
	var subject: Node3D=packed.instantiate() as Node3D
	if subject==null:
		_fail("Blender file imported without a Godot 3D hierarchy")
		return
	studio.add_child(subject)
	if not ADAPTER.verify_authoring(subject):
		_fail("Imported GLB lacks anatomical head or required shape keys")
		return
	if not ADAPTER.apply_genome(subject,GENES.founder("orin")):
		_fail("Existing Orin genome could not drive authored facial morphs")
		return
	var env:=WorldEnvironment.new()
	var scene_env:=Environment.new()
	scene_env.background_mode=Environment.BG_COLOR
	scene_env.background_color=Color("#171a1c")
	scene_env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	scene_env.ambient_light_color=Color("#d9c9b5")
	scene_env.ambient_light_energy=.35
	env.environment=scene_env
	studio.add_child(env)
	var key:=DirectionalLight3D.new()
	key.rotation_degrees=Vector3(-35,-23,0)
	key.light_energy=1.6
	studio.add_child(key)
	var fill:=OmniLight3D.new()
	fill.light_energy=.65
	fill.omni_range=3
	fill.position=Vector3(.4,.45,1.1)
	studio.add_child(fill)
	var cam:=Camera3D.new()
	cam.projection=Camera3D.PROJECTION_ORTHOGONAL
	cam.size=.88
	cam.near=.03
	studio.add_child(cam)
	cam.current=true
	var folder:=ProjectSettings.globalize_path("res://tests/orin_head_frames")
	if DirAccess.make_dir_recursive_absolute(folder)!=OK:
		_fail("Could not make true screenshot directory")
		return
	var shots: Array[Dictionary]=[
		{"name":"01_front_neutral","camera":Vector3(0,.025,1.20),
			"blink":0.0,"mouth":0.0},
		{"name":"02_three_quarter","camera":Vector3(.64,.09,1.07),
			"blink":0.0,"mouth":0.0},
		{"name":"03_profile","camera":Vector3(1.25,.04,0),
			"blink":0.0,"mouth":0.0},
		{"name":"04_eyes_closed","camera":Vector3(0,.025,1.20),
			"blink":1.0,"mouth":0.0},
		{"name":"05_speaking","camera":Vector3(0,.025,1.20),
			"blink":0.0,"mouth":1.0},
		{"name":"06_smiling","camera":Vector3(0,.025,1.20),
			"blink":0.0,"mouth":0.0,"smile":1.0},
		# Check both face orientations: an accidental reversed import
		# should fail review rather than be mislabeled as a front portrait.
		{"name":"07_reverse_hemisphere_diagnostic",
			"camera":Vector3(0,.025,-1.20),
			"blink":0.0,"mouth":0.0}
	]
	for shot in shots:
		if not ADAPTER.apply_expression(subject,float(shot.get("blink",0.0)),
				float(shot.get("mouth",0.0)),float(shot.get("smile",0.0))):
			_fail("Expression morph failed: "+String(shot["name"]))
			return
		cam.global_position=shot["camera"]
		cam.look_at(Vector3.ZERO,Vector3.UP)
		for frame in range(3): await process_frame
		RenderingServer.force_draw()
		var image: Image=root.get_texture().get_image()
		if image==null or image.get_size()!=Vector2i(1280,720):
			_fail("Godot art proof missing actual 1280x720 framebuffer")
			return
		var output:=folder+"/"+String(shot["name"])+".png"
		if image.save_png(output)!=OK:
			_fail("Image could not be saved: "+output)
			return
		print("ORIN_AUTHORED_GAME_FRAME: "+String(shot["name"]))
	print("PASS: imported Orin CC0 anatomical GLB, ten authored morph channels, seven actual Godot art frames")
	quit(0)
