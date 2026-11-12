extends RefCounted
## Persistent, modular human anatomy. Core injury facts are simulation data,
## never inferred from a damaged visual mesh or a detached physics prop.
const PARTS := ["left_arm","right_arm","left_leg","right_leg"]
const MAX_INTEGRITY := 50.0

static func new_state() -> Dictionary:
	var integrity: Dictionary={}
	for part in PARTS: integrity[part]=MAX_INTEGRITY
	return {"integrity":integrity,"missing":[],"bleeding":0.0,
		"vitality":100.0,"bandaged":false,"support":"none",
		"injured_tick":-1,"last_care_tick":-100}

static func validate(state: Variant) -> bool:
	if not (state is Dictionary): return false
	if not (state.get("integrity",null) is Dictionary): return false
	if not (state.get("missing",null) is Array): return false
	var lost: Array=state["missing"]
	if lost.size()>4: return false
	for part in lost:
		if part not in PARTS or lost.count(part)!=1: return false
	for part in PARTS:
		if not state["integrity"].has(part): return false
		var value: float=float(state["integrity"][part])
		if value<0.0 or value>MAX_INTEGRITY: return false
		if lost.has(part) and value>0.0: return false
	var flow: float=float(state.get("bleeding",-1.0))
	var life: float=float(state.get("vitality",-1.0))
	if flow<0.0 or flow>20.0 or life<0.0 or life>100.0: return false
	if String(state.get("support","none")) not in ["none","crutch","peg"]: return false
	if state.get("bandaged",false) is not bool: return false
	return true

static func injured(state: Dictionary) -> bool:
	return float(state.get("bleeding",0.0))>0.2 or not state.get("missing",[]).is_empty()

static func strike(state: Dictionary, part: String, force: float, tick: int) -> Dictionary:
	if part not in PARTS or force<=0.0 or not validate(state):
		return {"ok":false,"severed":false}
	if state["missing"].has(part) or float(state["vitality"])<=0.0:
		return {"ok":false,"severed":false}
	var previous: float=float(state["integrity"][part])
	var remaining: float=maxf(0.0,previous-minf(force,250.0))
	state["integrity"][part]=remaining
	var severed: bool=remaining<=0.0
	if severed:
		state["missing"].append(part)
		state["bleeding"]=minf(20.0,float(state["bleeding"])+4.5)
		state["bandaged"]=false
		if part.ends_with("_leg"): state["support"]="none"
	else:
		state["bleeding"]=minf(20.0,float(state["bleeding"])+force*.012)
	state["vitality"]=maxf(0.0,float(state["vitality"])-force*.10)
	state["injured_tick"]=tick
	return {"ok":true,"severed":severed,"part":part,
		"bleeding":state["bleeding"],"remaining":remaining}

static func passage(state: Dictionary) -> void:
	if not validate(state): return
	var flow: float=float(state["bleeding"])
	if flow>.0:
		state["vitality"]=maxf(0.0,float(state["vitality"])-flow*.45)
		state["bleeding"]=maxf(0.0,flow-(.055 if not bool(state["bandaged"]) else .75))
	elif float(state["vitality"])<100.0:
		state["vitality"]=minf(100.0,float(state["vitality"])+.14)

static func needs_support(state: Dictionary) -> bool:
	return (state["missing"].has("left_leg") or state["missing"].has("right_leg")) and not (
		state["missing"].has("left_leg") and state["missing"].has("right_leg"))

static func aid_kind(state: Dictionary, stocks: Dictionary) -> String:
	if not validate(state) or float(state["vitality"])<=0.0: return ""
	if float(state["bleeding"])>.2 and int(stocks.get("herb",0))>=1: return "bandage"
	if needs_support(state) and String(state["support"])=="none":
		if int(stocks.get("wood",0))>=1 and int(stocks.get("tools",0))>=1: return "peg"
		if int(stocks.get("wood",0))>=1: return "crutch"
	return ""

static func aid(state: Dictionary, kind: String, tick: int) -> bool:
	if not validate(state) or float(state["vitality"])<=0.0: return false
	if kind=="bandage" and float(state["bleeding"])>.2:
		state["bandaged"]=true
		state["bleeding"]=maxf(0.0,float(state["bleeding"])*.12)
		state["last_care_tick"]=tick
		return true
	if kind=="crutch" and needs_support(state) and state["support"]=="none":
		state["support"]="crutch"
		state["last_care_tick"]=tick
		return true
	if kind=="peg" and needs_support(state) and state["support"] in ["none","crutch"]:
		state["support"]="peg"
		state["last_care_tick"]=tick
		return true
	return false

static func locomotion(state: Dictionary) -> float:
	if not validate(state): return 1.0
	if float(state["vitality"])<=0.0: return 0.0
	var legs: int=int(state["missing"].has("left_leg"))+int(state["missing"].has("right_leg"))
	if legs>=2: return 0.0
	if legs==0: return 1.0
	match String(state["support"]):
		"peg": return .78
		"crutch": return .58
		_: return .22
