extends SceneTree
## Construction is an actual game loop, not isolated geometry rendering.
## Salvage -> inventory -> snap/validate -> physical part -> save/reload.
const PERSIST = preload("res://scripts/world_persistence.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var world = load("res://main.tscn").instantiate()
	root.add_child(world)
	await process_frame
	var player = world.player
	var craft = world.construction
	if craft == null or not craft.parts.is_empty():
		_fail("A new game must begin with an empty construction record")
		return
	if world.find_child("PlayerBuiltWizardTower",true,false) == null:
		_fail("World has no actual construction-root nodes")
		return

	var lumber: Node3D = world.find_child("SplitOakByCottage",true,false) as Node3D
	if lumber == null or not lumber.has_meta("resource_deposit"):
		_fail("The physical cottage woodpile isn't a gatherable timber source")
		return
	player.position = lumber.global_position + Vector3(0,.25,1.2)
	for i in range(4):
		if not bool(world.harvest_resource(lumber).get("ok",false)):
			_fail("Could not salvage real planks from the timber pile")
			return
	if player.inventory.count("wood") != 4 or int(world.harvest_counts.get("woodpile:hermitage",0)) != 4:
		_fail("Salvage failed to fill actual inventory or deplete the persistent source")
		return

	var stone: Node3D
	for obj in world.sim_objects:
		if obj.kind == "stone" and obj.global_position.x < 20.0:
			stone = obj
			break
	if stone == null:
		_fail("No real stone resource in the world")
		return
	player.position = stone.global_position + Vector3(0,.2,.9)
	if not bool(world.harvest_resource(stone).get("ok",false)):
		_fail("Could not gather physical stone from the vale")
		return
	if player.inventory.count("stone") != 1:
		_fail("Stone gathered outside of the existing inventory")
		return
	if player.inventory.size() != 5:
		_fail("Construction materials should occupy real limited inventory slots")
		return

	var plot: Vector3 = Vector3.ZERO
	var found: bool = false
	for cx in range(-4,7):
		for cz in range(10,17):
			var p := Vector3(float(cx)*3.0,0,float(cz)*3.0)
			player.position = Vector3(p.x,world.height_at(p.x,p.z)+.22,p.z+3.2)
			var inspect: Dictionary = craft.inspect("floor",p,0,player.inventory)
			if bool(inspect.get("ok",false)):
				plot = p
				found = true
				break
		if found: break
	if not found:
		_fail("Every starter valley building site is obstructed")
		return

	var prior: int = player.inventory.size()
	if bool(craft.build("wall",plot,0,player).get("ok",false)):
		_fail("A wall can float without its required foundation")
		return
	if player.inventory.size() != prior:
		_fail("Invalid placements consume materials")
		return
	var base: Dictionary = craft.build("floor",plot,0,player)
	if not bool(base.get("ok",false)) or craft.parts.size()!=1:
		_fail("Could not physically place a stone-and-timber floor")
		return
	if player.inventory.count("stone") != 0 or player.inventory.count("wood") != 3:
		_fail("Foundation didn't spend exactly one wood and one stone")
		return
	if bool(craft.build("floor",plot,0,player).get("ok",false)):
		_fail("Duplicate floors were accepted")
		return
	if player.inventory.count("wood") != 3:
		_fail("Attempting duplicate construction stole resources")
		return
	if not bool(craft.build("wall",plot,0,player).get("ok",false)):
		_fail("Could not attach physical wall to foundation")
		return
	if not bool(craft.build("shelf",plot,0,player).get("ok",false)):
		_fail("Couldn't place first bookcase in tower room")
		return
	if not player.inventory.is_empty() or craft.parts.size()!=3:
		_fail("First completed tower stage did not pay for three independent parts")
		return
	for key in craft.parts.keys():
		var part: Dictionary = craft.parts[key]
		var node: Node3D = part["node"]
		if not is_instance_valid(node) or node.find_child("SolidTower_"+String(key),true,false) == null:
			_fail("Built structure is missing a real world collision body")
			return
	if bool(craft.build("wall",plot,1,player).get("ok",false)):
		_fail("Could build with no actual materials")
		return

	var saved: Dictionary = PERSIST.snapshot(world)
	if saved.get("construction",{}).get("parts",[]).size()!=3:
		_fail("The three built structures are missing from the world snapshot")
		return
	if not PERSIST.apply_snapshot(world,saved):
		_fail("Could not restore the saved tower")
		return
	if craft.parts.size()!=3 or player.inventory.size()!=0:
		_fail("Tower or material expenses disappeared after restore")
		return
	if int(world.harvest_counts.get("woodpile:hermitage",0))!=4:
		_fail("Reloading regenerated previously salvaged timber")
		return
	var old_save: Dictionary = saved.duplicate(true)
	old_save.erase("construction")
	old_save.erase("harvest_counts")
	if not PERSIST.apply_snapshot(world,old_save):
		_fail("An old save without construction could not be loaded")
		return
	if not craft.parts.is_empty() or not world.harvest_counts.is_empty():
		_fail("Old saves invented structures or harvested-material history")
		return

	print("PASS: physical wood and stone harvesting, inventory-costed snapped construction, real collision, duplicate rejection, save/load and legacy migration")
	quit(0)

func _fail(reason: String) -> void:
	push_error(reason)
	quit(1)
