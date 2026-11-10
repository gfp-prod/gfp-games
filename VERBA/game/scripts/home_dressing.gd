extends RefCounted
## An authored arrival composition, using the existing PBR palette and
## actual low-volume 3D props rather than indiscriminate random clutter.
const ART = preload("res://scripts/art.gd")
const FOLIAGE = preload("res://scripts/foliage.gd")

static func populate(world: Node3D) -> void:
	var root := Node3D.new()
	root.name = "HermitageApproachArt"
	world.add_child(root)
	var oak := world.textured("res://assets/textures/cottage_wood.png",Color("a08b76"))
	var stone := world.stone_mat
	var dark := ART.mat(Color("3e4037"),.92)
	var bronze := ART.mat(Color("9e8659"),.48)
	bronze.metallic = .46
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261110

	# An approach curve to the cottage threshold, with real uneven stones
	# buried under the soil rather than enormous cobblestones floating on top.
	var steps: int = 16
	for i in range(steps):
		var t: float = float(i)/float(steps-1)
		var x: float = lerpf(24.0,27.8,t) + sin(t*PI*1.5)*.39
		var z: float = lerpf(19.4,10.7,t)
		var y: float = world.height_at(x,z)
		if i%3 != 1:
			ART.stone(root,Vector3(x,y+.012,z),
				Vector3(rng.randf_range(.58,.79),.045,rng.randf_range(.32,.53)),stone)
		# Shallow edging where feet have worn the approach.
		if i%3 == 0:
			for side in [-1.0,1.0]:
				var edge_x: float = x+side*1.20
				ART.stone(root,Vector3(edge_x,world.height_at(edge_x,z),z),
					Vector3(rng.randf_range(.23,.33),.09,.24),stone)

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
	world.add_solid_box(wood_root,Vector3(0,.37,0),Vector3(1.3,.7,1.18),"PhysicalStackedWood")

	# One warm navigational accent, visible at dusk from the path but not
	# enough artificial emissive lights to turn daytime into a theme park.
	var post_x: float = 25.3
	var post_z: float = 13.5
	var post_ground: float = world.height_at(post_x,post_z)
	var post := Node3D.new()
	post.name="HandmadeBronzePathLantern"
	post.position=Vector3(post_x,post_ground,post_z)
	root.add_child(post)
	ART.bone(post,Vector3.ZERO,Vector3(0,2.45,0),.09,.06,oak,10)
	ART.bone(post,Vector3(0,2.37,0),Vector3(.72,2.30,0),.07,.04,oak,10)
	ART.bone(post,Vector3(.72,2.30,0),Vector3(.72,2.03,0),.016,.015,dark,8)
	ART.cone(post,Vector3(.72,1.99,0),.18,.23,bronze,.06,10)
	ART.cone(post,Vector3(.72,1.55,0),.19,.11,bronze,.14,10)
	var candle := ART.mat(Color("f1ca8a"),.5,Color("6d5434"))
	ART.orb(post,Vector3(.72,1.78,0),Vector3(.135,.175,.135),candle,12)
	for side in [-1.0,1.0]:
		ART.bone(post,Vector3(.72+side*.13,1.56,0),
			Vector3(.72+side*.13,1.96,0),.012,.011,bronze,7)
	var glow := OmniLight3D.new()
	glow.name="QuietLanternGlow"
	glow.light_color=Color("f2c48c")
	glow.light_energy=.52
	glow.omni_range=4.5
	glow.position=Vector3(.72,1.77,0)
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
		if Vector2(x,z).distance_to(Vector2(28,12)) < 2.0:
			x += 3.0
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
