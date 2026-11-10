extends SceneTree
## No x-ray collection from the near-item fallback in a collision world.
func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game: Node3D = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	var player = game.player
	player.position = Vector3(0,game.height_at(0,26)+.10,26)
	player.rotation.y = 0.0
	var p := Vector3(0,game.height_at(0,24.25),24.25)
	game.spawn_item("stone","",p,true,"drop:qa_occluded")
	await physics_frame
	var solid = game.add_solid_box(game,
		Vector3(0,game.height_at(0,25.1)+1.2,25.1),
		Vector3(2.2,2.4,.28),"PickupBlockingWallTest")
	await physics_frame
	player.interact()
	if player.inventory.has("stone"):
		_fail("Player could steal a solid item through a wall")
		return
	for item in game.items:
		if item.persistent_id == "drop:qa_occluded":
			if not is_instance_valid(item):
				_fail("Occluded pickup was incorrectly deleted")
				return
	solid.queue_free()
	await physics_frame
	await physics_frame
	player.interact()
	if not player.inventory.has("stone"):
		_fail("Unobstructed nearby physical pickup stopped working")
		return
	print("PASS: near pickup fallback cannot collect through a wall but succeeds after obstruction removed")
	quit(0)

func _fail(reason: String) -> void:
	push_error(reason)
	quit(1)
