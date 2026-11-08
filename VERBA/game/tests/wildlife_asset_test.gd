extends SceneTree
## VERBA's wildlife must use genuinely different imported skinned models, not legacy primitives.
const ROOT := "res://assets/models/cc0/wildlife/"
const NAMES := ["Deer.gltf", "Stag.gltf", "Fox.gltf", "Wolf.gltf", "Hare.glb", "Crow.glb"]
const CREATURE = preload("res://scripts/creature.gd")
func _initialize() -> void:
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
		if item != "Crow.glb" and (player == null or player.get_animation_list().size() < 4):
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
		# Build the visual node directly: SceneTree._initialize runs before
		# normal scene-tree _ready callbacks are dispatched.
		creature.model = Node3D.new()
		creature.add_child(creature.model)
		creature.build_model()
		if not creature.using_library_mesh:
			fail("Creature still rendering legacy model: " + species)
			creature.queue_free()
			return
		if species == "crow":
			var crow_names: PackedStringArray = PackedStringArray()
			for descendant in creature.model.find_children("*", "Node3D", true, false):
				crow_names.append(String(descendant.name))
			print("VERBA CROW CHILD NODES: ", crow_names)
			if creature.animated_parts.size() < 2:
				fail("Crow missing articulated wing / leg pivots")
				creature.free()
				return
		elif creature.animation_player == null:
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
		if species != "crow":
			creature._update_anim("walk")
			if not creature.animation_player.is_playing():
				fail("Movement animation not playing for " + species)
				return
			print("VERBA RIG MOVEMENT: ", species, " clip=", creature.animation_player.current_animation, " height=", actual_height)
		else:
			print("VERBA CROW ARTICULATED BODY: ", creature.animated_parts.keys(), " height=", actual_height)
		creature.free()
	print("VERBA WILDLIFE IMPORT AND ANIMATION PASS")
	quit(0)
func fail(message: String) -> void:
	push_error(message)
	quit(1)
