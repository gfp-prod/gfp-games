extends SceneTree
## VERBA social vertical slice: physical NPCs, graded Latin, one-time
## relationship, barter, no duplicate volumes, and save/reload integrity.
const PERSIST = preload("res://scripts/world_persistence.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var world = load("res://main.tscn").instantiate()
	root.add_child(world)
	await process_frame
	var scholar = world.scholar
	var player = world.player
	if world.npcs.size() < 2 or world.social.definitions.size() < 2:
		_fail("Two real inhabitants and their graded conversations are required")
		return
	var mara: Node3D
	var tomas: Node3D
	for actor in world.npcs:
		if actor.npc_id == "mara": mara = actor
		if actor.npc_id == "tomas": tomas = actor
	if mara == null or tomas == null:
		_fail("The roadside scribe or hermitage keeper is missing")
		return
	for actor in [mara,tomas]:
		var body := actor.find_child("LivingNPCConversationCollider",true,false) as StaticBody3D
		if body == null or not body.has_meta("npc_ref") or body.get_meta("npc_ref") != actor:
			_fail("World person has no real, targetable interaction collision")
			return

	var early: Dictionary = world.social.view("mara",scholar,player.inventory)
	if int(early.get("stage",-1)) != 0 or not String(early.get("spoken","")).contains("I'm Mara"):
		_fail("Early learner is not greeted with comprehensible Latin and English")
		return
	var blocked: Dictionary = world.social.choose("mara",2,scholar,player)
	if bool(blocked.get("ok",false)) or not world.social.memories.is_empty():
		_fail("Unstudied Latin dialogue must not award free relationship progress")
		return
	var first: Dictionary = world.social.choose("mara",0,scholar,player)
	if not bool(first.get("ok",false)) or int(world.social.memory("mara")["rapport"]) != 1:
		_fail("A first real conversation must create one remembered topic")
		return
	world.social.choose("mara",0,scholar,player)
	if int(world.social.memory("mara")["rapport"]) != 1:
		_fail("Repeating a conversation is a relationship farming exploit")
		return

	# A real trade consumes one inventory item and acquires ONE collectible
	# book from the existing manuscript library, removing its world double.
	player.inventory.append("herb")
	player.refresh_held_model()
	var trade: Dictionary = world.social.choose("tomas",1,scholar,player)
	if not bool(trade.get("ok",false)) or not scholar.has_book("de_igne_et_aqua"):
		_fail("Herb-for-book barter did not transfer a usable Latin volume")
		return
	if player.inventory.has("herb"):
		_fail("Book barter failed to spend the herb")
		return
	if not bool(world.social.memory("tomas")["traded"]):
		_fail("Book exchange is not recorded as a one-time agreement")
		return
	for book_item in world.items:
		if is_instance_valid(book_item) and book_item.item_type == "book" and book_item.word == "de_igne_et_aqua":
			_fail("A traded book still has an exploitable physical duplicate")
			return
	var second_trade: Dictionary = world.social.choose("tomas",1,scholar,player)
	if bool(second_trade.get("ok",false)) or scholar.owned.count("de_igne_et_aqua") != 1:
		_fail("NPC trading can produce duplicates")
		return

	var record: Dictionary = PERSIST.snapshot(world)
	if not (record.get("social",null) is Dictionary):
		_fail("Social memory is missing from the unified world save")
		return
	world.social.memories.clear()
	scholar.owned.clear()
	if not PERSIST.apply_snapshot(world,record):
		_fail("Could not restore NPC memories from a saved world")
		return
	if int(world.social.memory("mara")["rapport"]) != 1:
		_fail("Conversation relationship was lost after reload")
		return
	if not bool(world.social.memory("tomas")["traded"]) or not scholar.has_book("de_igne_et_aqua"):
		_fail("Book trade and its memory diverged on reload")
		return
	if bool(world.social.choose("tomas",1,scholar,player).get("ok",false)):
		_fail("The same trade can be replayed after a save reload")
		return

	# Language complexity advances only with proven book understanding.
	if not scholar.collect_book("de_herbis"):
		_fail("Could not gather beginner Latin botany volume")
		return
	if not bool(scholar.answer("de_herbis",0).get("first_time",false)):
		_fail("Book comprehension did not advance the scholar")
		return
	var progressed: Dictionary = world.social.view("mara",scholar,player.inventory)
	if int(progressed.get("stage",-1)) != 1:
		_fail("Dialogue failed to respond to learned Latin")
		return
	if not String(progressed.get("options",[])[1]["label"]).contains("Ubi est silva"):
		_fail("Intermediate Latin did not replace the beginner prompt")
		return
	if not bool(world.social.choose("mara",2,scholar,player).get("ok",false)):
		_fail("Studying De Herbis did not unlock a real Latin exchange")
		return

	# Physical interaction: distance and line of sight must both apply.
	player.position = Vector3(mara.position.x,
		world.height_at(mara.position.x,mara.position.z+2.0)+.22,
		mara.position.z+2.0)
	await physics_frame
	player.camera.look_at(mara.global_position+Vector3.UP*1.25,Vector3.UP)
	await physics_frame
	if not player.begin_conversation(mara):
		_fail("Player cannot interact with a visible NPC at conversational range")
		return
	if not player.conversation_panel.visible:
		_fail("Conversation state has no actual in-game response interface")
		return
	player.end_conversation()
	player.position = Vector3(0,world.height_at(0,26)+.22,26)
	await physics_frame
	if player.begin_conversation(tomas):
		_fail("Player can open a remote conversation from across the valley")
		return
	print("PASS: two world NPCs, Latin comprehension stages, one-time rapport, secure book trade, unified persistence and first-person interaction")
	quit(0)

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
