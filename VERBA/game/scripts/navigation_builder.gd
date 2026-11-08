extends RefCounted
## Explicit procedural navigation mesh matching the playable terrain.
## Avoids costly runtime baking of every decorative grass blade and mesh.
## Only the character center can use the mesh: block radius includes clearance.
const HALF_EXTENT: float = 58.0
const STEP: float = 2.9

static func traversable(world, x: float, z: float) -> bool:
	if absf(x - world.stream_x(z)) < 5.0:
		return false
	if Vector2(x, z).distance_to(Vector2(29.0, 8.0)) < 6.9:
		return false
	if Vector2(x, z).distance_to(Vector2(4.0, -35.0)) < 9.5:
		return false
	if Vector2(x, z).distance_to(Vector2(-8.0, -7.0)) < 2.4:
		return false
	for blocker in world.navigation_blockers:
		if Vector2(x, z).distance_squared_to(Vector2(blocker.x, blocker.z)) < 1.8 * 1.8:
			return false
	return true

static func install(world) -> NavigationRegion3D:
	var region := NavigationRegion3D.new()
	region.name = "WildlifeNavigationRegion"
	var nav := NavigationMesh.new()
	nav.agent_radius = 0.45
	nav.agent_height = 1.7
	var count: int = int(2.0 * HALF_EXTENT / STEP) + 1
	var points := PackedVector3Array()
	var valid := PackedByteArray()
	for zi in range(count):
		for xi in range(count):
			var x: float = -HALF_EXTENT + float(xi) * STEP
			var z: float = -HALF_EXTENT + float(zi) * STEP
			points.append(Vector3(x, world.height_at(x, z) + 0.16, z))
			valid.append(1 if traversable(world, x, z) else 0)
	nav.vertices = points
	for zi in range(count - 1):
		for xi in range(count - 1):
			var a: int = zi * count + xi
			var b: int = a + 1
			var c: int = a + count
			var d: int = c + 1
			if valid[a] == 1 and valid[b] == 1 and valid[c] == 1 and valid[d] == 1:
				# Winding faces up; identical shared indices prevent cracks.
				nav.add_polygon(PackedInt32Array([a, c, b]))
				nav.add_polygon(PackedInt32Array([b, c, d]))
	region.navigation_mesh = nav
	world.add_child(region)
	return region
