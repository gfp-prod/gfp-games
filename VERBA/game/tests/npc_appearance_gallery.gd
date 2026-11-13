extends SceneTree
## Real Godot character lineup screenshots: front-lit, full body and facial closeups.
const ACTOR=preload("res://scripts/npc_actor.gd")
class GalleryWorld:
	extends Node3D
	var player: Node3D = null
	var village_sim: Node = null
	func height_at(_x: float,_z: float) -> float:
		return 0.0
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	var stage:=GalleryWorld.new()
	root.add_child(stage)
	var environment:=WorldEnvironment.new()
	environment.environment=Environment.new()
	environment.environment.background_mode=Environment.BG_COLOR
	environment.environment.background_color=Color("303637")
	environment.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color=Color("a5adb2")
	environment.environment.ambient_light_energy=.88
	stage.add_child(environment)
	var key:=DirectionalLight3D.new()
	key.rotation_degrees=Vector3(-38,25,-14)
	key.light_energy=1.85
	key.light_color=Color("f2dfc5")
	stage.add_child(key)
	var fill:=OmniLight3D.new()
	fill.position=Vector3(-3.0,3.5,-3.0)
	fill.light_energy=1.0
	fill.omni_range=14.0
	fill.light_color=Color("bfcad7")
	stage.add_child(fill)
	var floor:=MeshInstance3D.new()
	var plane:=PlaneMesh.new()
	plane.size=Vector2(35,20)
	floor.mesh=plane
	var clay:=StandardMaterial3D.new()
	clay.albedo_color=Color("615c51")
	clay.roughness=1.0
	floor.material_override=clay
	stage.add_child(floor)
	var cam:=Camera3D.new()
	cam.current=true
	cam.fov=48
	stage.add_child(cam)
	var entries:Array=JSON.parse_string(FileAccess.get_file_as_string("res://data/npcs.json"))
	var definitions:Dictionary={}
	for entry in entries:
		definitions[String(entry["id"])]=entry
	var renders:Array=[
		{"name":"npc_women_fullbody","ids":["ida","lena","nima","mara","sela","juno"],"distance":-8.3,"level":1.23},
		{"name":"npc_men_fullbody","ids":["orin","titus","tomas","daro","cass","brin"],"distance":-8.3,"level":1.23},
		{"name":"npc_faces_women","ids":["lena","nima","sela"],"distance":-3.7,"level":1.75},
		{"name":"npc_faces_men","ids":["titus","orin","tomas"],"distance":-3.7,"level":1.75}
	]
	var dir:="res://visual-reports"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	for shot in renders:
		for child in stage.get_children():
			if child is CharacterBody3D:
				child.queue_free()
		await process_frame
		var ids: Array=shot["ids"]
		var width:=1.22 if ids.size()==6 else .76
		for i in range(ids.size()):
			var person=ACTOR.new()
			person.setup(stage,definitions[String(ids[i])])
			stage.add_child(person)
			person.set_process(false)
			person.set_physics_process(false)
			person.position=Vector3((float(i)-(float(ids.size())-1.0)*.5)*width,.015,0)
			person.rotation.y=0
			if person.name_label!=null:
				person.name_label.visible=ids.size()==6
		cam.position=Vector3(0,float(shot["level"])+.42,float(shot["distance"]))
		cam.look_at(Vector3(0,float(shot["level"]),0),Vector3.UP)
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
		var screenshot:Image=root.get_texture().get_image()
		if screenshot.is_empty():
			push_error("NPC visual gallery produced empty frame: "+String(shot["name"]))
			quit(2)
			return
		var destination:String=dir+"/"+String(shot["name"])+".png"
		if screenshot.save_png(destination)!=OK:
			push_error("NPC visual gallery PNG write failed: "+destination)
			quit(3)
			return
		print("VERBA_NPC_APPEARANCE_SCREENSHOT ",destination)
	print("PASS: four actual Godot NPC anatomy and face screenshots")
	quit(0)
