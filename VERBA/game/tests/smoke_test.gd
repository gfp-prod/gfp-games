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
	# Verify the actual instanced landmark, not only disconnected mesh factories.
	var cottage: Node3D = game.find_child("HermitCottage",true,false) as Node3D
	if cottage == null or cottage.find_child("CrookedHermitage",true,false) == null:
		printerr("FAIL: storybook cottage missing from the actual world")
		quit(5)
		return
	if cottage.find_child("CC0ImportedArt",true,false) != null:
		printerr("FAIL: the old prefab cottage is still being rendered")
		quit(6)
		return
	if cottage.find_child("ApothecaryTurretSolid",true,false) == null:
		printerr("FAIL: visual turret lacks solid collision")
		quit(7)
		return
	var wall_instance: MeshInstance3D = cottage.find_child(
		"OnePieceTaperedLimePlasterWalls",true,false) as MeshInstance3D
	if wall_instance == null or not (wall_instance.material_override is StandardMaterial3D):
		printerr("FAIL: visible cottage plaster shell is missing")
		quit(8)
		return
	var plaster: StandardMaterial3D = wall_instance.material_override as StandardMaterial3D
	if plaster.cull_mode != BaseMaterial3D.CULL_DISABLED or plaster.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED:
		printerr("FAIL: actual cottage facade is backface-culled or transparent")
		quit(9)
		return
	print("PASS: scene, world, player, grimoire, wildlife, and lexicon instantiated")
	quit(0)
