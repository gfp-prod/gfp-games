extends SceneTree
const SIM=preload("res://scripts/village_sim.gd")
const ECON=preload("res://scripts/village_economy.gd")
func _initialize() -> void: call_deferred("_run")
func _fail(message: String) -> void:
	push_error("Village economy/lab: "+message)
	quit(1)
func _run() -> void:
	var e=ECON.new()
	var farmer={"wealth":0,"hunger":60.0}
	var baker={"wealth":2,"hunger":60.0}
	var grain_before: int=e.stocks["grain"]
	if not e.work("daro","farmer",farmer) or int(e.stocks["grain"])!=grain_before+3:
		_fail("Farmer produced no real grain")
		return
	if not e.work("ida","baker",baker) or int(e.stocks["grain"])!=grain_before+1:
		_fail("Baker did not consume grain")
		return
	var coins: int=baker["wealth"]
	var bread: int=e.stocks["bread"]
	if not e.eat("ida",baker) or baker["wealth"]!=coins-1 or e.stocks["bread"]!=bread-1:
		_fail("Eating did not transfer coins and consume bread")
		return
	e.stocks["grain"]=0
	if e.can_work("baker") or e.work("ida","baker",baker):
		_fail("Baker created food without grain")
		return
	var before: Dictionary=e.snapshot()
	var restored=ECON.new()
	if not restored.restore(JSON.parse_string(JSON.stringify(before))):
		_fail("JSON economic restore failed")
		return
	if JSON.stringify(JSON.parse_string(JSON.stringify(restored.snapshot())))!=JSON.stringify(JSON.parse_string(JSON.stringify(before))):
		_fail("Economic save/load changed resource ledger")
		return
	var corrupted: Dictionary=e.snapshot()
	corrupted["stocks"]["bread"]=-3
	if restored.restore(corrupted):
		_fail("Accepted negative inventory")
		return
	var sim=SIM.new(1122)
	var report: Dictionary=sim.inspector("ida")
	if report.is_empty() or report["ranked_actions"].size()!=7:
		_fail("Inspector missing complete utility action ranking")
		return
	for i in range(720):
		sim.step()
		for item in sim.economy.stocks:
			var amount: int=sim.economy.stocks[item]
			if amount<0 or amount>500:
				_fail("Resource bounds broken at tick %d: %s=%d" % [i,item,amount])
				return
		if sim.economy.treasury<0:
			_fail("Negative treasury")
			return
	var snap: Dictionary=sim.snapshot()
	var copy=SIM.new(1)
	if not copy.restore(JSON.parse_string(JSON.stringify(snap))):
		_fail("Integrated village+economy restore failed")
		return
	for i in range(120):
		sim.step()
		copy.step()
	var left: String=JSON.stringify(JSON.parse_string(JSON.stringify(sim.snapshot())))
	var right: String=JSON.stringify(JSON.parse_string(JSON.stringify(copy.snapshot())))
	if left!=right:
		_fail("Economic replay diverged after restore")
		return
	print("PASS: real input/output production, finite food and currency, zero-stock refusal, 720-tick bounds, inspector ranking and deterministic economic save/replay")
	quit(0)
