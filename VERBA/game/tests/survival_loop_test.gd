extends SceneTree
## Real survival loop regression: resources, injury, wolf bite/wall blocking,
## recovery with persistent loss, and backward-compatible save snapshots.
const PERSIST = preload("res://scripts/world_persistence.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var world = load("res://main.tscn").instantiate()
	root.add_child(world)
	await process_frame
	var player = world.player
	if player.health != 100.0 or player.stamina != 100.0:
		_fail("Initial wilderness survival resources are not full")
		return
	if not player.take_damage(22.0,"test"):
		_fail("Actual injury is not possible")
		return
	if absf(player.health-78.0) > .01 or player.take_damage(22.0,"test"):
		_fail("Damage is not clamped or immunity failed against repeated hits")
		return
	player.damage_immunity = 0.0
	player.health = 58.0
	player.inventory.append("herb")
	player.selected_slot = player.inventory.size()-1
	player.refresh_held_model()
	player.use_item()
	if player.inventory.has("herb") or absf(player.health-90.0) > .01:
		_fail("A consumed herb must actually restore vitality")
		return

	var wolf: Node3D
	for animal in world.creatures:
		if animal.species == "wolf":
			wolf = animal
			break
	if wolf == null:
		_fail("There is no wild wolf to make the wilderness dangerous")
		return

	# Force one short encounter at a real terrain point rather than faking
	# world.player.take_damage as if it came from predator AI.
	var point: Vector3 = wolf.position
	player.position = Vector3(point.x+1.15,
		world.height_at(point.x+1.15,point.z)+.22,point.z)
	player.health = 100.0
	player.damage_immunity = 0.0
	wolf.attack_cooldown = 0.0
	await physics_frame
	await physics_frame
	if player.health >= 100.0:
		_fail("Wolf state machine never made a real attack within reach")
		return
	if wolf.state != "hunt":
		_fail("The wolf did not actually enter pursuit state")
		return

	# Bite occlusion must respect the real cottage wall collider. No
	# hidden trigger box should damage the player through a closed house.
	wolf.attack_cooldown = 100.0
	var cottage: Node3D = world.find_child("HermitCottage",true,false) as Node3D
	if cottage == null:
		_fail("Missing cottage for physical line-of-sight test")
		return
	wolf.position = cottage.to_global(Vector3(-2.35,.45,.05))
	player.position = cottage.to_global(Vector3(-3.9,.23,.05))
	await physics_frame
	if wolf._player_exposed_to_attack():
		_fail("Wild predator could bite a player through a collidable wall")
		return

	player.position = Vector3(10.0,world.height_at(10.0,-3.0)+.3,-3.0)
	player.inventory.append("stone")
	player.selected_slot = player.inventory.size()-1
	player.refresh_held_model()
	var previous_drops: int = world.items.size()
	var defeats: int = player.death_count
	player.health = 8.0
	player.damage_immunity = 0.0
	if not player.take_damage(25.0,"wolf"):
		_fail("Fatal injury did not trigger a defeat")
		return
	if player.death_count != defeats+1 or absf(player.health-60.0) > .01:
		_fail("Defeat failed to respawn an injured but living player")
		return
	if world.items.size() != previous_drops+1 or player.inventory.has("stone"):
		_fail("Defeat has no item-loss consequence")
		return
	if player.position.distance_to(Vector3(0,world.height_at(0,26)+.22,26)) > .2:
		_fail("Player did not return to the starting cairn after defeat")
		return

	player.health = 73.5
	player.stamina = 21.0
	var history: Dictionary = PERSIST.snapshot(world)
	if not (history.get("player",null) is Dictionary):
		_fail("Player survival record is not saved")
		return
	player.health = 100.0
	player.stamina = 100.0
	player.death_count = 0
	if not PERSIST.apply_snapshot(world,history):
		_fail("Survival state could not be reloaded")
		return
	if absf(player.health-73.5) > .01 or absf(player.stamina-21.0) > .01 or player.death_count != defeats+1:
		_fail("Injury, stamina or defeats changed across a save reload")
		return
	var legacy: Dictionary = history.duplicate(true)
	legacy["player"].erase("health")
	legacy["player"].erase("stamina")
	legacy["player"].erase("deaths")
	if not PERSIST.apply_snapshot(world,legacy) or player.health != 100.0 or player.stamina != 100.0:
		_fail("Legacy saves should start healthy without survival fields")
		return
	print("PASS: wolf pursuit and physical bite, solid-wall protection, herb healing, consequential defeat and survival save/legacy restore")
	quit(0)

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
