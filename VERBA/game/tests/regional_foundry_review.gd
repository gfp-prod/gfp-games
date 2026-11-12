extends SceneTree
## End-to-end proof: fourteen Blender GLBs appear in the actual playable world.
## Existing physics/navigation and save-sensitive world coordinates remain intact.
const MODELS: Array[String] = [
	"old_creek_footbridge","old_fishing_jetty","witness_stone_circle",
	"rusting_delivery_wreck","dead_ash_tree",
	"ridge_arch","stone_prayer_shrine","cold_charcoal_kiln","roadside_station","castle_gatehouse",
	"village_bakery","village_forge","village_market_stall",
	"village_hearth_house"
]
const TARGETS: Array[String] = [
	"StrangeRoadDistrict/CastleOfTheSecondRoad",
	"StrangeRoadDistrict/ValeFuelStation",
	"ValleyScenicDetails/OldCreekFootbridge",
	"OuterValeRegionalLandmarks/StillwaterLake/OldFishingJetty",
	"OuterValeRegionalLandmarks/SevenWeatheredWitnessStones",
	"StrangeRoadDistrict/ValeFuelStation/WeatheredForecourtHistory/RustingDeliveryWreck",
	"RidgeArch","StonePrayerShrine","OuterValeRegionalLandmarks/ColdCharcoalKiln"
]
const WORKSHOP_TARGETS: Array[String]=[
	"VillageWorkingDistrict/IdaStoneBakery",
	"VillageWorkingDistrict/OrinBlacksmithForge",
	"VillageWorkingDistrict/VillagePublicMarket"
]


func _initialize() -> void:
	call_deferred("_check")

func _fail(reason: String) -> void:
	printerr("REGIONAL FOUNDRY FAIL: "+reason)
	quit(1)

func _check() -> void:
	root.size=Vector2i(1280,720)
	for id in MODELS:
		var path: String="res://assets/models/foundry/"+id+".glb"
		if not FileAccess.file_exists(path):
			_fail("No exported glTF at "+path)
			return
		var scene: PackedScene=load(path) as PackedScene
		if scene==null:
			_fail("Godot did not import Blender scene: "+id)
			return
		var imported: Node3D=scene.instantiate() as Node3D
		if imported==null:
			_fail("Malformed asset root: "+id)
			return
		# Correct import scale checks need a genuine SceneTree transform.
		# Calling global_transform on an unparented GLB logs hundreds of
		# !is_inside_tree errors and silently returns identity matrices.
		root.add_child(imported)
		imported.visible=false
		var meshes: Array[Node]=imported.find_children("*","MeshInstance3D",true,false)
		if meshes.size()<2:
			_fail("Unfinished authored model: "+id)
			return
		for node in meshes:
			var part: MeshInstance3D=node as MeshInstance3D
			if part.mesh==null or part.mesh.get_surface_count()==0:
				_fail("Missing mesh/surfaces: "+id)
				return
			for surface_index in range(part.mesh.get_surface_count()):
				var material: Material=part.mesh.surface_get_material(surface_index)
				if material==null:
					_fail("Untextured imported surface: "+id)
					return
		# Static PNG reviews cannot catch an axis-flipped model.
		# Verify the *imported* Godot Y-up bounds, not Blender source dimensions.
		var expected: Dictionary={
			"old_creek_footbridge":Vector3(11.8,.84,1.70),
			"old_fishing_jetty":Vector3(7.9,1.95,1.80),
			"witness_stone_circle":Vector3(8.3,1.6,8.3),
			"rusting_delivery_wreck":Vector3(2.4,.98,1.1),
			"dead_ash_tree":Vector3(2.3,5.8,2.0),
			"ridge_arch":Vector3(2.4,3.7,1.1),
			"stone_prayer_shrine":Vector3(1.7,1.65,1.2),
			"cold_charcoal_kiln":Vector3(2.1,1.5,2.1),
			"roadside_station":Vector3(13.0,5.9,8.0),
			"castle_gatehouse":Vector3(14.2,5.8,14.2),
			"village_bakery":Vector3(2.3,2.7,2.2),
			"village_forge":Vector3(2.1,2.9,1.45),
			"village_market_stall":Vector3(2.7,2.7,2.0),
			"village_hearth_house":Vector3(6.0,5.5,6.1)
		}
		var found: bool=false
		var bounds: AABB=AABB()
		var inverse: Transform3D=imported.global_transform.affine_inverse()
		for node in meshes:
			var mesh_node: MeshInstance3D=node as MeshInstance3D
			var mesh_box: AABB=mesh_node.mesh.get_aabb()
			for xi in range(2):
				for yi in range(2):
					for zi in range(2):
						var vertex: Vector3=mesh_box.position+mesh_box.size*Vector3(float(xi),float(yi),float(zi))
						var local: Vector3=inverse*(mesh_node.global_transform*vertex)
						bounds=AABB(local,Vector3.ZERO) if not found else bounds.expand(local)
						found=true
		var minimum: Vector3=expected[id]
		if not found or bounds.size.x<minimum.x or bounds.size.y<minimum.y or bounds.size.z<minimum.z:
			_fail("Model too small, sideways or wrongly aligned: "+id+" Godot bounds "+str(bounds.size))
			return
		if imported.find_children("*","StaticBody3D",true,false).size()>0:
			_fail("A visual-only GLB imported unexpected collision bodies: "+id)
			return
		imported.free()
	var world: Node3D=load("res://main.tscn").instantiate() as Node3D
	root.add_child(world)
	await process_frame
	for target_path in TARGETS:
		var landmark: Node3D=world.get_node_or_null(target_path) as Node3D
		if landmark==null:
			_fail("Lost live landmark: "+target_path)
			return
		if not landmark.has_meta("foundry_model"):
			_fail("The model swap is not active in the actual playable map: "+target_path)
			return
		if landmark.find_children("*","StaticBody3D",true,false).is_empty():
			_fail("Replacing visuals erased the original collision geometry: "+target_path)
			return
	if int(world.get_meta("foundry_replacements",0))!=TARGETS.size():
		_fail("Not all new landmark models installed")
		return
	# Workplaces have distinct finite inventories and active physical goals.
	# The new GLBs are visual surfaces only, on those same named sites.
	var workplace: Node3D=world.get_node_or_null("VillageWorkingDistrict") as Node3D
	if workplace==null or int(workplace.get_meta("foundry_workshop_count",0))!=WORKSHOP_TARGETS.size():
		_fail("The new Blender village workshops were not installed")
		return
	for target_path in WORKSHOP_TARGETS:
		var site: Node3D=world.get_node_or_null(target_path) as Node3D
		if site==null or not site.has_meta("foundry_model"):
			_fail("Village job location lost its authored model: "+target_path)
			return
		if site.get_node_or_null("BlenderAuthored_"+String(site.get_meta("foundry_model")))==null:
			_fail("Village GLB not attached to existing worksite: "+target_path)
			return
		if site.find_child("CarvedWorkplaceSign",true,false)==null and target_path.ends_with("VillagePublicMarket"):
			_fail("Village market lost its visible Latin signage")
			return
	for invariant in [
		{"site":"IdaStoneBakery","light":"BakerCoalLight","glow":"BakerWorkingEmbers","physical":"PhysicalBakeOven"},
		{"site":"OrinBlacksmithForge","light":"SmithCoalLight","glow":"ForgeWorkingCoals","physical":"PhysicalCoalForge"}
	]:
		var site: Node3D=workplace.get_node_or_null(String(invariant["site"])) as Node3D
		if site==null:
			_fail("Lost critical village workshop "+String(invariant["site"]))
			return
		var glow: GeometryInstance3D=site.find_child(String(invariant["glow"]),true,false) as GeometryInstance3D
		if glow==null or not glow.visible:
			_fail("New stonework concealed the working live fire or stock for "+String(invariant["site"]))
			return
		if site.find_child(String(invariant["light"]),true,false)==null:
			_fail("Forge replacement erased firelight for "+String(invariant["site"]))
			return
		if site.find_child(String(invariant["physical"]),true,false)==null:
			_fail("Forge replacement erased the actual interaction collider for "+String(invariant["site"]))
			return
	# New houses are real, enterable physical buildings, not decorative
	# billboards. The world creates them before the AI navigation bake.
	var homes: Node3D=world.get_node_or_null("PhysicalVillageHomesteads") as Node3D
	if homes==null or int(homes.get_meta("authored_homestead_count",0))!=2:
		_fail("Village still has no authored houses beyond the workstations")
		return
	if int(homes.get_meta("new_simulation_entities",-1))!=0:
		_fail("Decorative house pass minted unrelated economic/save identities")
		return
	for house_name in ["StonecutterHouse","MillwardHouse"]:
		var house: Node3D=homes.get_node_or_null(house_name) as Node3D
		if house==null or house.get_node_or_null("BlenderAuthoredVernacularHouse")==null:
			_fail("Actual textured house missing in village: "+house_name)
			return
		if house.find_children("*","StaticBody3D",true,false).size()<8:
			_fail("Vernacular house walls, open entrance or floor are not physically present: "+house_name)
			return
		if house.get_node_or_null("HouseSolidStoneFoundation")==null or house.get_node_or_null("PhysicalOldSlateRoof")==null:
			_fail("Village house doesn't have authentic collidable foundations and roof: "+house_name)
			return
	# The new homesteads must be settled into the ACTUAL physical terrain:
	# photographed earth at the entrance, garden beds, soft edge vegetation,
	# and no second set of world entities or invisible walls.
	var yards: Node3D=homes.get_node_or_null("VillageHomesteadGrounds") as Node3D
	if yards==null or not bool(yards.get_meta("decorative_only",false)):
		_fail("Vernacular houses still float as isolated assets without lived-in grounds")
		return
	if int(yards.get_meta("environmental_stamps",0))<35 or int(yards.get_meta("small_vegetation_count",0))<120:
		_fail("Dooryard approach and kitchen-herb composition is incomplete")
		return
	if int(yards.get_meta("garden_stone_count",0))<100 or int(yards.get_meta("new_simulation_entities",-1))!=0:
		_fail("Dooryard stone edging absent or it minted extra simulation identities")
		return
	if yards.find_children("*","StaticBody3D",true,false).size()>0:
		_fail("Non-interactive garden props now block villagers or player movement")
		return
	for garden_name in ["StonecutterDooryard","MillwardDooryard"]:
		var garden: Node3D=yards.get_node_or_null(garden_name) as Node3D
		if garden==null or int(garden.get_meta("stamped_wear_patches",0))<18:
			_fail("Garden isn't visibly connected to the village access path: "+garden_name)
			return
		var earth: MeshInstance3D=garden.get_node_or_null("WornPhotographicEarthAtDoorsAndBeds") as MeshInstance3D
		var herbs: MultiMeshInstance3D=garden.get_node_or_null("LowKitchenHerbsAndFoundationWeeds") as MultiMeshInstance3D
		var stones: MultiMeshInstance3D=garden.get_node_or_null("IrregularSettledDryStoneGardenEdging") as MultiMeshInstance3D
		if earth==null or earth.mesh==null or herbs==null or herbs.multimesh==null or stones==null or stones.multimesh==null:
			_fail("Real terrain-grounded garden art missing: "+garden_name)
			return
		if herbs.multimesh.instance_count!=64 or stones.multimesh.instance_count!=55:
			_fail("Ground-cover batching count unexpectedly changed: "+garden_name)
			return
		for sample in [0,11,29,48,63]:
			var pose: Transform3D=herbs.multimesh.get_instance_transform(sample)
			var p: Vector3=garden.global_transform*pose.origin
			if absf(p.y-world.height_at(p.x,p.z))>.16:
				_fail("Herb roots float or are buried against the true terrain in "+garden_name)
				return
	var castle: Node3D=world.get_node_or_null("StrangeRoadDistrict/CastleOfTheSecondRoad") as Node3D
	if castle==null or castle.get_node_or_null("CastleOpenGate")==null:
		_fail("Blender castle facade erased the physical open gate")
		return
	if castle.find_child("WalkableNorthRoadBridgeDeck",true,false)!=null:
		_fail("Castle art unexpectedly changed independent road bridge ownership")
		return
	if castle.get_node_or_null("QuietImpossibleLantern")==null:
		_fail("The original castle anomaly was lost with the visual swap")
		return
	var station: Node3D=world.get_node_or_null("StrangeRoadDistrict/ValeFuelStation") as Node3D
	if station==null or station.get_node_or_null("StationOpenEntrance")==null:
		_fail("Replacing station facade destroyed the walkable entrance marker")
		return
	if station.find_child("StationSalesCounter",true,false)==null:
		_fail("Replacing station facade removed the shop collision")
		return
	if station.find_child("WeatheredRoadsideInscription",true,false)==null:
		_fail("Replacing station facade removed the live label")
		return
	if station.find_child("BlenderAuthored_rusting_delivery_wreck",true,false)==null:
		_fail("Station asset replacement obscured the independent truck model")
		return
	var dead: Node3D=world.find_child("DeadTree",true,false) as Node3D
	if dead==null:
		_fail("Original living-world dead tree was removed")
		return
	if dead.get_node_or_null("CC0ImportedArt")==null:
		_fail("New dead ash geometry did not attach to the save-safe tree entity")
		return
	if world.get_node_or_null("HermitCottage/ClosedWoodenDoor")==null:
		_fail("Cottage doorway was altered during regional art swap")
		return
	var folder: String=ProjectSettings.globalize_path("res://tests/regional_frames")
	if DirAccess.make_dir_recursive_absolute(folder)!=OK:
		_fail("Could not make proof-image directory")
		return
	var camera:=Camera3D.new()
	camera.name="ActualWorldRegionalFoundryReviewLens"
	camera.fov=70.0
	world.add_child(camera)
	camera.current=true
	# The full visual atlas is captured by outer_vale_gallery.gd.
	# The Foundry gate captures THREE decisive in-engine views so exported
	# geometry is actually seen without repeating many minutes of raster work.
	# Every imported model still gets full material, dimension and physics QA.
	var views: Array[Dictionary]=[
		{"name":"02_stillwater_jetty","eye":Vector2(54,-57),"look":Vector2(64,-60)},
		{"name":"09_shop_and_canopy","eye":Vector2(-90,78),"look":Vector2(-102,77)},
		{"name":"10_masonry_castle","eye":Vector2(-33,39),"look":Vector2(-49,44)},
		{"name":"11_village_bakery_market","eye":Vector2(8,9),"look":Vector2(7,17)},
		{"name":"12_village_forge","eye":Vector2(18,12),"look":Vector2(21.8,19.1)},
		{"name":"13_stonecutter_house","eye":Vector2(-10,25.7),"look":Vector2(-7.5,34.0)},
		{"name":"14_millward_house","eye":Vector2(27.3,26),"look":Vector2(30.0,33.5)},
		{"name":"15_stonecutter_dooryard","eye":Vector2(-12.0,29.1),"look":Vector2(-12.4,34.0)},
		{"name":"16_millward_dooryard","eye":Vector2(35.0,28.9),"look":Vector2(35.1,33.7)}
	]
	for shot in views:
		var eye: Vector2=shot["eye"]
		var target: Vector2=shot["look"]
		camera.global_position=Vector3(eye.x,world.height_at(eye.x,eye.y)+1.7,eye.y)
		camera.look_at(Vector3(target.x,world.height_at(target.x,target.y)+1.7,target.y),Vector3.UP)
		for i in range(2):await process_frame
		RenderingServer.force_draw()
		var img: Image=root.get_texture().get_image()
		if img==null or img.get_size()!=Vector2i(1280,720):
			_fail("No rendered screenshot for "+String(shot["name"]))
			return
		if img.save_png(folder+"/"+String(shot["name"])+".png")!=OK:
			_fail("Cannot save proof screenshot: "+String(shot["name"]))
			return
		print("REGIONAL_FOUNDRY_FRAME: "+String(shot["name"]))
	print("PASS: fourteen editable Blender GLBs import, nine landmarks, three workplaces and two physical homes preserve gameplay, and nine actual-world screenshots render")
	quit(0)
