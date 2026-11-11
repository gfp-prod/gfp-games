extends SceneTree
## Actual player-eye-view screenshots of the FULL game, rendered in Godot/OpenGL.
## User does not need to open the editor to find world-scale mistakes.
func _initialize() -> void:
	call_deferred("_capture_world")

func _capture_world() -> void:
	var game: Node3D = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	await process_frame
	var player: Node3D = game.get("player") as Node3D
	var camera: Camera3D = player.get("camera") as Camera3D if player != null else null
	if player == null or camera == null:
		push_error("Main game failed to create player or camera")
		quit(1)
		return
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	camera.current = true
	var output := "res://visual-reports"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	for angle in [0.0, PI*0.50, PI, PI*1.50]:
		player.rotation.y = angle
		await process_frame
		await RenderingServer.frame_post_draw
		var shot: Image = root.get_texture().get_image()
		if shot.is_empty():
			push_error("Failed to capture first-person viewport")
			quit(2)
			return
		var name := "%s/world_spawn_%d.png" % [output, int(round(angle * 180.0 / PI))]
		if shot.save_png(name) != OK:
			push_error("Failed saving world view: " + name)
			quit(3)
			return
		print("VERBA_PLAYER_EYE_RENDER ", name, " ",shot.get_width(),"x",shot.get_height())
	# Distinct authored beauty checkpoints: every art change must be judged
	# from the player's eye at hero landmarks, not only from spawn yaw.
	var keyframes: Array[Dictionary] = [
		{"name":"cottage_front","at":Vector2(25.7,17.0),"look":Vector2(29.0,8.0),"target_y":2.7},
		{"name":"cottage_woodland","at":Vector2(38.0,14.5),"look":Vector2(29.0,8.0),"target_y":2.5},
		{"name":"cottage_rear","at":Vector2(31.0,-0.2),"look":Vector2(29.0,8.0),"target_y":2.7},
		{"name":"cottage_interior","at":Vector2(29.0,8.0),"look":Vector2(27.3,11.1),"target_y":2.0},
		{"name":"cottage_interior_study","at":Vector2(29.0,8.0),"look":Vector2(29.2,5.5),"target_y":1.5},
		{"name":"priory_approach","at":Vector2(3.5,-22.0),"look":Vector2(4.0,-35.0),"target_y":2.6},
		{"name":"creek_bank","at":Vector2(-13.0,9.0),"look":Vector2(-19.0,10.0),"target_y":0.7},
		{"name":"willow_bank","at":Vector2(-11.8,16.5),"look":Vector2(-21.0,7.0),"target_y":3.1}
	]
	player.set_physics_process(false)
	player.set_process(false)
	for keyframe in keyframes:
		var p: Vector2 = keyframe["at"]
		var t: Vector2 = keyframe["look"]
		player.position = Vector3(p.x,game.height_at(p.x,p.y)+1.9,p.y)
		camera.look_at(Vector3(t.x,game.height_at(t.x,t.y)+float(keyframe["target_y"]),t.y),Vector3.UP)
		await process_frame
		await RenderingServer.frame_post_draw
		var composition: Image = root.get_texture().get_image()
		if composition.is_empty():
			push_error("No landmark image for: "+String(keyframe["name"]))
			quit(4)
			return
		var frame_name: String = output + "/world_" + String(keyframe["name"]) + ".png"
		if composition.save_png(frame_name) != OK:
			push_error("Unable to save landmark checkpoint: "+frame_name)
			quit(5)
			return
		print("VERBA_ART_CHECKPOINT ",frame_name)
	# Verify that the SAME location has real tonal identity after dusk,
	# instead of simply dimming a white daytime sky.
	game.night_remaining = 30.0
	game.night_visual_blend = 1.0
	game._update_day_night_art(1.0)
	for case in [
		{"name":"world_moonlight_cottage","at":Vector2(25.7,17.0),"look":Vector2(29.0,8.0)},
		{"name":"world_moonlight_creek","at":Vector2(-13.0,9.0),"look":Vector2(-19.0,10.0)}
	]:
		var p: Vector2 = case["at"]
		var toward: Vector2 = case["look"]
		player.position=Vector3(p.x,game.height_at(p.x,p.y)+1.9,p.y)
		camera.look_at(Vector3(toward.x,game.height_at(toward.x,toward.y)+1.5,toward.y),Vector3.UP)
		await process_frame
		await RenderingServer.frame_post_draw
		var photograph: Image = root.get_texture().get_image()
		if photograph.is_empty():
			push_error("Missing actual moonlight photograph")
			quit(6)
			return
		var destination: String = output+"/"+String(case["name"])+".png"
		if photograph.save_png(destination) != OK:
			push_error("Could not save moonlight composition")
			quit(7)
			return
		print("VERBA_NIGHT_ART_CHECKPOINT ",destination)
	print("VERBA_WORLD_VISUAL_QA_COMPLETE")
	quit(0)
