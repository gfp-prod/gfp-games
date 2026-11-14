extends RefCounted
## OPT-IN ORIN ART PROTOTYPE. Never substitutes the live citizen automatically.
## Existing genotype remains authoritative; this translates established loci
## to authored mesh blend shapes rather than attaching decorative face parts.
const GENES=preload("res://scripts/npc_genetics.gd")

static func _head(scene: Node) -> MeshInstance3D:
	if scene is MeshInstance3D and (
			String(scene.name).contains("Orin_AnatomicalHead")):
		return scene as MeshInstance3D
	for child in scene.get_children():
		var found: MeshInstance3D=_head(child)
		if found!=null: return found
	return null

static func get_head(scene: Node) -> MeshInstance3D:
	return _head(scene)

static func _set(mesh: MeshInstance3D,key: String,weight: float) -> bool:
	if mesh==null or mesh.mesh==null: return false
	var id: int=mesh.find_blend_shape_by_name(StringName(key))
	if id<0: return false
	mesh.set_blend_shape_value(id,clampf(weight,0.0,1.0))
	return true

static func _inheritance_weight(g: Dictionary,locus: String) -> float:
	# Map inherited loci to consistent author-controlled endpoints. This
	# prototype has ONE sculpted adult male face; the rest of the population
	# must not be migrated to it before a larger expression/body study.
	return clampf((GENES.value(g,locus)-.35)/.65,0.0,1.0)

static func apply_genome(scene: Node,g: Dictionary) -> bool:
	var mesh: MeshInstance3D=get_head(scene)
	if mesh==null or not GENES.validate(g): return false
	var pairs: Dictionary={
		"JawWidth":"jaw_width",
		"CheekWidth":"cheek_fullness",
		"NoseWidth":"nose_width",
		"LipVolume":"lip_fullness"
	}
	for shape in pairs.keys():
		if not _set(mesh,String(shape),
				_inheritance_weight(g,String(pairs[shape]))): return false
	return true

static func apply_expression(scene: Node,blink: float=0.0,
		mouth_open: float=0.0,smile: float=0.0,
		frown: float=0.0,brows: float=0.0) -> bool:
	var mesh: MeshInstance3D=get_head(scene)
	if mesh==null: return false
	for shape in ["Blink_L","Blink_R"]:
		if not _set(mesh,shape,blink): return false
	for expr in ["MouthOpen","Smile","Frown","BrowRaise"]:
		var weight: float=0.0
		match expr:
			"MouthOpen": weight=mouth_open
			"Smile": weight=smile
			"Frown": weight=frown
			"BrowRaise": weight=brows
		if not _set(mesh,expr,weight): return false
	return true

static func verify_authoring(scene: Node) -> bool:
	var mesh: MeshInstance3D=get_head(scene)
	if mesh==null or mesh.mesh==null: return false
	for key in ["Blink_L","Blink_R","MouthOpen","Smile","Frown",
			"BrowRaise","JawWidth","CheekWidth","NoseWidth","LipVolume"]:
		if mesh.find_blend_shape_by_name(StringName(key))<0:
			push_error("Authored Orin head missing deformable shape: "+key)
			return false
	if mesh.mesh.get_aabb().size.y<.20: return false
	return true
