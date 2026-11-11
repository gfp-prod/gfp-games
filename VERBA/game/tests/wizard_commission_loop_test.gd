extends SceneTree
## Real world integration: study -> talk -> act on crops -> trust/wages ->
## pass calendar days -> revisit -> save and restore. Failure paths too.
const CLOCK=preload("res://scripts/world_calendar.gd")
const PERSIST=preload("res://scripts/world_persistence.gd")
const JOBS=preload("res://scripts/wizard_commissions.gd")
func _initialize() -> void: call_deferred("_run")
func _fail(message: String) -> void:
	push_error("Wizard commission integration: "+message)
	quit(1)
func _run() -> void:
	var clock=CLOCK.new()
	if clock.hour()!=9 or clock.darkness()>.1:
		_fail("Clock does not begin in daylight")
		return
	clock.advance(140.0)
	if not clock.is_night() or clock.darkness()<.6:
		_fail("Solar clock does not produce night")
		return
	clock.advance(20.0)
	if clock.day!=1 or clock.hour()!=1:
		_fail("Calendar does not cross midnight correctly")
		return
	var clock_saved: Dictionary=clock.snapshot()
	var copy=CLOCK.new()
	if not copy.restore(JSON.parse_string(JSON.stringify(clock_saved))) or copy.snapshot()["day"]!=1:
		_fail("Calendar did not survive JSON serialization")
		return
	if copy.restore({"version":1,"day":-8,"elapsed":0}):
		_fail("Corrupted calendar accepted")
		return
	var world=load("res://main.tscn").instantiate()
	root.add_child(world)
	await process_frame
	var sim=world.village_sim
	var farmer=world.player
	var scholar=world.scholar
	if not world.social.view("daro",scholar,farmer.inventory)["options"].size()==6:
		_fail("Real Daro conversation has no accept and refuse options")
		return
	var refused=world.social.choose("daro",5,scholar,farmer)
	if not bool(refused.get("ok",false)) or JOBS.state(sim)!="declined":
		_fail("Refusal is not recorded")
		return
	var trust_after_refusal: float=float(sim.people["daro"]["trust"].get("wizard",0.0))
	if trust_after_refusal>=-1.0:
		_fail("Refusal had no personal social consequence")
		return
	var data: Dictionary=PERSIST.snapshot(world)
	var reloaded=load("res://main.tscn").instantiate()
	root.add_child(reloaded)
	await process_frame
	if not PERSIST.apply_snapshot(reloaded,JSON.parse_string(JSON.stringify(data))):
		_fail("Persistent request could not be loaded into a fresh world")
		return
	if JOBS.state(reloaded.village_sim)!="declined" or absf(float(reloaded.village_sim.people["daro"]["trust"]["wizard"])-trust_after_refusal)>.01:
		_fail("Refusal and personal reputation were forgotten on load")
		return
	world.skip_days(3)
	if JOBS.state(sim)!="offered" or sim.current_day!=world.world_calendar.day:
		_fail("Daily reoffer did not use the one authoritative clock")
		return
	var accepted=world.social.choose("daro",4,scholar,farmer)
	if not bool(accepted.get("ok",false)) or JOBS.state(sim)!="accepted":
		_fail("Daro did not accept the player's help")
		return
	var field=Vector3(18.0,world.height_at(18.0,27.0),27.0)
	farmer.global_position=Vector3(18.0,world.height_at(18.0,25.0)+.25,25.0)
	await physics_frame
	var grain_start: int=int(sim.economy.stocks["grain"])
	var mana_start: float=scholar.mana
	if bool(farmer.cast_latin("crescite, herbae",{"position":field}).get("ok",true)) or scholar.mana!=mana_start:
		_fail("Unknown plural field magic worked or consumed mana")
		return
	if not scholar.collect_book("de_herbis") or not bool(scholar.answer("de_herbis",0).get("first_time",false)):
		_fail("Player could not learn the real herbal lesson")
		return
	var mana_studied: float=scholar.mana
	var magic=farmer.cast_latin("crescite, herbae",{"position":field})
	if not bool(magic.get("ok",false)) or JOBS.state(sim)!="ready" or sim.field_fertility!=2:
		_fail("Mastered Latin did not affect field and fulfill the request")
		return
	if absf(scholar.mana-(mana_studied-7.0))>.01 or int(sim.economy.stocks["grain"])!=grain_start:
		_fail("Latin task has wrong resource cost or minted grain without harvest")
		return
	if world.social.view("daro",scholar,farmer.inventory)["options"].size()!=5:
		_fail("Real dialogue does not offer a context-specific payment")
		return
	var paid=world.social.choose("daro",4,scholar,farmer)
	if not bool(paid.get("ok",false)) or JOBS.state(sim)!="rewarded" or not farmer.inventory.has("grain"):
		_fail("Actual NPC did not give the player a real traded object")
		return
	if int(sim.economy.stocks["grain"])!=grain_start-1:
		_fail("Commission payout created goods from nothing")
		return
	if float(sim.people["daro"]["trust"].get("wizard",0.0))<=trust_after_refusal:
		_fail("Helping did not change Daro's opinion")
		return
	var finished: Dictionary=PERSIST.snapshot(world)
	var new_world=load("res://main.tscn").instantiate()
	root.add_child(new_world)
	await process_frame
	if not PERSIST.apply_snapshot(new_world,JSON.parse_string(JSON.stringify(finished))):
		_fail("Completed task save could not load")
		return
	if JOBS.state(new_world.village_sim)!="rewarded" or not new_world.player.inventory.has("grain"):
		_fail("Finished job or physical wage disappeared after loading")
		return
	if new_world.world_calendar.day!=world.world_calendar.day or new_world.village_sim.current_day!=new_world.world_calendar.day:
		_fail("Village and world calendar diverged on reload")
		return
	world.skip_days(3)
	if JOBS.state(sim)!="offered":
		_fail("Request cannot be repeated after several days")
		return
	var second=world.social.choose("daro",4,scholar,farmer)
	if not bool(second.get("ok",false)): _fail("Second request failed");return
	var spoiled=farmer.cast_latin("ignis",{"position":field})
	if not bool(spoiled.get("ok",false)) or JOBS.state(sim)!="abandoned":
		_fail("Dangerous magic did not produce a negative social outcome")
		return
	if float(sim.people["daro"]["trust"].get("wizard",0.0))>=float(new_world.village_sim.people["daro"]["trust"].get("wizard",0.0)):
		_fail("Sabotage had no reputation cost")
		return
	print("PASS: authoritative clock day/night, discover/learn Latin, commission dialogue, real magic, finite wages, mutable reputation, consequences across days and save/reload")
	quit(0)
