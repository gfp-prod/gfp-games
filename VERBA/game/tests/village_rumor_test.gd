extends SceneTree
## Social reports cannot reveal events without witness or acquired knowledge.
func _initialize() -> void:
	call_deferred("_run")
func _fail(message: String) -> void:
	push_error("Witness dialogue: "+message)
	quit(1)
func _run() -> void:
	var world = load("res://main.tscn").instantiate()
	root.add_child(world)
	await process_frame
	if world.social.village_sim != world.village_sim:
		_fail("Dialogue and simulation are not the same world authority")
		return
	if not world.village_sim.witness_event("theft","orin","ida"):
		_fail("Incident rejected")
		return
	var event: Dictionary = world.village_sim.events.back()
	var victim_report: String = world.social.heard_report("ida")
	if not victim_report.contains("stole"):
		_fail("The victim cannot report their witnessed theft")
		return
	var response: Dictionary = world.social.choose("ida",2,world.scholar,world.player)
	if not bool(response.get("ok",false)) or not String(response.get("message","")).contains("stole"):
		_fail("Known crime does not alter conversation")
		return
	var unknowing: String = ""
	for id in world.village_sim.people:
		if not event["witnesses"].has(id):
			unknowing=id
			break
	if unknowing.is_empty():
		_fail("The incident was witnessed by everyone")
		return
	if not world.social.heard_report(unknowing).is_empty():
		_fail("NPC without evidence knows an unwitnessed theft")
		return
	print("PASS: heard incidents affect dialogue; uninformed citizens reveal nothing")
	quit(0)
