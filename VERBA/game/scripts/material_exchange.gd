extends RefCounted
## Deterministic local material exchange. Fire spreads because nearby objects
## actually heat and dry out, not because a random-effect table said to.
## Candidate pairs are limited to burning sources and nearby objects so the
## rest of the valley needs no expensive per-frame N^2 evaluation.

static func transmit_heat(world: Node3D, dt: float) -> int:
	var ignitions: int = 0
	if dt <= 0.0: return 0
	if world.raining: return 0
	var sources: Array = []
	for thing in world.sim_objects:
		if is_instance_valid(thing) and bool(thing.burning) and not bool(thing.dead):
			sources.append(thing)
	for source in sources:
		for neighbor in world.sim_objects:
			if not is_instance_valid(neighbor) or neighbor == source: continue
			if bool(neighbor.dead) or bool(neighbor.burning): continue
			var distance: float = source.global_position.distance_to(neighbor.global_position)
			if distance > 3.9: continue
			var delta_vec: Vector3 = neighbor.global_position - source.global_position
			var downwind: float = clampf(
				0.5 + signf(float(world.wind) * delta_vec.x) * 0.3,
				0.2,0.8)
			var intensity: float = dt * (1.0 - distance / 4.0) * (0.75 + downwind)
			var before: bool = bool(neighbor.burning)
			neighbor.apply_effect("heat",intensity)
			if not before and bool(neighbor.burning):
				world.add_fire(neighbor.global_position,neighbor)
				ignitions += 1
	return ignitions
