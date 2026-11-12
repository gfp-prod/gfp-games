extends RefCounted
## Three tested pieces from Quaternius's genuinely free Medieval Village
## Standard subset. They remain optional unless the individual original glTF
## and companion CC0 textures were imported by the separate build job.
## No source/Pro purchases, runtime network or new simulated characters.
const PACK = preload("res://scripts/cc0_pack_art.gd")
const PREFIX: String="res://assets/models/cc0/quaternius/medieval-standard/"

static func _place(world: Node3D,parent: Node3D,id: String,model_name: String,
		position: Vector3,yaw: float,height: float,tone: Color,
		physical_arch: bool=false) -> bool:
	var path: String=PREFIX+model_name+".gltf"
	if not ResourceLoader.exists(path):
		return false
	var original: PackedScene=load(path) as PackedScene
	if original==null:
		push_error("CC0 Quaternius Standard model not imported: "+path)
		return false
	var holder:=Node3D.new()
	holder.name=id
	holder.position=position
	holder.rotation.y=yaw
	parent.add_child(holder)
	var model: Node3D=original.instantiate() as Node3D
	if model==null:
		holder.queue_free()
		return false
	model.name="OriginalFreeStandardGLTF"
	holder.add_child(model)
	var bounds: AABB=PACK._bounds_relative(model)
	if bounds.size.x<.05 or bounds.size.y<.05:
		holder.queue_free()
		push_warning("Quaternius Standard unsuitable dimensional geometry: "+model_name)
		return false
	var scale: float=clampf(height/bounds.size.y,.1,8.0)
	model.scale=Vector3.ONE*scale
	model.position=Vector3(
		-(bounds.position.x+bounds.size.x*.5)*scale,
		-bounds.position.y*scale,
		-(bounds.position.z+bounds.size.z*.5)*scale)
	PACK._grade(model,tone)
	if physical_arch:
		# Two masonry posts, *no* solid collision sealing the real opening.
		var half_width: float=bounds.size.x*scale*.5
		for sign in [-1.0,1.0]:
			world.add_solid_box(holder,Vector3(
				sign*(half_width-.19),height*.46,0),
				Vector3(.38,height*.85,.37),
				"PhysicalAncientArchPost")
	holder.set_meta("original_artist","Quaternius")
	holder.set_meta("source_pack","Medieval Village MegaKit Standard - free CC0")
	holder.set_meta("source_file",model_name+".gltf")
	holder.set_meta("decorative_only",true)
	return true

static func build(world: Node3D) -> void:
	if world.get_node_or_null("QuaterniusFreeStandardVillageArt")!=null:
		return
	var root:=Node3D.new()
	root.name="QuaterniusFreeStandardVillageArt"
	world.add_child(root)
	var count: int=0
	var homes: Node3D=world.get_node_or_null("PhysicalVillageHomesteads") as Node3D
	if homes!=null:
		var mill: Node3D=homes.get_node_or_null("MillwardHouse") as Node3D
		var cutter: Node3D=homes.get_node_or_null("StonecutterHouse") as Node3D
		if mill!=null and _place(world,mill,"WeatheredMillwardShutters",
				"WindowShutters_Wide_Flat_Open",
				Vector3(1.87,1.84,-3.32),0.0,1.02,
				Color("a1a091")):
			count+=1
		if cutter!=null and _place(world,cutter,"RepairedStonecutterEntrance",
				"Stairs_Exterior_Straight",
				Vector3(0,.01,-3.64),0.0,.28,
				Color("96968a")):
			count+=1
	var pos:=Vector2(-18.0,46.0)
	if _place(world,root,"OldSettlementBoundaryArch","Wall_Arch",
			Vector3(pos.x,world.height_at(pos.x,pos.y),pos.y),.12,2.9,
			Color("7b8379"),true):
		count+=1
	root.set_meta("imported_free_standard_models",count)
	root.set_meta("simulation_entities_created",0)
	root.set_meta("original_source","https://quaternius.com/packs/medievalvillagemegakit.html")
