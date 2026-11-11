extends RefCounted
## Tailored, single-mesh hands for the held grimoire.
## Four articulated digits, opposed thumb, tapered palm and stitched glove cuff.
## No rig dependency: these are first-person rest-pose grips, not full character hands.
const ART = preload("res://scripts/art.gd")

static func add_book_hands(root: Node3D) -> void:
	var sleeve := ART.mat(Color("303633"),.98)
	var cuff := ART.mat(Color("353631"),.98)
	var seam := ART.mat(Color("756c5d"),.99)
	for sign in [-1.0,1.0]:
		var grip: float = sign*.67
		var arm := Node3D.new()
		arm.name = "LeftHandOnBinding" if sign < 0.0 else "RightHandOnBinding"
		arm.position = Vector3(grip,0,0)
		root.add_child(arm)
		# Forearms point back toward the viewer. The slim cuff conceals the
		# forearm-to-palm seam; the palm itself is no longer an orb.
		ART.bone(arm,Vector3(sign*.080,-1.03,.247),
			Vector3(0,-.680,.155),.099,.084,sleeve,9)
		ART.bone(arm,Vector3(0,-.709,.150),
			Vector3(0,-.633,.150),.105,.098,cuff,10)
		var grip_mesh := MeshInstance3D.new()
		grip_mesh.name = "SculptedLeatherPalmAndFingers"
		grip_mesh.mesh = make_grip_mesh(sign)
		var leather := ART.mat(Color("54483d"),.96)
		leather.vertex_color_use_as_albedo = true
		leather.cull_mode = BaseMaterial3D.CULL_DISABLED
		grip_mesh.material_override = leather
		arm.add_child(grip_mesh)
		# Subtle diagonal cuff seam, not three disconnected floating rods.
		for i in range(4):
			var x: float = (float(i)-1.5)*.042
			ART.bone(arm,Vector3(x,-.678,.241),
				Vector3(x+sign*.008,-.661,.242),.004,.003,seam,6)

static func make_grip_mesh(sign: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Hand-shaped mass: narrow at wrist, broad at the knuckles. Slight
	# oblique wrist angle prevents a mirror-symmetric mitten silhouette.
	var palm: Array[Vector3] = [
		Vector3(sign*.018,-.684,.148),
		Vector3(0,-.641,.149),
		Vector3(-sign*.012,-.588,.141),
		Vector3(-sign*.018,-.531,.132)
	]
	_tapered_tube(st,palm,[.074,.098,.116,.092],.76,Color("aba094"))
	# Real finger arcs, with a downward-facing hook toward the lower cover.
	# Fingertips stop above the writing area at the outer bottom margin.
	for finger in range(4):
		var lane: float = (float(finger)-1.5)*.046
		var knuckle: Vector3 = Vector3(lane-sign*.010,-.543,.147)
		var middle: Vector3 = Vector3(lane-sign*.015,
			-.501 + absf(lane)*.085,.135)
		var end: Vector3 = Vector3(lane-sign*.025,
			-.478+absf(lane)*.10,.102)
		var tip: Vector3 = Vector3(lane-sign*.027,
			-.493+absf(lane)*.10,.069)
		_tapered_tube(st,[knuckle,middle,end,tip],
			[.024,.021,.017,.012],1.0,
			Color("b9aa99").lerp(Color("8b7f70"),float(finger)*.075))
	# The thumb opposes the other digits and wraps around the fore edge.
	var inside: float = -sign
	_tapered_tube(st,[
		Vector3(inside*.078,-.604,.156),
		Vector3(inside*.132,-.576,.166),
		Vector3(inside*.163,-.551,.134),
		Vector3(inside*.159,-.549,.095)
	],[.039,.034,.027,.017],1.0,Color("b1a291"))
	st.generate_normals()
	return st.commit()

static func _tapered_tube(st: SurfaceTool,centers: Array[Vector3],
		radii: Array, depth_scale: float, shade: Color) -> void:
	var rings: Array = []
	var sides: int = 10
	for i in range(centers.size()):
		var tangent: Vector3
		if i == 0:
			tangent = (centers[i+1]-centers[i]).normalized()
		elif i == centers.size()-1:
			tangent = (centers[i]-centers[i-1]).normalized()
		else:
			tangent = (centers[i+1]-centers[i-1]).normalized()
		var axis: Vector3 = tangent.cross(Vector3.FORWARD).normalized()
		if axis.length_squared() < .01:
			axis = Vector3.RIGHT
		var binormal: Vector3 = tangent.cross(axis).normalized()
		var ring: Array[Vector3] = []
		for j in range(sides):
			var theta: float = TAU*float(j)/float(sides)
			ring.append(centers[i] + axis*cos(theta)*float(radii[i]) +
				binormal*sin(theta)*float(radii[i])*depth_scale)
		rings.append(ring)
	for i in range(rings.size()-1):
		for j in range(sides):
			var k: int = (j+1)%sides
			var color: Color = shade.lerp(Color("7c7166"),float(j)/float(sides)*.12)
			_tri(st,rings[i][j],rings[i+1][j],rings[i][k],color)
			_tri(st,rings[i+1][j],rings[i+1][k],rings[i][k],color)
	for j in range(1,sides-1):
		_tri(st,centers[0],rings[0][j+1],rings[0][j],shade)
		var last: int = rings.size()-1
		_tri(st,centers[last],rings[last][j],rings[last][j+1],shade)

static func _tri(st: SurfaceTool,a: Vector3,b: Vector3,c: Vector3,tint: Color) -> void:
	for vertex in [a,b,c]:
		st.set_color(tint)
		st.add_vertex(vertex)
