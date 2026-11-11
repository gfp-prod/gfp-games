extends RefCounted
## VERBA: authored crooked hermitage, built as a coherent architectural mesh.
## The old straight, imported prefab is no longer displayed. This replacement
## shares its door position and collidable body, while adding a small side turret.
## All surfaces are offline resources: no networking or runtime asset loading.
const ART = preload("res://scripts/art.gd")

static func build(cabin: Node3D, world: Node3D) -> void:
	var house := Node3D.new()
	house.name = "CrookedHermitage"
	cabin.add_child(house)
	var plaster := _paint("res://assets/textures/real/cottage_plaster_diffuse.jpg",Color("ddc9a9"))
	var wood := _paint("res://assets/textures/real/cottage_wood_diffuse.jpg",Color("9b7b60"))
	var soot := ART.mat(Color("463b35"),.97)
	var damp_stone := _paint("res://assets/textures/real/stone_diffuse.jpg",Color("a09a86"))
	var metal := ART.mat(Color("897758"),.67)
	metal.metallic = .21
	var roof_mat := _paint("res://assets/textures/real/cottage_roof_diffuse.jpg",Color("9bada2"))
	roof_mat.vertex_color_use_as_albedo = true
	roof_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	roof_mat.roughness = 1.0

	# Plaster is a tapered, peaked mesh, not a square slab. The ridge is
	# intentionally offset and the broad, bowed roof owns the silhouette.
	var walls := MeshInstance3D.new()
	walls.name = "OnePieceTaperedLimePlasterWalls"
	walls.mesh = make_wall_shell()
	walls.material_override = plaster
	house.add_child(walls)
	var roof := MeshInstance3D.new()
	roof.name = "CrookedMossSlateRoof"
	roof.mesh = make_roof()
	roof.material_override = roof_mat
	house.add_child(roof)

	# Foundation: separate real stones placed at actual ground contact.
	# Large masses, asymmetrical spacing; not a row of obvious small cubes.
	for i in range(10):
		var x: float = -2.7 + float(i)*.59
		for side in [-1.0,1.0]:
			ART.stone(house,Vector3(x,.11,side*2.64),
				Vector3(.51+.07*sin(float(i)*3.4),.24,.29),damp_stone)
	for i in range(8):
		var z: float = -2.25+float(i)*.64
		for side in [-1.0,1.0]:
			ART.stone(house,Vector3(side*2.87,.11,z),
				Vector3(.29,.25,.53),damp_stone)

	# Structural timbers have a readable construction logic: corner posts,
	# horizontal ring beam, diagonals that actually meet the frame.
	for side in [-1.0,1.0]:
		for z in [-2.59,2.65]:
			ART.bone(house,Vector3(side*2.71,.18,z),
				Vector3(side*2.66,3.18,z),.14,.115,wood,9)
		for y in [.34,2.96]:
			ART.bone(house,Vector3(-2.73,y,side*2.64),
				Vector3(2.73,y,side*2.64),.095,.087,wood,8)
		ART.bone(house,Vector3(side*2.62,.43,2.69),
			Vector3(side*1.68,2.85,2.70),.084,.072,wood,8)
		ART.bone(house,Vector3(side*2.63,.45,-2.65),
			Vector3(side*1.65,2.86,-2.66),.081,.071,wood,8)
		# Exposed east and west eave structure, no floating rectangular border.
		ART.bone(house,Vector3(side*3.28,3.04,-3.05),
			Vector3(side*3.28,3.04,3.12),.091,.08,soot,8)
		ART.bone(house,Vector3(-.20,5.88,3.12),
			Vector3(side*3.27,3.02,3.12),.09,.082,wood,8)

	# The pitched roof crests in a crooked timber ridge, with a single
	# deliberate rise at its overhanging front lip.
	ART.bone(house,Vector3(-.21,5.89,-3.10),
		Vector3(-.21,5.97,3.16),.095,.075,soot,9)
	for z in [-2.67,2.64]:
		for side in [-1.0,1.0]:
			ART.bone(house,Vector3(-.18,5.68,z),
				Vector3(side*2.67,3.17,z),.087,.068,wood,8)

	# Door remains at the same point as the original actual collider:
	# centre (-0.69, 1.3, +2.55), so movement and saves stay compatible.
	_add_door(house,wood,soot,metal)
	_add_windows(house,wood,soot,metal)
	_add_planter(house,wood)
	_add_chimney(house,damp_stone,soot,metal)
	_add_turret(house,world,cabin,damp_stone,roof_mat,wood,soot)

static func _paint(path: String, tint: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = tint
	m.roughness = .94
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	if ResourceLoader.exists(path):
		m.albedo_texture = load(path)
	return m

static func make_wall_shell() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var y0: float = .19
	var y1: float = 3.14
	var w0: float = 2.89
	var w1: float = 2.73
	var z0: float = 2.61
	var z1: float = 2.55
	# Front and back.
	_quad(st,Vector3(-w0,y0,z0),Vector3(w0,y0,z0),
		Vector3(w1,y1,z1),Vector3(-w1,y1,z1))
	_quad(st,Vector3(w0,y0,-z0),Vector3(-w0,y0,-z0),
		Vector3(-w1,y1,-z1),Vector3(w1,y1,-z1))
	# Side walls, gently battered from fieldstone foundation to first floor.
	_quad(st,Vector3(w0,y0,z0),Vector3(w0,y0,-z0),
		Vector3(w1,y1,-z1),Vector3(w1,y1,z1))
	_quad(st,Vector3(-w0,y0,-z0),Vector3(-w0,y0,z0),
		Vector3(-w1,y1,z1),Vector3(-w1,y1,-z1))
	_tri(st,Vector3(-w1,y1,z1),Vector3(w1,y1,z1),
		Vector3(-.20,5.69,z1),Color.WHITE)
	_tri(st,Vector3(w1,y1,-z1),Vector3(-w1,y1,-z1),
		Vector3(-.20,5.69,-z1),Color.WHITE)
	st.generate_normals()
	return st.commit()

static func make_roof() -> ArrayMesh:
	# Every uneven slate is generated into ONE mesh, roughly 5,000 vertices.
	# This avoids thousands of roof objects and gives a genuinely bowed pitch.
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rng := RandomNumberGenerator.new()
	rng.seed = 27506
	var columns: int = 20
	var rows: int = 24
	for side in [-1.0,1.0]:
		for ix in range(columns):
			for iz in range(rows):
				var u0: float = float(ix)/float(columns)
				var u1: float = float(ix+1)/float(columns)
				var z0: float = -3.11 + float(iz)*6.24/float(rows)
				var z1: float = -3.11 + float(iz+1)*6.24/float(rows)
				var offset: float = rng.randf_range(-.035,.035)
				var ridge_a: Vector3 = _roof_point(side,u0,z0,offset)
				var ridge_b: Vector3 = _roof_point(side,u1,z0,offset)
				var eve_a: Vector3 = _roof_point(side,u0,z1,offset)
				var eve_b: Vector3 = _roof_point(side,u1,z1,offset+.008)
				var color: Color = Color("b0b5a3").lerp(Color("697d73"),
					rng.randf_range(.08,.55))
				if (ix*3+iz)%13 == 0:
					color = color.lerp(Color("a39480"),.21)
				if side < 0.0:
					_tri(st,ridge_a,eve_a,ridge_b,color)
					_tri(st,ridge_b,eve_a,eve_b,color)
				else:
					_tri(st,ridge_a,ridge_b,eve_a,color)
					_tri(st,ridge_b,eve_b,eve_a,color)
	st.generate_normals()
	return st.commit()

static func _roof_point(side: float,u: float,z: float,shift: float) -> Vector3:
	var x: float = lerpf(-.21,side*3.32,u)
	var y: float = 5.89 - 2.89*pow(u,.88)
	y += .065*sin(z*1.28)*u
	y += .04*pow(maxf(0.0,(z-2.2)),2.0)
	return Vector3(x,y+shift,z)

static func _add_door(house: Node3D,wood: Material,soot: Material,metal: Material) -> void:
	# The door is hand-built from five staggered planks, with a curved header
	# suggested by length differences, not a flat black rectangular portal.
	var center: float = -.69
	for i in range(5):
		var x: float = center+(float(i)-2.0)*.21
		var h: float = 2.35 - .10*absf(float(i)-2.0)
		ART.box(house,Vector3(x,.23+h*.5,2.69),
			Vector3(.205,h,.10),wood,
			Vector3(0,radians(sin(float(i)*1.75)*1.9),0))
	ART.bone(house,Vector3(center-.66,.18,2.77),
		Vector3(center-.66,2.53,2.77),.11,.105,soot,8)
	ART.bone(house,Vector3(center+.65,.18,2.77),
		Vector3(center+.65,2.53,2.77),.11,.105,soot,8)
	ART.bone(house,Vector3(center-.71,2.55,2.78),
		Vector3(center+.71,2.55,2.78),.106,.098,soot,8)
	# Small actual iron studs, traditional diagonal cross brace, and latch.
	ART.bone(house,Vector3(center-.48,.60,2.764),
		Vector3(center+.46,1.94,2.764),.047,.045,soot,7)
	for yy in [.42,.78,1.24,1.65,2.10]:
		ART.box(house,Vector3(center+.37,yy,2.79),
			Vector3(.035,.036,.02),metal)
	ART.orb(house,Vector3(center+.41,1.28,2.833),
		Vector3(.072,.07,.024),metal,9)
	# A narrow roof over the doorstep is a distinct warm silhouette,
	# not a giant porch hiding the original gable.
	ART.bone(house,Vector3(-1.76,2.77,2.68),
		Vector3(.41,2.77,2.68),.112,.095,wood,8)
	for side in [-1.0,1.0]:
		ART.bone(house,Vector3(center+side*1.06,2.77,2.68),
			Vector3(center+side*1.02,2.45,3.24),.092,.075,wood,8)

static func _add_windows(house: Node3D,wood: Material,soot: Material,metal: Material) -> void:
	# Three visible windows, the upper a tiny scholar's diamond on the gable.
	# Flat diffuse glass avoids obvious emissive yellow rectangles at noon.
	var glass := ART.mat(Color("56756f"),.30)
	glass.metallic = .16
	for item in [
		{"x":1.51,"y":1.83,"z":2.66,"w":.93,"h":1.04},
		{"x":-.18,"y":4.17,"z":2.71,"w":.60,"h":.67}
	]:
		var x: float = float(item["x"])
		var y: float = float(item["y"])
		var z: float = float(item["z"])
		var w: float = float(item["w"])
		var h: float = float(item["h"])
		ART.box(house,Vector3(x,y,z),Vector3(w,h,.036),glass)
		for xx in [x-w*.5,x+w*.5]:
			ART.bone(house,Vector3(xx,y-h*.57,z+.06),
				Vector3(xx,y+h*.57,z+.06),.064,.060,wood,8)
		for yy in [y-h*.5,y+h*.5]:
			ART.bone(house,Vector3(x-w*.55,yy,z+.06),
				Vector3(x+w*.55,yy,z+.06),.064,.064,wood,8)
		ART.bone(house,Vector3(x,y-h*.49,z+.067),
			Vector3(x,y+h*.49,z+.067),.025,.025,soot,7)
		ART.bone(house,Vector3(x-w*.47,y,z+.067),
			Vector3(x+w*.47,y,z+.067),.025,.025,soot,7)
	# Open shutters on the lower window imply a real human occupant.
	for side in [-1.0,1.0]:
		var xx: float = 1.51+side*.61
		ART.box(house,Vector3(xx,1.83,2.78),
			Vector3(.23,1.01,.055),wood,
			Vector3(0,side*.39,0))
		for y in [1.48,2.14]:
			ART.box(house,Vector3(xx,y,2.83),
				Vector3(.24,.055,.014),soot)
	ART.box(house,Vector3(1.51,1.28,2.82),Vector3(1.19,.095,.23),wood)
	ART.box(house,Vector3(1.51,1.23,2.86),Vector3(1.25,.028,.17),metal)

static func _add_planter(house: Node3D,wood: Material) -> void:
	var planter := Node3D.new()
	planter.name = "HerbsOnTheWindowSill"
	planter.position = Vector3(1.50,1.29,2.95)
	house.add_child(planter)
	ART.box(planter,Vector3(0,-.09,0),Vector3(1.11,.20,.35),wood)
	ART.box(planter,Vector3(0,.013,0),Vector3(1.04,.025,.29),
		ART.mat(Color("4b4031"),.98))
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = _sprig_mesh()
	mm.instance_count = 31
	var rng := RandomNumberGenerator.new()
	rng.seed = 4102
	for i in range(mm.instance_count):
		var scale: float = rng.randf_range(.72,1.30)
		var p := Vector3(rng.randf_range(-.48,.48),.04,
			rng.randf_range(-.11,.11))
		mm.set_instance_transform(i,Transform3D(
			Basis(Vector3.UP,rng.randf_range(0,TAU)).scaled(Vector3.ONE*scale),p))
		mm.set_instance_color(i,Color("708a72").lerp(Color("a6a179"),
			rng.randf_range(0,.43)))
	var leaves := MultiMeshInstance3D.new()
	leaves.name = "BatchedApothecaryHerbs"
	leaves.multimesh = mm
	var mat := ART.mat(Color("aab59b"),.98)
	mat.vertex_color_use_as_albedo = true
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	leaves.material_override = mat
	planter.add_child(leaves)

static func _sprig_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for j in range(5):
		var theta: float = float(j)*TAU/5.0
		var direction := Vector3(cos(theta),.38,sin(theta))
		var lateral := Vector3(-direction.z,0,direction.x)
		_tri(st,Vector3(0,.02,0),
			direction*.36+lateral*.058,
			direction*.36-lateral*.058,Color("879a7e"))
	st.generate_normals()
	return st.commit()

static func _add_chimney(house: Node3D,stone: Material,soot: Material,metal: Material) -> void:
	# A slightly leaning, irregular apothecary chimney breaks the roofline.
	# Its larger lower sections anchor into the roof pitch.
	var levels: Array[Vector3] = [
		Vector3(1.72,4.21,-.94),
		Vector3(1.77,4.89,-.97),
		Vector3(1.89,5.63,-.99),
		Vector3(1.79,6.37,-1.05),
		Vector3(1.70,7.18,-1.07)
	]
	for i in range(levels.size()-1):
		var p: Vector3 = levels[i]
		var q: Vector3 = levels[i+1]
		ART.bone(house,p,q,.37+.06*sin(float(i)*2.1),
			.33+.045*sin(float(i+1)),stone,6)
		ART.box(house,q,Vector3(.66,.085,.64),soot,
			Vector3(0,.11*float(i),0))
	ART.box(house,Vector3(1.68,7.24,-1.08),
		Vector3(1.02,.19,.93),soot,Vector3(.04,-.14,.08))
	ART.box(house,Vector3(1.68,7.14,-1.08),
		Vector3(.60,.10,.58),metal)

static func _add_turret(house: Node3D,world: Node3D,cabin: Node3D,
		stone: Material,slate: Material,wood: Material,soot: Material) -> void:
	var tower := Node3D.new()
	tower.name = "HearthsideApothecaryTurret"
	tower.position = Vector3(-3.44,0,-1.33)
	house.add_child(tower)
	var body := MeshInstance3D.new()
	body.name = "SevenSidedStoneTurret"
	body.mesh = _turret_body()
	body.material_override = stone
	tower.add_child(body)
	var hat := MeshInstance3D.new()
	hat.name = "AsymmetricConicalTurretRoof"
	hat.mesh = _turret_hat()
	hat.material_override = slate
	tower.add_child(hat)
	for i in range(7):
		var theta: float = TAU*float(i)/7.0
		var x: float = cos(theta)
		var z: float = sin(theta)
		ART.bone(tower,Vector3(x*1.05,.30,z*1.05),
			Vector3(x*.99,3.10,z*.99),.064,.052,wood,7)
	# A small brass weather vane catches the eye without glowing artificially.
	ART.bone(tower,Vector3(-.14,4.48,0),
		Vector3(-.21,5.15,0),.038,.025,soot,8)
	ART.bone(tower,Vector3(-.53,4.93,0),
		Vector3(.15,4.93,0),.043,.030,wood,7)
	# The turret is physical rather than an illusory decoration. Keep its
	# collider separate so future spells may target the annex independently.
	world.add_solid_box(cabin,Vector3(-3.44,1.56,-1.33),
		Vector3(2.18,3.12,2.14),"ApothecaryTurretSolid")

static func _turret_body() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(7):
		var a: float = TAU*float(i)/7.0
		var b: float = TAU*float(i+1)/7.0
		var p0 := Vector3(cos(a)*1.13,.13,sin(a)*1.13)
		var q0 := Vector3(cos(b)*1.13,.13,sin(b)*1.13)
		var p1 := Vector3(cos(a)*1.03,3.13,sin(a)*1.03)
		var q1 := Vector3(cos(b)*1.03,3.13,sin(b)*1.03)
		_tri(st,p0,q0,p1,Color.WHITE)
		_tri(st,q0,q1,p1,Color.WHITE)
	st.generate_normals()
	return st.commit()

static func _turret_hat() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(12):
		var a: float = TAU*float(i)/12.0
		var b: float = TAU*float(i+1)/12.0
		var p := Vector3(cos(a)*1.50,3.04,sin(a)*1.50)
		var q := Vector3(cos(b)*1.50,3.04,sin(b)*1.50)
		var top := Vector3(-.14,4.57,.05)
		var tint: Color = Color("9aa891").lerp(Color("7b8677"),
			float(i%3)*.17)
		_tri(st,p,q,top,tint)
	st.generate_normals()
	return st.commit()

static func _quad(st: SurfaceTool,a: Vector3,b: Vector3,c: Vector3,d: Vector3) -> void:
	_tri(st,a,b,d,Color.WHITE)
	_tri(st,b,c,d,Color.WHITE)

static func _tri(st: SurfaceTool,a: Vector3,b: Vector3,c: Vector3,tint: Color) -> void:
	for v in [a,b,c]:
		st.set_color(tint)
		st.set_uv(Vector2(v.x*.38+v.z*.25,v.y*.34+v.z*.19))
		st.add_vertex(v)
