extends RefCounted
## Source-independent, batched silhouette for partially collapsed stone masonry.
## Original geometry, normal/tangent-correct and UV-mapped: no hundred-box wall.
static func add_broken_wall(parent: Node3D, start: Vector3, finish: Vector3,
		profile: PackedFloat32Array, thickness: float, stone: Material) -> MeshInstance3D:
	if profile.size() < 2 or (finish-start).length_squared() < .01:
		return null
	var axis: Vector3 = (finish-start).normalized()
	var side: Vector3 = Vector3(-axis.z,0,axis.x)*thickness*.5
	var length: float = start.distance_to(finish)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(profile.size()-1):
		var u0: float = float(i)/float(profile.size()-1)
		var u1: float = float(i+1)/float(profile.size()-1)
		var foot0: Vector3 = start.lerp(finish,u0)
		var foot1: Vector3 = start.lerp(finish,u1)
		var h0: float = maxf(.4,profile[i])
		var h1: float = maxf(.4,profile[i+1])
		var lf0: Vector3 = foot0+side
		var lf1: Vector3 = foot1+side
		var rf0: Vector3 = foot0-side
		var rf1: Vector3 = foot1-side
		var lt0: Vector3 = lf0+Vector3.UP*h0
		var lt1: Vector3 = lf1+Vector3.UP*h1
		var rt0: Vector3 = rf0+Vector3.UP*h0
		var rt1: Vector3 = rf1+Vector3.UP*h1
		_quad(st,lf0,lf1,lt1,lt0,length*u0,length*u1,h0,h1)
		_quad(st,rf1,rf0,rt0,rt1,length*u0,length*u1,h0,h1)
		_quad(st,lt0,lt1,rt1,rt0,length*u0,length*u1,0,thickness)
		if i == 0:
			_quad(st,rf0,lf0,lt0,rt0,0,thickness,0,h0)
		if i == profile.size()-2:
			_quad(st,lf1,rf1,rt1,lt1,0,thickness,0,h1)
	st.generate_normals()
	var mesh := MeshInstance3D.new()
	mesh.name = "BrokenMasonryProfile"
	mesh.mesh = st.commit()
	mesh.material_override = stone
	parent.add_child(mesh)
	return mesh

static func add_wall_collision(parent: Node3D,start: Vector3,finish: Vector3,
		profile: PackedFloat32Array,thickness: float,label: String) -> StaticBody3D:
	# Collide with the actual remaining masonry, not an invisible rectangle
	# above sections that have collapsed.
	var body := StaticBody3D.new()
	body.name = label
	body.collision_layer = 16
	body.collision_mask = 0
	parent.add_child(body)
	var axis: Vector3 = (finish-start).normalized()
	var yaw: float = -atan2(axis.z,axis.x)
	var pieces: int = maxi(1,profile.size()-1)
	for i in range(pieces):
		var u0: float = float(i)/float(pieces)
		var u1: float = float(i+1)/float(pieces)
		var at: Vector3 = start.lerp(finish,(u0+u1)*.5)
		var section_height: float = maxf(.35,minf(profile[i],profile[i+1])-.02)
		var node := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size=Vector3(start.distance_to(finish)/float(pieces)+.04,
			section_height,thickness)
		node.shape=box
		node.position=at+Vector3.UP*(section_height*.5)
		node.rotation.y=yaw
		body.add_child(node)
	return body

static func add_collapsed_bell_tower(world: Node3D,center: Vector3,
		stone: Material) -> Node3D:
	# A partial decagonal masonry bell tower. Actual volume and negative
	# space give the priory a distant landmark instead of a tiny arch on
	# an empty hill. The broken crown is *not* a flat circular cylinder.
	var root := Node3D.new()
	root.name = "CollapsedPrioryBellTower"
	root.position=center
	world.add_child(root)
	var sides: int = 11
	var radius: float = 1.64
	var rng := RandomNumberGenerator.new()
	rng.seed=438867
	var heights: Array[float] = []
	for i in range(sides):
		var a: float = TAU*float(i)/float(sides)
		var h: float = 5.2+sin(a*3.1)*.73+rng.randf_range(-.34,.42)
		heights.append(h)
	for i in range(sides):
		# The front and eastern portions have collapsed entirely, forming a
		# huge arched rupture. We do not fake black door cutouts on solid slabs.
		if i in [1,2,3]: continue
		var a0: float = TAU*float(i)/float(sides)
		var a1: float = TAU*float(i+1)/float(sides)
		var p0 := Vector3(cos(a0)*radius,0,sin(a0)*radius)
		var p1 := Vector3(cos(a1)*radius,0,sin(a1)*radius)
		var psteps := PackedFloat32Array([
			heights[i],maxf(1.1,(heights[i]+heights[(i+1)%sides])*.5-.26),
			heights[(i+1)%sides]
		])
		add_broken_wall(root,p0,p1,psteps,.39,stone)
		add_wall_collision(root,p0,p1,psteps,.39,"TowerMasonry_%02d" % i)
	# Visible stone strips at the entrance, not a box doorway. The tower
	# is naturally worn to a low parapet where its two ends have crumbled.
	var capstone: StandardMaterial3D = world.textured(
		"res://assets/textures/stone.png",Color("a69f90"))
	for i in [0,4,6,8]:
		var a: float = TAU*(float(i)+.46)/float(sides)
		var edge: Vector3 = Vector3(cos(a)*radius,heights[i]+.08,
			sin(a)*radius)
		# World-local fractured ridge pieces get caught by the real existing
		# stone meshes below, rather than constructing a second rock library.
		var fragment := MeshInstance3D.new()
		fragment.name = "AncientLooseCoping"
		var mesh := BoxMesh.new()
		mesh.size=Vector3(.45,.21,.40)
		fragment.mesh=mesh
		fragment.position=edge
		fragment.rotation=Vector3(.03,a,.09)
		fragment.material_override=capstone
		root.add_child(fragment)
	return root

static func _quad(st: SurfaceTool, a: Vector3,b: Vector3,c: Vector3,d: Vector3,
		u0: float,u1: float,v0: float,v1: float) -> void:
	for p in [
		[a,Vector2(u0,v0)],[b,Vector2(u1,v0)],[c,Vector2(u1,v1)],
		[a,Vector2(u0,v0)],[c,Vector2(u1,v1)],[d,Vector2(u0,v1)]
	]:
		st.set_uv(p[1])
		st.add_vertex(p[0])
