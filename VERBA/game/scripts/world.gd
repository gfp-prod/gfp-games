extends Node3D
## VERBA v0.5: one authored valley, rather than a random pile of primitives.
const ART = preload("res://scripts/art.gd")
const FOLIAGE = preload("res://scripts/foliage.gd")
const PLAYER_SCRIPT = preload("res://scripts/player.gd")
const CREATURE_SCRIPT = preload("res://scripts/creature.gd")
const PICKUP_SCRIPT = preload("res://scripts/pickup.gd")
const MAGIC_SCRIPT = preload("res://scripts/magic.gd")
const SIM_OBJECT = preload("res://scripts/sim_object.gd")
const NAV_BUILDER = preload("res://scripts/navigation_builder.gd")
const EXTERNAL_ART = preload("res://scripts/external_art.gd")
var player
var magic
var creatures: Array = []
var navigation_blockers: Array[Vector3] = []
var navigation_region: NavigationRegion3D
var sim_objects: Array = []
var next_sim_id: int = 1
var ecology_timer: float = 0.0
var natural_weather_timer: float = 0.0
var natural_weather_at: float = 80.0
var spontaneous_events: int = 0
var flora: Array = []
var items: Array = []
var fires: Array = []
var rain_fx: GPUParticles3D
var raining := false
var rain_remaining := 0.0
var wind := 0.0
var night_remaining := 0.0
var light_node: DirectionalLight3D
var ambient: WorldEnvironment
var terrain_noise := FastNoiseLite.new()
var small_noise := FastNoiseLite.new()
var rng := RandomNumberGenerator.new()
var time := 0.0
var stone_mat: Material
var bark_mat: Material
var bark_dark: Material
var leaf_green: Array[Material] = []
var leaf_rust: Array[Material] = []
var leaf_blue: Array[Material] = []
var ground_seed := 1938
const CC0_DIR: String = "res://assets/textures/real/"

func _ready() -> void:
	rng.seed=ground_seed
	terrain_noise.seed=9031
	terrain_noise.frequency=.024
	terrain_noise.fractal_type=FastNoiseLite.FRACTAL_FBM
	terrain_noise.fractal_octaves=4
	small_noise.seed=77421
	small_noise.frequency=.13
	setup_materials()
	setup_atmosphere()
	build_terrain()
	build_old_road()
	build_landmarks()
	build_stone_ridges()
	build_first_words_cairn()
	build_forest()
	build_scatter()
	build_water()
	FOLIAGE.populate_grass(self)
	FOLIAGE.populate_ferns(self)
	FOLIAGE.populate_litter(self)
	populate_reactive_grass()
	navigation_region = NAV_BUILDER.install(self)
	magic=MAGIC_SCRIPT.new(self)
	player=PLAYER_SCRIPT.new()
	player.name="Player"
	player.world=self
	player.position=Vector3(0,height_at(0,26)+.12,26)
	add_child(player)
	populate_wildlife()
	populate_collectibles()
	setup_rain()

func setup_materials() -> void:
	stone_mat=textured("res://assets/textures/stone.png",Color("e5e0d4"))
	bark_mat=textured("res://assets/textures/bark.png",Color("d4c2a8"))
	bark_dark=textured("res://assets/textures/bark.png",Color("a99e91"))
	for hue in ["5e7452","768b60","6a7c54","819171"]: leaf_green.append(ART.mat(Color(hue)))
	for hue in ["7d5b49","b78c5e","a56e52","c0a275"]: leaf_rust.append(ART.mat(Color(hue)))
	for hue in ["425754","607069","7d8272"]: leaf_blue.append(ART.mat(Color(hue)))

func photo_or_fallback(path: String) -> String:
	# The optional CC0 downloader installs real photographic Poly Haven textures.
	# Use those in every material, retaining bundled textures for offline launch.
	var base_name := path.get_file().get_basename()
	var photo: String = CC0_DIR + base_name + "_diffuse.jpg"
	return photo if ResourceLoader.exists(photo) else path

func textured(path: String, tint: Color) -> StandardMaterial3D:
	var m := ART.mat(tint)
	var selected: String = photo_or_fallback(path)
	var tex: Texture2D = load(selected)
	if tex != null: m.albedo_texture = tex
	var normal_path: String = CC0_DIR + path.get_file().get_basename() + "_normal.jpg"
	if ResourceLoader.exists(normal_path):
		m.normal_enabled=true
		m.normal_texture=load(normal_path)
	elif ResourceLoader.exists(path.replace(".png", "_normal.png")):
		m.normal_enabled=true
		m.normal_texture=load(path.replace(".png", "_normal.png"))
	m.uv1_triplanar=true
	m.uv1_scale=Vector3(2.0,2.0,2.0)
	m.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	return m

func setup_atmosphere() -> void:
	ambient=WorldEnvironment.new()
	ambient.name="MistAndSky"
	var e:=Environment.new()
	e.background_mode=Environment.BG_SKY
	var sky:=Sky.new()
	var s:=ProceduralSkyMaterial.new()
	s.sky_top_color=Color("53636a")
	s.sky_horizon_color=Color("89877e")
	s.ground_bottom_color=Color("435047")
	s.ground_horizon_color=Color("797e75")
	s.use_debanding=true
	sky.sky_material=s
	e.sky=sky
	e.ambient_light_source=Environment.AMBIENT_SOURCE_SKY
	e.reflected_light_source=Environment.REFLECTION_SOURCE_BG
	e.ambient_light_energy=.30
	e.tonemap_mode=Environment.TONE_MAPPER_FILMIC
	e.fog_enabled=true
	e.fog_light_color=Color("747975")
	e.fog_density=.0090
	e.fog_sky_affect=.36
	ambient.environment=e
	add_child(ambient)
	light_node=DirectionalLight3D.new()
	light_node.name="LowAutumnSun"
	light_node.light_color=Color("ffe3b9")
	light_node.light_energy=.48
	light_node.shadow_enabled=true
	light_node.rotation_degrees=Vector3(-48,29,-12)
	add_child(light_node)

func stream_x(z: float) -> float:
	return -20.0+4.4*sin(z*.075)+1.7*sin(z*.21)

func height_at(x: float,z: float) -> float:
	var hills: float = terrain_noise.get_noise_2d(x,z)*4.5+sin(x*.052)*1.15+cos(z*.069)*.76
	var ridge: float = 8.0*(1.0 - smoothstep(-56.0,-25.0,z)) + 3.0*smoothstep(28.0,53.0,x)
	var center: float = stream_x(z)
	var trench: float = 4.1*exp(-pow((x-center)/4.6,2))
	# Open central walkable meadow; rougher relief around its perimeter.
	var glade: float = 1.0 - .54*exp(-((x*x+(z-18.0)*(z-18.0))/340.0))
	return (hills + ridge)*glade-trench + small_noise.get_noise_2d(x,z)*.19

func terrain_color(x: float,z: float,y: float) -> Color:
	# Strong biome separation: cool creek, moss forest, amber hillside, pale ridges.
	var fleck:float = small_noise.get_noise_2d(x,z)
	var c := Color("74834f")
	if x > 23.0 and z < 24.0:
		c = Color("b08c55").lerp(Color("896b46"),.37+fleck*.22)
	elif x < -11.0 and z > -21.0:
		c = Color("526f57")
	elif z < -23.0:
		c = Color("6e795b")
	elif absf(x)<11.0 and z > -5.0 and z < 34.0:
		c = Color("8d995e")
	if absf(x-stream_x(z))<7.0: c = c.lerp(Color("465f58"),.52)
	if y>5.0: c = c.lerp(Color("a09272"),clampf((y-5.0)*.12,0.0,.45))
	return c.lerp(Color("d6c28f"),clampf(fleck*.10+.09,0.0,.20))

func terrain_biome(x: float, z: float) -> int:
	var near_water: float = absf(x-stream_x(z))
	if near_water < 6.8: return 3
	if x > 23.0 and z < 24.0: return 2
	if x < -12.0 and z > -25.0: return 1
	return 0

func build_terrain() -> void:
	# NO custom shader: it was showing up as a featureless near-white surface
	# on the user's GL Compatibility renderer. Use conventional Godot spatial
	# materials and photo-based diffuse/normal maps instead.
	var mat_paths: Array[String] = [
		"res://assets/textures/meadow_ground.png",
		"res://assets/textures/woodland_ground.png",
		"res://assets/textures/amber_ground.png",
		"res://assets/textures/river_silt.png"
	]
	var biome_names: Array[String] = ["OpenMeadow", "WoodlandSoil", "AutumnForest", "StreamBank"]
	# Keep biome render meshes separate, but create ONE continuous terrain physics surface.
	# Per-biome concave shapes exposed internal triangle edges and trapped the player.
	var collision_tool := SurfaceTool.new()
	collision_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var tools: Array[SurfaceTool] = []
	for biome in range(4):
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		tools.append(st)
	var grid_size: int = 126
	var extent: float = 144.0
	for zi in range(grid_size - 1):
		for xi in range(grid_size - 1):
			var x0: float = (float(xi)/float(grid_size-1)-.5)*extent
			var x1: float = (float(xi+1)/float(grid_size-1)-.5)*extent
			var z0: float = (float(zi)/float(grid_size-1)-.5)*extent
			var z1: float = (float(zi+1)/float(grid_size-1)-.5)*extent
			var biome: int = terrain_biome((x0+x1)*.5,(z0+z1)*.5)
			var tool: SurfaceTool = tools[biome]
			var p0 := Vector3(x0,height_at(x0,z0),z0)
			var p1 := Vector3(x1,height_at(x1,z0),z0)
			var p2 := Vector3(x0,height_at(x0,z1),z1)
			var p3 := Vector3(x1,height_at(x1,z1),z1)
			for v in [p0,p2,p1,p1,p2,p3]:
				var dx: float = height_at(v.x+.4,v.z)-height_at(v.x-.4,v.z)
				var dz: float = height_at(v.x,v.z+.4)-height_at(v.x,v.z-.4)
				tool.set_normal(Vector3(-dx, .8, -dz).normalized())
				tool.set_uv(Vector2(v.x*.16,v.z*.16))
				tool.set_color(terrain_color(v.x,v.z,v.y).lerp(Color.WHITE,.60))
				tool.add_vertex(v)
				collision_tool.add_vertex(v)
	var ground_root := Node3D.new()
	ground_root.name = "VisibleTexturedGround"
	add_child(ground_root)
	for biome in range(4):
		var generated_mesh: ArrayMesh = tools[biome].commit()
		if generated_mesh.get_surface_count() == 0: continue
		var visual := MeshInstance3D.new()
		visual.name = biome_names[biome]
		visual.mesh = generated_mesh
		var m := StandardMaterial3D.new()
		m.albedo_color = Color.WHITE  # keep photographic color, avoid double-tinting into flat gray
		m.albedo_texture = load(photo_or_fallback(mat_paths[biome]))
		m.vertex_color_use_as_albedo = true
		m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		m.roughness = 1.0
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		var normal_path: String = CC0_DIR + mat_paths[biome].get_file().get_basename() + "_normal.jpg"
		if ResourceLoader.exists(normal_path):
			m.normal_enabled = true
			m.normal_texture = load(normal_path)
		visual.material_override = m
		ground_root.add_child(visual)
	var terrain_body := StaticBody3D.new()
	terrain_body.name = "ContinuousTerrainCollision"
	terrain_body.collision_layer = 16
	terrain_body.collision_mask = 0
	var terrain_shape := CollisionShape3D.new()
	terrain_shape.shape = collision_tool.commit().create_trimesh_shape()
	terrain_body.add_child(terrain_shape)
	ground_root.add_child(terrain_body)
	# No physics bodies on individual biome render meshes: their borders are visual only.

func build_old_road() -> void:
	# A readable worn earth trail visually connects the clearing to the priory.
	# It follows the actual terrain, so it does not create a flat artificial floor.
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var steps := 112
	for i in range(steps):
		var z:float = 29.0 - float(i) * .65
		var x:float = sin(float(i)*.075)*2.15 + sin(float(i)*.19)*.45
		var half:float = 1.0 + .25*sin(float(i)*.21)
		for side in [-1.0,1.0]:
			var xx:float = x + half*side
			var point := Vector3(xx,height_at(xx,z)+.065,z)
			st.set_color(Color("a6875d").lerp(Color("695c44"),clampf((sin(float(i)*1.7)+1.0)*.23,0.0,.5)))
			st.set_uv(Vector2(float(i)*.10, 0.0 if side<0.0 else 1.0))
			st.add_vertex(point)
	for i in range(steps-1):
		var k:=i*2
		st.add_index(k);st.add_index(k+1);st.add_index(k+2)
		st.add_index(k+1);st.add_index(k+3);st.add_index(k+2)
	var trail:=MeshInstance3D.new()
	trail.name="OldPilgrimRoad"
	trail.mesh=st.commit()
	var material:=StandardMaterial3D.new()
	material.vertex_color_use_as_albedo=true
	material.albedo_texture=load(photo_or_fallback("res://assets/textures/earth_path.png"))
	material.roughness=1.0
	material.cull_mode=BaseMaterial3D.CULL_DISABLED
	trail.material_override=material
	add_child(trail)

func build_stone_ridges() -> void:
	# Distant vertical silhouettes provide a sense of region beyond the meadow.
	var ridge_stone := textured("res://assets/textures/stone.png",Color("817d70"))
	for p in [Vector3(-49,0,-39),Vector3(-41,0,-45),Vector3(-56,0,-48),Vector3(51,0,-35),Vector3(48,0,-46)]:
		var spire=SIM_OBJECT.new()
		spire.configure(self,"stone",next_sim_id)
		next_sim_id+=1
		sim_objects.append(spire)
		spire.name="RidgeOutcrop"
		spire.position=Vector3(p.x,height_at(p.x,p.z),p.z)
		add_child(spire)
		for j in range(3):
			var offset_x:float=sin(float(j)*2.3+p.x)*1.5
			var offset_z:float=cos(float(j)*1.8+p.z)*1.1
			var tall:float=5.0+float(j)*2.8
			ART.cone(spire,Vector3(offset_x,tall*.43,offset_z),1.8+float(j)*.38,tall,ridge_stone,.35,7)
			add_solid_box(spire, Vector3(offset_x,tall*.44,offset_z), Vector3(2.5+float(j)*.5, tall*.85, 2.5+float(j)*.5), "RockOutcropSolid")
	# One very large dead tree, deliberately isolated on a hill.
	var px:float=-37.0
	var pz:float=31.0
	spawn_tree(Vector3(px,height_at(px,pz),pz),"dead",2.2)

func build_first_words_cairn() -> void:
	# An authored landmark visible immediately after entering play.
	var cairn:=Node3D.new()
	cairn.name="FirstWordsCairn"
	cairn.position=Vector3(3.1,height_at(3.1,16.0),16.0)
	add_child(cairn)
	var stone:=textured("res://assets/textures/stone.png",Color("bcb09a"))
	ART.stone(cairn,Vector3(0,.4,0),Vector3(1.05,.78,.65),stone)
	ART.box(cairn,Vector3(0,1.45,0),Vector3(1.65,1.6,.43),stone)
	add_solid_box(cairn, Vector3(0,1.1,0), Vector3(1.65,2.2,.65), "InscribedCairnSolid")
	ART.box(cairn,Vector3(0,2.29,0),Vector3(1.8,.13,.54),stone)
	var inscription:=Label3D.new()
	inscription.name="InscriptionInStone"
	inscription.text="V E R B A\n\nIGNIS   •   fire\nPLUVIA   •   rain\nCRESCE   •   grow"
	inscription.font_size=36
	inscription.pixel_size=.0043
	inscription.modulate=Color("3c2c21")
	inscription.outline_size=0
	inscription.position=Vector3(0,1.42,.246)
	cairn.add_child(inscription)
	var lamp:=OmniLight3D.new()
	lamp.position=Vector3(0,2.8,.3)
	lamp.light_color=Color("eec38b")
	lamp.light_energy=.7
	lamp.omni_range=4.0
	cairn.add_child(lamp)
	ART.orb(cairn,Vector3(0,2.62,.25),Vector3(.07,.09,.07),ART.mat(Color("f3d3a2"),.3,Color("a37342")),12)

func build_water() -> void:
	var water:=Node3D.new()
	water.name="WindingStream"
	add_child(water)
	var st:=SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(68):
		var z:float=-61.0+float(i)*1.8
		var x:float=stream_x(z)
		var y:float=height_at(x,z)+1.55
		for side in [-1,1]:
			st.set_uv(Vector2(float(i)*.12,0.0 if side==-1 else 1.0))
			st.add_vertex(Vector3(x+side*2.25,y,z))
	for i in range(67):
		var k=i*2
		st.add_index(k);st.add_index(k+2);st.add_index(k+1)
		st.add_index(k+1);st.add_index(k+2);st.add_index(k+3)
	st.generate_normals()
	var n:=MeshInstance3D.new()
	n.mesh=st.commit()
	var m:=ShaderMaterial.new()
	m.shader=load("res://assets/materials/stream.gdshader")
	n.material_override=m
	water.add_child(n)
	for z in range(-54,57,9):
		var x=stream_x(float(z))
		for side in [-1,1]:
			var sx: float = float(x) + float(side) * rng.randf_range(2.7, 5.5)
			ART.stone(water,Vector3(sx,height_at(sx,float(z))+.15,float(z)),Vector3(rng.randf_range(.5,1.1),.25,rng.randf_range(.4,.8)),stone_mat)

func build_landmarks() -> void:
	var ruins:=Node3D.new()
	ruins.name="TheFallenPriory"
	ruins.position=Vector3(4,height_at(4,-35),-35)
	add_child(ruins)
	# The priory has empty space between structures and a legible broken silhouette.
	ART.arch(ruins,Vector3(0,0,0),3.4,3.2,stone_mat)
	ART.box(ruins,Vector3(-5.0,1.6,-3.8),Vector3(.85,3.2,7.2),stone_mat)
	ART.box(ruins,Vector3(5.0,1.6,-3.8),Vector3(.85,3.2,7.2),stone_mat)
	ART.box(ruins,Vector3(0,1.15,-7.3),Vector3(10.4,2.3,.85),stone_mat)
	ART.arch(ruins,Vector3(0,0,-7.0),1.8,1.8,ART.mat(Color("928d7b")))
	for i in range(7):
		var px=rng.randf_range(-5.5,5.5)
		var pz=rng.randf_range(-9,1)
		ART.stone(ruins,Vector3(px,.28,pz),Vector3(rng.randf_range(.3,.95),.2,.36),stone_mat)
	ART.bone(ruins,Vector3(-4.5,3.2,-7.2),Vector3(-1.4,5.3,-6.9),.37,.2,stone_mat,7)
	ART.bone(ruins,Vector3(4.4,3.1,-7.3),Vector3(1.5,4.9,-7.1),.38,.2,stone_mat,7)
	for j in range(9):
		var xp=-3.8+j*.95
		ART.box(ruins,Vector3(xp,.12,-6.4),Vector3(.55,.11,.52),stone_mat,Vector3(0,.15*j,0))
	# Broken arch on a ridge; visible from starting clearing.
	var arch:=Node3D.new()
	arch.name="RidgeArch"
	arch.position=Vector3(33,height_at(33,-22),-22)
	add_child(arch)
	ART.arch(arch,Vector3.ZERO,2.25,3.0,stone_mat)
	# The hermit's REAL, furnished timber-frame cottage: authored external glTF.
	# Separate walls, open entrance, roof tiles, joinery, window casements, hearth,
	# furnishings and weathered surfaces; no placeholder solid cube.
	# Priory perimeter walls are physical obstacles, not merely visual geometry.
	add_solid_box(ruins, Vector3(-5.0, 1.6, -3.8), Vector3(.9, 3.25, 7.3), "PrioryWestWall")
	add_solid_box(ruins, Vector3( 5.0, 1.6, -3.8), Vector3(.9, 3.25, 7.3), "PrioryEastWall")
	add_solid_box(ruins, Vector3(0.0, 1.15, -7.3), Vector3(10.4, 2.3, .9), "PrioryBackWall")
	add_solid_box(arch, Vector3(-1.2, 1.35, 0), Vector3(.7, 2.7, .8), "RidgeArchPillarWest")
	add_solid_box(arch, Vector3( 1.2, 1.35, 0), Vector3(.7, 2.7, .8), "RidgeArchPillarEast")
	var cabin := Node3D.new()
	cabin.name = "HermitCottage"
	cabin.position = Vector3(29, height_at(29, 8), 8)
	cabin.rotation.y = -.28
	add_child(cabin)
	var cottage_asset: PackedScene = load("res://assets/models/authored/Cottage_The_Hermit.glb")
	if cottage_asset != null:
		var cottage_model := cottage_asset.instantiate()
		cottage_model.name = "TimberStoneCottage"
		cabin.add_child(cottage_model)
		apply_cottage_photographic_materials(cottage_model)
	# An independently solid cottage shell with doorway, floor, chimney and walls.
	# The source GLB is visual artwork only and supplies NO physics by default.
	add_solid_box(cabin, Vector3(-3.02, 1.8, 0), Vector3(.42, 3.5, 5.5), "WestCottageWall")
	add_solid_box(cabin, Vector3( 3.02, 1.8, 0), Vector3(.42, 3.5, 5.5), "EastCottageWall")
	add_solid_box(cabin, Vector3(0, 1.8, -2.55), Vector3(6.1, 3.5, .45), "BackCottageWall")
	add_solid_box(cabin, Vector3(-2.05, 1.7, 2.55), Vector3(1.95, 3.4, .45), "FrontCottageWallWest")
	add_solid_box(cabin, Vector3( 1.47, 1.7, 2.55), Vector3(3.0, 3.4, .45), "FrontCottageWallEast")
	add_solid_box(cabin, Vector3(-.69, 2.95, 2.55), Vector3(1.15, .8, .4), "FrontCottageLintel")
	add_solid_box(cabin, Vector3(-.69, 1.3, 2.55), Vector3(1.02, 2.5, .27), "ClosedWoodenDoor")
	add_solid_box(cabin, Vector3(0, .15, 0), Vector3(6.75, .3, 5.85), "StoneCottageFloor")
	# Physical obstacles remain separate nodes so future spells can alter them.
	# Small shrine away from main path.
	var shrine:=Node3D.new()
	shrine.name="StonePrayerShrine"
	shrine.position=Vector3(-8,height_at(-8,-7),-7)
	add_child(shrine)
	ART.box(shrine,Vector3(0,.4,0),Vector3(1.8,.8,1.4),stone_mat)
	add_solid_box(shrine, Vector3(0,.65,0), Vector3(1.8,1.3,1.4), "StoneShrineBlock")
	ART.box(shrine,Vector3(0,1.4,-.3),Vector3(1.4,1.7,.5),stone_mat)
	ART.bone(shrine,Vector3(0,1.9,-.2),Vector3(0,2.6,-.2),.10,.08,ART.mat(Color("77736b")))
	ART.bone(shrine,Vector3(-.45,2.27,-.2),Vector3(.45,2.27,-.2),.07,.07,ART.mat(Color("77736b")))
	# Winding line of worn stepping stones, not a linear grid of objects.
	for i in range(18):
		var z=18.0-float(i)*2.2
		var x=sin(float(i)*.43)*2.6
		ART.stone(self,Vector3(x,height_at(x,z)+.05,z),Vector3(rng.randf_range(.25,.7),.06,rng.randf_range(.24,.7)),stone_mat)

func add_solid_box(parent: Node3D, local_center: Vector3, size: Vector3, label: String) -> StaticBody3D:
	# Physics-only collider for authored static architecture (collision bit 5).
	var solid := StaticBody3D.new()
	solid.name = label
	solid.collision_layer = 16
	solid.collision_mask = 0
	var shape_node := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	shape_node.shape = shape
	shape_node.position = local_center
	solid.add_child(shape_node)
	parent.add_child(solid)
	return solid

func apply_cottage_photographic_materials(root: Node) -> void:
	# Retains authored modeled geometry. Once CC0 photographs are installed by
	# GET_REAL_TEXTURES.bat, they replace procedural draft material patterns.
	# No network dependency during play or opening the Godot project.
	var photo_slots := {
		"lime": "cottage_plaster",
		"plaster": "cottage_plaster",
		"slate": "cottage_roof",
		"oak": "cottage_wood",
		"wood": "cottage_wood",
		"stone": "stone"
	}
	for child in root.find_children("*", "MeshInstance3D", true, false):
		var mesh_child: MeshInstance3D = child
		var name_lower: String = String(mesh_child.name).to_lower()
		var key := ""
		for text_key in photo_slots.keys():
			if name_lower.contains(text_key):
				key = String(photo_slots[text_key]); break
		if key.is_empty(): continue
		var path: String = CC0_DIR + key + "_diffuse.jpg"
		if not ResourceLoader.exists(path): continue
		if mesh_child.mesh == null or mesh_child.mesh.get_surface_count() == 0: continue
		var old_mat: Material = mesh_child.mesh.surface_get_material(0)
		if not (old_mat is StandardMaterial3D): continue
		var m := old_mat.duplicate() as StandardMaterial3D
		m.albedo_texture = load(path)
		m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		mesh_child.material_override = m

func build_forest() -> void:
	# Curated zones: sparse meadow, cool stream, amber eastern grove, dark ridge.
	for i in range(38):
		var x=rng.randf_range(-59,59)
		var z=rng.randf_range(-59,59)
		var near_meadow:bool= (x*x+(z-11.0)*(z-11.0))<175.0
		var near_path:bool=absf(x-sin((19.0-z)*.18)*2.7)<6.0 and z>-32 and z<27
		var near_ruin:bool=Vector2(x,z).distance_to(Vector2(4,-35))<12.0
		var near_cabin:bool=Vector2(x,z).distance_to(Vector2(29,8))<8.0
		if near_meadow or near_path or near_ruin or near_cabin: continue
		if absf(x-stream_x(z))<6.8: continue
		var kind: String = "autumn" if x>20 else "pine" if z<-28 else "broadleaf"
		spawn_tree(Vector3(x,height_at(x,z),z),kind,rng.randf_range(.72,1.65))
	# A single skeletal tree as an intentional landmark to the west.
	spawn_tree(Vector3(-11,height_at(-11,12),12),"dead",1.65)
	# Golden grove anchor near cottage with visible separation.
	for a in [Vector2(18,2),Vector2(42,12),Vector2(36,-3),Vector2(21,20),Vector2(40,24)]:
		spawn_tree(Vector3(a.x,height_at(a.x,a.y),a.y),"autumn",rng.randf_range(1.1,1.65))

func spawn_tree(p: Vector3,kind: String,scale_factor: float=1.0) -> Node3D:
	# Irregular tapered bole, three-dimensional crown, twigs and articulated leaves.
	# Authored canopy gaps keep the animal silhouettes visible through the grove.
	var node=SIM_OBJECT.new()
	node.configure(self,"dead_tree" if kind=="dead" else "tree",next_sim_id,scale_factor)
	next_sim_id += 1
	sim_objects.append(node)
	node.name="%sTree" % kind.capitalize()
	node.position=p
	node.scale=Vector3.ONE*scale_factor
	add_child(node)
	navigation_blockers.append(Vector3(p.x, 0.0, p.z))
	flora.append(node)
	var r:=RandomNumberGenerator.new()
	r.seed=int(absf(p.x*261.7+p.z*991.2))+rng.randi_range(0,8000)
	var trunk_h:float=7.5 if kind=="pine" else 5.0 if kind!="dead" else 8.7
	var dark:Material=bark_dark if kind=="pine" or kind=="dead" else bark_mat
	var trunk_width:float = .31 if kind=="pine" else .45
	# Optional CC0 trees replace the procedural mesh while keeping the same
	# ecology state and collision body. Installed via INSTALL_VERBA_ASSETS.bat.
	var external_name: String = "tree3.glb" if kind == "pine" else "tree2.glb" if kind == "autumn" else "tree1.glb"
	var external: bool = kind != "dead" and EXTERNAL_ART.attach_scaled(node, "res://assets/models/cc0/" + external_name, 7.5 if kind == "pine" else 9.0)
	if not external:
		ART.bone(node,Vector3(0,-.1,0),Vector3(.09,trunk_h,0),trunk_width,trunk_width*.38,dark,11)
		for root_i in range(5):
			var a:float=TAU*float(root_i)/5.0+r.randf_range(-.25,.25)
			ART.bone(node,Vector3(.06,.54,0),Vector3(cos(a)*r.randf_range(.65,1.2),.02,sin(a)*r.randf_range(.65,1.2)),.13,.018,dark,6)
		var ends:Array=[]
		if kind == "pine":
			for level in range(7):
				var f:float=float(level)/7.0
				var height:float=1.8+f*6.3
				for branch_i in range(8):
					var angle:float=TAU*float(branch_i)/8.0+f*2.5
					var reach:float=3.0*(1.0-f*.82)*r.randf_range(.78,1.14)
					var tip:=Vector3(cos(angle)*reach,height-.35+f*.25,sin(angle)*reach)
					ART.bone(node,Vector3(.05,height,0),tip,.13*(1.0-f*.5),.026,dark,7)
					ends.append(tip)
			var crown:=Node3D.new()
			crown.name="LivingCanopy"
			node.add_child(crown)
			FOLIAGE.make_conifer_needles(crown,ends,r.randi())
		else:
			for b in range(7):
				var theta:float=TAU*float(b)/7.0+r.randf_range(-.25,.25)
				var start:=Vector3(.07,trunk_h*r.randf_range(.52,.78),0)
				var end:=Vector3(cos(theta)*r.randf_range(2.1,3.6),trunk_h+r.randf_range(-.3,1.9),sin(theta)*r.randf_range(1.9,3.45))
				ART.bone(node,start,end,.20,.045,dark,8)
				for twig in range(3):
					var twig_theta:float=theta+r.randf_range(-.75,.75)
					var twig_tip:=end+Vector3(cos(twig_theta)*r.randf_range(.45,1.4),r.randf_range(-.25,1.1),sin(twig_theta)*r.randf_range(.45,1.5))
					ART.bone(node,end,twig_tip,.07,.015,dark,6)
					ends.append(twig_tip)
			if kind!="dead":
				var crown:=Node3D.new()
				crown.name="LivingCanopy"
				node.add_child(crown)
				FOLIAGE.make_broadleaf_crown(crown,ends,kind,r.randi())
	var collider:=StaticBody3D.new()
	collider.name="TrunkCollider"
	collider.collision_layer=4|16
	collider.collision_mask=0
	collider.set_meta("flora_ref",node)
	var shape:=CollisionShape3D.new()
	var cylinder:=CylinderShape3D.new()
	cylinder.height=trunk_h*.85
	cylinder.radius=trunk_width
	shape.shape=cylinder
	shape.position.y=trunk_h*.42
	collider.add_child(shape)
	node.add_child(collider)
	return node

func build_scatter() -> void:
	# Rocks grow in groups beside gullies and old masonry, not a random grid of props.
	var mossy := textured("res://assets/textures/moss.png",Color("d5d9c7"))
	for cluster in [Vector2(-15,-19),Vector2(-31,11),Vector2(22,-27),Vector2(50,37),Vector2(-44,-36),Vector2(9,-51)]:
		for i in range(rng.randi_range(4,9)):
			var x:float=cluster.x+rng.randf_range(-4.5,4.5)
			var z:float=cluster.y+rng.randf_range(-4.5,4.5)
			var width:float=rng.randf_range(.25,1.2)
			spawn_reactive_stone(Vector3(x,height_at(x,z),z), Vector3(width,width*rng.randf_range(.5,.95),width*rng.randf_range(.65,1.4)),stone_mat if i%3 else mossy)
	for z in range(-54,56,8):
		var x:float=stream_x(float(z))
		for side in [-1,1]:
			var px:float=x+float(side)*rng.randf_range(2.7,5.1)
			spawn_reactive_stone(Vector3(px,height_at(px,float(z)),float(z)),Vector3(.56,.32,.48),stone_mat)
	# One intentionally placed log: richer silhouette, textured bark, branching roots.
	var log=SIM_OBJECT.new()
	log.configure(self,"wood",next_sim_id)
	next_sim_id += 1
	sim_objects.append(log)
	log.name="FallenSplitOak"
	log.position=Vector3(-4,height_at(-4,-18),-18)
	add_child(log)
	ART.bone(log,Vector3(-2,.43,0),Vector3(2,.54,1.3),.43,.32,bark_mat,12)
	add_solid_box(log, Vector3(0,.5,.65), Vector3(4.25,.80,1.55), "FallenOakSolid")
	for i in range(6):
		var t:float=float(i)/6.0
		ART.bone(log,Vector3(t*3.2-1.7,.5,t*.9),Vector3(t*3.2-1.9,.35,t*.9+1.35),.095,.014,bark_dark,7)

func spawn_reactive_stone(point: Vector3, dimensions: Vector3, surface: Material) -> Node3D:
	var rock=SIM_OBJECT.new()
	rock.configure(self,"stone",next_sim_id)
	next_sim_id += 1
	rock.name="Stone_%d" % rock.uid
	rock.position=point
	add_child(rock)
	sim_objects.append(rock)
	ART.stone(rock,Vector3(0,dimensions.y*.22,0),dimensions,surface)
	var collider:=StaticBody3D.new()
	collider.name="RockTarget"
	collider.collision_layer=4|16
	collider.collision_mask=0
	collider.set_meta("flora_ref",rock)
	var hitbox:=CollisionShape3D.new()
	var volume:=SphereShape3D.new()
	volume.radius=maxf(.22,dimensions.x*.45)
	hitbox.shape=volume
	hitbox.position.y=dimensions.y*.35
	collider.add_child(hitbox)
	rock.add_child(collider)
	return rock

func make_living_plant(point: Vector3, plant_kind: String, mesh: Mesh, material: Material, factor: float) -> Node3D:
	var plant=SIM_OBJECT.new()
	plant.configure(self,plant_kind,next_sim_id,factor)
	next_sim_id += 1
	plant.name="%s_%d" % [plant_kind.capitalize(),plant.uid]
	plant.position=point
	add_child(plant)
	sim_objects.append(plant)
	var leaf_mesh:=MeshInstance3D.new()
	leaf_mesh.name="PlantVisual"
	leaf_mesh.mesh=mesh
	leaf_mesh.material_override=material
	plant.add_child(leaf_mesh)
	var body:=StaticBody3D.new()
	body.collision_layer=4
	body.collision_mask=0
	body.set_meta("flora_ref",plant)
	var shape:=CollisionShape3D.new()
	var sphere:=SphereShape3D.new()
	sphere.radius=.40 if plant_kind=="fern" else .25
	shape.shape=sphere
	shape.position.y=.29
	body.add_child(shape)
	plant.add_child(body)
	return plant

func populate_reactive_grass() -> void:
	# Decorative blades remain batched; every large, harvestable patch is an
	# independent stateful object that animals can eat, rain can hydrate and
	# fire can destroy. The distinction keeps the game responsive.
	var clump_mesh: ArrayMesh=FOLIAGE.grass_mesh()
	var material:=StandardMaterial3D.new()
	material.vertex_color_use_as_albedo=true
	material.cull_mode=BaseMaterial3D.CULL_DISABLED
	material.roughness=1.0
	material.albedo_texture=load("res://assets/textures/grass.png")
	var r:=RandomNumberGenerator.new()
	r.seed=54001
	for i in range(115):
		var x:=r.randf_range(-52,52)
		var z:=r.randf_range(-56,56)
		if absf(x)<4 and z>-30 and z<28: continue
		make_living_plant(Vector3(x,height_at(x,z)+.03,z),"grass",clump_mesh,material,r.randf_range(1.3,2.8))

func spawn_growth_patch(point: Vector3) -> Node3D:
	# Cap independently instantiated patches; decorative vegetation is batched.
	if sim_objects.size()>650: return null
	var mesh: ArrayMesh=FOLIAGE.grass_mesh()
	var material:=StandardMaterial3D.new()
	material.vertex_color_use_as_albedo=true
	material.cull_mode=BaseMaterial3D.CULL_DISABLED
	material.roughness=1.0
	material.albedo_texture=load("res://assets/textures/grass.png")
	var p:=Vector3(point.x,height_at(point.x,point.z),point.z)
	return make_living_plant(p,"grass",mesh,material,1.7)

func nearest_food(pos3: Vector3, radius: float=9.0) -> Node3D:
	var chosen:Node3D=null
	var best:=radius
	for obj in sim_objects:
		if not is_instance_valid(obj) or obj.kind not in ["grass","fern"] or obj.dead or obj.food < .16: continue
		var d:float=obj.global_position.distance_to(pos3)
		if d<best: best=d;chosen=obj
	return chosen

func ecology_step(dt: float) -> void:
	# Real simulation ticks are independent of player casting and run even
	# when the player stands still. Each object's state can diverge over time.
	for obj in sim_objects:
		if not is_instance_valid(obj):continue
		var nearby_fire:float=nearest_fire_distance(obj.global_position)
		# Stream-bank plants get a little moisture without waiting for the player.
		if absf(obj.global_position.x-stream_x(obj.global_position.z))<5.0:
			obj.apply_effect("wet",dt*.025)
		obj.simulate(dt,raining,nearby_fire,wind)
		if obj.burning and not obj.dead and nearby_fire>1.5:
			add_fire(obj.global_position,obj)
	# A tiny chance of a self-contained ecological disturbance. Fire can
	# propagate, grazing depletes food, animals hunt and the plants regenerate.
	if not raining and rng.randf()<dt*.008:
		var heat_sources: Array=[]
		for obj in sim_objects:
			if is_instance_valid(obj) and obj.burning:heat_sources.append(obj)
		if heat_sources.size()>0:
			var source=heat_sources[rng.randi_range(0,heat_sources.size()-1)]
			for obj in sim_objects:
				if obj != source and is_instance_valid(obj) and obj.flammable() and obj.global_position.distance_to(source.global_position)<3.5 and obj.water<.38:
					if obj.apply_effect("ignite"):
						add_fire(obj.global_position,obj)
						break

func setup_rain() -> void:
	rain_fx=GPUParticles3D.new()
	rain_fx.name="RainAroundPlayer"
	rain_fx.amount=360
	rain_fx.lifetime=1.2
	rain_fx.emitting=false
	rain_fx.local_coords=true
	rain_fx.position=Vector3(0,7,0)
	var proc:=ParticleProcessMaterial.new()
	proc.emission_shape=ParticleProcessMaterial.EMISSION_SHAPE_BOX
	proc.emission_box_extents=Vector3(13,1,13)
	proc.direction=Vector3(0,-1,0)
	proc.initial_velocity_min=10
	proc.initial_velocity_max=15
	proc.gravity=Vector3(0,-6,0)
	proc.spread=7
	rain_fx.process_material=proc
	var streak:=CylinderMesh.new()
	streak.height=.12
	streak.top_radius=.004
	streak.bottom_radius=.004
	var wet:=ART.mat(Color(.66,.76,.77,.62))
	wet.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	streak.material=wet
	rain_fx.draw_pass_1=streak
	add_child(rain_fx)

func populate_wildlife() -> void:
	var positions=[
		["hare",Vector2(7,7)],["hare",Vector2(-9,4)],["hare",Vector2(18,-8)],
		["deer",Vector2(12,-19)],["deer",Vector2(-3,-25)],["fox",Vector2(22,23)],
		["wolf",Vector2(-39,-30)],["crow",Vector2(-6,18)],["crow",Vector2(30,-16)],
		["wisp",Vector2(-30,2)]
	]
	for row in positions:
		var pos2: Vector2=row[1]
		var n=CREATURE_SCRIPT.new()
		n.setup(self,row[0],Vector3(pos2.x,height_at(pos2.x,pos2.y),pos2.y),rng.randi())
		add_child(n)
		creatures.append(n)

func populate_collectibles() -> void:
	for w in [
		["leaf","ventus",Vector2(1,23)],["leaf","muta",Vector2(-8,-8)],
		["leaf","fuge",Vector2(5,-30)],["leaf","aqua",Vector2(-16,16)],
		["leaf","arde",Vector2(29,12)],["leaf","surge",Vector2(33,-21)],
		["leaf","siste",Vector2(14,-13)],["leaf","nox",Vector2(-7,-24)],
		["leaf","gelu",Vector2(-29,-1)],["leaf","flamma",Vector2(37,4)]
	]:
		var xy:Vector2=w[2]
		spawn_item(w[0],w[1],Vector3(xy.x,height_at(xy.x,xy.y),xy.y))
	for w in [
		["lantern",Vector2(1.8,22)],["stone",Vector2(4,11)],["herb",Vector2(6,7)],["torch",Vector2(13,20)],
		["amber",Vector2(18,10)],["stone",Vector2(-4,2)]
	]:
		var xy:Vector2=w[1]
		spawn_item(w[0],"",Vector3(xy.x,height_at(xy.x,xy.y),xy.y))

func spawn_item(kind: String, word_key: String, p: Vector3) -> void:
	var i=PICKUP_SCRIPT.new()
	i.setup(self,kind,word_key,p)
	add_child(i)
	items.append(i)

func collect(item) -> void:
	if not is_instance_valid(item): return
	if item.item_type != "leaf" and player.inventory.size() >= 6:
		player.say_world("Hands full",item.global_position+Vector3.UP*.5,Color("c7a98e"))
		return
	if item.item_type == "leaf":
		player.book.learn(item.word)
		player.say_world("+ " + item.word.to_upper(),item.global_position+Vector3.UP*.6,Color("dfc287"))
	else:
		player.add_item(item.item_type)
	items.erase(item)
	item.queue_free()

func nearest_creature(pos3: Vector3,kind: String,distance: float) -> Node3D:
	var found: Node3D=null
	var dist=distance
	for c in creatures:
		if not is_instance_valid(c) or c.species != kind or c.dead: continue
		var d=pos3.distance_to(c.global_position)
		if d < dist:
			found=c
			dist=d
	return found

func wolf_distance(pos3: Vector3) -> float:
	var d=9999.0
	for c in creatures:
		if is_instance_valid(c) and c.species=="wolf": d=minf(d,c.global_position.distance_to(pos3))
	return d

func nearest_fire_distance(pos3: Vector3) -> float:
	var d=9999.0
	for f in fires:
		if is_instance_valid(f): d=minf(d,f.global_position.distance_to(pos3))
	return d

func set_rain(seconds: float) -> void:
	rain_remaining=maxf(rain_remaining,seconds)
	raining=true
	if rain_fx != null: rain_fx.emitting=true

func add_fire(pos3: Vector3, target: Node3D=null) -> void:
	if raining and rng.randf()<.72: return
	for f in fires:
		if is_instance_valid(f) and f.global_position.distance_to(pos3)<2.0: return
	var source:=Node3D.new()
	source.name="ActualFire"
	source.position=Vector3(pos3.x,height_at(pos3.x,pos3.z)+.2,pos3.z)
	add_child(source)
	for i in range(5):
		var amber=ART.mat(Color("e4a45f"),.3,Color("b35124"))
		var s=ART.orb(source,Vector3(rng.randf_range(-.35,.35),.4+rng.randf_range(0,.5),rng.randf_range(-.35,.35)),Vector3(rng.randf_range(.13,.3),rng.randf_range(.35,.65),rng.randf_range(.13,.3)),amber,9)
		s.set_meta("fire_flicker",true)
	var light:=OmniLight3D.new()
	light.name="Firelight"
	light.light_color=Color("f19c57")
	light.light_energy=1.2
	light.omni_range=6.0
	light.position.y=1.0
	source.add_child(light)
	source.set_meta("time_to_live",rng.randf_range(14,28))
	fires.append(source)
	if target != null and is_instance_valid(target) and target.has_method("apply_effect"):
		target.apply_effect("ignite")
	elif target != null and is_instance_valid(target) and target.has_meta("burning"):
		target.set_meta("burning",true)

func extinguish() -> void:
	for f in fires:
		if is_instance_valid(f): f.queue_free()
	fires.clear()
	for obj in sim_objects:
		if is_instance_valid(obj):obj.apply_effect("cold",1.0)

func _process(delta: float) -> void:
	time += delta
	if player == null: return
	natural_weather_timer += delta
	if natural_weather_timer >= natural_weather_at:
		natural_weather_timer = 0.0
		natural_weather_at = rng.randf_range(48.0,115.0)
		wind = rng.randf_range(-2.5,2.5)
		if rng.randf() < .37:set_rain(rng.randf_range(14.0,29.0))
	if rain_remaining>0:
		rain_remaining-=delta
		if not raining: raining=true
		if rain_fx!=null:
			rain_fx.global_position=player.global_position+Vector3(0,8,0)
	elif raining:
		raining=false
		if rain_fx!=null: rain_fx.emitting=false
	if night_remaining>0:
		night_remaining-=delta
		light_node.light_energy=lerpf(light_node.light_energy,.18,minf(1.0,delta*1.6))
	else:
		light_node.light_energy=lerpf(light_node.light_energy,.85,minf(1.0,delta*.3))
	ecology_timer += delta
	if ecology_timer >= .5:
		var elapsed:float=ecology_timer
		ecology_timer=0.0
		ecology_step(elapsed)
	if raining and fires.size()>0: extinguish()
	for f in fires.duplicate():
		if not is_instance_valid(f):
			fires.erase(f)
			continue
		var remain:float=float(f.get_meta("time_to_live"))-delta
		f.set_meta("time_to_live",remain)
		var light=f.get_node_or_null("Firelight")
		if light!=null: light.light_energy=1.1+sin(time*9+f.position.x)*.25
		if remain<=0:
			fires.erase(f)
			f.queue_free()
			continue
		for c in creatures:
			if is_instance_valid(c) and f.global_position.distance_to(c.global_position)<2.0:
				c.panic=maxf(c.panic,3.0)
		if rng.randf()<delta*.06:
			# Actual propagation occurs near burnable tree roots, not random teleports.
			for t in flora:
				if is_instance_valid(t) and t.global_position.distance_to(f.global_position)<3.4 and not bool(t.get_meta("burning")) and float(t.get_meta("wetness"))<.35:
					add_fire(t.global_position + Vector3(rng.randf_range(-.5,.5),0,rng.randf_range(-.5,.5)),t)
					break
