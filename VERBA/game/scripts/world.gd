extends Node3D
## VERBA v0.5: one authored valley, rather than a random pile of primitives.
const ART = preload("res://scripts/art.gd")
const RUIN_ART = preload("res://scripts/ruin_art.gd")
const HOME_DRESSING = preload("res://scripts/home_dressing.gd")
const GROUND_DRESSING = preload("res://scripts/ground_dressing.gd")
const SCENIC_DETAILS = preload("res://scripts/scenic_details.gd")
const FOLIAGE = preload("res://scripts/foliage.gd")
const PLAYER_SCRIPT = preload("res://scripts/player.gd")
const CREATURE_SCRIPT = preload("res://scripts/creature.gd")
const PICKUP_SCRIPT = preload("res://scripts/pickup.gd")
const MAGIC_SCRIPT = preload("res://scripts/magic.gd")
const SCHOLAR = preload("res://scripts/scholar.gd")
const SOCIAL = preload("res://scripts/dialogue_social.gd")
const VILLAGE_SIM = preload("res://scripts/village_sim.gd")
const WORLD_CALENDAR = preload("res://scripts/world_calendar.gd")
const VILLAGE_WORKPLACES = preload("res://scripts/village_workplaces.gd")
const SIM_LAB = preload("res://scripts/simulation_lab.gd")
const NPC_ACTOR = preload("res://scripts/npc_actor.gd")
const CONSTRUCTION = preload("res://scripts/tower_construction.gd")
const SIM_OBJECT = preload("res://scripts/sim_object.gd")
const NAV_BUILDER = preload("res://scripts/navigation_builder.gd")
const EXTERNAL_ART = preload("res://scripts/external_art.gd")
const STORYBOOK_HOUSE = preload("res://scripts/storybook_house.gd")
const LANDMARK_TREE = preload("res://scripts/landmark_tree.gd")
const WORLD_PERSIST = preload("res://scripts/world_persistence.gd")
const STRANGE_ROAD = preload("res://scripts/strange_road.gd")
const LATIN_WAYSTONE = preload("res://scripts/latin_waystone.gd")
const MATERIAL_EXCHANGE = preload("res://scripts/material_exchange.gd")
var player
var magic
var scholar
var creatures: Array = []
var npcs: Array = []
# Adoption selects an existing persistent wild animal: no second pet entity.
var familiar_id: String = ""
var familiar_mode: String = "follow"
var construction
var harvest_counts: Dictionary = {}
var social
var forest_waystone
var village_sim
var world_calendar = WORLD_CALENDAR.new()
var workplaces
var simulation_lab
var village_elapsed: float = 0.0
var navigation_blockers: Array[Vector3] = []
var navigation_region: NavigationRegion3D
var sim_objects: Array = []
var next_sim_id: int = 1
var ecology_timer: float = 0.0
var distant_object_elapsed: Dictionary = {}
var autosave_elapsed: float = 0.0
var natural_weather_timer: float = 0.0
var natural_weather_at: float = 80.0
var spontaneous_events: int = 0
var flora: Array = []
var items: Array = []
var collected_pickup_ids: Array[String] = []
# Immutable spawn templates allow loading older saves in an already-running world.
var authored_pickup_templates: Dictionary = {}
var next_drop_serial: int = 1
var fires: Array = []
var rain_fx: GPUParticles3D
var raining := false
var rain_remaining := 0.0
var wind := 0.0
var night_remaining := 0.0
var night_visual_blend: float = 0.0  # actual moonlit sky/ambient, not just sun dimming
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
	# The road is blended into the terrain atlas offline; no floating road mesh.
	build_landmarks()
	STRANGE_ROAD.build(self)
	build_stone_ridges()
	build_first_words_cairn()
	build_plural_tablet()
	build_forest()
	build_scatter()
	GROUND_DRESSING.populate(self)
	HOME_DRESSING.populate(self)
	SCENIC_DETAILS.populate(self)
	build_water()
	FOLIAGE.populate_grass(self)
	FOLIAGE.populate_ferns(self)
	FOLIAGE.populate_litter(self)
	populate_reactive_grass()
	navigation_region = NAV_BUILDER.install(self)
	magic=MAGIC_SCRIPT.new(self)
	scholar=SCHOLAR.new()
	social=SOCIAL.new()
	village_sim=VILLAGE_SIM.new(ground_seed)
	# Playable world jobs require someone to reach and work at the location.
	# Standalone headless simulation keeps its fast deterministic work model.
	village_sim.spatial_work_enabled=true
	social.village_sim=village_sim
	workplaces=VILLAGE_WORKPLACES.new()
	workplaces.setup(self)
	add_child(workplaces)
	populate_social_npcs()
	forest_waystone=LATIN_WAYSTONE.new()
	forest_waystone.setup(self)
	add_child(forest_waystone)
	# Debug HUD is opt-in; it does not alter ordinary game input or saves.
	simulation_lab=SIM_LAB.new()
	simulation_lab.setup(self)
	add_child(simulation_lab)
	construction=CONSTRUCTION.new(self)
	player=PLAYER_SCRIPT.new()
	player.name="Player"
	player.world=self
	player.position=Vector3(0,height_at(0,26)+.12,26)
	add_child(player)
	populate_wildlife()
	populate_collectibles()
	setup_rain()
	# Rendered gameplay resumes its living ecosystem; headless tests begin clean.
	if DisplayServer.get_name() != "headless":
		load_world()

func populate_social_npcs() -> void:
	# People are distinct authored world entities, not placed UI stations.
	# They do not consume sim_object IDs or disturb existing save identities.
	for key in social.definitions.keys():
		var actor = NPC_ACTOR.new()
		actor.setup(self,social.npc(String(key)))
		add_child(actor)
		npcs.append(actor)

func harvest_resource(source: Node3D) -> Dictionary:
	# A small sustainable starter loop: salvage existing cut logs and
	# loosen exposed stones from the valley. No mining through a wall.
	if not is_instance_valid(source) or player == null:
		return {"ok":false,"message":"There is nothing to gather."}
	if player.global_position.distance_to(source.global_position) > 3.8:
		return {"ok":false,"message":"That material is beyond your reach."}
	if player.inventory.size()>=6:
		return {"ok":false,"message":"Your hands are full."}
	# Living plants are harvestable matter, not inexhaustible pickup spawners.
	# Food is already saved and shared with wildlife grazing and Latin growth.
	if sim_objects.has(source) and source.has_method("apply_effect") and String(source.kind) in ["grass","fern"]:
		if bool(source.dead) or bool(source.burning) or float(source.food)<0.65:
			return {"ok":false,"message":"This patch has too little healthy growth. Water it or let it recover."}
		if not source.apply_effect("harvest",1.0):
			return {"ok":false,"message":"The plant cannot be harvested yet."}
		player.add_item("herb")
		if DisplayServer.get_name()!="headless": save_world()
		return {"ok":true,"message":"Gathered a herb from living growth.","material":"herb"}
	var material: String = ""
	var key: String = ""
	var limit: int = 0
	if source.has_meta("resource_deposit"):
		material = String(source.get_meta("resource_deposit"))
		key = String(source.get_meta("harvest_id",""))
		limit = 12
	elif source.has_method("apply_effect") and String(source.kind)=="stone":
		material = "stone"
		key = "sim:%d" % int(source.uid)
		limit = 3
	if material not in ["wood","stone"] or key.is_empty():
		return {"ok":false,"message":"Nothing useful can be taken."}
	var used: int = maxi(0,int(harvest_counts.get(key,0)))
	if used>=limit:
		return {"ok":false,"message":"That deposit has been exhausted."}
	harvest_counts[key]=used+1
	player.add_item(material)
	if DisplayServer.get_name()!="headless":
		save_world()
	return {"ok":true,"message":"Gathered %s (%d remain)." %
		[material,limit-used-1],"material":material}

func familiar() -> Node3D:
	if familiar_id.is_empty(): return null
	for creature in creatures:
		if is_instance_valid(creature) and creature.persistent_id == familiar_id and not creature.dead:
			return creature
	return null

func bond_animal(creature: Node3D) -> Dictionary:
	# The first familiar is one of the existing living, saved wild creatures.
	# A hare trusts an offered herb; a crow accepts a shiny piece of amber.
	if not is_instance_valid(creature) or not creatures.has(creature) or creature.dead or creature.species not in ["hare","crow"]:
		return {"ok":false,"message":"Only a living hare or crow can be befriended."}
	if player == null or player.global_position.distance_to(creature.global_position) > 3.7:
		return {"ok":false,"message":"Move closer before offering a gift."}
	if not familiar_id.is_empty():
		return {"ok":false,"message":"A familiar already travels with you."}
	var offering: String = "herb" if creature.species == "hare" else "amber"
	if not player.inventory.has(offering):
		return {"ok":false,"message":"Offer a piece of amber to the crow." if offering == "amber" else "Offer a herb to the hare."}
	player.inventory.erase(offering)
	player.selected_slot = clampi(player.selected_slot,0,maxi(0,player.inventory.size()-1))
	player.refresh_held_model()
	familiar_id = String(creature.persistent_id)
	familiar_mode = "follow"
	creature.panic = 0.0
	creature.asleep = 0.0
	creature.stop_time = 0.0
	if DisplayServer.get_name() != "headless":
		save_world()
	return {"ok":true,"message":"The %s accepts your gift and follows you." % creature.species}

func cycle_familiar_order() -> Dictionary:
	if familiar() == null:
		return {"ok":false,"message":"You have no living familiar."}
	match familiar_mode:
		"follow": familiar_mode = "stay"
		"stay": familiar_mode = "rest"
		_: familiar_mode = "follow"
	if familiar_mode == "follow" and familiar() != null:
		familiar().asleep = 0.0
	if DisplayServer.get_name() != "headless":
		save_world()
	return {"ok":true,"message":"Familiar: " + familiar_mode}

func skip_days(count: int) -> void:
	# Developer-only calendar acceleration uses the SAME daily transition as
	# real play. Work remains bounded; no fake fast-forward currency is minted.
	for i in range(clampi(count,0,12)):
		world_calendar.advance_days(1)
		if village_sim!=null:
			village_sim.advance_day(world_calendar.day)
			for j in range(4): village_sim.step()
	if workplaces!=null: workplaces.refresh_from_economy(true)

func save_world() -> bool:
	return WORLD_PERSIST.save_world(self)

func load_world() -> bool:
	return WORLD_PERSIST.load_world(self)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and is_inside_tree() and player != null:
		save_world()

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
	# Daytime has a blue open-world sky and warm distance haze; the earlier
	# desaturated grey sky made every clearing look permanently overcast.
	e.background_mode=Environment.BG_SKY
	var sky:=Sky.new()
	var s:=ProceduralSkyMaterial.new()
	s.sky_top_color=Color("729db4")
	s.sky_horizon_color=Color("dfceb4")
	s.ground_bottom_color=Color("476556")
	s.ground_horizon_color=Color("9caf99")
	s.use_debanding=true
	sky.sky_material=s
	e.sky=sky
	e.ambient_light_source=Environment.AMBIENT_SOURCE_SKY
	e.reflected_light_source=Environment.REFLECTION_SOURCE_BG
	e.ambient_light_energy=.49
	e.tonemap_mode=Environment.TONE_MAPPER_FILMIC
	e.fog_enabled=true
	e.fog_light_color=Color("bcc8bc")
	e.fog_density=.0040
	e.fog_sky_affect=.16
	ambient.environment=e
	add_child(ambient)
	light_node=DirectionalLight3D.new()
	light_node.name="LowAutumnSun"
	light_node.light_color=Color("f7e5c5")
	light_node.light_energy=.94
	light_node.shadow_enabled=true
	light_node.rotation_degrees=Vector3(-38,32,-10)
	add_child(light_node)

func _update_day_night_art(night_value: float) -> void:
	if ambient == null or ambient.environment == null or light_node == null: return
	var env: Environment = ambient.environment
	var sky: ProceduralSkyMaterial = env.sky.sky_material as ProceduralSkyMaterial
	if sky != null:
		sky.sky_top_color = Color("729db4").lerp(Color("1c2d3d"),night_value)
		sky.sky_horizon_color = Color("dfceb4").lerp(Color("3c4957"),night_value)
		sky.ground_bottom_color = Color("476556").lerp(Color("172c30"),night_value)
		sky.ground_horizon_color = Color("9caf99").lerp(Color("2c4548"),night_value)
	env.ambient_light_energy = lerpf(.49,.15,night_value)
	env.fog_light_color = Color("bcc8bc").lerp(Color("3a4c56"),night_value)
	env.fog_density = lerpf(.0040,.0084,night_value)
	light_node.light_color=Color("f7e5c5").lerp(Color("a4bcd2"),night_value)
	light_node.light_energy=lerpf(.94,.20,night_value)

func stream_x(z: float) -> float:
	return -20.0+4.4*sin(z*.075)+1.7*sin(z*.21)

# The cabin is an actual built site, not furniture perched on raw grass.
# The center is identical to its old elevation; only the footprint and a
# smooth, short transition are flattened. All other valley heights match.
func height_at(x: float,z: float) -> float:
	var raw: float = _raw_height_at(x,z)
	# Two small intentionally levelled authored sites. The surrounding hills
	# blend back over 4–5 metres; no hovering floors or invisible terrain seams.
	# Non-overlapping graded pads: the original broad falloffs merged two
	# different elevations and pushed a grassy ridge through the shop floor.
	var castle_edge: float=maxf(absf(x+49.0)/7.9,absf(z-44.0)/8.1)
	if castle_edge<1.17:
		raw=lerpf(raw,_raw_height_at(-49.0,44.0),
			1.0-smoothstep(1.0,1.17,castle_edge))
	# Station forecourt extends farther toward the river than the shop does
	# toward the castle. Asymmetric extents preserve both usable flat floors.
	var station_x_edge: float=(absf(x+33.0)/6.4) if x < -33.0 else ((x+33.0)/10.0)
	var station_edge: float=maxf(station_x_edge,absf(z-44.0)/5.0)
	if station_edge<1.16:
		raw=lerpf(raw,_raw_height_at(-33.0,44.0),
			1.0-smoothstep(1.0,1.16,station_edge))
	if absf(x-29.0) > 13.0 or absf(z-8.0) > 13.0:
		return raw
	var local: Vector2 = cottage_local_xz(x,z)
	var edge: float = maxf(absf(local.x)/5.15,absf(local.y)/3.55)
	if edge >= 1.72:
		return raw
	var blend: float = 1.0-smoothstep(1.0,1.72,edge)
	return lerpf(raw,_raw_height_at(29.0,8.0),blend)


func _raw_height_at(x: float,z: float) -> float:
	var hills: float = terrain_noise.get_noise_2d(x,z)*4.5+sin(x*.052)*1.15+cos(z*.069)*.76
	var ridge: float = 8.0*(1.0 - smoothstep(-56.0,-25.0,z)) + 3.0*smoothstep(28.0,53.0,x)
	var center: float = stream_x(z)
	var trench: float = 4.1*exp(-pow((x-center)/4.6,2))
	# Open central walkable meadow; rougher relief around its perimeter.
	var glade: float = 1.0 - .54*exp(-((x*x+(z-18.0)*(z-18.0))/340.0))
	return (hills + ridge)*glade-trench + small_noise.get_noise_2d(x,z)*.19


# Use the actual -0.28 radian cottage orientation for both the terrain site
# and the vegetation exclusion. A circular world-space mask would miss the
# turret and remove an unnecessary amount of garden.
func cottage_local_xz(x: float,z: float) -> Vector2:
	var dx: float = x-29.0
	var dz: float = z-8.0
	var c: float = cos(-.28)
	var s: float = sin(-.28)
	return Vector2(c*dx-s*dz,s*dx+c*dz)


func is_inside_cottage_plot(x: float,z: float, margin: float=0.0) -> bool:
	var p: Vector2 = cottage_local_xz(x,z)
	return absf(p.x) < 5.15+margin and absf(p.y) < 3.55+margin


func move_vegetation_outside_cottage(x: float,z: float) -> Vector2:
	if not is_inside_cottage_plot(x,z,.12):
		return Vector2(x,z)
	var local: Vector2 = cottage_local_xz(x,z)
	local.x = 5.65 if local.x >= 0.0 else -5.65
	var c: float = cos(-.28)
	var s: float = sin(-.28)
	return Vector2(29.0+c*local.x+s*local.y,
		8.0-s*local.x+c*local.y)

func move_vegetation_outside_roadside(x: float,z: float) -> Vector2:
	# Keep offline foliage batches from poking through the station floors
	# and castle archive. Move positions, never skip sim_object creation:
	# saved ecological IDs must not be renumbered by the new district.
	if x>=-58.5 and x<=-40.0 and z>=35.0 and z<=53.6:
		return Vector2(x,34.4 if z<44.0 else 54.25)
	if x>=-40.0 and x<=-21.8 and z>=37.5 and z<=50.5:
		return Vector2(x,36.9 if z<44.0 else 51.05)
	return Vector2(x,z)

func build_terrain() -> void:
	# One continuous, physically grounded terrain mesh. A WorldUV photographic
	# atlas already combines genuine CC0 meadow, soil, leaves, creek and worn
	# path with smooth ecotones. No sharp per-triangle biome boundaries.
	# All blending is baked offline via tools/bake_vale_terrain.py, so it runs
	# identically on Godot's GL Compatibility renderer and works without web.
	var visual_tool := SurfaceTool.new()
	visual_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var grid_size: int = 126
	var extent: float = 144.0
	for zi in range(grid_size-1):
		for xi in range(grid_size-1):
			var x0: float = (float(xi)/float(grid_size-1)-.5)*extent
			var x1: float = (float(xi+1)/float(grid_size-1)-.5)*extent
			var z0: float = (float(zi)/float(grid_size-1)-.5)*extent
			var z1: float = (float(zi+1)/float(grid_size-1)-.5)*extent
			var p0 := Vector3(x0,height_at(x0,z0),z0)
			var p1 := Vector3(x1,height_at(x1,z0),z0)
			var p2 := Vector3(x0,height_at(x0,z1),z1)
			var p3 := Vector3(x1,height_at(x1,z1),z1)
			for v in [p0,p2,p1,p1,p2,p3]:
				var dx: float = height_at(v.x+.4,v.z)-height_at(v.x-.4,v.z)
				var dz: float = height_at(v.x,v.z+.4)-height_at(v.x,v.z-.4)
				visual_tool.set_normal(Vector3(-dx,.8,-dz).normalized())
				visual_tool.set_uv(Vector2((v.x+extent*.5)/extent,(v.z+extent*.5)/extent))
				visual_tool.add_vertex(v)
	var ground_root := Node3D.new()
	ground_root.name = "VisibleTexturedGround"
	add_child(ground_root)
	var ground := MeshInstance3D.new()
	ground.name = "OpenMeadow"
	ground.mesh = visual_tool.commit()
	var material := StandardMaterial3D.new()
	var atlas: String = "res://assets/textures/real/vale_terrain_blend.jpg"
	if not ResourceLoader.exists(atlas):
		push_error("Missing baked CC0 terrain atlas; run the source/bake workflow")
		material.albedo_texture = load(photo_or_fallback("res://assets/textures/meadow_ground.png"))
	else:
		material.albedo_texture = load(atlas)
	material.roughness = .98
	material.metallic = 0.0
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	ground.material_override = material
	ground_root.add_child(ground)
	# Physics remains a single, untouched HeightMapShape3D: no visual-material
	# boundary can trap a player, rabbit or walking NPC.
	var terrain_body := StaticBody3D.new()
	terrain_body.name = "ContinuousTerrainCollision"
	terrain_body.collision_layer = 16
	terrain_body.collision_mask = 0
	var terrain_shape := CollisionShape3D.new()
	var terrain_map := HeightMapShape3D.new()
	terrain_map.map_width = grid_size
	terrain_map.map_depth = grid_size
	var cell_size: float = extent / float(grid_size-1)
	var elevation := PackedFloat32Array()
	for z_index in range(grid_size):
		for x_index in range(grid_size):
			var sample_x: float = (float(x_index)/float(grid_size-1)-.5)*extent
			var sample_z: float = (float(z_index)/float(grid_size-1)-.5)*extent
			elevation.append(height_at(sample_x,sample_z)/cell_size)
	terrain_map.map_data = elevation
	terrain_shape.shape = terrain_map
	terrain_shape.scale = Vector3.ONE * cell_size
	terrain_body.add_child(terrain_shape)
	ground_root.add_child(terrain_body)

func build_stone_ridges() -> void:
	# Distant vertical silhouettes provide a sense of region beyond the meadow.
	var ridge_stone := textured("res://assets/textures/stone.png",Color("817d70"))
	for p in [Vector3(-52,0,-49),Vector3(-57,0,-52),Vector3(54,0,-48)]:
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
			var tall:float=3.4+float(j)*1.9
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
	ART.chiseled_tablet(cairn,Vector3(0,1.45,0),Vector3(1.65,1.65,.43),stone)
	add_solid_box(cairn, Vector3(0,1.1,0), Vector3(1.65,2.2,.65), "InscribedCairnSolid")
	ART.stone(cairn,Vector3(0,2.29,0),Vector3(.95,.12,.37),stone)
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


func build_plural_tablet() -> void:
	# A diegetic grammar lesson, not a quest marker or floating tutorial.
	# Attested 2nd-person singular/plural Latin imperatives physically
	# inscribed next to the first word-cairn. The player can infer grammar
	# instead of unlocking a skill tree.
	var tablet = SIM_OBJECT.new()
	tablet.configure(self,"stone",next_sim_id)
	next_sim_id += 1
	sim_objects.append(tablet)
	tablet.name = "TwoVoicesStone"
	tablet.position = Vector3(-3.8,height_at(-3.8,20.0),20.0)
	tablet.rotation.y = -0.12
	add_child(tablet)
	var carved: Material = textured("res://assets/textures/stone.png",Color("8f9489"))
	ART.stone(tablet,Vector3(0,.16,0),Vector3(.9,.34,.72),carved)
	ART.chiseled_tablet(tablet,Vector3(0,1.18,0),Vector3(1.75,2.12,.33),carved)
	var body: StaticBody3D = add_solid_box(tablet,Vector3(0,1.14,0),
		Vector3(1.75,2.3,.38),"GrammaticalStone")
	body.set_meta("flora_ref",tablet)
	var words := Label3D.new()
	words.name="TheTwoVoicesInscription"
	words.text="UNUS     MULTI\n\nCRESCE    CRESCITE\nVENI      VENITE\nDORMI     DORMITE\n\nVERBA MOVENT MUNDUM"
	words.font_size=34
	words.pixel_size=.0026
	words.modulate=Color("292c26")
	words.outline_size=0
	words.no_depth_test=false
	words.position=Vector3(0,1.22,.186)
	tablet.add_child(words)

func build_water() -> void:
	var water:=Node3D.new()
	water.name="WindingStream"
	add_child(water)
	var st:=SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(68):
		var z:float=-61.0+float(i)*1.8
		var x:float=stream_x(z)
		var y:float=height_at(x,z)+.68  # water sits inside the carved creek, below its actual banks
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
	# Continuous low wall bases with chipped, wildly uneven upper stone.
	# Old 3 rectangular slabs looked like untextured gray test geometry.
	var west_ruin: PackedFloat32Array = PackedFloat32Array([2.9,3.1,2.2,1.9,2.6,1.4,2.0,3.2,2.8])
	var east_ruin: PackedFloat32Array = PackedFloat32Array([2.8,1.7,2.4,3.1,2.5,1.35,1.85,2.0,2.6])
	var rear_ruin: PackedFloat32Array = PackedFloat32Array([2.45,2.4,1.6,2.1,2.25,1.3,2.0,1.85,2.3,2.45])
	RUIN_ART.add_broken_wall(ruins,Vector3(-5,0,-.2),Vector3(-5,0,-7.4),west_ruin,.85,stone_mat)
	RUIN_ART.add_broken_wall(ruins,Vector3( 5,0,-.2),Vector3(5,0,-7.4),east_ruin,.85,stone_mat)
	RUIN_ART.add_broken_wall(ruins,Vector3(-5,0,-7.3),Vector3(5,0,-7.3),rear_ruin,.85,stone_mat)
	ART.arch(ruins,Vector3(0,0,-7.0),1.8,1.8,ART.mat(Color("928d7b")))
	# One legible vertical monument makes the ruined priory visible from
	# approach. Its broken circumference is walkable with actual segment
	# collisions rather than an invisible circular cylinder.
	RUIN_ART.add_collapsed_bell_tower(self,
		Vector3(-3.0,height_at(-3.0,-40.0),-40.0),stone_mat)
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
	# Low continuous collision portions sit INSIDE the visible masonry,
	# rather than placing invisible 3m walls above collapsed edges.
	RUIN_ART.add_wall_collision(ruins,Vector3(-5,0,-.2),Vector3(-5,0,-7.4),west_ruin,.85,"PrioryWestWall")
	RUIN_ART.add_wall_collision(ruins,Vector3(5,0,-.2),Vector3(5,0,-7.4),east_ruin,.85,"PrioryEastWall")
	RUIN_ART.add_wall_collision(ruins,Vector3(-5,0,-7.3),Vector3(5,0,-7.3),rear_ruin,.85,"PrioryBackWall")
	add_solid_box(arch, Vector3(-1.2, 1.35, 0), Vector3(.7, 2.7, .8), "RidgeArchPillarWest")
	add_solid_box(arch, Vector3( 1.2, 1.35, 0), Vector3(.7, 2.7, .8), "RidgeArchPillarEast")
	var cabin := Node3D.new()
	cabin.name = "HermitCottage"
	cabin.position = Vector3(29, height_at(29, 8), 8)
	cabin.rotation.y = -.28
	add_child(cabin)
	# Our authored silhouette replaces the generic imported cottage geometry.
	# The old GLB stays archived in assets, but is not loaded into the world.
	# Keeping the original wall/door collider positions protects player movement
	# and previously saved game positions.
	STORYBOOK_HOUSE.build(cabin,self)
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
	# The valley is now designed around real tree-stands rather than one or
	# two dozen isolated toys on an empty plane. Clearings and animal routes
	# remain legible, while each authored tree stays an independent sim object.
	var stands: Array[Dictionary] = [
		{"center":Vector2(-23,10), "radius":13.0, "count":25, "kind":"broadleaf"},
		{"center":Vector2(-21,-16), "radius":12.0, "count":23, "kind":"broadleaf"},
		{"center":Vector2(22,-19), "radius":13.0, "count":24, "kind":"autumn"},
		{"center":Vector2(40,20), "radius":14.0, "count":25, "kind":"autumn"},
		{"center":Vector2(-42,-35), "radius":16.0, "count":20, "kind":"broadleaf"},
		{"center":Vector2(12,43), "radius":17.0, "count":18, "kind":"broadleaf"}
	]
	for stand in stands:
		var center: Vector2 = stand["center"]
		var radius: float = float(stand["radius"])
		for index in range(int(stand["count"])):
			var theta: float = rng.randf_range(0,TAU)
			# Square-root radius creates varied canopy density while retaining
			# a few internal pockets, not a circular wall of evenly spaced trees.
			var radial: float = sqrt(rng.randf()) * radius
			var x: float = center.x + cos(theta) * radial
			var z: float = center.y + sin(theta) * radial
			if absf(x) > 64.0 or absf(z) > 64.0: continue
			if Vector2(x,z).distance_to(Vector2(0,26)) < 12.0: continue
			if Vector2(x,z).distance_to(Vector2(3.1,16)) < 6.8: continue
			if absf(x-sin((19.0-z)*.18)*2.7) < 4.7 and z > -35 and z < 29: continue
			if Vector2(x,z).distance_to(Vector2(4,-35)) < 12.0: continue
			if Vector2(x,z).distance_to(Vector2(29,8)) < 8.5: continue
			if absf(x-stream_x(z)) < 5.2: continue
			spawn_tree(Vector3(x,height_at(x,z),z),String(stand["kind"]),
				rng.randf_range(0.82,1.25))
	# Sparse landmarks break the skyline without turning the first clearing
	# into a hedge maze. The unusual dead tree is a recognizable landmark.
	for p in [Vector2(-47,32),Vector2(-56,8),Vector2(52,-9),Vector2(48,37)]:
		spawn_tree(Vector3(p.x,height_at(p.x,p.y),p.y),
			"autumn" if p.x > 0 else "broadleaf",1.12)
	# Frame the first reading stone without planting a wall of trees in its
	# path: two calm foreground silhouettes at different heights/depths.
	for p in [Vector2(-12.5,20.5),Vector2(14.2,14.5),Vector2(-15.5,38.0),
			Vector2(-17.5,27.0),Vector2(18.2,30.3)]:
		spawn_tree(Vector3(p.x,height_at(p.x,p.y),p.y),
			"broadleaf",1.14 if p.x < 0.0 else 1.03)
	spawn_tree(Vector3(-37,height_at(-37,31),31),"dead",1.25)
	# A single visually distinctive weeping ash on the creek bank.
	# Its sim object and trunk collider are handled by spawn_tree as normal.
	var willow_z: float = 7.0
	var willow_x: float = stream_x(willow_z)-4.9
	# A reserved authored UID preserves every pre-existing sim_object ID and
	# RNG draw in old saves when this new landmark is introduced.
	var old_next_id: int = next_sim_id
	var old_rng_state: int = rng.state
	next_sim_id = 700001
	spawn_tree(Vector3(willow_x,height_at(willow_x,willow_z),willow_z),"willow",1.07)
	next_sim_id = old_next_id
	rng.state = old_rng_state


func spawn_tree(p: Vector3,kind: String,scale_factor: float=1.0) -> Node3D:
	# Every tree is a separate living ecological object, collision obstacle and
	# spell target, but renders as a REAL authored Quaternius glTF with bark,
	# alpha foliage and physically scaled geometry.
	var node=SIM_OBJECT.new()
	node.configure(self,"dead_tree" if kind=="dead" else "tree",next_sim_id,scale_factor)
	next_sim_id+=1
	sim_objects.append(node)
	node.name="%sTree" % kind.capitalize()
	node.position=p
	node.scale=Vector3.ONE*clampf(scale_factor,0.82,1.25)
	add_child(node)
	navigation_blockers.append(Vector3(p.x,0.0,p.z))
	flora.append(node)
	var r:=RandomNumberGenerator.new()
	r.seed=int(absf(p.x*261.7+p.z*991.2))+rng.randi_range(0,8000)
	var source_name: String
	var target_height: float
	match kind:
		"willow":
			source_name = ""
			target_height = 7.2
		"autumn":
			var variants: Array[String] = ["MapleTree_1.gltf","MapleTree_2.gltf","MapleTree_3.gltf"]
			source_name=variants[r.randi_range(0,variants.size()-1)]
			target_height=7.3
		"dead":
			source_name="DeadTree_1.gltf" if r.randf()<0.5 else "DeadTree_3.gltf"
			target_height=8.1
		_:
			source_name="BirchTree_1.gltf" if r.randf()<0.5 else "BirchTree_3.gltf"
			target_height=7.1
	var path: String="res://assets/models/cc0/nature/"+source_name
	var attached: bool = false
	if kind == "willow":
		LANDMARK_TREE.decorate(node)
		attached = true
	else:
		attached = EXTERNAL_ART.attach_scaled(node,path,target_height)
	if attached and kind != "dead":
		# Quaternius alpha foliage is excellent geometry but its raw neon
		# yellow/salmon palette looked too toy-like in our actual Godot footage.
		# Preserve UVs, bark and opacity while tinting leaf surfaces only.
		var imported: Node3D = node.get_node_or_null("CC0ImportedArt") as Node3D
		if imported != null:
			var leaf_tint: Color = Color("647c69") if kind != "autumn" else Color("806b5a")
			# Autumn is a varied amber/olive canopy, not the same salmon pink
			# copied thirty times along the ridge. Preserve a few rust accents.
			if kind == "autumn":
				var variation: float = r.randf()
				if variation < .30:
					leaf_tint = Color("6c7d60")
				elif variation < .61:
					leaf_tint = Color("937455")
				elif variation < .86:
					leaf_tint = Color("866965")
				else:
					leaf_tint = Color("998266")
			else:
				leaf_tint = leaf_tint.lerp(Color("899b87"),r.randf_range(.0,.48))
			for member in imported.find_children("*","MeshInstance3D",true,false):
				var part: MeshInstance3D = member as MeshInstance3D
				if part == null or part.mesh == null: continue
				for surface_id in range(part.mesh.get_surface_count()):
					var source_material: Material = part.mesh.surface_get_material(surface_id)
					if source_material is StandardMaterial3D and (surface_id == 1 or String(source_material.resource_name).to_lower().contains("leav")):
						var new_mat: StandardMaterial3D = source_material.duplicate() as StandardMaterial3D
						new_mat.albedo_color = source_material.albedo_color * leaf_tint
						part.set_surface_override_material(surface_id,new_mat)
	if not attached:
		# Keep a solid landmark rather than fake orange canopy blobs or
		# thousands of loose rectangular procedural leaves.
		push_warning("VERBA textured tree asset missing: "+path)
		ART.bone(node,Vector3.ZERO,Vector3(.08,4.7,0),.32,.12,bark_mat,9)
	var collider:=StaticBody3D.new()
	collider.name="SolidTreeTrunk"
	collider.collision_layer=4|16
	collider.collision_mask=0
	collider.set_meta("flora_ref",node)
	var shape:=CollisionShape3D.new()
	var cylinder:=CylinderShape3D.new()
	cylinder.height=4.7
	cylinder.radius=.61 if kind=="willow" else .43 if kind=="autumn" else .29
	shape.shape=cylinder
	shape.position.y=2.35
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
		# Keep the same generated simulation IDs so saved plant states load.
		var clear_grass: Vector2 = move_vegetation_outside_cottage(x,z)
		clear_grass = move_vegetation_outside_roadside(clear_grass.x,clear_grass.y)
		x = clear_grass.x
		z = clear_grass.y
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
	var patch = make_living_plant(p,"grass",mesh,material,1.7)
	patch.is_generated = true
	return patch

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
		# Near objects simulate frequently. Far objects retain all elapsed time,
		# but use fewer real-time updates. No distant object's clock stops.
		var uid: int = int(obj.uid)
		var elapsed: float = float(distant_object_elapsed.get(uid,0.0)) + dt
		var distant: bool = player != null and player.global_position.distance_to(obj.global_position) > 42.0
		if distant and elapsed < 3.0:
			distant_object_elapsed[uid] = elapsed
			continue
		distant_object_elapsed[uid] = 0.0
		var nearby_fire: float = nearest_fire_distance(obj.global_position)
		# Stream-bank moisture is simulated with the same accumulated delta.
		if absf(obj.global_position.x-stream_x(obj.global_position.z)) < 5.0:
			obj.apply_effect("wet",elapsed*.025)
		obj.simulate(elapsed,raining,nearby_fire,wind)
		if obj.burning and not obj.dead and nearby_fire>1.5:
			add_fire(obj.global_position,obj)
	# Local heat transfer, rather than arbitrary secondary magic effects.
	# A burning tree naturally heats nearby fuel; moisture and wind alter the
	# outcome using the same persistent state as magic and weather.
	MATERIAL_EXCHANGE.transmit_heat(self,dt)

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
	# Data-defined books exist as independently collectible 3D volumes.
	for id in scholar.books.keys():
		var manuscript: Dictionary = scholar.get_book(String(id))
		var coords: Array = manuscript.get("location",[])
		if coords.size() != 2: continue
		var x: float = float(coords[0])
		var z: float = float(coords[1])
		if String(id) == "de_herbis":
			# Give the very first reading lesson a visible, solid world landmark,
			# rather than hiding a small brown model in a field of grass.
			var book_plinth = SIM_OBJECT.new()
			book_plinth.configure(self,"stone",next_sim_id)
			next_sim_id += 1
			book_plinth.name = "FirstLatinReadingStone"
			book_plinth.position = Vector3(x,height_at(x,z),z)
			sim_objects.append(book_plinth)
			add_child(book_plinth)
			# A low garden lectern, not a cube in the middle of the tutorial.
			ART.stone(book_plinth,Vector3(0,.17,0),
				Vector3(.75,.34,.61),stone_mat)
			ART.stone(book_plinth,Vector3(0,.54,0),
				Vector3(.49,.41,.38),stone_mat)
			ART.stone(book_plinth,Vector3(0,.82,0),
				Vector3(.68,.12,.54),stone_mat)
			var solid: StaticBody3D = add_solid_box(book_plinth,Vector3(0,.44,0),
				Vector3(.84,.83,.66),"SolidBookLectern")
			solid.set_meta("flora_ref",book_plinth)
			var plaque: Material = textured(
				"res://assets/textures/cottage_wood.png",Color("a18e6d"))
			ART.box(book_plinth,Vector3(0,.55,.398),
				Vector3(.70,.22,.045),plaque)
			var inscription := Label3D.new()
			inscription.name = "DeHerbisCarvedTitle"
			inscription.text = "DE HERBIS"
			inscription.font_size = 43
			inscription.pixel_size = .00235
			inscription.modulate = Color("332a22")
			inscription.outline_size = 0
			inscription.no_depth_test = false
			inscription.position = Vector3(0,.55,.428)
			book_plinth.add_child(inscription)
			spawn_item("book",String(id),Vector3(x,height_at(x,z)+.94,z))
		elif String(id)=="de_castello":
			# The castle archive contains a real collectable architecture book,
			# not a remotely delivered reward or a text-only map marker.
			var table := Node3D.new()
			table.name="CastleLatinManuscriptTable"
			table.position=Vector3(x,height_at(x,z),z)
			add_child(table)
			ART.box(table,Vector3(0,.36,0),Vector3(.98,.12,.60),bark_mat)
			for tx in [-.38,.38]:
				ART.box(table,Vector3(tx,.17,0),Vector3(.12,.33,.50),bark_dark)
			spawn_item("book",String(id),Vector3(x,height_at(x,z)+.47,z))
		else:
			spawn_item("book",String(id),Vector3(x,height_at(x,z),z))
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

func spawn_item(kind: String, word_key: String, p: Vector3,
		dropped: bool = false, stable_id: String = "") -> void:
	var id: String = stable_id
	if dropped and id.is_empty():
		id = "drop:%d" % next_drop_serial
		next_drop_serial += 1
	var i = PICKUP_SCRIPT.new()
	i.setup(self,kind,word_key,p,id,dropped)
	if not dropped and not authored_pickup_templates.has(i.persistent_id):
		authored_pickup_templates[i.persistent_id] = {
			"kind":kind,"word":word_key,"position":p
		}
	add_child(i)
	items.append(i)

func retire_book_pickup(book_id: String) -> void:
	# A book received from an NPC is the SAME collectible volume as its
	# original authored world object. Prevent ghost duplicates in this
	# scene, and record a tombstone for save/load.
	for item in items.duplicate():
		if not is_instance_valid(item) or item.item_type != "book" or item.word != book_id:
			continue
		if not item.is_dropped and not collected_pickup_ids.has(item.persistent_id):
			collected_pickup_ids.append(item.persistent_id)
		items.erase(item)
		item.queue_free()

func collect(item) -> void:
	if not is_instance_valid(item): return
	if item.item_type not in ["leaf","book"] and player.inventory.size() >= 6:
		player.say_world("Hands full",item.global_position+Vector3.UP*.5,Color("c7a98e"))
		return
	if item.item_type == "leaf":
		player.book.learn(item.word)
		player.say_world("+ " + item.word.to_upper(),item.global_position+Vector3.UP*.6,Color("dfc287"))
	elif item.item_type == "book":
		if not scholar.collect_book(item.word): return
		player.book.open_book(item.word)
		player.say_world("A volume found: " + String(scholar.get_book(item.word).get("title","Latin manuscript")),
			item.global_position + Vector3.UP*1.0,Color("dfc287"))
	else:
		player.add_item(item.item_type)
	# Only authored pickups need a tombstone record. Player-created drops
	# are saved as live items and disappear naturally if collected.
	if not item.is_dropped and not collected_pickup_ids.has(item.persistent_id):
		collected_pickup_ids.append(item.persistent_id)
	items.erase(item)
	item.queue_free()
	# Atomic journal the COMPLETE transaction, including removal of the
	# pickup. Previously book/leaf auto-saves ran before the tombstone,
	# allowing the same item to reappear after a crash.
	if DisplayServer.get_name() != "headless":
		save_world()

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
	# One authoritative time source drives the sun, seasons, and daily
	# social deadlines. No NPC or quest keeps an independent clock.
	var days_passed: int=world_calendar.advance(delta)
	if days_passed>0 and village_sim!=null:
		village_sim.advance_day(world_calendar.day)
	if light_node!=null:
		light_node.rotation_degrees.x=-10.0-50.0*sin((world_calendar.fraction()*24.0-6.0)*TAU/24.0)
		light_node.rotation_degrees.y=-60.0+190.0*world_calendar.fraction()
	if player != null and DisplayServer.get_name() != "headless":
		autosave_elapsed += delta
		if autosave_elapsed >= 45.0:
			autosave_elapsed = 0.0
			save_world()
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
		night_remaining=maxf(0.0,night_remaining-delta)
	# Night magic used to dim sunlight while leaving a bright noon sky.
	# The visual state now transitions in a finite duration and stops
	# changing renderer resources once it reaches either endpoint.
	var desired_night: float = maxf(world_calendar.darkness(),1.0 if night_remaining > 0.0 else 0.0)
	var previous_night: float = night_visual_blend
	night_visual_blend = move_toward(night_visual_blend,desired_night,delta*.57)
	if absf(night_visual_blend-previous_night) > .0001:
		_update_day_night_art(night_visual_blend)
	# Cheap deterministic village simulation, independent of camera and player actions.
	village_elapsed += delta
	if village_elapsed >= 10.0 and village_sim != null:
		var steps: int = mini(6,int(village_elapsed/10.0))
		village_elapsed -= float(steps)*10.0
		for i in range(steps): village_sim.step()
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
