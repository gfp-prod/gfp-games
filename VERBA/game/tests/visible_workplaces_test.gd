extends SceneTree
## Real world, real village ledger: visual cargo must never invent resources.
func _initialize() -> void: call_deferred("_run")
func fail(message: String) -> void:
	push_error("Workplace economy: "+message)
	quit(1)
func shown(nodes: Array) -> int:
	var result: int=0
	for obj in nodes:
		if obj.visible: result+=1
	return result
func _run() -> void:
	var world=load("res://main.tscn").instantiate()
	root.add_child(world)
	await process_frame
	var district=world.get_node_or_null("VillageWorkingDistrict")
	if district==null or world.workplaces!=district:
		fail("Economic district is not mounted in the playable world")
		return
	for label in ["DaroWorkingFarm","DaroGrainCart","IdaStoneBakery",
		"IdaBreadCounter","OrinBlacksmithForge","OrinAnvilAndToolRack",
		"VillagePublicMarket"]:
		if district.find_child(label,true,false)==null:
			fail("Missing workplace in level: "+label)
			return
	for collision_name in ["PhysicalHarvestCart","PhysicalBakeOven",
			"PhysicalBreadCounter","PhysicalCoalForge","PhysicalAnvil"]:
		var shape=district.find_child(collision_name,true,false)
		if shape==null or not (shape is StaticBody3D) or shape.collision_layer!=16:
			fail("Workplace has no real physical obstacle: "+collision_name)
			return
	# Clothing identity belongs to individual NPCs; a complete workplace
	# without recognizable workers is still just a prop display.
	for pair in [["ida","VisibleBakerApron"],["orin","VisibleSmithHammer"],
			["daro","VisibleFarmerHat"],["sela","VisibleMerchantPouch"]]:
		var actor=null
		for npc in world.npcs:
			if npc.npc_id==pair[0]:
				actor=npc
				break
		if actor==null or actor.find_child(pair[1],true,false)==null:
			fail("Worker lacks recognizable physical role silhouette: "+str(pair[0]))
			return
	var economy=world.village_sim.economy
	var slots: Dictionary=district.displays
	for kind in ["grain","bread","tools"]:
		if not slots.has(kind) or slots[kind].size()<4:
			fail("No physical stocked display for "+kind)
			return
	var original: Dictionary=world.village_sim.snapshot()
	for kind in ["grain","bread","tools","ore","wood"]: economy.stocks[kind]=0
	district.refresh_from_economy(true)
	for kind in ["grain","bread","tools"]:
		if shown(slots[kind])!=0:
			fail("Display invents "+kind+" when public stocks are empty")
			return
	if district.production_lamps["baker"].visible:
		fail("Baker oven burns without grain input")
		return
	if district.production_lamps["blacksmith"].visible:
		fail("Forge burns without input")
		return
	economy.stocks["grain"]=9
	economy.stocks["bread"]=0
	economy.stocks["ore"]=2
	economy.stocks["wood"]=2
	economy.stocks["tools"]=0
	district.refresh_from_economy(true)
	if shown(slots["grain"])!=3 or shown(slots["bread"])!=0:
		fail("Cargo display does not match stock change")
		return
	if not district.production_lamps["baker"].visible or not district.production_lamps["blacksmith"].visible:
		fail("Working industries do not show active fires")
		return
	var baker: Dictionary=world.village_sim.people["ida"]
	if not economy.work("ida","baker",baker):
		fail("Real bakery refused grain despite enough input")
		return
	district.refresh_from_economy(true)
	if int(economy.stocks["grain"])!=7 or int(economy.stocks["bread"])!=2:
		fail("Baking violates material resource accounting")
		return
	if shown(slots["bread"])!=1:
		fail("Bakery did not display its first real finished loaf")
		return
	var smith: Dictionary=world.village_sim.people["orin"]
	if not economy.work("orin","blacksmith",smith):
		fail("Working forge refused available ore and wood")
		return
	district.refresh_from_economy(true)
	if int(economy.stocks["tools"])!=1 or shown(slots["tools"])!=1:
		fail("Tool rack does not reflect real forged outputs")
		return
	var before_count: int=district.get_child_count()
	for i in range(100):
		economy.stocks["grain"]=i%30
		economy.stocks["bread"]=(i*3)%32
		economy.stocks["tools"]=i%17
		district.refresh_from_economy(true)
	if district.get_child_count()!=before_count:
		fail("Repeated trading generated unbounded scene objects")
		return
	if not world.village_sim.restore(original):
		fail("Cannot restore village economy after state mutations")
		return
	district.refresh_from_economy(true)
	if shown(slots["bread"])!=mini(6,ceili(float(world.village_sim.economy.stocks["bread"])/3.0)):
		fail("A save restore did not restore visual stock")
		return
	print("PASS: farm bakery forge market visible; finite stock controls props; production changes real cargo; no item duplication or unbounded scene nodes")
	quit(0)
