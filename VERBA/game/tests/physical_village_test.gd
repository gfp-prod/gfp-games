extends SceneTree
## Test in the real 3D world: all citizens have world bodies and act on simulation.
func _initialize() -> void:
	call_deferred("_run")
func _fail(message: String) -> void:
	push_error("Physical village: " + message)
	quit(1)
func _run() -> void:
	var world = load("res://main.tscn").instantiate()
	root.add_child(world)
	await process_frame
	if world.npcs.size()!=12 or world.village_sim.people.size()!=12:
		_fail("Expected exactly twelve world actors and simulation identities")
		return
	var seen: Dictionary = {}
	var ida = null
	for actor in world.npcs:
		if seen.has(actor.npc_id):
			_fail("Duplicate citizen: "+actor.npc_id)
			return
		seen[actor.npc_id] = true
		if not world.village_sim.people.has(actor.npc_id) or not actor.is_talkable():
			_fail("Citizen cannot be identified or conversed with: "+actor.npc_id)
			return
		var interaction = actor.find_child("LivingNPCConversationCollider",true,false)
		if interaction == null or interaction.get_meta("npc_ref",null)!=actor:
			_fail("Missing reachable dialogue collider for "+actor.npc_id)
			return
		if actor.mobile and actor.get_node_or_null("CitizenNavigation")==null:
			_fail("Missing path planner for "+actor.npc_id)
			return
		if actor.npc_id == "ida": ida=actor
	if ida == null or not ida.mobile:
		_fail("Baker is not a mobile simulated citizen")
		return
	var initial: Vector3 = ida.global_position
	world.village_sim.people["ida"]["last_action"]="work"
	var max_step: float = 0.0
	var previous: Vector3 = initial
	for i in range(240):
		await physics_frame
		var change: float = Vector2(ida.global_position.x-previous.x,ida.global_position.z-previous.z).length()
		max_step = maxf(max_step,change)
		previous = ida.global_position
	var traveled: float = Vector2(initial.x-ida.global_position.x,initial.z-ida.global_position.z).length()
	if traveled < .25:
		_fail("Baker is not moving toward work (%.3fm)" % traveled)
		return
	if max_step > .45:
		_fail("Baker teleported while moving: %.3fm/frame" % max_step)
		return
	print("PASS: 12 unique physical citizens with interaction colliders, navigation and visible utility-based travel")
	quit(0)
