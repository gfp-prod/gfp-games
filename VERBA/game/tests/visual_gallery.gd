extends SceneTree
## Godot-rendered visual QA for VERBA wildlife, without any player installation.
## Runs in GitHub Actions under Xvfb and exports actual frames.
const ANIMAL = preload("res://scripts/creature.gd")
const SPECIES := ["deer", "fox", "wolf", "hare", "crow"]
const OUTFOLDER := "res://visual-reports"

func _initialize() -> void:
	call_deferred("_render_gallery")

func _render_gallery() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTFOLDER))
	var viewport := SubViewport.new()
	viewport.size = Vector2i(960, 640)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	viewport.own_world_3d = true
	root.add_child(viewport)
	var stage := Node3D.new()
	stage.name = "ArtReviewStage"
	viewport.add_child(stage)
	var environment := WorldEnvironment.new()
	var settings := Environment.new()
	settings.background_mode = Environment.BG_COLOR
	settings.background_color = Color(0.21, 0.24, 0.25)
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color(0.78, 0.85, 0.9)
	settings.ambient_light_energy = 0.85
	environment.environment = settings
	stage.add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -32, 0)
	sun.light_energy = 2.0
	sun.shadow_enabled = true
	stage.add_child(sun)
	var ground := MeshInstance3D.new()
	var flat := PlaneMesh.new()
	flat.size = Vector2(20.0, 20.0)
	ground.mesh = flat
	var earth := StandardMaterial3D.new()
	earth.albedo_color = Color(0.33, 0.37, 0.31)
	earth.roughness = 1.0
	ground.material_override = earth
	stage.add_child(ground)
	var player_scale := MeshInstance3D.new()
	var height_mesh := CapsuleMesh.new()
	height_mesh.height = 1.75
	height_mesh.radius = 0.16
	player_scale.mesh = height_mesh
	var reference_material := StandardMaterial3D.new()
	reference_material.albedo_color = Color(0.40, 0.63, 0.78)
	player_scale.material_override = reference_material
	player_scale.position = Vector3(2.4, 0.88, -0.3)
	stage.add_child(player_scale)
	var camera := Camera3D.new()
	camera.current = true
	camera.fov = 50.0
	stage.add_child(camera)
	for species in SPECIES:
		var actor: CharacterBody3D = ANIMAL.new()
		actor.species = species
		actor.rng.seed = 54321
		actor.set_physics_process(false)
		stage.add_child(actor)
		await process_frame
		if not actor.using_library_mesh or actor.animation_player == null:
			push_error("Cannot render wildlife species: " + species)
			quit(1)
			return
		var desired: float = actor._desired_height()
		var multiplier: float = 0.65 if desired < 0.65 else 1.0
		camera.position = Vector3(3.8, 2.6, 6.5) * multiplier
		camera.look_at(Vector3(0, desired * 0.52, 0), Vector3.UP)
		# Baseline under precisely the same lighting and camera prevents enormous
		# broken skins from passing a text-only asset test.
		actor.visible = false
		await process_frame
		await RenderingServer.frame_post_draw
		var baseline: Image = viewport.get_texture().get_image()
		var baseline_path: String = "%s/%s_baseline.png" % [OUTFOLDER, species]
		if baseline.save_png(baseline_path) != OK:
			push_error("Cannot save visual baseline: " + baseline_path)
			quit(4)
			return
		actor.visible = true
		var phases := ["idle", "walk", "run"]
		for phase in phases:
			actor._update_anim(phase)
			if actor.animation_player == null: continue
			actor.animation_player.seek(0.27 if phase != "idle" else 0.12, true)
			# Physically render and fetch real GPU output, rather than asserting scripts.
			await process_frame
			await RenderingServer.frame_post_draw
			var rendered: Image = viewport.get_texture().get_image()
			if rendered == null or rendered.is_empty():
				push_error("No rendered pixels for " + species + " / " + phase)
				quit(2)
				return
			var filename := "%s/%s_%s.png" % [OUTFOLDER, species, phase]
			var code: Error = rendered.save_png(filename)
			if code != OK:
				push_error("Could not write screenshot: " + filename)
				quit(3)
				return
			print("VERBA_VISUAL_QA_SAVED ", filename, " ", rendered.get_width(), "x", rendered.get_height())
		actor.queue_free()
		await process_frame
	# Candidate rabbit is rendered without changing the game's live creature loader.
	var candidate_path := "res://assets/models/cc0/wildlife/ForestRabbit.glb"
	if ResourceLoader.exists(candidate_path):
		var new_rabbit: Node3D = load(candidate_path).instantiate()
		new_rabbit.name = "CandidateRabbit"
		stage.add_child(new_rabbit)
		new_rabbit.scale = Vector3.ONE * 1.24
		camera.position = Vector3(2.5, 1.7, 4.2)
		camera.look_at(Vector3(0.0,0.25,0),Vector3.UP)
		await process_frame
		await RenderingServer.frame_post_draw
		var candidate_image: Image = viewport.get_texture().get_image()
		var candidate_result := candidate_image.save_png(OUTFOLDER + "/candidate_rabbit.png")
		if candidate_result != OK:
			push_error("Rabbit candidate not rendered")
			quit(5)
			return
		print("VERBA_VISUAL_QA_SAVED candidate rabbit ",candidate_image.get_width(),"x",candidate_image.get_height())
		new_rabbit.queue_free()
	print("VERBA_VISUAL_QA_COMPLETE")
	quit(0)
