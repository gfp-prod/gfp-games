extends RefCounted
## Authored, deterministic cottage finishing details.  No new collision and no
## random clutter: roof craft, believable window horticulture, and a shaped
## threshold improve the landmark from the player's two approach cameras.
const ART = preload("res://scripts/art.gd")

static func decorate(cabin: Node3D) -> void:
	var root := Node3D.new()
	root.name = "CottageCraftAndWeathering"
	cabin.add_child(root)
	var aged_oak := _surface("res://assets/textures/real/cottage_wood_diffuse.jpg",Color("9b8a73"))
	var dark_oak := ART.mat(Color("51453d"),.96)
	var oxidized := ART.mat(Color("776950"),.87)
	var mortar := ART.mat(Color("77746a"),.98)
	# The mesh is one batch, not hundreds of separate roof tile nodes.
	var roof := MeshInstance3D.new()
	roof.name = "HandLaidIrregularSlateRoof"
	roof.mesh = make_roof_shingles()
	var slate := _surface("res://assets/textures/real/cottage_roof_diffuse.jpg",Color("b8afa1"))
	slate.vertex_color_use_as_albedo = true
	slate.cull_mode = BaseMaterial3D.CULL_DISABLED
	roof.material_override = slate
	root.add_child(roof)
	# Strong ridge/eave silhouette.  Small uneven timber elements read better
	# up close than another bright rectangular trim border.
	ART.bone(root,Vector3(-.03,5.48,-2.98),Vector3(-.03,5.48,3.05),
		.085,.077,dark_oak,8)
	for side in [-1.0,1.0]:
		ART.bone(root,Vector3(0,5.47,3.07),Vector3(side*3.19,3.64,3.07),
			.095,.075,aged_oak,9)
		ART.bone(root,Vector3(side*3.22,3.64,-3.00),
			Vector3(side*3.22,3.64,3.05),.095,.085,aged_oak,8)
	# A narrow step of hand-dressed fieldstone anchors the building to the
	# ground, while leaving the actual front entrance unobstructed.
	for i in range(8):
		var x: float = -2.78+float(i)*.79
		if x > -1.65 and x < .33:
			continue
		var width: float = .48 + .08*sin(float(i)*2.11)
		ART.stone(root,Vector3(x,.13,2.89),
			Vector3(width,.14,.20),mortar)
	# The low front sill is built from layered wood, not a white glowing box.
	ART.box(root,Vector3(1.56,1.11,2.91),Vector3(1.36,.09,.19),aged_oak)
	ART.box(root,Vector3(1.56,1.05,3.02),Vector3(1.24,.18,.22),dark_oak)
	# Herb planter sits directly below the window; twining shoots reach its
	# timber surround without covering the pane or the entrance.
	var planter := Node3D.new()
	planter.name = "LivingWindowHerbs"
	planter.position = Vector3(1.56,1.10,3.04)
	root.add_child(planter)
	ART.box(planter,Vector3(0,0,.01),Vector3(1.25,.20,.31),aged_oak)
	ART.box(planter,Vector3(0,.095,.01),Vector3(1.13,.038,.23),
		ART.mat(Color("403c31"),1.0))
	var foliage := MultiMesh.new()
	foliage.transform_format = MultiMesh.TRANSFORM_3D
	foliage.use_colors = true
	foliage.mesh = make_herb_sprigs()
	foliage.instance_count = 33
	var rng := RandomNumberGenerator.new()
	rng.seed = 70421
	for i in range(foliage.instance_count):
		var x: float = rng.randf_range(-.53,.53)
		var z: float = rng.randf_range(-.083,.09)
		var s: float = rng.randf_range(.62,1.32)
		foliage.set_instance_transform(i,Transform3D(
			Basis(Vector3.UP,rng.randf_range(0,TAU)).scaled(Vector3(s,s,s)),
			Vector3(x,.095,z)))
		foliage.set_instance_color(i,Color("819274").lerp(
			Color("a59e77"),rng.randf_range(0.0,.37)))
	var greens := MultiMeshInstance3D.new()
	greens.name = "BatchedWindowHerbs"
	greens.multimesh = foliage
	var leaf := ART.mat(Color("a3b18b"),1.0)
	leaf.vertex_color_use_as_albedo = true
	leaf.cull_mode = BaseMaterial3D.CULL_DISABLED
	greens.material_override = leaf
	planter.add_child(greens)
	# Two growing vine stems and the tiny aged hooks they climb.
	for x in [.90,2.25]:
		ART.bone(root,Vector3(x,1.31,3.00),
			Vector3(x+.08,1.75,2.99),.017,.012,dark_oak,6)
		ART.bone(root,Vector3(x+.08,1.75,2.99),
			Vector3(x+.04,2.05,2.97),.014,.007,oxidized,6)
	# Porch timber has real depth.  The thin overhead lintel also frames the
	# player-facing door rather than competing with the gable.
	ART.bone(root,Vector3(-1.68,2.71,3.07),
		Vector3(.34,2.71,3.07),.094,.079,aged_oak,8)
	ART.bone(root,Vector3(-1.66,2.67,3.07),
		Vector3(-1.33,2.24,3.07),.065,.052,dark_oak,7)
	ART.bone(root,Vector3(.32,2.67,3.07),
		Vector3(.04,2.24,3.07),.063,.052,dark_oak,7)

static func _surface(texture_path: String, tint: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.roughness = .97
	mat.albedo_color = tint
	if ResourceLoader.exists(texture_path):
		mat.albedo_texture = load(texture_path)
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	return mat

static func make_roof_shingles() -> ArrayMesh:
	# Individual scale/offset variation is baked into a single shared mesh.
	# Geometry is on the pitched roof surface, not a hovering rectangle.
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rng := RandomNumberGenerator.new()
	rng.seed = 110826
	var columns: int = 17
	var rows: int = 14
	for side in [-1.0,1.0]:
		for row in range(rows):
			for col in range(columns):
				var x0: float = .065+float(col)*3.10/float(columns)
				var x1: float = .065+float(col+1)*3.10/float(columns)
				var z0: float = -3.01+float(row)*6.06/float(rows)
				var z1: float = -3.01+float(row+1)*6.06/float(rows)
				var twist: float = rng.randf_range(-.012,.012)
				var uplift: float = rng.randf_range(-.019,.028)
				var c: Color = Color("a8a29b").lerp(
					Color("77736a"),rng.randf_range(.05,.46))
				if (col+row)%9==0:
					c = c.lerp(Color("696d61"),.17)
				var a := _roof_vertex(side,x0,z0,twist)
				var b := _roof_vertex(side,x1,z0,twist)
				var d := _roof_vertex(side,x1,z1,uplift)
				var e := _roof_vertex(side,x0,z1,uplift)
				_tile_tri(st,a,b,e,c,Vector2.ZERO,Vector2.RIGHT,Vector2.DOWN)
				_tile_tri(st,b,d,e,c,Vector2.RIGHT,Vector2.ONE,Vector2.DOWN)
	st.generate_normals()
	return st.commit()

static func _roof_vertex(side: float,x: float,z: float,lift: float) -> Vector3:
	return Vector3(side*x,5.47-x*.572+.052+lift,z)

static func _tile_tri(st: SurfaceTool,a: Vector3,b: Vector3,c: Vector3,
		tint: Color,ua: Vector2,ub: Vector2,uc: Vector2) -> void:
	for pair in [[a,ua],[b,ub],[c,uc]]:
		st.set_color(tint)
		st.set_uv(pair[1])
		st.add_vertex(pair[0])

static func make_herb_sprigs() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for stem in range(5):
		var theta: float = float(stem)*TAU/5.0
		var axis := Vector3(cos(theta),0,sin(theta))
		var side := Vector3(-axis.z,0,axis.x)
		for j in range(4):
			var t: float = float(j)/4.0
			var base := Vector3.UP*(.075+t*.26)+axis*(.06+t*.08)
			var tip := base+axis*.10+Vector3.UP*.095
			for direction in [-1.0,1.0]:
				var end := tip+side*direction*.067
				for v in [base-side*direction*.029,base+side*direction*.029,end]:
					st.set_color(Color("71875f").lerp(Color("b1b78a"),t*.48))
					st.add_vertex(v)
	st.generate_normals()
	return st.commit()
