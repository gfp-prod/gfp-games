extends SceneTree
## Run from the project directory: godot --headless --path . --script res://tests/smoke_test.gd

func _initialize() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	var scene=load("res://main.tscn")
	if scene == null:
		printerr("FAIL: main scene could not load")
		quit(1)
		return
	var game=scene.instantiate()
	root.add_child(game)
	await process_frame
	if game.player==null or game.player.book==null:
		printerr("FAIL: player or physical grimoire missing")
		quit(2)
		return
	if game.creatures.size()<2:
		printerr("FAIL: living wildlife missing")
		quit(3)
		return
	var entry=game.magic.lexicon.get("ignis",{})
	if entry.is_empty():
		printerr("FAIL: Latin lexicon missing")
		quit(4)
		return
	print("PASS: scene, world, player, grimoire, wildlife, and lexicon instantiated")
	quit(0)
