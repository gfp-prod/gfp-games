extends SceneTree
## The playable village defers production until a worker completes a real trip.
## Standalone deterministic simulations must still keep their immediate-work mode.
const SIM = preload("res://scripts/village_sim.gd")
func _initialize() -> void: call_deferred("_run")
func fail(message: String) -> void:
	push_error("Village physical labor: " + message)
	quit(1)
func actor_for(world, id: String):
	for actor in world.npcs:
		if actor.npc_id==id: return actor
	return null
func _run() -> void:
	var standalone=SIM.new(101)
	var grain_initial: int=int(standalone.economy.stocks["grain"])
	standalone._act("daro","work")
	if int(standalone.economy.stocks["grain"])!=grain_initial+3 or not standalone.work_orders.is_empty():
		fail("Headless deterministic work mode regressed")
		return
	var world=load("res://main.tscn").instantiate()
	root.add_child(world)
	await process_frame
	var sim=world.village_sim
	if not sim.spatial_work_enabled:
		fail("Playable world is still using instant abstract production")
		return
	var economy=sim.economy
	var farmer=actor_for(world,"daro")
	var baker=actor_for(world,"ida")
	var smith=actor_for(world,"orin")
	if farmer==null or baker==null or smith==null:
		fail("Physical working citizens missing")
		return
	for worker in [farmer,baker,smith]:
		if worker.find_child("AnimatedRightArm",true,false)==null or worker.find_child("AnimatedLeftLeg",true,false)==null:
			fail("Worker has no articulated limbs: "+worker.npc_id)
			return
	var before: Dictionary=economy.stocks.duplicate(true)
	var funds: int=economy.treasury
	sim._act("daro","work")
	sim._act("ida","work")
	sim._act("orin","work")
	if sim.work_orders.size()!=3 or economy.stocks!=before or economy.treasury!=funds:
		fail("Assigning jobs created inventory or wages before work")
		return
	if sim.complete_work("daro"):
		fail("Farmer credited grain before harvest delivery")
		return
	if not sim.advance_work("daro") or sim.advance_work("daro"):
		fail("Field labor to cart delivery was not a one-way transition")
		return
	farmer._process(.15)
	if farmer.harvest_sack==null or not farmer.harvest_sack.visible:
		fail("Farmer is carrying no visible pending grain")
		return
	var snapshot: Dictionary=sim.snapshot()
	var copy=SIM.new(55)
	copy.spatial_work_enabled=true
	if not copy.restore(JSON.parse_string(JSON.stringify(snapshot))):
		fail("Could not restore an in-progress physical delivery: "+copy.restore_error)
		return
	var cargo_kept: bool=String(copy.work_orders["daro"]["phase"])=="delivery"
	for item in before:
		if int(copy.economy.stocks[item])!=int(before[item]): cargo_kept=false
	if not cargo_kept:
		fail("Save/load minted, lost, or settled cargo in transit")
		return
	if not sim.complete_work("daro") or sim.complete_work("daro"):
		fail("Farmer was not able to deposit exactly one physical harvest")
		return
	farmer._process(.15)
	if farmer.harvest_sack.visible:
		fail("Farmer kept already-delivered cargo")
		return
	if int(economy.stocks["grain"])!=int(before["grain"])+3 or int(economy.stocks["herb"])!=int(before["herb"])+1:
		fail("Harvest cart delivery did not reconcile finite stocks")
		return
	if not sim.complete_work("ida") or sim.complete_work("ida"):
		fail("Oven job completed incorrectly or more than once")
		return
	if int(economy.stocks["grain"])!=int(before["grain"])+1 or int(economy.stocks["bread"])!=int(before["bread"])+2:
		fail("Baker did not consume delivered grain and produce two bread")
		return
	if not sim.complete_work("orin") or sim.complete_work("orin"):
		fail("Forge job completed incorrectly or more than once")
		return
	if int(economy.stocks["ore"])!=int(before["ore"])-1 or int(economy.stocks["wood"])!=int(before["wood"])-1 or int(economy.stocks["tools"])!=int(before["tools"])+1:
		fail("Smith did not exchange ore and fuel for a tool")
		return
	if economy.treasury!=funds-3 or not sim.work_orders.is_empty():
		fail("Wages or pending-work settlement violated once-only accounting")
		return
	var restored: Dictionary=sim.snapshot()
	if not sim.restore(JSON.parse_string(JSON.stringify(restored))):
		fail("Completed jobs corrupted normal world save/load")
		return
	# Restore replaces the resource ledger object; discard the old pointer.
	economy=sim.economy
	var old=SIM.new(1).snapshot()
	old.erase("work_orders")
	var legacy=SIM.new(22)
	if not legacy.restore(old) or not legacy.work_orders.is_empty():
		fail("Previously saved villages are no longer compatible")
		return
	for worker in [farmer,baker,smith]:
		sim._act(worker.npc_id,"work")
	if sim.work_orders.size()!=3:
		fail("A completed job cannot be assigned again")
		return
	economy.stocks["grain"]=0
	economy.stocks["ore"]=0
	if sim.complete_work("ida") or sim.complete_work("orin"):
		fail("A depleted worksite fabricated output")
		return
	world.workplaces.refresh_from_economy(true)
	if world.workplaces.inspect_workplace("bakery").contains("Ready to bake"):
		fail("Visible oven ignores production shortage")
		return
	print("PASS: physical work orders, field-to-cart harvest, articulated workers, save-safe deliveries, exact resource/wage settlement and no duplicated goods")
	quit(0)
