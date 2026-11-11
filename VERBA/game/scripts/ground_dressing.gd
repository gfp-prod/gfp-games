extends RefCounted
## A small, batched authored material layer for the valley.
## Uses the bundled CC0 stone and moss surfaces instead of hundreds of
## physics-less individually spawned MeshInstance3Ds.
## Position is deterministic; the existing living stones remain interactive.

static func populate(world: Node3D) -> void:
	var root := Node3D.new()
	root.name = "GroundDetailClusters"
	world.add_child(root)
	_add_pebbles(world, root)
	_add_mossy_banks(world, root)

static func _add_pebbles(world: Node3D, root: Node3D) -> void:
	var pebble := SphereMesh.new()
	pebble.radial_segments = 7
	pebble.rings = 4
	pebble.radius = .5
	pebble.height = 1.0
	var stone := StandardMaterial3D.new()
	stone.albedo_texture = load("res://assets/textures/real/stone_diffuse.jpg")
	stone.albedo_color = Color("a1a095")
	stone.roughness = 1.0
	stone.vertex_color_use_as_albedo = true
	stone.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = pebble
	# Small low rock-and-gravel groupings break repeated grass without
	# turning the meadow into gravel, and use just one draw call.
	mm.instance_count = 2100
	var rng := RandomNumberGenerator.new()
	rng.seed = 4141131
	var regions: Array[Dictionary] = [
		{"center":Vector2(-16,-18),"radius":19.0,"weight":.24},
		{"center":Vector2(-32, 12),"radius":16.0,"weight":.21},
		{"center":Vector2(  7,-43),"radius":15.0,"weight":.20},
		{"center":Vector2( 40, 23),"radius":18.0,"weight":.17},
		{"center":Vector2( 27, 10),"radius":15.0,"weight":.18}
	]
	for i in range(mm.instance_count):
		var selection: float = rng.randf()
		var region: Dictionary = regions[0]
		var total: float = 0.0
		for option in regions:
			total += float(option["weight"])
			if selection <= total:
				region = option
				break
		var center: Vector2 = region["center"]
		var angle: float = rng.randf_range(0.0,TAU)
		var radius: float = sqrt(rng.randf())*float(region["radius"])
		var x: float = center.x + cos(angle)*radius
		var z: float = center.y + sin(angle)*radius
		var size: float = rng.randf_range(.08,.34)
		# Near the worn road, stones accumulate at its shoulders.
		if i%5 == 0:
			z = rng.randf_range(-34.0,28.0)
			x = sin((29.0-z)/.49*.059)*2.15 + sin((29.0-z)/.49*.16)*.47
			x += (-1.0 if rng.randf() < .5 else 1.0)*rng.randf_range(1.45,3.8)
			size *= .74
		var scale := Vector3(size*rng.randf_range(.9,1.5),
			size*rng.randf_range(.13,.29),size*rng.randf_range(.72,1.34))
		var basis := Basis(Vector3.UP,rng.randf_range(0.0,TAU)).scaled(scale)
		var clear_stone: Vector2 = world.move_vegetation_outside_cottage(x,z)
		x = clear_stone.x
		z = clear_stone.y
		var y: float = world.height_at(x,z) + scale.y*.2
		mm.set_instance_transform(i,Transform3D(basis,Vector3(x,y,z)))
		mm.set_instance_color(i,Color("92938a").lerp(Color("565d55"),rng.randf_range(.1,.7)))
	var node := MultiMeshInstance3D.new()
	node.name = "WeatheredPebblesOneBatch"
	node.multimesh = mm
	node.material_override = stone
	root.add_child(node)

static func _add_mossy_banks(world: Node3D, root: Node3D) -> void:
	# Flattened moss islands conceal geometric terrain repetition on creek
	# banks. A UV-mapped elliptical sphere carries genuine CC0 moss pigment.
	var mesh := SphereMesh.new()
	mesh.radial_segments = 9
	mesh.rings = 4
	mesh.radius = .5
	mesh.height = 1.0
	var moss := StandardMaterial3D.new()
	moss.albedo_texture = load("res://assets/textures/real/moss_diffuse.jpg")
	moss.albedo_color = Color("67775e")
	moss.vertex_color_use_as_albedo = true
	moss.roughness = 1.0
	moss.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = mesh
	mm.instance_count = 580
	var rng := RandomNumberGenerator.new()
	rng.seed = 66101
	for i in range(mm.instance_count):
		var z: float = rng.randf_range(-55.0,58.0)
		var offset: float = rng.randf_range(4.2,12.0)
		var x: float = world.stream_x(z)+offset*(-1.0 if rng.randf()<.5 else 1.0)
		var size: float = rng.randf_range(.28,1.10)
		var scale := Vector3(size*rng.randf_range(1.0,2.1),
			rng.randf_range(.025,.065),size*rng.randf_range(.68,1.33))
		var basis := Basis(Vector3.UP,rng.randf_range(0.0,TAU)).scaled(scale)
		mm.set_instance_transform(i,Transform3D(basis,
			Vector3(x,world.height_at(x,z)+scale.y*.22,z)))
		mm.set_instance_color(i,Color("657b61").lerp(Color("87977a"),rng.randf_range(0.0,.68)))
	var node := MultiMeshInstance3D.new()
	node.name = "WetlandMossCarpetsOneBatch"
	node.multimesh = mm
	node.material_override = moss
	root.add_child(node)
