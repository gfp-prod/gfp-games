extends SceneTree
## End-to-end acceptance of real pinned-license CC0 models in Godot.
## Compared images are captured from one fixed camera, world and daylight.
const COUNT_BASE: int=11
const CAMERA_SITES: Array[Dictionary]=[
	{"id":"01_market_props","eye":Vector2(-1.5,20.0),"look":Vector2(2.9,23.8)},
	{"id":"02_station_service_yard","eye":Vector2(-113.2,90.0),"look":Vector2(-105.7,84.0)},
	{"id":"03_millward_yard","eye":Vector2(37.4,27.6),"look":Vector2(34.4,34.2)},
	{"id":"04_stonecutter_home","eye":Vector2(-13.1,28.2),"look":Vector2(-9.8,34.3)}
]
func _initialize() -> void:
	call_deferred("_run")
func _fail(why: String) -> void:
	printerr("CC0 LIVE IMPORT FAIL: "+why)
	quit(1)

func _shot(path: String) -> bool:
	RenderingServer.force_draw()
	var img: Image=root.get_texture().get_image()
	if img==null or img.get_size()!=Vector2i(1280,720):
		_fail("No 1280x720 in-engine camera evidence for "+path)
		return false
	if img.save_png(path)!=OK:
		_fail("Could not save actual game screenshot "+path)
		return false
	print("VERBA_CC0_RENDER "+path.get_file())
	return true

func _run() -> void:
	root.size=Vector2i(1280,720)
	var families=["retro-fantasy","retro-urban","furniture"]
	var needed={
		"retro-fantasy":["barrels","column-damaged","detail-crate-ropes",
			"detail-crate","ladder","stairs-stone"],
		"retro-urban":["detail-barrier-strong-damaged","detail-bricks-type-a",
			"detail-cables-type-a","detail-dumpster-closed","pallet"],
		"furniture":["bedSingle","bookcaseOpen","books","chair","table"]
	}
	for kit in families:
		for file in needed[kit]:
			var path: String="res://assets/models/cc0/kenney/"+kit+"/"+file+".glb"
			if not ResourceLoader.exists(path):
				_fail("Missing reviewed Kenney CC0 GLB "+path)
				return
			var scene: PackedScene=load(path) as PackedScene
			if scene==null:
				_fail("Unimported or invalid GLB "+path)
				return
			var sample: Node3D=scene.instantiate() as Node3D
			if sample==null or sample.find_children("*","MeshInstance3D",true,false).is_empty():
				_fail("CC0 download has no real imported meshes "+path)
				return
			sample.free()
	for key in ["weathered_planks","mossy_cobblestone","damaged_plaster","mossy_rock"]:
		for channel in ["diffuse","normal","rough"]:
			var path: String="res://assets/textures/cc0/polyhaven/"+key+"_"+channel+".png"
			if not ResourceLoader.exists(path):
				_fail("Missing verified official Poly Haven 1K surface: "+path)
				return
			var tex: Texture2D=load(path) as Texture2D
			if tex==null or tex.get_width()<500:
				_fail("Bad published PBR map "+path)
				return
	var world: Node3D=load("res://main.tscn").instantiate() as Node3D
	if world==null:
		_fail("The playable VERBA scene cannot be created")
		return
	root.add_child(world)
	await process_frame
	var pack: Node3D=world.get_node_or_null("LicensedCC0RetroPackArt") as Node3D
	if pack==null:
		_fail("The models are downloaded but not integrated with the world")
		return
	var houses: Node3D=world.get_node_or_null("PhysicalVillageHomesteads") as Node3D
	var with_homes: bool=houses!=null and int(houses.get_meta("authored_homestead_count",0))==2
	var count: int=int(pack.get_meta("installed_count",-1))
	if count!=COUNT_BASE+(4 if with_homes else 0):
		_fail("Only %d real retro models installed, expected %d"%
			[count,COUNT_BASE+(4 if with_homes else 0)])
		return
	if int(pack.get_meta("simulation_entities_created",-1))!=0:
		_fail("Decorative imported props created unauthorized gameplay entities")
		return
	for decoration in pack.get_children():
		if not decoration.has_meta("real_source_model"):
			_fail("Model without source provenance: "+decoration.name)
			return
		if String(decoration.get_meta("cc0_license"))!="CC0-1.0":
			_fail("Unexpected non-CC0 visual source "+decoration.name)
			return
		if decoration.get_node_or_null("LicensedKenneyOriginalMesh")==null:
			_fail("Source model not in live scene "+decoration.name)
			return
	if pack.get_node_or_null("StationWornDumpster/PhysicalImportedRetroProp")==null:
		_fail("Large gas station prop has no physical collider")
		return
	if pack.get_node_or_null("MarketCordedCrate/PhysicalImportedRetroProp")==null:
		_fail("Crate looks solid but has no collision")
		return
	if world.village_sim==null or world.player==null or not world.scholar.books.has("de_herbis"):
		_fail("Source art disabled the learning/economy systems")
		return
	var village: Node3D=world.get_node_or_null("VillageWorkingDistrict") as Node3D
	if village==null:
		_fail("Original inhabited and active work district lost")
		return
	var ground_paving: MultiMeshInstance3D=village.get_node_or_null(
		"ArtDirectedVillageApproaches/StaggeredSettledVillagePathStones") as MultiMeshInstance3D
	if ground_paving==null:
		_fail("Poly Haven cobblestone ground material never reached the village")
		return
	if not (ground_paving.material_override is StandardMaterial3D):
		_fail("Photo-material cobblestone shader is missing")
		return
	var paving: StandardMaterial3D=ground_paving.material_override
	if paving.normal_texture==null or paving.roughness_texture==null:
		_fail("New PBR texture maps were downloaded but never used")
		return

	var folder: String=ProjectSettings.globalize_path("res://tests/cc0_pack_frames")
	if DirAccess.make_dir_recursive_absolute(folder)!=OK:
		_fail("Cannot create source-licensed visual review directory")
		return
	var camera:=Camera3D.new()
	camera.fov=70.0
	camera.name="MatchedOriginalAndLicensedCC0WorldLens"
	world.add_child(camera)
	camera.current=true
	var images: int=0
	for site in CAMERA_SITES:
		var eye: Vector2=site["eye"]
		var target: Vector2=site["look"]
		camera.global_position=Vector3(eye.x,world.height_at(eye.x,eye.y)+1.7,eye.y)
		camera.look_at(Vector3(target.x,world.height_at(target.x,target.y)+1.10,
			target.y),Vector3.UP)
		for enabled in [false,true]:
			pack.visible=bool(enabled)
			for i in range(2):await process_frame
			var name: String=String(site["id"])+("_new" if enabled else "_before")+".png"
			if not _shot(folder+"/"+name):
				return
			images+=1
	pack.visible=true
	if images!=8:
		_fail("Must have eight actual-world before-and-after CC0 comparison frames")
		return
	print("PASS: source-pinned free Kenney GLBs and official Poly Haven PBR textures active in Godot; %d props, 4 matched live scenes"%count)
	quit(0)
