extends SceneTree
## Real world regression: a physical cottage cannot have terrain and plants
## poking through an invisible floor, and old authored ecology IDs stay stable.

func _initialize() -> void:
	call_deferred("_check")

func _check() -> void:
	var world: Node3D = load("res://main.tscn").instantiate()
	root.add_child(world)
	await process_frame
	var center_y: float = world.height_at(29.0,8.0)
	var c: float = cos(-.28)
	var s: float = sin(-.28)
	# Full floor and annex footprint: the site must be level underneath.
	for lx in [-2.9,-1.5,0.0,1.5,2.9,4.2]:
		for lz in [-2.55,0.0,2.55]:
			var x: float = 29.0+c*float(lx)+s*float(lz)
			var z: float = 8.0-s*float(lx)+c*float(lz)
			if absf(world.height_at(x,z)-center_y) > .012:
				_fail("Terrain still intersects visible cottage floor or turret footing")
				return
			if not world.is_inside_cottage_plot(x,z):
				_fail("Cottage exclusion misses a point inside the building")
				return
			var displaced: Vector2 = world.move_vegetation_outside_cottage(x,z)
			if world.is_inside_cottage_plot(displaced.x,displaced.y,.12):
				_fail("Foliage relocation left grass under the cottage")
				return
	if absf(world.height_at(-42.0,-36.0)-world._raw_height_at(-42.0,-36.0)) > .00001:
		_fail("Remote valley terrain changed while flattening the cottage site")
		return
	var cbox: Node3D = world.find_child("HermitCottage",true,false) as Node3D
	if cbox == null:
		_fail("World lost the hermitage")
		return
	var floor: MeshInstance3D = cbox.find_child("ContinuousSolidLookingCottageFloor",true,false) as MeshInstance3D
	if floor == null:
		_fail("Finished interior floor missing")
		return
	if floor.mesh.get_aabb().position.y < .245:
		_fail("Visible floor sank below the original physical slab")
		return
	print("PASS: cottage plot is level, exterior terrain unchanged, vegetation displaced, finished floor remains solid")
	quit(0)

func _fail(reason: String) -> void:
	push_error(reason)
	quit(1)
