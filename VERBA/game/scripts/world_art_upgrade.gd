extends RefCounted
## Replaces visible procedural geometry with authored Blender GLBs.
## All existing collision shapes, navigation blockers, saved IDs, jobs, doors,
## interactions and scene coordinates remain untouched.
const FOUNDRY = "res://assets/models/foundry/"
const REPLACEMENTS: Array[Dictionary] = [
	{"path":"ValleyScenicDetails/OldCreekFootbridge","asset":"old_creek_footbridge"},
	{"path":"OuterValeRegionalLandmarks/StillwaterLake/OldFishingJetty","asset":"old_fishing_jetty"},
	{"path":"OuterValeRegionalLandmarks/SevenWeatheredWitnessStones","asset":"witness_stone_circle"},
	{"path":"RidgeArch","asset":"ridge_arch"},
	{"path":"StonePrayerShrine","asset":"stone_prayer_shrine"},
	{"path":"OuterValeRegionalLandmarks/ColdCharcoalKiln","asset":"cold_charcoal_kiln"},
	{"path":"OuterValeRegionalLandmarks/StillwaterLake/TheHalfDrownedAltar","asset":"witness_stone_circle","enabled":false},
	{"path":"StrangeRoadDistrict/ValeFuelStation/WeatheredForecourtHistory/RustingDeliveryWreck",
	 "asset":"rusting_delivery_wreck"}
]

static func apply(world: Node3D) -> void:
	var applied: int = 0
	for definition in REPLACEMENTS:
		if not definition.get("enabled",true):
			continue
		var target: Node3D = world.get_node_or_null(String(definition["path"])) as Node3D
		if target == null:
			push_warning("Foundry target not present: "+String(definition["path"]))
			continue
		if replace_visuals(target,String(definition["asset"])):
			applied += 1
	world.set_meta("foundry_replacements",applied)

static func replace_visuals(target: Node3D, asset_name: String) -> bool:
	var path: String = FOUNDRY+asset_name+".glb"
	if not ResourceLoader.exists(path):
		# A fresh checkout remains playable until the Actions build
		# supplies the approved .glb; the original visuals stay visible.
		return false
	var resource: Resource = load(path)
	if not (resource is PackedScene):
		push_error("Foundry asset not imported as a 3D scene: "+path)
		return false
	var candidate: Node3D = (resource as PackedScene).instantiate() as Node3D
	if candidate == null:
		return false
	var sections: int = candidate.find_children("*","MeshInstance3D",true,false).size()
	if sections == 0:
		candidate.free()
		push_error("Foundry model empty: "+path)
		return false
	candidate.name="BlenderAuthored_"+asset_name
	# Hide only geometry, NEVER physics bodies or collision/navigation.
	for old_mesh in target.find_children("*","MeshInstance3D",true,false):
		(old_mesh as MeshInstance3D).visible=false
	for old_multimesh in target.find_children("*","MultiMeshInstance3D",true,false):
		(old_multimesh as MultiMeshInstance3D).visible=false
	target.add_child(candidate)
	target.set_meta("foundry_model",asset_name)
	target.set_meta("foundry_sections",sections)
	return true
