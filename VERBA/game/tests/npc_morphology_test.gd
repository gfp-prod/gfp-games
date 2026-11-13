extends SceneTree
## Headless model acceptance: genes must become independently visible anatomy,
## while no mesh introduces collisions or severs the physical limb modules.
const GENES=preload("res://scripts/npc_genetics.gd")
const FACE=preload("res://scripts/folk_portrait_finish.gd")
const BODY=preload("res://scripts/npc_body_morph.gd")
const COSTUME=preload("res://scripts/folk_costume_finish.gd")
const ART=preload("res://scripts/art.gd")

func _initialize() -> void:
	call_deferred("_run")

func _fail(why: String) -> void:
	push_error("VERBA detailed inheritable models: "+why)
	quit(1)

func _run() -> void:
	var a: Dictionary=GENES.founder("ida")
	var b: Dictionary=GENES.founder("orin")
	var child: Dictionary=GENES.child(a,b,"born_0001")
	if not GENES.validate(a) or not GENES.validate(b) or not GENES.validate(child):
		_fail("Expanded genome is invalid") ; return
	# Facial-hair growth is a true two-parent genotype, not a name or
	# costume lookup. The face must create different 3D facial surfaces
	# from the same loci without a second physical head/hitbox.
	var dense: Dictionary=a.duplicate(true)
	for locus in ["facial_hair_density","facial_hair_length",
			"facial_hair_pattern","mustache_weight","sideburn_weight"]:
		dense["alleles"][locus]=[940,940]
	var shaved: Dictionary=dense.duplicate(true)
	shaved["alleles"]["facial_hair_density"]=[30,30]
	if GENES.beard_profile(dense,"male",30.0)["style"]=="clean":
		_fail("Dominant inherited facial hair alleles never grow a beard")
		return
	if GENES.beard_profile(shaved,"male",30.0)["style"]!="clean":
		_fail("Facial hair density did not suppress beard growth")
		return
	if GENES.beard_profile(dense,"male",9.0)["style"]!="clean":
		_fail("Child with adult facial hair genotype grew an adult beard")
		return
	var beard_root:=Node3D.new()
	root.add_child(beard_root)
	var dark_hair:=ART.mat(GENES.hair_color(dense),.97)
	FACE.finish(beard_root,"portrait_reference",
		ART.mat(GENES.skin_color(dense),.96),dark_hair,dark_hair,
		dense,"male")
	var beard_geometry: MeshInstance3D=beard_root.find_child(
		"GeneticFacialHairChin",true,false) as MeshInstance3D
	if beard_geometry==null or beard_geometry.mesh==null:
		_fail("Inherited facial hair has no actual low-poly beard geometry")
		return
	if beard_geometry.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX].size()<70:
		_fail("Beard regressed to an unsupported billboard or empty mesh")
		return
	if beard_geometry.find_children("*","CollisionShape3D",true,false).size()>0:
		_fail("Facial hair incorrectly adds a new physical collision")
		return
	# The first 28 inherited alleles are exactly those from the prior game.
	var legacy: Dictionary=a.duplicate(true)
	legacy["version"]=1
	for key in GENES.EXTRA_MORPH_TRAITS+GENES.GROOM_TRAITS:
		legacy["alleles"].erase(key)
	# v2 player saves already have the body traits but not the beard genes.
	var old_v2: Dictionary=a.duplicate(true)
	old_v2["version"]=2
	for groom_locus in GENES.GROOM_TRAITS:
		old_v2["alleles"].erase(groom_locus)
	var upgraded_v2: Dictionary=GENES.upgrade(old_v2,"ida")
	if not GENES.validate(upgraded_v2):
		_fail("An existing v2 save cannot upgrade to facial hair genetics")
		return
	for inherited_locus in GENES.TRAITS:
		if inherited_locus in GENES.GROOM_TRAITS: continue
		if upgraded_v2["alleles"][inherited_locus]!=a["alleles"][inherited_locus]:
			_fail("New grooming genes overwrote an old physique gene")
			return
	var migrated: Dictionary=GENES.upgrade(legacy,"ida")
	if not GENES.validate(migrated):
		_fail("A saved v1 genome cannot migrate safely"); return
	for locus in GENES.TRAITS:
		if locus in GENES.EXTRA_MORPH_TRAITS or locus in GENES.GROOM_TRAITS:
			continue
		if migrated["alleles"][locus]!=a["alleles"][locus]:
			_fail("Migration changed an old inherited allele "+locus); return
	for locus in GENES.EXTRA_MORPH_TRAITS:
		if child["alleles"][locus].size()!=2:
			_fail("New body locus is not inherited: "+locus); return
		var transmitted: int=int(child["alleles"][locus][0])
		var parents: Array=a["alleles"][locus]
		if minf(absf(transmitted-float(parents[0])),
				absf(transmitted-float(parents[1])))>45:
			_fail("Child chest or face trait broke parental inheritance: "+locus); return
	# Compare exactly the same two-allele genome with two average adult
	# anatomical expressions. If there is no pronounced change in the
	# shoulder/pelvis or waist/pelvis ratios, the *visible* body shape is
	# still effectively unisex, however different its height may be.
	var same_genome: Dictionary=GENES.founder("adult-anatomy-reference",1938)
	# Median alleles let us independently detect unintentional universal
	# bulk without banning naturally wide-hipped or muscular bloodlines.
	for locus in ["stature","shoulder_width","chest_width",
			"waist_width","hip_width","body_depth","muscle_tone","bust_volume"]:
		same_genome["alleles"][locus]=[500,500]
	var female_hip: float=BODY._section(.80,same_genome,"female").x
	var male_hip: float=BODY._section(.80,same_genome,"male").x
	# Realistic average characters should not look wider than their
	# upper torso is tall. This detects the last pass's stocky, tent-like
	# baseline while retaining the separate feminine/masculine ratios.
	if female_hip>.285 or male_hip>.265 or (
			BODY._section(1.10,same_genome,"female").x>.214) or (
			BODY._section(1.10,same_genome,"male").x>.248):
		_fail("Average inherited anatomy regressed to the old husky silhouette")
		return
	# Compare genuine inherited finger geometry against the shoulder. A
	# shorter forearm alone can leave a visually overlong upper-arm assembly.
	for allele in [0,500,1000]:
		var inherited: Dictionary=same_genome.duplicate(true)
		inherited["alleles"]["limb_ratio"]=[allele,allele]
		var arm_root:=Node3D.new()
		root.add_child(arm_root)
		var sleeve:=COSTUME.fitted_sleeve(arm_root,1.0,inherited,
			ART.mat(Color("746b5b"),.97),"male")
		var elbow:=Node3D.new()
		elbow.position=Vector3(.040,-GENES.upper_arm_length(inherited),-.035)
		arm_root.add_child(elbow)
		COSTUME.fitted_forearm(elbow,1.0,inherited,
			ART.mat(Color("746b5b"),.97),
			ART.mat(GENES.skin_color(inherited),.96))
		var index_finger: MeshInstance3D=elbow.get_node_or_null(
			"Finger1LowPolyPhalanges") as MeshInstance3D
		if sleeve==null or sleeve.mesh==null or index_finger==null:
			_fail("Inherited articulated arm geometry is missing")
			return
		var tip: float=elbow.position.y+index_finger.get_aabb().position.y
		if tip<-.81 or tip>-.63:
			_fail("Inherited arm fingertips extend below the thigh or are stubby")
			return
	# Keep inherited ratios even as we narrow the average human mesh.
	# A broad bloodline remains broad by genotype, not by clothing.
	# Test vertical slenderness rather than simply shrinking all
	# anatomy: average adults should not be shorter than their rendered
	# body-width multiplier, even before the inherited waist sculpt.
	for profile in ["female","male"]:
		var proportion: Vector3=GENES.body_scale(same_genome,profile)
		if proportion.y/proportion.x<1.045:
			_fail("Average torso is squat despite lean geometric radii")
			return
		var widest_hip: float=BODY._section(.78,same_genome,profile).x
		var hem: float=BODY._section(.61,same_genome,profile).x
		if widest_hip-hem<.015:
			_fail("Tunic hem still extrudes a barrel-shaped pelvis")
			return
	var female_shoulder: float=BODY._section(1.365,same_genome,"female").x
	var male_shoulder: float=BODY._section(1.365,same_genome,"male").x
	var female_waist: float=BODY._section(1.10,same_genome,"female").x
	var male_waist: float=BODY._section(1.10,same_genome,"male").x
	if female_hip<=male_hip*1.055 or female_shoulder>=male_shoulder*.985:
		_fail("Shoulder and pelvic regions still have the same adult profiles")
		return
	if female_shoulder/female_hip>=male_shoulder/male_hip-.11:
		_fail("The skeletal shoulder-to-hip proportion is visibly unisex")
		return
	if female_waist/female_hip>=male_waist/male_hip-.09:
		_fail("The waist-to-pelvis taper is visually indistinguishable")
		return
	var female_shirt_node:=Node3D.new()
	var male_shirt_node:=Node3D.new()
	root.add_child(female_shirt_node)
	root.add_child(male_shirt_node)
	var shirt_color:=ART.mat(Color("746b5b"),.97)
	var woman_mesh: MeshInstance3D=BODY.finish(
		female_shirt_node,same_genome,shirt_color,false,"female")
	var man_mesh: MeshInstance3D=BODY.finish(
		male_shirt_node,same_genome,shirt_color,false,"male")
	if woman_mesh.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]==(
			man_mesh.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]):
		_fail("Sex-linked morphology still creates identical actual mesh vertices")
		return
	# The earlier side-view baker had a rigid spear-shaped bust apron,
	# despite her waist and hip ratios being correct. Inspect the actual
	# midline shirt projection, not just the saved bust-volume allele.
	var baseline_front: Vector3=BODY._point(1.265,-PI*.5,
		same_genome,"female")
	var baseline_rib: float=BODY._section(1.265,same_genome,"female").y
	var baseline_projection: float=-baseline_front.z-baseline_rib
	if baseline_projection<.025 or baseline_projection>.083:
		_fail("Typical inherited female torso has an implausibly flat or projecting chest")
		return
	var high_bust_genome: Dictionary=same_genome.duplicate(true)
	high_bust_genome["alleles"]["bust_volume"]=[970,970]
	var high_projection: float=-BODY._point(1.265,-PI*.5,
		high_bust_genome,"female").z-baseline_rib
	if high_projection<=baseline_projection+.036 or high_projection>.148:
		_fail("Inherited bust shape is either not expressed or protrudes as a rigid shield")
		return
	# Silhouette-only waist ratios are not enough: the last models still
	# looked like featureless oval cylinders from three-quarter angles.
	# Compare the finished front/back/side contour to each inherited oval.
	# The checks use one fixed median bloodline and independent sexes.
	for sex_profile in ["female","male"]:
		var front_rib: Vector3=BODY._point(1.355,-PI*.5,
			same_genome,sex_profile)
		var front_oval: float=BODY._section(1.355,
			same_genome,sex_profile).y
		if front_rib.z>=-front_oval-.008:
			_fail("No sternum projection: torso still a cylindrical ribcage")
			return
		var blade_angle: float=PI*.33
		var upper_back: Vector3=BODY._point(1.315,blade_angle,
			same_genome,sex_profile)
		var plain_back: float=sin(blade_angle)*BODY._section(
			1.315,same_genome,sex_profile).y
		if upper_back.z<=plain_back+.006:
			_fail("Scapula is absent from the actual three-quarter back")
			return
		var flank: Vector3=BODY._point(1.105,0.0,
			same_genome,sex_profile)
		var oval_waist: float=BODY._section(1.105,
			same_genome,sex_profile).x
		if flank.x>=oval_waist-.004:
			_fail("Oblique waist never interrupts cylindrical side profile")
			return
	# Increased density is concentrated at real contour transitions, not
	# spread indiscriminately across a massive primitive torso.
	for finished in [woman_mesh,man_mesh]:
		var arrays: Array=finished.mesh.surface_get_arrays(0)
		var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
		var normals: PackedVector3Array=arrays[Mesh.ARRAY_NORMAL]
		if vertices.size()<2800 or vertices.size()!=normals.size():
			_fail("Torso sculpt lost the support rings or normals")
			return
	# A past art pass hid the full femur under a single cylindrical robe,
	# even while the leg code and its unit tests passed. Verify the ACTUAL
	# generated shirt vertices and the length of the same severable leg mesh.
	for garment in [woman_mesh,man_mesh]:
		var lowest_shirt: float=INF
		for point in garment.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]:
			lowest_shirt=minf(lowest_shirt,point.y)
		if lowest_shirt<.79 or lowest_shirt>.84:
			_fail("Clothing regressed to a long shin-hiding torso cylinder")
			return
	var leg_stage:=Node3D.new()
	root.add_child(leg_stage)
	var thigh:=COSTUME.fitted_lower_leg(leg_stage,1.0,
		same_genome,"female")
	var upper_bounds: AABB=thigh.get_aabb()
	var knee: Node3D=leg_stage.get_node_or_null(
		"AnatomicalKneeHinge") as Node3D
	if knee==null or not bool(knee.get_meta("detaches_with_original_leg",false)):
		_fail("Shin has no knee pivot parented beneath the original leg")
		return
	var shin: MeshInstance3D=knee.get_node_or_null(
		"InheritedCalfAndShin") as MeshInstance3D
	var boot: MeshInstance3D=knee.get_node_or_null(
		"GeneticAnkleBoot") as MeshInstance3D
	if shin==null or boot==null or upper_bounds.position.y>-.46 or (
			upper_bounds.end.y<.05):
		_fail("Femur, hinged calf, or floor-contact boot was lost")
		return
	if shin.get_aabb().position.y+knee.position.y>-.83:
		_fail("Animated shin no longer reaches the ankle")
		return
	if boot.get_aabb().position.y+knee.position.y>-.955:
		_fail("Animated boot no longer meets the physical ground")
		return
	var toe: Vector3=Vector3(.0,-.50,-.13)
	var before_bend: Vector3=knee.to_global(toe)
	knee.rotation.x=.55
	var after_bend: Vector3=knee.to_global(toe)
	if before_bend.distance_to(after_bend)<.10:
		_fail("Shin/boot pivot exists but cannot visibly bend")
		return
	if not leg_stage.find_children("*","CollisionShape3D",true,false).is_empty():
		_fail("A second physical limb was added by knee art")
		return
	# Facial differences must live in the sculpted continuous mesh too,
	# not only the person's hair or hat. Inherited anatomy remains visible
	# using a single fixed genome and identical skin, hair and expressions.
	var female_face_root:=Node3D.new()
	var male_face_root:=Node3D.new()
	root.add_child(female_face_root)
	root.add_child(male_face_root)
	var comparable_skin:=ART.mat(GENES.skin_color(same_genome),.96)
	var comparable_hair:=ART.mat(GENES.hair_color(same_genome),.95)
	FACE.finish(female_face_root,"reference",comparable_skin,comparable_hair,
		comparable_hair,same_genome,"female")
	FACE.finish(male_face_root,"reference",comparable_skin,comparable_hair,
		comparable_hair,same_genome,"male")
	var female_face: MeshInstance3D=female_face_root.find_child(
		"IndividualIntegratedFaceMesh",true,false) as MeshInstance3D
	var male_face: MeshInstance3D=male_face_root.find_child(
		"IndividualIntegratedFaceMesh",true,false) as MeshInstance3D
	if female_face==null or male_face==null or female_face.mesh==null:
		_fail("Anatomic face profile is missing its continuous sculpted mesh")
		return
	if female_face.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]==(
			male_face.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]):
		_fail("Sex-linked faces share a completely identical skull geometry")
		return
	var female_brow: float=FACE._depth(.075,1.824,same_genome,"female")
	var male_brow: float=FACE._depth(.075,1.824,same_genome,"male")
	if male_brow>=female_brow-.003:
		_fail("The facial brow ridge ignored its anatomical variation")
		return

	if float(woman_mesh.get_meta("anatomic_shoulder_hip_ratio",9.0))>=float(
			man_mesh.get_meta("anatomic_shoulder_hip_ratio",0.0))-.11:
		_fail("Anatomy changes only metadata, not the visible torso surface")
		return
	# Preserve overlap between populations: unusually broad-shouldered
	# women and narrow-framed men must still be possible via their genes.
	var large: Dictionary=same_genome.duplicate(true)
	var small: Dictionary=same_genome.duplicate(true)
	for locus in ["stature","shoulder_width","chest_width","hip_width"]:
		large["alleles"][locus]=[980,980]
		small["alleles"][locus]=[20,20]
	if GENES.body_scale(large,"female").y<=GENES.body_scale(small,"male").y:
		_fail("Inherited large female bloodline cannot exceed a short male")
		return
	if BODY._section(1.365,large,"female").x<=BODY._section(
			1.365,small,"male").x:
		_fail("Female shoulder genes are overridden by a rigid sex template")
		return
	# The inherited garment must slope continuously into the neckline.
	# A single narrow upper ring used to form a hard, oversized collar;
	# a separate neck cylinder then made the torso appear assembled.
	for genome in [a,b,child]:
		var lower_shoulder: float=BODY._section(1.43,genome).x
		var slope_midpoint: float=BODY._section(1.50,genome).x
		var neck: float=BODY._section(1.575,genome).x
		if not (lower_shoulder>slope_midpoint and slope_midpoint>neck):
			_fail("Inherited neck/shoulder fabric forms a rigid ledge"); return
		for height in [.78,1.10,1.31,1.43]:
			var below: Vector2=BODY._section(height-.002,genome)
			var above: Vector2=BODY._section(height+.002,genome)
			if below.distance_to(above)>.018:
				_fail("Genetic torso surface tears at a section boundary")
				return
	var figures: Array[Node3D]=[]
	for record in [a,b,child]:
		var figure:=Node3D.new()
		root.add_child(figure)
		figures.append(figure)
		var skin:=ART.mat(GENES.skin_color(record),.96)
		var hair:=ART.mat(GENES.hair_color(record),.95)
		FACE.finish(figure,"citizen",skin,hair,hair,record)
		var clothing:=ART.mat(Color("887765"),.99)
		var body: MeshInstance3D=BODY.finish(figure,record,clothing)
		if body==null or body.mesh==null or body.mesh.get_surface_count()!=1:
			_fail("Inherited ribcage, waist and hips were not modeled"); return
		if body.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX].size()<600:
			_fail("Body reverted to one primitive cone"); return
		# The upper cloth must actually stop below the face. Sampling a
		# theoretical _section alone never detected the visible high collar.
		var body_vertices: PackedVector3Array=body.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
		var top_y: float=-INF
		for vertex in body_vertices:
			top_y=maxf(top_y,vertex.y)
		if top_y>1.515 or not bool(body.get_meta("natural_open_neckline",false)):
			_fail("A tall fabric cylinder has returned underneath the jaw"); return
		var expected: Array[String]=[
			"IndividualIntegratedFaceMesh","SmallRecessedEye","InheritedIris",
			"AnatomicalPupil","IndividualUpperEyelid",
			"AnatomicalLowerEyelid","ModeledNoseTip","ModeledNoseWing",
			"InheritedNostril","InheritedCheekboneFacet",
			"SmallNaturalLipLine","ModeledLowerLipLeft",
			"NaturalLipCorner","ModeledLowerLipRight",
			"ExpressionBrowLeft","ExpressionBrowRight",
			"InheritedChestWaistHipCloth","IndividualAnatomicalNeck"]
		for name in expected:
			if figure.find_child(name,true,false)==null:
				_fail("New face or torso is missing real 3D geometry: "+name)
				return
		var neck: MeshInstance3D=figure.find_child(
			"IndividualAnatomicalNeck",true,false) as MeshInstance3D
		if neck==null or neck.mesh==null or not bool(
				neck.get_meta("inherited_neck_bridge",false)):
			_fail("Face has a floating chin without anatomical neck geometry"); return
		var neck_bounds: AABB=neck.get_aabb()
		if neck_bounds.position.y>1.46 or neck_bounds.end.y<1.64 or (
				neck_bounds.size.x<.24 or neck_bounds.size.x>.45):
			_fail("Neck bridge does not meet jaw and open garment"); return
		# Reject the old thick skin-colored pipe, even if its total bounding
		# box still reaches the individual jaw and chest correctly.
		var narrow_throat_half_width: float=0.0
		for neck_vertex in neck.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]:
			if absf(neck_vertex.y-1.565)<.002:
				narrow_throat_half_width=maxf(narrow_throat_half_width,
					absf(neck_vertex.x))
		if narrow_throat_half_width<.069 or narrow_throat_half_width>.128:
			_fail("Anatomical neck reverted to a stiff oversized throat cylinder")
			return
		if not figure.find_children("*","CollisionShape3D",true,false).is_empty():
			_fail("Decorative anatomy replaced modular-limb physics"); return
		var portrait: Node3D=figure.get_node("IndividualFaceConstruction")
		var left: Node3D=portrait.get_node("ExpressionBrowLeft")
		var inherited_y: float=float(left.get_meta("rest_y",-1.0))
		for i in range(20): FACE.expression(figure,-.7,.65,true,float(i)*.09)
		if absf(left.position.y-(inherited_y-.7*.016))>.017:
			_fail("Expression wiped out the actual inherited brow height")
			return
		var mouth: Node3D=portrait.get_node("ExpressionMouth")
		var opening: MeshInstance3D=mouth.get_node("ExpressionMouthOpening")
		FACE.expression(figure,-.05,0.0,true,.21)
		if not opening.visible:
			_fail("NPC lip rig cannot articulate spoken syllables"); return
		# A blink is a lid closure, not eye compression. The inherited
		# iris and sclera must keep their geometry while two fitted lids
		# meet across them. A recent visual pass made this an explicit gate.
		var eye: Node3D=portrait.get_node("ExpressionEyeLeft")
		var sclera: MeshInstance3D=eye.get_node("SmallRecessedEye")
		var sclera_size: Vector3=sclera.scale
		# At gameplay distance the feature must remain proportionate to
		# the skull. Genetic shape survives; minuscule bead-eyes do not.
		var portrait_skull: MeshInstance3D=figure.find_child(
			"IndividualIntegratedFaceMesh",true,false) as MeshInstance3D
		if portrait_skull==null or portrait_skull.mesh==null:
			_fail("Eye-to-face proportion has no sculpted head"); return
		var eye_ratio: float=sclera.get_aabb().size.x/(
			portrait_skull.get_aabb().size.x)
		if eye_ratio<.105 or eye_ratio>.28:
			_fail("Eye-to-head proportion is unreadable or cartoonishly oversized")
			return
		var natural_mouth: Node3D=portrait.get_node("ExpressionMouth")
		var upper_lip: MeshInstance3D=natural_mouth.find_child(
			"SmallNaturalLipLine",true,false) as MeshInstance3D
		if upper_lip==null or upper_lip.get_aabb().size.y<.009:
			_fail("The inherited mouth is too fine to read at camera distance")
			return
		var face_at_socket: float=FACE._depth(
			eye.position.x,eye.position.y,record)
		var ocular_standoff: float=face_at_socket-(
			eye.position.z+sclera.position.z-sclera.scale.z*.5)
		# An earlier eye rig made the face look mechanical: three bright
		# disconnected strips floated forward of the sculpted socket.
		if ocular_standoff<.003 or ocular_standoff>.018 or (
				sclera.scale.x<.044 or sclera.scale.x>.083):
			_fail("Inherited eye became a protruding mechanical eyeball")
			return
		var upper: Node3D=eye.get_node_or_null("ExpressionUpperBlinkCover")
		var lower_lid: Node3D=eye.get_node_or_null("ExpressionLowerBlinkCover")
		if upper==null or lower_lid==null:
			_fail("Individual eyes lack physical blink surfaces"); return
		var upper_rest: float=float(upper.get_meta("rest_y",-999.0))
		var lower_rest: float=float(lower_lid.get_meta("rest_y",999.0))
		for tick in range(20): FACE.expression(figure,0.0,1.0,false,0.0)
		if upper.position.y>upper_rest-.015 or lower_lid.position.y<lower_rest+.014:
			_fail("Eyelid covers did not articulate during a blink"); return
		if not is_equal_approx(eye.scale.y,1.0) or sclera.scale!=sclera_size:
			_fail("Blink deformed the entire eye and iris instead of the lids"); return
		for tick in range(20): FACE.expression(figure,0.0,0.0,false,0.0)
		var iris: MeshInstance3D=eye.get_node_or_null("InheritedIris")
		var pupil: MeshInstance3D=eye.get_node_or_null("AnatomicalPupil")
		if iris==null or pupil==null:
			_fail("Eyes lost their separately movable inherited iris/pupil"); return
		if iris.scale.x>=sclera.scale.x*.48 or (
				pupil.scale.x>=iris.scale.x*.60):
			_fail("Oversized iris and pupil obscure the inherited almond eye")
			return
		var sclera_rest: Vector3=sclera.position
		for tick in range(20):
			FACE.expression(figure,0.0,0.0,true,.7,Vector2(.006,-.003))
		if iris.position.x<.004 or pupil.position.x<.004 or (
			iris.position.distance_to(pupil.position)>.018) or (
			sclera.position!=sclera_rest):
			_fail("NPC eye gaze displaced the sclera or separated iris/pupil"); return
		for tick in range(20): FACE.expression(figure,0.0,0.0,false,0.0)
		if absf(upper.position.y-upper_rest)>.003:
			_fail("Anatomical blink did not reopen"); return
		var lower_lips: Node3D=mouth.get_node_or_null("ExpressionLowerLip")
		if lower_lips==null:
			_fail("Mouth has no independent lower lip or jaw"); return
		for tick in range(20): FACE.expression(figure,0.0,0.0,true,.21)
		if lower_lips.position.y>-.008:
			_fail("Speech did not open a genuine space between the lips"); return
		# The tip should actually emerge from the sculpted nasal bridge;
		# an old offset placed it behind the surface at most angles.
		var tip: MeshInstance3D=portrait.get_node("ModeledNoseTip")
		var nose_y: float=lerpf(1.704,1.732,GENES.value(record,"nose_bridge"))
		if tip.position.z>=FACE._depth(0.0,nose_y,record)-.005:
			_fail("The modeled nose tip is buried in its head"); return
	# Morphology acceptance must prove the lip-curve locus reaches geometry,
	# not merely exist in the saved genome. Vary ONLY that inherited locus.
	var flat_genes: Dictionary=GENES.founder("lip-curve-acceptance")
	var raised_genes: Dictionary=flat_genes.duplicate(true)
	flat_genes["alleles"]["lip_curve"]=[0,0]
	raised_genes["alleles"]["lip_curve"]=[1000,1000]
	var curved_models: Array[Node3D]=[]
	for genome in [flat_genes,raised_genes]:
		var portrait_model:=Node3D.new()
		root.add_child(portrait_model)
		FACE.finish(portrait_model,"lip-curve-acceptance",
			ART.mat(GENES.skin_color(genome),.96),
			ART.mat(GENES.hair_color(genome),.95),
			ART.mat(GENES.hair_color(genome),.95),genome)
		curved_models.append(portrait_model)
	var flat_mouth: Node3D=curved_models[0].get_node(
		"IndividualFaceConstruction/ExpressionMouth")
	var raised_mouth: Node3D=curved_models[1].get_node(
		"IndividualFaceConstruction/ExpressionMouth")
	var flat_upper: MeshInstance3D=flat_mouth.get_node(
		"ExpressionLipLeft/SmallNaturalLipLine")
	var raised_upper: MeshInstance3D=raised_mouth.get_node(
		"ExpressionLipLeft/SmallNaturalLipLine")
	var flat_lower: MeshInstance3D=flat_mouth.get_node(
		"ExpressionLowerLip/ModeledLowerLipLeft")
	var raised_lower: MeshInstance3D=raised_mouth.get_node(
		"ExpressionLowerLip/ModeledLowerLipLeft")
	if flat_upper.transform==raised_upper.transform or flat_lower.transform==raised_lower.transform:
		_fail("Inherited lip curve does not change the visible upper AND lower lip contours")
		return
	if float(flat_mouth.get_meta("rest_corner_rise"))>=float(
			raised_mouth.get_meta("rest_corner_rise")):
		_fail("Neutral mouth corners ignore the transmitted lip curve")
		return
	var upper_at_rest: Transform3D=raised_upper.transform
	for tick in range(20):
		FACE.expression(curved_models[1],.7,0.0,true,.21)
	if raised_upper.transform!=upper_at_rest or float(
			raised_mouth.get_meta("rest_cupid_rise"))<=float(
			flat_mouth.get_meta("rest_cupid_rise")):
		_fail("Talking or smiling erased the inherited upper-lip shape")
		return
	var one: MeshInstance3D=figures[0].get_node("InheritedChestWaistHipCloth")
	var two: MeshInstance3D=figures[1].get_node("InheritedChestWaistHipCloth")
	var verts_a: PackedVector3Array=one.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var verts_b: PackedVector3Array=two.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	if verts_a==verts_b:
		_fail("Distinct parent genomes created the same chest/waist/hip model")
		return
	print("PASS: inherited chest/bust/waist/hips, uncompressed irises, blinking lids, articulated speech, projected noses, lip-curve inheritance, allele migration, no new collision")
	quit(0)
