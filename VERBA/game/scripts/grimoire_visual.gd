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

static func make_open_binding() -> Node3D:
	var root := Node3D.new()
	root.name = "LayeredLeatherGrimoire"
	var cover: StandardMaterial3D = material("res://assets/textures/authored/oxblood_leather.png",Color("6d5045"),.82)
	var leather_edge: StandardMaterial3D = material("res://assets/textures/authored/oxblood_leather.png",Color("3a2523"),.93)
	var vellum: StandardMaterial3D = material("res://assets/textures/authored/aged_vellum.png",Color("c5ae8e"),.95)
	var page_edge: StandardMaterial3D = ART.mat(Color("98846e"),1.0)
	var bronze: StandardMaterial3D = ART.mat(Color("a68b59"),.34)
	bronze.metallic = .63
	var bronze_dark: StandardMaterial3D = ART.mat(Color("654c35"),.52)
	bronze_dark.metallic = .49

	# Two modeled leather boards, with an actual gutter and rounded leather spine.
	# The boards protrude beyond the pages so they read as a binding from all angles.
	for side in [-1.0,1.0]:
		var x: float = side * .416
		ART.box(root,Vector3(x,.01,-.121),Vector3(.86,1.17,.092),cover)
		ART.box(root,Vector3(x,.01,-.177),Vector3(.84,1.14,.028),leather_edge)
		# Physical stack of leaves; edges and individual signatures are visible.
		ART.box(root,Vector3(side*.403,0,-.043),Vector3(.760,1.052,.071),page_edge)
		for folio in range(7):
			var depth: float = -.020 + float(folio)*.004
			ART.box(root,Vector3(side*.400,-.003,depth),Vector3(.750,1.037,.0034),
				ART.mat(Color("c5af8e").lerp(Color("91826c"),float(folio)/12.0),1.0))
		# Leather turn-ins along the outside and long edges.
		ART.box(root,Vector3(side*.850,.018,-.104),Vector3(.031,1.17,.11),leather_edge)
		for yy in [-.564,.581]:
			ART.box(root,Vector3(x,yy,-.118),Vector3(.84,.029,.13),leather_edge)

		# Eight restrained brass corner guards and small punched rivets.
		for yy in [-.546,.559]:
			ART.box(root,Vector3(side*.782,yy,-.011),Vector3(.13,.077,.032),bronze)
			ART.box(root,Vector3(side*.818,yy-signf(yy)*.074,-.008),Vector3(.055,.17,.028),bronze)
			ART.orb(root,Vector3(side*.779,yy,-.001),Vector3(.014,.014,.011),bronze_dark,8)

		# Real curved vellum. The crease is lower, outer edge curls slightly up.
		_add_curved_leaf(root,side,vellum)
		# Fine ruling along outside margin: subtle visible page ornament.
		ART.box(root,Vector3(side*.704,0,.088),Vector3(.007,.87,.0026),bronze_dark)
		for yy in [-.472,.484]:
			ART.box(root,Vector3(side*.399,yy,.091),Vector3(.55,.006,.003),bronze)

	# A distinct binding spine, with stitched threads and raised ribs.
	ART.bone(root,Vector3(0,-.578,-.132),Vector3(0,.592,-.132),
		.104,.104,leather_edge,12)
	for yy in [-.49,-.26,0,.26,.50]:
		ART.box(root,Vector3(0,yy,-.022),Vector3(.085,.020,.043),bronze)
	for stitch in range(19):
		var y: float = -.46 + float(stitch)*.051
		ART.box(root,Vector3(0,y,.011),Vector3(.018,.018,.014),bronze_dark)
	ART.box(root,Vector3(0,.010,.018),Vector3(.032,.94,.030),leather_edge)
	return root

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
			for item in [
				[a,Vector2(u0,v0)],[b,Vector2(u1,v0)],[c,Vector2(u0,v1)],
				[b,Vector2(u1,v0)],[d,Vector2(u1,v1)],[c,Vector2(u0,v1)]
			]:
				mesh_tool.set_uv(item[1])
				mesh_tool.add_vertex(item[0])
	mesh_tool.generate_normals()
	var parchment := MeshInstance3D.new()
	parchment.name = "SlightlyCurledVellum"
	parchment.mesh = mesh_tool.commit()
	var used: StandardMaterial3D = paper.duplicate() as StandardMaterial3D
	used.cull_mode = BaseMaterial3D.CULL_DISABLED
	parchment.material_override = used
	root.add_child(parchment)

static func _page_vertex(side: float, u: float, v: float) -> Vector3:
	var edge: float = .042 + u*.745
	var x: float = side*edge
	var y: float = -.513 + v*1.035
	# Low in the gutter, high at the free edge, softly dog-eared corners.
	var z: float = -.013 + .078*u*u + .011*sin(v*PI)*sin(u*PI)
	z += .009*pow(u,8.0)*pow(absf(v-.5)*2.0,5.0)
	return Vector3(x,y,z)
