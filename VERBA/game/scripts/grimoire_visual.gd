extends RefCounted
## VERBA — the open grimoire as a physical, layered object.
## Source textures are bundled: no placeholder billboard, CanvasLayer or runtime web.
## Coordinates match the camera-held book's two ink-bearing Label3D surfaces.

const ART = preload("res://scripts/art.gd")

static func material(texture_path: String, tint: Color, rough: float, metallic: float = 0.0) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = tint
	result.roughness = rough
	result.metallic = metallic
	result.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var tex: Texture2D = load(texture_path)
	if tex != null:
		result.albedo_texture = tex
	return result

static func parchment_material() -> StandardMaterial3D:
	# The held volume faces away from the open-world sun. Real vellum still
	# has reflected, diffuse ambient light; without a soft lighting floor,
	# correct face normals render the study pages charcoal-black.
	var paper := material("res://assets/textures/authored/vellum_cream.png",Color("e8ddc7"),.98)
	paper.emission_enabled = true
	paper.emission = Color("d8b18d")
	paper.emission_energy_multiplier = .53
	paper.cull_mode = BaseMaterial3D.CULL_DISABLED
	return paper

static func make_open_binding() -> Node3D:
	var root := Node3D.new()
	root.name = "LayeredLeatherGrimoire"
	var cover: StandardMaterial3D = material("res://assets/textures/authored/oxblood_leather.png",Color("6d5045"),.82)
	var leather_edge: StandardMaterial3D = material("res://assets/textures/authored/oxblood_leather.png",Color("3a2523"),.93)
	var vellum: StandardMaterial3D = parchment_material()
	var page_edge: StandardMaterial3D = ART.mat(Color("948475"),1.0)
	var bronze: StandardMaterial3D = ART.mat(Color("75624b"),.83)
	bronze.metallic = .14
	var bronze_dark: StandardMaterial3D = ART.mat(Color("4e4439"),.90)
	bronze_dark.metallic = .12

	# Two modeled leather boards, with an actual gutter and rounded leather spine.
	# The boards protrude beyond the pages so they read as a binding from all angles.
	for side in [-1.0,1.0]:
		var x: float = side * .416
		ART.box(root,Vector3(x,.01,-.121),Vector3(.86,1.17,.092),cover)
		ART.box(root,Vector3(x,.01,-.177),Vector3(.84,1.14,.028),leather_edge)
		# Physical stack of leaves; edges and individual signatures are visible.
		ART.box(root,Vector3(side*.403,0,-.043),Vector3(.760,1.052,.071),page_edge)
		# Individual signatures rise continuously from the glued text block.
		# The old seven leaves stopped almost 3 cm below the top parchment:
		# visible gaps made the book resemble stacked disconnected plates.
		for folio in range(11):
			var depth: float = -.017 + float(folio)*.005
			ART.box(root,Vector3(side*.400,-.003,depth),Vector3(.750,1.037,.0034),
				ART.mat(Color("c5af8e").lerp(Color("91826c"),float(folio)/12.0),1.0))
		# Leather turn-ins along the outside and long edges.
		ART.box(root,Vector3(side*.850,.018,-.104),Vector3(.031,1.17,.11),leather_edge)
		for yy in [-.564,.581]:
			ART.box(root,Vector3(x,yy,-.118),Vector3(.84,.029,.13),leather_edge)

		# Eight restrained brass corner guards and small punched rivets.
		for yy in [-.546,.559]:
			ART.box(root,Vector3(side*.782,yy,-.011),Vector3(.076,.046,.026),bronze)
			ART.box(root,Vector3(side*.810,yy-signf(yy)*.045,-.008),Vector3(.037,.094,.022),bronze)
			ART.orb(root,Vector3(side*.779,yy,-.001),Vector3(.014,.014,.011),bronze_dark,8)

		# Real curved vellum. The crease is lower, outer edge curls slightly up.
		_add_curved_leaf(root,side,vellum)
		# Fine ruling along outside margin: subtle visible page ornament.
		ART.box(root,Vector3(side*.704,0,.046),Vector3(.007,.87,.0026),bronze_dark)
		for yy in [-.472,.484]:
			ART.box(root,Vector3(side*.399,yy,.044),Vector3(.44,.0035,.002),bronze_dark)

	# A distinct binding spine, with stitched threads and raised ribs.
	ART.bone(root,Vector3(0,-.578,-.132),Vector3(0,.592,-.132),
		.104,.104,leather_edge,12)
	for yy in [-.49,-.26,0,.26,.50]:
		ART.box(root,Vector3(0,yy,-.022),Vector3(.085,.020,.043),bronze)
	for stitch in range(19):
		var y: float = -.46 + float(stitch)*.051
		ART.box(root,Vector3(0,y,.011),Vector3(.018,.018,.014),bronze_dark)
	ART.box(root,Vector3(0,.010,.018),Vector3(.032,.94,.030),leather_edge)
	# A hand-stitched fabric hinge occupies the actual page gutter; without
	# it the first-person camera showed an implausible black screen-sized slit.
	var linen: StandardMaterial3D = ART.mat(Color("554b44"),.98)
	ART.box(root,Vector3(0,.002,.039),Vector3(.024,.992,.009),linen)
	# The book is SUPPORTED by two leather-gloved hands and worn sleeves.
	# Before this pass it floated unsupported in the middle of the camera.
	var sleeve: StandardMaterial3D = ART.mat(Color("2e3431"),.97)
	var glove: StandardMaterial3D = ART.mat(Color("4d443b"),.93)
	var cuff: StandardMaterial3D = ART.mat(Color("383a35"),.96)
	for side in [-1.0,1.0]:
		var grip: float = side*.67
		ART.bone(root,Vector3(grip+side*.085,-1.03,.25),
			Vector3(grip,-.675,.12),.112,.095,sleeve,10)
		ART.bone(root,Vector3(grip,-.69,.12),
			Vector3(grip,-.61,.12),.113,.099,cuff,12)
		ART.orb(root,Vector3(grip,-.562,.102),
			Vector3(.107,.104,.077),glove,12)
		# Finger ends curl around the lower leather cover and never obscure
		# central Latin text. Slight spacing stops the hand looking mitten-flat.
		for finger in range(3):
			var xx: float = grip+side*(float(finger)-1.0)*.040
			ART.bone(root,Vector3(xx,-.54,.135),
				Vector3(xx-side*.012,-.469,.096),.023,.018,glove,8)
		ART.bone(root,Vector3(grip-side*.10,-.62,.115),
			Vector3(grip-side*.15,-.56,.143),.039,.028,glove,8)
	return root

static func make_turning_leaf() -> Node3D:
	# A physical sheet hinged at the center gutter. The player can see
	# its parchment face move in 3D rather than watching a page-number snap.
	var hinge := Node3D.new()
	hinge.name = "PageTurnHinge"
	# The hinge is at the same physical height as the raised paper block,
	# rather than hovering 6 cm above it. The leaf itself is tessellated,
	# gently bowed parchment (never a flat rectangular QuadMesh).
	hinge.position = Vector3(0,0,.046)
	var leaf := MeshInstance3D.new()
	leaf.name = "PageTurningVellumSheet"
	leaf.mesh = _build_turning_leaf_mesh()
	var vellum := parchment_material()
	leaf.material_override = vellum
	hinge.add_child(leaf)
	hinge.visible = false
	return hinge

static func _add_curved_leaf(root: Node3D, side: float, paper: StandardMaterial3D) -> void:
	var mesh_tool := SurfaceTool.new()
	mesh_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var segments_x: int = 18
	var segments_y: int = 12
	for ix in range(segments_x):
		for iy in range(segments_y):
			var u0: float = float(ix)/float(segments_x)
			var u1: float = float(ix+1)/float(segments_x)
			var v0: float = float(iy)/float(segments_y)
			var v1: float = float(iy+1)/float(segments_y)
			var a: Vector3 = _page_vertex(side,u0,v0)
			var b: Vector3 = _page_vertex(side,u1,v0)
			var c: Vector3 = _page_vertex(side,u0,v1)
			var d: Vector3 = _page_vertex(side,u1,v1)
			# Keep winding correct for both sides and avoid flipping normals
			# by enabling two-sided parchment on thin physical sheets.
			var triangles: Array = [
				[a,Vector2(u0,v0)],[b,Vector2(u1,v0)],[c,Vector2(u0,v1)],
				[b,Vector2(u1,v0)],[d,Vector2(u1,v1)],[c,Vector2(u0,v1)]
			]
			# Keep normal orientation identical on both wings of the book.
			# Reversed winding on the left previously produced mismatched shading.
			if side < 0.0:
				triangles = [
					[a,Vector2(u0,v0)],[c,Vector2(u0,v1)],[b,Vector2(u1,v0)],
					[b,Vector2(u1,v0)],[c,Vector2(u0,v1)],[d,Vector2(u1,v1)]
				]
			for item in triangles:
				mesh_tool.set_uv(item[1])
				mesh_tool.add_vertex(item[0])
	mesh_tool.generate_normals(true)
	var parchment := MeshInstance3D.new()
	parchment.name = "SlightlyCurledVellumLeft" if side < 0.0 else "SlightlyCurledVellumRight"
	parchment.mesh = mesh_tool.commit()
	var used: StandardMaterial3D = paper.duplicate() as StandardMaterial3D
	used.cull_mode = BaseMaterial3D.CULL_DISABLED
	parchment.material_override = used
	root.add_child(parchment)

static func _page_vertex(side: float, u: float, v: float) -> Vector3:
	var edge: float = .028 + u*.755
	var x: float = side*edge
	var y: float = -.513 + v*1.035
	# The ink is a 3D surface at z=.046, not a screen overlay.
	# Keep paper within a few millimetres of it: the previous 5.7 cm
	# crown-to-gutter variation buried letters at the free page edges.
	var z: float = .037 + .006*u*u + .0015*sin(v*PI)*sin(u*PI)
	z += .001*pow(u,8.0)*pow(absf(v-.5)*2.0,5.0)
	return Vector3(x,y,z)


static func _build_turning_leaf_mesh() -> ArrayMesh:
	# A shallow curved, double-faced physical sheet with a continuous page
	# silhouette. Both sides have proper normals, so oblique light catches
	# the leaf during a turn instead of revealing a completely flat quad.
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var columns: int = 18
	var rows: int = 12
	for i in range(columns):
		for j in range(rows):
			var u0 := float(i)/float(columns)
			var u1 := float(i+1)/float(columns)
			var v0 := float(j)/float(rows)
			var v1 := float(j+1)/float(rows)
			for face in [1.0,-1.0]:
				var a := _turn_vertex(u0,v0,face)
				var b := _turn_vertex(u1,v0,face)
				var c := _turn_vertex(u0,v1,face)
				var d := _turn_vertex(u1,v1,face)
				if face > 0.0:
					_sheet_tri(st,a,b,c,Vector2(u0,v0),Vector2(u1,v0),Vector2(u0,v1))
					_sheet_tri(st,b,d,c,Vector2(u1,v0),Vector2(u1,v1),Vector2(u0,v1))
				else:
					_sheet_tri(st,a,c,b,Vector2(u0,v0),Vector2(u0,v1),Vector2(u1,v0))
					_sheet_tri(st,b,c,d,Vector2(u1,v0),Vector2(u0,v1),Vector2(u1,v1))
	# Turned paper edges must read as paper, not a zero-thickness plane.
	for i in range(columns):
		var u0 := float(i)/float(columns)
		var u1 := float(i+1)/float(columns)
		for v in [0.0,1.0]:
			_sheet_edge(st,_turn_vertex(u0,v,1.0),_turn_vertex(u1,v,1.0),
				_turn_vertex(u0,v,-1.0),_turn_vertex(u1,v,-1.0))
	for j in range(rows):
		var v0 := float(j)/float(rows)
		var v1 := float(j+1)/float(rows)
		for u in [0.0,1.0]:
			_sheet_edge(st,_turn_vertex(u,v0,1.0),_turn_vertex(u,v1,1.0),
				_turn_vertex(u,v0,-1.0),_turn_vertex(u,v1,-1.0))
	st.generate_normals(true)
	return st.commit()


static func _turn_vertex(u: float, v: float, face: float) -> Vector3:
	var x: float = .028 + .755*u
	var y: float = -.513 + 1.035*v
	var z: float = .003 + .004*u*u + .0015*sin(u*PI)*sin(v*PI)
	return Vector3(x,y,z+face*.00075)


static func _sheet_tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3,
		uv_a: Vector2, uv_b: Vector2, uv_c: Vector2) -> void:
	for pair in [[a,uv_a],[b,uv_b],[c,uv_c]]:
		st.set_uv(pair[1])
		st.add_vertex(pair[0])


static func _sheet_edge(st: SurfaceTool,
		front_a: Vector3, front_b: Vector3, back_a: Vector3, back_b: Vector3) -> void:
	_sheet_tri(st,front_a,front_b,back_a,Vector2.ZERO,Vector2.RIGHT,Vector2.DOWN)
	_sheet_tri(st,front_b,back_b,back_a,Vector2.RIGHT,Vector2.ONE,Vector2.DOWN)
