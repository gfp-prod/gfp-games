extends SceneTree
## Book-learned Latin changes physical field growth, but never mints stored grain
## until the farmer has worked and delivered a real harvest to the cart.
const SIM=preload("res://scripts/village_sim.gd")
func _initialize() -> void: call_deferred("_run")
func fail(message: String) -> void:
	push_error("Latin field economy: "+message)
	quit(1)
func _run() -> void:
	var world=load("res://main.tscn").instantiate()
	root.add_child(world)
	await process_frame
	var sim=world.village_sim
	var scholar=world.scholar
	var farmer=world.player
	var farm_at=Vector3(18.0,world.height_at(18.0,27.0),27.0)
	farmer.global_position=Vector3(17.9,world.height_at(17.9,25.5)+.15,25.5)
	var utterance: Dictionary={"position":farm_at}
	var grain_before: int=int(sim.economy.stocks["grain"])
	var herb_before: int=int(sim.economy.stocks["herb"])
	var coins_before: int=sim.economy.treasury
	var unstudied_mana: float=scholar.mana
	if bool(farmer.cast_latin("crescite, herbae",utterance).get("ok",true)) or absf(scholar.mana-unstudied_mana)>.01:
		fail("Unstudied plural farming spell succeeded or spent mana")
		return
	var first: Dictionary=farmer.cast_latin("cresce",utterance)
	if not bool(first.get("ok",false)) or sim.field_fertility!=1 or absf(scholar.mana-(unstudied_mana-7.0))>.01:
		fail("Basic imperative failed to grow one real field charge at mana cost")
		return
	if not scholar.collect_book("de_herbis") or not bool(scholar.answer("de_herbis",0).get("first_time",false)):
		fail("Could not study physical botany book")
		return
	var studied_mana: float=scholar.mana
	var plural: Dictionary=farmer.cast_latin("crescite, herbae",utterance)
	if not bool(plural.get("ok",false)) or sim.field_fertility!=3 or absf(scholar.mana-(studied_mana-7.0))>.01:
		fail("Learned plural imperative did not improve real field with proper mana")
		return
	if int(sim.economy.stocks["grain"])!=grain_before or int(sim.economy.stocks["herb"])!=herb_before:
		fail("Latin magic generated inventory before a farmer delivered crops")
		return
	if world.workplaces.growing_stalks.size()!=40 or world.workplaces.growing_stalks[0].scale.y<1.19:
		fail("Enchanted crop height does not change in the rendered level")
		return
	if not world.workplaces.inspect_workplace("grain").contains("3 growth"):
		fail("Grain-cart inspection does not explain pending field magic")
		return
	# In the playable world, the farmer must labor, then carry cargo to cart.
	sim._act("daro","work")
	if not sim.work_orders.has("daro") or int(sim.economy.stocks["grain"])!=grain_before:
		fail("A magical field bypassed physical labor")
		return
	var pending: Dictionary=sim.snapshot()
	var restore_copy=SIM.new(3)
	restore_copy.spatial_work_enabled=true
	if not restore_copy.restore(JSON.parse_string(JSON.stringify(pending))) or restore_copy.field_fertility!=3:
		fail("In-progress enchanted harvest did not survive save/load")
		return
	if not sim.advance_work("daro") or not sim.complete_work("daro"):
		fail("Farmer could not deliver enchanted harvest")
		return
	if int(sim.economy.stocks["grain"])!=grain_before+5 or int(sim.economy.stocks["herb"])!=herb_before+1 or sim.field_fertility!=1:
		fail("Delivered harvest did not settle precisely two bonus grain")
		return
	if sim.complete_work("daro"):
		fail("Repeat completion duplicated magical crop delivery")
		return
	sim._act("daro","work")
	if not sim.advance_work("daro") or not sim.complete_work("daro"):
		fail("Second harvest did not complete")
		return
	if int(sim.economy.stocks["grain"])!=grain_before+9 or sim.field_fertility!=0:
		fail("Unused field magic was not consumed on second harvest")
		return
	if sim.economy.treasury!=coins_before-2:
		fail("Magical harvest bypassed finite wage transfers")
		return
	if restore_copy.advance_work("daro") and restore_copy.complete_work("daro"):
		if int(restore_copy.economy.stocks["grain"])!=grain_before+5:
			fail("Restored delivery settled different crop quantity")
			return
	else:
		fail("Restored delivery could not complete")
		return
	sim.bless_field(20)
	if sim.field_fertility!=6: fail("Field is not capped at six growth charges");return
	var full_mana: float=scholar.mana
	if bool(farmer.cast_latin("cresce",utterance).get("ok",true)) or scholar.mana!=full_mana:
		fail("Overgrown full field still charged mana")
		return
	var corrupted: Dictionary=sim.snapshot()
	corrupted["field_fertility"]=99
	if SIM.new().restore(corrupted):
		fail("Impossible stored field growth was accepted")
		return
	var old: Dictionary=sim.snapshot()
	old.erase("field_fertility")
	if not SIM.new().restore(old):
		fail("Older saves missing fertility were rejected")
		return
	print("PASS: study-gated plural Latin grows actual crops, real mana costs, deferred enriched harvest, no phantom grain, bounded persistence and old saves")
	quit(0)
