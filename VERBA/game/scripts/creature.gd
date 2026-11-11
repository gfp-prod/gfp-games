extends CharacterBody3D
## Wildlife: small purposeful state machine, not a randomly oscillating prop.
const ART = preload("res://scripts/art.gd")
var world
var species := "hare"
# Independent of array order and later transformation spells.
var persistent_id: String = ""
var velocity2 := Vector3.ZERO
var intent := Vector3.ZERO
var state := "wander"
var state_timer := 0.0
var phase := 0.0
var speed := 1.2
var asleep := 0.0
var panic := 0.0
var stop_time := 0.0
var growth := 1.0
var wetness := 0.0
var health := 100.0
var hunger: float = 0.25
var thirst: float = 0.15
var energy: float = 0.80
var attack_cooldown: float = 0.0
var feed_cooldown: float = 0.0
var dead: bool = false
var target_resource = null
var life_stage: float = 0.0
var rng := RandomNumberGenerator.new()
var model: Node3D
var proximity: StaticBody3D
var animated_parts: Dictionary = {}
var path_agent: NavigationAgent3D
var animation_player: AnimationPlayer
var active_clip: String = ""
var using_library_mesh: bool = false
var replan_after: float = 0.0
var familiar_tag: Label3D

func setup(w: Node3D, kind: String, pos3: Vector3, seed_value: int) -> void:
	world = w
	species = kind
	persistent_id = "wild:%s:%d:%d" % [kind, roundi(pos3.x*100.0), roundi(pos3.z*100.0)]
	position = pos3
	rng.seed = seed_value
	phase = rng.randf_range(0, TAU)
	speed = {"hare": 3.8, "deer": 2.7, "fox": 2.8, "wolf": 2.4, "crow": 3.8, "wisp": 1.4}.get(kind, 2.0)

func _ready() -> void:
	# Physical creature body. Spell-target sphere remains separate and non-blocking.
	collision_layer = 32  # creatures collide with one another
	collision_mask = 16 | 32  # terrain, static scenery, other creatures; targeting is separate
	var physical_shape := CollisionShape3D.new()
	physical_shape.name = "PhysicalAnimalCollider"
	var capsule := CapsuleShape3D.new()
	capsule.radius = {"hare":0.15,"crow":0.14,"fox":0.26,"wolf":0.35,"deer":0.40}.get(species,0.22)
	capsule.height = {"hare":0.43,"crow":0.43,"fox":0.60,"wolf":0.91,"deer":1.42}.get(species,0.65)
	physical_shape.shape = capsule
	physical_shape.position.y = capsule.height * 0.5 + 0.04
	add_child(physical_shape)
	floor_snap_length = 0.40
	path_agent = NavigationAgent3D.new()
	path_agent.name = "RoutePlanner"
	path_agent.path_desired_distance = 0.9
	path_agent.target_desired_distance = 1.25
	path_agent.radius = capsule.radius
	path_agent.avoidance_enabled = false
	add_child(path_agent)
	model = Node3D.new()
	model.name = "Anatomy"
	add_child(model)
	build_model()
	proximity = StaticBody3D.new()
	proximity.name = "SpellTarget"
	proximity.collision_layer = 4
	proximity.collision_mask = 0
	proximity.set_meta("creature_ref", self)
	add_child(proximity)
	var c := CollisionShape3D.new()
	var cs := SphereShape3D.new()
	cs.radius = 0.30 if species in ["hare","crow"] else (0.55 if species == "fox" else 0.85)
	c.shape = cs
	c.position.y = 0.23 if species in ["hare","crow"] else (0.40 if species=="fox" else 0.70)
	proximity.add_child(c)
	update_physical_dimensions()
	familiar_tag = Label3D.new()
	familiar_tag.name = "BondedCreatureIdentity"
	familiar_tag.text = "FAMILIAR"
	familiar_tag.pixel_size = .003
	familiar_tag.font_size = 36
	familiar_tag.modulate = Color("e0d3a3")
	familiar_tag.outline_size = 7
	familiar_tag.outline_modulate = Color("2a3228")
	familiar_tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	familiar_tag.position = Vector3(0,1.12,0)
	familiar_tag.visible = false
	add_child(familiar_tag)
	choose_direction()

func update_physical_dimensions() -> void:
	# When a deer becomes a hare (or magic grows a wolf), change physics,
	# spell targeting and navigation clearance together with the visible mesh.
	var dimensions: Dictionary = {
		"hare":[.15,.43,.30,.23],
		"crow":[.14,.43,.30,.23],
		"fox":[.26,.60,.55,.40],
		"wolf":[.35,.91,.85,.70],
		"deer":[.40,1.42,.85,.70],
		"wisp":[.22,.65,.55,.52]
	}
	var dim: Array = dimensions.get(species,[.22,.65,.55,.52])
	var factor: float = clampf(growth,.5,2.0)
	var collision: CollisionShape3D = get_node_or_null("PhysicalAnimalCollider") as CollisionShape3D
	if collision != null and collision.shape is CapsuleShape3D:
		var capsule: CapsuleShape3D = collision.shape as CapsuleShape3D
		capsule.radius = float(dim[0])*factor
		capsule.height = maxf(float(dim[1])*factor, 2.05*capsule.radius)
		collision.position.y = capsule.height*.5+.04
	if path_agent != null:
		path_agent.radius = float(dim[0])*factor
	if proximity != null:
		var target: CollisionShape3D = proximity.get_child(0) as CollisionShape3D
		if target != null:
			if not (target.shape is SphereShape3D):
				target.shape = SphereShape3D.new()
			(target.shape as SphereShape3D).radius = float(dim[2])*factor
			target.position.y = float(dim[3])*factor

func _desired_height() -> float:
	match species:
		"deer": return 1.72
		"wolf": return 0.88
		"fox": return 0.58
		"hare": return 0.46
		"crow": return 0.41
		_: return 1.0

func _model_bounds(root: Node3D) -> AABB:
	var bottom := Vector3(100000,100000,100000)
	var top := Vector3(-100000,-100000,-100000)
	var found := false
	for member in root.find_children("*","MeshInstance3D",true,false):
		var part: MeshInstance3D = member as MeshInstance3D
		if part == null or part.mesh == null: continue
		var box: AABB = part.get_aabb()
		for x in [box.position.x,box.end.x]:
			for y in [box.position.y,box.end.y]:
				for z in [box.position.z,box.end.z]:
					var relative: Transform3D = Transform3D.IDENTITY
					var cursor: Node3D = part
					while cursor != null and cursor != root:
						relative = cursor.transform * relative
						cursor = cursor.get_parent() as Node3D
					var pt: Vector3 = relative * Vector3(x,y,z)
					bottom = bottom.min(pt)
					top = top.max(pt)
					found = true
	if not found: return AABB()
	return AABB(bottom, top-bottom)

func build_model() -> void:
	if model == null: return
	for child in model.get_children(): child.queue_free()
	animated_parts.clear()
	animation_player = null
	active_clip = ""
	using_library_mesh = false
	var filename := ""
	match species:
		"deer": filename = "Stag.gltf" if rng.randf() < 0.35 else "Deer.gltf"
		"wolf": filename = "Wolf.gltf"
		"fox": filename = "Fox.gltf"
		"hare": filename = "ForestRabbit.glb"
		"crow": filename = "Crow.glb"
	if not filename.is_empty():
		var resource_path: String = "res://assets/models/cc0/wildlife/" + filename
		if not ResourceLoader.exists(resource_path):
			push_error("Missing VERBA wildlife art: " + resource_path)
			return
		var loaded: PackedScene = load(resource_path)
		if loaded == null:
			push_error("Could not import VERBA wildlife art: " + resource_path)
			return
		var animal: Node3D = loaded.instantiate()
		animal.name = "RiggedWildlife"
		model.add_child(animal)
		var bounds: AABB = _model_bounds(animal)
		if bounds.size.y < 0.001:
			push_error("Invalid wildlife geometry bounds: " + filename)
			return
		var factor: float = clampf(_desired_height()/bounds.size.y,0.008,150.0)
		animal.scale = Vector3.ONE * factor
		animal.position.y = -bounds.position.y * factor + 0.025
		using_library_mesh = true
		animation_player = animal.find_child("AnimationPlayer", true, false) as AnimationPlayer
		if animation_player == null:
			push_error("No skeletal animations for "+filename)
		else:
			_update_anim("idle")
		return
	if species == "wisp":
		var glow := ART.mat(Color("8bd5c9"), 0.15, Color("3b9caa"))
		ART.orb(model, Vector3(0, 1.0, 0), Vector3(.25,.30,.24), glow, 16)
		ART.orb(model, Vector3(0, .58, .08), Vector3(.12,.42,.10), glow)
		var light := OmniLight3D.new()
		light.light_color = Color("65b8ab")
		light.light_energy=.75
		light.omni_range=3.0
		light.position.y=1.0
		model.add_child(light)

func choose_direction() -> void:
	state_timer = rng.randf_range(2.5, 8.0)
	var angle := rng.randf_range(0,TAU)
	intent = Vector3(sin(angle),0,cos(angle))

func _player_exposed_to_attack() -> bool:
	if world == null or world.player == null: return false
	var mouth: Vector3 = global_position + Vector3.UP*.78
	var target: Vector3 = world.player.global_position + Vector3.UP*.97
	var ray := PhysicsRayQueryParameters3D.create(mouth,target)
	# Real stone walls, tree trunks and the cottage block the bite.
	# Actors themselves do not obstruct the ray, avoiding false positives
	# from the wolf's own spell-target proximity sphere.
	ray.collision_mask = 16
	ray.exclude = [get_rid()]
	return get_world_3d().direct_space_state.intersect_ray(ray).is_empty()

func _physics_process(delta: float) -> void:
	if not is_instance_valid(world): return
	if familiar_tag != null:
		familiar_tag.visible = world.familiar_id == persistent_id and not dead
	phase += delta * (2.0 + speed)
	wetness = minf(1.0, wetness + delta * 0.23) if world.raining else maxf(0.0, wetness - delta * .06)
	# Needs and injury are individual to this animal; they persist after spells.
	if dead:
		if world.familiar_id == persistent_id:
			world.familiar_id = ""
			world.familiar_mode = "follow"
		if using_library_mesh:
			_update_anim("death")
		else:
			model.rotation.z = lerpf(model.rotation.z, -PI*.5, minf(1.0,delta*3.0))
		return
	hunger = minf(1.0,hunger + delta*.0018)
	thirst = minf(1.0,thirst + delta*.0023)
	energy = maxf(0.0,energy - delta*.0009)
	attack_cooldown = maxf(0.0,attack_cooldown-delta)
	feed_cooldown = maxf(0.0,feed_cooldown-delta)
	if health <= 0.0:
		dead = true
		state = "dead"
		return
	if world.raining: thirst=maxf(0.0,thirst-delta*.018)
	if absf(position.x-world.stream_x(position.z))<4.8 and thirst>.2:
		thirst=maxf(0.0,thirst-delta*.15)
	if asleep > 0:
		asleep -= delta
		state = "sleep"
	if stop_time > 0: stop_time -= delta
	if panic > 0: panic -= delta
	var player_distance: float = global_position.distance_to(world.player.global_position)
	var companion: bool = world.familiar_id == persistent_id
	if companion:
		# Tamed animals no longer flee from their owner, forage at random,
		# chase prey or wander away. All physical navigation/animation below
		# remains the same as for wild animals.
		panic = 0.0
		target_resource = null
		if world.familiar_mode == "rest" or asleep > 0.0:
			state = "still"
			intent = Vector3.ZERO
		elif world.familiar_mode == "stay":
			state = "still"
			intent = Vector3.ZERO
		else:
			var toward_player: Vector3 = world.player.global_position-global_position
			toward_player.y = 0.0
			if toward_player.length() > 2.6:
				intent = toward_player.normalized()
				state = "follow"
			else:
				intent = Vector3.ZERO
				state = "still"
	else:
		var offering_keeps_calm: bool = (species == "hare" and world.player.inventory.has("herb")) or (species == "crow" and world.player.inventory.has("amber"))
		var threatened := player_distance < (4.5 if species in ["hare","deer"] else 2.0) and not offering_keeps_calm
		if world.nearest_fire_distance(global_position) < 6.0: threatened = true
		var predator: Node3D=null
		if species == "hare":predator=world.nearest_creature(position,"fox",10.0)
		if species in ["hare","deer"]:
			var wolf:Node3D=world.nearest_creature(position,"wolf",11.0)
			if wolf != null and (predator == null or global_position.distance_to(wolf.global_position)<global_position.distance_to(predator.global_position)):predator=wolf
		if predator != null and predator != self:threatened = true
		if species == "wisp": threatened = false
		# Wolves are the first genuine survival threat. A living wolf notices
		# the player and pursues, but CANNOT injure through an actual wall.
		if species == "wolf" and player_distance < 9.0 and asleep <= 0.0 and stop_time <= 0.0:
			state = "hunt"
			panic = 0.0
			intent = (world.player.global_position-global_position).normalized()
			if player_distance < 1.75 and attack_cooldown <= 0.0 and _player_exposed_to_attack():
				if world.player.take_damage(19.0,"wolf"):
					attack_cooldown = 2.4
					hunger = maxf(0.0,hunger-.08)
		elif threatened and asleep <= 0:
			panic = 3.0
			state = "flee"
			intent = (position - predator.position).normalized() if predator != null else (position - world.player.position).normalized()
		elif panic <= 0 and asleep <= 0 and stop_time <= 0:
			state = "wander"
			state_timer -= delta
			if state_timer < 0: choose_direction()
		if stop_time > 0 or asleep > 0: state = "still"
		if species in ["hare","deer"] and state == "wander" and hunger > .24:
			target_resource=world.nearest_food(position,10.0)
			if target_resource != null:
				state="forage"
				intent=(target_resource.position-position).normalized()
				if global_position.distance_to(target_resource.global_position)<1.1 and feed_cooldown <=0.0:
					if target_resource.apply_effect("eat",.55):
						hunger=maxf(0.0,hunger-.19)
						energy=minf(1.0,energy+.05)
						feed_cooldown=2.5
		elif species in ["fox","wolf"] and state == "wander" and hunger>.20:
			var target_kind: String="hare" if species == "fox" else "deer"
			var prey=world.nearest_creature(position,target_kind,13.0)
			if prey != null and prey != self and not prey.dead:
				intent=(prey.position-position).normalized()
				state="hunt"
				if global_position.distance_to(prey.global_position)<1.45 and attack_cooldown <= 0.0:
					prey.afflict("injure")
					hunger=maxf(0.0,hunger-.22)
					attack_cooldown=4.0
		elif species == "crow" and state == "wander" and hunger>.35:
			for other in world.creatures:
				if other != self and is_instance_valid(other) and other.dead and global_position.distance_to(other.global_position)<10.0:
					intent=(other.position-position).normalized()
					state="scavenge"
					if global_position.distance_to(other.global_position)<1.2 and feed_cooldown<=0.0:
						hunger=maxf(0.0,hunger-.25)
						feed_cooldown=5.0
					break
		# If an exhausted animal is safe, it occasionally rests without a spell.
		if energy < .12 and state == "wander" and panic <=0:
			asleep=6.0;energy=minf(1.0,energy+.30)
	var factor := 0.0 if state == "still" else (1.45 if state == "follow" else 1.8 if state == "flee" else 1.25 if state == "hunt" else 0.3)
	if species == "crow" and state != "still":
		factor *= 1.1
	var motion: Vector3 = Vector3(intent.x,0,intent.z).normalized() * speed * factor
	if position.length() > 55.0 and not companion: motion = -Vector3(position.x,0,position.z).normalized() * speed * 0.7
	# Route selection is separate from ecology. When the creature changes its
	# intention, Godot resolves a path around tree trunks and structures.
	replan_after -= delta
	if path_agent != null and replan_after <= 0.0 and motion.length_squared() > 0.01:
		var requested_goal: Vector3 = global_position + Vector3(intent.x, 0.0, intent.z).normalized() * 11.0
		requested_goal.y = world.height_at(requested_goal.x, requested_goal.z) + 0.3
		path_agent.target_position = requested_goal
		replan_after = rng.randf_range(0.9, 1.7)
	if path_agent != null and not path_agent.is_navigation_finished() and motion.length_squared() > 0.01:
		var next_point: Vector3 = path_agent.get_next_path_position()
		var toward: Vector3 = next_point - global_position
		toward.y = 0.0
		if toward.length_squared() > 0.10:
			motion = toward.normalized() * motion.length()
	# Ray steer before moving so animals can skirt obstacles rather than
	# trying to cross the same tree every frame while chasing prey.
	var desired: Vector3 = motion.normalized() if motion.length_squared() > .0001 else Vector3.ZERO
	if desired.length_squared() > .001:
		var ray_from: Vector3 = global_position + Vector3.UP * 0.6
		var ray_to: Vector3 = ray_from + desired * (1.5 if species in ["hare", "crow"] else 2.6)
		var probe: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(ray_from, ray_to, 16, [get_rid()])
		var obstacle: Dictionary = get_world_3d().direct_space_state.intersect_ray(probe)
		if not obstacle.is_empty():
			var obstacle_normal: Vector3 = obstacle["normal"]
			var tangent: Vector3 = Vector3(-obstacle_normal.z, 0.0, obstacle_normal.x)
			if tangent.dot(desired) < 0.0: tangent = -tangent
			if tangent.length_squared() > .01:
				desired = (tangent * 0.85 + obstacle_normal * 0.45).normalized()
			motion = desired * motion.length()
	# CharacterBody3D physics: collision-safe movement against the same solid
	# terrain/walls/trees as the player, with gravity and sliding.
	var future: Vector3 = position + motion * delta
	if absf(future.x - world.stream_x(future.z)) < 3.1 and species != "crow" and not companion:
		motion = Vector3.ZERO
		choose_direction()
	velocity.x = motion.x
	velocity.z = motion.z
	if species == "wisp":
		velocity.y = 0.0
		position.y = lerpf(position.y, world.height_at(position.x, position.z) + 1.9, minf(1.0, delta * 4.0))
	elif is_on_floor():
		velocity.y = -0.1
	else:
		velocity.y -= 14.0 * delta
	move_and_slide()
	if is_on_wall():
		# Physics always wins over navigation; reconsider blocked routes.
		replan_after = 0.0
		state_timer = minf(state_timer, 0.5)

	if motion.length_squared() > 0.15:
		model.rotation.y = lerp_angle(model.rotation.y,atan2(-motion.x,-motion.z),minf(1.0,delta*4.0))
	# Skinned Quaternius wildlife plays real armature clips (not fake leg swings).
	if using_library_mesh and animation_player != null:
		var action: String = "idle"
		if motion.length_squared() > 0.03:
			action = "run" if state in ["flee","hunt"] else "walk"
		elif state == "forage":
			action = "eat"
		_update_anim(action)
		return
	# Animated wildlife uses authored skeleton clips; the joint fallback is retained for wisps.
	var anim_strength: float = 0.0 if state in ["still", "sleep", "dead"] else 1.0 if motion.length_squared() > .03 else .25
	for part_name in animated_parts.keys():
		var limb: Node3D = animated_parts[part_name]
		if not is_instance_valid(limb): continue
		if String(part_name).begins_with("leg_"):
			var offset: float = PI if part_name in ["leg_fl", "leg_br"] else 0.0
			var target: float = sin(phase * (3.5 if species == "hare" else 2.3) + offset) * .32 * anim_strength
			limb.rotation.x = lerpf(limb.rotation.x, target, minf(1.0, delta * 10.0))
		elif String(part_name).begins_with("wing_") or String(part_name) in ["LeftWing","RightWing"]:
			var side: float = -1.0 if String(part_name) in ["wing_l","LeftWing"] else 1.0
			limb.rotation.z = side * (.12 + sin(phase * 7.0) * .48 * anim_strength)
		elif String(part_name) in ["LeftHindLeg","RightHindLeg","LeftHindUpLeg","RightHindUpLeg"]:
			var phase_offset: float = PI if String(part_name).begins_with("Left") else 0.0
			limb.rotation.x = sin(phase * 5.0 + phase_offset) * .23 * anim_strength
		elif String(part_name) == "Head":
			limb.rotation.y = sin(phase*.65) * .13
		elif String(part_name) == "Tail":
			limb.rotation.x = sin(phase*1.6) * .07
	model.position.y = (sin(phase * 2.5) * 0.035 if state != "still" else -0.07)
	if species == "wisp": model.position.y = sin(phase)*0.23

func _update_anim(action: String) -> void:
	if animation_player == null:
		return
	var options: PackedStringArray = animation_player.get_animation_list()
	var search_words: Array[String] = [action]
	match action:
		"idle": search_words = ["idle", "stand", "rest", "breath"]
		"walk": search_words = ["walk", "trot", "move"]
		"run": search_words = ["run", "gallop", "sprint", "walk"]
		"eat": search_words = ["eat", "graze", "idle"]
		"death": search_words = ["death", "dead", "die", "fall", "idle"]
	var chosen: String = ""
	for word in search_words:
		for clip in options:
			if String(clip).to_lower().contains(word):
				chosen = String(clip)
				break
		if not chosen.is_empty():
			break
	if chosen.is_empty():
		for clip in options:
			if String(clip).to_lower() != "reset":
				chosen = String(clip)
				break
	if chosen.is_empty() or chosen == active_clip:
		return
	active_clip = chosen
	var clip_resource: Animation = animation_player.get_animation(chosen)
	if clip_resource != null:
		clip_resource.loop_mode = Animation.LOOP_NONE if action == "death" else Animation.LOOP_LINEAR
	animation_player.play(StringName(chosen), 0.18)
	animation_player.speed_scale = 1.12 if action == "run" else 1.0

func afflict(kind: String) -> void:
	# An addressed, successful Latin invocation becomes an actual persistent
	# familiar order, not just a few seconds of wild-animal panic.
	if world != null and world.familiar_id == persistent_id:
		match kind:
			"come":
				world.familiar_mode = "follow"
				asleep = 0.0
			"stop":
				world.familiar_mode = "stay"
				asleep = 0.0
			"sleep":
				world.familiar_mode = "rest"
	match kind:
		"sleep": asleep = 12.0; panic = 0.0
		"flee": panic = 11.0; state = "flee"; intent = (position - world.player.position).normalized()
		"stop": stop_time = 9.0; panic = 0.0
		"come": panic=0.0; state="wander"; intent=(world.player.position-position).normalized(); state_timer=5.0
		"transform":
			var options := ["hare","deer","fox","wolf","crow","wisp"]
			options.erase(species)
			species=options[rng.randi_range(0,options.size()-1)]
			speed = {"hare":3.8,"deer":2.7,"fox":2.8,"wolf":2.4,"crow":3.8,"wisp":1.4}.get(species,2.0)
			build_model()
			update_physical_dimensions()
		"rise": position.y += 0.6
		"burn": health-=35.0; panic=7.0
		"injure": health-=28.0;panic=9.0
		"water": wetness=minf(1.0,wetness+.65);thirst=maxf(0.0,thirst-.20)
		"grow":
			growth=minf(1.7,growth+0.27)
			model.scale=Vector3.ONE * growth
			update_physical_dimensions()
