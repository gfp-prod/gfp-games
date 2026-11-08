extends SceneTree
## Headless integration test. Requires real Godot physics frames, not grep checks.
func _initialize() -> void:
	call_deferred("run_checks")

func fail(message: String) -> void:
	printerr("FAIL [PHYSICS]: " + message)
	quit(1)

func run_checks() -> void:
	var game_scene: PackedScene = load("res://main.tscn")
	if game_scene == null: fail("Could not load scene"); return
	var game = game_scene.instantiate()
	root.add_child(game)
	for i in range(8): await physics_frame
	var player: CharacterBody3D = game.player
	if player == null or player.get_node_or_null("Neck/POVCamera") == null:
		fail("Player or camera absent"); return
	if game.navigation_region == null or game.navigation_region.navigation_mesh == null:
		fail("World navigation region absent"); return
	if game.navigation_region.navigation_mesh.get_polygon_count() < 50:
		fail("Navigation map has too few polygons"); return
	if game.creatures.is_empty() or game.creatures[0].get_node_or_null("RoutePlanner") == null:
		fail("Animal missing NavigationAgent3D"); return
	if player.collision_mask & 16 == 0:
		fail("Player cannot collide with terrain"); return
	if player.collision_mask & 32 == 0:
		fail("Player can pass inside wildlife bodies"); return
	# Sweep the actual player capsule toward an animal-sized collider, far
	# above terrain. This tests physical contact, not just matching bit flags.
	var animal_blocker := StaticBody3D.new()
	animal_blocker.collision_layer = 32
	animal_blocker.collision_mask = 0
	var block_shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.60
	block_shape.shape = sphere
	animal_blocker.add_child(block_shape)
	animal_blocker.global_position = player.global_position + Vector3(0.0, 10.9, -1.5)
	root.add_child(animal_blocker)
	await physics_frame
	var elevated: Transform3D = player.global_transform
	elevated.origin += Vector3.UP * 10.0
	if not player.test_move(elevated, Vector3(0.0, 0.0, -3.0)):
		fail("Player sweeps through collision-layer-32 animal body"); return
	animal_blocker.queue_free()
	var origin: Vector3 = player.global_position
	Input.action_press("verba_forward")
	for i in range(30): await physics_frame
	Input.action_release("verba_forward")
	var horizontal_distance: float = Vector2(origin.x,origin.z).distance_to(Vector2(player.global_position.x,player.global_position.z))
	if horizontal_distance < .5:
		fail("WASD action did not move the character"); return
	if player.global_position.y < -12.0:
		fail("Player fell through terrain"); return
	print("PASS [PHYSICS]: moved ",horizontal_distance,"m; terrain collider and nav mesh available")
	quit(0)
