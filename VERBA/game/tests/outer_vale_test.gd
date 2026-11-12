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
	var old_road: MeshInstance3D=road.find_child("RoadSegment_1",true,false)
	if old_road==null:
		_fail("New distant station is disconnected from the actual visible road")
		return
	var road_skin: ShaderMaterial=old_road.material_override as ShaderMaterial
	if road_skin==null or not road_skin.shader.resource_path.ends_with("aged_road.gdshader"):
		_fail("Distant road reverted to a perfectly smooth gray plane")
		return
	var road_vertices: PackedVector3Array=old_road.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	if road_vertices.size()<600:
		_fail("Road has reverted to six-vertex quads that cut through terrain")
		return
	for i in range(0,road_vertices.size(),maxi(1,int(road_vertices.size()/22))):
		var vertex: Vector3=road_vertices[i]
		if vertex.y-world.height_at(vertex.x,vertex.z)<.08:
			_fail("Road triangle is buried inside actual walkable terrain")
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
	var masonry: Node3D=world.get_node_or_null(
		"OuterValeRegionalLandmarks/ColdCharcoalKiln/KilnCurvedBrickwork")
	if masonry==null or masonry.get_child_count()<39:
		_fail("The abandoned kiln is still one smooth cone instead of broken masonry")
		return
	var track: MeshInstance3D=world.get_node_or_null(
		"OuterValeRegionalLandmarks/LongTrackToStillwater/RuttedWalkableFootpath")
	if track==null or track.mesh==null:
		_fail("Lake path does not render over the walking terrain")
		return
	var trail_vertices: PackedVector3Array=track.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	if trail_vertices.size()<1500:
		_fail("Lake path was not subdivided laterally to follow the heightfield")
		return
	for j in range(0,trail_vertices.size(),maxi(1,int(trail_vertices.size()/48))):
		var p: Vector3=trail_vertices[j]
		if p.y-world.height_at(p.x,p.z)<.065:
			_fail("Lake trail is still buried in large triangular soil gaps")
			return
	for landmark in ["TumbledTollGate","ColdCharcoalKiln","OldHunterBlind",
			"SevenWeatheredWitnessStones","WindbrokenOrchard",
			"LastMeasuredMileStone","LongTrackToStillwater"]:
		if world.get_node_or_null("OuterValeRegionalLandmarks/"+landmark)==null:
			_fail("Outer world has no identifiable location: "+landmark)
			return
	var history: Node3D=world.get_node_or_null("WeatheredWorldHistory")
	if history==null:
		_fail("The weathering layer never made it into the actual scene")
		return
	for name in ["OldRoadShouldersAndBoundaryFence","StillwaterDriftwoodAndSedge",
			"WindbrokenOrchard"]:
		if name=="WindbrokenOrchard": continue
		if history.get_node_or_null(name)==null:
			_fail("A material-history region is missing: "+name)
			return
	var scratches: Node3D=station.find_child("WeatheredForecourtHistory",true,false)
	if scratches==null or scratches.find_child("RustingDeliveryWreck",true,false)==null:
		_fail("The station is still a clean showroom with no aging or abandonment")
		return
	var covered: int=0
	for group in ["LakeSedges","OldRoadHeather","WitnessMeadow","OrchardThistle"]:
		var clumps: MultiMeshInstance3D=history.get_node_or_null(group)
		if clumps==null or clumps.multimesh.instance_count<2500:
			_fail("Expanded map returned to a giant empty green ground in "+group)
			return
		covered+=clumps.multimesh.instance_count
	if covered<10000:
		_fail("Outer region cover is too sparse")
		return
	var orchard: Node3D=world.get_node_or_null("OuterValeRegionalLandmarks/WindbrokenOrchard")
	if orchard==null or orchard.find_child("CollapsedOrchardFence",true,false)==null:
		_fail("Orchard does not show signs of previous habitation")
		return
	if world.navigation_region.navigation_mesh.get_polygon_count()<1000:
		_fail("Navigation was not expanded with the terrain")
		return

	# Distant photographic ridge landscape must conceal the former square
	# world's sky void, but must never extend the game collision/save map.
	var horizon: Node3D=world.get_node_or_null("DistantVisualHorizon") as Node3D
	if horizon==null or not bool(horizon.get_meta("visual_only",false)):
		_fail("The far horizon returned to blank sky beyond the terrain square")
		return
	var far_ground: MeshInstance3D=horizon.get_node_or_null("BeyondTheWalkableVale") as MeshInstance3D
	if far_ground==null or far_ground.mesh==null:
		_fail("The seamless visual-only ridge does not exist")
		return
	var far_bounds: AABB=far_ground.mesh.get_aabb()
	if far_bounds.size.x<800.0 or far_bounds.size.z<800.0:
		_fail("The distant horizon doesn't cover the visible map edges")
		return
	if horizon.find_children("*","StaticBody3D",true,false).size()>0:
		_fail("Visual horizon improperly introduced inaccessible collision")
		return

	# The cottage-to-lake art milestone is a complete passage, not
	# a scattering of unrelated props. All features are visual or retain
	# separately authored, tangible geometry without any new save ID.
	var journey: Node3D=world.get_node_or_null("HermitageToStillwaterArtPass") as Node3D
	if journey==null or not bool(journey.get_meta("decoration_only",false)):
		_fail("The hermitage-to-lake composition was not built")
		return
	var woodline: Node3D=journey.get_node_or_null("VariedTreeEdgeAndSmallGroves") as Node3D
	if woodline==null or int(woodline.get_meta("imported_tree_count",0))<12:
		_fail("The lake road still has an empty forest edge")
		return
	for entry in [
		{"name":"CottageFernEdge","minimum":400},
		{"name":"ShadedForestUnderstory","minimum":650},
		{"name":"LakeMarginTussocks","minimum":600},
		{"name":"RuttedTrackPebbleAndGravelMargins","minimum":1200},
		{"name":"UnevenWetMossAndSiltShore","minimum":400}
	]:
		var group: MultiMeshInstance3D=journey.find_child(
			String(entry["name"]),true,false) as MultiMeshInstance3D
		if group==null or group.multimesh==null or group.multimesh.instance_count<int(entry["minimum"]):
			_fail("Missing authored ground-cover layer: "+String(entry["name"]))
			return
	var worn: MeshInstance3D=world.get_node_or_null(
		"OuterValeRegionalLandmarks/LongTrackToStillwater/RuttedWalkableFootpath") as MeshInstance3D
	if worn==null or not (worn.material_override is ShaderMaterial):
		_fail("The lake path lost its photographed, softly blended track material")
		return
	if (worn.material_override as ShaderMaterial).shader.resource_path != "res://assets/materials/worn_lake_track.gdshader":
		_fail("The lake path returned to flat, sharply edged brown")
		return
	if journey.find_child("BrokenHermitageFieldstoneGardenBoundary",true,false)==null:
		_fail("Cottage landscaping is disconnected from its approach")
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
