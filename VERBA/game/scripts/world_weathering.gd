extends RefCounted
## Designed weathering; the geography reflects use, abandonment and water.
## Decorative additions do not create flora, ecological save IDs or missions.
const ART=preload("res://scripts/art.gd")
const ROAD=preload("res://scripts/strange_road.gd")
const REGIONS=preload("res://scripts/world_regions.gd")
const FOLIAGE=preload("res://scripts/foliage.gd")

static func build(world) -> void:
	var root:=Node3D.new()
	root.name="WeatheredWorldHistory"
	world.add_child(root)
	_region_cover(world,root)
	_station(world,root)
	_old_road(world,root)
	_stillwater(world,root)
	_orchard(world,root)
	_forgotten_ruins(world,root)

static func _stone_mat(world, tint: Color) -> StandardMaterial3D:
	return world.textured("res://assets/textures/real/stone_diffuse.jpg",tint)

static func _wood_mat(world, tint: Color) -> StandardMaterial3D:
	return world.textured("res://assets/textures/authored/weathered_oak.png",tint)

static func _at(world, pos: Vector2) -> Vector3:
	return Vector3(pos.x,world.height_at(pos.x,pos.y),pos.y)

static func _region_cover(world,root: Node3D) -> void:
	# The old grass generator covered only the central 138 m square.
	# These deterministic, batched clumps give the expanded Outer Vale
	# regional ecology without touching the persistent living-flora IDs.
	var grass_mesh: ArrayMesh=FOLIAGE.grass_mesh()
	var mat:=StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo=true
	mat.cull_mode=BaseMaterial3D.CULL_DISABLED
	mat.roughness=.99
	mat.albedo_color=Color("c6c3b1")
	var groups: Array[Dictionary]=[
		{"id":"LakeSedges","center":Vector2(79,-60),"radius":34.0,
		 "count":3400,"tone":Color("738578")},
		{"id":"OldRoadHeather","center":Vector2(-96,66),"radius":34.0,
		 "count":2900,"tone":Color("827961")},
		{"id":"WitnessMeadow","center":Vector2(78,39),"radius":38.0,
		 "count":3200,"tone":Color("8a8c6d")},
		{"id":"OrchardThistle","center":Vector2(103,-11),"radius":28.0,
		 "count":2600,"tone":Color("968365")}
	]
	for group in groups:
		var rng:=RandomNumberGenerator.new()
		rng.seed=810139+int(group["count"])
		var mm:=MultiMesh.new()
		mm.transform_format=MultiMesh.TRANSFORM_3D
		mm.use_colors=true
		mm.mesh=grass_mesh
		mm.instance_count=int(group["count"])
		for i in range(mm.instance_count):
			var x: float=0.0
			var z: float=0.0
			var center: Vector2=group["center"]
			for attempts in range(18):
				var theta: float=rng.randf_range(0,TAU)
				var radius: float=sqrt(rng.randf())*float(group["radius"])
				x=center.x+cos(theta)*radius
				z=center.y+sin(theta)*radius
				if absf(x)>123 or absf(z)>123: continue
				if REGIONS.is_lake_water(x,z): continue
				if Vector2(x,z).distance_to(REGIONS.STATION)<12.0: continue
				break
			var scale: float=rng.randf_range(.40,.94)
			var basis:=Basis(Vector3.UP,rng.randf_range(0,TAU)).scaled(
				Vector3(scale,rng.randf_range(.45,1.30),scale))
			mm.set_instance_transform(i,Transform3D(basis,
				Vector3(x,world.height_at(x,z)+.017,z)))
			var tone: Color=group["tone"]
			mm.set_instance_color(i,tone.lerp(
				Color("c2b59a"),rng.randf_range(.0,.27)))
		var clumps:=MultiMeshInstance3D.new()
		clumps.name=String(group["id"])
		clumps.multimesh=mm
		clumps.material_override=mat
		root.add_child(clumps)

static func _station(world,root: Node3D) -> void:
	var site: Node3D=world.get_node_or_null("StrangeRoadDistrict/ValeFuelStation")
	if site==null:
		return
	var grime:=Node3D.new()
	grime.name="WeatheredForecourtHistory"
	site.add_child(grime)
	var tar:=ART.mat(Color("292e2b"),.99)
	var rust:=ART.mat(Color("6a4c3c"),.95)
	var dull_steel:=ART.mat(Color("414646"),.93)
	var sickly_moss:=ART.mat(Color("68715e"),.98)
	var pale:=_stone_mat(world,Color("7d7466"))
	var cabin_wood:=_wood_mat(world,Color("68584a"))
	var rng:=RandomNumberGenerator.new()
	rng.seed=496013
	# Thin misaligned fissures cross the actual walkable concrete, not a
	# decal plane covering the entrance or another invisible collider.
	for i in range(39):
		var x: float=rng.randf_range(-3.2,9.0)
		var z: float=rng.randf_range(-4.1,4.1)
		var a: Vector3=Vector3(x,.126,z)
		var b: Vector3=a+Vector3(rng.randf_range(-.70,.90),0,rng.randf_range(.23,.87))
		ART.bone(grime,a,b,.016,.008,tar,5)
		if i%3==0:
			ART.bone(grime,b,b+Vector3(rng.randf_range(-.27,.42),0,
				rng.randf_range(.20,.56)),.011,.004,tar,5)
		if i%4==0:
			# A small tuft actually rises through the crack.
			for leaf in range(3):
				var h: float=rng.randf_range(.10,.28)
				ART.bone(grime,b, b+Vector3(rng.randf_range(-.13,.13),h,
					rng.randf_range(-.13,.13)),.013,.003,sickly_moss,5)
	# Stains gather around the pumps and the drainage side of the apron.
	for i in range(14):
		var pos:=Vector3(rng.randf_range(2.0,7.4),.113,
			rng.randf_range(-3.3,3.3))
		var size: float=rng.randf_range(.17,.53)
		ART.orb(grime,pos,Vector3(size,.006,size*rng.randf_range(.6,1.5)),tar,10)
	# Rust at standing seams, not every surface painted orange.
	for z in [-4.17,4.17]:
		ART.box(grime,Vector3(5.0,4.29,z),Vector3(6.6,.035,.10),rust)
		ART.bone(grime,Vector3(6.68,3.17,z),Vector3(6.68,4.05,z),
			.030,.024,rust,7)
	for z in [-3.52,3.52]:
		ART.box(grime,Vector3(6.68,.25,z),Vector3(.53,.19,.56),rust)
	# Peeling paint and slow seepage under the shop windows.
	for z in [-2.22,2.21]:
		for i in range(5):
			var yy: float=.45+float(i)*.36
			var dz: float=z+rng.randf_range(-.36,.36)
			ART.box(grime,Vector3(1.69,yy,dz),Vector3(.016,.08,.20),
				pale if i%2==0 else rust)
	# A folded, broken guardrail and weathered shopping crates to give
	# the place a lived-in scale; neither seals the real doorway.
	for i in range(5):
		var z: float=-4.4+float(i)*.43
		ART.box(grime,Vector3(-5.88,.18,z),Vector3(.38,.26,.29),
			cabin_wood,Vector3(0,rng.randf_range(-.21,.18),0))
	# An abandoned, damaged small delivery vehicle outside the footpath.
	var wreck:=Node3D.new()
	wreck.name="RustingDeliveryWreck"
	var gx: float=9.0
	var gz: float=5.1
	wreck.position=Vector3(gx,
		world.height_at(site.global_position.x+gx,site.global_position.z+gz)-
			site.global_position.y+.10,gz)
	grime.add_child(wreck)
	ART.box(wreck,Vector3(0,.58,0),Vector3(2.95,.58,1.48),rust)
	ART.box(wreck,Vector3(-.64,1.07,0),Vector3(1.42,.57,1.26),dull_steel)
	ART.box(wreck,Vector3(-1.37,.66,0),Vector3(.12,.39,1.40),cabin_wood)
	ART.box(wreck,Vector3(.35,.90,-.76),Vector3(.90,.022,.14),pale)
	for x in [-.95,.97]:
		for z in [-.78,.78]:
			var tire:=CylinderMesh.new()
			tire.top_radius=.41
			tire.bottom_radius=.42
			tire.height=.16
			tire.radial_segments=12
			var wheel:=MeshInstance3D.new()
			wheel.name="AbandonedRubberWheel"
			wheel.mesh=tire
			wheel.material_override=tar
			wheel.rotation_degrees.z=90
			wheel.position=Vector3(x,.35,z)
			wreck.add_child(wheel)
			ART.orb(wreck,Vector3(x,.35,z*1.07),Vector3(.14,.14,.05),
				dull_steel,7)

static func _old_road(world,root: Node3D) -> void:
	var history:=Node3D.new()
	history.name="OldRoadShouldersAndBoundaryFence"
	root.add_child(history)
	var gravel:=_stone_mat(world,Color("8c8270"))
	var old_wood:=_wood_mat(world,Color("605142"))
	var iron:=ART.mat(Color("53544f"),.92)
	var moss:=ART.mat(Color("65735b"),.97)
	var rng:=RandomNumberGenerator.new()
	rng.seed=290144
	var points: Array[Vector2]=ROAD.station_route()
	# Single batched rock/pebble draw call for the entire long road.
	var mesh:=SphereMesh.new()
	mesh.radial_segments=7
	mesh.rings=4
	var mm:=MultiMesh.new()
	mm.transform_format=MultiMesh.TRANSFORM_3D
	mm.use_colors=true
	mm.mesh=mesh
	mm.instance_count=700
	var positions: Array[Vector2]=[]
	for i in range(points.size()-1):
		var delta: Vector2=points[i+1]-points[i]
		var length: int=maxi(2,ceili(delta.length()))
		var normal:=Vector2(-delta.y,delta.x).normalized()
		for j in range(length):
			var t: float=(float(j)+.5)/float(length)
			var point: Vector2=points[i].lerp(points[i+1],t)
			for side in [-1.0,1.0]:
				positions.append(point+normal*side*rng.randf_range(1.52,2.8))
	for i in range(mm.instance_count):
		var point: Vector2=positions[rng.randi_range(0,positions.size()-1)]
		point+=Vector2(rng.randf_range(-.36,.36),rng.randf_range(-.36,.36))
		var size: float=rng.randf_range(.07,.45)
		mm.set_instance_transform(i,Transform3D(
			Basis(Vector3.UP,rng.randf_range(0,TAU)).scaled(
				Vector3(size,size*rng.randf_range(.10,.27),size*rng.randf_range(.6,1.5))),
			_at(world,point)+Vector3.UP*.02))
		mm.set_instance_color(i,Color("736f65").lerp(Color("a0937a"),rng.randf()))
	var deposits:=MultiMeshInstance3D.new()
	deposits.name="CrushedRoadShoulderStone"
	deposits.multimesh=mm
	gravel.vertex_color_use_as_albedo=true
	deposits.material_override=gravel
	history.add_child(deposits)
	# A few segments of degraded boundary fence, not regular decorative
	# triangles placed every meter on a perfect road.
	for i in [1,3]:
		var a: Vector2=points[i]
		var b: Vector2=points[i+1]
		var axis: Vector2=(b-a).normalized()
		var normal: Vector2=Vector2(-axis.y,axis.x)
		for k in range(4):
			var at: Vector2=a.lerp(b,.18+float(k)*.14)+normal*2.75
			var top: Vector3=_at(world,at)+Vector3.UP*(1.15 if k!=2 else .69)
			ART.bone(history,_at(world,at),top,.11,.08,old_wood,6)
			if k>0:
				var prev: Vector2=a.lerp(b,.18+float(k-1)*.14)+normal*2.75
				ART.bone(history,_at(world,prev)+Vector3.UP*.89,
					_at(world,at)+Vector3.UP*(.89 if k!=2 else .46),
					.07,.05,old_wood if k%2 else iron,6)
	# A single broken road marker fallen into the gravel.
	var sign_at: Vector2=Vector2(-86.5,69.2)
	var base: Vector3=_at(world,sign_at)
	ART.bone(history,base,base+Vector3(.96,.21,-.25),.08,.055,iron,7)
	ART.box(history,base+Vector3(1.15,.19,-.29),Vector3(.76,.32,.09),gravel)

static func _stillwater(world,root: Node3D) -> void:
	var bank:=Node3D.new()
	bank.name="StillwaterDriftwoodAndSedge"
	root.add_child(bank)
	var wood:=_wood_mat(world,Color("615b4d"))
	var bark: StandardMaterial3D=world.textured("res://assets/textures/bark.png",Color("5b5649"))
	var stone:=_stone_mat(world,Color("868274"))
	var brown:=ART.mat(Color("77664d"),.99)
	var rng:=RandomNumberGenerator.new()
	rng.seed=811053
	for i in range(24):
		var theta: float=rng.randf_range(0,TAU)
		var radial: float=rng.randf_range(1.10,1.47)
		var p:=Vector2(REGIONS.LAKE.x+cos(theta)*REGIONS.LAKE_RADII.x*radial,
			REGIONS.LAKE.y+sin(theta)*REGIONS.LAKE_RADII.y*radial)
		var origin: Vector3=_at(world,p)
		var size: float=rng.randf_range(.8,2.2)
		var direction:=Vector3(cos(theta+.90),0,sin(theta+.90))*size
		ART.bone(bank,origin+Vector3.UP*.10,origin+direction+Vector3.UP*.07,
			.13,.035,wood if i%3 else bark,7)
		if i%4==0:
			ART.stone(bank,origin+Vector3(rng.randf_range(-1,1),.04,
				rng.randf_range(-1,1)),Vector3(.64,.19,.53),stone)
		if i%5==0:
			for blade in range(6):
				var lean: float=rng.randf_range(-.25,.25)
				ART.bone(bank,origin,origin+Vector3(lean,
					rng.randf_range(.6,1.3),rng.randf_range(-.28,.28)),
					.016,.003,brown,5)
	# A broken mooring post, rope and leaf litter on the dock's seaward
	# end. The original timber collider remains the only walk surface.
	var lake: Node3D=world.get_node_or_null("OuterValeRegionalLandmarks/StillwaterLake")
	if lake!=null:
		var post:=Node3D.new()
		post.name="AbandonedMooring"
		post.position=Vector3(REGIONS.LAKE.x-REGIONS.LAKE_RADII.x+4,
			world.lake_water_level+.52,REGIONS.LAKE.y)
		lake.add_child(post)
		ART.bone(post,Vector3(0,-1.8,-.75),Vector3(.15,.75,-.75),
			.15,.09,bark,8)
		ART.bone(post,Vector3(.15,.55,-.75),Vector3(1,.20,-.55),
			.025,.022,brown,6)

static func _orchard(world,root: Node3D) -> void:
	var orchard: Node3D=world.get_node_or_null(
		"OuterValeRegionalLandmarks/WindbrokenOrchard")
	if orchard==null: return
	var oak:=_wood_mat(world,Color("605443"))
	var fruit:=ART.mat(Color("6c5b49"),.98)
	var rng:=RandomNumberGenerator.new()
	rng.seed=89410
	for j in range(11):
		var tree: Node3D=orchard.get_node_or_null("WeatherBrokenFruitTree_%d" % j)
		if tree==null: continue
		if j in [1,3,7,9]:
			# A few surviving crowns imply a working orchard slowly dying,
			# not identical skeletal Y sticks repeated on a green field.
			var ends: Array=[
				Vector3(.70,3.6,.28),Vector3(-1.12,3.4,.35),
				Vector3(.35,3.90,-.9)]
			FOLIAGE.make_broadleaf_crown(tree,ends,"autumn",8201+j)
		for k in range(3):
			var offset:=Vector3(rng.randf_range(-1.2,1.2),.08,
				rng.randf_range(-.9,.9))
			ART.orb(tree,offset,Vector3(.07,.058,.066),fruit,7)
	# Ruined cultivation is visible from the path at close range.
	var fence:=Node3D.new()
	fence.name="CollapsedOrchardFence"
	orchard.add_child(fence)
	for k in range(6):
		var pos:=Vector2(92.5+float(k)*3.4,1.8)
		ART.bone(fence,_at(world,pos),_at(world,pos)+Vector3(0,.85,0),
			.10,.065,oak,7)
		if k<5 and k!=2:
			ART.bone(fence,_at(world,pos)+Vector3.UP*.65,
				_at(world,Vector2(pos.x+3.4,pos.y))+Vector3.UP*.55,
				.065,.045,oak,7)
	var crate:=Node3D.new()
	crate.name="FallenProduceCrates"
	crate.position=_at(world,Vector2(101,0))
	orchard.add_child(crate)
	for k in range(2):
		ART.box(crate,Vector3(float(k)*.9,.21,0),
			Vector3(.71,.41,.55),oak,Vector3(.1,float(k)*.65,.03))

static func _forgotten_ruins(world,root: Node3D) -> void:
	var landmarks: Node3D=world.get_node_or_null("OuterValeRegionalLandmarks")
	if landmarks==null: return
	var stone:=_stone_mat(world,Color("928d7b"))
	var charcoal:=ART.mat(Color("333431"),.99)
	var lichen: StandardMaterial3D=world.textured("res://assets/textures/real/moss_diffuse.jpg",Color("69715a"))
	var oak:=_wood_mat(world,Color("615645"))
	var toll: Node3D=landmarks.get_node_or_null("TumbledTollGate")
	if toll!=null:
		var left:=Node3D.new()
		left.name="MasonryCoursesAndCollapsedLintel"
		toll.add_child(left)
		for side in [-1.0,1.0]:
			for j in range(4):
				var y: float=.30+float(j)*.63
				ART.box(left,Vector3(side*2.1,y,0),
					Vector3(.90,.49,.84),stone,Vector3(0,.05*float(j)*side,0))
				if j%2==0:
					ART.box(left,Vector3(side*2.09,y+.22,-.445),
						Vector3(.42,.09,.06),lichen)
		ART.box(left,Vector3(.55,.16,1.45),
			Vector3(1.18,.26,.65),stone,Vector3(.12,.34,.08))
	var kiln: Node3D=landmarks.get_node_or_null("ColdCharcoalKiln")
	if kiln!=null:
		var ash:=Node3D.new()
		ash.name="AbandonedFireboxAndAsh"
		kiln.add_child(ash)
		for i in range(10):
			var a: float=TAU*float(i)/10.0
			var x: float=cos(a)*2.45
			var z: float=sin(a)*2.25
			ART.stone(ash,Vector3(x,.16,z),Vector3(.39,.27,.36),
				charcoal if i%3 else stone)
		ART.box(ash,Vector3(0,.07,-1.72),Vector3(.95,.14,.58),charcoal)
	var blind: Node3D=landmarks.get_node_or_null("OldHunterBlind")
	if blind!=null:
		var shelter:=Node3D.new()
		shelter.name="WeatheredRailingAndTornShelter"
		blind.add_child(shelter)
		var top: float=3.45
		ART.box(shelter,Vector3(.25,top+.10,0),
			Vector3(1.9,.11,1.52),oak,Vector3(.0,.0,-.12))
		for z in [-.75,.75]:
			ART.bone(shelter,Vector3(-1.02,2.45,z),
				Vector3(.68,2.41,z),.07,.045,oak,7)
