extends SceneTree
## VERBA's wildlife must use genuinely different imported skinned models, not legacy primitives.
const ROOT := "res://assets/models/cc0/wildlife/"
const NAMES := ["Deer.gltf", "Stag.gltf", "Fox.gltf", "Wolf.gltf"]
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
	print("VERBA WILDLIFE IMPORT AND ANIMATION PASS")
	quit(0)
func fail(message: String) -> void:
	push_error(message)
	quit(1)
