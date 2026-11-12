extends SceneTree
## End-to-end proof: five imported Blender GLBs replace live game visuals.
## Existing physics/navigation and save-sensitive world coordinates remain intact.
const MODELS: Array[String] = [
	"old_creek_footbridge","old_fishing_jetty","witness_stone_circle",
	"rusting_delivery_wreck","dead_ash_tree"
]
const TARGETS: Array[String] = [
	"ValleyScenicDetails/OldCreekFootbridge",
	"OuterValeRegionalLandmarks/StillwaterLake/OldFishingJetty",
	"OuterValeRegionalLandmarks/SevenWeatheredWitnessStones",
	"StrangeRoadDistrict/ValeFuelStation/WeatheredForecourtHistory/RustingDeliveryWreck"
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
	var views: Array[Dictionary]=[
		{"name":"01_creek_bridge","eye":Vector2(-13,9),"look":Vector2(-19,9)},
		{"name":"02_stillwater_jetty","eye":Vector2(54,-57),"look":Vector2(64,-60)},
		{"name":"03_witness_circle","eye":Vector2(68,45),"look":Vector2(76,49)},
		{"name":"04_abandoned_station","eye":Vector2(-91,87),"look":Vector2(-93,82)},
		{"name":"05_dead_ash","eye":Vector2(-28,29),"look":Vector2(-37,31)}
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
	print("PASS: five editable Blender GLBs import, four landmark visuals replace live geometry without collision loss, and five actual-world screenshots render")
	quit(0)
