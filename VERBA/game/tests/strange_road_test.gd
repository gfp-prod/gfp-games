extends SceneTree
## M5 world gate: two enterable authored interiors, physical road and
## castle beside gas station, a clerk who speaks graded Latin, and old saves.
const SIM=preload("res://scripts/village_sim.gd")
const PERSIST=preload("res://scripts/world_persistence.gd")
func _initialize() -> void: call_deferred("_run")
func _fail(reason: String) -> void:
	push_error("Road district: "+reason)
	quit(1)
func _run() -> void:
	var world=load("res://main.tscn").instantiate()
	root.add_child(world)
	await process_frame
	await physics_frame
	var district: Node=world.get_node_or_null("StrangeRoadDistrict")
	if district==null:
		_fail("Authored strange road is not in playable scene")
		return
	for name in ["ValeFuelStation","CastleOfTheSecondRoad","RoadSegment_0","RoadSegment_1"]:
		if district.find_child(name,true,false)==null:
			_fail("Missing road landmark "+name)
			return
	# The northern track crosses the creek at z~36. Prove that a ray
	# down from walking height hits real bridge collision, not the creek bed.
	var bridge: Node3D=district.find_child("OldNorthRoadFootbridge",true,false)
	if bridge==null:
		_fail("The northern road lacks a physically traversable stream crossing")
		return
	var deck: StaticBody3D=bridge.find_child("WalkableNorthRoadBridgeDeck",true,false)
	if deck==null or deck.collision_layer!=16:
		_fail("North footbridge has no terrain-layer physics")
		return
	var east: Vector2=Vector2(-11.0,32.22)
	var west: Vector2=Vector2(-24.0,40.82)
	var center: Vector2=east.lerp(west,0.5)
	var height: float=lerpf(world.height_at(east.x,east.y),world.height_at(west.x,west.y),.5)+.15
	var bridge_query:=PhysicsRayQueryParameters3D.create(
		Vector3(center.x,height+2.0,center.y),Vector3(center.x,height-6.0,center.y))
	bridge_query.collision_mask=16
	var bridge_hit: Dictionary=world.get_world_3d().direct_space_state.intersect_ray(bridge_query)
	if bridge_hit.is_empty() or bridge_hit.get("collider")!=deck:
		_fail("North road deck ray: hit=%s at height=%.2f bank_y=(%.2f,%.2f) streambed=%.2f" % [String(bridge_hit.get("collider",null)),height,world.height_at(east.x,east.y),world.height_at(west.x,west.y),world.height_at(center.x,center.y)])
		return
	var station: Node3D=district.find_child("ValeFuelStation",true,false)
	var castle: Node3D=district.find_child("CastleOfTheSecondRoad",true,false)
	var shop: Marker3D=station.find_child("StationWalkableInterior",true,false)
	var shop_gate: Marker3D=station.find_child("StationOpenEntrance",true,false)
	var archive: Marker3D=castle.find_child("CastleWalkableArchive",true,false)
	var castle_gate: Marker3D=castle.find_child("CastleOpenGate",true,false)
	if shop==null or shop_gate==null or archive==null or castle_gate==null:
		_fail("Two physical buildings must have an identifiable entrance and room")
		return
	# Player-height horizontal wall rays must pass through actual open doors,
	# not a deceptive translucent texture over a solid cube.
	for pair in [[shop_gate,shop],[castle_gate,archive]]:
		var start: Vector3=pair[0].global_position+Vector3.UP*1.15
		var goal: Vector3=pair[1].global_position+Vector3.UP*1.15
		var query:=PhysicsRayQueryParameters3D.create(start,goal)
		query.collision_mask=16
		var hit: Dictionary=world.get_world_3d().direct_space_state.intersect_ray(query)
		if not hit.is_empty():
			_fail("A supposedly open station/castle interior is blocked by "+String(hit["collider"].name))
			return
	var pumps: Array[Node]=station.find_children("FuelPump_*","StaticBody3D",true,false)
	var turrets: Array[Node]=castle.find_children("SolidMasonryTower","StaticBody3D",true,false)
	if pumps.size()<2 or turrets.size()<4:
		_fail("Expected two physical pumps and four towers, got %d pumps/%d towers" % [pumps.size(),turrets.size()])
		return
	if world.npcs.size()!=13 or not world.village_sim.people.has("juno"):
		_fail("Roadside clerk missing physical NPC or autonomous citizen state")
		return
	if world.social.npc("juno").is_empty():
		_fail("Roadside attendant lacks Latin conversation definitions")
		return
	var view: Dictionary=world.social.view("juno",world.scholar,[])
	if view.get("options",[]).size()!=4:
		_fail("Roadside attendant cannot answer directions")
		return
	var manuscript: bool=false
	for item in world.items:
		if is_instance_valid(item) and item.item_type=="book" and item.word=="de_castello":
			manuscript=true
	if not manuscript or not world.scholar.books.has("de_castello"):
		_fail("Castle archive does not contain its authored physical Latin book")
		return
	# Preserve a pre-district twelve-person save without fabricating any
	# prior relationship or rewinding the existing stock/treasury.
	var old=SIM.new(2026)
	var legacy: Dictionary=old.snapshot()
	legacy["people"].erase("juno")
	var after=SIM.new(88)
	if not after.restore(JSON.parse_string(JSON.stringify(legacy))):
		_fail("Pre-road saved social simulation was rejected: "+after.restore_error)
		return
	if after.people.size()!=13 or not after.people.has("juno"):
		_fail("Legacy migration erased a citizen")
		return
	if int(after.people["ida"]["wealth"])!=int(legacy["people"]["ida"]["wealth"]):
		_fail("Legacy migration modified a preexisting citizen")
		return
	var before: Dictionary=PERSIST.snapshot(world)
	if not PERSIST.apply_snapshot(world,before):
		_fail("Road district broke living world load/save")
		return
	print("PASS: station and medieval castle share authored road, two physical walk-in interiors, thirteen social actors, graded roadside attendant, castle Latin book and backward-compatible saves")
	quit(0)
