extends RefCounted
## Physical, authored micro-landmarks. Reuses existing free CC0 photo materials.
## Consistent, modest asset hierarchy: no random level-wide object spam.
const ART = preload("res://scripts/art.gd")

static func populate(world: Node3D) -> void:
	var root := Node3D.new()
	root.name = "ValleyScenicDetails"
	world.add_child(root)
	_add_creek_bridge(world,root)
	_add_botanical_clusters(world,root)
	_add_fallen_wood(world,root)

static func _add_creek_bridge(world: Node3D,root: Node3D) -> void:
	# A true traversable, slightly uneven footbridge across the existing
	# stream. It is a visual landmark, not a quest or teleport trigger.
	var z: float = 9.1
	var x: float = world.stream_x(z)
	var ground: float = world.height_at(x,z)
	var bridge := Node3D.new()
	bridge.name = "OldCreekFootbridge"
	bridge.position = Vector3(x,ground+1.08,z)
	root.add_child(bridge)
	var timber: StandardMaterial3D = world.textured(
		"res://assets/textures/cottage_wood.png",Color("807362"))
	timber.uv1_scale=Vector3(1.4,2.5,2.5)
	var darkwood: StandardMaterial3D = world.textured(
		"res://assets/textures/cottage_wood.png",Color("514b40"))
	var rope := ART.mat(Color("5d5848"),.99)
	# The bridge extends from one real bank to the other. All planks align
	# to the cross-stream x axis; staggered joins and uneven edges feel old.
	for k in range(18):
		var step: float = float(k)-8.5
		var xx: float = step*.71
		var width_z: float = 2.1+sin(float(k)*2.1)*.055
		var stagger: float = sin(float(k)*6.1)*.035
		ART.box(bridge,Vector3(xx,stagger,0),
			Vector3(.675,.135,width_z),timber,
			Vector3(0,sin(float(k)*1.6)*.016,0))
		if k%4==0:
			for railing in [-1.0,1.0]:
				var zpost: float = railing*1.13
				ART.bone(bridge,Vector3(xx,-.12,zpost),
					Vector3(xx,.91,zpost),.07,.065,darkwood,9)
				ART.cone(bridge,Vector3(xx,.94,zpost),
					.10,.14,darkwood,.034,8)
	# Continuous dark support beams under the planks and handrails over the
	# narrow crossing (rails stay low enough to keep the water visible).
	for sign in [-1.0,1.0]:
		var edge_z: float = sign*1.03
		ART.bone(bridge,Vector3(-6.5,-.23,edge_z),
			Vector3(6.5,-.23,edge_z),.105,.09,darkwood,9)
	# Sagging hand-tied rope spans the five support posts; a single batched
	# mesh replaces the two implausibly straight, bright crossing rails.
	var handrope := MeshInstance3D.new()
	handrope.name="TiedAndSaggingRopeHandrails"
	handrope.mesh=_bridge_handrope_mesh()
	handrope.material_override=rope
	bridge.add_child(handrope)
	world.add_solid_box(bridge,Vector3(0,-.13,0),
		Vector3(12.8,.32,2.20),"CrossableBridgeDeck")
	# Warm stone abutments partly embedded in the banks. Their size gives
	# visual weight without using a pair of cuboid concrete pillars.
	for sign in [-1.0,1.0]:
		var endpoint_x: float = x+sign*6.3
		var y: float = world.height_at(endpoint_x,z)
		for dz in [-.86,.85]:
			ART.stone(root,Vector3(endpoint_x,y+.04,z+dz),
				Vector3(.55,.22,.57),world.stone_mat)

static func _bridge_handrope_mesh() -> ArrayMesh:
	# Rope sags gently between upright supports, with enough polygon sections
	# to keep its thin silhouette intact from either bank.
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for sign in [-1.0,1.0]:
		for span in range(4):
			var ax: float = (float(span*4)-8.5)*.71
			var bx: float = (float((span+1)*4)-8.5)*.71
			for segment in range(9):
				var ta: float = float(segment)/9.0
				var tb: float = float(segment+1)/9.0
				var a := Vector3(lerpf(ax,bx,ta),
					.82-.13*sin(ta*PI),sign*1.13)
				var b := Vector3(lerpf(ax,bx,tb),
					.82-.13*sin(tb*PI),sign*1.13)
				var tangent: Vector3 = (b-a).normalized()
				var cross: Vector3 = tangent.cross(Vector3.UP).normalized()
				var upper: Vector3 = tangent.cross(cross).normalized()
				for side in range(7):
					var angle0: float = TAU*float(side)/7.0
					var angle1: float = TAU*float(side+1)/7.0
					var ra: Vector3 = cross*cos(angle0)*.025+upper*sin(angle0)*.025
					var rb: Vector3 = cross*cos(angle1)*.025+upper*sin(angle1)*.025
					for vertex in [a+ra,b+ra,a+rb,b+ra,b+rb,a+rb]:
						st.add_vertex(vertex)
	st.generate_normals()
	return st.commit()


static func _wildflower_mesh() -> ArrayMesh:
	# Each bloom is true 3D; five modest petals, 2 slender leaves and stem.
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for petal in range(5):
		var a: float = TAU*float(petal)/5.0
		var outward: Vector3 = Vector3(cos(a),.24,sin(a))
		var lateral: Vector3 = Vector3(-outward.z,0,outward.x)
		var center: Vector3 = Vector3(0,.29,0)
		var point: Vector3 = center+outward*.095
		for v in [center-lateral*.018,center+lateral*.018,point]:
			st.set_color(Color("d1c3aa").lerp(Color("a6a9b0"),float(petal)/7.0))
			st.add_vertex(v)
	# A slender, green triangular stem and two pointed leaves.
	for v in [Vector3(-.014,0,0),Vector3(.014,0,0),
		Vector3(0,.27,0)]:
		st.set_color(Color("637956"))
		st.add_vertex(v)
	for wing in [-1.0,1.0]:
		var a: Vector3 = Vector3(0,.085,0)
		var b: Vector3 = Vector3(wing*.11,.16,.023)
		var c: Vector3 = Vector3(0,.185,0)
		for v in [a,b,c]:
			st.set_color(Color("6c855f"))
			st.add_vertex(v)
	st.generate_normals()
	return st.commit()

static func _add_botanical_clusters(world: Node3D,root: Node3D) -> void:
	var meadow_mat := StandardMaterial3D.new()
	meadow_mat.vertex_color_use_as_albedo=true
	meadow_mat.roughness=1.0
	meadow_mat.cull_mode=BaseMaterial3D.CULL_DISABLED
	var mesh: ArrayMesh = _wildflower_mesh()
	var scatter := MultiMesh.new()
	scatter.transform_format=MultiMesh.TRANSFORM_3D
	scatter.use_colors=true
	scatter.mesh=mesh
	scatter.instance_count=420
	var rng := RandomNumberGenerator.new()
	rng.seed=778833
	var places: Array[Vector2] = [
		Vector2(-5.3,14.5),Vector2(9.3,22.0),
		Vector2(20.3,14.1),Vector2(35.0,14.0),
		Vector2(-12.0,16.0),Vector2(-12.0,-28.0)
	]
	for i in range(scatter.instance_count):
		var anchor: Vector2 = places[i%places.size()]
		var angle: float = rng.randf_range(0,TAU)
		var radius: float = sqrt(rng.randf())*rng.randf_range(.7,3.5)
		var x: float = anchor.x+cos(angle)*radius
		var z: float = anchor.y+sin(angle)*radius
		var t: float = rng.randf_range(.68,1.4)
		var yaw: float = rng.randf_range(0,TAU)
		var transform := Transform3D(Basis(Vector3.UP,yaw).scaled(Vector3.ONE*t),
			Vector3(x,world.height_at(x,z)+.024,z))
		scatter.set_instance_transform(i,transform)
		scatter.set_instance_color(i,Color("e2d6bc").lerp(Color("9aa5ba"),rng.randf_range(.0,.35)))
	var flowers := MultiMeshInstance3D.new()
	flowers.name="QuietMeadowFlowers"
	flowers.multimesh=scatter
	flowers.material_override=meadow_mat
	root.add_child(flowers)

static func _add_fallen_wood(world: Node3D,root: Node3D) -> void:
	# Not a random scatter: three long weathered logs frame the woodland
	# edges, two around the creek and one near the ruined wall.
	var timber: Material = world.textured(
		"res://assets/textures/cottage_wood.png",Color("6c6856"))
	var endgrain := ART.mat(Color("999078"),.96)
	for info in [
		{"p":Vector2(-12.4,13.4),"length":3.8,"yaw":.21},
		{"p":Vector2(-25.9,8.5),"length":4.5,"yaw":-.45},
		{"p":Vector2(14.0,-31.7),"length":4.3,"yaw":.8}
	]:
		var spot: Vector2 = info["p"]
		var length: float = info["length"]
		var yaw: float = info["yaw"]
		var tree := Node3D.new()
		tree.name = "WeatheredFallenOak"
		tree.position = Vector3(spot.x,world.height_at(spot.x,spot.y)+.19,spot.y)
		tree.rotation.y=yaw
		root.add_child(tree)
		ART.bone(tree,Vector3(-length*.5,0,0),Vector3(length*.5,0,0),
			.24,.20,timber,11)
		for sign in [-1.0,1.0]:
			ART.orb(tree,Vector3(sign*length*.5,0,0),
				Vector3(.025,.18,.18),endgrain,11)
		world.add_solid_box(tree,Vector3.ZERO,
			Vector3(length,.28,.44),"PhysicalFallenTimber")
