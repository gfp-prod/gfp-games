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
	var sim=VILLAGE.new(1938)
	var first: Dictionary=sim.create_child("ida","orin","Alma")
	var second: Dictionary=sim.create_child("ida","orin","Milo")
	if not _check(first.get("ok",false) and second.get("ok",false),"cannot create descendants"): return
	var baby: Dictionary=sim.people[first["id"]]
	if not _check(baby["genome"]==child,"child's inherited genes mismatch"): return
	if not _check(sim.bloodline(first["id"])["parents"]==["ida","orin"],"missing parents"): return
	if not _check(sim.bloodline("ida")["children"].has(first["id"]),"parent cannot find child"): return
	if not _check(sim.people[first["id"]]["life_stage"]=="child","newborn is adult"): return
	var snapshot: Dictionary=sim.snapshot()
	var loaded=VILLAGE.new(1938)
	if not _check(loaded.restore(JSON.parse_string(JSON.stringify(snapshot))),
			"persistent genome/lineage restore rejected"): return
	if not _check(loaded.people[first["id"]]["genome"]==baby["genome"],
			"genome did not survive JSON save/load"): return
	if not _check(loaded.bloodline("orin")["children"].has(first["id"]),
			"bloodline was forgotten on reload"): return
	# Historical saves cannot contain born_* descendants; prove
	# migration against an actual original-population record.
	var legacy: Dictionary=VILLAGE.new(1938).snapshot()
	for id in legacy["people"]:
		legacy["people"][id].erase("genome")
		legacy["people"][id].erase("family")
		legacy["people"][id].erase("life_stage")
	legacy.erase("gene_seed")
	if not _check(loaded.restore(legacy),"older save without genes no longer loads"): return
	if not _check(GENES.validate(loaded.people["ida"]["genome"]),
			"legacy appearance not restored"): return
	print("PASS: deterministic diverse founders, two-parent inheritance, differentiated siblings, permanent ancestry and legacy save compatibility")
	quit(0)
