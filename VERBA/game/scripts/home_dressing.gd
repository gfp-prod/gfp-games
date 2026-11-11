extends RefCounted
## An authored arrival composition, using the existing PBR palette and
## actual low-volume 3D props rather than indiscriminate random clutter.
const ART = preload("res://scripts/art.gd")
const FOLIAGE = preload("res://scripts/foliage.gd")

static func populate(world: Node3D) -> void:
	var root := Node3D.new()
	root.name = "HermitageApproachArt"
	world.add_child(root)
	var oak: StandardMaterial3D = world.textured("res://assets/textures/cottage_wood.png",Color("a08b76"))
	var stone: Material = world.stone_mat
	var worn_paving: StandardMaterial3D = world.textured("res://assets/textures/real/earth_path_diffuse.jpg",Color("7d7569"))
	worn_paving.roughness = 1.0
	var dark := ART.mat(Color("3e4037"),.92)
	var bronze := ART.mat(Color("9e8659"),.48)
	bronze.metallic = .46
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261110

	# An approach curve to the cottage threshold, with real uneven stones
	# buried under the soil rather than enormous cobblestones floating on top.
	var steps: int = 13
	for i in range(steps):
		var t: float = float(i)/float(steps-1)
		var x: float = lerpf(24.0,27.8,t) + sin(t*PI*1.5)*.39
		var z: float = lerpf(19.4,10.7,t)
		var y: float = world.height_at(x,z)
		if i%2 == 0:
			ART.stone(root,Vector3(x,y+.012,z),
				Vector3(rng.randf_range(.36,.62),.038,rng.randf_range(.24,.45)),worn_paving)
		# Shallow edging where feet have worn the approach.
		if i%3 == 0:
			for side in [-1.0,1.0]:
				var edge_x: float = x+side*1.20
				ART.stone(root,Vector3(edge_x,world.height_at(edge_x,z),z),
					Vector3(rng.randf_range(.20,.30),.065,.24),worn_paving)

	# A workaday woodpile near the side of the house. Timber is substantial
	# but its approximate collider only covers the physically visible stack.
	var wood_x: float = 35.15
	var wood_z: float = 12.15
	var wood_ground: float = world.height_at(wood_x,wood_z)
	var wood_root := Node3D.new()
	wood_root.name="SplitOakByCottage"
	wood_root.position=Vector3(wood_x,wood_ground,wood_z)
	root.add_child(wood_root)
	for tier in range(2):
		for i in range(3-tier):
			var x_local: float = float(i)*.42-.43+float(tier)*.22
			var y_local: float = .18+float(tier)*.30
			var half_len: float = .55+rng.randf_range(-.09,.1)
			ART.bone(wood_root,
				Vector3(x_local,y_local,-half_len),
				Vector3(x_local,y_local,half_len),
				.18,.14,oak,10)
			for zz in [-half_len,half_len]:
				ART.orb(wood_root,Vector3(x_local,y_local,zz),
					Vector3(.12,.11,.02),ART.mat(Color("a48a70"),1.0),10)
	# A physically visible salvaging source, rather than a magic resource menu.
	wood_root.set_meta("resource_deposit","wood")
	wood_root.set_meta("harvest_id","woodpile:hermitage")
	var log_collider: StaticBody3D = world.add_solid_box(wood_root,
		Vector3(0,.37,0),Vector3(1.3,.7,1.18),"PhysicalStackedWood")
	log_collider.set_meta("harvest_ref",wood_root)

	# One warm navigational accent, visible at dusk from the path but not
	# enough artificial emissive lights to turn daytime into a theme park.
	var post_x: float = 23.5
	var post_z: float = 10.8
	var post_ground: float = world.height_at(post_x,post_z)
	var post := Node3D.new()
	post.name="HandmadeBronzePathLantern"
	post.position=Vector3(post_x,post_ground,post_z)
	root.add_child(post)
	ART.bone(post,Vector3.ZERO,Vector3(0,2.45,0),.09,.06,oak,10)
	ART.bone(post,Vector3(0,2.37,0),Vector3(.72,2.30,0),.07,.04,oak,10)
	ART.bone(post,Vector3(.72,2.30,0),Vector3(.72,2.03,0),.016,.015,dark,8)
	# A proper framed oil lantern: four metal rails, glazed amber window,
	# footplate and small roof. It replaces a giant pale umbrella-like cone.
	var glass: StandardMaterial3D = StandardMaterial3D.new()
	glass.albedo_color = Color(.31,.27,.23,.55)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.emission_enabled = true
	glass.emission = Color("ad743a")
	glass.emission_energy_multiplier = .13
	glass.roughness = .32
	var soot: Material = ART.mat(Color("413d36"),.74)
	ART.box(post,Vector3(.72,1.82,0),Vector3(.23,.275,.23),glass)
	ART.box(post,Vector3(.72,1.99,0),Vector3(.34,.055,.34),soot)
	ART.box(post,Vector3(.72,1.65,0),Vector3(.32,.055,.32),soot)
	for side_x in [-1.0,1.0]:
		for side_z in [-1.0,1.0]:
			ART.bone(post,
				Vector3(.72+side_x*.14,1.68,side_z*.14),
				Vector3(.72+side_x*.14,1.99,side_z*.14),
				.016,.016,soot,8)
	ART.bone(post,Vector3(.72,2.035,0),Vector3(.72,2.10,0),
		.036,.025,bronze,8)
	var glow := OmniLight3D.new()
	glow.name="QuietLanternGlow"
	glow.light_color=Color("f2c48c")
	glow.light_energy=.23
	glow.omni_range=4.5
	glow.position=Vector3(.72,1.82,0)
	post.add_child(glow)
	world.add_solid_box(post,Vector3(0,1.15,0),Vector3(.19,2.30,.19),"SolidLanternPost")

	# Muted undergrowth in clustered stands framing the home. The center
	# approach stays readable; plants are one batched draw call.
	var mesh: ArrayMesh = FOLIAGE.make_fern_mesh()
	var plant_mat := StandardMaterial3D.new()
	plant_mat.vertex_color_use_as_albedo = true
	plant_mat.albedo_color = Color("7e987a")
	plant_mat.roughness=1.0
	plant_mat.cull_mode=BaseMaterial3D.CULL_DISABLED
	var clumps := MultiMesh.new()
	clumps.transform_format=MultiMesh.TRANSFORM_3D
	clumps.use_colors=true
	clumps.mesh=mesh
	clumps.instance_count=128
	for i in range(clumps.instance_count):
		var patch: Vector2 = Vector2(21,11) if i%3==0 else Vector2(33.8,15) if i%3==1 else Vector2(35,4.0)
		var a: float = rng.randf_range(0,TAU)
		var radial: float = sqrt(rng.randf())*5.4
		var x: float = patch.x+cos(a)*radial
		var z: float = patch.y+sin(a)*radial
		# Retain deterministic clump count but keep the cottage interior and
		# the attached turret clear of ferns and other planted geometry.
		var outside: Vector2 = world.move_vegetation_outside_cottage(x,z)
		x = outside.x
		z = outside.y
		var size: float = rng.randf_range(.49,.92)
		var basis := Basis(Vector3.UP,rng.randf_range(0,TAU)).scaled(Vector3(size,size*.8,size))
		clumps.set_instance_transform(i,Transform3D(basis,
			Vector3(x,world.height_at(x,z)+.025,z)))
		clumps.set_instance_color(i,Color("526c53").lerp(Color("7b8864"),rng.randf_range(.0,.52)))
	var undergrowth := MultiMeshInstance3D.new()
	undergrowth.name="CuratedHermitageFernClusters"
	undergrowth.multimesh=clumps
	undergrowth.material_override=plant_mat
	root.add_child(undergrowth)
	# A small practical herb garden anchors the cottage to its landscape.
	# Old houses have working margins: plants, rainwater, tools, soil.
	_add_kitchen_garden(world,root,rng,oak,stone)

static func _herb_mesh() -> ArrayMesh:
	# One shared geometric herb, batched as thirty instances. Replaces
	# 100+ tiny individual sphere/cylinder nodes and material allocations.
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(7):
		var phi: float = TAU*float(i)/7.0
		var axis: Vector3 = Vector3(cos(phi),0,sin(phi))
		var width: Vector3 = Vector3(-axis.z,0,axis.x)
		var root: Vector3 = Vector3(0,.13,0)
		var tip: Vector3 = root+axis*.15+Vector3.UP*.13
		for p in [root-width*.026,root+width*.026,tip]:
			st.set_color(Color("637a58"))
			st.add_vertex(p)
	for i in range(4):
		var phi: float = TAU*float(i)/4.0
		var axis: Vector3 = Vector3(cos(phi),0,sin(phi))
		var width: Vector3 = Vector3(-axis.z,0,axis.x)
		var center: Vector3 = Vector3(0,.34,0)
		for p in [center-width*.022,center+width*.022,
				center+axis*.085+Vector3.UP*.045]:
			st.set_color(Color("b4aa8b"))
			st.add_vertex(p)
	for p in [Vector3(-.012,.12,0),Vector3(.012,.12,0),
			Vector3(0,.36,0)]:
		st.set_color(Color("536b4d"))
		st.add_vertex(p)
	st.generate_normals()
	return st.commit()

static func _add_kitchen_garden(world: Node3D,root: Node3D,rng: RandomNumberGenerator,
		oak: Material,stone: Material) -> void:
	var garden := Node3D.new()
	garden.name="HerbalistsKitchenGarden"
	garden.position=Vector3(21.6,world.height_at(21.6,9.1),9.1)
	garden.rotation.y=.13
	root.add_child(garden)
	var earth: Material = world.textured(
		"res://assets/textures/earth_path.png",Color("8d846d"))
	var washed: Material = ART.mat(Color("998d73"),.95)
	var leaves := MultiMesh.new()
	leaves.transform_format=MultiMesh.TRANSFORM_3D
	leaves.mesh=_herb_mesh()
	leaves.instance_count=30
	var plant_count: int=0
	for bed in range(2):
		var depth: float = -1.75+float(bed)*3.0
		# Soil is dark and planted, framed by rough short logs. The growing
		# beds are intentionally too low to look like rectangular planter UI.
		ART.box(garden,Vector3(0,.10,depth),Vector3(2.75,.14,2.1),earth)
		for side in [-1.0,1.0]:
			ART.bone(garden,Vector3(side*1.40,.24,depth-1.10),
				Vector3(side*1.40,.24,depth+1.10),.12,.11,oak,10)
			ART.bone(garden,Vector3(-1.42,.24,depth+side*1.1),
				Vector3(1.42,.24,depth+side*1.1),.12,.11,oak,10)
		# Thirty plants across two real beds share a single mesh and material.
		for stem in range(15):
			var bx: float = rng.randf_range(-1.08,1.08)
			var bz: float = depth+rng.randf_range(-.78,.78)
			var scale: float = rng.randf_range(.80,1.52)
			var axis := Basis(Vector3.UP,rng.randf_range(0,TAU)).scaled(
				Vector3(scale,scale,scale))
			leaves.set_instance_transform(plant_count,
				Transform3D(axis,Vector3(bx,.12,bz)))
			plant_count += 1
	var herb_visual := MultiMeshInstance3D.new()
	herb_visual.name="BatchedKitchenHerbRows"
	herb_visual.multimesh=leaves
	var herb_material := StandardMaterial3D.new()
	herb_material.vertex_color_use_as_albedo=true
	herb_material.roughness=1.0
	herb_material.cull_mode=BaseMaterial3D.CULL_DISABLED
	herb_visual.material_override=herb_material
	garden.add_child(herb_visual)
	# One faded label on a carved board teaches Latin materially.
	var label := Label3D.new()
	label.name = "HORTUS_KitchenGarden"
	label.text = "HORTUS"
	label.font_size = 42
	label.pixel_size = .0022
	label.modulate = Color("49382b")
	label.position = Vector3(-1.43,.95,2.525)
	label.rotation.y = -.25
	garden.add_child(label)
	ART.box(garden,Vector3(-1.43,.94,2.48),
		Vector3(.86,.34,.07),washed)
	ART.bone(garden,Vector3(-1.43,.18,2.50),
		Vector3(-1.43,.92,2.50),.046,.038,oak,8)
	# Practical rain barrel at the porch. Real curved staves, four iron
	# hoops, a little visible water at the open top.
	var barrel := Node3D.new()
	barrel.name="RainBarrelByPorch"
	# The old barrel overlapped the attached study turret; keep it in the yard.
	barrel.position = Vector3(35.6,world.height_at(35.6,10.5),10.5)
	root.add_child(barrel)
	var stave: Material = world.textured(
		"res://assets/textures/cottage_wood.png",Color("837361"))
	var band := ART.mat(Color("525550"),.63)
	band.metallic=.49
	for i in range(12):
		var theta: float = TAU*float(i)/12.0
		var radius: float = .46
		var around: Vector3 = Vector3(cos(theta)*radius,0,sin(theta)*radius)
		ART.box(barrel,around+Vector3.UP*.54,
			Vector3(.22,1.04,.08),stave,Vector3(0,-theta,0))
	for height in [.12,.39,.81,1.02]:
		ART.cone(barrel,Vector3(0,height,0),
			.505,.025,band,.505,16)
	ART.cone(barrel,Vector3(0,1.01,0),.42,.025,
		ART.mat(Color("405d5c"),.19),.42,20)
	world.add_solid_box(barrel,Vector3(0,.5,0),Vector3(.93,1.02,.93),"PhysicalRainBarrel")
