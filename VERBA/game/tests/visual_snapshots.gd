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
		{"name":"village_farm","eye":Vector2(9,32),"look":Vector2(17,26)},
		{"name":"village_bakery","eye":Vector2(12,11.5),"look":Vector2(8.9,16.2)},
		{"name":"village_forge","eye":Vector2(17.5,13.5),"look":Vector2(21.7,18.7)},
		{"name":"north_road_bridge","eye":Vector2(-7.5,30.0),"look":Vector2(-19,38)},
		{"name":"gas_station","eye":Vector2(-20.2,35.6),"look":Vector2(-33,44)},
		{"name":"castle_gate","eye":Vector2(-32,33),"look":Vector2(-49,44)},
		{"name":"station_shop","eye":Vector2(-30.8,44),"look":Vector2(-36.4,44)},
		{"name":"castle_archive","eye":Vector2(-47,44),"look":Vector2(-51.6,44)},
		{"name":"enchanted_farm","eye":Vector2(9,32),"look":Vector2(17,26),"enchanted":true},
		{"name":"village_after_dark","eye":Vector2(4,24),"look":Vector2(12,15),"night":true}
	]
	for view in views:
		if bool(view.get("enchanted",false)):
			world.village_sim.bless_field(4)
			world.workplaces.refresh_from_economy(true)
		if bool(view.get("night",false)):
			world.world_calendar.elapsed=220.0
			world.night_visual_blend=world.world_calendar.darkness()
			world._update_day_night_art(world.night_visual_blend)
		var eye: Vector2=view["eye"]
		var look: Vector2=view["look"]
		camera.global_position=Vector3(eye.x,world.height_at(eye.x,eye.y)+1.67,eye.y)
		camera.look_at(Vector3(look.x,world.height_at(look.x,look.y)+1.3,look.y),Vector3.UP)
		# Allow vegetation, environment textures, render buffers and draw list
		# to catch up; never capture the initial loading frame.
		for i in range(2): await process_frame
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
		print("VERBA_VISUAL_CAPTURE: "+String(view["name"]))
	# Take actual perspective captures of the wizard's leather book, not
	# an invented mockup of study UI. The first image must WITHHOLD the
	# answer; the second displays the master's corrective marginalia.
	world.world_calendar.elapsed=90.0
	world.night_visual_blend=0.0
	world._update_day_night_art(0.0)
	world.player.camera.current=true
	world.player.book.toggle()
	if not world.player.book.begin_practice():
		_fail("Cannot open wizard memory exercise for visual QA")
		return
	for i in range(45): await process_frame
	RenderingServer.force_draw()
	var grimoire_frame: Image=root.get_texture().get_image()
	if grimoire_frame==null or grimoire_frame.get_width()<640:
		_fail("Physical book not rendered")
		return
	if grimoire_frame.save_png(directory+"/grimoire_recollection.png")!=OK:
		_fail("Could not save parchment recall view")
		return
	for character in "crescit":
		world.player.book.write_practice_character(character)
	var corrected: Dictionary=world.player.book.submit_practice()
	if not corrected.get("ok",false) or corrected.get("correct",true):
		_fail("Cannot display authentic corrected singular imperative")
		return
	for i in range(8): await process_frame
	RenderingServer.force_draw()
	var correction_frame: Image=root.get_texture().get_image()
	if correction_frame==null or correction_frame.save_png(directory+"/grimoire_correction.png")!=OK:
		_fail("Could not save scholar's correction view")
		return
	# The observation folio must also be inspected in real perspective.
	# Both entries below pass through the same player casting path as play.
	world.player.book.leave_practice()
	var trial_target: Dictionary={"position":world.player.global_position+Vector3(0,0,-3)}
	world.player.cast_latin("crescite arbor",trial_target)
	world.player.cast_latin("lux",trial_target)
	if not world.player.book.begin_journal():
		_fail("Cannot open physical experiment folio for visual QA")
		return
	for i in range(8): await process_frame
	RenderingServer.force_draw()
	var trial_frame: Image=root.get_texture().get_image()
	if trial_frame==null or trial_frame.get_width()<640 or trial_frame.save_png(directory+"/grimoire_experiments.png")!=OK:
		_fail("Could not save wizard field experiment view")
		return
	# Review a first-person, actually rendered Latin NPC exchange. Capturing
	# both the written request and the response catches clipped or invisible UI.
	world.player.book.toggle()
	var mara: Node3D
	for actor in world.npcs:
		if actor.npc_id=="mara":
			mara=actor
			break
	if mara==null:
		_fail("The roadside scribe is missing from the physical scene")
		return
	world.player.position=Vector3(mara.position.x,
		world.height_at(mara.position.x,mara.position.z+2.0)+.22,
		mara.position.z+2.0)
	world.player.camera.current=true
	await physics_frame
	world.player.camera.look_at(mara.global_position+Vector3.UP*1.25,Vector3.UP)
	await physics_frame
	if not world.scholar.collect_book("de_herbis") or not bool(world.scholar.answer("de_herbis",0).get("first_time",false)):
		_fail("Cannot stage learned Latin for an NPC visual inspection")
		return
	if not world.player.begin_conversation(mara):
		_fail("Cannot visually inspect a world-reachable conversation")
		return
	world.player.conversation_listening=true
	world.player.conversation_buffer="Ubi est silva?"
	world.player.refresh_conversation()
	for i in range(8): await process_frame
	RenderingServer.force_draw()
	var written: Image=root.get_texture().get_image()
	if written==null or written.save_png(directory+"/conversation_latin_entry.png")!=OK:
		_fail("Could not save the actually rendered Latin text-entry view")
		return
	var spoken: Dictionary=world.player.submit_conversation_latin()
	if not bool(spoken.get("ok",false)) or not String(world.player.conversation_body.text).contains("Silva est trans rivum"):
		_fail("The renderer could not produce a real Latin NPC reply")
		return
	for i in range(8): await process_frame
	RenderingServer.force_draw()
	var answered: Image=root.get_texture().get_image()
	if answered==null or answered.save_png(directory+"/conversation_latin_reply.png")!=OK:
		_fail("Could not save the actually rendered conversation result")
		return
	# Correctly produced Latin also alters scenery, not just a menu.
	world.player.end_conversation()
	# The fixed-angle QA camera is not the player's active gaze. Relocate
	# the player away from Mara so her live E-interaction prompt does not
	# appear spuriously over the waystone screenshot.
	world.player.position=Vector3(-12.5,world.height_at(-12.5,28.0)+.22,28.0)
	world.forest_waystone.update_from_knowledge()
	if not world.forest_waystone.revealed:
		_fail("Mara's learned direction did not reveal the real forest stone")
		return
	camera.current=true
	var marker: Vector3=world.forest_waystone.global_position
	camera.global_position=marker+Vector3(1.1,1.55,-3.0)
	camera.look_at(marker+Vector3.UP*.85,Vector3.UP)
	for i in range(8): await process_frame
	# The fixed QA camera isn't where the player is aiming. Suppress the
	# unrelated interaction hint; keep the genuine 3D inscription visible.
	world.player.interaction_hint.visible=false
	RenderingServer.force_draw()
	var guided: Image=root.get_texture().get_image()
	if guided==null or guided.save_png(directory+"/latin_waystone_revealed.png")!=OK:
		_fail("Could not capture the physically revealed forest direction")
		return
	# A second genuine first-person conversation: the baker initiates a
	# Latin question about actual carried inventory and consumes it for bread.
	var ida: Node3D
	for actor in world.npcs:
		if actor.npc_id=="ida":
			ida=actor
			break
	if ida==null:
		_fail("The physical baker is missing from the living village")
		return
	world.player.inventory.append("grain")
	world.player.refresh_held_model()
	world.player.position=Vector3(ida.position.x,
		world.height_at(ida.position.x,ida.position.z+2.0)+.22,
		ida.position.z+2.0)
	world.player.camera.current=true
	await physics_frame
	world.player.camera.look_at(ida.global_position+Vector3.UP*1.25,Vector3.UP)
	await physics_frame
	if not world.player.begin_conversation(ida):
		_fail("The baker cannot be approached for her contextual Latin question")
		return
	if not String(world.player.conversation_body.text).contains("Quid fers?"):
		_fail("Ida's inventory-conditioned Latin question is not visible in real dialogue")
		return
	for i in range(2): await process_frame
	if world.player.conversation_footer==null or world.player.conversation_speech_scroll==null:
		_fail("Scrolling speech and pinned Latin input do not exist")
		return
	if world.player.conversation_footer.get_global_rect().end.y>root.size.y-5:
		_fail("Latin writing controls are clipped beyond the bottom of the physical screen")
		return
	if world.player.conversation_speech_scroll.size.y<55:
		_fail("The villager's speech cannot be read in a usable scrolling window")
		return
	world.player.conversation_listening=true
	world.player.conversation_buffer="Frumentum fero"
	world.player.refresh_conversation()
	for i in range(8): await process_frame
	if world.player.conversation_footer.get_global_rect().end.y>root.size.y-5 or not world.player.conversation_footer.text.contains("Frumentum fero"):
		_fail("The typed first-person Latin response is not visibly accessible in the footer")
		return
	RenderingServer.force_draw()
	var baker_question: Image=root.get_texture().get_image()
	if baker_question==null or baker_question.save_png(directory+"/baker_latin_question.png")!=OK:
		_fail("Failed to capture Ida's spoken Latin question and typed response")
		return
	var baker_response: Dictionary=world.player.submit_conversation_latin()
	if not bool(baker_response.get("ok",false)) or not world.player.inventory.has("bread"):
		_fail("The actual Latin answer did not produce a real bakery exchange")
		return
	for i in range(8): await process_frame
	RenderingServer.force_draw()
	var baker_bread: Image=root.get_texture().get_image()
	if baker_bread==null or baker_bread.save_png(directory+"/baker_latin_bread.png")!=OK:
		_fail("Failed to capture real baked-goods response to productive Latin")
		return
	print("PASS: twenty-one actual rendered views including Ida's Latin question, real bread exchange and forest waystone")
	quit(0)
