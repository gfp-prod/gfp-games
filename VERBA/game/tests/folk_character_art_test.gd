extends SceneTree
## Render-asset regression: preserve human proportions and the baker's
## identifiable working costume without changing any simulation authority.
func _initialize() -> void:
	call_deferred("_run")

func _fail(reason: String) -> void:
	push_error("Villager character art: " + reason)
	quit(1)

func _run() -> void:
	var world=load("res://main.tscn").instantiate()
	root.add_child(world)
	await process_frame
	var ida: Node3D
	var orin: Node3D
	for actor in world.npcs:
		if actor.npc_id=="ida": ida=actor
		if actor.npc_id=="orin": orin=actor
	if ida==null or orin==null:
		_fail("Baker or blacksmith is missing from the living village")
		return
	var figure=ida.find_child("VisibleInhabitant",true,false)
	var face=ida.find_child("ModeledInhabitantHead",true,false) as MeshInstance3D
	var robe=ida.find_child("TaperedVillagerTunic",true,false) as MeshInstance3D
	var apron=ida.find_child("VisibleBakerApron",true,false) as MeshInstance3D
	var bonnet=ida.find_child("VisibleBakerBonnet",true,false) as MeshInstance3D
	var pocket=ida.find_child("BakerWorkPocket",true,false)
	if figure==null or face==null or robe==null or apron==null or bonnet==null or pocket==null:
		_fail("The baker has lost her fitted clothing, modeled face or work gear")
		return
	if not (face.mesh is SphereMesh) or face.scale.x<.38 or face.scale.y<.43:
		_fail("Character head regressed to the tiny floating-eyes mannequin")
		return
	if not (robe.mesh is ArrayMesh) or robe.mesh.get_surface_count()<1:
		_fail("The modeled torso was replaced by the old CylinderMesh barrel")
		return
	var neck=ida.find_child("ModeledNeck",true,false) as MeshInstance3D
	if neck==null or neck.mesh is CylinderMesh:
		_fail("The skin-colored chest/neck cylinder has returned")
		return
	var thigh=ida.find_child("AnatomicalThigh",true,false) as MeshInstance3D
	var calf=ida.find_child("AnatomicalCalf",true,false) as MeshInstance3D
	if thigh==null or calf==null or not (thigh.mesh is ArrayMesh) or not (calf.mesh is ArrayMesh):
		_fail("Legs regressed to two stacked cylinders")
		return
	if ida.left_leg.position.y<.94 or ida.right_leg.position.y<.94:
		_fail("NPC leg length regressed to stumpy proportions")
		return
	if apron.mesh==null or apron.mesh.get_surface_count()!=1:
		_fail("The shaped baker apron surface is missing")
		return
	var triangles: PackedVector3Array=apron.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	if triangles.size()!=24:
		_fail("Baker apron no longer has eight curved, fitted cloth triangles")
		return
	var bounds: AABB=apron.get_aabb()
	if bounds.size.y<.8 or bounds.size.x<.4 or bounds.size.x>.7:
		_fail("The apron has lost plausible body proportions")
		return
	var smith_head=orin.find_child("ModeledInhabitantHead",true,false) as MeshInstance3D
	if smith_head==null or smith_head.material_override==null or face.material_override==null:
		_fail("Different village workers do not have modeled, shaded faces")
		return
	if (smith_head.material_override as StandardMaterial3D).albedo_color.is_equal_approx(
		(face.material_override as StandardMaterial3D).albedo_color):
		_fail("Every villager received an identical skin material")
		return
	print("PASS: fitted villager bodies, shaded facial proportions and four-panel baker apron preserve distinct worker appearance")
	quit(0)
