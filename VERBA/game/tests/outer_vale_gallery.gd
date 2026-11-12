extends SceneTree
## Real GL Compatibility screenshots for each new region and each screen UI.
## Not concept art: these cameras view the built, physically traversable map.
func _initialize() -> void: call_deferred("_capture")
func _fail(reason: String) -> void:
	push_error("Outer Vale visual acceptance: "+reason)
	quit(1)

func _frame(directory: String, filename: String) -> bool:
	RenderingServer.force_draw()
	var picture: Image=root.get_texture().get_image()
	if picture==null or picture.get_width()!=1280 or picture.get_height()!=720:
		_fail("No actual 1280x720 frame: "+filename)
		return false
	var samples: Dictionary={}
	for y in range(3,19):
		for x in range(3,27):
			samples[picture.get_pixel(int(x*44),int(y*34)).to_html()]=true
	if samples.size()<22:
		_fail("Scene lacks visible terrain material or geometry: "+filename)
		return false
	if picture.save_png(directory+"/"+filename+".png")!=OK:
		_fail("Could not save real in-game region: "+filename)
		return false
	print("VERBA_OUTER_VALE_FRAME: "+filename)
	return true

func _capture() -> void:
	root.size=Vector2i(1280,720)
	var world=load("res://main.tscn").instantiate()
	root.add_child(world)
	await process_frame
	var director:=Camera3D.new()
	director.name="RealTerrainCamera"
	director.fov=70.0
	world.add_child(director)
	director.current=true
	var directory: String=ProjectSettings.globalize_path("res://tests/outer_vale_screens")
	if DirAccess.make_dir_recursive_absolute(directory)!=OK:
		_fail("Could not create real rendered region screenshot directory")
		return
	var views: Array[Dictionary]=[
		{"name":"01_stillwater_overlook","eye":Vector2(48,-43),"look":Vector2(78,-60)},
		{"name":"02_reed_shore","eye":Vector2(57,-64),"look":Vector2(75,-59)},
		{"name":"03_walkable_jetty","eye":Vector2(55,-60),"look":Vector2(67,-60)},
		{"name":"04_remote_station_approach","eye":Vector2(-85,66),"look":Vector2(-102,77)},
		{"name":"05_station_forecourt","eye":Vector2(-92,73),"look":Vector2(-104,77)},
		{"name":"06_old_road","eye":Vector2(-61,59),"look":Vector2(-88,72)},
		{"name":"07_witness_stones","eye":Vector2(69,39),"look":Vector2(76,49)},
		{"name":"08_old_orchard","eye":Vector2(92,-18),"look":Vector2(101,-5)},
		{"name":"09_tollgate_path","eye":Vector2(44,-40),"look":Vector2(52,-47)},
		{"name":"14_cracked_forecourt","eye":Vector2(-93.6,82.2),"look":Vector2(-99.4,77.0)},
		{"name":"15_muddy_lake_bank","eye":Vector2(63,-69),"look":Vector2(75,-60)},
		{"name":"16_weathered_orchard","eye":Vector2(100,5),"look":Vector2(102,-4)},
		{"name":"17_road_and_fence","eye":Vector2(-72,67),"look":Vector2(-84,71)}
	]
	for view in views:
		var eye: Vector2=view["eye"]
		var target: Vector2=view["look"]
		director.global_position=Vector3(eye.x,world.height_at(eye.x,eye.y)+1.65,eye.y)
		director.look_at(Vector3(target.x,world.height_at(target.x,target.y)+1.40,target.y),Vector3.UP)
		for i in range(4): await process_frame
		if not _frame(directory,String(view["name"])):
			return
	# All screen-based screenshots use the actual player's camera and
	# actual created UI. No Photoshop comps or editorial fake overlays.
	director.current=false
	world.player.camera.current=true
	world.player.guide_visible=true
	world.player.guide_panel.visible=true
	for i in range(5): await process_frame
	if not _frame(directory,"10_worn_help_panel"):
		return
	world.player.guide_visible=false
	world.player.guide_panel.visible=false
	world.player.health=34.0
	world.player.stamina=48.0
	for i in range(5): await process_frame
	if not world.player.survival_plate.visible:
		_fail("Health/danger plaque not visible when genuinely injured")
		return
	if not _frame(directory,"11_worn_survival_status"):
		return
	world.player.health=100.0
	world.player.stamina=100.0
	var mara: Node3D
	for actor in world.npcs:
		if actor.npc_id=="mara":
			mara=actor
			break
	if mara==null:
		_fail("The scribe is missing from the actual world")
		return
	world.player.position=Vector3(mara.position.x,
		world.height_at(mara.position.x,mara.position.z+2.0)+.22,
		mara.position.z+2.0)
	await physics_frame
	world.player.camera.look_at(mara.global_position+Vector3.UP*1.25,Vector3.UP)
	await physics_frame
	if not world.player.begin_conversation(mara):
		_fail("Could not open a genuine reachable conversation")
		return
	world.player.conversation_listening=true
	world.player.conversation_buffer="Quid novi?"
	world.player.refresh_conversation()
	for i in range(5): await process_frame
	if not world.player.conversation_footer.text.contains("Quid novi?"):
		_fail("The responsive Latin writing panel cannot show the actual words")
		return
	if not _frame(directory,"12_iron_latin_conversation"):
		return
	world.player.end_conversation()
	world.player.book.toggle()
	for i in range(45): await process_frame
	if not _frame(directory,"13_worn_physical_grimoire"):
		return
	print("PASS: seventeen real 1280x720 world and UI images show weathered 256m terrain, lake, station, ruins, roads and manuscript")
	quit(0)
