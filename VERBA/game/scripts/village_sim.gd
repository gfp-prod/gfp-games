extends RefCounted
## Deterministic social simulation. No scene nodes, UI, or omniscient world knowledge.
## Each fixed tick evaluates circumstances; actions emit causal, witnessed events.
const VERSION := 1
const ECONOMY = preload("res://scripts/village_economy.gd")
const ANATOMY = preload("res://scripts/npc_anatomy.gd")
const GENES = preload("res://scripts/npc_genetics.gd")
const COMMISSIONS = preload("res://scripts/wizard_commissions.gd")
const ROLES := [
	["mara","scribe","crow",82,53,24],
	["tomas","keeper","crow",75,36,30],
	["ida","baker","cat",35,84,24],
	["orin","blacksmith","crow",91,21,52],
	["ves","mayor","wolf",55,38,90],
	["titus","guard","wolf",69,26,83],
	["lena","painter","cat",27,91,19],
	["daro","farmer","crow",73,43,45],
	["nima","bard","cat",31,89,42],
	["cass","priest","wolf",62,44,77],
	["brin","builder","crow",88,35,39],
	["sela","merchant","wolf",57,65,72],
	["juno","merchant","cat",66,77,25]
]
var rng := RandomNumberGenerator.new()
var economy = ECONOMY.new()
var last_scores: Dictionary = {}
var people: Dictionary = {}
var events: Array[Dictionary] = []
var tick_count := 0
var next_event_id := 1
var recent_action: Dictionary = {}
# Opt-in scene-world labor. Headless simulations preserve the original
# deterministic immediate-work semantics for long-run and replay tests.
var spatial_work_enabled: bool = false
var work_orders: Dictionary = {}
# Mana-fed fertility is promised future harvest, not instantly available grain.
var field_fertility: int = 0
var seeded := false
var restore_error: String = ""
var current_day: int = 0
var commissions: Dictionary = {}
# Transient physical reach is supplied by the scene, not serialized as omniscience.
var nearby_care: Dictionary = {}
# Sight alone never grants the ability to administer treatment.
var care_contact: Dictionary = {}
var gene_seed: int=1938
var next_child_serial: int=1

func _init(seed_value: int = 1938) -> void:
	reset(seed_value)

func reset(seed_value: int) -> void:
	rng.seed = seed_value
	gene_seed=seed_value
	next_child_serial=1
	people.clear()
	events.clear()
	recent_action.clear()
	work_orders.clear()
	field_fertility=0
	current_day=0
	commissions.clear()
	last_scores.clear()
	nearby_care.clear()
	care_contact.clear()
	economy=ECONOMY.new()
	tick_count = 0
	next_event_id = 1
	for row in ROLES:
		var id: String = row[0]
		people[id] = {"id":id,"role":row[1],"nature":row[2],
			"crow":row[3],"cat":row[4],"wolf":row[5],
			"hunger":rng.randf_range(5.0,25.0),
			"fatigue":rng.randf_range(5.0,25.0),
			"loneliness":rng.randf_range(5.0,40.0),
			"wealth":rng.randi_range(2,10),"mood":50.0,
			"spouse":"","trust":{},"grievance":{},
			"known_events":[],"last_action":"idle","alive":true,
			"anatomy":ANATOMY.new_state(),"known_wounded":[],
			"genome":GENES.founder(id,gene_seed),
			"family":GENES.founder_family(id,-365*(21+posmod(id.hash(),28))),
			"life_stage":"adult"}
	# Stable initial families without hardcoded affair, crime, or plot outcomes.
	people["ida"]["spouse"] = "orin"
	people["orin"]["spouse"] = "ida"
	people["daro"]["spouse"] = "sela"
	people["sela"]["spouse"] = "daro"
	seeded = true

func _score(p: Dictionary, action: String) -> float:
	var crow: float = float(p["crow"])/100.0
	var cat: float = float(p["cat"])/100.0
	var wolf: float = float(p["wolf"])/100.0
	match action:
		"eat": return float(p["hunger"])*1.45 if int(p["wealth"]) > 0 and int(economy.stocks["bread"])>0 else -1.0
		"rest": return float(p["fatigue"])*1.45
		"work":
			var body: Dictionary=p.get("anatomy",ANATOMY.new_state())
			if ANATOMY.locomotion(body)<.42 or body["missing"].has("right_arm"): return -1.0
			return (15.0 + crow*32.0 + (8.0 if int(p["wealth"]) < 4 else 0.0) - float(p["fatigue"])*0.30) if economy.can_work(String(p["role"])) else -1.0
		"socialize": return float(p["loneliness"])*0.80 + cat*22.0 - float(p["fatigue"])*0.12
		"court": return float(p["loneliness"])*0.58 + cat*25.0 + wolf*8.0 - (22.0 if not String(p["spouse"]).is_empty() else 0.0)
		"steal": return (46.0 if int(p["wealth"]) < 3 else -25.0) + wolf*28.0 - crow*14.0
		"investigate": return 18.0 + wolf*30.0 if String(p["role"])=="guard" and _unresolved_crime_known(p) else -1.0
		"aid":
			var target_id: String=_care_target(String(p["id"]))
			if target_id.is_empty(): return -1.0
			var target: Dictionary=people[target_id]
			var relationship: float=float(p["trust"].get(target_id,0.0))
			var resentment: float=float(p["grievance"].get(target_id,0.0))
			var loyalty: float=47.0 if String(p["spouse"])==target_id else 0.0
			# Kindness is contextual, not hardcoded to one NPC or plot.
			# Fear, character, trust, exhaustion and scarcity can overcome care.
			return 14.0+cat*32.0+crow*10.0-wolf*18.0+loyalty+relationship*.45-resentment*.8-float(p["fatigue"])*.4
	return -1.0

func _unresolved_crime_known(p: Dictionary) -> bool:
	for entry in events:
		if entry["type"] == "theft" and not bool(entry.get("resolved",false)) and p["known_events"].has(entry["id"]):
			return true
	return false


func _select(p: Dictionary) -> String:
	# Once someone starts an actual work journey, they finish or abandon
	# that journey rather than magically producing again on the next tick.
	if spatial_work_enabled and work_orders.has(String(p["id"])):
		return "work"
	var scores: Dictionary = {}
	var actions: Array=["eat","rest","work","socialize","court","steal","investigate"]
	# Preserve the exact seven-action seed/replay RNG sequence when there
	# is no known nearby patient. Optional care must not silently rewrite
	# the entire economy in old saves or independent simulations.
	if not _care_target(String(p["id"])).is_empty():
		actions.append("aid")
	for action in actions:
		# Gumbel-free small bounded noise avoids action lockstep, not arbitrary decisions.
		scores[action] = _score(p,action) + rng.randf_range(-3.0,3.0)
		if String(recent_action.get(p["id"],"")) == action:
			scores[action] -= 7.0
	last_scores[String(p["id"])] = scores.duplicate(true)
	var best: String = "rest"
	for action in scores:
		if float(scores[action]) > float(scores.get(best,-INF)): best = action
	return best

func _candidate(source_id: String, allow_spouse: bool = true) -> String:
	var possible: Array[String] = []
	for id in people:
		if id == source_id: continue
		if not allow_spouse and id == String(people[source_id]["spouse"]): continue
		if bool(people[id]["alive"]): possible.append(id)
	if possible.is_empty(): return ""
	# JSON normalizes Dictionary insertion order; selection order must not depend on it.
	possible.sort()
	return possible[rng.randi_range(0,possible.size()-1)]

func _witnesses(actor: String, target: String) -> Array[String]:
	# Abstract village encounter proximity: only a subset can perceive an event.
	# Recorded witnesses are the only NPCs who learn its contents automatically.
	var found: Array[String] = [actor]
	if not target.is_empty() and not found.has(target): found.append(target)
	var ordered_ids: Array = people.keys()
	ordered_ids.sort()
	for id in ordered_ids:
		if id == actor or id == target: continue
		if rng.randf() < 0.12: found.append(id)
	return found

func _event(kind: String, actor: String, target: String = "", amount: int = 0) -> void:
	var observers: Array[String] = _witnesses(actor,target)
	var event: Dictionary = {"id":next_event_id,"tick":tick_count,
		"type":kind,"actor":actor,"target":target,
		"amount":amount,"witnesses":observers,"resolved":false}
	next_event_id += 1
	events.append(event)
	for id in observers:
		var known: Array = people[id]["known_events"]
		known.append(event["id"])
		if known.size()>32: known.pop_front()
	# Cap historical telemetry without inventing world knowledge.
	if events.size()>256: events.pop_front()

func _act(id: String, action: String) -> void:
	var p: Dictionary = people[id]
	match action:
		"eat":
			economy.eat(id,p)
		"rest":
			p["fatigue"] = maxf(0.0,float(p["fatigue"])-55.0)
		"work":
			# A severed working arm or untreated loss of mobility changes
			# what this person can actually produce.
			var body: Dictionary=p.get("anatomy",ANATOMY.new_state())
			if ANATOMY.locomotion(body)<.42 or body["missing"].has("right_arm"):
				work_orders.erase(id)
				p["last_action"]="rest"
				recent_action[id]="rest"
				return
			var job_role: String = String(p["role"])
			if spatial_work_enabled and job_role in ["farmer","baker","blacksmith"]:
				# A work order is permission to travel and labor, not a resource
				# transaction. Inventory changes only on physical completion.
				if not work_orders.has(id) and economy.can_work(job_role):
					work_orders[id] = {"role":job_role,"phase":"labor","tick":tick_count}
			elif economy.work(id,job_role,p):
				_finish_wage(p)
		"socialize":
			var other: String = _candidate(id)
			if not other.is_empty():
				p["loneliness"] = maxf(0.0,float(p["loneliness"])-35.0)
				people[other]["loneliness"] = maxf(0.0,float(people[other]["loneliness"])-12.0)
				var trust: Dictionary = p["trust"]
				trust[other] = clampf(float(trust.get(other,0.0))+5.0,-100.0,100.0)
				_event("conversation",id,other)
		"court":
			var other: String = _candidate(id,false)
			if not other.is_empty():
				var trust_value: float = float(people[other]["trust"].get(id,0.0))
				var receptive: float = (float(people[other]["cat"])+trust_value)*0.003
				if rng.randf()<clampf(receptive,0.02,0.72):
					p["loneliness"] = maxf(0.0,float(p["loneliness"])-28.0)
					people[other]["trust"][id] = clampf(trust_value+9.0,-100.0,100.0)
					_event("courtship",id,other)
				else:
					_event("rejection",id,other)
		"steal":
			var victim: String = _candidate(id)
			if not victim.is_empty() and int(people[victim]["wealth"])>0:
				people[victim]["wealth"] -= 1
				p["wealth"] = mini(100,int(p["wealth"])+1)
				people[victim]["grievance"][id] = float(people[victim]["grievance"].get(id,0.0))+18.0
				_event("theft",id,victim,1)
		"aid":
			_perform_neighbor_aid(id,_care_target(id))
		"investigate":
			for entry in events:
				if entry["type"]=="theft" and not bool(entry["resolved"]) and p["known_events"].has(entry["id"]):
					entry["resolved"] = true
					var suspect: String = String(entry["actor"])
					var recovered: int = mini(1,int(people[suspect]["wealth"]))
					if recovered>0:
						people[suspect]["wealth"] -= recovered
						people[String(entry["target"])]["wealth"] = mini(100,int(people[String(entry["target"])]["wealth"])+recovered)
					_event("law_response",id,suspect,recovered)
					break
	p["last_action"] = action
	recent_action[id] = action

func _finish_wage(p: Dictionary) -> void:
	p["fatigue"] = minf(100.0,float(p["fatigue"])+12.0)
	p["mood"] = minf(100.0,float(p["mood"])+float(p["crow"])*0.035)

func bless_field(amount: int) -> int:
	# Capped, persisted potential: only a farmer's delivered harvest
	# converts Latin growth into goods. Never spawn items on spell cast.
	var gained: int=mini(maxi(0,amount),6-field_fertility)
	field_fertility+=gained
	return gained

func advance_work(id: String) -> bool:
	# The farmer must finish field labor before leaving with a visible
	# harvest. Grain enters storage only on a separate cart delivery.
	if not spatial_work_enabled or not work_orders.has(id): return false
	var order: Dictionary=work_orders[id]
	if String(order.get("role",""))!="farmer" or String(order.get("phase",""))!="labor": return false
	order["phase"]="delivery"
	return true

func complete_work(id: String) -> bool:
	if not spatial_work_enabled or not work_orders.has(id) or not people.has(id): return false
	var order: Dictionary=work_orders[id]
	var job_role: String=String(order.get("role",""))
	var needed: String="delivery" if job_role=="farmer" else "labor"
	if String(order.get("phase",""))!=needed or String(people[id]["role"])!=job_role: return false
	work_orders.erase(id)
	if not economy.work(id,job_role,people[id]): return false
	if job_role=="farmer" and field_fertility>0:
		var harvest_bonus: int=mini(2,mini(field_fertility,ECONOMY.CAP-int(economy.stocks["grain"])))
		if harvest_bonus>0:
			economy.stocks["grain"]=int(economy.stocks["grain"])+harvest_bonus
			field_fertility-=harvest_bonus
			economy._record("enchanted_harvest",id,"grain",harvest_bonus)
	_finish_wage(people[id])
	return true

func _stabilize_floats() -> void:
	# JSON persistence has finite decimal precision. Quantize at each tick,
	# rather than allowing an in-memory world to drift from its reloaded twin.
	for id in people:
		var p: Dictionary=people[id]
		for key in ["hunger","fatigue","loneliness","mood"]:
			p[key]=snappedf(float(p[key]),0.001)
		for key in ["trust","grievance"]:
			var values: Dictionary=p[key]
			for other in values:
				values[other]=snappedf(float(values[other]),0.001)

func advance_day(day: int) -> void:
	# Offscreen social consequences run once per calendar day, not every
	# rendered frame or every arbitrary simulation tick.
	if day<=current_day: return
	for next_day in range(current_day+1,day+1):
		current_day=next_day
		# Natural development uses calendar time, not render ticks.
		# Family ties and appearance are immutable across stages.
		for who in people:
			var citizen: Dictionary=people[who]
			if not bool(citizen.get("alive",true)): continue
			var age: int=current_day-int(citizen["family"]["birth_day"])
			if String(citizen.get("life_stage","adult"))=="child" and age>=18*365:
				citizen["life_stage"]="adult"
				citizen["role"]=String(citizen.get("trained_role","wanderer"))
				_event("coming_of_age",String(who))
		COMMISSIONS.day_passed(self)

func step() -> void:
	tick_count += 1
	# A worker who cannot reach an obstructed workplace eventually gives
	# up without manufacturing cargo. Next tick re-evaluates their needs.
	for id in work_orders.keys():
		if tick_count-int(work_orders[id].get("tick",tick_count))>24:
			work_orders.erase(id)
	# Local scarcity changes the incentives without dictating a plot. It is
	# possible to earn money, lose customers, or become desperate later.
	economy.tick=tick_count
	if tick_count % 19 == 0:
		var lost: int=economy.shortage("grain",rng.randi_range(2,5))
		if lost>0:
			# A harvest loss is an actual grain deficit; the baker feels it.
			people["ida"]["mood"]=maxf(0.0,float(people["ida"]["mood"])-12.0)
			_event("shortage","daro","ida",lost)
	var ordered: Array = people.keys()
	ordered.sort()
	for id in ordered:
		var p: Dictionary = people[id]
		if not bool(p["alive"]): continue
		# Children are residents with persistent IDs and genes, but do
		# not participate in adult courtship, theft or economic production.
		if String(p.get("life_stage","adult"))=="child":
			p["last_action"]="rest"
			continue
		p["hunger"] = minf(100.0,float(p["hunger"])+3.5)
		p["fatigue"] = minf(100.0,float(p["fatigue"])+2.5)
		p["loneliness"] = minf(100.0,float(p["loneliness"])+2.0)
		ANATOMY.passage(p["anatomy"])
		if float(p["anatomy"]["vitality"])<=0.0:
			p["alive"]=false
			work_orders.erase(id)
			_event("fatal_injury",id)
			continue
		_act(id,_select(p))
	_stabilize_floats()

# Actual observations are made by existing physical world characters. A
# stranger does not know a wound merely because the village sim has its ID.
func observe_wound(victim_id: String, witnesses: Array) -> void:
	if not people.has(victim_id): return
	for observer in witnesses:
		var id: String=String(observer)
		if id==victim_id or not people.has(id): continue
		var known: Array=people[id]["known_wounded"]
		if not known.has(victim_id): known.append(victim_id)

# An observer's reaction to harm depends on THEIR relationship to the
# patient. A loving spouse is horrified; a bitter enemy may welcome the
# blow. Only explicitly present witnesses change opinion.
func _harm_witness_delta(observer_id: String, patient_id: String) -> float:
	if not people.has(observer_id) or not people.has(patient_id): return 0.0
	var observer: Dictionary=people[observer_id]
	var affection: float=float(observer["trust"].get(patient_id,0.0))
	var grievance: float=float(observer["grievance"].get(patient_id,0.0))
	var spouse_bond: float=70.0 if String(observer["spouse"])==patient_id else 0.0
	return clampf(-7.0-(affection+spouse_bond-grievance)*.24,-35.0,18.0)

func injure_person(victim_id: String, part: String, force: float,
		attacker: String, witnesses: Array=[]) -> Dictionary:
	if not people.has(victim_id) or not bool(people[victim_id]["alive"]):
		return {"ok":false,"severed":false}
	var victim: Dictionary=people[victim_id]
	var result: Dictionary=ANATOMY.strike(victim["anatomy"],part,force,tick_count)
	if not bool(result.get("ok",false)): return result
	if bool(result["severed"]):
		work_orders.erase(victim_id)
	observe_wound(victim_id,witnesses)
	if attacker=="wizard":
		victim["trust"]["wizard"]=clampf(
			float(victim["trust"].get("wizard",0.0))-16.0,-100.0,100.0)
		for seen in witnesses:
			var observer: String=String(seen)
			if not people.has(observer) or observer==victim_id: continue
			var witness: Dictionary=people[observer]
			witness["trust"]["wizard"]=clampf(
				float(witness["trust"].get("wizard",0.0))+
				_harm_witness_delta(observer,victim_id),-100.0,100.0)
	elif people.has(attacker) and attacker!=victim_id:
		victim["grievance"][attacker]=clampf(
			float(victim["grievance"].get(attacker,0.0))+28.0,0.0,100.0)
		for seen in witnesses:
			var observer: String=String(seen)
			if not people.has(observer) or observer in [attacker,victim_id]: continue
			var witness: Dictionary=people[observer]
			witness["trust"][attacker]=clampf(
				float(witness["trust"].get(attacker,0.0))+
				_harm_witness_delta(observer,victim_id),-100.0,100.0)
	# The event has exact observed witnesses; random village witnesses
	# cannot magically learn the particulars of a physical injury.
	var observers: Array=[victim_id]
	for seen in witnesses:
		if people.has(String(seen)) and not observers.has(String(seen)):
			observers.append(String(seen))
	events.append({"id":next_event_id,"tick":tick_count,
		"type":"severance" if bool(result["severed"]) else "wound",
		"actor":victim_id,"target":attacker if people.has(attacker) else "",
		"part":part,"witnesses":observers,"resolved":false,"amount":int(force)})
	for seen in observers:
		var memory: Array=people[String(seen)]["known_events"]
		memory.append(next_event_id)
		if memory.size()>32: memory.pop_front()
	next_event_id+=1
	if events.size()>256: events.pop_front()
	return result

func _care_target(helper_id: String) -> String:
	if not people.has(helper_id): return ""
	var helper: Dictionary=people[helper_id]
	var seen: Array=nearby_care.get(helper_id,[])
	var chosen: String=""
	var top: float=-INF
	for other in seen:
		var target_id: String=String(other)
		if target_id==helper_id or not people.has(target_id): continue
		if not helper["known_wounded"].has(target_id): continue
		if not bool(people[target_id]["alive"]): continue
		var body: Dictionary=people[target_id]["anatomy"]
		if ANATOMY.aid_kind(body,economy.stocks).is_empty(): continue
		# Each helper prioritizes patients according to that individual
		# relationship, resentment and observed urgency rather than
		# magically treating everyone in a fixed alphabetical queue.
		var tie: float=55.0 if String(helper["spouse"])==target_id else 0.0
		var affection: float=float(helper["trust"].get(target_id,0.0))*.8
		var hostility: float=float(helper["grievance"].get(target_id,0.0))*1.1
		var urgency: float=float(body["bleeding"])*4.0
		if body["support"]=="none" and ANATOMY.needs_support(body):
			urgency+=6.0
		var score: float=tie+affection-hostility+urgency
		if score>top or (is_equal_approx(score,top) and (chosen.is_empty() or target_id<chosen)):
			top=score
			chosen=target_id
	return chosen

func _perform_neighbor_aid(helper_id: String, target_id: String) -> bool:
	if target_id.is_empty() or not people.has(target_id) or not people.has(helper_id):
		return false
	if not nearby_care.get(helper_id,[]).has(target_id): return false
	# Helper must physically reach the patient. Knowledge, compassion and
	# finite supplies alone cannot provide instantaneous remote aid.
	if not care_contact.get(helper_id,[]).has(target_id): return false
	var kind: String=ANATOMY.aid_kind(people[target_id]["anatomy"],economy.stocks)
	if kind.is_empty(): return false
	var recipe: Dictionary={"herb":1} if kind=="bandage" else (
		{"wood":1,"tools":1} if kind=="peg" else {"wood":1})
	for item in recipe:
		if int(economy.stocks.get(item,0))<int(recipe[item]): return false
	if not ANATOMY.aid(people[target_id]["anatomy"],kind,tick_count): return false
	for item in recipe:
		economy.stocks[item]=int(economy.stocks[item])-int(recipe[item])
		economy._record("care",helper_id,String(item),int(recipe[item]))
	var trust: Dictionary=people[target_id]["trust"]
	trust[helper_id]=clampf(float(trust.get(helper_id,0.0))+14.0,-100.0,100.0)
	_event("neighbor_care",helper_id,target_id)
	return true

func player_help(target_id: String, inventory: Array,
		witnesses: Array=[]) -> Dictionary:
	if not people.has(target_id) or not bool(people[target_id]["alive"]):
		return {"ok":false,"message":"There is nobody here to help."}
	var target: Dictionary=people[target_id]
	var loyalty: float=float(target["trust"].get("wizard",0.0))
	if loyalty< -55.0:
		return {"ok":false,"message":"They recoil from you and refuse treatment."}
	var supplies: Dictionary={"herb":int(inventory.count("herb")),
		"wood":int(inventory.count("wood")),
		"tools":int(inventory.count("tools"))}
	var kind: String=ANATOMY.aid_kind(target["anatomy"],supplies)
	if kind.is_empty():
		return {"ok":false,"message":"They need a wound dressing or usable timber and tools."}
	var consumed: Array=["herb"] if kind=="bandage" else (
		["wood","tools"] if kind=="peg" else ["wood"])
	if not ANATOMY.aid(target["anatomy"],kind,tick_count):
		return {"ok":false,"message":"That aid is not needed now."}
	for item in consumed: inventory.erase(item)
	target["trust"]["wizard"]=clampf(loyalty+19.0,-100.0,100.0)
	# Only people who actually saw both patient and helper update their
	# feelings about the player's actions; an uninvolved merchant on the
	# opposite side of the valley does not magically know.
	for seen in witnesses:
		var observer_id: String=String(seen)
		if observer_id==target_id or not people.has(observer_id): continue
		var observer: Dictionary=people[observer_id]
		var witnessed_good: float=clampf(
			-_harm_witness_delta(observer_id,target_id)*.65,-12.0,22.0)
		observer["trust"]["wizard"]=clampf(
			float(observer["trust"].get("wizard",0.0))+witnessed_good,
			-100.0,100.0)
	_event("wizard_care",target_id)
	return {"ok":true,"message":(
		"The wound is dressed." if kind=="bandage" else
		"You fit a wooden prosthetic leg." if kind=="peg" else
		"You fashion a walking crutch."),
		"kind":kind}

func witness_event(kind: String, actor: String, target: String = "") -> bool:
	if not people.has(actor): return false
	if not target.is_empty() and not people.has(target): return false
	_event(kind,actor,target)
	return true

# No forced marriage or childbirth. Existing or future NPC behaviors may
# request birth once conditions are met; this API is the shared authority.
# A newborn is a new persistent person, not a copy of a parent's visual mesh.
func create_child(parent_a_id: String,parent_b_id: String,
		child_name: String="") -> Dictionary:
	if not people.has(parent_a_id) or not people.has(parent_b_id) or parent_a_id==parent_b_id:
		return {"ok":false,"reason":"unknown or identical parents"}
	var a: Dictionary=people[parent_a_id]
	var b: Dictionary=people[parent_b_id]
	if not bool(a["alive"]) or not bool(b["alive"]):
		return {"ok":false,"reason":"deceased parent"}
	if String(a.get("life_stage","adult"))!="adult" or String(b.get("life_stage","adult"))!="adult":
		return {"ok":false,"reason":"child parent"}
	var child_id: String="born_%04d" % next_child_serial
	if people.has(child_id) or people.size()>=60:
		return {"ok":false,"reason":"population limit or repeated ID"}
	var family: Dictionary=GENES.descendant_family(child_id,parent_a_id,parent_b_id,people,current_day)
	var genome: Dictionary=GENES.child(a["genome"],b["genome"],child_id,gene_seed)
	if family.is_empty() or not GENES.validate(genome):
		return {"ok":false,"reason":"invalid pedigree"}
	var record: Dictionary={
		"id":child_id,"role":"child","trained_role":"wanderer","life_stage":"child",
		"display_name":child_name if not child_name.strip_edges().is_empty() else "Child",
		"nature":"unformed","crow":50,"cat":50,"wolf":50,
		"hunger":15.0,"fatigue":15.0,"loneliness":15.0,
		"wealth":0,"mood":50.0,"spouse":"","trust":{},"grievance":{},
		"known_events":[],"last_action":"rest","alive":true,
		"anatomy":ANATOMY.new_state(),"known_wounded":[],
		"genome":genome,"family":family}
	people[child_id]=record
	for parent_id in [parent_a_id,parent_b_id]:
		people[parent_id]["family"]["children"].append(child_id)
	next_child_serial+=1
	_event("birth",parent_a_id,child_id)
	return {"ok":true,"id":child_id,"child":record.duplicate(true)}

func bloodline(person_id: String) -> Dictionary:
	if not people.has(person_id): return {}
	var result: Dictionary=people[person_id]["family"].duplicate(true)
	result["person_id"]=person_id
	result["living_children"]=[]
	for child_id in result["children"]:
		if people.has(child_id) and bool(people[child_id]["alive"]):
			result["living_children"].append(child_id)
	return result

func inspector(id: String) -> Dictionary:
	if not people.has(id): return {}
	var p: Dictionary=people[id]
	var ranked: Array[Dictionary]=[]
	var actions: Array=["eat","rest","work","socialize","court","steal","investigate"]
	if not _care_target(id).is_empty():
		actions.append("aid")
	for action in actions:
		ranked.append({"action":action,"score":_score(p,action)})
	ranked.sort_custom(func(a,b): return float(a["score"])>float(b["score"]))
	return {"id":id,"person":p.duplicate(true),"ranked_actions":ranked,
		"stocks":economy.stocks.duplicate(true),"treasury":economy.treasury,
		"recent_transactions":economy.transactions.slice(maxi(0,economy.transactions.size()-8)),
		"work_order":work_orders.get(id,{}).duplicate(true),
		"field_fertility":field_fertility,
		"tick":tick_count}

func snapshot() -> Dictionary:
	return {"version":VERSION,"tick":tick_count,"rng_state":str(rng.state),
		"next_event_id":next_event_id,"people":people.duplicate(true),
		"events":events.duplicate(true),"recent_action":recent_action.duplicate(true),
		"work_orders":work_orders.duplicate(true),"field_fertility":field_fertility,
		"current_day":current_day,"commissions":commissions.duplicate(true),
		"gene_seed":gene_seed,"next_child_serial":next_child_serial,
		"economy":economy.snapshot()}

func restore(record: Dictionary) -> bool:
	restore_error = ""
	if int(record.get("version",0))!=VERSION:
		restore_error = "schema version"
		return false
	var stored: Variant = record.get("people",{})
	# Existing 12-citizen saves predate the roadside attendant. Preserve
	# the original agents and simulated history; add only the new identity.
	if stored is Dictionary and stored.size()==ROLES.size()-1 and not stored.has("juno"):
		stored=stored.duplicate(true)
		stored["juno"]=people["juno"].duplicate(true)
	if not (stored is Dictionary) or stored.size()<ROLES.size() or stored.size()>60:
		restore_error = "population: %d" % stored.size()
		return false
	stored=stored.duplicate(true)
	var restore_gene_seed: int=int(record.get("gene_seed",gene_seed))
	# Upgrade old saves without discarding any relationships or injuries.
	for stored_id in stored:
		var old_person: Dictionary=stored[stored_id]
		if not old_person.has("genome"):
			old_person["genome"]=GENES.founder(String(stored_id),restore_gene_seed)
		if not old_person.has("family"):
			old_person["family"]=GENES.founder_family(String(stored_id),
				-365*(21+posmod(String(stored_id).hash(),28)))
		if not old_person.has("life_stage"):
			old_person["life_stage"]="adult"
		if not GENES.validate(old_person["genome"]) or not GENES.validate_family(
				old_person["family"],String(stored_id),stored):
			restore_error="invalid genome or bloodline: "+String(stored_id)
			return false
		if old_person.get("life_stage","") not in ["adult","child"]:
			restore_error="invalid stage"
			return false
		if String(stored_id).begins_with("born_") and (
				old_person["family"]["parents"].size()!=2 or
				String(old_person.get("id",""))!=String(stored_id)):
			restore_error="broken child identity"
			return false
	# A bloodline must be reciprocal; forged parent/child links cannot
	# enter world state through tampered or corrupted save data.
	for stored_id in stored:
		for parent_id in stored[stored_id]["family"]["parents"]:
			if not stored[parent_id]["family"]["children"].has(stored_id):
				restore_error="broken parent-child bond"
				return false
		for child_id in stored[stored_id]["family"]["children"]:
			if not stored[child_id]["family"]["parents"].has(stored_id):
				restore_error="broken child-parent bond"
				return false
	for row in ROLES:
		if not stored.has(row[0]) or not (stored[row[0]] is Dictionary):
			restore_error = "missing person: %s" % row[0]
			return false
		# Recover original schema-1 citizens without altering save IDs.
		if not stored[row[0]].has("anatomy"):
			stored[row[0]]["anatomy"]=ANATOMY.new_state()
		if not stored[row[0]].has("known_wounded"):
			stored[row[0]]["known_wounded"]=[]
		if not ANATOMY.validate(stored[row[0]]["anatomy"]):
			restore_error="invalid anatomical record"
			return false
		if not (stored[row[0]]["known_wounded"] is Array):
			restore_error="invalid wound memories"
			return false
		for seen in stored[row[0]]["known_wounded"]:
			if not (seen is String) or not stored.has(seen):
				restore_error="unknown remembered patient"
				return false
		if String(stored[row[0]].get("id",""))!=row[0]:
			restore_error = "identity mismatch: %s" % row[0]
			return false
		var spouse: String = String(stored[row[0]].get("spouse",""))
		if not spouse.is_empty():
			if not stored.has(spouse) or String(stored[spouse].get("spouse",""))!=row[0]:
				restore_error = "non-reciprocal spouse: %s" % row[0]
				return false
	var history: Variant = record.get("events",[])
	if not (history is Array) or history.size()>256:
		restore_error = "history length"
		return false
	for entry in history:
		if not (entry is Dictionary) or not stored.has(String(entry.get("actor",""))):
			restore_error = "invalid event actor"
			return false
	# Schema-1 saves created before the resource economy receive default stocks.
	var next_economy=ECONOMY.new()
	var saved_economy: Variant=record.get("economy",{})
	if saved_economy is Dictionary and not saved_economy.is_empty():
		if not next_economy.restore(saved_economy):
			restore_error="invalid resource economy"
			return false
	var saved_day: int=int(record.get("current_day",0))
	var saved_jobs: Variant=record.get("commissions",{})
	if saved_day<0 or saved_day>3600000 or not (saved_jobs is Dictionary) or saved_jobs.size()>16:
		restore_error="invalid history or commissions"
		return false
	for job_id in saved_jobs:
		if String(job_id)!="farm_fertility" or not (saved_jobs[job_id] is Dictionary):
			restore_error="invalid commission"
			return false
		var stage: String=String(saved_jobs[job_id].get("status",""))
		if stage not in COMMISSIONS.STATES or int(saved_jobs[job_id].get("cycle",0))<1:
			restore_error="invalid commission state"
			return false
	var saved_field: int=int(record.get("field_fertility",0))
	if saved_field<0 or saved_field>6:
		restore_error="invalid field fertility"
		return false
	var saved_orders: Variant=record.get("work_orders",{})
	if not (saved_orders is Dictionary):
		restore_error="invalid work orders"
		return false
	for id in saved_orders:
		if not stored.has(id) or not (saved_orders[id] is Dictionary):
			restore_error="unknown work order"
			return false
		var job_role: String=String(saved_orders[id].get("role",""))
		var phase: String=String(saved_orders[id].get("phase",""))
		if job_role not in ["farmer","baker","blacksmith"] or String(stored[id]["role"])!=job_role or phase not in ["labor","delivery"] or (phase=="delivery" and job_role!="farmer"):
			restore_error="invalid work phase"
			return false
	economy=next_economy
	work_orders=saved_orders.duplicate(true)
	field_fertility=saved_field
	current_day=saved_day
	commissions=saved_jobs.duplicate(true)
	people = stored.duplicate(true)
	gene_seed=restore_gene_seed
	next_child_serial=maxi(1,int(record.get("next_child_serial",1)))
	if not record.has("next_child_serial"):
		for person_id in people:
			if String(person_id).begins_with("born_"):
				next_child_serial=maxi(next_child_serial,int(String(person_id).trim_prefix("born_"))+1)
	nearby_care.clear()
	care_contact.clear()
	events.clear()
	for entry in history:
		events.append(entry.duplicate(true))
	tick_count = maxi(0,int(record.get("tick",0)))
	next_event_id = maxi(1,int(record.get("next_event_id",1)))
	recent_action = record.get("recent_action",{}).duplicate(true) if record.get("recent_action",{}) is Dictionary else {}
	rng.state = int(record.get("rng_state",rng.state))
	return true
