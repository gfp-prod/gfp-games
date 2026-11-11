extends SceneTree
const PERSIST=preload("res://scripts/world_persistence.gd")
func _initialize() -> void: call_deferred("_run")
func fail(message: String) -> void:
	push_error("Living herb harvest: "+message)
	quit(1)
func _run() -> void:
	var world=load("res://main.tscn").instantiate()
	root.add_child(world)
	await process_frame
	var patch=world.spawn_growth_patch(world.player.global_position+Vector3(1,0,0))
	if patch==null:
		fail("Could not create a real spell-grown patch")
		return
	patch.food=0.9
	patch.health=1.0
	var position=world.player.position
	world.player.position=Vector3(patch.position.x,world.height_at(patch.position.x,patch.position.z)+0.3,patch.position.z+1.0)
	await physics_frame
	var initial: int=world.player.inventory.count("herb")
	var gathered: Dictionary=world.harvest_resource(patch)
	if not gathered.get("ok",false) or world.player.inventory.count("herb")!=initial+1:
		fail("Living spell patch failed to yield a physical herb")
		return
	if patch.food>=0.65 or world.harvest_resource(patch).get("ok",false):
		fail("Plant gave duplicate harvest without recovery")
		return
	var record: Dictionary=PERSIST.snapshot(world)
	patch.food=0.95
	if not PERSIST.apply_snapshot(world,record):
		fail("Could not reload world")
		return
	var found=null
	for obj in world.sim_objects:
		if is_instance_valid(obj) and int(obj.uid)==int(patch.uid): found=obj;break
	if found==null or found.food>=0.65:
		fail("Save/load replenished depleted patch")
		return
	if world.harvest_resource(found).get("ok",false):
		fail("Reload duplicated harvestable biomass")
		return
	if not found.apply_effect("grow",5.0):
		fail("Latin growth could not restore living patch")
		return
	if found.food<0.65 or not world.harvest_resource(found).get("ok",false):
		fail("Growth magic cannot replenish actual harvestable herbs")
		return
	print("PASS: spell-grown plant harvests real herb, prevents duplication, persists depletion, Latin growth restores yield")
	quit(0)
