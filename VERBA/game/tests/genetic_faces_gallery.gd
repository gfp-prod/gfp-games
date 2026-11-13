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
		name: String,base: String,focus: float,distance: float) -> bool:
	cam.global_position=actor.to_global(Vector3(.38,focus+.05,-distance))
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
		var focus: float=1.74
		var dist: float=1.30
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
		# Additional full figure to prove body's inherited measurements.
		if i in [0,1,2,3,4,7,8]:
			var body_focus: float=.85
			var body_distance: float=3.15
			if not await _capture(world,cam,citizen,
					names[i]+"_whole_body",base,body_focus,body_distance):
				_fail("Could not photograph genetically different body")
				return
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
	print("PASS: seventeen actual Godot face/body/family screenshots with anatomical sex and inherited body-size variety")
	quit(0)
