extends SceneTree
## Headless model acceptance: genes must become independently visible anatomy,
## while no mesh introduces collisions or severs the physical limb modules.
const GENES=preload("res://scripts/npc_genetics.gd")
const FACE=preload("res://scripts/folk_portrait_finish.gd")
const BODY=preload("res://scripts/npc_body_morph.gd")
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
	# The first 28 inherited alleles are exactly those from the prior game.
	var legacy: Dictionary=a.duplicate(true)
	legacy["version"]=1
	for key in GENES.EXTRA_MORPH_TRAITS: legacy["alleles"].erase(key)
	var migrated: Dictionary=GENES.upgrade(legacy,"ida")
	if not GENES.validate(migrated):
		_fail("A saved v1 genome cannot migrate safely"); return
	for locus in GENES.TRAITS:
		if locus in GENES.EXTRA_MORPH_TRAITS: continue
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
	var female_hip: float=BODY._section(.80,same_genome,"female").x
	var male_hip: float=BODY._section(.80,same_genome,"male").x
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
