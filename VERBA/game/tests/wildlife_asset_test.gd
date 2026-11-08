extends SceneTree
## VERBA's wildlife must use genuinely different imported skinned models, not legacy primitives.
const ROOT := "res://assets/models/cc0/wildlife/"
const NAMES := ["Deer.gltf", "Stag.gltf", "Fox.gltf", "Wolf.gltf"]
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
		if player == null or player.get_animation_list().size() < 4:
			fail(item + " missing rig animations")
			actor.free()
			return
		print("VERBA wildlife OK: ", item, " clips: ", player.get_animation_list())
		actor.free()

	# A model file existing on disk is insufficient: test the actual creature
	# spawning code so an old procedural placeholder cannot silently remain.
	for species in ["deer", "fox", "wolf"]:
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
		if creature.animation_player == null:
			fail("Creature rig has no playing AnimationPlayer: " + species)
			creature.queue_free()
			return
		if creature.model.find_child("RiggedWildlife", true, false) == null:
			fail("Creature isn't showing imported mesh: " + species)
			creature.queue_free()
			return
		print("VERBA SPAWN USES REAL RIG: ", species, " animation=", creature.animation_player.current_animation)
		creature.free()
	print("VERBA WILDLIFE IMPORT AND ANIMATION PASS")
	quit(0)
func fail(message: String) -> void:
	push_error(message)
	quit(1)
