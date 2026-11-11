extends SceneTree
## First living-familiar slice: choose a wild crow or hare, give its actual
## offering, command it in Latin, and save its identity without cloning wildlife.
const PERSIST = preload("res://scripts/world_persistence.gd")

func _initialize() -> void:
	call_deferred("_check")

func _check() -> void:
	var world = load("res://main.tscn").instantiate()
	root.add_child(world)
	await process_frame
	var crow: Node3D
	var hare: Node3D
	var original_count: int = world.creatures.size()
	for c in world.creatures:
		if crow == null and c.species == "crow": crow = c
		if hare == null and c.species == "hare": hare = c
	if crow == null or hare == null or world.familiar_id != "":
		_fail("Initial world must contain untamed crow and hare choices")
		return
	var player = world.player
	player.position = Vector3(crow.position.x,
		world.height_at(crow.position.x,crow.position.z+1.5)+.22,
		crow.position.z+1.5)
	if bool(world.bond_animal(crow).get("ok",false)):
		_fail("A crow can be bonded without the shiny amber offering")
		return
	player.inventory.append("amber")
	player.refresh_held_model()
	var bond: Dictionary = world.bond_animal(crow)
	if not bool(bond.get("ok",false)) or world.familiar_id != crow.persistent_id:
		_fail("The crow didn't accept a real item as its bonding offering")
		return
	if player.inventory.has("amber") or world.creatures.size() != original_count:
		_fail("Bonding duplicated the amber or spawned a second crow")
		return
	if world.familiar() != crow or world.familiar_mode != "follow":
		_fail("Existing crow did not become the active following familiar")
		return
	player.position = crow.position + Vector3(0,.24,5.0)
	await physics_frame
	await physics_frame
	if crow.state != "follow":
		_fail("Familiar did not follow the player instead of wandering or fleeing")
		return
	world.cycle_familiar_order()
	await physics_frame
	if world.familiar_mode != "stay" or crow.state != "still":
		_fail("Stay order does not stop companion navigation")
		return
	world.cycle_familiar_order()
	await physics_frame
	if world.familiar_mode != "rest" or crow.state != "still":
		_fail("Rest order does not hold companion in place")
		return
	world.cycle_familiar_order()
	if world.familiar_mode != "follow":
		_fail("Player cannot resume familiar following")
		return

	var targeted := {"position":crow.global_position,"entity":crow}
	world.scholar.mana = world.scholar.max_mana
	var command: Dictionary = player.cast_latin("siste, corve!",targeted)
	if not bool(command.get("ok",false)) or world.familiar_mode != "stay":
		_fail("Correct Latin 'siste, corve' did not change persistent pet behavior")
		return
	world.scholar.mana = world.scholar.max_mana
	command = player.cast_latin("veni corve",targeted)
	if not bool(command.get("ok",false)) or world.familiar_mode != "follow":
		_fail("Latin 'veni corve' did not make the familiar follow")
		return
	world.scholar.mana = world.scholar.max_mana
	command = player.cast_latin("dormi corve",targeted)
	if not bool(command.get("ok",false)) or world.familiar_mode != "rest":
		_fail("Latin 'dormi corve' did not make the familiar rest")
		return

	var save: Dictionary = PERSIST.snapshot(world)
	if String(save.get("familiar",{}).get("id","")) != crow.persistent_id:
		_fail("Familiar bond was not serialized in the unified save")
		return
	world.familiar_id = ""
	world.familiar_mode = "follow"
	if not PERSIST.apply_snapshot(world,save):
		_fail("Could not load a saved familiar")
		return
	if world.familiar() != crow or world.familiar_mode != "rest":
		_fail("Saved companion identity or Latin command state was lost")
		return
	player.inventory.append("amber")
	player.refresh_held_model()
	if bool(world.bond_animal(hare).get("ok",false)):
		_fail("A second companion was bound while one already lives with the player")
		return
	player.inventory.erase("amber")
	player.refresh_held_model()

	# Backward compatibility: an older save has neither companion field
	# nor stale companion IDs. Both choices remain available to new players.
	var legacy: Dictionary = save.duplicate(true)
	legacy.erase("familiar")
	if not PERSIST.apply_snapshot(world,legacy) or world.familiar_id != "":
		_fail("Older saves must load without inventing a familiar")
		return
	player.position = Vector3(hare.position.x,
		world.height_at(hare.position.x,hare.position.z+1.3)+.24,
		hare.position.z+1.3)
	player.inventory.append("herb")
	player.refresh_held_model()
	if not bool(world.bond_animal(hare).get("ok",false)):
		_fail("Alternative hare familiar cannot be chosen with a herb")
		return
	if player.inventory.has("herb") or world.familiar() != hare:
		_fail("The alternative familiar failed to spend a herb or bind correctly")
		return
	if world.creatures.size() != original_count:
		_fail("Adoption changed wild creature count")
		return
	print("PASS: crow/hare choices, physical gifts, follow/stay/rest, attested Latin orders, identity and save compatibility")
	quit(0)

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
