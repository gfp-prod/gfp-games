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
			"pitch":float(world.player.pitch.rotation.x)
		}
	return {"schema":1,"saved_unix":Time.get_unix_time_from_system(),
		"objects":objects,"animals":animals,"player":player,
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
	var history: Array = data.get("animals",[])
	for i in range(mini(history.size(),world.creatures.size())):
		var record: Dictionary = history[i]
		var animal = world.creatures[i]
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
	var player_data: Dictionary = data.get("player",{})
	if world.player != null and player_data.has("position"):
		world.player.position = _as_vector(player_data["position"],world.player.position)
		world.player.rotation.y = float(player_data.get("yaw",world.player.rotation.y))
		world.player.pitch.rotation.x = float(player_data.get("pitch",world.player.pitch.rotation.x))
		world.player.velocity = Vector3.ZERO
	return true

static func save_world(world: Node3D, path: String = SAVE_FILE) -> bool:
	if world == null or world.player == null: return false
	var file: FileAccess = FileAccess.open(path,FileAccess.WRITE)
	if file == null: return false
	file.store_string(JSON.stringify(snapshot(world),"\t"))
	file.close()
	return true

static func load_world(world: Node3D, path: String = SAVE_FILE) -> bool:
	if not FileAccess.file_exists(path): return false
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not (data is Dictionary): return false
	return apply_snapshot(world,data)
