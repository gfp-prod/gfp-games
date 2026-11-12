extends SceneTree
## Real Godot review of Quaternius's genuinely free Standard medieval modules.
## No paid sources, synthetic meshes or re-created screenshots.
const NAMES: Array[String]=[
	"WindowShutters_Wide_Flat_Open",
	"Stairs_Exterior_Straight",
	"Wall_Arch",
	"Prop_Chimney"
]
const ACTIVE: Array[String]=[
	"PhysicalVillageHomesteads/StonecutterHouse/StonecutterWorkingWindowShutters",
	"PhysicalVillageHomesteads/MillwardHouse/MillwardApproachStairs",
	"FreeQuaterniusMedievalArt/VillageOldThresholdArch"
]
const VIEWS: Array[Dictionary]=[
	{"id":"01_medieval_threshold","eye":Vector2(-2.5,19.8),"look":Vector2(-1.8,26.1)},
	{"id":"02_stonecutter_shutters","eye":Vector2(-12.0,26.7),"look":Vector2(-9.37,30.92)},
	{"id":"03_miller_steps","eye":Vector2(29.7,26.0),"look":Vector2(30.0,30.4)}
]
func _initialize() -> void:
	call_deferred("_run")
func _fail(message: String) -> void:
	printerr("FREE MEDIEVAL KIT FAIL: "+message)
	quit(1)

func _run() -> void:
	root.size=Vector2i(1280,720)
	for asset in NAMES:
		var path: String="res://assets/models/cc0/quaternius/medieval-standard/"+asset+".gltf"
		if not ResourceLoader.exists(path):
			_fail("Unimported genuine free glTF "+path)
			return
		var scene: PackedScene=load(path) as PackedScene
		if scene==null or scene.instantiate()==null:
			_fail("Corrupt glTF model: "+asset)
			return
	var world: Node3D=load("res://main.tscn").instantiate() as Node3D
	root.add_child(world)
	await process_frame
	var authored: Node3D=world.get_node_or_null("FreeQuaterniusMedievalArt") as Node3D
	if authored==null or int(authored.get_meta("free_standard_models_installed",0))!=3:
		_fail("Three actual Quaternius models not integrated into houses and village")
		return
	if int(authored.get_meta("new_economy_or_save_objects",-1))!=0:
		_fail("Free architecture created unapproved sim identities")
		return
	for path in ACTIVE:
		var node: Node3D=world.get_node_or_null(path) as Node3D
		if node==null or node.get_node_or_null("OriginalQuaterniusStandardGeometry")==null:
			_fail("House/castle architectural detail did not render: "+path)
			return
		if not bool(node.get_meta("decorative_visual_only",false)):
			_fail("Quaternius modular facade unexpectedly owns gameplay physics")
			return
	# New wall remnants make the free arch a real roadside ruin, not a
	# random rectangle whose legs stop in uninterrupted grass.
	var old_arch: Node3D=world.get_node_or_null(
		"FreeQuaterniusMedievalArt/VillageOldThresholdArch") as Node3D
	var masonry: Node3D=old_arch.get_node_or_null(
		"RuinedMasonryLinkedToOldRoadArch") as Node3D if old_arch!=null else null
	if masonry==null or masonry.get_child_count()<20:
		_fail("Imported free arch still lacks its surveyed boundary-wall history")
		return
	var house: Node3D=world.get_node_or_null("PhysicalVillageHomesteads/StonecutterHouse") as Node3D
	if house==null or house.get_node_or_null("SolidFrontWallPier")==null:
		# There are two actual front pier bodies named the same; the engine
		# resolves one, preserving the physically open passage.
		_fail("Free window shutters replaced the physical house envelope")
		return
	if world.village_sim==null or world.player==null:
		_fail("Free visual kit disabled the running RPG")
		return
	var folder: String=ProjectSettings.globalize_path("res://tests/quaternius_frames")
	if DirAccess.make_dir_recursive_absolute(folder)!=OK:
		_fail("Cannot create review screenshots")
		return
	var lens:=Camera3D.new()
	lens.name="MatchedRealGodotFreeStandardArchitectureCamera"
	lens.fov=70
	world.add_child(lens)
	lens.current=true
	var made: int=0
	for scene in VIEWS:
		var eye: Vector2=scene["eye"]
		var target: Vector2=scene["look"]
		lens.global_position=Vector3(eye.x,world.height_at(eye.x,eye.y)+1.69,eye.y)
		lens.look_at(Vector3(target.x,world.height_at(target.x,target.y)+1.32,target.y))
		for with_art in [false,true]:
			for path in ACTIVE:
				var obj: Node3D=world.get_node_or_null(path) as Node3D
				obj.visible=bool(with_art)
			for i in range(2): await process_frame
			RenderingServer.force_draw()
			var img: Image=root.get_texture().get_image()
			if img==null or img.get_size()!=Vector2i(1280,720):
				_fail("No actual in-game image for "+String(scene["id"]))
				return
			var name: String=folder+"/"+String(scene["id"])+("_new" if with_art else "_before")+".png"
			if img.save_png(name)!=OK:
				_fail("Could not save direct in-game screenshot")
				return
			made+=1
	if made!=6:
		_fail("Not all real-world before/after frames rendered")
		return
	print("PASS: four genuine CC0 Quaternius Standard glTF sources load, three architectural pieces visibly installed and six original/new game images render")
	quit(0)
