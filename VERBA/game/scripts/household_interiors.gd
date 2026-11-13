extends RefCounted
## Tangible, occupation-specific interiors for the two physical village homes.
## Both houses retain the Blender shell, original world economy, resident IDs
## and the unobstructed south (-Z) doorway. Furniture sits against the walls.
## No food, grain, tools, magical rewards or simulated economic stock is minted.
const ART=preload("res://scripts/art.gd")

static func _pot(parent: Node3D, location: Vector3, size: float, clay: Material) -> MeshInstance3D:
	# A small wheel-thrown jar with distinct foot, shoulder, narrow neck and
	# rolled rim. Actual curved geometry, not another featureless cuboid.
	var sections: Array[Vector2]=[
		Vector2(.25,.0),Vector2(.34,.10),Vector2(.40,.39),
		Vector2(.34,.66),Vector2(.20,.79),Vector2(.18,.88),Vector2(.24,.91)
	]
	var st:=SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var sides: int=16
	for level in range(sections.size()-1):
		var lower: Vector2=sections[level]
		var upper: Vector2=sections[level+1]
		for i in range(sides):
			var a: float=TAU*float(i)/float(sides)
			var b: float=TAU*float(i+1)/float(sides)
			var points: Array[Vector3]=[
				Vector3(cos(a)*lower.x,lower.y,sin(a)*lower.x),
				Vector3(cos(a)*upper.x,upper.y,sin(a)*upper.x),
				Vector3(cos(b)*lower.x,lower.y,sin(b)*lower.x),
				Vector3(cos(b)*upper.x,upper.y,sin(b)*upper.x)
			]
			for index in [0,1,2,1,3,2]:
				var v: Vector3=points[index]
				st.set_uv(Vector2(float(i+(1 if index>=2 else 0))/float(sides),v.y))
				st.add_vertex(v)
	st.generate_normals()
	var jar:=MeshInstance3D.new()
	jar.name="WheelThrownStorageJar"
	jar.mesh=st.commit()
	jar.material_override=clay
	jar.position=location
	jar.scale=Vector3.ONE*size
	parent.add_child(jar)
	return jar

static func _bed(room: Node3D, timber: Material, linen: Material, wool: Material) -> void:
	# Shared everyday furniture occupies the east rear corner, leaving the
	# center aisle and front entrance free even for a wide character capsule.
	var furniture:=Node3D.new()
	furniture.name="TimberBedAndWoolBlanket"
	room.add_child(furniture)
	for x in [.92,2.10]:
		for z in [.70,2.54]:
			ART.bone(furniture,Vector3(x,.15,z),Vector3(x,.68,z),
				.067,.056,timber,9)
	for x in [.92,2.10]:
		ART.box(furniture,Vector3(x,.42,1.62),Vector3(.13,.14,2.03),timber)
	for z in [.69,2.55]:
		ART.box(furniture,Vector3(1.51,.43,z),Vector3(1.29,.17,.13),timber)
	ART.box(furniture,Vector3(1.51,.53,1.62),Vector3(1.13,.13,1.84),linen)
	ART.box(furniture,Vector3(1.51,.635,1.27),Vector3(1.12,.10,1.06),wool)
	ART.orb(furniture,Vector3(1.51,.64,2.24),Vector3(.89,.22,.48),linen,14)
	# Headboard is jointed into the frame instead of floating behind it.
	for x in [.91,2.11]:
		ART.bone(furniture,Vector3(x,.39,2.55),Vector3(x,1.05,2.55),
			.062,.052,timber,8)
	ART.box(furniture,Vector3(1.51,.93,2.55),Vector3(1.19,.21,.11),timber)

static func _hearth(room: Node3D, stone: Material, iron: Material,
		soot: Material) -> void:
	# A small banked domestic firebox against the west wall near the entrance, well clear of the licensed shelves. It is
	# deliberately dark in daylight: the world's existing night lighting
	# provides a subtle hearth glow after dusk, not permanent neon embers.
	var hearth:=Node3D.new()
	hearth.name="SootMarkedDomesticHearth"
	room.add_child(hearth)
	ART.box(hearth,Vector3(-2.00,.22,-1.48),Vector3(.83,.34,.65),stone)
	ART.box(hearth,Vector3(-2.00,.36,-1.43),Vector3(.59,.045,.46),soot)
	for x in [-2.37,-1.63]:
		ART.stone(hearth,Vector3(x,.34,-1.48),Vector3(.22,.36,.43),stone)
	ART.bone(hearth,Vector3(-2.26,.61,-1.43),Vector3(-1.74,.61,-1.43),
		.029,.029,iron,9)

static func _craft_table(room: Node3D, kind: String, timber: Material,
		stone: Material, iron: Material, clay: Material,
		flour: Material) -> void:
	var work:=Node3D.new()
	work.name="OccupiedWorkTableDetails"
	room.add_child(work)
	# Align with the exact existing physical worktable collider.
	ART.box(work,Vector3(-1.25,1.18,1.22),Vector3(1.29,.10,.72),timber)
	for x in [-1.75,-.76]:
		ART.bone(work,Vector3(x,.12,1.0),Vector3(x,1.14,1.0),
			.068,.053,timber,8)
	if kind=="stonecutter":
		var offcuts:=Node3D.new()
		offcuts.name="StackedHewnPracticeStones"
		work.add_child(offcuts)
		for i in range(4):
			ART.stone(offcuts,Vector3(-1.66+float(i%2)*.28,
				1.285+float(i/2)*.095,1.14+float(i%2)*.13),
				Vector3(.16,.14,.17),stone)
		# A narrow iron chisel and a wooden mallet: no new harvest tool.
		ART.bone(work,Vector3(-.97,1.26,1.06),Vector3(-.68,1.26,1.45),
			.019,.015,iron,8)
		ART.bone(work,Vector3(-1.07,1.28,1.47),Vector3(-.79,1.28,1.50),
			.038,.038,timber,10)
		ART.box(work,Vector3(-.81,1.28,1.50),Vector3(.17,.14,.12),timber)
	else:
		var sieves:=Node3D.new()
		sieves.name="WickerSievesAndDryingRack"
		work.add_child(sieves)
		# An empty hand sieve and a clay mixing vessel, not counterfeit
		# grain that the baker could supposedly collect from the room.
		ART.cone(sieves,Vector3(-1.54,1.26,1.25),.24,.07,timber,.28,18)
		ART.cone(sieves,Vector3(-1.54,1.30,1.25),.19,.015,flour,.19,18)
		_pot(sieves,Vector3(-.92,1.23,1.23),.28,clay)
		for x in [-1.76,-.79]:
			ART.bone(sieves,Vector3(x,1.26,.93),
				Vector3(x,1.64,.93),.022,.022,timber,7)
		ART.bone(sieves,Vector3(-1.76,1.64,.93),
			Vector3(-.79,1.64,.93),.025,.025,timber,8)

static func _storage(room: Node3D, timber: Material,
		clay: Material, kind: String) -> void:
	# Shallow wall shelving makes the room readable from the doorway.
	# All stored items are domestic scenery, not economy inventory.
	var storage:=Node3D.new()
	storage.name="DomesticCeramicStorage"
	room.add_child(storage)
	for y in [1.62,2.13]:
		ART.box(storage,Vector3(.12,y,2.75),
			Vector3(1.10,.082,.30),timber)
	for x in [-.38,.62]:
		ART.bone(storage,Vector3(x,1.15,2.80),
			Vector3(x,2.25,2.80),.037,.037,timber,8)
	for i in range(4):
		var x: float=-.28+float(i%2)*.71
		var y: float=1.67+float(i/2)*.52
		var shade: Material=clay
		_pot(storage,Vector3(x,y,2.72),.30 if kind=="stonecutter" else .35,shade)

static func build(world: Node3D, house: Node3D, kind: String,
		timber: Material, stone: Material) -> void:
	if house.get_node_or_null("LivedInDomesticInterior")!=null:
		return
	var room:=Node3D.new()
	room.name="LivedInDomesticInterior"
	house.add_child(room)
	var linen:=ART.mat(Color("b5a994"),1.0)
	linen.albedo_texture=load("res://assets/textures/authored/aged_vellum.png")
	linen.uv1_triplanar=true
	var wool:=ART.mat(Color("6f765f") if kind=="stonecutter" else Color("9a866b"),.98)
	wool.albedo_texture=load("res://assets/textures/authored/aged_vellum.png")
	wool.uv1_triplanar=true
	var iron:=ART.mat(Color("504c47"),.82)
	var soot:=ART.mat(Color("342e29"),1.0)
	var clay:=ART.mat(Color("856957") if kind=="stonecutter" else Color("967a61"),.97)
	var flour:=ART.mat(Color("a99c84"),1.0)
	# A genuine Kenney CC0 bed is already placed in MillwardHouse by the
	# source-pinned asset installer. Do not put a second bed through it.
	# A bare checkout still gets the authored bed instead of an empty room.
	var licensed_bed: bool=kind=="miller" and ResourceLoader.exists(
		"res://assets/models/cc0/kenney/furniture/bedSingle.glb")
	if not licensed_bed:
		_bed(room,timber,linen,wool)
	_hearth(room,stone,iron,soot)
	_craft_table(room,kind,timber,stone,iron,clay,flour)
	_storage(room,timber,clay,kind)
	# These two forms are the only new blocking furniture; both are
	# behind the front threshold and built BEFORE world navigation bakes.
	if not licensed_bed:
		world.add_solid_box(house,Vector3(1.51,.38,1.62),
			Vector3(1.30,.62,2.02),"PhysicalDomesticBed")
	world.add_solid_box(house,Vector3(-2.00,.26,-1.48),
		Vector3(.90,.50,.72),"PhysicalDomesticHearth")
	room.set_meta("occupation",kind)
	room.set_meta("uses_licensed_bed",licensed_bed)
	room.set_meta("new_simulation_entities",0)
	room.set_meta("authored_storage_vessels",4)
	room.set_meta("walkable_door_clear",true)
