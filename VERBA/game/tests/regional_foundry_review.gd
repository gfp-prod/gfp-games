extends SceneTree
## End-to-end proof: five imported Blender GLBs replace live game visuals.
## Existing physics/navigation and save-sensitive world coordinates remain intact.
const MODELS: Array[String] = [
	"old_creek_footbridge","old_fishing_jetty","witness_stone_circle",
	"rusting_delivery_wreck","dead_ash_tree",
	"ridge_arch","stone_prayer_shrine","cold_charcoal_kiln","roadside_station","castle_gatehouse"
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
			"castle_gatehouse":Vector3(14.2,5.8,14.2)
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
		{"name":"10_masonry_castle","eye":Vector2(-33,39),"look":Vector2(-49,44)}
	]
	for shot in views:
		var eye: Vector2=shot["eye"]
		var target: Vector2=shot["look"]
		camera.global_position=Vector3(eye.x,world.height_at(eye.x,eye.y)+1.7,eye.y)
		camera.look_at(Vector3(target.x,world.height_at(target.x,target.y)+1.7,target.y),Vector3.UP)
		for i in range(6):await process_frame
		RenderingServer.force_draw()
		var img: Image=root.get_texture().get_image()
		if img==null or img.get_size()!=Vector2i(1280,720):
			_fail("No rendered screenshot for "+String(shot["name"]))
			return
		if img.save_png(folder+"/"+String(shot["name"])+".png")!=OK:
			_fail("Cannot save proof screenshot: "+String(shot["name"]))
			return
		print("REGIONAL_FOUNDRY_FRAME: "+String(shot["name"]))
	print("PASS: ten editable Blender GLBs import, nine landmark visuals replace live geometry without collision loss, and three actual-world screenshots render")
	quit(0)
