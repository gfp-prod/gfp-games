extends SceneTree
## VERBA's wildlife must use genuinely different imported skinned models, not legacy primitives.
const ROOT := "res://assets/models/cc0/wildlife/"
const NAMES := ["Deer.gltf", "Stag.gltf", "Fox.gltf", "Wolf.gltf", "Hare.glb", "Crow.glb"]
const CREATURE = preload("res://scripts/creature.gd")
func _initialize() -> void:
	call_deferred("_run_checks")

func _run_checks() -> void:
	for item in NAMES:
		var path: String = ROOT + item
		if not ResourceLoader.exists(path):
			fail("Missing wildlife asset: " + path)
			return
		var source: PackedScene = load(path)
		if source == null:
			fail("Couldn't import wildlife: " + item)
			return
		var actor: Node3D = source.instantiate()
		var player: AnimationPlayer = actor.find_child("AnimationPlayer", true, false) as AnimationPlayer
		if player == null or player.get_animation_list().size() < 4:
			fail(item + " missing rig animations")
			actor.free()
			return
		print("VERBA wildlife OK: ", item, " clips: ", player.get_animation_list() if player != null else "articulated wing / leg pivots")
		actor.free()

	# A model file existing on disk is insufficient: test the actual creature
	# spawning code so an old procedural placeholder cannot silently remain.
	for species in ["deer", "fox", "wolf", "hare", "crow"]:
		var creature = CREATURE.new()
		creature.species = species
		creature.rng.seed = 567
		# Instantiate the ACTUAL wildlife actor and call _ready as gameplay does.
		root.add_child(creature)
		await process_frame
		if not creature.using_library_mesh:
			fail("Creature still rendering legacy model: " + species)
			creature.queue_free()
			return
		if creature.animation_player == null:
			fail("Creature rig has no AnimationPlayer: " + species)
			creature.free()
			return
		if creature.model.find_child("RiggedWildlife", true, false) == null:
			fail("Creature isn't showing imported mesh: " + species)
			creature.queue_free()
			return
		var art: Node3D = creature.model.find_child("RiggedWildlife", true, false) as Node3D
		if art == null:
			fail("Missing creature scene: " + species)
			return
		var bounds: AABB = creature._model_bounds(art)
		var actual_height: float = bounds.size.y * art.scale.y
		var target_height: float = creature._desired_height()
		if absf(actual_height - target_height) > 0.03:
			fail("Size mismatch for %s: %.2f vs %.2f m" % [species,actual_height,target_height])
			return
		creature._update_anim("walk")
		if not creature.animation_player.is_playing():
			fail("Movement animation not playing for " + species)
			return
		var skeleton: Skeleton3D = art.find_child("Skeleton3D", true, false) as Skeleton3D
		if skeleton == null or skeleton.get_bone_count() < 2:
			fail("No actual bone rig for " + species)
			return
		creature.animation_player.seek(0.0, true)
		var initial_poses: Array[Transform3D] = []
		for bone_index in range(skeleton.get_bone_count()):
			initial_poses.append(skeleton.get_bone_pose(bone_index))
		creature.animation_player.advance(0.24)
		var movement: float = 0.0
		for bone_index in range(skeleton.get_bone_count()):
			var before: Transform3D = initial_poses[bone_index]
			var after: Transform3D = skeleton.get_bone_pose(bone_index)
			movement = maxf(movement, before.origin.distance_to(after.origin))
			movement = maxf(movement, before.basis.get_rotation_quaternion().angle_to(after.basis.get_rotation_quaternion()))
		if movement < 0.001:
			fail("Skeletal bones did not animate in walk clip for " + species)
			return
		print("VERBA RIG MOVEMENT: ", species, " clip=", creature.animation_player.current_animation, " height=", actual_height, " bone_delta=", movement)

		creature.free()
	print("VERBA WILDLIFE IMPORT AND ANIMATION PASS")
	quit(0)
func fail(message: String) -> void:
	push_error(message)
	quit(1)
