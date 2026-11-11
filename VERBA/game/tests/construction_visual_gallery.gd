extends SceneTree
## The tower must be judged from the real player's eye in the living valley,
## not only by passing unit tests on isolated mesh factories.
func _initialize() -> void:
	call_deferred("_capture")

func _capture() -> void:
	var world = load("res://main.tscn").instantiate()
	root.add_child(world)
	await process_frame
	await process_frame
	var player = world.player
	var tower = world.construction
	player.set_physics_process(false)
	player.set_process(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	player.inventory.clear()
	for item in ["wood","wood","wood","wood","stone"]:
		player.inventory.append(item)
	player.refresh_held_model()
	var site := Vector3.ZERO
	var found := false
	for cx in range(-4,7):
		for cz in range(10,17):
			var point := Vector3(float(cx)*3.0,0.0,float(cz)*3.0)
			player.position = Vector3(point.x,world.height_at(point.x,point.z)+.22,point.z+3.2)
			if bool(tower.inspect("floor",point,0,player.inventory).get("ok",false)):
				site=point
				found=true
				break
		if found: break
	if not found:
		push_error("No safe tower plot can be rendered")
		quit(1)
		return
	for kind in ["floor","wall","shelf"]:
		var result: Dictionary = tower.build(kind,site,0,player)
		if not bool(result.get("ok",false)):
			push_error("Could not assemble a real tower for screenshot: "+String(result.get("message","")))
			quit(2)
			return
	player.position = Vector3(site.x+2.4,world.height_at(site.x+2.4,site.z+8.0)+.25,site.z+8.0)
	player.camera.look_at(Vector3(site.x,world.height_at(site.x,site.z)+1.9,site.z),Vector3.UP)
	await process_frame
	await RenderingServer.frame_post_draw
	var dir := "res://visual-reports"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	var picture: Image = root.get_texture().get_image()
	if picture.is_empty() or picture.save_png(dir+"/tower_first_room.png")!=OK:
		push_error("Could not render authored snap-built tower structure")
		quit(3)
		return
	print("VERBA_CONSTRUCTION_VISUAL ",dir+"/tower_first_room.png")
	# The same real structure under moonlight; silhouettes and collision
	# placements must not disappear at night.
	world.night_remaining = 30.0
	world.night_visual_blend = 1.0
	world._update_day_night_art(1.0)
	await process_frame
	await RenderingServer.frame_post_draw
	var night: Image = root.get_texture().get_image()
	if night.is_empty() or night.save_png(dir+"/tower_moonlight.png")!=OK:
		push_error("Could not render night-time tower construction")
		quit(4)
		return
	print("VERBA_CONSTRUCTION_VISUAL ",dir+"/tower_moonlight.png")
	quit(0)
