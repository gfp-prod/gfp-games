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
	if game.player == null or game.player.camera == null:
		push_error("Main game failed to create player or camera")
		quit(1)
		return
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	game.player.camera.current = true
	var output := "res://visual-reports"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	for angle in [0.0, PI*0.50, PI, PI*1.50]:
		game.player.rotation.y = angle
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
	print("VERBA_WORLD_VISUAL_QA_COMPLETE")
	quit(0)
