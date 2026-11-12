extends RefCounted
## Genuine Quaternius CC0 Standard-only medieval modules; no paid source.
## This is architectural trim *on* the existing physical homes and walk,
## not a new puzzle/loot item or another free-floating fake building.
const RETRO=preload("res://scripts/cc0_pack_art.gd")
const SOURCE="res://assets/models/cc0/quaternius/medieval-standard/"
const SPECS: Array[Dictionary]=[
	{"id":"StonecutterWorkingWindowShutters",
	 "file":"WindowShutters_Wide_Flat_Open.gltf",
	 "house":"StonecutterHouse","local":Vector3(-1.87,1.40,-3.26),
	 "height":1.17,"yaw":0.0,"tint":Color("80786e")},
	{"id":"MillwardApproachStairs",
	 "file":"Stairs_Exterior_Straight.gltf",
	 "house":"MillwardHouse","local":Vector3(0,.03,-4.06),
	 "height":.48,"yaw":0.0,"tint":Color("8a8880")},
	{"id":"VillageOldThresholdArch",
	 "file":"Wall_Arch.gltf",
	 "house":"","at":Vector2(-1.8,26.1),
	 "height":3.04,"yaw":-.30,"tint":Color("85847d")}
]

static func build(world: Node3D) -> void:
	if world.get_node_or_null("FreeQuaterniusMedievalArt")!=null:
		return
	var root:=Node3D.new()
	root.name="FreeQuaterniusMedievalArt"
	world.add_child(root)
	var count: int=0
	for spec in SPECS:
		var path: String=SOURCE+String(spec["file"])
		if not ResourceLoader.exists(path):
			continue
		var source: PackedScene=load(path) as PackedScene
		if source==null:
			continue
		var owner: Node3D=root
		var local: Vector3
		if not String(spec["house"]).is_empty():
			owner=world.get_node_or_null(
				"PhysicalVillageHomesteads/"+String(spec["house"])) as Node3D
			if owner==null:
				continue
			local=spec["local"]
		else:
			var at: Vector2=spec["at"]
			local=Vector3(at.x,world.height_at(at.x,at.y),at.y)
		var node:=Node3D.new()
		node.name=String(spec["id"])
		node.position=local
		node.rotation.y=float(spec["yaw"])
		owner.add_child(node)
		var model: Node3D=source.instantiate() as Node3D
		if model==null:
			node.queue_free()
			continue
		model.name="OriginalQuaterniusStandardGeometry"
		node.add_child(model)
		var bounds: AABB=RETRO._bounds_relative(model)
		if bounds.size.y<.02 or maxf(bounds.size.x,bounds.size.z)<.02:
			node.queue_free()
			continue
		var factor: float=clampf(float(spec["height"])/bounds.size.y,.1,8)
		model.scale=Vector3.ONE*factor
		model.position=Vector3(
			-(bounds.position.x+bounds.size.x*.5)*factor,
			-bounds.position.y*factor,
			-(bounds.position.z+bounds.size.z*.5)*factor)
		RETRO._grade(model,spec["tint"])
		node.set_meta("source_license","Quaternius CC0 Standard")
		node.set_meta("source_model",String(spec["file"]))
		node.set_meta("decorative_visual_only",true)
		count+=1
	root.set_meta("free_standard_models_installed",count)
	root.set_meta("new_economy_or_save_objects",0)
