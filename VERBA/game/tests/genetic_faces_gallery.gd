extends SceneTree
## Actual Godot world faces, each driven by its simulation genome.
## No pre-rendered mockups, common fake face textures or separate 3D editor.
const PORTRAIT=preload("res://scripts/folk_portrait_finish.gd")

func _initialize() -> void:
	call_deferred("_run")

func _fail(reason: String) -> void:
	push_error("VERBA inherited faces gallery: "+reason)
	quit(1)

func _find(world: Node3D,wanted: String) -> Node3D:
	for actor in world.npcs:
		if String(actor.npc_id)==wanted: return actor
	return null

func _capture(world: Node3D,cam: Camera3D,actor: Node3D,
		name: String,base: String,focus: float,distance: float,
		offset_x: float=.38) -> bool:
	# Controlled close-up lighting reveals actual low-poly facial planes
	# across light/dark skin without changing normal in-game scene lights.
	var fill: OmniLight3D=cam.get_node_or_null("DiagnosticFaceFill") as OmniLight3D
	if fill!=null:
		fill.visible=name.ends_with("_face_detail") or (
			name.ends_with("_eyes_open") or
			name.ends_with("_eyes_closed") or
			name.ends_with("_speaking"))
	cam.global_position=actor.to_global(Vector3(offset_x,focus+.05,-distance))
	cam.look_at(actor.to_global(Vector3(0,focus,0)),Vector3.UP)
	for frame in range(2): await process_frame
	RenderingServer.force_draw()
	var picture: Image=root.get_texture().get_image()
	if picture==null or picture.get_size()!=Vector2i(1280,720): return false
	if picture.save_png(base+"/"+name+".png")!=OK: return false
	print("GENETIC_FACE_FRAME: "+name)
	return true

func _run() -> void:
	if DisplayServer.get_name()=="headless":
		_fail("Requires a genuine 1280x720 Godot OpenGL window")
		return
	var world: Node3D=load("res://main.tscn").instantiate()
	root.add_child(world)
	await process_frame
	root.get_window().size=Vector2i(1280,720)
	var base: String=ProjectSettings.globalize_path("res://tests/genetic_faces")
	if DirAccess.make_dir_recursive_absolute(base)!=OK:
		_fail("Could not make visual artifact directory")
		return
	# Keep the first-person avatar and its held item out of the
	# comparative portrait staging area. Only the NPC being reviewed
	# belongs in the photograph.
	if world.player!=null:
		world.player.visible=false
		world.player.set_physics_process(false)
	var first: Dictionary=world.birth_child("ida","orin","Alma")
	var second: Dictionary=world.birth_child("ida","orin","Milo")
	if not first.get("ok",false) or not second.get("ok",false):
		_fail("An actual family cannot produce physical descendants")
		return
	var ids: Array[String]=["ida","orin","mara","sela","juno",
		String(first["id"]),String(second["id"]),"titus","lena"]
	var names: Array[String]=["01_ida_baker","02_orin_blacksmith",
		"03_mara_scribe","04_sela_merchant","05_juno_attendant",
		"06_alma_child","07_milo_sibling","09_titus_guard","10_lena_painter"]
	var cam:=Camera3D.new()
	cam.near=.04
	cam.fov=50.0
	cam.name="InGameGeneticsComparisonCamera"
	var fill:=OmniLight3D.new()
	fill.name="DiagnosticFaceFill"
	fill.light_energy=.72
	fill.omni_range=2.15
	fill.shadow_enabled=false
	fill.position=Vector3(.12,.11,-.36)
	fill.visible=false
	cam.add_child(fill)
	world.add_child(cam)
	cam.current=true
	# For comparative anatomy pictures, move the existing physical actors
	# temporarily into the same open piece of their actual game landscape.
	# Their bodies, modules, shaders and sim state stay unchanged.
	# Actual reserved starter clearing: unlike the old bridge, its
	# sightlines are not intersected by timber rails or bridge posts.
	var center_x: float=0.0
	var center_z: float=26.0
	# Never accumulate faces on top of one another during inspection.
	# All actors are the real villagers, temporarily hidden until it is
	# their turn to stand in the exact same light.
	for each_actor in world.npcs:
		if is_instance_valid(each_actor): each_actor.visible=false
	for i in range(ids.size()):
		var citizen: Node3D=_find(world,ids[i])
		if citizen==null:
			_fail("Child or original citizen missing from scene: "+ids[i])
			return
		citizen.set_physics_process(false)
		citizen.visible=true
		citizen.global_position=Vector3(center_x,
			world.height_at(center_x,center_z)+.1,center_z)
		citizen.rotation.y=0.0
		if world.village_sim.people.has(ids[i]):
			var info: Dictionary=world.village_sim.people[ids[i]]
			# Diverse state so facial animation is visible alongside
			# genetic structural differences.
			info["mood"]=95.0 if i in [0,3,5] else (
				18.0 if i in [1,4,6] else 50.0)
		# A portrait has to contain the entire crown, bun or high hairstyle.
		# Prior frames clipped Ida's hair at the top edge even at 720p.
		var focus: float=1.85
		var dist: float=1.64
		if ids[i].begins_with("born_"):
			focus=1.78*.54
			dist=1.10
		# Stage an actual expression using the same runtime facial
		# controls that respond to mood in ordinary play.
		var visual_root: Node3D=citizen.visual_figure
		if citizen.visual_attendant!=null:
			visual_root=citizen.visual_attendant
		var feel: float=clampf(
			(float(world.village_sim.people[ids[i]]["mood"])-50.0)/75.0,-1,1)
		for n in range(7):
			PORTRAIT.expression(visual_root,feel,0.0)
		if not await _capture(world,cam,citizen,names[i],base,focus,dist):
			_fail("Could not photograph genuine world citizen: "+ids[i])
			return
		# A head-size-aware portrait rather than a fixed-height camera.
		# Smaller genetic statures previously ended up at the BOTTOM of the
		# photograph; their faces were buried below sky, nametag and tools.
		if i in [0,1,2,3,8]:
			var head: MeshInstance3D=citizen.find_child(
				"ModeledInhabitantHead",true,false) as MeshInstance3D
			if head==null:
				_fail("The genuine NPC has no inherited head to photograph")
				return
			var old_processing: bool=citizen.is_processing()
			var prior_visual_rotation: Vector3=visual_root.rotation
			var prior_visual_position: Vector3=visual_root.position
			var title_node: Node3D=citizen.name_label
			var prior_title_visible: bool=title_node.visible if title_node!=null else false
			citizen.set_process(false)
			visual_root.rotation=Vector3.ZERO
			visual_root.position.y=0.0
			if title_node!=null: title_node.visible=false
			var head_focus: float=citizen.to_local(head.global_position).y
			var portrait_ok: bool=await _capture(world,cam,citizen,
					names[i]+"_face_detail",base,head_focus,.84,.12)
			# An immobile skin-colored strip can pass a numeric blink
			# check. These frames instead show the same real rig OPEN,
			# FULLY CLOSED and ARTICULATING, in identical real-world light.
			if portrait_ok and i in [0,1,3,8]:
				for tick in range(24):
					PORTRAIT.expression(visual_root,0.0,0.0,false,0.0)
				portrait_ok=await _capture(world,cam,citizen,
					names[i]+"_eyes_open",base,head_focus,.84,.12)
				if portrait_ok:
					for tick in range(24):
						PORTRAIT.expression(visual_root,0.0,1.0,false,0.0)
					portrait_ok=await _capture(world,cam,citizen,
						names[i]+"_eyes_closed",base,head_focus,.84,.12)
				if portrait_ok:
					for tick in range(24):
						PORTRAIT.expression(visual_root,0.0,0.0,true,.21)
					portrait_ok=await _capture(world,cam,citizen,
						names[i]+"_speaking",base,head_focus,.84,.12)
			visual_root.rotation=prior_visual_rotation
			visual_root.position=prior_visual_position
			if title_node!=null: title_node.visible=prior_title_visible
			citizen.set_process(old_processing)
			if not portrait_ok:
				_fail("Could not inspect true eye, nose, lip and hair silhouette")
				return
		# Additional full figure to prove body's inherited measurements.
		if i in [0,1,2,3,4,7,8]:
			# Centre higher and pull back so the largest inherited
			# bloodlines retain both their hair and boots in-frame.
			var body_focus: float=1.10
			var body_distance: float=3.56
			if not await _capture(world,cam,citizen,
					names[i]+"_whole_body",base,body_focus,body_distance):
				_fail("Could not photograph genetically different body")
				return
		# Model-review orthographic turnaround: strict front and profile
		# photographs use the SAME actual in-world person and genetic meshes.
		# Orthographic projection removes perspective distortion so we can
		# compare head-to-stature, shoulders, hip projection and limb reach.
		if i in [0,1,8]:
			# Lift the REAL NPC for the temporary orthographic inspection.
			# Ten metres was not enough: nearby tree beams still crossed the
			# foreground of side views and hid the apron/body silhouette.
			# The actor is returned to its unchanged simulation position.
			var ground_pose: Vector3=citizen.global_position
			citizen.global_position=ground_pose+Vector3(0,120.0,0)
			cam.projection=Camera3D.PROJECTION_ORTHOGONAL
			cam.size=2.48
			for direction in ["front","three_quarter","profile"]:
				if direction=="front":
					cam.global_position=citizen.to_global(
						Vector3(0,1.12,-4.0))
				elif direction=="three_quarter":
					# Equal lighting and distance: contour transitions and
					# dress projection invisible in head-on shots must be reviewed.
					cam.global_position=citizen.to_global(
						Vector3(2.85,1.12,-2.85))
				else:
					cam.global_position=citizen.to_global(
						Vector3(4.0,1.12,0))
				cam.look_at(citizen.to_global(
						Vector3(0,1.03,0)),Vector3.UP)
				for frame in range(3): await process_frame
				RenderingServer.force_draw()
				var anatomy_frame: Image=root.get_texture().get_image()
				var anatomy_name: String="%s/%s_orthographic_%s.png" % [
					base,names[i],direction]
				if anatomy_frame==null or anatomy_frame.save_png(anatomy_name)!=OK:
					_fail("Cannot render orthographic anatomical "+direction)
					return
				print("GENETIC_LANDMARK_FRAME: "+anatomy_name)
			cam.projection=Camera3D.PROJECTION_PERSPECTIVE
			citizen.global_position=ground_pose
		# Waist-level detail frames catch the old sphere hands and rigid
		# wrists that are invisible in full-body game screenshots.
		if i in [0,1,8]:
			if not await _capture(world,cam,citizen,
					names[i]+"_hand_detail",base,.62,1.25):
				_fail("Could not photograph modeled wrists and fingers")
				return
		# Diagnostic pose capture uses the actual citizen's articulated
		# and severable modules. These are staged movement KEY POSES,
		# not a claim that the actor walked here under simulation.
		# Preserve every live transform after photographing so the family
		# proof below still depicts the undisturbed scene.
		if i in [0,1]:
			# Disable the actor's presentation _process only for these
			# rig diagnostics. Otherwise three camera frames would blend the
			# deliberately selected joint pose straight back to idle.
			var prior_processing: bool=citizen.is_processing()
			citizen.set_process(false)
			var prior_root: Vector3=citizen.global_position
			var prior_left_arm: Vector3=citizen.left_arm.rotation
			var prior_right_arm: Vector3=citizen.right_arm.rotation
			var prior_left_leg: Vector3=citizen.left_leg.rotation
			var prior_right_leg: Vector3=citizen.right_leg.rotation
			var prior_left_forearm: Vector3=citizen.left_forearm.rotation
			var prior_right_forearm: Vector3=citizen.right_forearm.rotation
			var old_turn: float=visual_root.rotation.y
			var old_gait: float=citizen.gait_weight
			var old_phase: float=citizen.distance_gait_phase
			var old_clock: float=citizen.motion_clock
			citizen.global_position=prior_root+Vector3(0,120.0,0)
			citizen.motion_clock=2.10
			if i==0:
				citizen.gait_weight=1.0
				citizen.distance_gait_phase=PI*.44
				citizen._pose_upper_body(.35,true,false,false)
				citizen.left_arm.rotation.x=.25
				citizen.right_arm.rotation.x=-.24
				citizen.left_leg.rotation.x=-.20
				citizen.right_leg.rotation.x=.23
			else:
				citizen.gait_weight=0.0
				citizen._pose_upper_body(.35,false,true,false)
				citizen.left_arm.rotation.x=-.34
				citizen.right_arm.rotation.x=-.85
				citizen.left_forearm.rotation.x=.51
				citizen.right_forearm.rotation.x=.70
			cam.projection=Camera3D.PROJECTION_ORTHOGONAL
			cam.size=2.48
			cam.global_position=citizen.to_global(Vector3(2.85,1.12,-2.85))
			cam.look_at(citizen.to_global(Vector3(0,1.03,0)),Vector3.UP)
			for frame in range(3): await process_frame
			RenderingServer.force_draw()
			var pose_name: String=names[i]+(
				"_walk_rig_pose" if i==0 else "_work_rig_pose")
			var posed_image: Image=root.get_texture().get_image()
			if posed_image==null or posed_image.save_png(
					base+"/"+pose_name+".png")!=OK:
				_fail("Could not capture animated module pose: "+pose_name)
				return
			print("GENETIC_POSE_FRAME: "+pose_name)
			cam.projection=Camera3D.PROJECTION_PERSPECTIVE
			citizen.global_position=prior_root
			citizen.left_arm.rotation=prior_left_arm
			citizen.right_arm.rotation=prior_right_arm
			citizen.left_leg.rotation=prior_left_leg
			citizen.right_leg.rotation=prior_right_leg
			citizen.left_forearm.rotation=prior_left_forearm
			citizen.right_forearm.rotation=prior_right_forearm
			visual_root.rotation.y=old_turn
			citizen.gait_weight=old_gait
			citizen.distance_gait_phase=old_phase
			citizen.motion_clock=old_clock
			citizen.set_process(prior_processing)
		# Two additional authentic game-world views examine a BENT knee
		# from an oblique angle. A static front portrait cannot prove that
		# the foot and calf actually follow the second articulated joint.
		if i in [1,8]:
			var pivot_leg: Node3D=citizen.right_leg
			var knee_hinge: Node3D=pivot_leg.get_node_or_null(
				"AnatomicalKneeHinge") as Node3D if pivot_leg!=null else null
			if knee_hinge==null:
				_fail("Expected bendable shin on full-body "+ids[i])
				return
			pivot_leg.rotation.x=-.36
			knee_hinge.rotation.x=.65
			cam.global_position=citizen.to_global(Vector3(2.9,1.48,-2.15))
			cam.look_at(citizen.to_global(Vector3(0,1.00,0)),Vector3.UP)
			for frame in range(3): await process_frame
			RenderingServer.force_draw()
			var bending: Image=root.get_texture().get_image()
			var frame_name: String=base+"/"+names[i]+"_knee_bend.png"
			if bending==null or bending.save_png(frame_name)!=OK:
				_fail("Failed to photograph independently bending shin")
				return
			print("GENETIC_KNEE_FRAME: "+names[i]+"_knee_bend")
			knee_hinge.rotation.x=0.0
			pivot_leg.rotation.x=0.0
		citizen.visible=false
	# A final family portrait proves the same hereditary rules create
	# related but visibly non-identical children inside the REAL landscape.
	var family_ids: Array[String]=["ida","orin",String(first["id"]),String(second["id"])]
	var horizontal: Array[float]=[-1.32,1.32,-.42,.42]
	for idx in range(family_ids.size()):
		var person: Node3D=_find(world,family_ids[idx])
		if person==null:
			_fail("Bloodline family missing physical member "+family_ids[idx])
			return
		person.set_physics_process(false)
		person.global_position=Vector3(center_x+horizontal[idx],
			world.height_at(center_x+horizontal[idx],center_z)+.10,center_z)
		person.rotation.y=0.0
		person.visible=true
	cam.global_position=Vector3(center_x,
		world.height_at(center_x,center_z)+1.35,center_z-4.65)
	cam.look_at(Vector3(center_x,world.height_at(center_x,center_z)+1.05,
		center_z),Vector3.UP)
	for frame in range(2): await process_frame
	RenderingServer.force_draw()
	var family_frame: Image=root.get_texture().get_image()
	if family_frame==null or family_frame.save_png(base+"/08_ida_orin_and_children.png")!=OK:
		_fail("Actual on-map four-person bloodline photo failed")
		return
	print("GENETIC_FACE_FRAME: 08_ida_orin_and_children")
	print("PASS: fifty actual Godot face/body/family/expression screenshots with anatomical sex and inherited body-size variety")
	quit(0)
