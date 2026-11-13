extends SceneTree
## Render-asset regression: preserve human proportions and the baker's
## identifiable working costume without changing any simulation authority.
const FABRIC=preload("res://scripts/npc_cloth_finish.gd")
const GROOM=preload("res://scripts/folk_hair_finish.gd")
const GENES=preload("res://scripts/npc_genetics.gd")
const ART_LIB=preload("res://scripts/art.gd")

func _initialize() -> void:
	call_deferred("_run")

func _fail(reason: String) -> void:
	push_error("Villager character art: " + reason)
	quit(1)

## Examine real SurfaceTool vertices near the ends of inherited long locks.
## A lock may be long but invisible if its last rows disappear inside cloth.
func _long_lock_clears_tunic(mesh: MeshInstance3D,front: bool) -> bool:
	if mesh==null or mesh.mesh==null: return false
	var points: PackedVector3Array=mesh.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	if points.size()<100: return false
	var lowest: float=100.0
	for v in points:
		lowest=minf(lowest,v.y)
	var at_hem: int=0
	for v in points:
		if v.y>lowest+.021: continue
		at_hem+=1
		if front and v.z>-.298: return false
		if not front and v.z<.320: return false
	return at_hem>=8

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
	# Quality gate: women must have distinct hair and dress silhouettes
	# and professions must use low-poly tools, not floating huge boxes.
	var sela: Node3D
	var mara: Node3D
	var titus: Node3D
	for resident in world.npcs:
		match resident.npc_id:
			"sela": sela=resident
			"mara": mara=resident
			"titus": titus=resident
	if sela==null or mara==null or titus==null:
		_fail("Character art gallery lacks female/male profession variety"); return
	for woman in [ida,mara,sela]:
		var styled: Node3D=woman.find_child(
			"GroomedHairStudio",true,false) as Node3D
		var tailored: MeshInstance3D=woman.find_child(
			"TailoredHereditaryDress",true,false) as MeshInstance3D
		var outfit: Node3D=woman.find_child(
			"RoleWardrobeLayers",true,false) as Node3D
		if styled==null or tailored==null or outfit==null:
			_fail("Women regressed to the unisex tunic and blank scalp"); return
		if styled.get_child_count()<3 or tailored.mesh==null:
			_fail("Female hair and dress silhouettes lack modeled layers"); return
		if woman.find_children("*","CollisionShape3D",true,false).is_empty():
			_fail("Character lost physical limb targeting during costume pass"); return
	if String(mara.find_child("GroomedHairStudio",true,false).get_meta(
			"hairstyle",""))==String(sela.find_child(
			"GroomedHairStudio",true,false).get_meta("hairstyle","")):
		_fail("Different women still share identical grooming"); return
	var merchant_pouch: MeshInstance3D=sela.find_child(
		"VisibleMerchantPouch",true,false) as MeshInstance3D
	if merchant_pouch==null or merchant_pouch.mesh is BoxMesh or (
			merchant_pouch.get_aabb().size.x>.32) or (
			not bool(merchant_pouch.get_meta("hip_fitted_satchels",false))):
		_fail("Merchant still carries a large floating golden box"); return
	var shield: MeshInstance3D=titus.find_child(
		"VisibleGuardShield",true,false) as MeshInstance3D
	if shield==null or shield.mesh==null or shield.mesh is BoxMesh or (
			not titus.left_arm.is_ancestor_of(shield)):
		_fail("Guard still carries a suspended rectangular shield"); return
	var smith_style: Node3D=orin.find_child(
		"GroomedHairStudio",true,false) as Node3D
	if smith_style==null or smith_style.get_child_count()<3:
		_fail("Blacksmith has no inherited male hairstyle geometry"); return
	# The blacksmith's curls must be ONE coherent surface. Previous
	# attempts passed density checks by scattering spheres above his skull.
	var curl_crown: MeshInstance3D=smith_style.get_node_or_null(
		"SculptedCurlyCrown") as MeshInstance3D
	if curl_crown==null or curl_crown.mesh==null or (
			not bool(curl_crown.get_meta("one_connected_curl_silhouette",false))):
		_fail("Curly hair reverted to a floating collection of spheres")
		return
	var curl_vertices: PackedVector3Array=curl_crown.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	if curl_vertices.size()<1000:
		_fail("Curly crown lost its connected low-poly sculpt"); return
	# A curl shell can be connected and STILL hover like a flat hat.
	# Check actual foremost roots reach the forehead below the crown.
	var seated_curls: bool=false
	for point in curl_vertices:
		if absf(point.x)<.035 and point.z<-.140 and point.y<1.943:
			seated_curls=true
			break
	if not seated_curls:
		_fail("Curly crown has lifted back off the natural forehead"); return
	if smith_style.find_child("TightFacetedCurl*",true,false)!=null or (
			smith_style.find_child("TightCurlLock*",true,false)!=null):
		_fail("Unconnected curl beads or stiff dangling locks returned")
		return
	# Visual quality must be inspected in generated mesh vertices, not
	# just the presence of a hairstyle tag. Check real hairline geometry.
	for person_actor in [ida,orin,mara,sela]:
		var cap: MeshInstance3D=person_actor.find_child(
			"NaturalHairline",true,false) as MeshInstance3D
		if cap==null or cap.mesh==null or not bool(
				cap.get_meta("hairline_follows_skull",false)):
			_fail("Genetically shaped hairline was replaced by a helmet sphere")
			return
		var hairline_vertices: PackedVector3Array=cap.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
		if hairline_vertices.size()<500:
			_fail("Hairline lacks the sculpted silhouette topology")
			return
		var forehead_contact: bool=false
		var temple_rise: bool=false
		for point in hairline_vertices:
			if absf(point.x)<.033 and point.z<-.151 and point.y<1.925:
				forehead_contact=true
			if absf(point.x)>.155 and absf(point.z)<.052 and point.y>1.924:
				temple_rise=true
		if not forehead_contact or not temple_rise:
			_fail("Scalp shell returned to floating halo/straight cap hairline")
			return
	for actor in [mara,sela]:
		var groom: Node3D=actor.find_child("GroomedHairStudio",true,false)
		var panels: Array[Node]=groom.find_children(
			"FacetedBackHairPanel*","MeshInstance3D",false,false)
		if panels.size()<3:
			_fail("Long hair lost its overlapping sculpted silhouette")
			return
		for panel in panels:
			if not bool(panel.get_meta("sculpted_continuous_tress",false)):
				_fail("Long hairstyle reverted to hanging rigid hair tubes")
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
	# The bonnet must hug the inherited skull. Wide flat rims are what
	# made the baker look as though she wore a pale mushroom on her head.
	var bonnet_bounds: AABB=bonnet.get_aabb()
	if bonnet_bounds.size.x>.397 or bonnet_bounds.size.y<.125:
		_fail("Baker kerchief is a wide brim rather than a fitted cap")
		return
	# Check the visible mesh, not a metadata-only claim. Earlier adult
	# inhabitants were 4-head-tall caricatures because their skulls were
	# nearly half a meter high against a two-meter world body.
	if not (face.mesh is SphereMesh) or face.scale.x<.31 or (
			face.scale.x>.38) or (face.scale.y<.31 or face.scale.y>.38):
		_fail("Figure-reference skull calibration regressed")
		return
	var crown_height: float=face.position.y+face.scale.y*.5
	var skull_ratio: float=crown_height/face.scale.y
	if skull_ratio<5.30 or skull_ratio>7.10:
		_fail("Adult body/head proportions returned to stocky mannequin scale")
		return
	var skull_root: Node3D=ida.find_child(
		"IndividualFaceConstruction",true,false) as Node3D
	if skull_root==null or not bool(skull_root.get_meta(
			"landmark_calibrated_skull",false)) or (
			absf(skull_root.scale.y-face.scale.y/.49)>.004):
		_fail("Facial features and head mesh no longer share throat-anchored scaling")
		return
	var age_child: Vector3=load("res://scripts/folk_portrait_finish.gd").skull_scale(
		world.village_sim.people["ida"]["genome"],6.0)
	if age_child.y<=skull_root.scale.y+.07:
		_fail("Child heads no longer remain proportionally larger")
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
	# The baker must now be a particular woman with a work dress and
	# a tied bun, rather than the same male-bodied cylinder in an apron.
	var tailored: MeshInstance3D=ida.find_child(
		"TailoredHereditaryDress",true,false) as MeshInstance3D
	var bun: MeshInstance3D=ida.find_child(
		"TiedLowHairBun",true,false) as MeshInstance3D
	if tailored==null or tailored.mesh==null or bun==null:
		_fail("Ida lost the bespoke dress silhouette or her tied long hair")
		return
	if String(tailored.get_meta("tailored_style",""))!="baker_apron_dress":
		_fail("The baker is still rendered in the generic unisex outfit")
		return
	var dress_vertices: PackedVector3Array=tailored.mesh.surface_get_arrays(0)[
		Mesh.ARRAY_VERTEX]
	if dress_vertices.size()<800 or not bool(
			tailored.get_meta("no_new_collision",false)):
		_fail("The fitted skirt is missing its real, non-physical pleated mesh")
		return
	var male_face: Node3D=orin.find_child(
		"IndividualFaceConstruction",true,false) as Node3D
	if male_face==null or not male_face.has_meta("heritable_beard_style"):
		_fail("Orin's appearance does not consult inherited facial hair")
		return
	if apron.mesh==null or apron.mesh.get_surface_count()!=1:
		_fail("The shaped baker apron surface is missing")
		return
	var triangles: PackedVector3Array=apron.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	if triangles.size()<3000:
		_fail("Baker apron lost its dense anatomical loft and may float away from the chest")
		return
	# Prove the actual pale apron stays outside the inherited front
	# surface, not hidden behind the worker's shirt as it was on camera.
	var genetic_body=load("res://scripts/npc_body_morph.gd")
	var ida_genome: Dictionary=world.village_sim.people["ida"]["genome"]
	for v in triangles:
		var section_width: float=genetic_body._section(v.y,ida_genome,String(world.village_sim.people["ida"]["sex"])).x
		var angle: float=-PI*.5+asin(clampf(v.x/section_width,-.89,.89))
		var outer_front: float=genetic_body._point(v.y,angle,ida_genome,String(world.village_sim.people["ida"]["sex"])).z
		var clearance: float=outer_front-v.z
		if clearance<.020 or clearance>.071:
			_fail("Baker apron is clipping or visibly floating off the torso")
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
		var triangle_clearance: float=front-center.z
		if triangle_clearance<.018 or triangle_clearance>.073:
			_fail("Baker apron triangle interior clips or lifts off its body")
			return
	if not bool(apron.get_meta("drapes_over_inherited_torso",false)):
		_fail("Baker apron lost its fitted living-body surface")
		return
	var bounds: AABB=apron.get_aabb()
	if bounds.size.y<.8 or bounds.size.x<.4 or bounds.size.x>.7:
		_fail("The apron has lost plausible body proportions")
		return
	# The baker's bib must actually taper at the waist, not just carry
	# a metadata claim over the old full-length rectangular white slab.
	var apron_waist: float=0.0
	var apron_hem: float=0.0
	for vertex in triangles:
		if absf(vertex.y-1.055)<.012:
			apron_waist=maxf(apron_waist,absf(vertex.x))
		if vertex.y<.59:
			apron_hem=maxf(apron_hem,absf(vertex.x))
	if apron_waist<=0.0 or apron_hem<apron_waist*1.27:
		_fail("Baker work apron reverted to a waist-obscuring rectangle")
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
	# The painter's work apron must reveal the inherited waist. A
	# rectangular drape can conceal all our anatomical sculpting while
	# still passing a torso-mesh unit test.
	var painter: Node3D
	for resident in world.npcs:
		if String(resident.npc_id)=="lena": painter=resident
	if painter==null:
		_fail("Painter missing from living game world"); return
	var painter_smock: MeshInstance3D=painter.find_child(
		"PainterPigmentedWorkSmock",true,false) as MeshInstance3D
	if painter_smock==null or not bool(painter_smock.get_meta(
			"genetic_waist_fitted_apron",false)):
		_fail("Painter's apron reverted to an identical rectangular slab")
		return
	var waist_width: float=0.0
	var hem_width: float=0.0
	for point in painter_smock.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]:
		if point.y>.98 and point.y<1.07:
			waist_width=maxf(waist_width,absf(point.x))
		if point.y<.79:
			hem_width=maxf(hem_width,absf(point.x))
	if waist_width<=.02 or hem_width<=waist_width*1.22:
		_fail("Painter's apron covers the waist with a rigid box profile")
		return
	# Every citizen's over-tunic must stop above the thigh, leaving the
	# original detachable femurs rather than burying them in a tube.
	for actor in [ida,orin,painter]:
		var overshirt: MeshInstance3D=actor.find_child(
			"CutAndRepairedTunicPanels",true,false) as MeshInstance3D
		if overshirt==null or not bool(overshirt.get_meta(
				"leg_silhouette_uncovered",false)):
			_fail("Over-tunic reverted to the old long cylinder")
			return
	# Compare actual living shoulder pivots against the same inherited
	# torso width. Smaller-average female shoulders must not have an
	# identical square outer-arm attachment as the blacksmith.
	var ida_shoulder_width: float=genetic_body._section(1.365,
		world.village_sim.people["ida"]["genome"],"female").x
	var orin_shoulder_width: float=genetic_body._section(1.365,
		world.village_sim.people["orin"]["genome"],"male").x
	var ida_socket_ratio: float=(absf(ida.left_arm.position.x)-.024)/ida_shoulder_width
	var orin_socket_ratio: float=(absf(orin.left_arm.position.x)-.024)/orin_shoulder_width
	if ida_socket_ratio>=orin_socket_ratio-.025:
		_fail("Female-average arms still attach at broad male shoulder offsets")
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
			if not bool(sleeve.get_meta("sealed_upper_shoulder",false)) or (
					not bool(sleeve.get_meta("lowered_deltoid_cap",false))):
				_fail("Shoulder sleeve lost its skin-safe upper cloth closure"); return
			if vertices.size()<540 or limb_bounds.size.y<.275 or (
					limb_bounds.size.x<.105 or limb_bounds.size.x>.27) or (
					limb_bounds.end.y>.052):
				_fail("An arm reverted to a rigid one-piece cylinder"); return
			# Check the ACTUAL shoulder-cap vertices in local sleeve space:
			# the previous overwide top ellipse produced a sharp triangular
			# floating shoulder above the garment in orthographic screenshots.
			var upper_min_x: float=INF
			var upper_max_x: float=-INF
			for point in vertices:
				if point.y>=.013:
					upper_min_x=minf(upper_min_x,point.x)
					upper_max_x=maxf(upper_max_x,point.x)
			if upper_min_x==INF or upper_max_x-upper_min_x>.101:
				_fail("Shoulder cap regressed to a swollen triangular deltoid")
				return
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
			# Reject visually oversized paddle palms while keeping all
			# individually modeled digits and original severable limb identity.
			var palm_width: float=hand.get_aabb().size.x
			if palm_width<.069 or palm_width>.114:
				_fail("Individual hand reverted to an oversized mitten or tiny block")
				return
			if not (hand.mesh is ArrayMesh) or (
					not bool(hand.get_meta("anatomic_palm",false))) or (
					int(hand.get_meta("modeled_fingers",0))!=4):
				_fail("NPC's anatomical hand regressed to a spherical bead")
				return
			for finger in range(4):
				var digit: MeshInstance3D=elbow.get_node_or_null(
					"Finger"+str(finger)+"LowPolyPhalanges") as MeshInstance3D
				if digit==null or digit.mesh==null:
					_fail("Full hand is missing one of four individually modeled fingers")
					return
				if not (digit.mesh is ArrayMesh) or (
						not bool(digit.get_meta("three_section_anatomical_digit",false))) or (
						digit.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX].size()<110):
					_fail("Anatomical fingers reverted to rigid primitive cylinders")
					return
			if elbow.get_node_or_null("AnatomicalThumbMetacarpal")==null or (
					elbow.get_node_or_null("AnatomicalThumbDistal")==null):
				_fail("Hand is missing its angled two-bone thumb")
				return
			if not bool(hand.get_meta("faceted_curved_digits",false)):
				_fail("Hand reverted to four rigid fingers")
				return
			var thumb: MeshInstance3D=elbow.get_node(
				"AnatomicalThumbMetacarpal") as MeshInstance3D
			if not (thumb.mesh is ArrayMesh):
				_fail("Thumb regressed to rigid cylinder")
				return
			if not hand.find_children("*","CollisionShape3D",true,false).is_empty():
				_fail("Decorative hand added duplicate physical collision")
				return
			if not bool(mesh.get_meta("detaches_with_parent_arm",false)):
				_fail("Forearm does not detach with its upper arm"); return
			var length: float=float(mesh.get_meta("inherited_wrist_reach",0.0))
			if absf(length-load("res://scripts/npc_genetics.gd").forearm_length(
					genome))>.002:
				_fail("Arm length ignores actual inherited limb ratio"); return
			var hand_drop: float=arm.to_local(hand.global_position).y
			if hand_drop>-.49 or hand_drop<-.67:
				_fail("Fingertips are back at knee level or arms too short"); return
			var area: Area3D=citizen.limb_hitboxes[side.to_lower()+"_arm"]
			var capsule: CollisionShape3D=area.get_child(0) as CollisionShape3D
			var expected_reach: float=load("res://scripts/npc_genetics.gd").upper_arm_length(genome)+load("res://scripts/npc_genetics.gd").forearm_length(genome)+.185
			if capsule==null or not (capsule.shape is CapsuleShape3D) or (
					absf((capsule.shape as CapsuleShape3D).height-expected_reach)>.012):
				_fail("Genetic arm hitbox no longer matches its real reach"); return
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
		var shoulder_socket: float=.024+(
			.80 if sex=="female" else .87)*genetic_body._section(
			1.365,gg,sex).x
		var femur_socket: float=.455*genetic_body._section(.78,gg,sex).x
		if absf(citizen.left_arm.position.x+shoulder_socket)>.007 or (
				absf(citizen.left_arm.position.y-1.405)>.007) or (
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
			var knee: Node3D=original_leg.get_node_or_null(
				"AnatomicalKneeHinge") as Node3D if original_leg!=null else null
			var calf: MeshInstance3D=knee.get_node_or_null(
				"InheritedCalfAndShin") as MeshInstance3D if knee!=null else null
			var boot: MeshInstance3D=knee.get_node_or_null(
				"GeneticAnkleBoot") as MeshInstance3D if knee!=null else null
			if original_leg==null or trousers==null or knee==null or calf==null or boot==null:
				_fail("Original severable leg lost its knee, shin or attached boot"); return
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
			# Catch the exact stubby-leg regression in actual generated vertex
			# bounds, not only an invisible "long legs" metadata flag.
			var pants_bounds: AABB=trousers.get_aabb()
			if original_leg.position.y<.95 or pants_bounds.size.y<.52 or (
					knee.position.y>-.39 or
					calf.get_aabb().position.y+knee.position.y>-.82):
				_fail("Femur, shin or anatomical knee reverted to a short rigid cylinder")
				return
			var sole_y: float=original_leg.position.y+knee.position.y+foot_bounds.position.y
			if absf(sole_y-.012)>.055:
				_fail("Full-length boot no longer contacts the actual ground")
				return
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
	if smith_points.size()<2500 or smith_apron.get_aabb().size.y<.75:
		_fail("Smith apron lacks torso-following geometry"); return
	var smith_genome: Dictionary=world.village_sim.people["orin"]["genome"]
	for index in range(0,smith_points.size(),3):
		var p: Vector3=(smith_points[index]+smith_points[index+1]+
			smith_points[index+2])/3.0
		var section: float=genetic_body._section(p.y,smith_genome,String(world.village_sim.people["orin"]["sex"])).x
		var angle: float=-PI*.5+asin(clampf(p.x/section,-.91,.91))
		var smith_front: float=genetic_body._point(p.y,angle,smith_genome,
			String(world.village_sim.people["orin"]["sex"])).z
		var smith_clearance: float=smith_front-p.z
		if smith_clearance<.017 or smith_clearance>.073:
			_fail("Blacksmith apron is clipping or floating away from inherited torso"); return
	# Verify the *mesh* rather than a waist-taper metadata promise:
	# a smith's chest bib should cinch at the belt instead of a slab that
	# masks the inherited waist for every citizen.
	var smith_waist: float=0.0
	var smith_lower: float=0.0
	for point in smith_points:
		if absf(point.y-1.02)<.012:
			smith_waist=maxf(smith_waist,absf(point.x))
		if point.y<.60:
			smith_lower=maxf(smith_lower,absf(point.x))
	if smith_waist<=.01 or smith_lower<smith_waist*1.28:
		_fail("Smith's apron still reads as an oversized leather rectangle")
		return
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
		# A separate face patch, inherited nose and legacy skull occupied
		# overlapping volume. Their dynamic self-shadowing previously
		# turned light and dark skin alike into an opaque shadow mask.
		var skull: MeshInstance3D=citizen.find_child(
			"ModeledInhabitantHead",true,false) as MeshInstance3D
		var nasal_tip: MeshInstance3D=portrait.get_node_or_null(
			"ModeledNoseTip") as MeshInstance3D
		for layer in [sculpt,skull,nasal_tip]:
			if layer==null or layer.cast_shadow!=(
					GeometryInstance3D.SHADOW_CASTING_SETTING_OFF):
				_fail("Overlapping sculpted head layer casts black self-shadow")
				return
		var verts: PackedVector3Array=sculpt.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
		if verts.size()<3800:
			_fail("The face lost its continuous high-detail cheek/eye/nose topology")
			return
		# The real face gallery at source e7326e46 had nearly black
		# forehead/cheeks and eye sockets, despite passing mesh checks.
		# Protect lighting normals as well as mesh density: the smooth
		# front-facing face must not go grazing over its visible centre.
		var face_normals: PackedVector3Array=sculpt.mesh.surface_get_arrays(0)[
			Mesh.ARRAY_NORMAL]
		if face_normals.size()!=verts.size():
			_fail("Face surface has no matching explicit lighting normals")
			return
		for index in range(verts.size()):
			var point: Vector3=verts[index]
			var normal: Vector3=face_normals[index]
			if absf(point.x)>.13 or point.y<1.63 or point.y>1.89:
				continue
			if normal.z>-.94:
				_fail("Face gradients create black mask-like shading")
				return
		# SurfaceTool triangle winding determines the actual light-facing
		# normal. Previously lip, brow, nose and upper eyelid strips faced
		# INTO the head, producing dark patches and white faceted bars in
		# real Godot close-ups despite passing all topology tests.
		for feature_name in ["SmallNaturalLipLine","ModeledLowerLipLeft",
				"NaturalLipCorner","ExpressionUpperBlinkCover",
				"ExpressionLowerBlinkCover","InheritedBrow","ModeledNoseTip"]:
			var feature: MeshInstance3D=portrait.find_child(
				feature_name,true,false) as MeshInstance3D
			if feature==null or feature.mesh==null:
				_fail("Face lost anatomical surface: "+feature_name); return
			var normals: PackedVector3Array=feature.mesh.surface_get_arrays(0)[
				Mesh.ARRAY_NORMAL]
			if normals.size()<24:
				_fail("Face feature has no real shaded triangle normals: "+feature_name)
				return
			var visible_normals: int=0
			for normal in normals:
				if normal.z<-.15:
					visible_normals+=1
			if visible_normals<float(normals.size())*.64:
				_fail("Face strip backfaces away from camera: "+feature_name)
				return
		# The last published close-ups showed a hard rectangular jaw shelf.
		# Evaluate true face mesh: chin edges must tuck inward below cheek.
		var widest_cheek: float=0.0
		var bottom_chin: float=0.0
		for vertex in verts:
			if absf(vertex.y-1.75)<.014:
				widest_cheek=maxf(widest_cheek,absf(vertex.x))
			if vertex.y<1.595:
				bottom_chin=maxf(bottom_chin,absf(vertex.x))
		if widest_cheek<.12 or bottom_chin>=widest_cheek*.89:
			_fail("Face returned to its flat rectangular jaw shelf"); return
		# At eyebrow height the mesh remains broad, but its forehead
		# corners must roll inward under the crown. A full-width straight
		# top edge is the rectangular mask visible in real close-ups.
		var middle_outline: float=0.0
		var crown_outline: float=0.0
		for p in verts:
			if absf(p.y-1.840)<.009:
				middle_outline=maxf(middle_outline,absf(p.x))
			if p.y>1.918:
				crown_outline=maxf(crown_outline,absf(p.x))
		if middle_outline<.12 or crown_outline>=middle_outline*.94:
			_fail("Inherited forehead did not curve into the skull"); return
		var lip_node: Node3D=portrait.get_node_or_null("ExpressionMouth")
		var top_lip: MeshInstance3D=lip_node.get_node_or_null(
			"ExpressionLipLeft/SmallNaturalLipLine") as MeshInstance3D if lip_node!=null else null
		var lower_lip: MeshInstance3D=lip_node.get_node_or_null(
			"ExpressionLowerLip/ModeledLowerLipLeft") as MeshInstance3D if lip_node!=null else null
		var crease: MeshInstance3D=lip_node.get_node_or_null(
			"ExpressionMouthOpening") as MeshInstance3D if lip_node!=null else null
		if top_lip==null or lower_lip==null or crease==null or not crease.visible:
			_fail("Neutral face lost its thin continuous oral crease"); return
		if top_lip.get_aabb().size.y>.034 or lower_lip.get_aabb().size.y>.031:
			_fail("Lip masses regressed to oversized four-petal geometry"); return
		for part_name in ["SmallRecessedEye","IndividualUpperEyelid",
				"AnatomicalLowerEyelid","InheritedBrow","InheritedCheekboneFacet",
				"ModeledNoseWing","SmallNaturalLipLine"]:
			var facial_part: MeshInstance3D=portrait.find_child(
				part_name,true,false) as MeshInstance3D
			if facial_part==null or facial_part.cast_shadow!=(
					GeometryInstance3D.SHADOW_CASTING_SETTING_OFF):
				_fail("Decorative face mesh casts artificial under-eye shadows: "+
					part_name)
				return
		# Verify skin-attached folds on the real inherited face, not only
		# metadata or a decorative separate brow cylinder. Both eyes and both
		# expression rigs must remain independently animated.
		var face_math=load("res://scripts/folk_portrait_finish.gd")
		var person_genome: Dictionary=world.village_sim.people[
			String(citizen.npc_id)]["genome"]
		var person_sex: String=String(world.village_sim.people[
			String(citizen.npc_id)]["sex"])
		for eye_name in ["ExpressionEyeLeft","ExpressionEyeRight"]:
			var socket: Node3D=portrait.get_node_or_null(eye_name)
			if socket==null:
				_fail("Inherited face lost one of its articulated eye sockets"); return
			var sclera: MeshInstance3D=socket.get_node_or_null(
				"SmallRecessedEye") as MeshInstance3D
			if sclera==null or sclera.scale.x<.051:
				_fail("NPC eyes shrank back to the old unreadable bead size"); return
			for lid_name in ["IndividualUpperEyelid","AnatomicalLowerEyelid"]:
				var fold: MeshInstance3D=socket.get_node_or_null(
					lid_name) as MeshInstance3D
				if fold==null or fold.mesh==null or not bool(
						fold.get_meta("attached_to_inherited_face",false)):
					_fail("Skin-attached eye fold replaced by floating strip"); return
				var fold_points: PackedVector3Array=fold.mesh.surface_get_arrays(0)[
					Mesh.ARRAY_VERTEX]
				if fold_points.size()<100:
					_fail("Eye socket lost its tapered sculpted geometry"); return
				for p in fold_points:
					var skin_z: float=face_math._depth(
						socket.position.x+p.x,socket.position.y+p.y,
						person_genome,person_sex)
					var relief: float=skin_z-(socket.position.z+p.z)
					if relief<-.003 or relief>.022:
						_fail("Eyelid fold floats off inherited facial contour"); return
		for brow_name in ["ExpressionBrowLeft","ExpressionBrowRight"]:
			var brow_rig: Node3D=portrait.get_node_or_null(brow_name)
			var brow_mesh: MeshInstance3D=brow_rig.get_node_or_null(
					"InheritedBrow") as MeshInstance3D if brow_rig!=null else null
			if brow_mesh==null or brow_mesh.mesh==null or not bool(
						brow_mesh.get_meta("attached_to_inherited_brow_bone",false)):
				_fail("Expressive inherited brow returned to floating straight line"); return
		if portrait.find_children("*","StaticBody3D",true,false).size()>0:
			_fail("An artistic face introduced unnecessary collision")
			return
	# Verify gait changes the actual articulated shoulders without moving
	# physics or replacing the original independently severable arm nodes.
	var shoulder_at_rest: float=ida.left_arm.rotation.z
	ida.gait_weight=.9
	ida.distance_gait_phase=PI*.30
	ida.motion_clock=1.33
	ida._pose_upper_body(.18,true,false,false)
	if absf(ida.left_arm.rotation.z-shoulder_at_rest)<.002 or (
		absf(ida.visual_figure.rotation.y)<.008):
		_fail("NPC remains mannequin-rigid despite walking gait"); return
	ida._pose_upper_body(.18,false,false,true)
	if ida.modular_limbs.get("left_arm")!=ida.left_arm:
		_fail("Procedural animation replaced the original detachable arm"); return
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
	# Three real hairstyle generators should clear clothes at the ends of
	# the locks. Previously the strands were geometrically valid but
	# disappeared into the chest and back of every walking villager.
	for person_name in ["sela","mara","juno"]:
		var groom_root:=Node3D.new()
		root.add_child(groom_root)
		var inherited: Dictionary=GENES.founder(person_name)
		var finish: Node3D=GROOM.finish(groom_root,person_name,inherited,
			"female",ART_LIB.mat(GENES.hair_color(inherited),.98))
		# Long loose hair now flows into the BACK panel, while short
		# temple framing stops at the jaw rather than dangling as planks.
		# Braids deliberately remain forward of the garment.
		var strand_name: String="FacetedBackHairPanel2" if person_name=="sela" else (
			"WovenLeftHairCore" if person_name=="mara" else "LongPonytailTail1")
		var strand: MeshInstance3D=finish.get_node_or_null(
			strand_name) as MeshInstance3D
		if not _long_lock_clears_tunic(strand,person_name=="mara"):
			_fail("Long hairstyle disappears into clothing: "+person_name)
			return
		if person_name=="sela":
			var temple_panel: MeshInstance3D=finish.get_node_or_null(
				"FacetedLeftHairFrame") as MeshInstance3D
			if temple_panel==null or temple_panel.mesh==null:
				_fail("Loose hairstyle lost scalp-attached temple framing"); return
			var lowest_temple: float=100.0
			for v in temple_panel.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]:
				lowest_temple=minf(lowest_temple,v.y)
			if lowest_temple<1.66:
				_fail("Loose side fringe became a hanging cardboard plank"); return
			# A front-facing hair sheet disappears edge-on. Verify actual
			# three-dimensional thickness at the MIDDLE of the strand, not
			# a marker that claims to have solid geometry.
			for hair_panel in [temple_panel,strand]:
				var vertices: PackedVector3Array=hair_panel.mesh.surface_get_arrays(0)[
					Mesh.ARRAY_VERTEX]
				var top_y: float=-1000.0
				var low_y: float=1000.0
				for v in vertices:
					top_y=maxf(top_y,v.y)
					low_y=minf(low_y,v.y)
				var middle_y: float=lerpf(top_y,low_y,.52)
				var backmost: float=-1000.0
				var foremost: float=1000.0
				for v in vertices:
					if absf(v.y-middle_y)<.055:
						backmost=maxf(backmost,v.z)
						foremost=minf(foremost,v.z)
				if backmost-foremost<.022:
					_fail("Hair is still a paper-thin floating polygon"); return
		if finish.find_children("*","CollisionShape3D",true,false).size()>0:
			_fail("Grooming added a new body collision or blocked limb severance")
			return
		if person_name=="sela":
			var left_frame: MeshInstance3D=finish.get_node_or_null(
				"FacetedLeftHairFrame") as MeshInstance3D
			var frame_points: PackedVector3Array=left_frame.mesh.surface_get_arrays(0)[
				Mesh.ARRAY_VERTEX]
			# Hair length is inherited: compare the real mesh at its own
			# middle and end instead of assuming an absolute world Y.
			var bottom_y: float=1000.0
			var top_y: float=-1000.0
			for p in frame_points:
				bottom_y=minf(bottom_y,p.y)
				top_y=maxf(top_y,p.y)
			var midpoint_y: float=lerpf(top_y,bottom_y,.55)
			var mid_min: float=1000.0
			var mid_max: float=-1000.0
			var hem_min: float=1000.0
			var hem_max: float=-1000.0
			for p in frame_points:
				if absf(p.y-midpoint_y)<.052:
					mid_min=minf(mid_min,p.x)
					mid_max=maxf(mid_max,p.x)
				if p.y<bottom_y+.012:
					hem_min=minf(hem_min,p.x)
					hem_max=maxf(hem_max,p.x)
			if mid_max<=mid_min or hem_max<=hem_min or (
					hem_max-hem_min)>.74*(mid_max-mid_min):
				_fail("Long side hair has blunt rectangular ends again"); return
			var back: MeshInstance3D=finish.get_node_or_null(
				"FacetedBackHairPanel2") as MeshInstance3D
			if not _long_lock_clears_tunic(back,false):
				_fail("Loose long hair still penetrates the fitted back")
				return
	print("PASS: fitted villager bodies, individual face anatomy, distance-aware rigging and baker apron preserve distinct worker appearance")
	quit(0)
