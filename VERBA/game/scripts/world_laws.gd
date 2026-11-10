extends RefCounted
## Spells are instructions to the SAME persistent objects that weather, grazing
## and natural fire affect. This layer does not invent unrelated random results.
var world: Node3D

func _init(w: Node3D) -> void:
	world = w

func _matches(target: Node3D, kind: String) -> bool:
	if not is_instance_valid(target): return false
	if kind.is_empty(): return true
	if target.has_method("afflict"):
		return String(target.species) == kind
	if target.has_method("apply_effect"):
		var thing: String = String(target.kind)
		if kind == "tree": return thing == "tree" or thing == "dead_tree"
		if kind == "grass": return thing == "fern" or thing == "grass"
		return thing == kind
	return false

func _attempt(target: Node3D, effect: String) -> bool:
	if not is_instance_valid(target): return false
	if target.has_method("afflict"):
		if effect == "kindle":
			target.afflict("burn")
			return true
		if effect == "frost":
			target.afflict("stop")
			return true
		if effect in ["sleep","flee","stop","come","transform","rise","grow"]:
			target.afflict(effect)
			return true
		return false
	if not target.has_method("apply_effect"): return false
	var translated: String = effect
	match effect:
		"kindle":
			if target.has_method("flammable") and not target.flammable():
				return target.apply_effect("heat",0.7)
			translated = "ignite"
		"sleep","flee","come","stop","transform":
			return false
		"frost": translated = "frost"
	if target.apply_effect(translated,1.0):
		if translated == "ignite":
			world.add_fire(target.global_position,target)
		return true
	return false

func invoke(parsed: Dictionary, position: Vector3, target: Node3D = null) -> Dictionary:
	var effect: String = String(parsed.get("effect",""))
	var kind: String = String(parsed.get("kind",""))
	var plurality: bool = String(parsed.get("number","singular")) == "plural"
	var radius: float = 12.0 if plurality else 6.0
	var candidates: Array[Node3D] = []
	if is_instance_valid(target) and _matches(target,kind):
		candidates.append(target)
	for obj in world.sim_objects:
		if not is_instance_valid(obj) or not (obj is Node3D): continue
		if obj.global_position.distance_to(position) > radius: continue
		if not _matches(obj,kind) or candidates.has(obj): continue
		candidates.append(obj)
	for animal in world.creatures:
		if not is_instance_valid(animal) or not (animal is Node3D): continue
		if animal.global_position.distance_to(position) > radius: continue
		if not _matches(animal,kind) or candidates.has(animal): continue
		candidates.append(animal)
	candidates.sort_custom(func(a: Node3D, b: Node3D) -> bool:
		return a.global_position.distance_squared_to(position) < b.global_position.distance_squared_to(position))
	var affected: int = 0
	for object in candidates:
		if _attempt(object,effect):
			affected += 1
		if not plurality and affected >= 1: break
		if affected >= 32: break
	if affected == 0 and effect == "grow" and kind.is_empty() and not plurality:
		var germinated = world.spawn_growth_patch(position)
		affected = 1 if germinated != null else 0
	if affected == 0 and effect == "kindle" and kind.is_empty() and not plurality:
		# An untargeted flame can start a fire on the ground.
		world.add_fire(position)
		affected = 1
	return {
		"ok":affected > 0, "count":affected,
		"message":"%d %s answered." % [affected,"things" if plurality else "thing"] if affected > 0 else "Nothing nearby answers that form."
	}
