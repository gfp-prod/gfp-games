extends SceneTree
## In-engine proof: GLB resources import at true human scale, without replacing
## the existing cottage, collision, door, magic, inventory or old saves.
## On a real Xvfb OpenGL viewport, capture matching old/new camera views.
const MODEL = "res://assets/models/foundry/hermit_cottage_v2.glb"

func _initialize() -> void:
	call_deferred("_review")

func _fail(message: String) -> void:
	push_error("Blender asset foundry: "+message)
	quit(1)

func _frame(folder: String,name: String) -> bool:
	RenderingServer.force_draw()
	var img: Image=root.get_texture().get_image()
	if img==null or img.get_size()!=Vector2i(1280,720):
		_fail("Godot did not render a real 720p asset comparison: "+name)
		return false
	if img.save_png(folder+"/"+name+".png")!=OK:
		_fail("Failed to save rendered cottage asset: "+name)
		return false
	print("FOUNDRY_GODOT_FRAME: "+name)
	return true

func _review() -> void:
	root.size=Vector2i(1280,720)
	if not FileAccess.file_exists(MODEL):
		_fail("GLB is missing from actual project assets after the Blender stage")
		return
	var packed: PackedScene=load(MODEL) as PackedScene
	if packed==null:
		_fail("Godot cannot import exported Blender glTF as PackedScene")
		return
	var world=load("res://main.tscn").instantiate()
	root.add_child(world)
	await process_frame
	var cottage: Node3D=world.get_node_or_null("HermitCottage")
	if cottage==null:
		_fail("Live hermit cottage lost during visual development")
		return
	var shell: Node3D=cottage.get_node_or_null("CrookedHermitage")
	if shell==null:
		_fail("Existing live cottage art is missing; cannot compare fairly")
		return
	var door: Node3D=cottage.get_node_or_null("ClosedWoodenDoor")
	if door==null or not door is StaticBody3D:
		_fail("Existing original door collider cannot be removed by asset work")
		return
	var prototype: Node3D=packed.instantiate() as Node3D
	if prototype==null:
		_fail("Imported GLB is not an editable Node3D hierarchy")
		return
	prototype.name="AssetFoundryReviewOnly"
	cottage.add_child(prototype)
	var count: int=0
	var material_count: int=0
	var bounds: AABB
	var first: bool=true
	for child in prototype.get_children():
		if child is MeshInstance3D:
			var mesh: MeshInstance3D=child
			count+=1
			if mesh.mesh==null:
				_fail("Imported geometry lacks its authored mesh")
				return
			var bb: AABB=mesh.mesh.get_aabb()
			var start: Vector3=prototype.to_local(mesh.to_global(bb.position))
			var end: Vector3=prototype.to_local(mesh.to_global(bb.end))
			var ext:=AABB(start,Vector3.ZERO).expand(end)
			bounds=ext if first else bounds.merge(ext)
			first=false
			for surf in range(mesh.mesh.get_surface_count()):
				if mesh.mesh.surface_get_material(surf)!=null:
					material_count+=1
	if count<7 or material_count<7:
		_fail("Blender export lost original geometry or material surfaces")
		return
	if bounds.size.x<5.3 or bounds.size.y<5.0 or bounds.size.z<4.8:
		_fail("Cottage imported at miniature scale or with rotated world axes")
		return
	if prototype.find_children("*","StaticBody3D",true,false).size()!=0:
		_fail("Art-only review model unexpectedly overrides game physics")
		return
	if world.scholar.books.size()<5:
		_fail("Art pipeline unexpectedly modified existing Latin manuscripts")
		return

	var folder:=ProjectSettings.globalize_path("res://tests/foundry_frames")
	if DirAccess.make_dir_recursive_absolute(folder)!=OK:
		_fail("Could not establish screenshot output")
		return
	var camera:=Camera3D.new()
	camera.name="SameLensOriginalVsFoundry"
	camera.fov=70
	world.add_child(camera)
	camera.current=true
	var views: Array[Dictionary]=[
		{"prefix":"01_front","eye":Vector2(34,18)},
		{"prefix":"02_west","eye":Vector2(22,15)}
	]
	for view in views:
		var eye: Vector2=view["eye"]
		camera.global_position=Vector3(eye.x,world.height_at(eye.x,eye.y)+1.72,eye.y)
		camera.look_at(cottage.global_position+Vector3.UP*2.9,Vector3.UP)
		prototype.visible=false
		shell.visible=true
		for i in range(7): await process_frame
		if not _frame(folder,String(view["prefix"])+"_old_cottage"):
			return
		shell.visible=false
		prototype.visible=true
		for i in range(7): await process_frame
		if not _frame(folder,String(view["prefix"])+"_new_blender"):
			return
	shell.visible=true
	prototype.visible=false
	print("PASS: Blender cottage GLB imports with packed surfaces, correct scale, untouched collision and four actual Godot comparison views")
	quit(0)
