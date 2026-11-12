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
	if not (robe.mesh is CylinderMesh) or (robe.mesh as CylinderMesh).radial_segments<10:
		_fail("The fitted villager torso was replaced by a cuboid")
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
	# Improved appearance must stay on the original articulated rig;
	# costume geometry may not replace the moving limbs or their jobs.
	for actor in [ida,orin]:
		if actor.find_child("CutAndRepairedTunicPanels",true,false)==null:
			_fail("Villager lost the tapered, textured over-garment")
			return
		if actor.find_child("SmallTarnishedBeltBuckle",true,false)==null:
			_fail("Profession-specific clothing hardware was not instanced")
			return
		if actor.find_child("AnimatedLeftArm",true,false)==null:
			_fail("A new costume mesh accidentally removed the original moving rig")
			return
	# The previous faces were near-identical spheres with surface eyes.
	# Regressions must retain recesses, realistic profile and role variants.
	for citizen in [ida,orin]:
		var portrait: Node3D=citizen.find_child(
			"IndividualFaceConstruction",true,false) as Node3D
		if portrait==null or not bool(portrait.get_meta("no_new_collision",false)):
			_fail("The villager lost its distinctive non-physical facial rig")
			return
		for part in ["IndividualIntegratedFaceMesh","SmallRecessedEye",
				"NaturalHairline","SmallNaturalLipLine"]:
			if portrait.find_child(part,true,false)==null:
				_fail("A low-poly facial feature was lost: "+part)
				return
		var sculpt: MeshInstance3D=portrait.get_node_or_null(
			"IndividualIntegratedFaceMesh") as MeshInstance3D
		if sculpt==null or sculpt.mesh==null or sculpt.mesh.surface_get_count()!=1:
			_fail("An anatomical face has regressed to disconnected prop spheres")
			return
		var verts: PackedVector3Array=sculpt.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
		if verts.size()<2000:
			_fail("The face no longer has sufficient sculpted profile topology")
			return
		if portrait.find_children("*","StaticBody3D",true,false).size()>0:
			_fail("An artistic face introduced unnecessary collision")
			return
	# Movement is driven by measured displacement, not a fixed walk cycle.
	# The tested physics actor and its normal joints are retained.
	if ida.get("visual_figure")==null or ida.get("distance_gait_phase")==null:
		_fail("Visual rig no longer supports distance-driven gait")
		return
	var smith_head=orin.find_child("ModeledInhabitantHead",true,false) as MeshInstance3D
	if smith_head==null or smith_head.material_override==null or face.material_override==null:
		_fail("Different village workers do not have modeled, shaded faces")
		return
	if (smith_head.material_override as StandardMaterial3D).albedo_color.is_equal_approx(
		(face.material_override as StandardMaterial3D).albedo_color):
		_fail("Every villager received an identical skin material")
		return
	print("PASS: fitted villager bodies, individual face anatomy, distance-aware rigging and baker apron preserve distinct worker appearance")
	quit(0)
