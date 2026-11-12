extends RefCounted
## Rural road history: the modern petrol station is a long walk west of
## the medieval archive, so the impossible juxtaposition unfolds gradually.
## All geometry is built from committed, offline-compatible art/texture helpers.
## Open entries, floors, walls and pumps have matching real physics.
const ART=preload("res://scripts/art.gd")
const REGIONS=preload("res://scripts/world_regions.gd")
const STATION: Vector2=Vector2(-102.0,77.0)
const CASTLE: Vector2=Vector2(-49.0,44.0)

static func _at(world, xy: Vector2) -> Vector3:
	return Vector3(xy.x,world.height_at(xy.x,xy.y),xy.y)

static func _solid(world,parent: Node3D,where: Vector3,size: Vector3,material: Material,label: String) -> StaticBody3D:
	ART.box(parent,where,size,material)
	return world.add_solid_box(parent,where,size,label)

static func _sign(parent: Node3D,writing: String,where: Vector3,size: int,color: Color) -> void:
	var text_label:=Label3D.new()
	text_label.name="WeatheredRoadsideInscription"
	text_label.text=writing
	text_label.font_size=size
	text_label.pixel_size=.004
	text_label.modulate=color
	text_label.outline_size=5
	text_label.outline_modulate=Color("302b2b")
	text_label.no_depth_test=false
	text_label.position=where
	parent.add_child(text_label)

static func _lamp(parent: Node3D,where: Vector3,energy: float=0.75,range_m: float=7.0) -> void:
	var light:=OmniLight3D.new()
	light.name="RoadsidePracticalLight"
	light.light_color=Color("ffe1b1")
	light.light_energy=energy
	light.omni_range=range_m
	light.shadow_enabled=false
	light.position=where
	parent.add_child(light)

static func build(world) -> void:
	var root:=Node3D.new()
	root.name="StrangeRoadDistrict"
	world.add_child(root)
	_road(world,root)
	_north_road_bridge(world,root)
	_station(world,root)
	_castle(world,root)

static func station_route() -> Array[Vector2]:
	return [Vector2(-41.4,44),Vector2(-44,53),Vector2(-56,61),
		Vector2(-71,65),Vector2(-87,71),Vector2(-99.2,77)]

static func _road(world,root: Node3D) -> void:
	# Deliberate hand-curated road graph, rather than scattered random props.
	# Splines are samples at terrain height; the heightmap remains the collider.
	var tracks: Array=[
		[Vector2(0,26),Vector2(-7,30),Vector2(-11,32.22),
			Vector2(-24,40.82),Vector2(-32,41),Vector2(-41.4,44)],
		station_route(),
		[Vector2(0,26),Vector2(6,19),Vector2(10,11),Vector2(7,-3),
			Vector2(5,-19),Vector2(4,-35)]
	]
	var path: StandardMaterial3D=world.textured("res://assets/textures/earth_path.png",Color("948977"))
	var asphalt:=ShaderMaterial.new()
	asphalt.shader=load("res://assets/materials/aged_road.gdshader")
	asphalt.set_shader_parameter("road_stone",load("res://assets/textures/real/stone_diffuse.jpg"))
	path.roughness=1.0
	path.cull_mode=BaseMaterial3D.CULL_DISABLED
	for index in range(tracks.size()):
		var points: Array=tracks[index]
		var mesh_tool:=SurfaceTool.new()
		mesh_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
		var dist: float=0.0
		for segment in range(points.size()-1):
			var first: Vector2=points[segment]
			var last: Vector2=points[segment+1]
			var length: float=first.distance_to(last)
			var subdivisions: int=maxi(2,ceili(length/1.0))
			var tangent: Vector2=(last-first).normalized()
			var normal: Vector2=Vector2(-tangent.y,tangent.x)
			for t in range(subdivisions):
				var u0: float=float(t)/float(subdivisions)
				var u1: float=float(t+1)/float(subdivisions)
				var p0: Vector2=first.lerp(last,u0)
				var p1: Vector2=first.lerp(last,u1)
				var half_width: float=1.46 if index==1 else 1.15
				var a: Vector2=p0+normal*half_width
				var b: Vector2=p0-normal*half_width
				var c: Vector2=p1+normal*half_width
				var d: Vector2=p1-normal*half_width
				var aa:=Vector3(a.x,world.height_at(a.x,a.y)+.047,a.y)
				var bb:=Vector3(b.x,world.height_at(b.x,b.y)+.047,b.y)
				var cc:=Vector3(c.x,world.height_at(c.x,c.y)+.047,c.y)
				var dd:=Vector3(d.x,world.height_at(d.x,d.y)+.047,d.y)
				var v0: float=(dist+length*u0)*.3
				var v1: float=(dist+length*u1)*.3
				for vertex in [[aa,Vector2(0,v0)],[bb,Vector2(1,v0)],
						[cc,Vector2(0,v1)],[bb,Vector2(1,v0)],
						[dd,Vector2(1,v1)],[cc,Vector2(0,v1)]]:
					mesh_tool.set_uv(vertex[1])
					mesh_tool.add_vertex(vertex[0])
			dist+=length
		mesh_tool.generate_normals()
		var roadway:=MeshInstance3D.new()
		roadway.name="RoadSegment_%d" % index
		roadway.mesh=mesh_tool.commit()
		roadway.material_override=asphalt if index==1 else path
		roadway.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(roadway)


static func _north_road_bridge(world, root: Node3D) -> void:
	# The western branch of the road otherwise drops four meters into the
	# stream at z~36. A road texture through water is NOT a traversable road.
	# Cross between landfall points that lie on the authored road segments.
	var eastern: Vector2=Vector2(-11.0,32.22)
	var western: Vector2=Vector2(-24.0,40.82)
	var axis: Vector2=(western-eastern).normalized()
	var normal: Vector2=Vector2(-axis.y,axis.x)
	var span: float=eastern.distance_to(western)
	var first_y: float=world.height_at(eastern.x,eastern.y)+0.15
	var last_y: float=world.height_at(western.x,western.y)+0.15
	var bridge:=Node3D.new()
	bridge.name="OldNorthRoadFootbridge"
	root.add_child(bridge)
	var timber: Material=world.textured("res://assets/textures/real/cottage_wood_diffuse.jpg",Color("726450"))
	var aged: Material=ART.mat(Color("554c40"),.98)
	var st:=SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var parts: int=20
	var half_width: float=1.31
	# Collision is one continuous body with overlapping convex segments.
	# A single concave plane fails some physics queries along triangle seams.
	var collider:=StaticBody3D.new()
	collider.name="WalkableNorthRoadBridgeDeck"
	collider.collision_layer=16
	collider.collision_mask=0
	bridge.add_child(collider)
	for index in range(parts):
		var u0: float=float(index)/float(parts)
		var u1: float=float(index+1)/float(parts)
		var at0: Vector2=eastern.lerp(western,u0)
		var at1: Vector2=eastern.lerp(western,u1)
		var y0: float=lerpf(first_y,last_y,u0)+1.05*sin(u0*PI)
		var y1: float=lerpf(first_y,last_y,u1)+1.05*sin(u1*PI)
		var middle: Vector2=at0.lerp(at1,0.5)
		var start3:=Vector3(at0.x,y0,at0.y)
		var end3:=Vector3(at1.x,y1,at1.y)
		var forward3: Vector3=(end3-start3).normalized()
		var across3: Vector3=Vector3(normal.x,0.0,normal.y)
		var up3: Vector3=across3.cross(forward3).normalized()
		var box_shape:=BoxShape3D.new()
		box_shape.size=Vector3(start3.distance_to(end3)+.16,.18,half_width*2.0)
		var collision_part:=CollisionShape3D.new()
		collision_part.name="BridgeSlopeSegment_%d" % index
		collision_part.shape=box_shape
		collision_part.transform=Transform3D(Basis(forward3,up3,across3),
			Vector3(middle.x,(y0+y1)*.5,middle.y)-up3*.07)
		collider.add_child(collision_part)
		var a:=Vector3(at0.x+normal.x*half_width,y0,at0.y+normal.y*half_width)
		var b:=Vector3(at0.x-normal.x*half_width,y0,at0.y-normal.y*half_width)
		var c:=Vector3(at1.x+normal.x*half_width,y1,at1.y+normal.y*half_width)
		var d:=Vector3(at1.x-normal.x*half_width,y1,at1.y-normal.y*half_width)
		for pair in [[a,Vector2(0,u0*span*.25)],[c,Vector2(0,u1*span*.25)],
				[b,Vector2(1,u0*span*.25)],[b,Vector2(1,u0*span*.25)],
				[c,Vector2(0,u1*span*.25)],[d,Vector2(1,u1*span*.25)]]:
			st.set_uv(pair[1])
			st.add_vertex(pair[0])
	st.generate_normals()
	var plank_mesh: ArrayMesh=st.commit()
	var deck:=MeshInstance3D.new()
	deck.name="NorthBridgeTimberDeck"
	deck.mesh=plank_mesh
	deck.material_override=timber
	bridge.add_child(deck)
	# Overlapping physics segments track the arched deck and bank transitions.
	for side in [-1.0,1.0]:
		var edge: Vector2=normal*(half_width-0.06)*side
		for section in range(12):
			var v0: float=float(section)/12.0
			var v1: float=float(section+1)/12.0
			var p0: Vector2=eastern.lerp(western,v0)+edge
			var p1: Vector2=eastern.lerp(western,v1)+edge
			ART.bone(bridge,Vector3(p0.x,lerpf(first_y,last_y,v0)+1.05*sin(v0*PI)-.15,p0.y),
				Vector3(p1.x,lerpf(first_y,last_y,v1)+1.05*sin(v1*PI)-.15,p1.y),
				.11,.11,aged,10)
		# Low rail; the player can see the stream and still cross freely.
		for k in range(6):
			var u: float=float(k)/5.0
			var point: Vector2=eastern.lerp(western,u)+edge
			var y: float=lerpf(first_y,last_y,u)+1.05*sin(u*PI)
			ART.bone(bridge,Vector3(point.x,y-.12,point.y),
				Vector3(point.x,y+.82,point.y),.065,.054,aged,8)
		for k in range(5):
			var u0: float=float(k)/5.0
			var u1: float=float(k+1)/5.0
			var start: Vector2=eastern.lerp(western,u0)+edge
			var stop: Vector2=eastern.lerp(western,u1)+edge
			ART.bone(bridge,
				Vector3(start.x,lerpf(first_y,last_y,u0)+1.05*sin(u0*PI)+.72,start.y),
				Vector3(stop.x,lerpf(first_y,last_y,u1)+1.05*sin(u1*PI)+.72,stop.y),
				.033,.033,aged,7)

static func _station(world,root: Node3D) -> void:
	var site:=Node3D.new()
	site.name="ValeFuelStation"
	site.position=_at(world,STATION)
	root.add_child(site)
	var concrete: StandardMaterial3D=world.textured("res://assets/textures/real/cottage_plaster_diffuse.jpg",Color("b6a999"))
	var wood: StandardMaterial3D=world.textured("res://assets/textures/real/cottage_wood_diffuse.jpg",Color("79624d"))
	var steel:=ART.mat(Color("53534f"),.62)
	var ochre:=ART.mat(Color("ac784e"),.83)
	var light_panel:=ART.mat(Color("efe0be"),.84)
	var signage:=ART.mat(Color("5b7067"),.9)
	# Flat concrete forecourt and a one-room walk-in shop.
	_solid(world,site,Vector3(2,.00,0),Vector3(15,.21,9.7),concrete,"StationConcreteApron")
	_solid(world,site,Vector3(-2.15,.18,0),Vector3(7.1,.20,7.0),wood,"StationInteriorFloor")
	# Walls: eastern shop entrance has a real 2.2m opening at z=0.
	_solid(world,site,Vector3(-5.70,1.82,0),Vector3(.36,3.42,7.2),concrete,"StationWestWall")
	_solid(world,site,Vector3(-2.10,1.82,-3.48),Vector3(7.5,3.42,.38),concrete,"StationNorthWall")
	_solid(world,site,Vector3(-2.10,1.82,3.48),Vector3(7.5,3.42,.38),concrete,"StationSouthWall")
	_solid(world,site,Vector3(1.45,1.82,-2.35),Vector3(.38,3.42,2.30),concrete,"StationEastWallNorth")
	_solid(world,site,Vector3(1.45,1.82,2.35),Vector3(.38,3.42,2.30),concrete,"StationEastWallSouth")
	_solid(world,site,Vector3(1.45,3.08,0),Vector3(.38,.88,2.40),concrete,"StationEntranceLintel")
	_solid(world,site,Vector3(-2.15,3.65,0),Vector3(7.7,.28,7.4),steel,"StationShopRoof")
	# Windows are framed opaque glass with no one-sided missing walls.
	for z in [-2.25,2.25]:
		ART.box(site,Vector3(1.67,2.02,z),Vector3(.08,1.16,1.0),signage)
		for dy in [-.62,.62]:
			ART.box(site,Vector3(1.73,2.02+dy,z),Vector3(.12,.09,1.12),wood)
	# A real shop interior: stocked shelves, counter, lamp and hanging sign.
	_solid(world,site,Vector3(-3.8,.78,-2.55),Vector3(2.5,1.1,.63),wood,"StationProvisionShelf")
	_solid(world,site,Vector3(-3.8,.78,2.55),Vector3(2.5,1.1,.63),wood,"StationColdGoods")
	_solid(world,site,Vector3(-.7,.71,1.66),Vector3(.69,1.18,2.60),wood,"StationSalesCounter")
	for z in [-2.6,-1.9,-1.2]:
		for y in [.47,.95,1.41]:
			ART.box(site,Vector3(-3.9,y,z),Vector3(.44,.22,.26),ochre)
	_lamp(site,Vector3(-2.5,3.11,0),.87,7.0)
	_sign(site,"GAS • PROVISIONS",Vector3(1.69,3.09,0),53,Color("e3d2b8"))
	# Long low canopy; pump columns terminate in the canopy and are solid.
	_solid(world,site,Vector3(5.00,4.09,0),Vector3(6.65,.38,8.6),signage,"StationPumpCanopy")
	for z in [-3.52,3.52]:
		_solid(world,site,Vector3(6.68,2.07,z),Vector3(.37,4.03,.37),steel,"StationCanopyColumn")
	for z in [-2.27,2.27]:
		_solid(world,site,Vector3(4.6,.77,z),Vector3(.83,1.43,.77),ochre,"FuelPump_"+str(z))
		ART.box(site,Vector3(5.055,1.11,z),Vector3(.035,.49,.40),light_panel)
		ART.bone(site,Vector3(4.72,1.08,z+.39),Vector3(5.15,.57,z+.74),.038,.026,steel,9)
		ART.box(site,Vector3(4.73,1.52,z),Vector3(1.0,.09,1.0),steel)
	_lamp(site,Vector3(4.7,3.72,0),.81,9.0)
	# Roadside pole sign, legible after following the old road rather than
	# from the castle courtyard sixty metres away.
	_solid(world,site,Vector3(9.12,3.55,-2.68),Vector3(.22,7.1,.22),steel,"FuelSignPole")
	ART.box(site,Vector3(9.12,6.2,-2.68),Vector3(.34,1.47,3.6),signage)
	_sign(site,"VALE FUEL",Vector3(9.32,6.24,-2.7),57,Color("f3dfb4"))
	var inside:=Marker3D.new()
	inside.name="StationWalkableInterior"
	inside.position=Vector3(-2.1,.40,-.6)
	site.add_child(inside)
	var entrance:=Marker3D.new()
	entrance.name="StationOpenEntrance"
	entrance.position=Vector3(1.46,.45,0)
	site.add_child(entrance)

static func _tower(world,parent: Node3D,where: Vector3,height: float,name: String,stone: Material,slate: Material) -> void:
	var root:=Node3D.new()
	root.name=name
	root.position=where
	parent.add_child(root)
	var masonry:=MeshInstance3D.new()
	masonry.name="RoundMasonryTower"
	var tube:=CylinderMesh.new()
	tube.top_radius=1.60
	tube.bottom_radius=1.82
	tube.height=height
	tube.radial_segments=14
	masonry.mesh=tube
	masonry.material_override=stone
	masonry.position.y=height*.5
	root.add_child(masonry)
	var collision:=StaticBody3D.new()
	collision.name="SolidMasonryTower"
	collision.collision_layer=16
	collision.collision_mask=0
	var shape:=CollisionShape3D.new()
	var cylinder:=CylinderShape3D.new()
	cylinder.radius=1.70
	cylinder.height=height
	shape.shape=cylinder
	shape.position.y=height*.5
	collision.add_child(shape)
	root.add_child(collision)
	var crown:=CylinderMesh.new()
	crown.top_radius=2.04
	crown.bottom_radius=1.96
	crown.height=.24
	crown.radial_segments=14
	var lip:=MeshInstance3D.new()
	lip.name="WornTowerCoping"
	lip.mesh=crown
	lip.material_override=slate
	lip.position.y=height+.04
	root.add_child(lip)
	for i in range(10):
		if i in [2,7]: continue
		var a: float=TAU*float(i)/10.0
		ART.box(root,Vector3(cos(a)*1.7,height+.40,sin(a)*1.7),
			Vector3(.55,.68,.68),stone,Vector3(0,-a,0))
	for y in [1.85,3.33]:
		ART.box(root,Vector3(0,y,1.735),Vector3(.26,.72,.10),slate)

static func _castle(world,root: Node3D) -> void:
	var castle:=Node3D.new()
	castle.name="CastleOfTheSecondRoad"
	castle.position=_at(world,CASTLE)
	root.add_child(castle)
	var limestone: StandardMaterial3D=world.textured("res://assets/textures/real/cottage_plaster_diffuse.jpg",Color("938e7f"))
	var dark: StandardMaterial3D=world.textured("res://assets/textures/stone.png",Color("6f706b"))
	var oak: StandardMaterial3D=world.textured("res://assets/textures/real/cottage_wood_diffuse.jpg",Color("716256"))
	var slate:=ART.mat(Color("585c60"),.97)
	var moss:=ART.mat(Color("646f59"),.95)
	_solid(world,castle,Vector3.ZERO,Vector3(14.9,.24,15.0),limestone,"CastleWalkableCourt")
	# West/north/south curtain and the *opened* eastern gate facing the station.
	_solid(world,castle,Vector3(-7.45,2.17,0),Vector3(.73,4.3,15.35),limestone,"CastleWestCurtain")
	_solid(world,castle,Vector3(0,2.17,-7.45),Vector3(15.5,4.3,.74),limestone,"CastleNorthCurtain")
	_solid(world,castle,Vector3(0,2.17,7.45),Vector3(15.5,4.3,.74),limestone,"CastleSouthCurtain")
	for z in [-5.0,5.0]:
		_solid(world,castle,Vector3(7.45,2.17,z),Vector3(.74,4.3,5.0),limestone,"CastleEastCurtain_"+str(z))
	_solid(world,castle,Vector3(7.45,4.47,0),Vector3(.74,.74,5.10),limestone,"CastleGateLintel")
	# Four textured towers with distinct tower silhouettes and actual hulls.
	for x in [-7.25,7.25]:
		for z in [-7.25,7.25]:
			_tower(world,castle,Vector3(x,.04,z),6.35 if x<0 else 5.75,
				"CornerTurret_%d_%d" % [int(x),int(z)],limestone,slate)
	# An enclosed, enterable roofed archive inside the courtyard.
	var archive:=Node3D.new()
	archive.name="KeepArchiveRoom"
	archive.position=Vector3(-2.5,.13,0)
	castle.add_child(archive)
	_solid(world,archive,Vector3(0,.08,0),Vector3(5.45,.17,5.7),dark,"CastleArchiveFloor")
	_solid(world,archive,Vector3(-2.65,1.85,0),Vector3(.48,3.4,5.5),limestone,"CastleArchiveWestWall")
	_solid(world,archive,Vector3(0,1.85,-2.74),Vector3(5.5,3.4,.45),limestone,"CastleArchiveNorthWall")
	_solid(world,archive,Vector3(0,1.85,2.74),Vector3(5.5,3.4,.45),limestone,"CastleArchiveSouthWall")
	for z in [-2.0,2.0]:
		_solid(world,archive,Vector3(2.65,1.82,z),Vector3(.45,3.4,1.55),limestone,"CastleArchiveEastJamb")
	_solid(world,archive,Vector3(2.65,3.12,0),Vector3(.45,.75,2.85),limestone,"CastleArchiveOpenArch")
	_solid(world,archive,Vector3(0,3.75,0),Vector3(5.9,.38,6.3),slate,"CastleArchiveRoof")
	for z in [-1.78,1.78]:
		for y in [.70,1.49,2.22]:
			ART.box(archive,Vector3(-1.72,y,z),Vector3(.95,.18,.51),oak)
	_lamp(archive,Vector3(0,3.25,0),.57,6.2)
	# The castle holds an impossible, harmless glow: neither a quest marker nor a trap.
	var oddity:=Node3D.new()
	oddity.name="QuietImpossibleLantern"
	oddity.position=Vector3(2.45,2.35,-3.0)
	castle.add_child(oddity)
	ART.orb(oddity,Vector3.ZERO,Vector3(.18,.27,.18),
		ART.mat(Color("d3e1ce"),.3,Color("8bcaab")),14)
	_lamp(oddity,Vector3.ZERO,.36,5.4)
	var inside:=Marker3D.new()
	inside.name="CastleWalkableArchive"
	inside.position=Vector3(-2.7,.54,-.7)
	castle.add_child(inside)
	var entrance:=Marker3D.new()
	entrance.name="CastleOpenGate"
	entrance.position=Vector3(7.46,.43,0)
	castle.add_child(entrance)
