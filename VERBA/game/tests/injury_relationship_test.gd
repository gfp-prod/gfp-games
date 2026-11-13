extends SceneTree
## Relationship-specific injury opinions, patient triage and optional aid.
const SIM=preload("res://scripts/village_sim.gd")
const ANATOMY=preload("res://scripts/npc_anatomy.gd")

func _initialize() -> void:
	call_deferred("_run")

func _fail(reason: String) -> void:
	push_error("VERBA relationship injury QA: "+reason)
	quit(1)

func _run() -> void:
	var sim=SIM.new(841)
	var compassionate: Dictionary=sim.people["sela"]
	var resentful: Dictionary=sim.people["brin"]
	compassionate["trust"]["ida"]=55.0
	resentful["grievance"]["ida"]=100.0
	var struck: Dictionary=sim.injure_person("ida","left_arm",22.0,
		"wizard",["sela","brin"])
	if not struck.get("ok",false) or struck.get("severed",true):
		_fail("Small observed hit should cause a real wound, not severance")
		return
	var friend_anger: float=float(compassionate["trust"].get("wizard",0.0))
	var enemy_approval: float=float(resentful["trust"].get("wizard",0.0))
	if friend_anger>=-10.0 or enemy_approval<=0.0:
		_fail("All observers reacted identically despite contrasting relationships")
		return
	if sim.people["tomas"]["trust"].has("wizard"):
		_fail("An absent person learned who committed a private injury")
		return
	var prior_friend: float=friend_anger
	var prior_enemy: float=enemy_approval
	var bag: Array=["herb"]
	var treated: Dictionary=sim.player_help("ida",bag,["sela","brin"])
	if not treated.get("ok",false) or bag.has("herb"):
		_fail("Physical player care did not consume finite medical resources")
		return
	if float(compassionate["trust"]["wizard"])<=prior_friend:
		_fail("Witness of a friend's recovery did not improve player reputation")
		return
	if float(resentful["trust"]["wizard"])>=prior_enemy:
		_fail("A person's enemy did not react differently to being helped")
		return
	if sim.people["tomas"]["trust"].has("wizard"):
		_fail("Uninvolved villagers received distant player care reputation")
		return
	var triage=SIM.new(842)
	triage.economy.stocks["herb"]=3
	triage.nearby_care["sela"]=["ida","daro"]
	triage.people["sela"]["known_wounded"]=["ida","daro"]
	ANATOMY.strike(triage.people["ida"]["anatomy"],"right_arm",66.0,0)
	ANATOMY.strike(triage.people["daro"]["anatomy"],"right_leg",66.0,0)
	if triage._care_target("sela")!="daro":
		_fail("An affectionate spouse did not outrank an unrelated patient")
		return
	triage.people["sela"]["trust"]["daro"]=-100.0
	triage.people["sela"]["grievance"]["daro"]=100.0
	triage.people["sela"]["trust"]["ida"]=70.0
	if triage._care_target("sela")!="ida":
		_fail("Triage ignored severe resentment and individual trust")
		return
	if triage._perform_neighbor_aid("sela","ida"):
		_fail("Compassion teleported bandages to a patient outside contact")
		return
	triage.care_contact["sela"]=["ida"]
	var herb_before: int=int(triage.economy.stocks["herb"])
	if not triage._perform_neighbor_aid("sela","ida"):
		_fail("A nearby helper with supplies could not treat their chosen patient")
		return
	if int(triage.economy.stocks["herb"])!=herb_before-1:
		_fail("Treating a citizen produced medicine without using goods")
		return
	triage.people["sela"]["trust"]["ida"]=-100.0
	triage.people["sela"]["grievance"]["ida"]=100.0
	if triage._score(triage.people["sela"],"aid")>=0.0:
		_fail("Even extreme mutual hatred could not suppress voluntary care")
		return
	print("PASS: witnessed personalized violence, observed player care, contextual triage, physical contact, finite resources and genuine refusal")
	quit(0)
