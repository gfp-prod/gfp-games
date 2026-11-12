extends SceneTree
## Child bloodlines must occupy child-sized world space, not simply be
## adult collision capsules wearing a scaled-down visual costume.
func _initialize() -> void:
	call_deferred("_run")

func _fail(why: String) -> void:
	push_error("VERBA physical family growth: "+why)
	quit(1)

func _run() -> void:
	var world: Node3D=load("res://main.tscn").instantiate()
	root.add_child(world)
	await process_frame
	var created: Dictionary=world.birth_child("ida","orin","Alma")
	if not bool(created.get("ok",false)):
		_fail("Could not create a genuine villager descendant"); return
	var child: Node3D=null
	var parent: Node3D=null
	for actor in world.npcs:
		if String(actor.npc_id)==String(created["id"]): child=actor
		if String(actor.npc_id)=="ida": parent=actor
	if child==null or parent==null:
		_fail("Living physical child or parent was not spawned"); return
	var walk: CollisionShape3D=child.get_node_or_null("PhysicalCitizenCollider")
	var parent_walk: CollisionShape3D=parent.get_node_or_null("PhysicalCitizenCollider")
	var talk: CollisionShape3D=child.get_node_or_null(
		"LivingNPCConversationCollider/CollisionShape3D")
	if walk==null or parent_walk==null or talk==null:
		_fail("Physical walking or ray-interaction capsule was lost"); return
	if not (walk.shape is CapsuleShape3D) or not (talk.shape is CapsuleShape3D):
		_fail("Modular physical actor lost its original capsule physics"); return
	var child_height: float=(walk.shape as CapsuleShape3D).height
	var parent_height: float=(parent_walk.shape as CapsuleShape3D).height
	if child_height>=parent_height*.83:
		_fail("Newborn still collides as an adult-sized villager"); return
	var look_height: float=(talk.shape as CapsuleShape3D).height
	if look_height>1.36:
		_fail("Newborn conversation target is still adult-sized"); return
	if not is_equal_approx(child.name_label.position.y,
			2.29*child.visual_figure.scale.y):
		_fail("Child's floating label is stuck above an invisible adult"); return
	for part in ["left_arm","right_arm","left_leg","right_leg"]:
		if not child.modular_limbs.has(part) or not child.limb_hitboxes.has(part):
			_fail("Growing child lost its independently detachable "+part); return
		if child.limb_hitboxes[part].collision_layer!=4:
			_fail("Child's visible limb lost its targetable hitbox"); return
	# Advance this child's saved birth date inside a deterministic test
	# without altering world ecology or spawning another visual identity.
	var person: Dictionary=world.village_sim.people[created["id"]]
	person["family"]["birth_day"]=world.village_sim.current_day-365*14
	child._apply_genetic_growth()
	var grown_height: float=(walk.shape as CapsuleShape3D).height
	if grown_height<=child_height+.26:
		_fail("Physical collider failed to grow with the child"); return
	if not is_equal_approx(child.name_label.position.y,
			2.29*child.visual_figure.scale.y):
		_fail("Interaction label failed to follow inherited growth"); return
	if absf(walk.position.y-.90*child.visual_figure.scale.y)>.002:
		_fail("Grown body collision is vertically misaligned"); return
	if child.npc_id!=String(created["id"]) or child.name.begins_with("Detached_"):
		_fail("Growing an NPC replaced its persisted simulation identity"); return
	print("PASS: inherited child growth updates walking and conversation collisions, label height and detachable limb identities")
	quit(0)
