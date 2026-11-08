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
	var origin: Vector3 = player.global_position
	print("DEBUG START: origin=", origin, " floor=",player.is_on_floor(), " basis=",player.global_transform.basis, " mode=",Input.mouse_mode)
	Input.action_press("verba_forward")
	print("DEBUG ACTION: pressed=",Input.is_action_pressed("verba_forward")," process=",player.is_physics_processing())
	for i in range(30):
		await physics_frame
		if i == 2 or i == 15 or i == 29: print("DEBUG FRAME ",i," pos=",player.global_position, " axes=",player.last_motion," velocity=",player.velocity," floor=",player.is_on_floor()," colliding=",player.get_slide_collision_count())
	Input.action_release("verba_forward")
	var horizontal_distance: float = Vector2(origin.x,origin.z).distance_to(Vector2(player.global_position.x,player.global_position.z))
	if horizontal_distance < .5:
		fail("WASD action did not move the character"); return
	if player.global_position.y < -12.0:
		fail("Player fell through terrain"); return
	print("PASS [PHYSICS]: moved ",horizontal_distance,"m; terrain collider and nav mesh available")
	quit(0)
