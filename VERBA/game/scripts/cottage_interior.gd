extends RefCounted
## The hermit's lived-in writing room, not an inaccessible grassy test shell.
## Visual floor aligns with the pre-existing .30m cottage floor collider.
## Furniture collision is separate from its mesh, matching other architecture.
const ART = preload("res://scripts/art.gd")

static func furnish(house: Node3D, world: Node3D, cabin: Node3D) -> void:
	var room := Node3D.new()
	room.name = "HermitsActualWritingRoom"
	house.add_child(room)
	var wood: StandardMaterial3D = _textured_wood()
	var darkwood := ART.mat(Color("504437"),.98)
	var paper := ART.mat(Color("cfc2a1"),.96)
	var leather := ART.mat(Color("5b4639"),.93)
	var brass := ART.mat(Color("837350"),.61)
	brass.metallic = .27

	# One authored wood-plank mesh instead of a dozen individual render nodes.
	var floor := MeshInstance3D.new()
	floor.name = "ContinuousSolidLookingCottageFloor"
	floor.mesh = make_floor_mesh()
	var floor_material := _textured_wood()
	floor_material.vertex_color_use_as_albedo = true
	floor_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	floor_material.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
	floor.material_override = floor_material
	room.add_child(floor)

	# The hermit's desk is set against the rear wall so there is a clear
	# walkway from the entrance; it is physically obstructive, not a ghost prop.
	var desk := Node3D.new()
	desk.name = "HermitScholarsDesk"
	desk.position = Vector3(-1.33,0,-1.73)
	room.add_child(desk)
	ART.box(desk,Vector3(0,.91,0),Vector3(1.65,.14,.89),wood)
	ART.box(desk,Vector3(0,.74,.33),Vector3(1.38,.23,.14),leather)
	for sx in [-1.0,1.0]:
		for sz in [-1.0,1.0]:
			ART.box(desk,Vector3(sx*.68,.60,sz*.34),
				Vector3(.15,.59,.16),darkwood)
	# A rolled field note and small inkwell make this a writing desk.
	ART.box(desk,Vector3(-.22,1.005,-.12),
		Vector3(.56,.018,.42),paper,Vector3(0,-.09,0))
	ART.box(desk,Vector3(.42,1.01,.13),Vector3(.15,.09,.15),leather)
	ART.orb(desk,Vector3(.42,1.075,.13),Vector3(.067,.035,.067),brass,9)
	world.add_solid_box(cabin,Vector3(-1.33,.66,-1.73),
		Vector3(1.66,.91,.89),"HermitDeskPhysical")

	# A shallow shelf and five differently sized leather volumes.
	# These are environmental props, not falsely interactive study books.
	var shelf := Node3D.new()
	shelf.name = "HermitWallShelf"
	shelf.position = Vector3(1.68,0,-2.18)
	room.add_child(shelf)
	for xx in [-.46,.46]:
		ART.box(shelf,Vector3(xx,1.35,0),
			Vector3(.105,1.95,.39),darkwood)
	for y in [.48,1.16,1.88,2.31]:
		ART.box(shelf,Vector3(0,y,0),Vector3(1.05,.085,.46),wood)
	for j in range(5):
		var ht: float = .30+float((j*7)%4)*.047
		var pos_x: float = -.36+float(j)*.175
		var spine: Material = leather if j%2==0 else darkwood
		ART.box(shelf,Vector3(pos_x,1.20+ht*.5,.035),
			Vector3(.137,ht,.25),spine,Vector3(0,0,deg_to_rad(float(j-2)*2.2)))
	world.add_solid_box(cabin,Vector3(1.68,1.35,-2.18),
		Vector3(1.05,2.30,.54),"HermitBookshelfPhysical")

	# A resting stool opposite the doorway leaves the central room open.
	var stool := Node3D.new()
	stool.name = "LowWritingStool"
	stool.position = Vector3(-1.0,0,-.50)
	room.add_child(stool)
	ART.box(stool,Vector3(0,.58,0),Vector3(.70,.11,.58),wood)
	for sx in [-1.0,1.0]:
		for sz in [-1.0,1.0]:
			ART.box(stool,Vector3(sx*.245,.43,sz*.18),
				Vector3(.10,.34,.10),darkwood)
	world.add_solid_box(cabin,Vector3(-1.0,.46,-.50),
		Vector3(.7,.44,.58),"HermitStoolPhysical")


static func _textured_wood() -> StandardMaterial3D:
	var wood := StandardMaterial3D.new()
	wood.albedo_color = Color("c1aa8c")
	wood.roughness = .96
	wood.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var path := "res://assets/textures/real/cottage_wood_diffuse.jpg"
	if ResourceLoader.exists(path):
		wood.albedo_texture = load(path)
	return wood


static func make_floor_mesh() -> ArrayMesh:
	# Visible deck is a few millimeters ABOVE the original collision top at
	# y=.30. Never build a decorative raised floor that player feet clip through.
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rng := RandomNumberGenerator.new()
	rng.seed = 112720
	var count: int = 14
	for i in range(count):
		var x0: float = -2.73+float(i)*5.46/float(count)+.008
		var x1: float = -2.73+float(i+1)*5.46/float(count)-.008
		var top: float = .305+rng.randf_range(0,.004)
		var z0: float = -2.43
		var z1: float = 2.45
		var tint: Color = Color("b7a486").lerp(Color("96866d"),
			rng.randf_range(.12,.51))
		if i%4==0:
			tint = tint.lerp(Color("817b6b"),.14)
		var a := Vector3(x0,top,z0)
		var b := Vector3(x1,top,z0)
		var c := Vector3(x1,top,z1)
		var d := Vector3(x0,top,z1)
		_face(st,a,c,b,tint)
		_face(st,a,d,c,tint)
		var depth: float = .052
		_face(st,a-Vector3.UP*depth,b-Vector3.UP*depth,b,tint.darkened(.23))
		_face(st,a-Vector3.UP*depth,b,a,tint.darkened(.23))
		_face(st,c-Vector3.UP*depth,d-Vector3.UP*depth,d,tint.darkened(.23))
		_face(st,c-Vector3.UP*depth,d,c,tint.darkened(.23))
	st.generate_normals()
	return st.commit()


static func _face(st: SurfaceTool,a: Vector3,b: Vector3,c: Vector3,color: Color) -> void:
	for v in [a,b,c]:
		st.set_color(color)
		st.set_uv(Vector2(v.x*.57,v.z*.23+v.y*.12))
		st.add_vertex(v)
