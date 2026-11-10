extends SceneTree
const PERSIST = preload("res://scripts/world_persistence.gd")

func _initialize() -> void:
	call_deferred("_test")

func _test() -> void:
	var world: Node3D = load("res://main.tscn").instantiate()
	root.add_child(world)
	await process_frame
	await physics_frame
	if world.scholar == null or world.player.book == null:
		_fail("Missing scholar or physical grimoire")
		return
	var book_pickup: Node3D = null
	var count: int = 0
	for pickup in world.items:
		if pickup.item_type == "book":
			count += 1
			if pickup.word == "de_herbis": book_pickup = pickup
	if count != 3 or book_pickup == null:
		_fail("Three physical Latin book objects were not placed in the world")
		return
	if book_pickup.find_child("FoundLatinVolume",true,false) == null:
		_fail("Book pickup has no real 3D cover model")
		return
	world.player.position = book_pickup.position + Vector3(0.0,0.0,1.4)
	await physics_frame
	world.player.interact()
	if not world.scholar.has_book("de_herbis"):
		_fail("First-person interaction didn't collect the actual book")
		return
	if not world.player.book.open or not world.player.book.page_labels[0].text.contains("Herba in horto crescit"):
		_fail("Physical grimoire didn't display the Latin text after collecting")
		return
	if not world.player.book.begin_study():
		_fail("Player could not study the discovered book")
		return
	var wrong: Dictionary = world.player.book.submit_answer(2)
	if bool(wrong.get("ok",false)) or world.scholar.level != 1:
		_fail("Wrong Latin answer gave an undeserved level")
		return
	var right: Dictionary = world.player.book.submit_answer(0)
	if not bool(right.get("first_time",false)) or world.scholar.level < 2:
		_fail("Correct comprehension didn't reward scholarship")
		return
	if world.scholar.max_mana <= 26.0 or not world.player.book.has_word("crescite"):
		_fail("Reading failed to expand mana or teach a real Latin form")
		return
	var tree: Node3D = null
	for candidate in world.sim_objects:
		if is_instance_valid(candidate) and candidate.kind == "tree":
			tree = candidate
			break
	if tree == null:
		_fail("No tree to cast learned growth magic upon")
		return
	var before: float = float(tree.growth)
	var old_mana: float = float(world.scholar.mana)
	var response: Dictionary = world.player.cast_latin("crescite arbores",
		{"position":tree.global_position,"entity":tree})
	if not bool(response.get("ok",false)) or tree.growth <= before:
		_fail("A learned Latin formula didn't physically alter the tree")
		return
	if absf(world.scholar.mana-(old_mana-7.0)) > .01:
		_fail("Spell did not deduct exactly one learned-form mana cost")
		return
	var snapshot: Dictionary = PERSIST.snapshot(world)
	var fresh: Node3D = load("res://main.tscn").instantiate()
	root.add_child(fresh)
	await process_frame
	if not PERSIST.apply_snapshot(fresh,snapshot):
		_fail("Could not restore book knowledge in a new world")
		return
	if not fresh.scholar.completed.has("de_herbis") or fresh.scholar.level != world.scholar.level:
		_fail("Reading progress disappeared between sessions")
		return
	for pickup in fresh.items:
		if pickup.item_type == "book" and pickup.word == "de_herbis":
			_fail("A collected manuscript incorrectly respawned on load")
			return
	print("PASS: discover 3D Latin book, E pickup, physical page reading, quiz, one-time XP, mana increase, learned growth cast, and fresh-world restore")
	quit(0)

func _fail(reason: String) -> void:
	push_error(reason)
	quit(1)
