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

static func _quad(st: SurfaceTool, a: Vector3,b: Vector3,c: Vector3,d: Vector3,
		u0: float,u1: float,v0: float,v1: float) -> void:
	for p in [
		[a,Vector2(u0,v0)],[b,Vector2(u1,v0)],[c,Vector2(u1,v1)],
		[a,Vector2(u0,v0)],[c,Vector2(u1,v1)],[d,Vector2(u0,v1)]
	]:
		st.set_uv(p[1])
		st.add_vertex(p[0])
