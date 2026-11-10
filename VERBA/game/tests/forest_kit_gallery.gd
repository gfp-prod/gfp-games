extends SceneTree
## Preview *real* CC0 KayKit forest meshes in Godot before allowing them
## to replace VERBA's ugly primitive grass, bushes and boulders.
const FOREST = "res://assets/models/cc0/forest/ForestNatureKit.glb"
const OUT = "res://visual-reports"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	if not ResourceLoader.exists(FOREST):
		push_error("Forest kit is not bundled")
		quit(1)
		return
	var source: Node3D = load(FOREST).instantiate()
	root.add_child(source)
	var view := SubViewport.new()
	view.size = Vector2i(850,620)
	view.own_world_3d = true
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(view)
	var stage := Node3D.new()
	view.add_child(stage)
	var environment := WorldEnvironment.new()
	var sky := Environment.new()
	sky.background_mode = Environment.BG_COLOR
	sky.background_color = Color("737f7e")
	sky.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	sky.ambient_light_color = Color("bdc4b9")
	sky.ambient_light_energy = .8
	environment.environment = sky
	stage.add_child(environment)
	var sunlight := DirectionalLight3D.new()
	sunlight.rotation_degrees = Vector3(-43,28,-7)
	sunlight.light_energy=1.15
	sunlight.shadow_enabled = true
	stage.add_child(sunlight)
	var floor := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(20,20)
	floor.mesh = plane
	var floor_mat := StandardMaterial3D.new()
	floor_mat.albedo_color = Color("566b5a")
	floor.material_override = floor_mat
	stage.add_child(floor)
	var camera := Camera3D.new()
	camera.current = true
	camera.fov = 54.0
	stage.add_child(camera)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var cases: Dictionary = {
		"Bush_1_E_Color1":.92,"Bush_3_B_Color1":.85,
		"Grass_2_D_Color1":.48,"Rock_1_D_Color1":.62,
		"Rock_2_C_Color1":.81,"Rock_3_E_Color1":.95,
		"Tree_1_A_Color1":6.3
	}
	for name in cases.keys():
		var part: MeshInstance3D = source.find_child(String(name),true,false) as MeshInstance3D
		if part == null or part.mesh == null:
			push_error("No CC0 source mesh: " + String(name))
			quit(2)
			return
		var copy := MeshInstance3D.new()
		copy.name = "Verified_" + String(name)
		copy.mesh = part.mesh
		stage.add_child(copy)
		var bounds: AABB = copy.mesh.get_aabb()
		if bounds.size.y <= .0001:
			push_error("Invalid mesh bounds for " + name)
			quit(3)
			return
		var height: float = float(cases[name])
		var scale_factor: float = height / bounds.size.y
		copy.scale = Vector3.ONE * scale_factor
		copy.position.y = -bounds.position.y*scale_factor + .03
		var distance: float = 4.8 if height < 2 else 17.0
		camera.position = Vector3(distance*.43,height*.66+1.1,distance)
		camera.look_at(Vector3(0,height*.48,0),Vector3.UP)
		await process_frame
		await RenderingServer.frame_post_draw
		var screenshot: Image = view.get_texture().get_image()
		var filename: String = OUT + "/forestkit_" + String(name) + ".png"
		if screenshot.is_empty() or screenshot.save_png(filename) != OK:
			push_error("Could not render forest kit: "+String(name))
			quit(4)
			return
		print("VERBA_FOREST_KIT_RENDER ",filename," height=",height)
		copy.queue_free()
		await process_frame
	print("VERBA_FOREST_KIT_PREVIEW_COMPLETE")
	quit(0)
