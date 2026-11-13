extends SceneTree
const GENES=preload("res://scripts/npc_genetics.gd")
const VILLAGE=preload("res://scripts/village_sim.gd")

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool,why: String) -> bool:
	if ok: return true
	push_error("VERBA genetics: "+why)
	quit(1)
	return false

func _run() -> void:
	var a: Dictionary=GENES.founder("ida",1938)
	var b: Dictionary=GENES.founder("orin",1938)
	if not _check(GENES.validate(a) and GENES.validate(b),"founder traits invalid"): return
	if not _check(a==GENES.founder("ida",1938) and a!=b,
			"founder traits are random on reload or everyone looks identical"): return
	# Citizens must not cluster around one average-colored, average-
	# shaped mannequin. Their inherited alleles define a useful visible
	# range before any occupation-specific costumes are added.
	var tone_min: float=1.0
	var tone_max: float=0.0
	var face_min: float=1.0
	var face_max: float=0.0
	for id in ["ida","orin","mara","sela","daro","nima",
			"brin","cass","lena","titus","ves","juno"]:
		var founder: Dictionary=GENES.founder(id,1938)
		tone_min=minf(tone_min,GENES.value(founder,"pigment"))
		tone_max=maxf(tone_max,GENES.value(founder,"pigment"))
		face_min=minf(face_min,GENES.value(founder,"face_width"))
		face_max=maxf(face_max,GENES.value(founder,"face_width"))
	if not _check(tone_max-tone_min>.37 and face_max-face_min>.30,
			"Founders still have nearly identical pigmentation or faces"): return
	var child: Dictionary=GENES.child(a,b,"born_0001",1938)
	var sibling: Dictionary=GENES.child(a,b,"born_0002",1938)
	if not _check(GENES.validate(child) and GENES.validate(sibling) and child!=sibling,
			"siblings are identical or uninhabitable"): return
	for locus in GENES.TRAITS:
		var alleles: Array=child["alleles"][locus]
		var inheritance: bool=(
			a["alleles"][locus].has(alleles[0]) or
			abs(int(alleles[0])-int(a["alleles"][locus][0]))<=45 or
			abs(int(alleles[0])-int(a["alleles"][locus][1]))<=45)
		if not _check(inheritance,"inherited allele not traceable: "+String(locus)): return
	# Sex changes average adult expression, not genetics: two parents
	# with large build alleles can have a tall daughter, and one family
	# can produce children of different physiques without role presets.
	var tall: Dictionary=a.duplicate(true)
	var short: Dictionary=a.duplicate(true)
	for locus in ["stature","shoulder_width","body_depth","hip_width","limb_ratio"]:
		tall["alleles"][locus]=[970,970]
		short["alleles"][locus]=[40,40]
	var large_daughter: Vector3=GENES.body_scale(tall,"female")
	var small_son: Vector3=GENES.body_scale(short,"male")
	if not _check(large_daughter.y>small_son.y+.08,
			"Large inherited bloodline cannot produce tall women"): return
	if not _check(large_daughter.x>small_son.x,
			"Strong female shoulder alleles were incorrectly suppressed"): return
	if not _check(GENES.body_scale(a,"female").y<GENES.body_scale(a,"male").y,
			"Same genome no longer has a smaller female population baseline"): return
	var inherited_tall: Dictionary=GENES.child(tall,tall,"born_tall",1938)
	if not _check(GENES.validate(inherited_tall) and (
			GENES.body_scale(inherited_tall,"female").y>GENES.body_scale(short,"male").y),
			"Parents' stature does not survive reproduction"): return
	if not _check(GENES.forearm_length(tall)>.335 and
			GENES.forearm_length(short)<GENES.forearm_length(tall),
			"Old limb_ratio allele is still ignored for arm reach"): return
	if not _check(GENES.offspring_sex("born_0001",1938) in ["female","male"],
			"Child sex did not resolve to a physical phenotype"): return
	var sim=VILLAGE.new(1938)
	var first: Dictionary=sim.create_child("ida","orin","Alma")
	var second: Dictionary=sim.create_child("ida","orin","Milo")
	if not _check(first.get("ok",false) and second.get("ok",false),"cannot create descendants"): return
	var baby: Dictionary=sim.people[first["id"]]
	if not _check(baby["genome"]==child,"child's inherited genes mismatch"): return
	if not _check(sim.people["ida"]["sex"]=="female" and sim.people["orin"]["sex"]=="male",
			"Founders lost established female/male phenotypes"): return
	if not _check(baby["sex"]==GENES.offspring_sex(String(first["id"]),1938),
			"Child sex is not independently assigned and persisted"): return
	if not _check(sim.bloodline(first["id"])["parents"]==["ida","orin"],"missing parents"): return
	if not _check(sim.bloodline("ida")["children"].has(first["id"]),"parent cannot find child"): return
	if not _check(sim.people[first["id"]]["life_stage"]=="child","newborn is adult"): return
	var snapshot: Dictionary=sim.snapshot()
	var loaded=VILLAGE.new(1938)
	if not _check(loaded.restore(JSON.parse_string(JSON.stringify(snapshot))),
			"persistent genome/lineage restore rejected"): return
	if not _check(loaded.people[first["id"]]["genome"]==baby["genome"],
			"genome did not survive JSON save/load"): return
	if not _check(loaded.people[first["id"]]["sex"]==baby["sex"],
			"Descendant sex was lost on save reload"): return
	if not _check(loaded.bloodline("orin")["children"].has(first["id"]),
			"bloodline was forgotten on reload"): return
	# Historical saves cannot contain born_* descendants; prove
	# migration against an actual original-population record.
	var legacy: Dictionary=VILLAGE.new(1938).snapshot()
	for id in legacy["people"]:
		legacy["people"][id].erase("genome")
		legacy["people"][id].erase("family")
		legacy["people"][id].erase("life_stage")
		legacy["people"][id].erase("sex")
	legacy.erase("gene_seed")
	if not _check(loaded.restore(legacy),"older save without genes no longer loads"): return
	if not _check(GENES.validate(loaded.people["ida"]["genome"]),
			"legacy appearance not restored"): return
	if not _check(loaded.people["ida"]["sex"]=="female",
			"Historical saved women were incorrectly changed into men"): return
	print("PASS: deterministic diverse founders, two-parent inheritance, differentiated siblings, permanent ancestry and legacy save compatibility")
	quit(0)
