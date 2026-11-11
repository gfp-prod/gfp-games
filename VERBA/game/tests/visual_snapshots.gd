extends SceneTree
## Deterministic visual regression capture. Run with an Xvfb-backed real
## OpenGL display, not --headless (which cannot prove rendered appearance).
func _initialize() -> void:
	call_deferred("_capture")

func _fail(message: String) -> void:
	push_error("VERBA visual QA: " + message)
	quit(1)

func _capture() -> void:
	root.size=Vector2i(1280,720)
	var world=load("res://main.tscn").instantiate()
	root.add_child(world)
	await process_frame
	var camera=Camera3D.new()
	camera.name="QAFixedPerspective"
	camera.fov=70.0
	world.add_child(camera)
	camera.current=true
	var directory: String = ProjectSettings.globalize_path("res://tests/screenshots")
	if DirAccess.make_dir_recursive_absolute(directory)!=OK:
		_fail("Cannot make screenshot artifact directory")
		return
	# Same ground-height function as real playable camera; fixed yaw/focal length.
	var views: Array[Dictionary] = [
		{"name":"spawn_meadow","eye":Vector2(0,26),"look":Vector2(8,14)},
		{"name":"cottage_facade","eye":Vector2(34,18),"look":Vector2(29,8)},
		{"name":"village_market","eye":Vector2(4,24),"look":Vector2(12,15)},
		{"name":"north_road_bridge","eye":Vector2(-7.5,30.0),"look":Vector2(-19,38)},
		{"name":"gas_station","eye":Vector2(-17,37),"look":Vector2(-27,44)},
		{"name":"castle_gate","eye":Vector2(-32,45),"look":Vector2(-49,44)},
		{"name":"station_shop","eye":Vector2(-24.8,44),"look":Vector2(-31.0,44)},
		{"name":"castle_archive","eye":Vector2(-47,44),"look":Vector2(-51.6,44)}
	]
	for view in views:
		var eye: Vector2=view["eye"]
		var look: Vector2=view["look"]
		camera.global_position=Vector3(eye.x,world.height_at(eye.x,eye.y)+1.67,eye.y)
		camera.look_at(Vector3(look.x,world.height_at(look.x,look.y)+1.3,look.y),Vector3.UP)
		# Allow vegetation, environment textures, render buffers and draw list
		# to catch up; never capture the initial loading frame.
		for i in range(5): await process_frame
		# Capture explicitly; awaiting frame_post_draw under a virtual display
		# can deadlock when the rendering loop is throttled.
		RenderingServer.force_draw()
		var image: Image=root.get_texture().get_image()
		if image==null or image.get_width()<640 or image.get_height()<360:
			_fail("Missing real viewport rendering: "+String(view["name"]))
			return
		var unique: Dictionary={}
		for gy in range(10):
			for gx in range(16):
				var x: int=int(float(gx+1)*float(image.get_width())/17.0)
				var y: int=int(float(gy+1)*float(image.get_height())/11.0)
				unique[image.get_pixel(x,y).to_html()] = true
		if unique.size()<15:
			_fail("Rendered view lacks detail (possibly black frame): "+String(view["name"]))
			return
		var path: String=directory+"/"+String(view["name"])+".png"
		if image.save_png(path)!=OK:
			_fail("Cannot save "+path)
			return
	print("PASS: eight fixed-view 1280x720 screenshots captured with nontrivial rendered content")
	quit(0)
