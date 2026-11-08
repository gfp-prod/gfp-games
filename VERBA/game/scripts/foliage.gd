extends RefCounted
## Stylized, mesh-based botanical workshop for VERBA v0.7.
## No sphere crowns, no traffic-cone conifers, no flat grass rectangles.
## Leaves are individual curved polygons; ferns are pinnate fronds; grass is batched.
const ART = preload("res://scripts/art.gd")

static func leaf_material(kind: String) -> StandardMaterial3D:
	var tex_name := "leaf_amber" if kind == "autumn" else "leaf_blue" if kind == "pine" else "leaf_green"
	var material := StandardMaterial3D.new()
	material.albedo_texture = load("res://assets/textures/" + tex_name + ".png")
	material.albedo_color = Color.WHITE
	material.vertex_color_use_as_albedo = true
	material.roughness = 0.93
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	return material

static func draw_leaf(st: SurfaceTool, root: Vector3, direction: Vector3, width: float, tint: Color) -> void:
	var length := direction.length()
	if length < 0.01: return
	var axis := direction.normalized()
	var side := axis.cross(Vector3.UP).normalized()
	if side.length_squared() < 0.01: side=Vector3.RIGHT
	var lift := Vector3.UP * width * 0.20
	var origin := root
	var a := root + axis*length*.28 + side*width*.72 + lift
	var b := root + axis*length*.58 + side*width + lift*.76
	var tip := root + axis*length + Vector3.UP*width*.27
	var c := root + axis*length*.58 - side*width + lift*.76
	var d := root + axis*length*.28 - side*width*.72 + lift
	var centre := root + axis*length*.48 + Vector3.UP*width*.29
	var points: Array[Vector3] = [origin,a,b,tip,c,d]
	var uvs: Array[Vector2] = [Vector2(.5,1),Vector2(.15,.72),Vector2(.02,.41),Vector2(.5,0),Vector2(.98,.41),Vector2(.85,.72)]
	for i in range(6):
		var k := (i+1)%6
		st.set_color(tint)
		st.set_uv(Vector2(.5,.46));st.add_vertex(centre)
		st.set_color(tint.lightened(.08 if i%2==0 else 0.0))
		st.set_uv(uvs[i]);st.add_vertex(points[i])
		st.set_color(tint)
		st.set_uv(uvs[k]);st.add_vertex(points[k])

static func make_broadleaf_crown(parent: Node3D, branch_ends: Array, kind: String, seed: int) -> void:
	var rng := RandomNumberGenerator.new();rng.seed=seed
	var mesh_tool := SurfaceTool.new()
	mesh_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for end in branch_ends:
		var cluster_count := rng.randi_range(41,64)
		for j in range(cluster_count):
			var outward := Vector3(rng.randf_range(-1,1),rng.randf_range(-.65,1.0),rng.randf_range(-1,1)).normalized()
			var pos: Vector3 = end + Vector3(rng.randf_range(-1.35,1.35),rng.randf_range(-.73,1.06),rng.randf_range(-1.3,1.3))
			var size := rng.randf_range(.30,.65)
			var color := Color("f6e9d2") if kind == "autumn" else Color("f1f5e2")
			color=color.lerp(Color("c4d3a8") if kind == "broadleaf" else Color("dac096"), rng.randf_range(.12,.5))
			draw_leaf(mesh_tool,pos,outward*size,size*.35,color)
	mesh_tool.generate_normals()
	var n := MeshInstance3D.new()
	n.name="IndividualLeavesAndVeins"
	n.mesh=mesh_tool.commit()
	n.material_override=leaf_material(kind)
	parent.add_child(n)

static func make_conifer_needles(parent: Node3D, branch_ends: Array, seed: int) -> void:
	var rng:=RandomNumberGenerator.new();rng.seed=seed
	var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for end in branch_ends:
		for i in range(10):
			var theta:=TAU*float(i)/10.0+rng.randf_range(-.1,.1)
			var radial := Vector3(cos(theta),rng.randf_range(-.18,.07),sin(theta))
			var root: Vector3 = end + radial*rng.randf_range(.0,.5)
			var tip := radial*rng.randf_range(.65,1.23)+Vector3.UP*rng.randf_range(-.22,.20)
			for j in range(5):
				var t:=float(j)/5.0
				var p := root+tip*t
				var cross := Vector3(-radial.z,.12,radial.x)
				var color:=Color("758975").lerp(Color("a4b3a0"),rng.randf_range(0,.65))
				draw_leaf(st,p,cross*rng.randf_range(.23,.4),.06,color)
	st.generate_normals()
	var n:=MeshInstance3D.new();n.name="NeedleSprays"
	n.mesh=st.commit();n.material_override=leaf_material("pine");parent.add_child(n)

static func make_fern_mesh() -> ArrayMesh:
	var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for frond in range(8):
		var theta:=TAU*float(frond)/8.0
		var axis:=Vector3(cos(theta),0,sin(theta))
		var lateral:=Vector3(-sin(theta),0,cos(theta))
		for j in range(13):
			var t:=float(j)/13.0
			var p:=Vector3(0,.09,0)+axis*(.82*t*t)+Vector3.UP*(.50*sin(t*PI*.9)+.22*t)
			var length:=.24*sin((t+.07)*PI)*(.83 if frond%2 else 1.0)
			var color:=Color("738b5e").lerp(Color("acb780"),t*.32)
			for side in [-1.0,1.0]:
				var tip: Vector3 = p + lateral * (float(side) * length) + axis * 0.09 + Vector3.UP * 0.06
				var root:=p-axis*.1
				st.set_color(color.darkened(.11));st.set_uv(Vector2(.5,1));st.add_vertex(root)
				st.set_color(color);st.set_uv(Vector2(1 if side>0 else 0,.3));st.add_vertex(tip)
				st.set_color(color.lightened(.1));st.set_uv(Vector2(.5,0));st.add_vertex(p+axis*.17+Vector3.UP*.06)
	st.generate_normals()
	return st.commit()

static func populate_ferns(world) -> void:
	var mesh:=make_fern_mesh()
	var material:=StandardMaterial3D.new()
	material.vertex_color_use_as_albedo=true
	material.cull_mode=BaseMaterial3D.CULL_DISABLED
	material.roughness=1.0
	var rng:=RandomNumberGenerator.new();rng.seed=17641
	var root:=Node3D.new();root.name="FernBanksAndUnderstorey";world.add_child(root)
	for i in range(62):
		var x:=rng.randf_range(-56,56)
		var z:=rng.randf_range(-57,57)
		if Vector2(x,z).distance_to(Vector2(0,20)) < 12.0:continue
		if absf(x) < 5.0 and z > -35 and z < 26:continue
		if x > 20.0 and z > -5.0:continue
		var plant=world.make_living_plant(Vector3(x,world.height_at(x,z)+.02,z),"fern",mesh,material,rng.randf_range(.65,1.65))
		plant.rotation.y=rng.randf_range(0,TAU)

static func grass_mesh() -> ArrayMesh:
	var rng:=RandomNumberGenerator.new();rng.seed=772
	var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(9):
		var a := float(i)*2.39996323
		var root:=Vector3(cos(a),0,sin(a))*rng.randf_range(.03,.15)
		var height:=rng.randf_range(.29,.63)
		var bend := Vector3(cos(a)*.15,0,sin(a)*.15)
		var side := Vector3(-sin(a),0,cos(a))
		var w:=rng.randf_range(.025,.055)
		var lower := root+Vector3.UP*height*.55+bend*.3
		var upper := root+Vector3.UP*height+bend
		var vertices: Array[Vector3]=[
			root-side*w,root+side*w,lower+side*w*.62,
			root-side*w,lower+side*w*.62,lower-side*w*.62,
			lower-side*w*.62,lower+side*w*.62,upper
		]
		var colors: Array[Color]=[
			Color("62704f"),Color("7f8d61"),Color("a5ae78"),
			Color("62704f"),Color("a5ae78"),Color("88976b"),
			Color("829465"),Color("a3b07c"),Color("c9bc85")
		]
		for j in range(vertices.size()):
			st.set_color(colors[j]);st.set_uv(Vector2(float(j%3)*.5,float(j)/9.0));st.add_vertex(vertices[j])
	st.generate_normals()
	return st.commit()

static func populate_grass(world) -> void:
	var mesh:=grass_mesh()
	var material:=StandardMaterial3D.new()
	material.vertex_color_use_as_albedo=true
	material.cull_mode=BaseMaterial3D.CULL_DISABLED
	material.roughness=1.0
	material.texture_filter=BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
	material.albedo_texture=load("res://assets/textures/grass.png")
	var groups: Array[Dictionary]=[
		{"name":"Meadow Tufts","n":2600,"tint":Color("d0c38a")},
		{"name":"Cool Bank Grasses","n":700,"tint":Color("86a28c")},
		{"name":"Amber Ridge Grasses","n":850,"tint":Color("d9b47b")}
	]
	for group in groups:
		var count:int=group["n"]
		var mm:=MultiMesh.new()
		mm.transform_format=MultiMesh.TRANSFORM_3D
		mm.use_colors=true
		mm.mesh=mesh
		mm.instance_count=count
		var rng:=RandomNumberGenerator.new();rng.seed=9024+count
		for i in range(count):
			var x:=rng.randf_range(-69,69)
			var z:=rng.randf_range(-69,69)
			# Vegetation has ecologically distinct bands; the middle of the trail stays open.
			for tries in range(10):
				if String(group["name"])=="Cool Bank Grasses":
					z=rng.randf_range(-61,60);x=world.stream_x(z)+rng.randf_range(-11,11)
				elif String(group["name"])=="Amber Ridge Grasses":
					x=rng.randf_range(18,65);z=rng.randf_range(-42,52)
				if not (absf(x)<3.8 and z>-32 and z<32):break
			var base:=Basis(Vector3.UP,rng.randf_range(0,TAU))
			var s:=rng.randf_range(.55,1.43)
			base=base.scaled(Vector3(s,rng.randf_range(.75,1.45),s))
			mm.set_instance_transform(i,Transform3D(base,Vector3(x,world.height_at(x,z)+.017,z)))
			var c:Color=group["tint"]
			mm.set_instance_color(i,c.lerp(Color("6f885d"),rng.randf_range(.04,.43)))
		var mi:=MultiMeshInstance3D.new();mi.name=group["name"]
		mi.multimesh=mm
		mi.material_override=material
		world.add_child(mi)

static func leaf_litter_mesh() -> ArrayMesh:
	var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	# One curled leaf of true silhouette, not a flat colored rectangle.
	var pts:Array[Vector3]=[
		Vector3(0,.025,-.19),Vector3(-.15,.04,-.1),Vector3(-.22,.08,.06),
		Vector3(-.09,.06,.17),Vector3(0,.09,.23),Vector3(.11,.06,.14),
		Vector3(.21,.06,.03),Vector3(.11,.05,-.1)
	]
	var cen:=Vector3(0,.09,0)
	for i in range(pts.size()):
		st.set_uv(Vector2(.5,.5));st.add_vertex(cen)
		st.set_uv(Vector2(.5+pts[i].x,.5+pts[i].z));st.add_vertex(pts[i])
		st.set_uv(Vector2(.5+pts[(i+1)%8].x,.5+pts[(i+1)%8].z));st.add_vertex(pts[(i+1)%8])
	st.generate_normals()
	return st.commit()

static func populate_litter(world) -> void:
	var mesh:=leaf_litter_mesh()
	var material:=StandardMaterial3D.new()
	material.albedo_texture=load("res://assets/textures/leaf_amber.png")
	material.vertex_color_use_as_albedo=true
	material.cull_mode=BaseMaterial3D.CULL_DISABLED
	material.roughness=1.0
	var mm:=MultiMesh.new();mm.transform_format=MultiMesh.TRANSFORM_3D
	mm.use_colors=true;mm.mesh=mesh;mm.instance_count=750
	var rng:=RandomNumberGenerator.new();rng.seed=1140
	for i in range(750):
		var x:=rng.randf_range(17,58)
		var z:=rng.randf_range(-21,48)
		var size:=rng.randf_range(.48,1.4)
		var basis:=Basis(Vector3.UP,rng.randf_range(0,TAU)).scaled(Vector3.ONE*size)
		mm.set_instance_transform(i,Transform3D(basis,Vector3(x,world.height_at(x,z)+.015,z)))
		mm.set_instance_color(i,Color("daa469").lerp(Color("8a633f"),rng.randf_range(.1,.75)))
	var n:=MultiMeshInstance3D.new()
	n.name="FallenIndividualLeaves"
	n.multimesh=mm
	n.material_override=material
	world.add_child(n)
