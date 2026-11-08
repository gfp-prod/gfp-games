extends SceneTree
## Headless runtime integration test: objects change independently.
## Run via: godot --headless --path . --script res://tests/ecology_smoke_test.gd

func _initialize() -> void:
	call_deferred("run_checks")

func fail(message: String) -> void:
	printerr("FAIL [ECOLOGY]: " + message)
	quit(1)

func run_checks() -> void:
	var scene=load("res://main.tscn")
	if scene == null:fail("Main scene missing");return
	var game=scene.instantiate()
	root.add_child(game)
	await process_frame
	if game.sim_objects.size()<15:fail("Not enough independently simulated objects");return
	var trees: Array = []
	var food_patches: Array = []
	var stones: Array = []
	for obj in game.sim_objects:
		if obj.kind == "tree":trees.append(obj)
		elif obj.kind in ["grass","fern"]:food_patches.append(obj)
		elif obj.kind == "stone":stones.append(obj)
	if trees.size()<2 or food_patches.size()<2 or stones.size()<2:fail("Missing object types");return
	var first=trees[0]
	var second=trees[1]
	var before_second: float=second.growth
	first.apply_effect("grow",1.0)
	if first.growth <= 1.0 or absf(second.growth-before_second)>.0001:fail("Growth leaked between objects");return
	first.apply_effect("water",1.0)
	if first.apply_effect("ignite"):fail("Waterlogged tree ignited");return
	if first.water < .5:fail("Tree lost wetness state");return
	if not second.apply_effect("ignite"):fail("Dry second tree would not ignite");return
	var first_rock=stones[0]
	var second_rock=stones[1]
	first_rock.apply_effect("impact",2.0)
	if first_rock.brittleness <= second_rock.brittleness:fail("Individual rocks did not diverge");return
	if first_rock.apply_effect("ignite"):fail("Nonflammable rock ignited");return
	var eaten=food_patches[0]
	var not_eaten=food_patches[1]
	var food_before:float=not_eaten.food
	if not eaten.apply_effect("eat",1.0):fail("Edible vegetation could not be eaten");return
	if absf(not_eaten.food-food_before)>.0001:fail("Grazing affected another plant");return
	game.ecology_step(0.5)
	if game.creatures.size()<2:fail("No creatures to interact with simulated world");return
	print("PASS [ECOLOGY]: ",game.sim_objects.size()," independent objects; isolated growth, water, fire, rock fractures, grazing, tick step")
	quit(0)
