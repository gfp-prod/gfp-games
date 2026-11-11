extends SceneTree
## Two complete player professions: craftable physical items, inventory and
## vigor costs, apprentice progression, Latin hearth, dynamic merchant stock,
## saved gear and coins. Every output must come from a real input.
const PERSIST=preload("res://scripts/world_persistence.gd")
func _initialize() -> void: call_deferred("_run")
func _fail(message: String) -> void:
	push_error("Artisan professions: "+message)
	quit(1)
func _move_near(world,player,x: float,z: float) -> void:
	player.position=Vector3(x,world.height_at(x,z)+.21,z)
func _run() -> void:
	var world=load("res://main.tscn").instantiate()
	root.add_child(world)
	await process_frame
	var player=world.player
	var artisans=player.professions
	var ledger=world.village_sim.economy
	_move_near(world,player,8.9,13.7)
	await physics_frame
	var stamina_before: float=player.stamina
	var empty: Dictionary=artisans.craft("bakery",player)
	if bool(empty.get("ok",true)) or player.stamina!=stamina_before or not player.inventory.is_empty():
		_fail("Empty hands produced a loaf or charged stamina")
		return
	player.inventory.append_array(["grain","wood"])
	player.refresh_held_model()
	var first: Dictionary=artisans.craft("bakery",player)
	if not bool(first.get("ok",false)) or player.inventory!=["bread"]:
		_fail("Physical baking did not exchange grain plus wood for one loaf")
		return
	if absf(player.stamina-(stamina_before-18.0))>.01 or int(artisans.experience["baker"])!=1:
		_fail("Basic baking had no vigor cost or apprenticeship progress")
		return
	var wage_stock: int=int(ledger.stocks["bread"])
	var funds: int=ledger.treasury
	var ida_trust: float=float(world.village_sim.people["ida"]["trust"].get("wizard",0.0))
	var sale: Dictionary=world.social.choose("ida",4,world.scholar,player)
	if not bool(sale.get("ok",false)) or player.coins!=2 or player.inventory.has("bread"):
		_fail("Ida did not purchase a real player-made loaf for finite money")
		return
	if int(ledger.stocks["bread"])!=wage_stock+1 or ledger.treasury!=funds-2:
		_fail("Selling a loaf failed to credit public stock and debit public funds")
		return
	if float(world.village_sim.people["ida"]["trust"].get("wizard",0.0))<=ida_trust:
		_fail("Artisan services are invisible to NPC reputation")
		return
	var double_sale: Dictionary=world.social.choose("ida",4,world.scholar,player)
	if bool(double_sale.get("ok",false)) or player.coins!=2 or ledger.treasury!=funds-2:
		_fail("A sold loaf could be sold again for duplicate coins")
		return
	var supplies_before: int=int(ledger.stocks["ore"])
	var ore_buy: Dictionary=world.social.choose("sela",5,world.scholar,player)
	if not bool(ore_buy.get("ok",false)) or player.coins!=0 or not player.inventory.has("ore"):
		_fail("Sela's actual market cannot sell iron ore")
		return
	if int(ledger.stocks["ore"])!=supplies_before-1 or ledger.treasury!=funds:
		_fail("Supply purchase failed to reconcile village ore or currency")
		return
	var denied: Dictionary=world.social.choose("sela",5,world.scholar,player)
	if bool(denied.get("ok",false)) or player.coins<0:
		_fail("An empty wallet can purchase market ingredients")
		return
	_move_near(world,player,21.8,17.1)
	await physics_frame
	var cannot_forge: Dictionary=artisans.craft("forge",player)
	if bool(cannot_forge.get("ok",true)):
		_fail("Ore can be forged without fuel or studied magic")
		return
	var forge_body=world.workplaces.find_child("PhysicalCoalForge",true,false)
	if forge_body==null or not forge_body.has_meta("workplace_kind"):
		_fail("Forging is disconnected from the physical workshop collider")
		return
	var magic_before: float=world.scholar.mana
	var ignited: Dictionary=player.cast_latin("ignis",{"entity":forge_body,"position":forge_body.global_position})
	if not bool(ignited.get("ok",false)) or int(artisans.charged_hearths["blacksmith"])!=1:
		_fail("Known Latin IGNIS did not fuel the actual anvil economy")
		return
	if world.scholar.mana>=magic_before or world.scholar.mana<0:
		_fail("Latin heating created free magic without paying mana")
		return
	var second_ignition: Dictionary=player.cast_latin("ignis",{"entity":forge_body,"position":forge_body.global_position})
	if bool(second_ignition.get("ok",true)) or int(artisans.charged_hearths["blacksmith"])!=1:
		_fail("A prepared magical furnace accepted an unlimited duplicate charge")
		return
	var tool_work: Dictionary=artisans.craft("forge",player)
	if not bool(tool_work.get("ok",false)) or not player.inventory.has("tools") or player.inventory.has("ore"):
		_fail("Blacksmith did not consume real ore and create a real tool")
		return
	if int(artisans.charged_hearths["blacksmith"])!=0 or int(artisans.experience["blacksmith"])!=1:
		_fail("Forging failed to consume the magical ember exactly once")
		return
	var tool_stock_before: int=int(ledger.stocks["tools"])
	var coin_before: int=player.coins
	var blacksmith_payment: Dictionary=world.social.choose("orin",3,world.scholar,player)
	if not bool(blacksmith_payment.get("ok",false)) or player.coins!=coin_before+4 or player.inventory.has("tools"):
		_fail("Orin could not buy the smith's forged tool")
		return
	if int(ledger.stocks["tools"])!=tool_stock_before+1 or ledger.treasury!=funds-4:
		_fail("Tool sale did not move real tools and coins")
		return
	# Second work and skilled recipes are not imaginary inventory icons.
	_move_near(world,player,8.9,13.7)
	await physics_frame
	player.inventory.append_array(["grain","wood"])
	player.refresh_held_model()
	var bread_second: Dictionary=artisans.craft("bakery",player)
	if not bool(bread_second.get("ok",false)) or int(artisans.experience["baker"])!=2:
		_fail("Repeated real baking did not train the apprentice")
		return
	player.inventory.append_array(["herb","wood"])
	player.refresh_held_model()
	# Select bread; buying/making ingredients in a different order is valid.
	player.selected_slot=player.inventory.find("bread")
	player.refresh_held_model()
	var advanced: Dictionary=artisans.craft("bakery",player)
	if not bool(advanced.get("ok",false)) or not player.inventory.has("herb_bread"):
		_fail("Higher-rank baking failed to craft the genuine restorative loaf")
		return
	var save: Dictionary=PERSIST.snapshot(world)
	var fresh=load("res://main.tscn").instantiate()
	root.add_child(fresh)
	await process_frame
	if not PERSIST.apply_snapshot(fresh,JSON.parse_string(JSON.stringify(save))):
		_fail("Crafting a career corrupts the living-world save")
		return
	if not fresh.player.inventory.has("herb_bread") or int(fresh.player.professions.experience["baker"])!=3 or int(fresh.player.professions.experience["blacksmith"])!=1:
		_fail("Craftable goods and career advancement do not survive save/load")
		return
	if fresh.player.coins!=4 or int(fresh.village_sim.economy.stocks["tools"])!=tool_stock_before+1:
		_fail("Finance and public stock have diverged after reload")
		return
	if not fresh.player.professions.restore({}):
		_fail("Older saves without a profession record cannot migrate")
		return
	var corrupted: Dictionary=save.duplicate(true)
	corrupted["player"]["professions"]["experience"]["baker"]=-1
	if PERSIST.apply_snapshot(fresh,corrupted):
		_fail("Corrupt saved professions were accepted")
		return
	# The 3D inventory item must remain a real dropped pickup.
	fresh.player.inventory.clear()
	fresh.player.inventory.append("herb_bread")
	fresh.player.selected_slot=0
	fresh.player.refresh_held_model()
	var count_before: int=fresh.items.size()
	fresh.player.drop_item()
	if fresh.items.size()!=count_before+1 or fresh.items.back().item_type!="herb_bread" or fresh.items.back().persistent_id.is_empty():
		_fail("Crafted bread could not exist as persistent loose world loot")
		return
	print("PASS: two playable artisan professions, physical inventory recipes, magic versus fuel, honest stamina, finite wages/supplies, apprenticeship, NPC trust, save/load, loose gear and anti-duplication")
	quit(0)
