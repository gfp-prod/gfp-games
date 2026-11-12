extends RefCounted
## Shared authored geography. The old instructional village, cottage, castle
## and existing plot coordinates remain fixed to preserve older saves.
## Only the modern roadside station leaves its implausibly cramped location.
const HALF_EXTENT: float = 128.0
const STATION: Vector2 = Vector2(-102.0,77.0)
const CASTLE: Vector2 = Vector2(-49.0,44.0)
const LAKE: Vector2 = Vector2(79.0,-60.0)
const LAKE_RADII: Vector2 = Vector2(20.0,15.0)

static func lake_distance(x: float, z: float) -> float:
	var dx: float = (x-LAKE.x)/LAKE_RADII.x
	var dz: float = (z-LAKE.y)/LAKE_RADII.y
	# Slightly uneven banks; the irregularity is deterministic and matches
	# shoreline geometry and the terrain shader.
	return sqrt(dx*dx+dz*dz)*(1.0+0.044*sin(x*.37)+.031*cos(z*.29))

static func lake_level(world) -> float:
	return world._raw_height_at(LAKE.x,LAKE.y)-.38

static func lake_height(world, x: float, z: float, previous: float) -> float:
	var radial: float=lake_distance(x,z)
	if radial>=1.26:
		return previous
	var water: float=lake_level(world)
	var bottom: float=water-2.20+.25*sin(x*.14)*cos(z*.13)
	var bank: float=lerpf(bottom,water+.50,smoothstep(.66,1.22,radial))
	var influence: float=1.0-smoothstep(.82,1.26,radial)
	return lerpf(previous,bank,influence)

static func is_lake_water(x: float,z: float) -> bool:
	return lake_distance(x,z)<.995
