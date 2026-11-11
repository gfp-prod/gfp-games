extends SceneTree
## Integrated production Latin: graded listening, genuine case morphology,
## real player text-entry, inventory exchange, persistent social consequences.
const PERSIST = preload("res://scripts/world_persistence.gd")
const LATIN = preload("res://scripts/latin_conversation.gd")

func _initialize() -> void:
	call_deferred("_run")

func _fail(message: String) -> void:
	push_error("Typed Latin conversation: " + message)
	quit(1)

func _key(player, code: int, unicode_value: int = 0) -> void:
	var event := InputEventKey.new()
	event.pressed = true
	event.keycode = code
	event.unicode = unicode_value
	player._input(event)

func _say(player, words: String) -> void:
	_key(player, KEY_ENTER)
	for index in range(words.length()):
		_key(player, KEY_NONE, words.unicode_at(index))
	_key(player, KEY_ENTER)

func _run() -> void:
	var world = load("res://main.tscn").instantiate()
	root.add_child(world)
	await process_frame
	var player = world.player
	var scholar = world.scholar
	var social = world.social
	# A learner cannot obtain high-tier knowledge by guessing a modeled
	# phrase before understanding its source manuscript.
	if bool(social.speak("mara", "Ubi est silva?", scholar, player).get("ok",false)):
		_fail("An unstudied request bypassed the graded conversation")
		return
	if not social.memories.is_empty():
		_fail("An unstudied or rejected phrase awarded relationship progress")
		return
	if not scholar.collect_book("de_herbis") or not bool(scholar.answer("de_herbis",0).get("first_time",false)):
		_fail("The introductory reading milestone is unavailable")
		return
	var prior_xp: int = scholar.xp
	# The trade menu is no longer a way to bypass practiced production.
	player.inventory.append("herb")
	player.refresh_held_model()
	var prevented: Dictionary = social.choose("tomas",1,scholar,player)
	if bool(prevented.get("ok",false)) or scholar.has_book("de_igne_et_aqua"):
		_fail("The learned route still bypasses productive Latin")
		return
	for phrase in ["Da mihi liber", "Da me librum", "Da mihi librum nunc"]:
		if bool(social.speak("tomas",phrase,scholar,player).get("ok",false)):
			_fail("Invalid morphology or unauthored extra words were accepted: " + phrase)
			return
	if not player.inventory.has("herb") or not social.memories.is_empty():
		_fail("Failed Latin altered inventory or social memory")
		return
	# Latin's flexible word order is honored but its case endings matter.
	var traded: Dictionary = social.speak("tomas","Librum mihi da",scholar,player)
	if not bool(traded.get("ok",false)) or not bool(traded.get("latin_understood",false)):
		_fail("An attested, grammatical request was not understood")
		return
	if not scholar.has_book("de_igne_et_aqua") or player.inventory.has("herb") or not bool(social.memory("tomas")["traded"]):
		_fail("Spoken trade failed to affect the same physical book and item ledger")
		return
	if bool(social.speak("tomas","Da mihi librum",scholar,player).get("ok",false)):
		_fail("The same Latin request duplicated a unique book")
		return
	# The grain for Ida must be earned, not conjured by this test: help
	# Daro with a real learned field spell, then receive a finite wage.
	var commission: Dictionary = social.choose("daro",4,scholar,player)
	if not bool(commission.get("ok",false)):
		_fail("Daro did not offer an actual harvest commission")
		return
	var field: Vector3 = Vector3(18.0,world.height_at(18.0,27.0),27.0)
	player.position=Vector3(18.0,world.height_at(18.0,25.0)+.25,25.0)
	await physics_frame
	var field_before: int = int(world.village_sim.field_fertility)
	var improved: Dictionary = player.cast_latin("crescite, herbae",{"position":field})
	if not bool(improved.get("ok",false)) or int(world.village_sim.field_fertility)<=field_before:
		_fail("Learned Latin did not enrich Daro's actual field")
		return
	var earned: Dictionary = social.choose("daro",4,scholar,player)
	if not bool(earned.get("ok",false)) or not player.inventory.has("grain"):
		_fail("A real wizard commission failed to pay an actual sack of grain")
		return
	# Speaking to Ida then participates in the existing finite economy.
	var bread_before: int = int(world.village_sim.economy.stocks.get("bread",0))
	if bread_before < 1:
		_fail("The test village has no starting loaf for the baker to exchange")
		return
	if bool(social.choose("ida",3,scholar,player).get("ok",false)):
		_fail("The baker's learned market route still bypasses Latin")
		return
	var baker: Dictionary = social.speak("ida","Tibi frumentum fero",scholar,player)
	if not bool(baker.get("ok",false)) or not player.inventory.has("bread") or player.inventory.has("grain"):
		_fail("Producing genuine Latin did not deliver grain for real bread")
		return
	if int(world.village_sim.economy.stocks.get("bread",0)) != bread_before-1:
		_fail("Typed trade fabricated bread without consuming bakery stock")
		return
	# Entry is performed through the actual first-person NPC UI, not just
	# the parser directly. Its keys must not trigger world spellcasting.
	var mara: Node3D
	for actor in world.npcs:
		if actor.npc_id=="mara":
			mara=actor
			break
	if mara==null:
		_fail("Mara is missing as a physical world resident")
		return
	player.position = Vector3(mara.position.x,
		world.height_at(mara.position.x,mara.position.z+2.0)+.22,
		mara.position.z+2.0)
	await physics_frame
	player.camera.look_at(mara.global_position+Vector3.UP*1.25,Vector3.UP)
	await physics_frame
	if not player.begin_conversation(mara):
		_fail("The physical NPC cannot receive typed Latin at conversational range")
		return
	for i in range(18): await process_frame
	if mara.name_label == null or mara.name_label.visible:
		_fail("The floating NPC billboard still occludes a live conversation")
		return
	var toward: Vector3=player.global_position-mara.global_position
	toward.y=0.0
	if (-mara.global_transform.basis.z).dot(toward.normalized()) < .7:
		_fail("Mara does not turn toward the person actually speaking")
		return
	_say(player, "Ubi est silva?")
	if not social.memory("mara")["topics"].has("forest") or player.conversation_listening or player.typing:
		_fail("Player dialogue keys did not produce the understood forest request")
		return
	if not String(player.conversation_body.text).contains("Silva est trans rivum"):
		_fail("Mara did not answer in progressively comprehensible Latin")
		return
	if scholar.xp != prior_xp:
		_fail("Correctly typing model dialogue manufactured scholarship XP")
		return
	player.end_conversation()
	# Integrate the two accepted systems: a genuine field spell belongs
	# in the physical journal, while immortal defeat advances living time.
	var found_field_trial: bool = false
	for trial in scholar.experiments.entries:
		if String(trial.get("latin",""))=="crescite herbae" and bool(trial.get("worked",false)):
			found_field_trial = true
			break
	if not found_field_trial:
		_fail("The real spoken field magic vanished from Liber Experimentorum")
		return
	var day_before: int = world.world_calendar.day
	player.damage_immunity = 0.0
	player.health = 8.0
	if not player.take_damage(25.0,"wolf") or world.world_calendar.day != day_before+1:
		_fail("Immortal recovery did not advance the authoritative world calendar")
		return
	# Every outcome must survive the existing unified world snapshot.
	var saved: Dictionary = PERSIST.snapshot(world)
	var previous_bread: int = int(world.village_sim.economy.stocks["bread"])
	social.memories.clear()
	if not PERSIST.apply_snapshot(world,JSON.parse_string(JSON.stringify(saved))):
		_fail("Cannot restore the actual world after spoken Latin transactions")
		return
	if not bool(social.memory("tomas")["traded"]) or not social.memory("mara")["topics"].has("forest"):
		_fail("Typed social memory vanished from the authoritative save")
		return
	if not scholar.has_book("de_igne_et_aqua") or int(world.village_sim.economy.stocks["bread"])!=previous_bread:
		_fail("The material results of Latin interaction failed save/reload")
		return
	if world.world_calendar.day!=day_before+1 or scholar.experiments.entries.is_empty():
		_fail("The journal or consequential immortal passage of time failed save/reload")
		return
	print("PASS: produced Latin cases and flexible word order drive real NPC speech, book trade, bread stocks, physical entry and persistent memories")
	quit(0)
