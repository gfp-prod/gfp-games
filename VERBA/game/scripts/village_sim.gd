extends RefCounted
## Deterministic social simulation. No scene nodes, UI, or omniscient world knowledge.
## Each fixed tick evaluates circumstances; actions emit causal, witnessed events.
const VERSION := 1
const ECONOMY = preload("res://scripts/village_economy.gd")
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
	["sela","merchant","wolf",57,65,72]
]
var rng := RandomNumberGenerator.new()
var economy = ECONOMY.new()
var last_scores: Dictionary = {}
var people: Dictionary = {}
var events: Array[Dictionary] = []
var tick_count := 0
var next_event_id := 1
var recent_action: Dictionary = {}
var seeded := false
var restore_error: String = ""

func _init(seed_value: int = 1938) -> void:
	reset(seed_value)

func reset(seed_value: int) -> void:
	rng.seed = seed_value
	people.clear()
	events.clear()
	recent_action.clear()
	last_scores.clear()
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
			"known_events":[],"last_action":"idle","alive":true}
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
		"work": return (15.0 + crow*32.0 + (8.0 if int(p["wealth"]) < 4 else 0.0) - float(p["fatigue"])*0.30) if economy.can_work(String(p["role"])) else -1.0
		"socialize": return float(p["loneliness"])*0.80 + cat*22.0 - float(p["fatigue"])*0.12
		"court": return float(p["loneliness"])*0.58 + cat*25.0 + wolf*8.0 - (22.0 if not String(p["spouse"]).is_empty() else 0.0)
		"steal": return (46.0 if int(p["wealth"]) < 3 else -25.0) + wolf*28.0 - crow*14.0
		"investigate": return 18.0 + wolf*30.0 if String(p["role"])=="guard" and _unresolved_crime_known(p) else -1.0
	return -1.0

func _unresolved_crime_known(p: Dictionary) -> bool:
	for entry in events:
		if entry["type"] == "theft" and not bool(entry.get("resolved",false)) and p["known_events"].has(entry["id"]):
			return true
	return false

func _select(p: Dictionary) -> String:
	var scores: Dictionary = {}
	for action in ["eat","rest","work","socialize","court","steal","investigate"]:
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
			if economy.work(id,String(p["role"]),p):
				p["fatigue"] = minf(100.0,float(p["fatigue"])+12.0)
				p["mood"] = minf(100.0,float(p["mood"])+float(p["crow"])*0.035)
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

func step() -> void:
	tick_count += 1
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
		p["hunger"] = minf(100.0,float(p["hunger"])+3.5)
		p["fatigue"] = minf(100.0,float(p["fatigue"])+2.5)
		p["loneliness"] = minf(100.0,float(p["loneliness"])+2.0)
		_act(id,_select(p))
	_stabilize_floats()

func witness_event(kind: String, actor: String, target: String = "") -> bool:
	if not people.has(actor): return false
	if not target.is_empty() and not people.has(target): return false
	_event(kind,actor,target)
	return true

func inspector(id: String) -> Dictionary:
	if not people.has(id): return {}
	var p: Dictionary=people[id]
	var ranked: Array[Dictionary]=[]
	for action in ["eat","rest","work","socialize","court","steal","investigate"]:
		ranked.append({"action":action,"score":_score(p,action)})
	ranked.sort_custom(func(a,b): return float(a["score"])>float(b["score"]))
	return {"id":id,"person":p.duplicate(true),"ranked_actions":ranked,
		"stocks":economy.stocks.duplicate(true),"treasury":economy.treasury,
		"recent_transactions":economy.transactions.slice(maxi(0,economy.transactions.size()-8)),
		"tick":tick_count}

func snapshot() -> Dictionary:
	return {"version":VERSION,"tick":tick_count,"rng_state":str(rng.state),
		"next_event_id":next_event_id,"people":people.duplicate(true),
		"events":events.duplicate(true),"recent_action":recent_action.duplicate(true),
		"economy":economy.snapshot()}

func restore(record: Dictionary) -> bool:
	restore_error = ""
	if int(record.get("version",0))!=VERSION:
		restore_error = "schema version"
		return false
	var stored: Variant = record.get("people",{})
	if not (stored is Dictionary) or stored.size()!=ROLES.size():
		restore_error = "population: %d" % stored.size()
		return false
	for row in ROLES:
		if not stored.has(row[0]) or not (stored[row[0]] is Dictionary):
			restore_error = "missing person: %s" % row[0]
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
	economy=next_economy
	people = stored.duplicate(true)
	events.clear()
	for entry in history:
		events.append(entry.duplicate(true))
	tick_count = maxi(0,int(record.get("tick",0)))
	next_event_id = maxi(1,int(record.get("next_event_id",1)))
	recent_action = record.get("recent_action",{}).duplicate(true) if record.get("recent_action",{}) is Dictionary else {}
	rng.state = int(record.get("rng_state",rng.state))
	return true
