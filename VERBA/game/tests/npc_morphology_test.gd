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
		var expected: Array[String]=[
			"IndividualIntegratedFaceMesh","SmallRecessedEye","InheritedIris",
			"AnatomicalPupil","IndividualUpperEyelid",
			"AnatomicalLowerEyelid","ModeledNoseTip","ModeledNoseWing",
			"InheritedNostril","InheritedCheekboneFacet",
			"SmallNaturalLipLine","ModeledLowerLipLeft",
			"NaturalLipCorner","ModeledLowerLipRight",
			"ExpressionBrowLeft","ExpressionBrowRight",
			"InheritedChestWaistHipCloth"]
		for name in expected:
			if figure.find_child(name,true,false)==null:
				_fail("New face or torso is missing real 3D geometry: "+name)
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
	var one: MeshInstance3D=figures[0].get_node("InheritedChestWaistHipCloth")
	var two: MeshInstance3D=figures[1].get_node("InheritedChestWaistHipCloth")
	var verts_a: PackedVector3Array=one.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var verts_b: PackedVector3Array=two.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	if verts_a==verts_b:
		_fail("Distinct parent genomes created the same chest/waist/hip model")
		return
	print("PASS: inherited chest/bust/waist/hips, uncompressed irises, blinking lids, articulated speech, projected noses, allele migration, no new collision")
	quit(0)
