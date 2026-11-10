extends RefCounted
## Small reusable geometry workshop. No external runtime services.

static func mat(color: Color, rough: float = 0.92, emission: Color = Color.BLACK) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = rough
	if emission != Color.BLACK:
		m.emission_enabled = true
		m.emission = emission
		m.emission_energy_multiplier = 1.4
	return m

static func box(parent: Node3D, at: Vector3, size: Vector3, m: Material, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	node.mesh = mesh
	node.material_override = m
	node.position = at
	node.rotation = rot
	parent.add_child(node)
	return node

static func orb(parent: Node3D, at: Vector3, scale3: Vector3, m: Material, segments: int = 12) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radial_segments = segments
	mesh.rings = maxi(6, int(segments / 2))
	node.mesh = mesh
	node.material_override = m
	node.position = at
	node.scale = scale3
	parent.add_child(node)
	return node

static func cone(parent: Node3D, at: Vector3, radius: float, length: float, m: Material, top_radius: float = 0.0, sides: int = 8) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = top_radius
	mesh.bottom_radius = radius
	mesh.height = length
	mesh.radial_segments = sides
	node.mesh = mesh
	node.material_override = m
	node.position = at
	parent.add_child(node)
	return node

static func bone(parent: Node3D, p1: Vector3, p2: Vector3, r1: float, r2: float, m: Material, sides: int = 9) -> MeshInstance3D:
	var axis := p2 - p1
	var node := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.bottom_radius = r1
	mesh.top_radius = r2
	mesh.height = axis.length()
	mesh.radial_segments = sides
	node.mesh = mesh
	node.material_override = m
	node.position = (p1 + p2) * 0.5
	if axis.length_squared() > 0.00001:
		node.quaternion = Quaternion(Vector3.UP, axis.normalized())
	parent.add_child(node)
	return node

static func capsule_collision(parent: CollisionObject3D, radius: float, height: float) -> CollisionShape3D:
	var c := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = radius
	shape.height = height
	c.shape = shape
	parent.add_child(c)
	return c

static func stone(parent: Node3D, at: Vector3, scale3: Vector3, m: Material) -> void:
	# Irregular six-to-twelve-sided hand-cut rock, with plane changes and a flat ground footprint.
	# No sphere primitives: this silhouette holds up in first-person close inspection.
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var sides := 11
	var seed := absf(at.x*17.1 + at.z*9.21)
	var bottom: Array[Vector3] = []
	var middle: Array[Vector3] = []
	var top: Array[Vector3] = []
	for i in range(sides):
		var t := TAU*float(i)/float(sides)
		var r := .79+.18*sin(float(i)*3.37+seed)+.12*cos(float(i)*7.71+seed*.3)
		bottom.append(Vector3(cos(t)*r,-.36,sin(t)*r))
		middle.append(Vector3(cos(t)*r*1.11,.05+.08*sin(float(i)*2.14+seed),sin(t)*r*1.06))
		top.append(Vector3(cos(t)*r*.62,.48+.12*cos(float(i)*4.11+seed),sin(t)*r*.62))
	for i in range(sides):
		var j := (i+1)%sides
		for tri in [[bottom[i],bottom[j],middle[i]],[middle[i],bottom[j],middle[j]],[middle[i],middle[j],top[i]],[top[i],middle[j],top[j]],[top[i],top[j],Vector3(0,.58,0)]]:
			for v in tri:
				st.set_uv(Vector2(v.x*.45+.5,v.z*.45+.5))
				st.add_vertex(v)
	st.generate_normals()
	var n:=MeshInstance3D.new()
	n.name="AngularWeatheredStone"
	n.mesh=st.commit()
	n.material_override=m
	n.position=at
	n.scale=scale3
	n.rotation=Vector3(.035,seed*.6,.025)
	parent.add_child(n)

static func arch(parent: Node3D, center: Vector3, width: float, height: float, m: Material) -> void:
	box(parent, center + Vector3(-width * 0.5, height * 0.5, 0), Vector3(0.63, height, 0.8), m)
	box(parent, center + Vector3(width * 0.5, height * 0.5, 0), Vector3(0.63, height, 0.8), m)
	for i in range(9):
		var t: float = PI - float(i) * PI / 8.0
		var p := center + Vector3(cos(t) * width * 0.5, height + sin(t) * width * 0.5, 0)
		box(parent, p, Vector3(0.68, 0.46, 0.92), m, Vector3(0, 0, t + PI * 0.5))


# Silhouette-led carved stone: no featureless rectangular tombstone slab.
# The insets leave a deliberately flat central face for readable, genuinely
# world-space Latin. Chamfer and chipped outline model a cut and weathered rock.
static func chiseled_tablet(parent: Node3D, position: Vector3,
		size: Vector3, stone_material: Material) -> MeshInstance3D:
	var outline: Array[Vector2] = [
		Vector2(-.82,.015),Vector2(-.23,-.015),Vector2(.57,.02),
		Vector2(.87,.14),Vector2(.84,.57),Vector2(.91,.81),
		Vector2(.59,.985),Vector2(.22,1.025),Vector2(-.48,1.01),
		Vector2(-.86,.86),Vector2(-.82,.42)
	]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var center_front := Vector3(0.0,size.y*.52,size.z*.5)
	var center_back := Vector3(0.0,size.y*.52,-size.z*.5)
	var count: int = outline.size()
	for i in range(count):
		var j: int = (i+1)%count
		var front_a := Vector3(outline[i].x*size.x*.43,
			(.5+(outline[i].y-.5)*.89)*size.y,size.z*.5)
		var front_b := Vector3(outline[j].x*size.x*.43,
			(.5+(outline[j].y-.5)*.89)*size.y,size.z*.5)
		var edge_a := Vector3(outline[i].x*size.x*.5,
			outline[i].y*size.y,size.z*.26)
		var edge_b := Vector3(outline[j].x*size.x*.5,
			outline[j].y*size.y,size.z*.26)
		var rear_a := Vector3(edge_a.x,edge_a.y,-size.z*.5)
		var rear_b := Vector3(edge_b.x,edge_b.y,-size.z*.5)
		_art_triangle(st,center_front,front_a,front_b)
		_art_triangle(st,front_a,edge_a,edge_b)
		_art_triangle(st,front_a,edge_b,front_b)
		_art_triangle(st,edge_a,rear_a,rear_b)
		_art_triangle(st,edge_a,rear_b,edge_b)
		_art_triangle(st,center_back,rear_b,rear_a)
	st.generate_normals()
	var mesh := MeshInstance3D.new()
	mesh.name = "ChippedWeatheredTablet"
	mesh.mesh = st.commit()
	mesh.material_override = stone_material
	mesh.position = position - Vector3(0,size.y*.5,0)
	parent.add_child(mesh)
	return mesh

static func _art_triangle(st: SurfaceTool, a: Vector3,b: Vector3,c: Vector3) -> void:
	for vertex in [a,b,c]:
		st.set_uv(Vector2(vertex.x*.72,vertex.y*.55))
		st.add_vertex(vertex)
