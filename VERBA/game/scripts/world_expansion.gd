extends RefCounted
## The Outer Vale: additive, save-safe geography made of authored forms,
## shared weathered material families, bounded batches, and real collision.
## Nothing here allocates a SIM_OBJECT UID or changes existing citizen jobs.
const ART=preload("res://scripts/art.gd")
const REGIONS=preload("res://scripts/world_regions.gd")

static func build(world) -> void:
	var root:=Node3D.new()
	root.name="OuterValeRegionalLandmarks"
	world.add_child(root)
	_lake(world,root)
	_lake_road(world,root)
	_distant_landmarks(world,root)
	_remote_gravel(world,root)
	_remote_heath(world,root)

static func _place(world,point: Vector2) -> Vector3:
	return Vector3(point.x,world.height_at(point.x,point.y),point.y)

static func _physical(world,parent: Node3D,at: Vector3,ext: Vector3,
		surface: Material,label: String) -> void:
	ART.box(parent,at,ext,surface)
	world.add_solid_box(parent,at,ext,label)

static func _lake(world,root: Node3D) -> void:
	var water:=Node3D.new()
	water.name="StillwaterLake"
	root.add_child(water)
	var center: Vector2=REGIONS.LAKE
	var level: float=world.lake_water_level
	var st:=SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	const SEGMENTS: int=96
	for i in range(SEGMENTS):
		var a: float=TAU*float(i)/float(SEGMENTS)
		var b: float=TAU*float(i+1)/float(SEGMENTS)
		var p0: Vector2=Vector2(center.x+cos(a)*REGIONS.LAKE_RADII.x,
			center.y+sin(a)*REGIONS.LAKE_RADII.y)
		var p1: Vector2=Vector2(center.x+cos(b)*REGIONS.LAKE_RADII.x,
			center.y+sin(b)*REGIONS.LAKE_RADII.y)
		# Correct the radius to match the same irregular shore function
		# used for the physical basin and six-material ground shader.
		for j in range(6):
			var d0: float=REGIONS.lake_distance(p0.x,p0.y)
			var d1: float=REGIONS.lake_distance(p1.x,p1.y)
			p0=center+(p0-center)*clampf(1.0/maxf(.01,d0),.82,1.18)
			p1=center+(p1-center)*clampf(1.0/maxf(.01,d1),.82,1.18)
		for p in [p1,center,p0]:
			st.set_uv(Vector2((p.x-center.x)*.04,(p.y-center.y)*.04))
			st.add_vertex(Vector3(p.x,level,p.y))
	st.generate_normals()
	var surface:=MeshInstance3D.new()
	surface.name="RealLakeSurface"
	surface.mesh=st.commit()
	var water_mat:=ShaderMaterial.new()
	water_mat.shader=load("res://assets/materials/lake_water.gdshader")
	surface.material_override=water_mat
	water.add_child(surface)

	# Mooring pier on the western shore: proper walkable timber and posts.
	# The old river bridge still serves the old village, independently.
	var dock:=Node3D.new()
	dock.name="OldFishingJetty"
	dock.position=Vector3(center.x-REGIONS.LAKE_RADII.x-2.0,level+.61,center.y)
	water.add_child(dock)
	var plank: Material=world.textured("res://assets/textures/authored/weathered_oak.png",Color("756c58"))
	var pitch: Material=world.textured("res://assets/textures/bark.png",Color("50443b"))
	for i in range(13):
		var dx: float=float(i)*.70
		_physical(world,dock,Vector3(dx,-.08,0),Vector3(.63,.18,2.3),
			plank,"FishingJettyPlank_%d" % i)
		if i%3==0:
			for side in [-1.0,1.0]:
				ART.bone(dock,Vector3(dx,-1.75,side*1.0),
					Vector3(dx,.70,side*1.0),.11,.08,pitch,8)
	for x in [0.12,8.42]:
		ART.bone(dock,Vector3(x,.66,-1.02),Vector3(x,.66,1.02),.09,.09,pitch,8)
	# A flooded standing stone on a low island: not a quest marker.
	var isle:=Node3D.new()
	isle.name="TheHalfDrownedAltar"
	isle.position=Vector3(center.x+2.2,level-.9,center.y-1.8)
	water.add_child(isle)
	var stone: Material=world.textured("res://assets/textures/authored/wet_fieldstone.png",Color("696b63"))
	ART.stone(isle,Vector3.ZERO,Vector3(2.0,2.9,1.9),stone)
	ART.stone(isle,Vector3(.6,1.25,-.4),Vector3(.65,1.4,.56),stone)
	ART.bone(isle,Vector3(-.45,1.4,-.4),Vector3(.35,2.75,-.4),.20,.14,stone,7)
	_reed_beds(world,water)
	_shore_rock_batches(world,water)

static func _reed_beds(world,root: Node3D) -> void:
	var reed:=CylinderMesh.new()
	reed.top_radius=.007
	reed.bottom_radius=.026
	reed.height=1.0
	reed.radial_segments=5
	var moss:=ART.mat(Color("7e8970"),.97)
	var mm:=MultiMesh.new()
	mm.transform_format=MultiMesh.TRANSFORM_3D
	mm.use_colors=true
	mm.mesh=reed
	mm.instance_count=460
	var rng:=RandomNumberGenerator.new()
	rng.seed=715003
	for i in range(mm.instance_count):
		var angle: float=rng.randf_range(0.0,TAU)
		var spread: float=rng.randf_range(.92,1.19)
		var x: float=REGIONS.LAKE.x+cos(angle)*REGIONS.LAKE_RADII.x*spread
		var z: float=REGIONS.LAKE.y+sin(angle)*REGIONS.LAKE_RADII.y*spread
		var h: float=rng.randf_range(.60,1.7)
		var basis:=Basis(Vector3.UP,rng.randf_range(-.16,.16)).scaled(
			Vector3(rng.randf_range(.8,1.25),h,rng.randf_range(.8,1.25)))
		var y: float=maxf(world.height_at(x,z),world.lake_water_level-.5)
		mm.set_instance_transform(i,Transform3D(basis,Vector3(x,y+h*.43,z)))
		mm.set_instance_color(i,Color("7c886d").lerp(Color("b29b70"),
			rng.randf_range(.0,.80)))
	var stems:=MultiMeshInstance3D.new()
	stems.name="ReedsAlongIrregularLakeShore"
	stems.multimesh=mm
	stems.material_override=moss
	root.add_child(stems)

static func _shore_rock_batches(world,root: Node3D) -> void:
	var pebbles:=SphereMesh.new()
	pebbles.radial_segments=8
	pebbles.rings=4
	var mm:=MultiMesh.new()
	mm.transform_format=MultiMesh.TRANSFORM_3D
	mm.use_colors=true
	mm.mesh=pebbles
	mm.instance_count=720
	var rng:=RandomNumberGenerator.new()
	rng.seed=715127
	for i in range(mm.instance_count):
		var a: float=rng.randf_range(0.0,TAU)
		var radial: float=rng.randf_range(.92,1.55)
		var x: float=REGIONS.LAKE.x+cos(a)*REGIONS.LAKE_RADII.x*radial
		var z: float=REGIONS.LAKE.y+sin(a)*REGIONS.LAKE_RADII.y*radial
		var size: float=rng.randf_range(.05,.43)
		var basis:=Basis(Vector3.UP,rng.randf_range(0.0,TAU)).scaled(
			Vector3(size,size*rng.randf_range(.18,.36),size*rng.randf_range(.7,1.3)))
		mm.set_instance_transform(i,Transform3D(basis,Vector3(
			x,world.height_at(x,z)+.025,z)))
		mm.set_instance_color(i,Color("77766e").lerp(Color("9b8c78"),rng.randf()))
	var rocks:=MultiMeshInstance3D.new()
	rocks.name="SiltAndPebblesAtWaterline"
	rocks.multimesh=mm
	var material: StandardMaterial3D=world.textured("res://assets/textures/stone.png",Color("8d8b80"))
	material.vertex_color_use_as_albedo=true
	rocks.material_override=material
	root.add_child(rocks)

static func _lake_road(world,root: Node3D) -> void:
	# A route through real land, not a straight visual line across the lake.
	var route: Array[Vector2]=[
		Vector2(16,18),Vector2(27,3),Vector2(32,-16),Vector2(39,-32),
		Vector2(48,-44),Vector2(57,-56),Vector2(58.5,-60)]
	var gravel: Material=world.textured("res://assets/textures/earth_path.png",
		Color("8f8470"))
	var path:=Node3D.new()
	path.name="LongTrackToStillwater"
	root.add_child(path)
	_path(world,path,route,1.33,gravel)

static func _path(world,parent: Node3D,points: Array[Vector2],
		half_width: float,material: Material) -> void:
	var mesh:=SurfaceTool.new()
	mesh.begin(Mesh.PRIMITIVE_TRIANGLES)
	var progress: float=0.0
	for i in range(points.size()-1):
		var start: Vector2=points[i]
		var stop: Vector2=points[i+1]
		var distance: float=start.distance_to(stop)
		var steps: int=maxi(2,ceili(distance/1.10))
		var axis: Vector2=(stop-start).normalized()
		var normal: Vector2=Vector2(-axis.y,axis.x)
		for section in range(steps):
			var a: float=float(section)/float(steps)
			var b: float=float(section+1)/float(steps)
			var lo: Vector2=start.lerp(stop,a)
			var hi: Vector2=start.lerp(stop,b)
			var uv0: float=(progress+distance*a)*.24
			var uv1: float=(progress+distance*b)*.24
			var p0: Vector2=lo-normal*half_width
			var p1: Vector2=lo+normal*half_width
			var p2: Vector2=hi-normal*half_width
			var p3: Vector2=hi+normal*half_width
			for pair in [
				[p0,Vector2(0,uv0)],[p2,Vector2(0,uv1)],[p1,Vector2(1,uv0)],
				[p1,Vector2(1,uv0)],[p2,Vector2(0,uv1)],[p3,Vector2(1,uv1)]]:
				var p: Vector2=pair[0]
				mesh.set_uv(pair[1])
				mesh.add_vertex(Vector3(p.x,world.height_at(p.x,p.y)+.055,p.y))
		progress+=distance
	mesh.generate_normals()
	var road:=MeshInstance3D.new()
	road.name="RuttedWalkableFootpath"
	road.mesh=mesh.commit()
	road.material_override=material
	parent.add_child(road)

static func _distant_landmarks(world,root: Node3D) -> void:
	var wet_stone: StandardMaterial3D=world.textured("res://assets/textures/authored/wet_fieldstone.png",
		Color("817d73"))
	var oak: StandardMaterial3D=world.textured("res://assets/textures/authored/weathered_oak.png",Color("74604a"))
	var moss: StandardMaterial3D=world.textured("res://assets/textures/real/moss_diffuse.jpg",Color("72785f"))
	var iron:=ART.mat(Color("4d4f4b"),.86)
	# Ruined lakeside toll-post.
	var toll:=Node3D.new()
	toll.name="TumbledTollGate"
	toll.position=_place(world,Vector2(51.5,-47.5))
	root.add_child(toll)
	for side in [-1.0,1.0]:
		_physical(world,toll,Vector3(side*2.1,1.4,0),
			Vector3(.7,2.8,.95),wet_stone,"TollGatePillar")
	ART.bone(toll,Vector3(-2.2,2.94,0),
		Vector3(1.72,3.7,.30),.28,.22,oak,8)
	ART.stone(toll,Vector3(2.5,.32,1.3),Vector3(.95,.5,.85),wet_stone)
	# Isolated abandoned charcoal kiln in the dry forest.
	var kiln:=Node3D.new()
	kiln.name="ColdCharcoalKiln"
	kiln.position=_place(world,Vector2(50.0,-21.0))
	root.add_child(kiln)
	# Courses of irregular dressed masonry, broken at the firebox.
	# A single pristine cone looked like an impossible stone pyramid.
	var kiln_rubble:=Node3D.new()
	kiln_rubble.name="KilnCurvedBrickwork"
	kiln.add_child(kiln_rubble)
	for course in range(5):
		var radius: float=1.55-.13*float(course)
		for segment in range(10):
			if course<3 and segment==1: continue
			if course==4 and segment in [6,7]: continue
			var a: float=TAU*(float(segment)+.5*float(course%2))/10.0
			var yy: float=.24+float(course)*.43
			ART.box(kiln_rubble,Vector3(cos(a)*radius,yy,sin(a)*radius),
				Vector3(.95,.40,.48),wet_stone if segment%4!=0 else moss,
				Vector3(0,-a,0))
	_physical(world,kiln,Vector3(0,.45,0),Vector3(2.1,.9,2.1),
		wet_stone,"KilnFootprint")
	for j in range(6):
		var a: float=TAU*float(j)/6.0
		ART.stone(kiln,Vector3(cos(a)*2.25,.16,sin(a)*2.0),
			Vector3(.45,.3,.5),moss)
	# Animal blind overlooking the lake from the northern slopes.
	var blind:=Node3D.new()
	blind.name="OldHunterBlind"
	blind.position=_place(world,Vector2(83,-27))
	root.add_child(blind)
	for side in [-1.0,1.0]:
		for end in [-1.0,1.0]:
			ART.bone(blind,Vector3(side*.93,0,end*.71),
				Vector3(side*.93,3.25,end*.71),.14,.11,oak,8)
	_physical(world,blind,Vector3(0,2.1,0),Vector3(2.2,.17,1.8),
		oak,"HunterBlindDeck")
	ART.box(blind,Vector3(0,3.45,0),Vector3(2.65,.13,2.15),oak)
	for side in [-1.0,1.0]:
		ART.bone(blind,Vector3(side*.95,2.5,.8),
			Vector3(side*.95,3.37,.8),.09,.075,iron,7)
	# Stone circle north of the meadow; its geometry communicates distance.
	var circle:=Node3D.new()
	circle.name="SevenWeatheredWitnessStones"
	circle.position=_place(world,Vector2(76,49))
	root.add_child(circle)
	for i in range(7):
		var a: float=TAU*float(i)/7.0
		var x: float=cos(a)*4.8
		var z: float=sin(a)*4.8
		var height: float=1.6+float(i%3)*.34
		ART.stone(circle,Vector3(x,height*.46,z),
			Vector3(.78,height,.65),wet_stone)
		world.add_solid_box(circle,Vector3(x,height*.43,z),
			Vector3(.66,height*.85,.56),"WitnessStone_%d" % i)
	ART.stone(circle,Vector3(0,.24,0),Vector3(1.1,.36,.92),moss)
	# Old orchards, showing the aftermath of agriculture without another
	# arbitrary colored tree generator or a new ecological save state.
	var orchard:=Node3D.new()
	orchard.name="WindbrokenOrchard"
	root.add_child(orchard)
	for j in range(11):
		var x: float=96.0+float(j%4)*4.7+sin(float(j)*2.4)*.75
		var z: float=-8.0+float(j/4)*5.8
		var old:=Node3D.new()
		old.name="WeatherBrokenFruitTree_%d" % j
		old.position=_place(world,Vector2(x,z))
		orchard.add_child(old)
		ART.bone(old,Vector3.ZERO,Vector3(.2,3.5,0),.23,.13,oak,8)
		for branch in range(3):
			var a: float=TAU*float(branch)/3.0+float(j)*.22
			ART.bone(old,Vector3(.18,2.4,0),
				Vector3(cos(a)*1.30,3.85+sin(a)*.2,sin(a)*.9),
				.13,.035,oak,7)
	# A boundary marker at the old route, deliberately low and weathered.
	var mile:=Node3D.new()
	mile.name="LastMeasuredMileStone"
	mile.position=_place(world,Vector2(-80,74.5))
	root.add_child(mile)
	ART.stone(mile,Vector3(0,.77,0),Vector3(.71,1.52,.41),wet_stone)
	world.add_solid_box(mile,Vector3(0,.73,0),Vector3(.62,1.46,.38),
		"RoadMileStoneCollider")

static func _remote_gravel(world,root: Node3D) -> void:
	# Two deliberate dry gravel belts and one damp shoulder; one draw call.
	var mesh:=SphereMesh.new()
	mesh.radial_segments=6
	mesh.rings=4
	var mm:=MultiMesh.new()
	mm.transform_format=MultiMesh.TRANSFORM_3D
	mm.use_colors=true
	mm.mesh=mesh
	mm.instance_count=1300
	var rng:=RandomNumberGenerator.new()
	rng.seed=614728
	for i in range(mm.instance_count):
		var point: Vector2
		if i<470:
			point=Vector2(-97+rng.randf_range(-18,18),
				74+rng.randf_range(-23,20))
		elif i<860:
			point=Vector2(78+rng.randf_range(-27,27),
				-60+rng.randf_range(-27,27))
		else:
			point=Vector2(83+rng.randf_range(-29,31),
				23+rng.randf_range(-19,25))
		if REGIONS.is_lake_water(point.x,point.y):
			point+=Vector2(21,17)
		var size: float=rng.randf_range(.05,.32)
		var basis:=Basis(Vector3.UP,rng.randf_range(0.0,TAU)).scaled(
			Vector3(size,size*.16,size*.82))
		mm.set_instance_transform(i,Transform3D(basis,Vector3(point.x,
			world.height_at(point.x,point.y)+.016,point.y)))
		mm.set_instance_color(i,Color("8b857a").lerp(Color("5b645d"),rng.randf()))
	var pebbles:=MultiMeshInstance3D.new()
	pebbles.name="RegionalGravelDeposits"
	pebbles.multimesh=mm
	var surface: StandardMaterial3D=world.textured("res://assets/textures/stone.png",Color("b7afa0"))
	surface.vertex_color_use_as_albedo=true
	pebbles.material_override=surface
	root.add_child(pebbles)

static func _remote_heath(world,root: Node3D) -> void:
	# A few clean distant silhouettes rather than a blank new hundred metres.
	# Geometry is decorative; it cannot reorder existing saved tree IDs.
	var trunk: StandardMaterial3D=world.textured("res://assets/textures/bark.png",Color("554939"))
	var olive: StandardMaterial3D=world.textured("res://assets/textures/real/moss_diffuse.jpg",Color("68715b"))
	var rng:=RandomNumberGenerator.new()
	rng.seed=781933
	var stands: Array[Dictionary]=[
		{"point":Vector2(-109,49),"spread":19.0,"n":13},
		{"point":Vector2(83,23),"spread":22.0,"n":18},
		{"point":Vector2(112,-93),"spread":13.0,"n":12}
	]
	for stand in stands:
		var center: Vector2=stand["point"]
		for i in range(int(stand["n"])):
			var theta: float=rng.randf_range(0,TAU)
			var radius: float=sqrt(rng.randf())*float(stand["spread"])
			var x: float=center.x+cos(theta)*radius
			var z: float=center.y+sin(theta)*radius
			if absf(x)>=123 or absf(z)>=123 or REGIONS.lake_distance(x,z)<1.55:
				continue
			if Vector2(x,z).distance_to(REGIONS.STATION)<12:
				continue
			var place:=Node3D.new()
			place.name="SparseWindSculptedHeathTree"
			place.position=_place(world,Vector2(x,z))
			root.add_child(place)
			var height: float=rng.randf_range(3.8,6.7)
			ART.bone(place,Vector3.ZERO,Vector3(.24,height,0),
				.22,.11,trunk,7)
			for k in range(3):
				var angle: float=TAU*float(k)/3.0
				ART.bone(place,Vector3(.12,height*.58,0),
					Vector3(cos(angle)*1.45,height*.94,sin(angle)*1.2),
					.095,.028,trunk,7)
			if i%4==0:
				ART.stone(place,Vector3(.8,.18,.5),Vector3(.55,.32,.45),olive)
