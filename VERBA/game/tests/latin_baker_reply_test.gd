extends SceneTree
## Contextual conversation: Ida asks a visible question, and the wizard
## answers with the correct Latin person and object case to trade actual grain.
const PERSIST = preload("res://scripts/world_persistence.gd")

func _initialize() -> void:
	call_deferred("_run")

func _fail(reason: String) -> void:
	push_error("Contextual baker Latin: " + reason)
	quit(1)

func _run() -> void:
	var world = load("res://main.tscn").instantiate()
	root.add_child(world)
	await process_frame
	var scholar = world.scholar
	var social = world.social
	var player = world.player
	if String(social.view("ida",scholar,player.inventory).get("spoken","")).contains("Quid fers?"):
		_fail("Advanced dialogue appeared before any book comprehension")
		return
	if bool(social.speak("ida","Frumentum fero.",scholar,player).get("ok",false)):
		_fail("Guessing a phrase before learning unlocked real bread")
		return
	if not scholar.collect_book("de_herbis") or not bool(scholar.answer("de_herbis",0).get("first_time",false)):
		_fail("The actual introductory manuscript could not be understood")
		return
	var learned_xp: int = scholar.xp
	if String(social.view("ida",scholar,player.inventory).get("spoken","")).contains("Quid fers?"):
		_fail("Ida asks about nonexistent grain")
		return
	player.inventory.append("grain")
	player.refresh_held_model()
	var model: String = String(social.view("ida",scholar,player.inventory).get("spoken",""))
	if not model.contains("'Quid fers?'"):
		_fail("Ida failed to ask a contextual Latin question about actual carried grain")
		return
	var bread_before: int = int(world.village_sim.economy.stocks.get("bread",0))
	if bread_before < 1:
		_fail("The village economy has no finite loaf to exchange")
		return
	for phrase in ["Frumento fero", "Frumentum fers", "Frumentum ferunt", "Frumentum fero nunc"]:
		if bool(social.speak("ida",phrase,scholar,player).get("ok",false)):
			_fail("Bad person, case or extra words accepted: " + phrase)
			return
	if not player.inventory.has("grain") or player.inventory.has("bread") or int(world.village_sim.economy.stocks["bread"])!=bread_before:
		_fail("Rejected answers manipulated the physical trade ledger")
		return
	if social.memory("ida").get("spoken_topics",[]).has("baker_delivery"):
		_fail("A rejected answer was remembered as actual productive Latin")
		return
	# Latin case carries meaning without a single rigid word order.
	var earned: Dictionary = social.speak("ida","Fero frumentum",scholar,player)
	if not bool(earned.get("ok",false)) or not bool(earned.get("latin_understood",false)):
		_fail("Grammatical first-person Latin was not understood")
		return
	if player.inventory.has("grain") or not player.inventory.has("bread"):
		_fail("Ida did not take real grain and give real bread")
		return
	if int(world.village_sim.economy.stocks["bread"]) != bread_before-1:
		_fail("Real Latin reply created bread without reducing village stock")
		return
	if not social.memory("ida").get("spoken_topics",[]).has("baker_delivery"):
		_fail("Correct meaningful Latin did not persist in the social ledger")
		return
	if String(social.view("ida",scholar,player.inventory).get("spoken","")).contains("Quid fers?"):
		_fail("Ida kept teaching the same prompt after demonstrated spoken use")
		return
	if bool(social.speak("ida","Frumentum fero",scholar,player).get("ok",false)):
		_fail("Speaking without any grain generated a free duplicate loaf")
		return
	if scholar.xp != learned_xp:
		_fail("Meaningful trade falsely granted academic progress XP")
		return
	var saved: Dictionary = PERSIST.snapshot(world)
	var fresh = load("res://main.tscn").instantiate()
	root.add_child(fresh)
	await process_frame
	if not PERSIST.apply_snapshot(fresh,JSON.parse_string(JSON.stringify(saved))):
		_fail("The full world could not reload Ida's trade")
		return
	if not fresh.player.inventory.has("bread") or fresh.player.inventory.has("grain"):
		_fail("Bread and consumed grain do not survive an actual fresh world")
		return
	if not fresh.social.memory("ida").get("spoken_topics",[]).has("baker_delivery"):
		_fail("Produced Latin response was not durable across a fresh world")
		return
	if String(fresh.social.view("ida",fresh.scholar,fresh.player.inventory).get("spoken","")).contains("Quid fers?"):
		_fail("Contextual language model failed to fade after reload")
		return
	print("PASS: Ida asks contextual Quid fers, player replies in attested Latin, finite bread exchange and social memory survive fresh-world restore")
	quit(0)
