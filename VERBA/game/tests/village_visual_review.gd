extends SceneTree
## Matched-camera visual acceptances for the existing real village.
## The original procedural meshes and newly authored GLBs are swapped
## within one loaded scene, leaving weather, physics, NPCs and light fixed.
const VIEWS: Array[Dictionary]=[
	{"name":"01_bakery","site":"VillageWorkingDistrict/IdaStoneBakery",
	 "asset":"village_bakery","eye":Vector2(11.7,10.9),
	 "look":Vector2(8.9,16.25),"preserve":["BakerWorkingEmbers"]},
	{"name":"02_forge","site":"VillageWorkingDistrict/OrinBlacksmithForge",
	 "asset":"village_forge","eye":Vector2(20.7,12.65),
	 "look":Vector2(21.8,19.1),"preserve":["ForgeWorkingCoals"]},
	{"name":"03_market","site":"VillageWorkingDistrict/VillagePublicMarket",
	 "asset":"village_market_stall","eye":Vector2(4.2,14.5),
	 "look":Vector2(5.3,20.5),"preserve":[]}
]

func _initialize() -> void:
	call_deferred("_review")

func _fail(message: String) -> void:
	printerr("VILLAGE VISUAL FAIL: "+message)
	quit(1)

func _capture(path: String) -> bool:
	RenderingServer.force_draw()
	var picture: Image=root.get_texture().get_image()
	if picture==null or picture.get_size()!=Vector2i(1280,720):
		_fail("No rendered 720p photo of actual village: "+path)
		return false
	if picture.save_png(path)!=OK:
		_fail("Could not write the real village comparison: "+path)
		return false
	print("VILLAGE_MATCHED_CAMERA_FRAME: "+path.get_file())
	return true

func _show_version(site: Node3D,model: Node3D,
		new_model: bool,preserve: Array[String]) -> void:
	for child in site.get_children():
		if child==model: continue
		if child is MeshInstance3D or child is MultiMeshInstance3D:
			if preserve.has(String(child.name)):
				(child as GeometryInstance3D).visible=true
			else:
				(child as GeometryInstance3D).visible=not new_model
	model.visible=new_model

func _review() -> void:
	root.size=Vector2i(1280,720)
	var world: Node3D=load("res://main.tscn").instantiate() as Node3D
	if world==null:
		_fail("Real playable world didn't load")
		return
	root.add_child(world)
	await process_frame
	var folder: String=ProjectSettings.globalize_path("res://tests/village_frames")
	if DirAccess.make_dir_recursive_absolute(folder)!=OK:
		_fail("Cannot create village visual-review output directory")
		return
	var camera:=Camera3D.new()
	camera.name="ExactSameVillageCameraForBeforeAndAfter"
	camera.fov=70.0
	world.add_child(camera)
	camera.current=true
	var made: int=0
	for shot in VIEWS:
		var site: Node3D=world.get_node_or_null(String(shot["site"])) as Node3D
		if site==null or not site.has_meta("foundry_model"):
			_fail("Village worksite is absent or did not get its real GLB: "+String(shot["site"]))
			return
		var model: Node3D=site.get_node_or_null("BlenderAuthored_"+String(shot["asset"])) as Node3D
		if model==null:
			_fail("No authored geometry on live worksite "+String(shot["site"]))
			return
		var protected: Array[String]=[]
		protected.assign(shot["preserve"])
		var eye: Vector2=shot["eye"]
		var look: Vector2=shot["look"]
		camera.global_position=Vector3(eye.x,world.height_at(eye.x,eye.y)+1.65,eye.y)
		camera.look_at(Vector3(look.x,world.height_at(look.x,look.y)+1.15,look.y),Vector3.UP)
		for fresh in [false,true]:
			_show_version(site,model,bool(fresh),protected)
			for i in range(2): await process_frame
			var suffix: String="new" if fresh else "original"
			var name: String=folder+"/"+String(shot["name"])+"_"+suffix+".png"
			if not _capture(name):
				return
			made+=1
		_show_version(site,model,true,protected)
		if site.find_children("*","Label3D",true,false).is_empty() and String(shot["asset"])=="village_market_stall":
			_fail("The market's original Latin sign was erased")
			return
		if String(shot["asset"])!="village_market_stall":
			if site.find_children("*","StaticBody3D",true,false).is_empty():
				_fail("A visual model change erased working collision: "+String(shot["asset"]))
				return
	if made!=6:
		_fail("Six actual-game matched photos were not created")
		return
	print("PASS: three original village workplaces and three new GLBs rendered in exactly matched 1280x720 Godot camera views with intact jobs")
	quit(0)
