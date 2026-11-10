extends RefCounted
## Persistent state belongs to the objects, not the currently visible render nodes.
## Save data deliberately avoids Resource and Node references so game updates can
## retain history without serializing engine-internal state.
const SAVE_FILE := "user://verba_living_world_v1.json"

static func _as_array(vector: Vector3) -> Array[float]:
	return [vector.x,vector.y,vector.z]

static func _as_vector(values: Variant, fallback: Vector3) -> Vector3:
	if not (values is Array) or values.size() != 3: return fallback
	return Vector3(float(values[0]),float(values[1]),float(values[2]))

static func snapshot(world: Node3D) -> Dictionary:
	var objects: Array[Dictionary] = []
	for obj in world.sim_objects:
		if not is_instance_valid(obj): continue
		objects.append({
			"id":int(obj.uid), "kind":String(obj.kind),
			"position":_as_array(obj.position),
			"water":float(obj.water), "heat":float(obj.heat),
			"fuel":float(obj.fuel), "health":float(obj.health),
			"growth":float(obj.growth), "food":float(obj.food),
			"brittleness":float(obj.brittleness),
			"burning":bool(obj.burning), "dead":bool(obj.dead)
		})
	var animals: Array[Dictionary] = []
	for animal in world.creatures:
		if not is_instance_valid(animal): continue
		animals.append({
			"id":String(animal.persistent_id),
			"species":String(animal.species),"position":_as_array(animal.position),
			"health":float(animal.health),"hunger":float(animal.hunger),
			"thirst":float(animal.thirst),"energy":float(animal.energy),
			"wetness":float(animal.wetness),"growth":float(animal.growth),
			"dead":bool(animal.dead),"asleep":float(animal.asleep),
			"panic":float(animal.panic)
		})
	var player: Dictionary = {}
	if world.player != null:
		player = {
			"position":_as_array(world.player.position),
			"yaw":float(world.player.rotation.y),
			"pitch":float(world.player.pitch.rotation.x),
			"inventory":world.player.inventory.duplicate(),
			"selected_slot":int(world.player.selected_slot),
			"learned":world.player.book.learned.duplicate(),
			"total_casts":int(world.player.book.total_casts)
		}
	var dropped: Array[Dictionary] = []
	for item in world.items:
		if not is_instance_valid(item) or not item.is_dropped: continue
		dropped.append({
			"id":String(item.persistent_id),"kind":String(item.item_type),
			"word":String(item.word),"position":_as_array(item.position)
		})
	var scholarship: Dictionary = world.scholar.snapshot() if world.scholar != null else {}
	return {"schema":1,"saved_unix":Time.get_unix_time_from_system(),
		"objects":objects,"animals":animals,"player":player,"scholar":scholarship,
		"collected_pickups":world.collected_pickup_ids.duplicate(),
		"dropped_pickups":dropped,"next_drop_serial":world.next_drop_serial,
		"weather":{"raining":bool(world.raining),
			"rain_remaining":float(world.rain_remaining),"wind":float(world.wind),
			"night_remaining":float(world.night_remaining),"time":float(world.time)}}

static func apply_snapshot(world: Node3D, data: Dictionary) -> bool:
	if int(data.get("schema",0)) != 1: return false
	var state_by_id: Dictionary = {}
	for record in data.get("objects",[]):
		if record is Dictionary and record.has("id"):
			state_by_id[int(record["id"])] = record
	for obj in world.sim_objects:
		if not is_instance_valid(obj): continue
		if not state_by_id.has(int(obj.uid)): continue
		var record: Dictionary = state_by_id[int(obj.uid)]
		if String(record.get("kind","")) != String(obj.kind): continue
		obj.position = _as_vector(record.get("position",[]),obj.position)
		for attr in ["water","heat","fuel","health","growth","food","brittleness"]:
			if record.has(attr):
				obj.set(attr,float(record[attr]))
		obj.burning = bool(record.get("burning",false))
		obj.dead = bool(record.get("dead",false))
		obj.set_meta("wetness",obj.water)
		obj.set_meta("burning",obj.burning)
		obj.set_meta("growth",obj.growth)
		obj.update_visual_state()
	# Stable identity is independent of generation/list ordering and spell-
	# transformed species. Legacy saves without IDs still load by old index.
	var history: Array = data.get("animals",[])
	var animal_by_id: Dictionary = {}
	for animal in world.creatures:
		if is_instance_valid(animal) and not String(animal.persistent_id).is_empty():
			animal_by_id[String(animal.persistent_id)] = animal
	for i in range(history.size()):
		if not (history[i] is Dictionary): continue
		var record: Dictionary = history[i]
		var animal = null
		if record.has("id"):
			animal = animal_by_id.get(String(record["id"]),null)
		elif i < world.creatures.size():
			animal = world.creatures[i]
		if not is_instance_valid(animal): continue
		if String(animal.species) != String(record.get("species",animal.species)):
			animal.species = String(record.get("species",animal.species))
			animal.build_model()
		animal.position = _as_vector(record.get("position",[]),animal.position)
		for attr in ["health","hunger","thirst","energy","wetness","growth","asleep","panic"]:
			if record.has(attr): animal.set(attr,float(record[attr]))
		animal.dead = bool(record.get("dead",false))
		if animal.model != null:
			animal.model.scale = Vector3.ONE * float(animal.growth)
	var climate: Dictionary = data.get("weather",{})
	world.wind = float(climate.get("wind",world.wind))
	world.rain_remaining = float(climate.get("rain_remaining",world.rain_remaining))
	world.night_remaining = float(climate.get("night_remaining",world.night_remaining))
	world.time = float(climate.get("time",world.time))
	world.raining = bool(climate.get("raining",world.raining))
	if is_instance_valid(world.rain_fx):
		world.rain_fx.emitting = bool(world.raining)
	# Restore scholarship before item visibility, so mastered books never respawn.
	if world.scholar != null and data.get("scholar",null) is Dictionary:
		world.scholar.restore(data["scholar"])

	# Rebuild pickups from immutable templates: works in a fresh instance AND
	# when loading a save into an already-played world. No duplicates.
	world.collected_pickup_ids.clear()
	for key in data.get("collected_pickups",[]):
		if key is String and world.authored_pickup_templates.has(key):
			if not world.collected_pickup_ids.has(key):
				world.collected_pickup_ids.append(key)
	world.next_drop_serial = maxi(1,int(data.get("next_drop_serial",1)))
	for item in world.items.duplicate():
		if is_instance_valid(item):
			world.items.erase(item)
			item.queue_free()
	for key in world.authored_pickup_templates.keys():
		if world.collected_pickup_ids.has(String(key)): continue
		var template: Dictionary = world.authored_pickup_templates[key]
		if String(template["kind"]) == "book" and world.scholar != null and world.scholar.has_book(String(template["word"])):
			continue
		world.spawn_item(String(template["kind"]),String(template["word"]),
			template["position"],false,String(key))
	# Player-generated drops have their own persistent IDs and positions.
	for dropped in data.get("dropped_pickups",[]):
		if not (dropped is Dictionary): continue
		var kind: String = String(dropped.get("kind",""))
		if kind not in ["stone","herb","amber","torch","lantern"]: continue
		var key: String = String(dropped.get("id",""))
		if not key.begins_with("drop:"): continue
		var p: Vector3 = _as_vector(dropped.get("position",[]),Vector3.ZERO)
		world.spawn_item(kind,String(dropped.get("word","")),p,true,key)

	var player_data: Dictionary = data.get("player",{})
	if world.player != null:
		# Unknown/invalid old items are intentionally rejected, not replayed.
		if player_data.get("inventory",null) is Array:
			world.player.inventory.clear()
			for entry in player_data["inventory"]:
				if entry is String and entry in ["stone","herb","amber","torch","lantern"] and world.player.inventory.size() < 6:
					world.player.inventory.append(entry)
			world.player.selected_slot = clampi(int(player_data.get("selected_slot",0)),
				0,maxi(0,world.player.inventory.size()-1))
			world.player.refresh_held_model()
		if player_data.has("position"):
			world.player.position = _as_vector(player_data["position"],world.player.position)
		world.player.rotation.y = float(player_data.get("yaw",world.player.rotation.y))
		world.player.pitch.rotation.x = float(player_data.get("pitch",world.player.pitch.rotation.x))
		world.player.velocity = Vector3.ZERO
		if world.player.book != null:
			if player_data.get("learned",null) is Array:
				var lexicon: Dictionary = world.player.book.lexicon
				for form in player_data["learned"]:
					if form is String and lexicon.has(form) and not world.player.book.learned.has(form):
						world.player.book.learned.append(form)
			if world.scholar != null:
				for form in world.scholar.studied_forms:
					if not world.player.book.learned.has(form):
						world.player.book.learned.append(form)
			world.player.book.learned.sort()
			world.player.book.total_casts = maxi(0,int(player_data.get("total_casts",world.player.book.total_casts)))
			world.player.book.update_pages()
	return true

static func save_world(world: Node3D, path: String = SAVE_FILE) -> bool:
	if world == null or world.player == null: return false
	# Write a complete replacement, flush it, then rotate the previous save
	# to a recoverable backup. Never truncate the currently playable save.
	var staged: String = path + ".tmp"
	var backup: String = path + ".bak"
	var file: FileAccess = FileAccess.open(staged,FileAccess.WRITE)
	if file == null: return false
	file.store_string(JSON.stringify(snapshot(world),"\t"))
	file.flush()
	file.close()
	var stage_abs: String = ProjectSettings.globalize_path(staged)
	var active_abs: String = ProjectSettings.globalize_path(path)
	var backup_abs: String = ProjectSettings.globalize_path(backup)
	var had_active: bool = FileAccess.file_exists(path)
	if had_active:
		if FileAccess.file_exists(backup):
			if DirAccess.remove_absolute(backup_abs) != OK: return false
		if DirAccess.rename_absolute(active_abs,backup_abs) != OK: return false
	if DirAccess.rename_absolute(stage_abs,active_abs) != OK:
		if had_active: DirAccess.rename_absolute(backup_abs,active_abs)
		return false
	return true

static func load_world(world: Node3D, path: String = SAVE_FILE) -> bool:
	# A corrupted/incomplete primary file cannot erase a good prior save.
	for candidate in [path,path + ".bak"]:
		if not FileAccess.file_exists(candidate): continue
		var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(candidate))
		if not (data is Dictionary): continue
		if int(data.get("schema",0)) != 1: continue
		if not (data.get("objects",null) is Array) or not (data.get("animals",null) is Array):
			continue
		if apply_snapshot(world,data):
			return true
	return false
