extends SceneTree
## First-person social UI proof, captured by the real Godot renderer.
## Both portraits are actual physical world residents, not static mockups.
func _initialize() -> void:
	call_deferred("_capture")

func _capture() -> void:
	var world = load("res://main.tscn").instantiate()
	root.add_child(world)
	await process_frame
	await process_frame
	await process_frame
	var player = world.player
	player.set_physics_process(false)
	player.set_process(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var folder := "res://visual-reports"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	for case in [
		{"id":"mara","name":"npc_mara_conversation","offset":Vector2(0.0,2.5),"choice":1},
		{"id":"tomas","name":"npc_tomas_conversation","offset":Vector2(0.0,2.5),"choice":0}
	]:
		var actor: Node3D
		for person in world.npcs:
			if person.npc_id == String(case["id"]):
				actor = person
				break
		if actor == null:
			push_error("Missing NPC scene for art review")
			quit(1)
			return
		var x: float = actor.position.x+float(case["offset"].x)
		var z: float = actor.position.z+float(case["offset"].y)
		player.position = Vector3(x,world.height_at(x,z)+.22,z)
		player.camera.look_at(actor.global_position+Vector3.UP*1.27,Vector3.UP)
		await physics_frame
		if not player.begin_conversation(actor):
			push_error("Social visual camera could not interact with real-world NPC")
			quit(2)
			return
		player.choose_conversation_option(int(case["choice"]))
		await process_frame
		await RenderingServer.frame_post_draw
		var screenshot: Image = root.get_texture().get_image()
		if screenshot.is_empty():
			push_error("No rendered Latin dialogue frame")
			quit(3)
			return
		var path: String = folder+"/"+String(case["name"])+".png"
		if screenshot.save_png(path) != OK:
			push_error("Could not write NPC dialogue art checkpoint")
			quit(4)
			return
		print("VERBA_SOCIAL_VISUAL ",path)
		player.end_conversation()
	print("VERBA_SOCIAL_VISUAL_QA_COMPLETE")
	quit(0)
