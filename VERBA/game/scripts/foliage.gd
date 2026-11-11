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
		var cleared: Vector2=world.move_vegetation_outside_roadside(x,z)
		x=cleared.x
		z=cleared.y
		var plant=world.make_living_plant(Vector3(x,world.height_at(x,z)+.02,z),"fern",mesh,material,rng.randf_range(.65,1.65))
		plant.rotation.y=rng.randf_range(0,TAU)

static func grass_mesh() -> ArrayMesh:
	# A tuft of fine tapered blades, not nine giant triangular spikes.
	# Subtle curved blades read as foliage at first-person scale and keep
	# each MultiMesh instance under 65 triangles.
	var rng := RandomNumberGenerator.new()
	rng.seed=772
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(12):
		var angle: float = float(i)*2.39996323+rng.randf_range(-.13,.13)
		var base: Vector3 = Vector3(cos(angle),0.0,sin(angle))*rng.randf_range(.018,.11)
		var direction: Vector3 = Vector3(cos(angle),0.0,sin(angle))
		var lateral: Vector3 = Vector3(-direction.z,0.0,direction.x)
		var height: float = rng.randf_range(.19,.40)
		var width: float = rng.randf_range(.011,.027)
		var lower: Vector3 = base + Vector3.UP*(height*.54) + direction*.027
		var tip: Vector3 = base + Vector3.UP*height + direction*rng.randf_range(.055,.12)
		var base_left: Vector3 = base-lateral*width
		var base_right: Vector3 = base+lateral*width
		var middle_left: Vector3 = lower-lateral*width*.53
		var middle_right: Vector3 = lower+lateral*width*.53
		var darker: Color = Color("83916b")
		var mid: Color = Color("abb78a")
		var tip_color: Color = Color("c3cba4")
		for triangle in [
			[base_left,darker,base_right,mid,middle_right,mid],
			[base_left,darker,middle_right,mid,middle_left,mid],
			[middle_left,mid,middle_right,mid,tip,tip_color]
		]:
			for j in range(0,6,2):
				var vertex: Vector3 = triangle[j]
				var tint: Color = triangle[j+1]
				st.set_color(tint)
				st.set_uv(Vector2(vertex.x*2.0,vertex.y*2.0))
				st.add_vertex(vertex)
	st.generate_normals()
	return st.commit()

static func populate_grass(world) -> void:
	var mesh:=grass_mesh()
	var material:=StandardMaterial3D.new()
	material.vertex_color_use_as_albedo=true
	material.cull_mode=BaseMaterial3D.CULL_DISABLED
	material.roughness=1.0
	material.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	# Avoid triple color multiplication that made grass appear almost black.
	material.albedo_color=Color("c2c9ad")
	var groups: Array[Dictionary]=[
		{"name":"Meadow Tufts","n":13500,"tint":Color("929e79")},
		{"name":"Cool Bank Grasses","n":3500,"tint":Color("809781")},
		{"name":"Amber Ridge Grasses","n":2600,"tint":Color("a59e7d")}
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
			# No decorative grass may render through the cottage floor.
			var clear_spot: Vector2 = world.move_vegetation_outside_cottage(x,z)
			clear_spot = world.move_vegetation_outside_roadside(clear_spot.x,clear_spot.y)
			x = clear_spot.x
			z = clear_spot.y
			var base:=Basis(Vector3.UP,rng.randf_range(0,TAU))
			var s:=rng.randf_range(.58,1.20)
			base=base.scaled(Vector3(s,rng.randf_range(.66,1.15),s))
			mm.set_instance_transform(i,Transform3D(base,Vector3(x,world.height_at(x,z)+.017,z)))
			var c:Color=group["tint"]
			mm.set_instance_color(i,c.lerp(Color("5b7554"),rng.randf_range(.14,.54)))
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
	material.albedo_color=Color("8c8276")
	var mm:=MultiMesh.new();mm.transform_format=MultiMesh.TRANSFORM_3D
	mm.use_colors=true;mm.mesh=mesh;mm.instance_count=900
	var rng:=RandomNumberGenerator.new();rng.seed=1140
	for i in range(900):
		var stand: Vector2 = Vector2(22,-19) if rng.randf() < .47 else Vector2(40,20)
		var angle: float = rng.randf_range(0,TAU)
		var radius: float = sqrt(rng.randf())*13.0
		var x: float = stand.x + cos(angle)*radius
		var z: float = stand.y + sin(angle)*radius
		var clear_leaf: Vector2 = world.move_vegetation_outside_cottage(x,z)
		x = clear_leaf.x
		z = clear_leaf.y
		var size: float = rng.randf_range(.24,.59)
		var basis:=Basis(Vector3.UP,rng.randf_range(0,TAU)).scaled(Vector3.ONE*size)
		mm.set_instance_transform(i,Transform3D(basis,Vector3(x,world.height_at(x,z)+.015,z)))
		mm.set_instance_color(i,Color("827360").lerp(Color("665447"),rng.randf_range(.1,.75)))
	var n:=MultiMeshInstance3D.new()
	n.name="FallenIndividualLeaves"
	n.multimesh=mm
	n.material_override=material
	world.add_child(n)
