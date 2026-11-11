extends SceneTree
const SIM=preload("res://scripts/village_sim.gd")
const SOCIAL=preload("res://scripts/dialogue_social.gd")
func _initialize() -> void: call_deferred("_run")
func fail(message: String) -> void:
	push_error("Player market chain: "+message)
	quit(1)
func _run() -> void:
	print("MARKET CHECK: begin")
	var sim=SIM.new(2026)
	var social=SOCIAL.new()
	social.village_sim=sim
	var inventory: Array[String]=["herb"]
	var mock_player=RefCounted.new()
	# Actual game player is required for refreshing held item; test uses a
	# tiny node with the same inventory and UI-facing surface.
	var player=load("res://tests/market_player_stub.gd").new()
	player.inventory=inventory
	var before_grain: int=sim.economy.stocks["grain"]
	var before_herb: int=sim.economy.stocks["herb"]
	print("MARKET CHECK: trade farmer")
	var first: Dictionary=social.choose("daro",3,null,player)
	if not first.get("ok",false) or not player.inventory.has("grain") or player.inventory.has("herb"):
		fail("Daro did not exchange physical herb for grain")
		return
	if sim.economy.stocks["grain"]!=before_grain-1 or sim.economy.stocks["herb"]!=before_herb+1:
		fail("Daro's market exchange fabricated resources")
		return
	var bread_before: int=sim.economy.stocks["bread"]
	print("MARKET CHECK: trade baker")
	var second: Dictionary=social.choose("ida",3,null,player)
	if not second.get("ok",false) or not player.inventory.has("bread") or player.inventory.has("grain"):
		fail("Ida did not exchange grain for bread")
		return
	if sim.economy.stocks["grain"]!=before_grain or sim.economy.stocks["bread"]!=bread_before-1:
		fail("Ida's bakery exchange did not reconcile inventory")
		return
	var duplicate: Dictionary=social.choose("ida",3,null,player)
	if duplicate.get("ok",false):
		fail("Repeat trade duplicated a loaf")
		return
	sim.economy.stocks["grain"]=0
	if not social.view("ida",null,player.inventory)["spoken"].contains("nearly empty"):
		fail("Baker failed to recognize real grain shortage")
		return
	player.inventory=["herb"]
	if social.choose("daro",3,null,player).get("ok",false):
		fail("Farmer gave out grain from empty stores")
		return
	var saved: Dictionary=sim.snapshot()
	var reloaded=SIM.new(7)
	if not reloaded.restore(JSON.parse_string(JSON.stringify(saved))):
		fail("Market state could not be restored")
		return
	if reloaded.economy.stocks["grain"]!=0 or reloaded.economy.stocks["bread"]!=sim.economy.stocks["bread"]:
		fail("Save/load refilled the depleted market")
		return
	print("PASS: player herb->grain->bread trade, real storehouse accounting, dynamic baker dialogue, no duplicate trades, shortage gating, persistent market")
	quit(0)
