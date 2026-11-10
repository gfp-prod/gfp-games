extends SceneTree
## Prevent loot duplication/loss, wildlife identity confusion and broken saves.
const PERSIST = preload("res://scripts/world_persistence.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var world: Node3D = load("res://main.tscn").instantiate()
	root.add_child(world)
	await process_frame
	var stone = null
	var leaf = null
	for item in world.items:
		if item.item_type == "stone" and stone == null: stone = item
		if item.item_type == "leaf" and leaf == null: leaf = item
	if stone == null or leaf == null:
		_fail("Missing source loot for persistence regression")
		return
	var source_key: String = String(stone.persistent_id)
	var leaf_key: String = String(leaf.persistent_id)
	world.collect(stone)
	world.collect(leaf)
	if not world.player.inventory.has("stone") or not world.player.book.has_word("ventus"):
		# The first authored leaf is the wind/ventus word.
		_fail("Physical loot pickup or spell fragment not stored")
		return
	if not world.collected_pickup_ids.has(source_key) or not world.collected_pickup_ids.has(leaf_key):
		_fail("Collected authored pickup not tombstoned")
		return
	world.player.drop_item()
	var dropped_key: String = ""
	for item in world.items:
		if item.is_dropped:
			dropped_key = String(item.persistent_id)
	if not dropped_key.begins_with("drop:"):
		_fail("Dropping stone did not create uniquely persistent loot")
		return
	world.player.add_item("lantern")
	world.player.book.total_casts = 13
	if world.creatures.size() < 2:
		_fail("Need multiple creatures to test ordering")
		return
	var animal = world.creatures[0]
	var wildlife_key: String = String(animal.persistent_id)
	animal.hunger = 0.93
	var spell_created = world.spawn_growth_patch(Vector3(9.0,0.0,9.0))
	if spell_created == null or not spell_created.is_generated:
		_fail("New spell-grown patch cannot be created")
		return
	var grown_key: int = int(spell_created.uid)
	spell_created.growth = 1.42
	var snapshot: Dictionary = PERSIST.snapshot(world)
	if snapshot["dropped_pickups"].size() != 1:
		_fail("Player drop missing from snapshot")
		return
	world.player.inventory.clear()
	world.player.refresh_held_model()
	if not PERSIST.apply_snapshot(world,snapshot):
		_fail("Same-world restore failed")
		return
	if world.player.inventory != ["lantern"]:
		_fail("Lost inventory after restoring already-running world")
		return
	if world.player.book.total_casts != 13 or not world.player.book.has_word("ventus"):
		_fail("Grimoire literacy or history lost")
		return
	var old_stone_count: int = _count_item(world,source_key)
	if old_stone_count != 0 or _count_item(world,dropped_key) != 1:
		_fail("Previously taken original respawned or dropped item disappeared")
		return
	# Repeat restore: duplicated objects must never accumulate.
	if not PERSIST.apply_snapshot(world,snapshot):
		_fail("Second restore failed")
		return
	if _count_item(world,dropped_key) != 1:
		_fail("Repeated save restore created duplicate dropped loot")
		return

	var fresh: Node3D = load("res://main.tscn").instantiate()
	root.add_child(fresh)
	await process_frame
	# Make order different to prove animal keys, not array indices, are used.
	fresh.creatures.reverse()
	if not PERSIST.apply_snapshot(fresh,snapshot):
		_fail("Fresh-world snapshot restore failed")
		return
	if fresh.player.inventory != ["lantern"] or _count_item(fresh,source_key) != 0:
		_fail("Fresh world lost inventory or restored already-taken authored loot")
		return
	if _count_item(fresh,dropped_key) != 1 or _count_item(fresh,leaf_key) != 0:
		_fail("Fresh world lost player drop or respawned manuscript fragment")
		return
	var matched: bool = false
	for creature in fresh.creatures:
		if creature.persistent_id == wildlife_key:
			matched = absf(float(creature.hunger)-.93) < .01
	if not matched:
		_fail("Wildlife identity was corrupted by list reordering")
		return
	var grown_count: int = 0
	for obj in fresh.sim_objects:
		if obj.is_generated and int(obj.uid) == grown_key:
			grown_count += 1
			if absf(float(obj.growth)-1.42)>.01:
				_fail("Generated plant was restored with the wrong growth state")
				return
	if grown_count != 1:
		_fail("A spell-created living plant was lost or duplicated after loading")
		return
	if not PERSIST.apply_snapshot(fresh,snapshot):
		_fail("Repeated ecosystem load failed")
		return
	var grown_twice: int = 0
	for obj in fresh.sim_objects:
		if obj.is_generated and int(obj.uid) == grown_key: grown_twice += 1
	if grown_twice != 1:
		_fail("Spell-created vegetation duplicated on repeated load")
		return

	var save_file: String = "user://verba_save_integrity_ci.json"
	if not PERSIST.save_world(world,save_file):
		_fail("First transactional save failed")
		return
	# Second save rotates previous complete version to .bak.
	world.player.inventory.clear()
	world.player.refresh_held_model()
	if not PERSIST.save_world(world,save_file):
		_fail("Second transactional save/backup failed")
		return
	if not FileAccess.file_exists(save_file+".bak"):
		_fail("Prior valid save not backed up")
		return
	var broken := FileAccess.open(save_file,FileAccess.WRITE)
	broken.store_string("partially written / corrupted")
	broken.close()
	if not PERSIST.load_world(fresh,save_file):
		_fail("Backup recovery after corrupted primary failed")
		return
	if fresh.player.inventory != ["lantern"]:
		_fail("Backup recovered wrong inventory or failed to load")
		return
	for file in [save_file,save_file+".bak",save_file+".tmp"]:
		var absolute: String = ProjectSettings.globalize_path(file)
		if FileAccess.file_exists(file):
			DirAccess.remove_absolute(absolute)
	print("PASS: collected loot, persistent drops, same-world reload idempotence, grimoire, stable wildlife, transactional backup recovery")
	quit(0)

func _count_item(world: Node3D, identity: String) -> int:
	var count: int = 0
	for item in world.items:
		if is_instance_valid(item) and item.persistent_id == identity:
			count += 1
	return count

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
