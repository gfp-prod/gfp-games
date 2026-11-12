extends RefCounted
## The village is connected by weatherworn pedestrian routes, not props placed
## in an isolated flat field. This is static visual dressing only; all original
## farm plots, jobs, pathfinding, finite inventories and physical worksites stay.
const ROUTES: Array[Dictionary]=[
	{"a":Vector2(5.3,20.5),"b":Vector2(8.9,16.25)},
	{"a":Vector2(8.9,16.25),"b":Vector2(21.8,19.1)},
	{"a":Vector2(21.8,19.1),"b":Vector2(18.0,27.0)}
]
const SEED: int=902711

static func _physical_clearance(p: Vector2) -> bool:
	# Paths can meet the workspace approaches, but must never put rocks
	# over the public counters, hot oven, smith's anvil or crop furrows.
	for site in [
		Vector2(8.9,16.25),Vector2(21.8,19.1),Vector2(5.3,20.5),
		Vector2(19.8,16.45),Vector2(6.7,13.7)
	]:
		if p.distance_to(site)<1.15:
			return false
	return true

static func _new_batch(root: Node3D, name: String, mesh: Mesh,
		material: Material, positions: Array[Transform3D],
		pigments: Array[Color]) -> MultiMeshInstance3D:
	var batch:=MultiMesh.new()
	batch.transform_format=MultiMesh.TRANSFORM_3D
	batch.use_colors=true
	batch.mesh=mesh
	batch.instance_count=positions.size()
	for i in range(positions.size()):
		batch.set_instance_transform(i,positions[i])
		batch.set_instance_color(i,pigments[i])
	var item:=MultiMeshInstance3D.new()
	item.name=name
	item.multimesh=batch
	item.material_override=material
	root.add_child(item)
	return item

static func build(world: Node3D, district: Node3D) -> void:
	if district.get_node_or_null("ArtDirectedVillageApproaches")!=null:
		return
	var root:=Node3D.new()
	root.name="ArtDirectedVillageApproaches"
	district.add_child(root)
	var rng:=RandomNumberGenerator.new()
	rng.seed=SEED
	var stone: StandardMaterial3D=world.textured(
		"res://assets/textures/real/stone_diffuse.jpg",Color("a39b8e"))
	stone.vertex_color_use_as_albedo=true
	stone.roughness=.98
	var earth: StandardMaterial3D=world.textured(
		"res://assets/textures/real/earth_path_diffuse.jpg",Color("7a7467"))
	earth.vertex_color_use_as_albedo=true
	earth.roughness=.99
	var cobble:=BoxMesh.new()
	cobble.size=Vector3.ONE
	var grit:=PlaneMesh.new()
	grit.size=Vector2.ONE
	var stone_poses: Array[Transform3D]=[]
	var stone_colors: Array[Color]=[]
	var soil_poses: Array[Transform3D]=[]
	var soil_colors: Array[Color]=[]
	for route in ROUTES:
		var a: Vector2=route["a"]
		var b: Vector2=route["b"]
		var vector: Vector2=b-a
		var tangent: Vector2=vector.normalized()
		var sideways:=Vector2(-tangent.y,tangent.x)
		var steps: int=ceili(vector.length()/.53)
		for step in range(steps):
			var fraction: float=(float(step)+.5)/float(steps)
			var center: Vector2=a.lerp(b,fraction)+sideways*rng.randf_range(-.13,.13)
			# Stone edges on either side of a distinct, softer central tread.
			for sign in [-1.0,1.0]:
				var p: Vector2=center+sideways*sign*rng.randf_range(.56,.84)
				p+=tangent*rng.randf_range(-.07,.07)
				if not _physical_clearance(p):
					continue
				var x_extent: float=rng.randf_range(.31,.47)
				var z_extent: float=rng.randf_range(.32,.50)
				var basis:=Basis(Vector3.UP,rng.randf_range(-.20,.20))
				basis=basis.scaled(Vector3(x_extent,rng.randf_range(.06,.13),z_extent))
				stone_poses.append(Transform3D(basis,
					Vector3(p.x,world.height_at(p.x,p.y)+.042,p.y)))
				stone_colors.append(Color("8d897e").lerp(
					Color("c0ba9f"),rng.randf_range(0.0,.24)))
			if step%2==0:
				var patch: Vector2=center+sideways*rng.randf_range(-.22,.22)
				if not _physical_clearance(patch):
					continue
				var basis:=Basis(Vector3.UP,tangent.angle()*.16).scaled(
					Vector3(rng.randf_range(.42,.69),1,rng.randf_range(.38,.65)))
				soil_poses.append(Transform3D(basis,
					Vector3(patch.x,world.height_at(patch.x,patch.y)+.033,patch.y)))
				soil_colors.append(Color("776c60").lerp(
					Color("a29782"),rng.randf_range(.0,.19)))
	var masonry:=_new_batch(root,"StaggeredSettledVillagePathStones",
		cobble,stone,stone_poses,stone_colors)
	_new_batch(root,"PackedEarthBetweenOldPaving",
		grit,earth,soil_poses,soil_colors)
	# Blacksmith's fire and bakery chimney produce distinctive soot stains.
	# These stay local to their cause instead of a generic grey-brown wash.
	var ash_poses: Array[Transform3D]=[]
	var ash_colors: Array[Color]=[]
	for site in [Vector2(21.8,19.1),Vector2(8.9,16.25)]:
		for i in range(28):
			var angle: float=rng.randf_range(0.0,TAU)
			var distance: float=rng.randf_range(1.45,2.82)
			var p: Vector2=site+Vector2(cos(angle),sin(angle))*distance
			if not _physical_clearance(p):
				continue
			var basis:=Basis(Vector3.UP,rng.randf_range(-PI,PI)).scaled(
				Vector3(rng.randf_range(.15,.60),1,rng.randf_range(.10,.53)))
			ash_poses.append(Transform3D(basis,
				Vector3(p.x,world.height_at(p.x,p.y)+.037,p.y)))
			ash_colors.append(Color("46423d") if site.x>15.0
				else Color("a49a84"))
	_new_batch(root,"WorkplaceSootAndFlourAtGroundLevel",
		grit,earth,ash_poses,ash_colors)
	root.set_meta("paving_stones",stone_poses.size())
	root.set_meta("ground_scars",soil_poses.size()+ash_poses.size())
	root.set_meta("simulation_or_collisions_modified",false)
