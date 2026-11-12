extends RefCounted
## Two distinct inhabited-scale village houses set into the actual valley.
## Both share one editable Blender vernacular building family; their gardens,
## orientations and local history differ. Physical doors lead into unfaked,
## roofed interiors. No inhabitants, money, books or quests are spawned here:
## existing simulations, ledgers, IDs and navigation are left authoritative.
const SOURCE: String="res://assets/models/foundry/village_hearth_house.glb"
const SITES: Array[Dictionary]=[
	{"name":"StonecutterHouse","at":Vector2(-7.5,34.0),"yaw":-.16,
	 "yard_side":-1.0,"kind":"stonecutter"},
	{"name":"MillwardHouse","at":Vector2(30.0,33.5),"yaw":.23,
	 "yard_side":1.0,"kind":"miller"}
]
const ART=preload("res://scripts/art.gd")
const VILLAGE_YARD_ART=preload("res://scripts/village_yard_art.gd")

static func build(world: Node3D) -> void:
	if world.get_node_or_null("PhysicalVillageHomesteads")!=null:
		return
	if not ResourceLoader.exists(SOURCE):
		# A bare checkout, prior to the Blender GitHub Actions export,
		# must remain playable. The old world has no phantom roof collisions.
		return
	var source: PackedScene=load(SOURCE) as PackedScene
	if source==null:
		push_error("Village art: failed to import the genuine Blender house")
		return
	var root:=Node3D.new()
	root.name="PhysicalVillageHomesteads"
	world.add_child(root)
	var installed: int=0
	# A true worn-board photographic PBR surface for the handcart, house
	# joinery and practical yard wood; preserve original if not bundled yet.
	var planks_path: String="res://assets/textures/cc0/polyhaven/weathered_planks_diffuse.png"
	if not ResourceLoader.exists(planks_path):
		planks_path="res://assets/textures/real/cottage_wood_diffuse.jpg"
	var timber: StandardMaterial3D=world.textured(planks_path,Color("65594d"))
	if ResourceLoader.exists("res://assets/textures/cc0/polyhaven/weathered_planks_normal.png"):
		timber.normal_enabled=true
		timber.normal_scale=.42
		timber.normal_texture=load("res://assets/textures/cc0/polyhaven/weathered_planks_normal.png")
	if ResourceLoader.exists("res://assets/textures/cc0/polyhaven/weathered_planks_rough.png"):
		timber.roughness_texture=load("res://assets/textures/cc0/polyhaven/weathered_planks_rough.png")
	var stone: Material=world.textured(
		"res://assets/textures/real/stone_diffuse.jpg",Color("8d8b81"))
	var metal: Material=ART.mat(Color("5e615c"),.78)
	for definition in SITES:
		var center: Vector2=definition["at"]
		var house:=Node3D.new()
		house.name=String(definition["name"])
		house.position=Vector3(center.x,world.height_at(center.x,center.y),center.y)
		house.rotation.y=float(definition["yaw"])
		root.add_child(house)
		var imported: Node3D=source.instantiate() as Node3D
		if imported==null:
			house.queue_free()
			continue
		imported.name="BlenderAuthoredVernacularHouse"
		house.add_child(imported)
		# Existing terrain is collidable. Only the tangible foundations,
		# actual walls and roof are blocked, with a front doorway left open.
		# The front faces -Z and its opening runs x[-.7,.7].
		world.add_solid_box(house,Vector3(0,.13,0),Vector3(6.12,.25,6.36),
			"HouseSolidStoneFoundation")
		for side in [-1.0,1.0]:
			world.add_solid_box(house,Vector3(side*2.84,1.71,0),
				Vector3(.33,3.23,6.24),"SolidLoadBearingSideWall")
		world.add_solid_box(house,Vector3(0,1.71,3.04),
			Vector3(5.85,3.22,.36),"SolidBackWall")
		for side in [-1.0,1.0]:
			world.add_solid_box(house,Vector3(side*1.74,1.69,-3.03),
				Vector3(2.05,3.23,.38),"SolidFrontWallPier")
		world.add_solid_box(house,Vector3(0,2.92,-3.03),
			Vector3(1.42,.76,.35),"SolidOpenDoorLintel")
		# Lightweight triangular roofs use the original broad roof collider
		# without sealing the entrance and the exposed ground floor.
		world.add_solid_box(house,Vector3(0,4.60,0),
			Vector3(6.45,.24,6.85),"PhysicalOldSlateRoof")
		# One central worktable leaves a navigable ~1.2m doorway and aisle.
		world.add_solid_box(house,Vector3(-1.25,.62,1.22),
			Vector3(1.23,1.04,.66),"PhysicalHomesteadWorktable")
		# A small carved Latin house inscription is a real world object,
		# not a tutorial HUD or a lesson that breaks the fourth wall.
		# It is fixed above the physically open doorway.
		var plaque: MeshInstance3D=ART.box(house,Vector3(0,2.58,-3.36),
			Vector3(1.79,.31,.10),timber)
		plaque.name="HandCarvedHouseNameBoard"
		var inscription:=Label3D.new()
		inscription.name="DiegeticLatinHouseInscription"
		inscription.text="DOMUS LAPIDARII" if String(definition["kind"])=="stonecutter" else "DOMUS MOLITORIS"
		inscription.font_size=30
		inscription.pixel_size=.0023
		inscription.modulate=Color("c2ad85")
		inscription.no_depth_test=false
		inscription.outline_size=0
		inscription.position=Vector3(0,2.58,-3.428)
		inscription.rotation.y=PI
		house.add_child(inscription)
		# Small practical yards say which profession lived here. Each uses
		# completely deterministic static details, not harvested stock.
		var yard:=Node3D.new()
		yard.name=String(definition["kind"]).capitalize()+"LivedInYard"
		yard.position=Vector3(3.40*float(definition["yard_side"]),0,.40)
		house.add_child(yard)
		for x in [-.60,.45]:
			for z in [-.64,.62]:
				ART.stone(yard,Vector3(x,.11,z),Vector3(.31,.19,.29),
					stone)
		if String(definition["kind"])=="stonecutter":
			for i in range(4):
				var x: float=-.55+float(i%2)*.71
				var z: float=-.70+float(i/2)*.88
				ART.stone(yard,Vector3(x,.25,z),
					Vector3(.46,.25,.41),stone)
			ART.bone(yard,Vector3(-.35,.13,.95),
				Vector3(.45,.78,.95),.11,.07,timber,8)
		else:
			# A bent grain handcart and a weathered small wheel are grounded
			# in the miller's task. No counterfeit grain added to the ledger.
			ART.box(yard,Vector3(0,.39,.12),
				Vector3(1.0,.18,.66),timber)
			for side in [-1.0,1.0]:
				ART.orb(yard,Vector3(side*.52,.23,.12),
					Vector3(.25,.25,.11),metal,12)
			for x in [-.30,.30]:
				ART.bone(yard,Vector3(x,.44,.28),
					Vector3(x,.78,1.02),.052,.043,timber,7)
		# Low-cost interior hearth bounce: a mundane sign that someone lives
		# here, visible through the truly open door and glazed windows.
		# Night strength is driven by the world's authoritative clock.
		var hearth_glow:=OmniLight3D.new()
		hearth_glow.name="WarmHearthWindowBounce"
		hearth_glow.position=Vector3(1.55,1.61,1.75)
		hearth_glow.light_color=Color("f0b379")
		hearth_glow.light_energy=0.0
		hearth_glow.omni_range=5.25
		hearth_glow.shadow_enabled=false
		house.add_child(hearth_glow)
		house.set_meta("visual_art_family","village_hearth_house")
		house.set_meta("site_profession",definition["kind"])
		house.set_meta("save_or_economy_id","none")
		installed+=1
	root.set_meta("authored_homestead_count",installed)
	root.set_meta("new_simulation_entities",0)
	# Terrain-conforming old garden beds, trampled access and worked yards.
	# Visual-only, with no new NPC goals, collision or persistence identities.
	VILLAGE_YARD_ART.build(world,root)
