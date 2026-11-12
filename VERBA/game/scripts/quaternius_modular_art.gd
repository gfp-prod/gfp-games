extends RefCounted
## Genuine Quaternius CC0 Standard-only medieval modules; no paid source.
## This is architectural trim *on* the existing physical homes and walk,
## not a new puzzle/loot item or another free-floating fake building.
const RETRO=preload("res://scripts/cc0_pack_art.gd")
const ART=preload("res://scripts/art.gd")
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

static func _build_old_threshold(world: Node3D,gate: Node3D) -> void:
	var path: String="res://assets/textures/cc0/polyhaven/mossy_rock_diffuse.png"
	if not ResourceLoader.exists(path):
		path="res://assets/textures/real/stone_diffuse.jpg"
	var masonry: Material=world.textured(path,Color("8c8b82"))
	var midden: Material=world.textured(
		"res://assets/textures/real/moss_diffuse.jpg",Color("576756"))
	var fragments:=Node3D.new()
	fragments.name="RuinedMasonryLinkedToOldRoadArch"
	gate.add_child(fragments)
	for sign in [-1.0,1.0]:
		for index in range(5):
			var relative_x: float=sign*(1.77+float(index)*.57)
			var site: Vector3=gate.to_global(Vector3(relative_x,0,0))
			var soil_offset: float=world.height_at(site.x,site.z)-gate.global_position.y
			var courses: int=2 if index<3 else 1
			for level in range(courses):
				var y: float=soil_offset+.15+float(level)*.29
				ART.stone(fragments,
					Vector3(relative_x+sign*.015*float(level),y,0),
					Vector3(.52,.25,.53),midden if index==2 and level==0 else masonry)
		# Small corner footing: the road's masonry continues into the
		# ground rather than stopping at perfectly cut portal edges.
		for j in range(3):
			var x: float=sign*(2.7+.40*float(j))
			var site: Vector3=gate.to_global(Vector3(x,0,.4))
			var ground: float=world.height_at(site.x,site.z)-gate.global_position.y
			ART.stone(fragments,
				Vector3(x,ground+.09,.4),
				Vector3(.33,.16,.35),midden)
	fragments.set_meta("visual_low_ruin_not_solid_wall",true)

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
		# The old arch is a leftover road boundary, not a free-standing
		# decorative gateway: both sides retain short ruined courses.
		if String(spec["id"])=="VillageOldThresholdArch":
			_build_old_threshold(world,node)
		node.set_meta("source_license","Quaternius CC0 Standard")
		node.set_meta("source_model",String(spec["file"]))
		node.set_meta("decorative_visual_only",true)
		count+=1
	root.set_meta("free_standard_models_installed",count)
	root.set_meta("new_economy_or_save_objects",0)
