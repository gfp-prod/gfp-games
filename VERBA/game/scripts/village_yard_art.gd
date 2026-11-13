extends RefCounted
## Ground the two Blender homesteads in a lived-in landscape. Everything
## here is scenery: no StaticBody3D, pickups, crops, NPC jobs or save IDs.
## The real heightfield is sampled at every vertex and each plant base.
const ART=preload("res://scripts/art.gd")
const SEED: int=281107

static func _vertex(tool: SurfaceTool, point: Vector3, pigment: Color) -> void:
	tool.set_color(pigment)
	tool.set_uv(Vector2(point.x*.31,point.z*.31))
	tool.add_vertex(point)

static func _earth_stamp(tool: SurfaceTool, world: Node3D,
		center: Vector2, radius: Vector2, turn: float) -> void:
	# Two concentric, terrain-conforming rings soften each footprint. In
	# contrast to a rectangle, no hard edge floats on an uneven hillside.
	var middle: Array[Vector3]=[]
	var outside: Array[Vector3]=[]
	var count: int=16
	for i in range(count):
		var a: float=TAU*float(i)/float(count)
		var outline: float=1.0+.105*sin(a*3.0+turn)+.075*cos(a*5.0-turn)
		var arm:=Vector2(cos(a)*radius.x,sin(a)*radius.y).rotated(turn)*outline
		var core: Vector2=center+arm*.60
		var edge: Vector2=center+arm
		middle.append(Vector3(core.x,world.height_at(core.x,core.y)+.047,core.y))
		outside.append(Vector3(edge.x,world.height_at(edge.x,edge.y)+.045,edge.y))
	var center3:=Vector3(center.x,world.height_at(center.x,center.y)+.049,center.y)
	for i in range(count):
		var next: int=(i+1)%count
		# Winding faces upward: the ground decal receives actual daylight.
		_vertex(tool,center3,Color(1,1,1,.71))
		_vertex(tool,middle[next],Color(1,1,1,.51))
		_vertex(tool,middle[i],Color(1,1,1,.51))
		_vertex(tool,middle[i],Color(1,1,1,.51))
		_vertex(tool,middle[next],Color(1,1,1,.51))
		_vertex(tool,outside[i],Color(1,1,1,0))
		_vertex(tool,middle[next],Color(1,1,1,.51))
		_vertex(tool,outside[next],Color(1,1,1,0))
		_vertex(tool,outside[i],Color(1,1,1,0))

static func _ground_patches(world: Node3D, parent: Node3D,
		stamps: Array[Dictionary], name: String) -> void:
	var surface:=SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for stamp in stamps:
		_earth_stamp(surface,world,stamp["center"],stamp["radius"],
			float(stamp["turn"]))
	surface.generate_normals()
	var pigment: StandardMaterial3D=world.textured(
		"res://assets/textures/real/earth_path_diffuse.jpg",Color("9e9181"))
	pigment.vertex_color_use_as_albedo=true
	pigment.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	pigment.roughness=1.0
	pigment.depth_draw_mode=BaseMaterial3D.DEPTH_DRAW_OPAQUE_ONLY
	var cover:=MeshInstance3D.new()
	cover.name=name
	cover.mesh=surface.commit()
	cover.material_override=pigment
	parent.add_child(cover)
	cover.set_meta("terrain_conforming",true)

static func _leaf_mesh() -> ArrayMesh:
	# Small bent, actual leaf geometry. Muted, non-emissive and double sided.
	var tool:=SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for leaf in range(7):
		var angle: float=TAU*float(leaf)/7.0
		var direction:=Vector3(cos(angle),0,sin(angle))
		var across:=Vector3(-direction.z,0,direction.x)
		var height: float=.20+.055*float(leaf%3)
		var base:=Vector3(direction.x*.04,.018,direction.z*.04)
		var middle:=direction*.17+Vector3.UP*height
		var tip:=direction*(.34+.04*float(leaf%2))+Vector3.UP*(height*.40)
		var width: float=.067+.012*float(leaf%3)
		var p1: Vector3=middle-across*width
		var p2: Vector3=middle+across*width
		for triangle in [[base,p1,middle],[base,middle,p2],
				[p1,tip,middle],[middle,tip,p2]]:
			for point in triangle:
				tool.set_color(Color("a8b69b") if point==tip else Color("e1dac1"))
				tool.set_uv(Vector2(point.x*1.7,point.z*1.7))
				tool.add_vertex(point)
	tool.generate_normals()
	return tool.commit()

static func _batch_plants(world: Node3D, parent: Node3D,
		center: Vector2, garden: Vector2, rng: RandomNumberGenerator) -> int:
	var count: int=64
	var multimesh:=MultiMesh.new()
	multimesh.transform_format=MultiMesh.TRANSFORM_3D
	multimesh.use_colors=true
	multimesh.mesh=_leaf_mesh()
	multimesh.instance_count=count
	for i in range(count):
		var p: Vector2
		if i<44:
			# Garden has a grazed, imperfect edge, not a uniform crop grid.
			var a: float=rng.randf_range(0.0,TAU)
			var r: float=sqrt(rng.randf_range(.04,1.0))
			p=garden+Vector2(cos(a)*1.28,sin(a)*.87)*r
		else:
			# Individual weeds at the base of the house, away from the door.
			var side: float=-1.0 if i%2==0 else 1.0
			p=center+Vector2(side*rng.randf_range(2.95,3.68),
				rng.randf_range(-2.65,2.65))
		var size: float=rng.randf_range(.72,1.28)
		var basis:=Basis(Vector3.UP,rng.randf_range(0.0,TAU)).scaled(
			Vector3(size,size*rng.randf_range(.78,1.25),size))
		multimesh.set_instance_transform(i,Transform3D(basis,
			Vector3(p.x,world.height_at(p.x,p.y)+.032,p.y)))
		multimesh.set_instance_color(i,Color("69795e").lerp(
			Color("a19b73"),rng.randf_range(0.0,.39)))
	var greenery:=MultiMeshInstance3D.new()
	greenery.name="LowKitchenHerbsAndFoundationWeeds"
	greenery.multimesh=multimesh
	var leaf_material=ART.mat(Color("d9d8c6"),.98)
	leaf_material.vertex_color_use_as_albedo=true
	leaf_material.cull_mode=BaseMaterial3D.CULL_DISABLED
	greenery.material_override=leaf_material
	parent.add_child(greenery)
	return count

static func _batch_fieldstones(world: Node3D, parent: Node3D,
		garden: Vector2, rng: RandomNumberGenerator) -> int:
	var count: int=55
	var mesh:=SphereMesh.new()
	mesh.radius=.5
	mesh.height=1.0
	mesh.radial_segments=8
	mesh.rings=4
	var batch:=MultiMesh.new()
	batch.transform_format=MultiMesh.TRANSFORM_3D
	batch.use_colors=true
	batch.mesh=mesh
	batch.instance_count=count
	for i in range(count):
		var angle: float=TAU*float(i)/float(count)
		var spread: float=rng.randf_range(.96,1.06)
		var x: float=garden.x+cos(angle)*1.80*spread
		var z: float=garden.y+sin(angle)*1.30*spread
		var half_width: float=rng.randf_range(.115,.24)
		var size_y: float=rng.randf_range(.115,.21)
		var size_z: float=rng.randf_range(.15,.32)
		var basis:=Basis(Vector3.UP,rng.randf_range(-.3,.3)).scaled(
			Vector3(half_width*2.0,size_y*2.0,size_z*2.0))
		batch.set_instance_transform(i,Transform3D(basis,
			Vector3(x,world.height_at(x,z)+size_y*.34,z)))
		batch.set_instance_color(i,Color("82847c").lerp(Color("b0a792"),
			rng.randf_range(0.0,.38)))
	var edging:=MultiMeshInstance3D.new()
	edging.name="IrregularSettledDryStoneGardenEdging"
	edging.multimesh=batch
	var rock_material: StandardMaterial3D=world.textured(
		"res://assets/textures/cc0/polyhaven/mossy_rock_diffuse.png",
		Color("b5b0a6"))
	rock_material.vertex_color_use_as_albedo=true
	rock_material.roughness=.98
	edging.material_override=rock_material
	parent.add_child(edging)
	return count

static func _make_old_rail(world: Node3D, parent: Node3D,
		garden: Vector2, side: float) -> void:
	# A short, repaired rail is placed on the BACK of the kitchen plot.
	# It is not a solid fence around the door or a false navigation wall.
	var wood: Material=world.textured(
		"res://assets/textures/cc0/polyhaven/weathered_planks_diffuse.png",
		Color("776e5e"))
	var ends: Array[Vector2]=[
		garden+Vector2(-1.32,1.85),
		garden+Vector2(.03,1.89),
		garden+Vector2(1.31,1.83)
	]
	var tops: Array[Vector3]=[]
	for i in range(ends.size()):
		var p: Vector2=ends[i]
		var at:=Vector3(p.x,world.height_at(p.x,p.y),p.y)
		var height: float=.89-.13*float(i==1)
		ART.bone(parent,at+Vector3(0,.03,0),at+Vector3(0,height,0),
			.071,.052,wood,7)
		tops.append(at+Vector3(0,height-.19,0))
	# A missing rail section communicates wear rather than procedural noise.
	ART.bone(parent,tops[0],tops[1],.047,.040,wood,6)
	if side<0:
		ART.bone(parent,tops[1]-Vector3(0,.22,0),
			tops[2]-Vector3(0,.28,0),.042,.039,wood,6)

static func build(world: Node3D, homes: Node3D) -> void:
	if homes.get_node_or_null("VillageHomesteadGrounds")!=null:
		return
	var root:=Node3D.new()
	root.name="VillageHomesteadGrounds"
	homes.add_child(root)
	var site_index: int=0
	var total_stamps: int=0
	var total_herbs: int=0
	var total_stones: int=0
	for site in [
		{"name":"StonecutterDooryard","center":Vector2(-7.5,34.0),"side":-1.0},
		{"name":"MillwardDooryard","center":Vector2(30.0,33.5),"side":1.0}
	]:
		var center: Vector2=site["center"]
		var side: float=float(site["side"])
		var garden: Vector2=center+Vector2(side*5.36,.38)
		var yard:=Node3D.new()
		yard.name=String(site["name"])
		root.add_child(yard)
		var rng:=RandomNumberGenerator.new()
		rng.seed=SEED+site_index*179
		var patches: Array[Dictionary]=[]
		# Entrance trail bridges the established village stone route and
		# the true, collidable doorway. The house itself remains unaltered.
		for i in range(9):
			var t: float=float(i)/8.0
			patches.append({
				"center":Vector2(center.x+sin(t*PI)*.13,
					center.y-4.88+t*1.85),
				"radius":Vector2(.65+.12*sin(t*PI),.53),
				"turn":rng.randf_range(-.20,.20)
			})
		for i in range(10):
			var angle: float=TAU*float(i)/10.0
			patches.append({
				"center":garden+Vector2(cos(angle)*.63,sin(angle)*.36),
				"radius":Vector2(.70,.49),
				"turn":angle*.12
			})
		_ground_patches(world,yard,patches,"WornPhotographicEarthAtDoorsAndBeds")
		total_stamps+=patches.size()
		total_herbs+=_batch_plants(world,yard,center,garden,rng)
		total_stones+=_batch_fieldstones(world,yard,garden,rng)
		_make_old_rail(world,yard,garden,side)
		yard.set_meta("stamped_wear_patches",patches.size())
		yard.set_meta("pure_visual",true)
		site_index+=1
	root.set_meta("environmental_stamps",total_stamps)
	root.set_meta("small_vegetation_count",total_herbs)
	root.set_meta("garden_stone_count",total_stones)
	root.set_meta("new_simulation_entities",0)
	root.set_meta("save_id_changes",0)
	root.set_meta("decorative_only",true)
