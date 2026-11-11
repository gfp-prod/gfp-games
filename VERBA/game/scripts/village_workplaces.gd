extends Node3D
## Authored economic workplaces with visual outputs driven by the *existing*
## finite village ledger. No stock is created or destroyed by decoration.
## All large work areas live beside, not on, the citizens' navigation goals.
const ART = preload("res://scripts/art.gd")
const ECONOMY = preload("res://scripts/village_economy.gd")
var world: Node3D
var displays: Dictionary = {}
var production_lamps: Dictionary = {}
var refresh_elapsed: float = 0.0
var prior_signature: String = ""

func setup(owner_world: Node3D) -> void:
	world = owner_world
	name = "VillageWorkingDistrict"

func _ready() -> void:
	if world == null: return
	_build_fields()
	_build_bakery()
	_build_forge()
	_build_market()
	refresh_from_economy(true)

func _material(path: String, color: Color) -> StandardMaterial3D:
	return world.textured(path,color)

func _site(label: String, x: float, z: float) -> Node3D:
	var root := Node3D.new()
	root.name = label
	root.position = Vector3(x,world.height_at(x,z),z)
	add_child(root)
	return root

func _ground(x: float,z: float,offset: float=0.0) -> Vector3:
	return Vector3(x,world.height_at(x,z)+offset,z)

func _sign(parent: Node3D, writing: String, at: Vector3, tone: Color) -> void:
	var text_node := Label3D.new()
	text_node.name = "CarvedWorkplaceSign"
	text_node.text = writing
	text_node.font_size = 48
	text_node.pixel_size = .0032
	text_node.modulate = tone
	text_node.outline_size = 0
	text_node.no_depth_test = false
	text_node.position = at
	parent.add_child(text_node)

func _slots(item: String, nodes: Array) -> void:
	displays[item] = nodes

func _dome_mesh(radius: float, height: float) -> ArrayMesh:
	var st:=SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rings: int=9
	var segments: int=20
	for ring in range(rings):
		var a0: float=(float(ring)/float(rings))*PI*.5
		var a1: float=(float(ring+1)/float(rings))*PI*.5
		var r0: float=radius*cos(a0)
		var r1: float=radius*cos(a1)
		var y0: float=height*sin(a0)
		var y1: float=height*sin(a1)
		for segment in range(segments):
			var t0: float=TAU*float(segment)/float(segments)
			var t1: float=TAU*float(segment+1)/float(segments)
			var p0:=Vector3(cos(t0)*r0,y0,sin(t0)*r0)
			var p1:=Vector3(cos(t0)*r1,y1,sin(t0)*r1)
			var p2:=Vector3(cos(t1)*r0,y0,sin(t1)*r0)
			var p3:=Vector3(cos(t1)*r1,y1,sin(t1)*r1)
			for entry in [[p0,Vector2(t0/TAU,a0)],[p1,Vector2(t0/TAU,a1)],
					[p2,Vector2(t1/TAU,a0)],[p1,Vector2(t0/TAU,a1)],
					[p3,Vector2(t1/TAU,a1)],[p2,Vector2(t1/TAU,a0)]]:
				st.set_uv(entry[1])
				st.add_vertex(entry[0])
	st.generate_normals()
	return st.commit()

func _build_fields() -> void:
	# Crops and growing plants belong to a single organized plot; no giant
	# field blocks the entrance, the market, or the NPC navigation goal.
	var plot := _site("DaroWorkingFarm",18.0,27.0)
	var soil := _material("res://assets/textures/real/earth_path_diffuse.jpg",Color("99765b"))
	var leaf := ART.mat(Color("73845b"),.98)
	var stalk := ART.mat(Color("bca56e"),.95)
	var dark_wood := _material("res://assets/textures/real/cottage_wood_diffuse.jpg",Color("76604b"))
	var rope := ART.mat(Color("a99978"),1.0)
	var harvest := ART.mat(Color("bc9d67"),.97)
	for row in range(4):
		var z: float=24.5+float(row)*1.72
		# Narrow ridges follow real terrain, not a floating rectangular slab.
		for piece in range(5):
			var x: float=14.45+float(piece)*1.46
			var ground: Vector3=_ground(x,z,.055)
			var ridge := ART.orb(plot,ground-plot.global_position+Vector3(0,.035,0),
				Vector3(.79,.135,.57),soil,12)
			ridge.name = "CultivatedSoilRidge"
		for plant in range(10):
			var x: float=14.3+float(plant)*.71
			var base: Vector3=_ground(x,z,.06)-plot.global_position
			var sway: float=sin(float(row)*1.7+float(plant)*2.18)*.11
			ART.bone(plot,base,base+Vector3(sway,.85+float((row+plant)%3)*.075,0),
				.024,.012,stalk,7)
			ART.orb(plot,base+Vector3(sway,.77,.02),
				Vector3(.090,.14,.06),harvest,9)
			for side in [-1.0,1.0]:
				ART.bone(plot,base+Vector3(0,.21,0),
					base+Vector3(side*.21,.45,.07),.036,.008,leaf,6)
	# Seed cart and real sacks are outside the 4m-by-7m field.
	var cart := _site("DaroGrainCart",13.0,23.0)
	ART.box(cart,Vector3(0,.53,0),Vector3(2.0,.22,1.2),dark_wood)
	world.add_solid_box(cart,Vector3(0,.49,0),Vector3(1.99,.87,1.16),"PhysicalHarvestCart")
	world.navigation_blockers.append(cart.global_position)
	for x in [-.83,.83]:
		for z in [-.52,.52]:
			ART.bone(cart,Vector3(x,.13,z),Vector3(x,.56,z),.07,.065,dark_wood,8)
	for x in [-.76,.76]:
		ART.orb(cart,Vector3(x,.34,-.58),Vector3(.26,.30,.10),dark_wood,10)
	var sacks: Array=[]
	for i in range(6):
		var x: float=-.66+float(i%3)*.66
		var y: float=.82+float(i/3)*.44
		var bag := ART.orb(cart,Vector3(x,y,.06),Vector3(.30,.25,.40),harvest,10)
		bag.name="RealGrainStock_%d" % i
		sacks.append(bag)
	ART.bone(cart,Vector3(-.28,.59,.60),Vector3(-.28,.59,1.36),.055,.052,dark_wood,8)
	ART.bone(cart,Vector3(.28,.59,.60),Vector3(.28,.59,1.36),.055,.052,dark_wood,8)
	_sign(cart,"FRUMENTUM",Vector3(0,1.93,-.47),rope.albedo_color)
	_slots("grain",sacks)

func _build_bakery() -> void:
	var bakery := _site("IdaStoneBakery",8.9,16.25)
	var masonry := _material("res://assets/textures/real/stone_diffuse.jpg",Color("a5a08e"))
	var wood := _material("res://assets/textures/real/cottage_wood_diffuse.jpg",Color("675346"))
	var roof := ART.mat(Color("705343"),.97)
	var soot := ART.mat(Color("241e1a"),1.0)
	var bread := ART.mat(Color("b87943"),.88)
	var wheat := ART.mat(Color("d5bd86"),.94)
	# Distinct domed kiln with a dark opening, chimney and peel rack.
	ART.box(bakery,Vector3(.05,.33,.28),Vector3(2.45,.61,2.2),masonry)
	world.add_solid_box(bakery,Vector3(.05,1.12,.29),Vector3(2.35,2.18,2.15),"PhysicalBakeOven")
	world.navigation_blockers.append(bakery.global_position)
	# A true hemisphere, not the full stone sphere that made the oven look
	# like a loose boulder placed on a rectangular table.
	var dome:=MeshInstance3D.new()
	dome.name="ContinuousHemisphericalKiln"
	dome.mesh=_dome_mesh(1.17,1.42)
	dome.material_override=masonry
	dome.position=Vector3(0,.60,.34)
	bakery.add_child(dome)
	ART.cone(bakery,Vector3(0,.68,.34),1.21,.22,masonry,1.16,18)
	ART.orb(bakery,Vector3(0,.95,-.862),Vector3(.57,.42,.09),soot,16)
	var embers := ART.orb(bakery,Vector3(0,.67,-.966),
		Vector3(.43,.11,.063),ART.mat(Color("ed9a58"),.55,Color("be5224")),12)
	embers.name="BakerWorkingEmbers"
	production_lamps["baker"]=embers
	ART.bone(bakery,Vector3(.64,1.69,.83),Vector3(.69,3.42,.91),.24,.22,roof,11)
	# Only a narrow wooden peel rack remains; the bulky porch roof blocked
	# the oven when approaching from the village.
	ART.bone(bakery,Vector3(-1.60,.08,-.25),Vector3(-1.60,1.67,-.25),.065,.055,wood,8)
	for dy in [.43,1.08]:
		ART.bone(bakery,Vector3(-1.60,dy,-.35),Vector3(-2.11,dy,-.35),.05,.044,wood,8)
	_sign(bakery,"PANIS",Vector3(.85,1.30,-.81),wheat.albedo_color)
	# Display food is *not* decorative infinite loot: visibility reads the
	# finite bakery stock each frame, but no new physical pickups are minted.
	var stand := _site("IdaBreadCounter",6.7,13.7)
	ART.box(stand,Vector3(0,.84,0),Vector3(2.05,.17,1.04),wood)
	world.add_solid_box(stand,Vector3(0,.61,0),Vector3(2.0,1.08,1.0),"PhysicalBreadCounter")
	world.navigation_blockers.append(stand.global_position)
	for x in [-.89,.89]:
		for z in [-.37,.37]:
			ART.bone(stand,Vector3(x,.06,z),Vector3(x,.83,z),.073,.06,wood,7)
	var loaves: Array=[]
	for i in range(6):
		var x: float=-.64+float(i%3)*.62
		var z: float=-.24+float(i/3)*.45
		var loaf := ART.orb(stand,Vector3(x,1.04,z),
			Vector3(.25,.14,.17),bread,11)
		loaf.name="RealBreadStock_%d" % i
		loaves.append(loaf)
	_slots("bread",loaves)

func _build_forge() -> void:
	var forge := _site("OrinBlacksmithForge",21.8,19.1)
	var stone := _material("res://assets/textures/real/stone_diffuse.jpg",Color("797a71"))
	var timber := _material("res://assets/textures/real/cottage_wood_diffuse.jpg",Color("6b5847"))
	var iron := ART.mat(Color("42494c"),.59)
	iron.metallic=.60
	var glow := ART.mat(Color("e2a05f"),.35,Color("a65a30"))
	var leather := ART.mat(Color("b5a17c"),.95)
	ART.box(forge,Vector3(.0,.48,.47),Vector3(2.25,.93,1.27),stone)
	world.add_solid_box(forge,Vector3(0,.92,.47),Vector3(2.19,1.75,1.25),"PhysicalCoalForge")
	world.navigation_blockers.append(forge.global_position)
	ART.box(forge,Vector3(.0,1.17,.54),Vector3(2.32,.48,.75),stone)
	var coal := ART.box(forge,Vector3(0,.86,-.23),
		Vector3(1.35,.14,.44),glow)
	coal.name="ForgeWorkingCoals"
	production_lamps["blacksmith"]=coal
	ART.bone(forge,Vector3(1.12,.92,.73),Vector3(1.12,2.92,.73),.22,.17,stone,10)
	var anvil := _site("OrinAnvilAndToolRack",19.8,16.45)
	ART.bone(anvil,Vector3(0,.08,0),Vector3(0,.78,0),.24,.20,timber,10)
	ART.box(anvil,Vector3(0,.9,0),Vector3(1.33,.25,.61),iron)
	world.add_solid_box(anvil,Vector3(0,.62,0),Vector3(1.32,.96,.60),"PhysicalAnvil")
	ART.cone(anvil,Vector3(.82,.90,0),.26,.22,iron,.03,9)
	ART.bone(anvil,Vector3(1.3,.17,-.8),Vector3(1.3,2.2,-.8),.07,.067,timber,8)
	ART.bone(anvil,Vector3(1.3,2.14,-.8),Vector3(1.3,2.14,1.0),.07,.067,timber,8)
	var tools: Array=[]
	for i in range(4):
		var z: float=-.47+float(i)*.43
		var tool:=Node3D.new()
		tool.name="RealToolStock_%d" % i
		tool.position=Vector3(1.30,1.52,z)
		anvil.add_child(tool)
		ART.bone(tool,Vector3(0,-.33,0),Vector3(0,.28,0),
			.047,.039,timber,8)
		ART.box(tool,Vector3(0,.24,0),Vector3(.39,.12,.15),iron)
		tools.append(tool)
	_slots("tools",tools)
	_sign(anvil,"FERRUM",Vector3(0,2.48,-.25),leather.albedo_color)

func _build_market() -> void:
	# Simple proper stall makes the exchange point legible without putting
	# a solid pillar in the crowd's shared navigation destination.
	var stall := _site("VillagePublicMarket",5.3,20.5)
	var timber := _material("res://assets/textures/real/cottage_wood_diffuse.jpg",Color("756249"))
	var cloth := ART.mat(Color("887b5e"),.98)
	var pale := ART.mat(Color("c0b497"),.98)
	for x in [-1.12,1.12]:
		for z in [-.70,.70]:
			ART.bone(stall,Vector3(x,.0,z),Vector3(x,2.55,z),.085,.08,timber,8)
	ART.box(stall,Vector3(0,2.66,0),Vector3(2.65,.10,1.95),cloth)
	for x in [-.93,-.28,.37,.97]:
		ART.box(stall,Vector3(x,2.61,-.98),Vector3(.48,.30,.07),pale)
	ART.box(stall,Vector3(0,.98,0),Vector3(2.55,.16,1.35),timber)
	_sign(stall,"MERCATUS",Vector3(0,2.06,-.82),pale.albedo_color)

func refresh_from_economy(force: bool=false) -> void:
	if world == null or world.village_sim == null: return
	var economy = world.village_sim.economy
	var sig: String="%d:%d:%d:%d:%d" % [
		int(economy.stocks["grain"]),int(economy.stocks["bread"]),
		int(economy.stocks["tools"]),int(economy.stocks["ore"]),
		int(economy.stocks["wood"])]
	if not force and sig==prior_signature: return
	prior_signature=sig
	for kind in displays:
		var nodes: Array=displays[kind]
		var available: int=int(economy.stocks.get(kind,0))
		# Exactly zero stock renders no goods; positive goods render a
		# bounded sample. Full stock never spawns more scene nodes.
		var shown: int=mini(nodes.size(),ceili(float(available)/3.0))
		for i in range(nodes.size()):
			var node: Node3D=nodes[i]
			node.visible = i<shown
	production_lamps["baker"].visible=economy.can_work("baker")
	production_lamps["blacksmith"].visible=economy.can_work("blacksmith")

func _process(delta: float) -> void:
	refresh_elapsed+=delta
	if refresh_elapsed>=.33:
		refresh_elapsed=0
		refresh_from_economy()
