extends RefCounted
## Hand-composed ecological passage from the hermit's cottage to Stillwater.
## Decoration is deterministic, offline and save-safe: no new SIM_OBJECT IDs,
## plants that can be harvested, NPC jobs, or quest state.
const ART=preload("res://scripts/art.gd")
const FOLIAGE=preload("res://scripts/foliage.gd")
const EXTERNAL_ART=preload("res://scripts/external_art.gd")
const TREE_PALETTE=preload("res://scripts/tree_palette.gd")
const REGIONS=preload("res://scripts/world_regions.gd")
const ROUTE: Array[Vector2]=[
	Vector2(27.8,10.7),Vector2(27.0,3.0),Vector2(32,-16),
	Vector2(39,-32),Vector2(48,-44),Vector2(57,-56),Vector2(58.5,-60)
]

static func build(world: Node3D) -> void:
	var root:=Node3D.new()
	root.name="HermitageToStillwaterArtPass"
	world.add_child(root)
	_rim_and_fallen_wood(world,root)
	_woodland_stands(world,root)
	_plant_understory(world,root)
	_mineral_shoulder(world,root)
	_pond_edge(world,root)
	root.set_meta("decoration_only",true)
	root.set_meta("tree_count",32)
	root.set_meta("route_end",REGIONS.LAKE)

static func _distance_to_track(point: Vector2) -> float:
	var nearest: float=INF
	for i in range(ROUTE.size()-1):
		var a: Vector2=ROUTE[i]
		var b: Vector2=ROUTE[i+1]
		var ab: Vector2=b-a
		var u: float=clampf((point-a).dot(ab)/maxf(ab.length_squared(),.001),0.0,1.0)
		nearest=minf(nearest,point.distance_to(a+ab*u))
	return nearest

static func _valid_ground(world: Node3D,x: float,z: float) -> bool:
	if absf(x)>121.0 or absf(z)>121.0:
		return false
	if world.is_inside_cottage_plot(x,z,2.4):
		return false
	if REGIONS.lake_distance(x,z)<1.02:
		return false
	if Vector2(x,z).distance_to(REGIONS.STATION)<15.0:
		return false
	return true

static func _rim_and_fallen_wood(world: Node3D,root: Node3D) -> void:
	# Cottage garden is ringed by weathered fieldstone, not an invisible
	# square fence. Broken courses reveal where a wall collapsed.
	var stones: Material=world.textured("res://assets/textures/real/stone_diffuse.jpg",Color("868477"))
	var lichen: Material=world.textured("res://assets/textures/real/moss_diffuse.jpg",Color("5b6b54"))
	var dark_oak: Material=world.textured("res://assets/textures/real/cottage_wood_diffuse.jpg",Color("66594a"))
	var cut: Material=world.textured("res://assets/textures/authored/weathered_oak.png",Color("8d7961"))
	var rng:=RandomNumberGenerator.new()
	rng.seed=17111983
	var dry_wall:=Node3D.new()
	dry_wall.name="BrokenHermitageFieldstoneGardenBoundary"
	root.add_child(dry_wall)
	# East boundary, clear of the known woodpile, the garden and front entry.
	for j in range(13):
		if j in [4,5,9]:
			continue
		var z: float=-.5+float(j)*1.27
		var x: float=39.2+sin(float(j)*.75)*.18
		for course in range(2):
			for k in range(3):
				var px: float=x+float(k-1)*.35+rng.randf_range(-.055,.055)
				var pz: float=z+rng.randf_range(-.12,.12)
				var h: float=.13+float(course)*.24
				ART.stone(dry_wall,Vector3(px,world.height_at(px,pz)+h,pz),
					Vector3(.36,.23,.37),lichen if j%4==0 and k==0 else stones)
	# A repaired rail and crooked gatepost at the approach fork.
	for z in [15.9,17.35]:
		var px: float=35.7
		var py: float=world.height_at(px,z)
		ART.bone(dry_wall,Vector3(px,py,z),Vector3(px+.06,py+1.55,z),.14,.12,dark_oak,8)
	ART.bone(dry_wall,Vector3(35.72,world.height_at(35.72,15.9)+1.29,15.9),
		Vector3(35.72,world.height_at(35.72,17.35)+1.19,17.35),.066,.052,dark_oak,8)
	# Single deliberate fallen timber on each side of the longer track;
	# keep a generous gap to the footpath and avoid fake collision.
	for pair in [
		{"p":Vector2(43,-26),"yaw":.43,"length":4.4},
		{"p":Vector2(54,-47),"yaw":-.78,"length":5.1},
		{"p":Vector2(21,-8),"yaw":.95,"length":3.2}
	]:
		var at: Vector2=pair["p"]
		if _distance_to_track(at)<4.2:
			continue
		var fallen:=Node3D.new()
		fallen.name="WeatheredOakTrunkAndExposedRoots"
		fallen.position=Vector3(at.x,world.height_at(at.x,at.y)+.20,at.y)
		fallen.rotation.y=float(pair["yaw"])
		root.add_child(fallen)
		var length: float=pair["length"]
		ART.bone(fallen,Vector3(-length*.5,0,0),Vector3(length*.5,0,0),
			.30,.20,dark_oak,11)
		for end in [-1.0,1.0]:
			var point:=Vector3(end*length*.5,0,0)
			ART.orb(fallen,point,Vector3(.07,.17,.17),cut,10)
			for k in range(4):
				var angle: float=TAU*float(k)/4.0+float(end)*.27
				ART.bone(fallen,point,point+Vector3(end*.38,0.0,
					cos(angle)*.41),.105,.028,dark_oak,7)
		world.add_solid_box(fallen,Vector3.ZERO,Vector3(length,.36,.45),
			"WalkableFallenTimberCollision")

static func _woodland_stands(world: Node3D,root: Node3D) -> void:
	var rng:=RandomNumberGenerator.new()
	rng.seed=483128
	var woodland:=Node3D.new()
	woodland.name="VariedTreeEdgeAndSmallGroves"
	root.add_child(woodland)
	var count: int=0
	# The route crosses meadow, dense oak/birch margins, then sparse lake
	# trees. Not a tree every meter or a straight row of identical trunks.
	var belts: Array[Dictionary]=[
		{"center":Vector2(29,-5),"radius":12.0,"n":12,"species":"birch"},
		{"center":Vector2(41,-27),"radius":17.0,"n":11,"species":"maple"},
		{"center":Vector2(53,-46),"radius":12.0,"n":9,"species":"birch"}
	]
	for belt in belts:
		var middle: Vector2=belt["center"]
		for i in range(int(belt["n"])):
			var p: Vector2=middle
			for attempt in range(25):
				var angle: float=rng.randf_range(0.0,TAU)
				var distance: float=sqrt(rng.randf())*float(belt["radius"])
				p=middle+Vector2(cos(angle),sin(angle))*distance
				if _valid_ground(world,p.x,p.y) and _distance_to_track(p)>6.0:
					break
			if not _valid_ground(world,p.x,p.y) or _distance_to_track(p)<6.0:
				continue
			var node:=Node3D.new()
			node.name="UnharvestableSilhouetteTree_%02d" % count
			node.position=Vector3(p.x,world.height_at(p.x,p.y),p.y)
			node.rotation.y=rng.randf_range(0.0,TAU)
			woodland.add_child(node)
			var is_maple: bool=String(belt["species"])=="maple"
			var variant: int=rng.randi_range(0,2)
			var name: String=("MapleTree_%d.gltf" if is_maple else "BirchTree_%d.gltf") % ([1,2,3][variant] if is_maple else [1,3,1][variant])
			var imported: bool=EXTERNAL_ART.attach_scaled(node,
				"res://assets/models/cc0/nature/"+name,
				rng.randf_range(6.0,8.0) if is_maple else rng.randf_range(5.5,7.6))
			if not imported:
				node.queue_free()
				continue
			TREE_PALETTE.dress_tree(node.get_node("CC0ImportedArt"),
				"autumn" if is_maple else "broadleaf",variant)
			# This is scenery, but trunks are tangible from a first-person
			# camera. No new sim entities, flora IDs or harvest resources.
			world.add_solid_box(node,Vector3(0,1.8,0),
				Vector3(.47,3.6,.47),"PhysicalLandscapeTreeTrunk")
			count+=1
	woodland.set_meta("imported_tree_count",count)

static func _plant_understory(world: Node3D,root: Node3D) -> void:
	var fern: ArrayMesh=FOLIAGE.make_fern_mesh()
	var grass: ArrayMesh=FOLIAGE.grass_mesh()
	var mat:=StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo=true
	mat.albedo_color=Color("a8aa94")
	mat.cull_mode=BaseMaterial3D.CULL_DISABLED
	mat.roughness=.99
	var rng:=RandomNumberGenerator.new()
	rng.seed=481932
	# Plant ecology follows the passage's moisture and tree cover.
	var stations: Array[Dictionary]=[
		{"center":Vector2(29,-3),"radius":14.0,"count":440,"name":"CottageFernEdge","tone":Color("586a54")},
		{"center":Vector2(43,-29),"radius":20.0,"count":700,"name":"ShadedForestUnderstory","tone":Color("596d62")},
		{"center":Vector2(56,-48),"radius":13.0,"count":650,"name":"LakeMarginTussocks","tone":Color("73816b")}
	]
	for station in stations:
		var m:=MultiMesh.new()
		m.transform_format=MultiMesh.TRANSFORM_3D
		m.use_colors=true
		m.mesh=fern if String(station["name"])!="LakeMarginTussocks" else grass
		m.instance_count=int(station["count"])
		var center: Vector2=station["center"]
		for i in range(m.instance_count):
			var p: Vector2=center
			for attempt in range(15):
				var a: float=rng.randf_range(0.0,TAU)
				var radius: float=sqrt(rng.randf())*float(station["radius"])
				p=center+Vector2(cos(a),sin(a))*radius
				if _valid_ground(world,p.x,p.y) and _distance_to_track(p)>1.75:
					break
			if not _valid_ground(world,p.x,p.y) or _distance_to_track(p)<1.75:
				p=Vector2(43,-19) # never place shrubs inside cottage / lake
			var size: float=rng.randf_range(.43,.91)
			var angle: float=rng.randf_range(0,TAU)
			var basis:=Basis(Vector3.UP,angle).scaled(Vector3(size,
				size*rng.randf_range(.53,1.12),size))
			m.set_instance_transform(i,Transform3D(basis,
				Vector3(p.x,world.height_at(p.x,p.y)+.025,p.y)))
			var tone: Color=station["tone"]
			m.set_instance_color(i,tone.lerp(Color("a59b7b"),rng.randf_range(.0,.25)))
		var cluster:=MultiMeshInstance3D.new()
		cluster.name=String(station["name"])
		cluster.multimesh=m
		cluster.material_override=mat
		root.add_child(cluster)

static func _mineral_shoulder(world: Node3D,root: Node3D) -> void:
	var pebble:=SphereMesh.new()
	pebble.radial_segments=7
	pebble.rings=4
	var material:=world.textured("res://assets/textures/real/stone_diffuse.jpg",Color("99958b"))
	material.vertex_color_use_as_albedo=true
	var mm:=MultiMesh.new()
	mm.transform_format=MultiMesh.TRANSFORM_3D
	mm.use_colors=true
	mm.mesh=pebble
	mm.instance_count=1250
	var rng:=RandomNumberGenerator.new()
	rng.seed=914213
	for i in range(mm.instance_count):
		var start: Vector2=ROUTE[rng.randi_range(0,ROUTE.size()-2)]
		var stop: Vector2=ROUTE[ROUTE.find(start)+1]
		var mid: Vector2=start.lerp(stop,rng.randf())
		var tangent: Vector2=(stop-start).normalized()
		var side: Vector2=Vector2(-tangent.y,tangent.x)
		var p: Vector2=mid+side*rng.randf_range(1.65,5.4)*(-1.0 if rng.randf()<.5 else 1.0)
		if not _valid_ground(world,p.x,p.y):
			p=Vector2(41,-25)
		var radius: float=rng.randf_range(.085,.35)
		var basis:=Basis(Vector3.UP,rng.randf_range(0,TAU)).scaled(
			Vector3(radius,radius*rng.randf_range(.10,.25),
				radius*rng.randf_range(.82,1.45)))
		mm.set_instance_transform(i,Transform3D(basis,
			Vector3(p.x,world.height_at(p.x,p.y)+.022,p.y)))
		mm.set_instance_color(i,Color("615d55").lerp(Color("aca08d"),rng.randf_range(.0,.60)))
	var stones:=MultiMeshInstance3D.new()
	stones.name="RuttedTrackPebbleAndGravelMargins"
	stones.multimesh=mm
	stones.material_override=material
	root.add_child(stones)

static func _pond_edge(world: Node3D,root: Node3D) -> void:
	var rng:=RandomNumberGenerator.new()
	rng.seed=225704
	var moss:=world.textured("res://assets/textures/real/moss_diffuse.jpg",Color("6c806c"))
	moss.vertex_color_use_as_albedo=true
	var mesh:=SphereMesh.new()
	mesh.radial_segments=8
	mesh.rings=4
	var mm:=MultiMesh.new()
	mm.transform_format=MultiMesh.TRANSFORM_3D
	mm.use_colors=true
	mm.mesh=mesh
	mm.instance_count=440
	for i in range(mm.instance_count):
		var a: float=rng.randf_range(0,TAU)
		# Concentrate the work on the west/near shore. The far reeds already
		# have their own visual ecology.
		if i%4!=0:a=rng.randf_range(PI*.76,PI*1.25)
		var radius: float=rng.randf_range(1.03,1.30)
		var p:=Vector2(REGIONS.LAKE.x+cos(a)*REGIONS.LAKE_RADII.x*radius,
			REGIONS.LAKE.y+sin(a)*REGIONS.LAKE_RADII.y*radius)
		var diameter: float=rng.randf_range(.31,.92)
		var basis:=Basis(Vector3.UP,rng.randf_range(0,TAU)).scaled(Vector3(
			diameter*rng.randf_range(.7,1.8),rng.randf_range(.024,.065),
			diameter*rng.randf_range(.7,1.7)))
		mm.set_instance_transform(i,Transform3D(basis,
			Vector3(p.x,world.height_at(p.x,p.y)+.024,p.y)))
		mm.set_instance_color(i,Color("5b6855").lerp(Color("979781"),rng.randf_range(0,.43)))
	var damp:=MultiMeshInstance3D.new()
	damp.name="UnevenWetMossAndSiltShore"
	damp.multimesh=mm
	damp.material_override=moss
	root.add_child(damp)
