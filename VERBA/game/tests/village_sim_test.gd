extends SceneTree
## Headless simulation checks. Runs without loading expensive terrain/GLBs.
const SIM = preload("res://scripts/village_sim.gd")

func _initialize() -> void:
	call_deferred("_run")

func _fail(message: String) -> void:
	push_error("Village simulation: " + message)
	quit(1)

func _check_invariants(sim) -> String:
	if sim.people.size()!=13: return "Wrong population"
	for id in sim.people:
		var p: Dictionary = sim.people[id]
		if String(p.get("id",""))!=id: return "Unstable NPC ID"
		if int(p["wealth"])<0 or int(p["wealth"])>100: return "Invalid wealth for %s: %s (last=%s)" % [id,str(p["wealth"]),str(p["last_action"])]
		for metric in ["hunger","fatigue","loneliness","mood"]:
			if float(p[metric])<0.0 or float(p[metric])>100.0:
				return "Out of bounds " + metric
		var spouse: String = String(p["spouse"])
		if not spouse.is_empty() and (not sim.people.has(spouse) or String(sim.people[spouse]["spouse"])!=id):
			return "Nonreciprocal spouse link"
	var known: Dictionary = {}
	for event in sim.events:
		if known.has(event["id"]): return "Duplicate event ID"
		known[event["id"]] = true
		if not sim.people.has(event["actor"]): return "Unknown event actor"
		for witness in event["witnesses"]:
			if not sim.people.has(witness): return "Unknown event witness"
	return ""

func _canonical(snapshot_record: Dictionary) -> String:
	# Godot JSON parses all numeric literals as float; 74 and 74.0 have
	# identical meaning on disk but different pre-serialization text.
	return JSON.stringify(JSON.parse_string(JSON.stringify(snapshot_record)))

func _run() -> void:
	var variety: Dictionary = {}
	for seed_value in range(100):
		var sim = SIM.new(seed_value + 100)
		for day in range(7):
			for hour in range(24):
				sim.step()
				var error: String = _check_invariants(sim)
				if not error.is_empty():
					_fail("seed=%d day=%d hour=%d: %s" % [seed_value,day,hour,error])
					return
		for e in sim.events:
			variety[String(e["type"])] = true
	if variety.size()<4:
		_fail("Too few independent social event types across 100 seeds")
		return
	var a = SIM.new(9801)
	var b = SIM.new(9801)
	for i in range(160):
		a.step()
		b.step()
	if _canonical(a.snapshot())!=_canonical(b.snapshot()):
		_fail("Same seed does not produce the same state")
		return
	var save: Dictionary = a.snapshot()
	var loaded = SIM.new(42)
	if not loaded.restore(JSON.parse_string(JSON.stringify(save))):
		_fail("Could not restore JSON-round-tripped village: " + loaded.restore_error)
		return
	if _canonical(a.snapshot()) != _canonical(loaded.snapshot()):
		var before: String = _canonical(a.snapshot())
		var after: String = _canonical(loaded.snapshot())
		var first: int = 0
		while first < mini(before.length(),after.length()) and before[first]==after[first]: first += 1
		_fail("Load differs byte=%d expected=%s actual=%s rng=%s/%s" % [first,before.substr(maxi(0,first-80),160),after.substr(maxi(0,first-80),160),str(a.rng.state),str(loaded.rng.state)])
		return
	for i in range(70):
		a.step()
		loaded.step()
	if _canonical(a.snapshot())!=_canonical(loaded.snapshot()):
		var left: String = _canonical(a.snapshot())
		var right: String = _canonical(loaded.snapshot())
		var offset: int = 0
		while offset < mini(left.length(),right.length()) and left[offset] == right[offset]: offset += 1
		_fail("Replay mismatch byte=%d expected=%s got=%s" % [offset,left.substr(maxi(0,offset-80),160),right.substr(maxi(0,offset-80),160)])
		return
	var broken: Dictionary = loaded.snapshot()
	broken["people"]["ida"]["spouse"] = "titus"
	if loaded.restore(broken):
		_fail("Invalid family links were accepted")
		return
	var isolated = SIM.new(4455)
	if not isolated.witness_event("theft","orin","ida"):
		_fail("Cannot register witnessed crime")
		return
	var crime: Dictionary = isolated.events.back()
	for id in isolated.people:
		if not crime["witnesses"].has(id) and isolated.people[id]["known_events"].has(crime["id"]):
			_fail("An unwitnessed crime became omniscient knowledge")
			return
	print("PASS: 100 seeds x 7 days, bounded state, witnessed events, independent event variety, deterministic replay, JSON save/load and invalid family rejection")
	quit(0)
