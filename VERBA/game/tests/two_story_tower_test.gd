extends SceneTree
## Native physical acceptance: a lower entrance connects by a walkable ramp
## to an upper, roofed landing. Door and shelved-book state survives reload.
const PERSIST=preload("res://scripts/world_persistence.gd")

func _initialize() -> void:
	call_deferred("_run")

func fail(message: String) -> void:
	push_error("Two-story tower: "+message)
	quit(1)

func _run() -> void:
	var world=load("res://main.tscn").instantiate()
	root.add_child(world)
	await process_frame
	var player=world.player
	var tower=world.construction
	player.inventory.clear()
	for i in range(65): player.inventory.append("wood")
	for i in range(16): player.inventory.append("stone")
	for i in range(5): player.inventory.append("amber")
	var stock: int=player.inventory.size()
	var lower:=Vector3.ZERO
	var middle:=Vector3.ZERO
	var upper:=Vector3.ZERO
	var located: bool=false
	for x in range(-12,15):
		for z in range(-12,15):
			var m:=Vector3(float(x)*3.0,0,float(z)*3.0)
			var a:=m-Vector3(0,0,3)
			var b:=m+Vector3(0,0,3)
			if absf(tower._floor_y(Vector2i(x,z-1))-tower._floor_y(Vector2i(x,z+1)))>0.50: continue
			if absf(tower._floor_y(Vector2i(x,z-1))-tower._floor_y(Vector2i(x,z)))>0.50: continue
			player.position=Vector3(a.x,world.height_at(a.x,a.z)+.35,a.z)
			var inspection: Dictionary=tower.inspect("floor",a,0,player.inventory)
			if not bool(inspection.get("ok",false)):continue
			var clear: bool=true
			for target in [m,b]:
				if world.is_inside_cottage_plot(target.x,target.z,3.1) or absf(target.x-world.stream_x(target.z))<5.7: clear=false
				for blocker in world.navigation_blockers:
					if Vector2(blocker.x,blocker.z).distance_to(Vector2(target.x,target.z))<2.4: clear=false
			if not clear:continue
			lower=a;middle=m;upper=b;located=true;break
		if located:break
	if not located:
		fail("No level three-cell building lot in starter district")
		return
	for pos in [lower,middle,upper]:
		player.position=Vector3(pos.x,world.height_at(pos.x,pos.z)+.25,pos.z)
		var placed: Dictionary=tower.build("floor",pos,0,player)
		if not bool(placed.get("ok",false)):
			fail("Cannot place three adjoining ground floors: "+String(placed.get("message","")))
			return
	player.position=Vector3(upper.x,world.height_at(upper.x,upper.z)+.25,upper.z)
	for kind in ["upper_floor","upper_wall","roof"]:
		var result: Dictionary=tower.build(kind,upper,0,player)
		if not bool(result.get("ok",false)):
			fail("Cannot add "+kind+": "+String(result.get("message","")))
			return
	player.position=Vector3(middle.x,world.height_at(middle.x,middle.z)+.25,middle.z)
	if not bool(tower.build("stairs",middle,0,player).get("ok",false)):
		fail("Stairs must connect an approach floor to the upper landing")
		return
	if bool(tower.build("stairs",middle,0,player).get("ok",false)):
		fail("Duplicate staircase accepted")
		return
	if tower.root.find_child("WalkableTowerStairRamp",true,false)==null:
		fail("Staircase is only decoration and has no physical sloped collision")
		return
	player.position=Vector3(lower.x,world.height_at(lower.x,lower.z)+.25,lower.z)
	for kind in ["door","shelf","lamp"]:
		if not bool(tower.build(kind,lower,0,player).get("ok",false)):
			fail("Missing entrance room feature "+kind)
			return
	if bool(tower.build("wall",lower,0,player).get("ok",false)):
		fail("A doorway and solid wall overlap in the same edge")
		return
	var door_key: String=tower._key("door",tower._cell_at(lower),0)
	var shelf_key: String=tower._key("shelf",tower._cell_at(lower),0)
	if not bool(tower.toggle_door(door_key).get("ok",false)) or not tower.parts[door_key]["open"]:
		fail("Physical door cannot be opened")
		return
	if not world.scholar.collect_book("de_herbis"):
		fail("Cannot acquire a real book for shelving")
		return
	if not bool(tower.shelve_book(shelf_key,world.scholar).get("ok",false)):
		fail("Latin book did not appear on a built shelf")
		return
	if bool(tower.shelve_book(shelf_key,world.scholar).get("ok",false)):
		fail("The same book was shelved twice")
		return
	if stock-player.inventory.size()<15:
		fail("Tower construction failed to consume real materials")
		return
	# The source world enforces a six-slot normal backpack on reload.
	player.inventory.clear()
	var saved: Dictionary=PERSIST.snapshot(world)
	var count: int=tower.parts.size()
	if count!=10:
		fail("Expected 10 physical tower components, got %d" % count)
		return
	if not PERSIST.apply_snapshot(world,saved):
		fail("Cannot restore a two-story tower save")
		return
	if tower.parts.size()!=count or not tower.parts.has(door_key) or not tower.parts.has(shelf_key):
		fail("Tower parts lost after save")
		return
	if not bool(tower.parts[door_key].get("open",false)) or String(tower.parts[shelf_key].get("book_id",""))!="de_herbis":
		fail("Door state or shelved Latin volume lost on reload")
		return
	var door: Node3D=tower.parts[door_key]["node"]
	if door.get_node_or_null("DoorPivot")==null or not bool(tower.parts[door_key]["open"]):
		fail("Saved door is no longer interactable")
		return
	print("PASS: two-story tower supports physical floors, stairs, interactive door, roof, lamp, book display, material costs and persistence")
	quit(0)
