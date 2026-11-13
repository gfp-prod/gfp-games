extends SceneTree
## Render-asset regression: preserve human proportions and the baker's
## identifiable working costume without changing any simulation authority.
const FABRIC=preload("res://scripts/npc_cloth_finish.gd")

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
	# The inherited fitted torso must be the actual visible garment.
	# Two older identical rigid cones previously covered every variation
	# in the genetic waist, hip and chest surfaces.
	var lower_legacy: Node3D=ida.find_child("LegacyLowerTunicHidden",true,false)
	if not (robe.mesh is CylinderMesh) or lower_legacy==null or (
			robe.visible or lower_legacy.visible) or not bool(
			robe.get_meta("legacy_hidden_by_genetic_torso",false)):
		_fail("Rigid legacy cone clothes are still masking individual physiques")
		return
	if apron.mesh==null or apron.mesh.get_surface_count()!=1:
		_fail("The shaped baker apron surface is missing")
		return
	var triangles: PackedVector3Array=apron.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	if triangles.size()<180:
		_fail("Baker apron has too few fitted patches to follow chest anatomy")
		return
	# Prove the actual pale apron stays outside the inherited front
	# surface, not hidden behind the worker's shirt as it was on camera.
	var genetic_body=load("res://scripts/npc_body_morph.gd")
	var ida_genome: Dictionary=world.village_sim.people["ida"]["genome"]
	for v in triangles:
		var section_width: float=genetic_body._section(v.y,ida_genome,String(world.village_sim.people["ida"]["sex"])).x
		var angle: float=-PI*.5+asin(clampf(v.x/section_width,-.89,.89))
		var outer_front: float=genetic_body._point(v.y,angle,ida_genome,String(world.village_sim.people["ida"]["sex"])).z
		if v.z>outer_front-.046:
			_fail("Baker apron is buried behind genetically modeled clothing")
			return
	# Vertex-only clearance missed the huge chest-colored hole: the shirt
	# intersected the broad triangle interiors between sampled edge points.
	# Reject any apron whose triangle centers cut into the inherited torso.
	for triangle in range(0,triangles.size(),3):
		var center: Vector3=(triangles[triangle]+triangles[triangle+1]+
			triangles[triangle+2])/3.0
		var radius: float=genetic_body._section(center.y,ida_genome,String(world.village_sim.people["ida"]["sex"])).x
		var angle: float=-PI*.5+asin(clampf(center.x/radius,-.89,.89))
		var front: float=genetic_body._point(center.y,angle,ida_genome,String(world.village_sim.people["ida"]["sex"])).z
		if center.z>front-.055:
			_fail("Baker apron triangle interior clips through the chest or waist")
			return
	if not bool(apron.get_meta("drapes_over_inherited_torso",false)):
		_fail("Baker apron lost its fitted living-body surface")
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
	# The old movable arms were plain cylinders whose hard shoulder
	# intersections made the bodies look assembled from spare parts.
	# Ensure the new fitted meshes belong to the exact original limb rigs.
	for actor in [ida,orin]:
		for side in ["Left","Right"]:
			var arm: Node3D=actor.find_child(
				"Animated"+side+"Arm",true,false) as Node3D
			var sleeve: MeshInstance3D=arm.get_node_or_null(
				"GeneticFittedSleeve") as MeshInstance3D if arm!=null else null
			if arm==null or sleeve==null or sleeve.mesh==null:
				_fail("An original detachable arm has lost its fitted sleeve"); return
			if not bool(sleeve.get_meta("old_limb_pivot_preserved",false)):
				_fail("Decorative sleeve replaced an amputatable arm joint"); return
			var sign: float=-1.0 if side=="Left" else 1.0
			if arm.rotation.z*sign<.04:
				_fail("NPC arm lost its inherited relaxed resting posture"); return
			var vertices: PackedVector3Array=sleeve.mesh.surface_get_arrays(0)[
				Mesh.ARRAY_VERTEX]
			var limb_bounds: AABB=sleeve.get_aabb()
			# The top surface must be sealed: an earlier fitted sleeve
			# exposed an open dark hole when the camera stood above a person.
			if not bool(sleeve.get_meta("sealed_upper_shoulder",false)):
				_fail("Shoulder sleeve lost its skin-safe upper cloth closure"); return
			if vertices.size()<540 or limb_bounds.size.y<.45 or (
					limb_bounds.size.x<.15 or limb_bounds.size.x>.38):
				_fail("An arm reverted to a rigid one-piece cylinder"); return
			if not sleeve.find_children("*","CollisionShape3D",true,false).is_empty():
				_fail("Decorative sleeve added redundant physical collision"); return
			var module_name: String=side.to_lower()+"_arm"
			if actor.modular_limbs.get(module_name)!=arm:
				_fail("Sleeve was added to a different arm than the injury rig"); return
	# A full two-piece arm should reach the upper thigh, not end at
	# chest level. The forearm's length comes from the inherited ratio and
	# the elbow belongs to the original severable arm hierarchy.
	for citizen in [ida,orin]:
		var person: Dictionary=world.village_sim.people[String(citizen.npc_id)]
		var genome: Dictionary=person["genome"]
		for side in ["Left","Right"]:
			var arm: Node3D=citizen.modular_limbs[
				side.to_lower()+"_arm"] as Node3D
			var elbow: Node3D=arm.get_node_or_null("Animated"+side+"Forearm")
			if elbow==null or not arm.is_ancestor_of(elbow):
				_fail("Inherited arm has no articulated elbow"); return
			var mesh: MeshInstance3D=elbow.get_node_or_null(
				"InheritedForearmSleeve") as MeshInstance3D
			var hand: MeshInstance3D=elbow.get_node_or_null(
				"InheritedArticulatedHand") as MeshInstance3D
			if mesh==null or hand==null or mesh.mesh==null:
				_fail("Arm still ends in a stub instead of a forearm and hand"); return
			if not bool(mesh.get_meta("detaches_with_parent_arm",false)):
				_fail("Forearm does not detach with its upper arm"); return
			var length: float=float(mesh.get_meta("inherited_wrist_reach",0.0))
			if absf(length-load("res://scripts/npc_genetics.gd").forearm_length(
					genome))>.002:
				_fail("Arm length ignores actual inherited limb ratio"); return
			if arm.to_local(hand.global_position).y>-.82:
				_fail("Individual's hand still sits at the waist"); return
			var area: Area3D=citizen.limb_hitboxes[side.to_lower()+"_arm"]
			var capsule: CollisionShape3D=area.get_child(0) as CollisionShape3D
			if capsule==null or not (capsule.shape is CapsuleShape3D) or (
					(capsule.shape as CapsuleShape3D).height<1.10):
				_fail("Long forearm lost its continuous physical hitbox"); return
		var torso: MeshInstance3D=citizen.find_child(
			"InheritedChestWaistHipCloth",true,false) as MeshInstance3D
		if torso==null or String(torso.get_meta(
				"sex_linked_body_shape",""))!=String(person["sex"]):
			_fail("Female/male inherited body profiles are not expressed"); return
		var expected: Vector3=load("res://scripts/npc_genetics.gd").body_scale(
			genome,String(person["sex"]))
		if citizen.inherited_body_dimensions.distance_to(expected)>.001:
			_fail("NPC stature and frame size ignore heritable body genes"); return
	# Shoulder joints sit at each citizen's actual rib/shoulder breadth;
	# femoral heads sit at the inherited pelvis. A shared .345/.17 offset
	# would erase the anatomy even though the cloth has a better shape.
	for citizen in [ida,orin]:
		var person: Dictionary=world.village_sim.people[String(citizen.npc_id)]
		var gg: Dictionary=person["genome"]
		var sex: String=String(person["sex"])
		var shoulder_socket: float=.040+.88*genetic_body._section(
			1.365,gg,sex).x
		var femur_socket: float=.455*genetic_body._section(.78,gg,sex).x
		if absf(citizen.left_arm.position.x+shoulder_socket)>.007 or (
				absf(citizen.left_leg.position.x+femur_socket)>.007):
			_fail("Physical joint spacing ignores inherited shoulder or pelvis")
			return
	# Legs must remain independently amputatable while trousers and
	# footwear follow the inherited body rather than cubic ankle blocks.
	for citizen in [ida,orin]:
		for side in ["Left","Right"]:
			var original_leg: Node3D=citizen.modular_limbs.get(
				side.to_lower()+"_leg") as Node3D
			var trousers: MeshInstance3D=original_leg.get_node_or_null(
				"GeneticTrouserLeg") as MeshInstance3D if original_leg!=null else null
			var boot: MeshInstance3D=original_leg.get_node_or_null(
				"GeneticAnkleBoot") as MeshInstance3D if original_leg!=null else null
			if original_leg==null or trousers==null or boot==null:
				_fail("Old cuboid boots or one-piece leg cylinders returned"); return
			if trousers.mesh==null or boot.mesh==null or (
					trousers.mesh is CylinderMesh or boot.mesh is BoxMesh):
				_fail("Fitted leg geometry was replaced by primitive shapes"); return
			var trouser_vertices: PackedVector3Array=trousers.mesh.surface_get_arrays(0)[
				Mesh.ARRAY_VERTEX]
			var boot_vertices: PackedVector3Array=boot.mesh.surface_get_arrays(0)[
				Mesh.ARRAY_VERTEX]
			if trouser_vertices.size()<500 or boot_vertices.size()<250:
				_fail("Leg or boot lost its faceted inherited silhouettes"); return
			var foot_bounds: AABB=boot.get_aabb()
			if foot_bounds.size.z<.32 or foot_bounds.size.y<.13:
				_fail("Foot lost instep, toe or ankle volume"); return
			if not bool(trousers.get_meta("original_detachable_leg",false)) or (
					not bool(boot.get_meta("no_new_collision",false))):
				_fail("Fitted leg violated modular injury/collision contract"); return
			var hide: StandardMaterial3D=boot.material_override as StandardMaterial3D
			if hide==null or hide.albedo_texture!=FABRIC.leather_texture() or (
					not bool(boot.get_meta("weathered_leather",false))):
				_fail("Boot lost its grounded, worn leather material"); return
			# The existing limb hitbox is deliberately physical. Only the
			# NEW art meshes must be collision-free.
			if not trousers.find_children("*","CollisionShape3D",true,false).is_empty() or (
					not boot.find_children("*","CollisionShape3D",true,false).is_empty()):
				_fail("Decorative leg geometry added redundant collision"); return
	# The blacksmith must have a curved work apron, not a detached
	# rectangular chest plate. The rear cloth is not the source of truth.
	var smith_apron: MeshInstance3D=orin.find_child(
		"VisibleSmithApron",true,false) as MeshInstance3D
	if smith_apron==null or not bool(
			smith_apron.get_meta("fitted_to_inherited_torso",false)):
		_fail("The blacksmith apron is still a featureless box"); return
	# A panel with wrong triangle winding passed mesh tests but vanished in
	# real Godot screenshots. Both faces and actual leather grain are required.
	var hide: StandardMaterial3D=smith_apron.material_override as StandardMaterial3D
	if hide==null or hide.cull_mode!=BaseMaterial3D.CULL_DISABLED or (
			hide.albedo_texture!=FABRIC.leather_texture()):
		_fail("Smith apron backface is culled or aged leather was not applied")
		return
	if smith_apron.mesh is BoxMesh or smith_apron.mesh==null:
		_fail("The smith lost the sculpted apron mesh"); return
	var smith_points: PackedVector3Array=smith_apron.mesh.surface_get_arrays(0)[
		Mesh.ARRAY_VERTEX]
	if smith_points.size()<500 or smith_apron.get_aabb().size.y<.75:
		_fail("Smith apron lacks torso-following geometry"); return
	var smith_genome: Dictionary=world.village_sim.people["orin"]["genome"]
	for index in range(0,smith_points.size(),3):
		var p: Vector3=(smith_points[index]+smith_points[index+1]+
			smith_points[index+2])/3.0
		var section: float=genetic_body._section(p.y,smith_genome,String(world.village_sim.people["orin"]["sex"])).x
		var angle: float=-PI*.5+asin(clampf(p.x/section,-.91,.91))
		if p.z>genetic_body._point(p.y,angle,smith_genome,String(world.village_sim.people["orin"]["sex"])).z-.05:
			_fail("Blacksmith apron intersects its inherited torso"); return
	# Keep the baker's original apron identity but ban the bright stiff
	# waist rods that dominated its real first-person view.
	var stitch: Node3D=ida.find_child("BakerCloseFittedWaistSeam",true,false)
	if stitch==null or (
			ida.find_child("BakerFittedLeftTie",true,false)==null) or (
			ida.find_child("BakerFittedRightTie",true,false)==null):
		_fail("Baker lost a uniquely named left or right fitted waist tie")
		return
	# Catch the exact modeling artifact: a broad cylinder floating across
	# the clavicles was mistakenly used as an ivory costume/trim seam.
	# It is not required by the detachable limb rig.
	for actor in [ida,orin]:
		var torso: Node3D=actor.find_child("VisibleInhabitant",true,false)
		var fitted: MeshInstance3D=actor.find_child(
			"TaperedVillagerTunic",true,false) as MeshInstance3D
		if torso==null or fitted==null:
			_fail("The tested living torso is missing")
			return
		var dyed: StandardMaterial3D=fitted.material_override as StandardMaterial3D
		if dyed==null or dyed.albedo_texture!=FABRIC.woven_texture():
			_fail("Villager clothing reverted to parchment instead of woven cloth")
			return
		for part in torso.get_children():
			if not (part is MeshInstance3D): continue
			var mesh: MeshInstance3D=part as MeshInstance3D
			if not (mesh.mesh is CylinderMesh): continue
			var cylinder: CylinderMesh=mesh.mesh as CylinderMesh
			if absf(mesh.position.y-1.47)<.12 and absf(mesh.position.z+.13)<.10 and cylinder.height>.36:
				_fail("The exposed chest collarbone cylinder has returned")
				return
	# The forging hammer must stay attached to Orin's original modular
	# hand, but it must not dominate the camera as a giant horizontal slab.
	var hammer: Node3D=orin.find_child(
		"VisibleSmithHammer",true,false) as Node3D
	var hammer_head: MeshInstance3D=hammer.get_node_or_null(
		"SmithHammerWorkingHead") as MeshInstance3D if hammer!=null else null
	if hammer==null or hammer_head==null or not (
			orin.right_arm.is_ancestor_of(hammer)):
		_fail("Smith's resized hammer lost its original movable hand"); return
	if not (hammer_head.mesh is BoxMesh) or (
			(hammer_head.mesh as BoxMesh).size.x>.27):
		_fail("Smith's tool has become an enormous floating beam again"); return
	# The petrol worker must swing its actual visible uniform sleeves,
	# not the old medieval character model that is hidden beneath it.
	var attendant: Node3D=null
	for person in world.npcs:
		if String(person.npc_id)=="juno":
			attendant=person
			break
	if attendant!=null:
		var modern: Node3D=attendant.find_child("DistinctModernAttendant",true,false)
		if modern==null or not modern.is_ancestor_of(attendant.left_leg):
			_fail("Roadside attendant animation drives hidden limbs")
			return
		if not modern.is_ancestor_of(attendant.right_arm):
			_fail("Roadside attendant's work sleeve lost its animation joint")
			return

		var station_apron: MeshInstance3D=modern.get_node_or_null(
			"FittedStationWorkApron") as MeshInstance3D
		var old_torso: MeshInstance3D=modern.get_node_or_null(
			"HiddenOldStationShirtBox") as MeshInstance3D
		var old_box: MeshInstance3D=modern.get_node_or_null(
			"HiddenOldStationApronBox") as MeshInstance3D
		if station_apron==null or station_apron.mesh==null or old_torso==null or old_box==null:
			_fail("Modern work uniform lost fitted inherited clothing"); return
		if old_torso.visible or old_box.visible or not bool(
				station_apron.get_meta("contoured_to_hips_and_waist",false)):
			_fail("Station staff still wear rigid unisex box clothing"); return
		if station_apron.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX].size()<650:
			_fail("Anatomical apron uses an oversimplified rectangle"); return
		if String(station_apron.get_meta("anatomic_body_profile",""))!=(
				String(world.village_sim.people["juno"]["sex"])):
			_fail("Station staff's inherited physique does not reach clothing"); return

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
		if sculpt==null or sculpt.mesh==null or sculpt.mesh.get_surface_count()!=1:
			_fail("An anatomical face has regressed to disconnected prop spheres")
			return
		var verts: PackedVector3Array=sculpt.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
		if verts.size()<1200:
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
