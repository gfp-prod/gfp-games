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
	var one: MeshInstance3D=figures[0].get_node("InheritedChestWaistHipCloth")
	var two: MeshInstance3D=figures[1].get_node("InheritedChestWaistHipCloth")
	var verts_a: PackedVector3Array=one.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var verts_b: PackedVector3Array=two.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	if verts_a==verts_b:
		_fail("Distinct parent genomes created the same chest/waist/hip model")
		return
	print("PASS: individually sculpted inherited chest/bust/waist/hips, true eyes/noses/lips/cheekbones/brows, speaking animation, allele migration and no new collision")
	quit(0)
