extends SceneTree
## Actual Godot careers: near-workstation crafting, finite feedstock, Latin
## ignition, physical mining, NPC sale, persistence and no duplicated items.
const PERSIST=preload("res://scripts/world_persistence.gd")
const CAREERS=preload("res://scripts/player_professions.gd")
func _initialize() -> void: call_deferred("_run")
func fail(message: String) -> void:
	push_error("Player artisan professions: "+message)
	quit(1)
func station(world,kind: String):
	for node in world.workplaces.find_children("*","StaticBody3D",true,false):
		if node.has_meta("workplace_kind") and String(node.get_meta("workplace_kind"))==kind:
			return node
	return null
func prepare(player,items: Array[String],selected: int=0) -> void:
	player.inventory=items.duplicate()
	player.selected_slot=selected
	player.refresh_held_model()
func _run() -> void:
	var world=load("res://main.tscn").instantiate()
	root.add_child(world)
	await process_frame
	var player=world.player
	var prof=player.professions
	var oven=station(world,"bakery")
	var forge=station(world,"forge")
	if oven==null or forge==null:
		fail("The physical kiln and forge have no targetable colliders")
		return
	var iron_vein=null
	for obj in world.sim_objects:
		if obj.has_meta("ore_vein"): iron_vein=obj
	if iron_vein==null or not iron_vein.has_meta("resource_deposit"):
		fail("Crafting has no real, harvestable ferrous deposit")
		return
	if prof.craft("bakery",player).get("ok",true):
		fail("Remote bare-hand crafting succeeded")
		return
	player.global_position=Vector3(8.9,world.height_at(8.9,14.2)+.2,14.2)
	prepare(player,["grain","wood"])
	var stamina_before: float=player.stamina
	# Prove the ordinary player-facing F key reaches the physical oven,
	# not merely the headless career calculation.
	await physics_frame
	player.camera.look_at(oven.global_position+Vector3.UP*1.0,Vector3.UP)
	await physics_frame
	var aim: Dictionary=player.look_hit(4.5)
	var aimed_object=aim.get("entity",null)
	if aimed_object==null or not aimed_object.has_meta("workplace_kind") or String(aimed_object.get_meta("workplace_kind"))!="bakery":
		fail("First-person eye ray cannot actually reach the oven collider")
		return
	var f_key:=InputEventKey.new()
	f_key.keycode=KEY_F
	f_key.pressed=true
	player._input(f_key)
	if not player.inventory.has("bread") or player.inventory.has("grain") or player.inventory.has("wood"):
		fail("Pressing real F at the oven did not make a carried loaf")
		return
	if prof.experience["baker"]!=1 or absf(player.stamina-(stamina_before-18.0))>.01:
		fail("Physical baking did not spend correct stamina or gain profession skill")
		return
	if prof.craft("bakery",player).get("ok",true):
		fail("Oven created free bread with no ingredients")
		return
	prepare(player,["grain","wood"])
	if not prof.craft("bakery",player).get("ok",false) or prof.experience["baker"]!=2:
		fail("Second loaf did not unlock the baker's advanced path")
		return
	prepare(player,["bread","herb","wood"])
	if not prof.craft("bakery",player).get("ok",false) or not player.inventory.has("herb_bread"):
		fail("Skilled herbal baking recipe not craftable")
		return
	var old_health: float=player.health
	player.health=60.0
	var old_stamina: float=player.stamina
	player.use_item()
	if player.inventory.has("herb_bread") or player.health<=60.0 or player.stamina<=old_stamina:
		fail("Finished herbal bread is not genuinely consumable")
		return
	player.stamina=100.0
	prepare(player,["grain"])
	var mana_before: float=world.scholar.mana
	var lighting=player.cast_latin("ignis",{"entity":oven,"position":oven.global_position})
	if not lighting.get("ok",false) or prof.charged_hearths["baker"]!=1 or world.scholar.mana>=mana_before:
		fail("Latin fire did not power the real baking furnace at a mana cost")
		return
	var mana_left: float=world.scholar.mana
	if player.cast_latin("ignis",{"entity":oven,"position":oven.global_position}).get("ok",true) or world.scholar.mana!=mana_left:
		fail("Repeated fire invocation fabricated extra work charge or took mana")
		return
	var magic_work=prof.craft("bakery",player)
	if not magic_work.get("ok",false) or player.inventory.has("grain") or not player.inventory.has("bread") or prof.charged_hearths["baker"]!=0:
		fail("Magic-assisted baking failed to use prepared heat exactly once")
		return
	# A real resource node, positioned away from the player, cannot be mined
	# remotely. The finite six-piece seam then remains depleted on reload.
	if world.harvest_resource(iron_vein).get("ok",true):
		fail("Player could mine ore without physically reaching its source")
		return
	player.global_position=iron_vein.global_position+Vector3(0,.2,-1.5)
	prepare(player,[])
	for i in range(6):
		if not world.harvest_resource(iron_vein).get("ok",false):
			fail("Finite iron seam failed to yield ore "+str(i))
			return
		# The hands are limited to six. A banked craft later consumes ore;
		# empty manually here to specifically exhaust the source quota.
		if i<5: player.inventory.clear()
	var ore_key: String="sim:%d" % int(iron_vein.uid)
	if int(world.harvest_counts.get(ore_key,0))!=6 or world.harvest_resource(iron_vein).get("ok",true):
		fail("Spent iron outcrop regenerated unlimited ore")
		return
	player.global_position=Vector3(21.8,world.height_at(21.8,16.8)+.2,16.8)
	player.stamina=100.0
	prepare(player,["ore","wood"])
	if not prof.craft("forge",player).get("ok",false) or not player.inventory.has("tools"):
		fail("Real ore and timber cannot become a physical forge tool")
		return
	player.stamina=100.0
	prepare(player,["ore","wood"])
	if not prof.craft("forge",player).get("ok",false) or prof.experience["blacksmith"]!=2:
		fail("Repeated smithing failed to unlock the lantern")
		return
	player.stamina=100.0
	prepare(player,["tools","ore","wood"])
	if not prof.craft("forge",player).get("ok",false) or not player.inventory.has("lantern"):
		fail("Mastered tool+ore lantern crafting is nonfunctional")
		return
	prepare(player,["ore"])
	var forged_fire=player.cast_latin("ignis",{"entity":forge,"position":forge.global_position})
	if not forged_fire.get("ok",false):
		fail("Latinate forge fuel refused valid smithing workstation")
		return
	var spent_magic=prof.craft("forge",player)
	if not spent_magic.get("ok",false) or not player.inventory.has("tools") or prof.charged_hearths["blacksmith"]!=0:
		fail("Magic heat couldn't forge without a wood ingredient")
		return
	# Artisan product sales transfer real money and actual village stocks.
	prepare(player,["bread"])
	var economy=world.village_sim.economy
	var funds_before: int=economy.treasury
	var loaves_before: int=int(economy.stocks["bread"])
	var options: Array=world.social.view("ida",world.scholar,player.inventory)["options"]
	if options.size()!=5:
		fail("Ida has no dynamic artisan purchase dialogue")
		return
	var paid=world.social.choose("ida",4,world.scholar,player)
	if not paid.get("ok",false) or player.coins!=2 or economy.treasury!=funds_before-2 or int(economy.stocks["bread"])!=loaves_before+1:
		fail("Baker sale didn't transfer finite public coins and a real loaf")
		return
	if world.social.choose("ida",4,world.scholar,player).get("ok",true):
		fail("The baker purchased the same physical loaf twice")
		return
	prepare(player,["tools"])
	funds_before=economy.treasury
	var tools_before: int=int(economy.stocks["tools"])
	if not world.social.choose("orin",3,world.scholar,player).get("ok",false) or player.coins!=6 or economy.treasury!=funds_before-4 or int(economy.stocks["tools"])!=tools_before+1:
		fail("Smith sale was not a finite ledger transaction")
		return
	var saved: Dictionary=PERSIST.snapshot(world)
	var restored=load("res://main.tscn").instantiate()
	root.add_child(restored)
	await process_frame
	if not PERSIST.apply_snapshot(restored,JSON.parse_string(JSON.stringify(saved))):
		fail("Profession progression and crafted goods corrupted world save")
		return
	if restored.player.coins!=6 or restored.player.professions.experience!=prof.experience or int(restored.harvest_counts.get(ore_key,0))!=6:
		fail("Crafting, mining and currency history did not persist")
		return
	var legacy: Dictionary=PERSIST.snapshot(restored)
	legacy["player"].erase("professions")
	legacy["player"].erase("coins")
	if not PERSIST.apply_snapshot(restored,legacy) or restored.player.coins!=0 or int(restored.player.professions.experience["baker"])!=0:
		fail("Older saved worlds cannot migrate to the new trade system")
		return
	var bogus: Dictionary=prof.snapshot()
	bogus["charged_hearths"]["baker"]=2
	if CAREERS.new().restore(bogus):
		fail("Invalid, duplicated magical furnace charges were accepted")
		return
	print("PASS: mined finite ore, physical baking and forging, Latin-powered workshops, skills and crafted items, real NPC sales, saved professions and old-save migration")
	quit(0)
