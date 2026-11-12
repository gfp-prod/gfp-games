extends SceneTree
## Whole-scene QA for deliberate terrain variety and route separation.
## It never asks the user to infer working geography from a concept map.
const REGIONS=preload("res://scripts/world_regions.gd")
const NAV=preload("res://scripts/navigation_builder.gd")
const PERSIST=preload("res://scripts/world_persistence.gd")

func _initialize() -> void: call_deferred("_run")
func _fail(message: String) -> void:
	push_error("Expanded Outer Vale: "+message)
	quit(1)

func _run() -> void:
	var world=load("res://main.tscn").instantiate()
	root.add_child(world)
	await process_frame
	var terrain: Node3D=world.get_node_or_null("VisibleTexturedGround")
	if terrain==null:
		_fail("Visible contiguous world terrain is missing")
		return
	var ground: MeshInstance3D=terrain.find_child("OpenMeadow",true,false)
	var collider: StaticBody3D=terrain.find_child("ContinuousTerrainCollision",true,false)
	if ground==null or ground.mesh==null or collider==null:
		_fail("Terrain rendering and real collision no longer agree")
		return
	var box: AABB=ground.get_aabb()
	if box.size.x<250.0 or box.size.z<250.0:
		_fail("Map was not actually expanded beyond its original 144 metres")
		return
	var material: ShaderMaterial=ground.material_override as ShaderMaterial
	if material==null or material.shader==null or not material.shader.resource_path.ends_with("region_ground.gdshader"):
		_fail("Ground still uses a single repetitive green texture")
		return
	for material_slot in ["meadow_tex","woodland_tex","dry_tex",
			"packed_tex","silt_tex","stone_tex"]:
		if material.get_shader_parameter(material_slot)==null:
			_fail("Regional ground lacks unique material: "+material_slot)
			return

	var road: Node3D=world.get_node_or_null("StrangeRoadDistrict")
	var station: Node3D=road.find_child("ValeFuelStation",true,false)
	var castle: Node3D=road.find_child("CastleOfTheSecondRoad",true,false)
	if station==null or castle==null:
		_fail("Relocated station or old castle missing from the valley")
		return
	var station_pt:=Vector2(station.global_position.x,station.global_position.z)
	var castle_pt:=Vector2(castle.global_position.x,castle.global_position.z)
	if station_pt.distance_to(REGIONS.STATION)>.1 or castle_pt.distance_to(REGIONS.CASTLE)>.1:
		_fail("Map changes moved the old castle or misplaced the new station")
		return
	if station_pt.distance_to(castle_pt)<50.0:
		_fail("Modern petrol station is still practically on top of the castle")
		return
	var clerk: Node3D
	for actor in world.npcs:
		if actor.npc_id=="juno": clerk=actor; break
	if clerk==null or Vector2(clerk.global_position.x,clerk.global_position.z).distance_to(REGIONS.STATION)>6.5:
		_fail("The living attendant was left behind in the castle courtyard")
		return
	if road.find_child("RoadSegment_1",true,false)==null:
		_fail("New distant station is disconnected from the actual visible road")
		return

	var lake: Node3D=world.get_node_or_null("OuterValeRegionalLandmarks/StillwaterLake")
	if lake==null:
		_fail("Physical lake does not exist inside the expanded world")
		return
	if lake.find_child("RealLakeSurface",true,false)==null or lake.find_child("OldFishingJetty",true,false)==null:
		_fail("Water surface or accessible lakeside jetty is missing")
		return
	var jetty=lake.find_child("OldFishingJetty",true,false)
	var planks=jetty.find_children("FishingJettyPlank_*","StaticBody3D",true,false)
	if planks.size()<12:
		_fail("The pier has no genuine walking collision")
		return
	if world.height_at(REGIONS.LAKE.x,REGIONS.LAKE.y)>world.lake_water_level-1.0:
		_fail("Lake is an opaque floating blue disk without a carved bottom")
		return
	if NAV.traversable(world,REGIONS.LAKE.x,REGIONS.LAKE.y):
		_fail("Animals or citizens can path through deep lake water")
		return
	for distance in [1.25,1.42]:
		var x: float=REGIONS.LAKE.x+distance*REGIONS.LAKE_RADII.x
		if not world.height_at(x,REGIONS.LAKE.y)>world.height_at(REGIONS.LAKE.x,REGIONS.LAKE.y)+.35:
			_fail("There is no bank rising out of the physical lake")
			return
	for landmark in ["TumbledTollGate","ColdCharcoalKiln","OldHunterBlind",
			"SevenWeatheredWitnessStones","WindbrokenOrchard",
			"LastMeasuredMileStone","LongTrackToStillwater"]:
		if world.get_node_or_null("OuterValeRegionalLandmarks/"+landmark)==null:
			_fail("Outer world has no identifiable location: "+landmark)
			return
	if world.navigation_region.navigation_mesh.get_polygon_count()<1000:
		_fail("Navigation was not expanded with the terrain")
		return

	# Existing structures and academic simulation survive untouched.
	if world.get_node_or_null("HermitCottage")==null or not world.scholar.books.has("de_herbis"):
		_fail("Visual expansion destroyed the original learning loop")
		return
	var save: Dictionary=PERSIST.snapshot(world)
	if not PERSIST.apply_snapshot(world,JSON.parse_string(JSON.stringify(save))):
		_fail("The new geography corrupted the original save ledger")
		return
	if station_pt.distance_to(castle_pt)<50.0 or world.get_node_or_null("OuterValeRegionalLandmarks/StillwaterLake")==null:
		_fail("The persistent world did not retain its geographical continuity")
		return
	print("PASS: 256m varied-material map, remote service station, carved collidable lake, walkable jetty, landmarks and saved learning world")
	quit(0)
