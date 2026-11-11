extends RefCounted
## VERBA construction slice: real gathered materials become collidable parts.
## One 3m grid, free choice of site, persistent IDs. No voxel dependency.
const ART = preload("res://scripts/art.gd")
const CELL: float = 3.0
const LIMIT: float = 58.0
const COSTS: Dictionary = {
	"floor": {"stone": 1, "wood": 1},
	"wall": {"wood": 2},
	"shelf": {"wood": 1},
	"door": {"wood": 2},
	"upper_floor": {"stone": 1, "wood": 2},
	"upper_wall": {"wood": 2},
	"stairs": {"wood": 3},
	"roof": {"wood": 3},
	"lamp": {"wood": 1, "amber": 1}
}
const UPPER_LEVEL: float = 3.0

func get_build_choices() -> Array[String]:
	return BUILD_ORDER.duplicate()
const BUILD_ORDER: Array[String] = ["floor","wall","door","shelf","upper_floor","upper_wall","stairs","roof","lamp"]
var world
var root: Node3D
var parts: Dictionary = {}
var site: Vector2 = Vector2(INF,INF)
var preview: MeshInstance3D

func _init(owner_world) -> void:
	world = owner_world
	root = Node3D.new()
	root.name = "PlayerBuiltWizardTower"
	world.add_child(root)

func _cell_at(point: Vector3) -> Vector2i:
	return Vector2i(roundi(point.x/CELL),roundi(point.z/CELL))

func _key(kind: String,cell: Vector2i,side: int) -> String:
	# Godot node names cannot contain colons; use stable filename-safe IDs.
	return "%s_%d_%d_%d" % [kind,cell.x,cell.y,side if kind in ["wall","door","upper_wall","stairs"] else 0]

func _base_key(cell: Vector2i) -> String:
	return _key("floor",cell,0)

func _upper_key(cell: Vector2i) -> String:
	return _key("upper_floor",cell,0)

func _direction(face: int) -> Vector2i:
	match posmod(face,4):
		0: return Vector2i(0,1)
		1: return Vector2i(1,0)
		2: return Vector2i(0,-1)
		_: return Vector2i(-1,0)

func _world_pos(cell: Vector2i) -> Vector3:
	return Vector3(float(cell.x)*CELL,0.0,float(cell.y)*CELL)

func _floor_y(cell: Vector2i) -> float:
	var center: Vector3 = _world_pos(cell)
	var height: float = world.height_at(center.x,center.z)
	for dx in [-1.26,1.26]:
		for dz in [-1.26,1.26]:
			height = maxf(height,world.height_at(center.x+dx,center.z+dz))
	return height+.31

func _part_center(kind: String,cell: Vector2i,side: int) -> Vector3:
	var point: Vector3 = _world_pos(cell)
	var y: float = _floor_y(cell)
	match kind:
		"wall","door","upper_wall":
			point.y = y+1.42+(UPPER_LEVEL if kind=="upper_wall" else 0.0)
			match side:
				0: point.z -= 1.43
				1: point.x += 1.43
				2: point.z += 1.43
				3: point.x -= 1.43
		"shelf":
			point.y = y+.82
			point.x += .35
			point.z -= .64
		"upper_floor": point.y = y+UPPER_LEVEL
		"stairs": point.y = y
		"roof": point.y = y+UPPER_LEVEL*2.0
		"lamp": point.y = y+1.95
		_: point.y = y
	return point

func _dimensions(kind: String,side: int) -> Vector3:
	match kind:
		"wall","door","upper_wall":
			return Vector3(.20,2.75,2.90) if side%2==1 else Vector3(2.90,2.75,.20)
		"stairs": return Vector3(1.48,3.0,4.5)
		"roof": return Vector3(3.2,1.4,3.2)
		"lamp": return Vector3(.32,.54,.32)
		"shelf": return Vector3(1.37,1.43,.45)
		_: return Vector3(2.96,.25,2.96)

func inspect(kind: String,where: Vector3,face: int,inventory: Array) -> Dictionary:
	if not COSTS.has(kind):
		return {"ok":false,"message":"No such tower piece exists."}
	var cell: Vector2i = _cell_at(where)
	var pos: Vector3 = _world_pos(cell)
	if absf(pos.x) > LIMIT or absf(pos.z) > LIMIT:
		return {"ok":false,"message":"That part of the vale cannot support a building."}
	if world.player != null and world.player.global_position.distance_to(
			Vector3(pos.x,world.height_at(pos.x,pos.z),pos.z)) > 10.5:
		return {"ok":false,"message":"Move closer to the building site."}
	if world.is_inside_cottage_plot(pos.x,pos.z,3.1):
		return {"ok":false,"message":"The hermitage already occupies that ground."}
	if absf(pos.x-world.stream_x(pos.z)) < 5.7:
		return {"ok":false,"message":"The streambank will not hold this foundation."}
	var id: String = _key(kind,cell,posmod(face,4))
	if parts.has(id):
		return {"ok":false,"message":"There is already a piece in that position."}
	if kind in ["wall","door"]:
		for other in ["wall","door"]:
			if parts.has(_key(other,cell,posmod(face,4))):
				return {"ok":false,"message":"That edge already has a wall or doorway."}
	if kind != "floor" and not parts.has(_base_key(cell)):
		return {"ok":false,"message":"Place a stone-and-oak floor beneath it first."}
	if kind in ["upper_wall","roof"] and not parts.has(_upper_key(cell)):
		return {"ok":false,"message":"An upper floor must support this piece."}
	if kind=="stairs":
		var along: Vector2i=_direction(face)
		var lower: Vector2i=cell-along
		var higher: Vector2i=cell+along
		if not parts.has(_base_key(lower)) or not parts.has(_upper_key(higher)):
			return {"ok":false,"message":"Stairs need an approach floor and an adjacent upper landing."}
		var low_height: float=_floor_y(lower)
		var high_height: float=_floor_y(higher)
		if absf(low_height-high_height)>0.55 or absf(low_height-_floor_y(cell))>0.55:
			return {"ok":false,"message":"The staircase needs nearly level underlying terrain."}
	if kind=="upper_floor" and site.x==INF:
		return {"ok":false,"message":"Build a ground-level foundation first."}
	if kind=="floor" and site.x != INF:
		if pos.distance_to(Vector3(site.x,0,site.y)) > 13.5:
			return {"ok":false,"message":"Extend the tower near your first foundation."}
	else:
		# First placement must be reasonably clear of the old wild trees.
		for obstruction in world.navigation_blockers:
			if Vector2(obstruction.x,obstruction.z).distance_to(Vector2(pos.x,pos.z)) < 2.4:
				return {"ok":false,"message":"A tree or old wall already occupies this land."}
	var cost: Dictionary = COSTS[kind]
	for item in cost.keys():
		if inventory.count(String(item)) < int(cost[item]):
			return {"ok":false,"message":"Need %d %s to build %s." %
				[int(cost[item]),String(item),kind]}
	return {"ok":true,"id":id,"kind":kind,"gx":cell.x,"gz":cell.y,
		"face":posmod(face,4),"message":"Ready to place %s." % kind}

func build(kind: String,where: Vector3,face: int,player) -> Dictionary:
	var candidate: Dictionary = inspect(kind,where,face,player.inventory)
	if not bool(candidate.get("ok",false)): return candidate
	var record: Dictionary = {
		"kind":kind,"gx":int(candidate["gx"]),"gz":int(candidate["gz"]),
		"face":int(candidate["face"])
	}
	var cost: Dictionary = COSTS[kind]
	# No resources are spent on blocked, duplicate or out-of-range pieces.
	for item in cost.keys():
		for i in range(int(cost[item])):
			player.inventory.erase(String(item))
	place_saved_part(record)
	player.selected_slot = clampi(player.selected_slot,0,
		maxi(0,player.inventory.size()-1))
	player.refresh_held_model()
	if kind == "floor" and site.x == INF:
		site = Vector2(float(record["gx"])*CELL,float(record["gz"])*CELL)
	if DisplayServer.get_name() != "headless":
		world.save_world()
	return {"ok":true,"message":"Built %s. The vale will remember it." % kind,
		"id":String(candidate["id"])}

func place_saved_part(record: Dictionary) -> void:
	var kind: String = String(record.get("kind",""))
	if not COSTS.has(kind): return
	var cell := Vector2i(int(record.get("gx",0)),int(record.get("gz",0)))
	var side: int = posmod(int(record.get("face",0)),4)
	if absf(float(cell.x)*CELL)>LIMIT or absf(float(cell.y)*CELL)>LIMIT: return
	var key: String = _key(kind,cell,side)
	if parts.has(key): return
	var center: Vector3 = _part_center(kind,cell,side)
	var size: Vector3 = _dimensions(kind,side)
	var node := Node3D.new()
	node.name = "TowerPart_" + key
	node.position = center
	root.add_child(node)
	var stone := ART.mat(Color("989183"),.98)
	var timber := ART.mat(Color("8a745e"),.97)
	var deep := ART.mat(Color("4b443b"),.97)
	match kind:
		"floor","upper_floor":
			ART.box(node,Vector3.ZERO,size,stone if kind=="floor" else timber)
			for offset in [-1.31,1.31]:
				ART.box(node,Vector3(offset,.16,0),Vector3(.12,.11,3.03),deep)
				ART.box(node,Vector3(0,.16,offset),Vector3(3.03,.11,.12),deep)
			for dx in [-1.23,1.23]:
				for dz in [-1.23,1.23]:
					var ground: float = world.height_at(center.x+dx,center.z+dz)
					var length: float = maxf(.18,center.y-ground)
					ART.box(node,Vector3(dx,-length*.5,dz),Vector3(.24,length,.24),deep)
		"wall","upper_wall":
			ART.box(node,Vector3.ZERO,size,timber)
			var across: bool = side%2==0
			var brace: Vector3 = Vector3(1.25,0,0) if across else Vector3(0,0,1.25)
			var upright := Vector3.UP*1.27
			ART.bone(node,-brace-upright,brace+upright,.10,.08,deep,8)
			ART.bone(node,brace-upright,-brace+upright,.09,.08,deep,8)
		"door":
			# An actual opening in a timber frame: never a full invisible wall.
			node.rotation.y=PI*.5 if side%2==1 else 0.0
			for x in [-1.20,1.20]:
				var beam: Vector3=Vector3(x,0,0)
				ART.box(node,beam,Vector3(.50,2.75,.23),timber)
				var post=world.add_solid_box(node,beam,Vector3(.50,2.75,.23),"TowerDoorPost_"+key+str(x))
				post.set_meta("tower_ref",node)
			var lintel: Vector3=Vector3(0,1.17,0)
			ART.box(node,lintel,Vector3(1.98,.4,.23),deep)
			var frame=world.add_solid_box(node,lintel,Vector3(1.98,.4,.23),"TowerDoorLintel_"+key)
			frame.set_meta("tower_ref",node)
			var pivot:=Node3D.new()
			pivot.name="DoorPivot"
			pivot.position=Vector3(-.81,-.26,0)
			node.add_child(pivot)
			var leaf:=StaticBody3D.new()
			leaf.name="InteractiveTowerDoor"
			leaf.collision_layer=16
			leaf.collision_mask=0
			leaf.set_meta("tower_ref",node)
			leaf.position.x=.70
			pivot.add_child(leaf)
			ART.box(leaf,Vector3.ZERO,Vector3(1.37,2.16,.12),timber)
			var c:=CollisionShape3D.new()
			var leaf_box:=BoxShape3D.new()
			leaf_box.size=Vector3(1.37,2.16,.12)
			c.shape=leaf_box
			leaf.add_child(c)
			for y in [-.81,.81]:
				ART.box(leaf,Vector3(0,y,.078),Vector3(1.20,.08,.075),deep)
			pivot.rotation.y=-PI*.52 if bool(record.get("open",false)) else 0.0
		"shelf":
			for y in [-.54,-.03,.47]:
				ART.box(node,Vector3(0,y,0),Vector3(1.32,.09,.41),timber)
			for x in [-.58,.58]:
				ART.box(node,Vector3(x,0,0),Vector3(.09,1.4,.42),deep)
		"stairs":
			# A walkable continuous convex ramp *under* visible wooden treads,
			# avoiding the stock character controller's inability to climb
			# disconnected 25cm vertical box steps.
			node.rotation.y=float(side)*PI*.5
			var lower: Vector2i=cell-_direction(side)
			var higher: Vector2i=cell+_direction(side)
			var lo: float=_floor_y(lower)-_floor_y(cell)+.16
			var hi: float=_floor_y(higher)-_floor_y(cell)+UPPER_LEVEL+.18
			var rail:=StaticBody3D.new()
			rail.name="WalkableTowerStairRamp"
			rail.collision_layer=16
			rail.collision_mask=0
			var hull:=ConvexPolygonShape3D.new()
			hull.points=PackedVector3Array([
				Vector3(-.78,lo-.23,-3.0),Vector3(.78,lo-.23,-3.0),
				Vector3(-.78,lo,-3.0),Vector3(.78,lo,-3.0),
				Vector3(-.78,lo-.23,1.52),Vector3(.78,lo-.23,1.52),
				Vector3(-.78,hi,1.52),Vector3(.78,hi,1.52)])
			var ramp_shape:=CollisionShape3D.new()
			ramp_shape.shape=hull
			rail.add_child(ramp_shape)
			node.add_child(rail)
			for i in range(12):
				var t: float=(float(i)+.5)/12.0
				var zz: float=-3.0+t*4.52
				var yy: float=lerpf(lo,hi,t)-.12
				ART.box(node,Vector3(0,yy,zz),Vector3(1.60,.12,.37),timber)
			for edge in [-.78,.78]:
				ART.bone(node,Vector3(edge,lo+.40,-3.0),Vector3(edge,hi+.40,1.52),.06,.055,deep,8)
		"roof":
			var slate:=ART.mat(Color("5b665f"),.98)
			for side_sign in [-1.0,1.0]:
				var roof_center:=Vector3(side_sign*.76,.68,0)
				var tilt:=Vector3(0,0,side_sign*PI/5.3)
				ART.box(node,roof_center,Vector3(1.89,.17,3.42),slate,tilt)
				var collision:=world.add_solid_box(node,roof_center,Vector3(1.89,.17,3.42),"TowerRoofPitch_"+key+str(side_sign))
				collision.rotation=tilt
			ART.bone(node,Vector3(0,1.37,-1.7),Vector3(0,1.37,1.7),.12,.12,deep,9)
		"lamp":
			var brass:=ART.mat(Color("8f7445"),.6)
			var flame:=ART.mat(Color("ffdfab"),.44,Color("e2a257"))
			ART.box(node,Vector3.ZERO,Vector3(.26,.48,.26),brass)
			ART.orb(node,Vector3(0,.17,0),Vector3(.15,.15,.15),flame,10)
			var point_light:=OmniLight3D.new()
			point_light.name="TowerLampWarmLight"
			point_light.light_color=Color("ffd29b")
			point_light.light_energy=.80
			point_light.omni_range=7.0
			point_light.shadow_enabled=false
			node.add_child(point_light)
			point_light.position.y=.20
	if kind in ["floor","upper_floor","wall","upper_wall","shelf","lamp"]:
		var solid=world.add_solid_box(node,Vector3.ZERO,size,"SolidTower_"+key)
		if kind=="shelf": solid.set_meta("tower_ref",node)
	elif kind=="roof":
		# Roof pitch colliders above replace the obstructive full-cube shape.
		pass
	elif kind=="stairs":
		pass
	elif kind=="door":
		pass
	parts[key] = {"kind":kind,"gx":cell.x,"gz":cell.y,"face":side,"node":node,
		"open":bool(record.get("open",false)),"book_id":String(record.get("book_id",""))}
	if kind=="door": node.set_meta("tower_door_key",key)
	if kind=="shelf":
		node.set_meta("tower_shelf_key",key)
		_update_shelf_visual(key)

func _update_shelf_visual(key: String) -> void:
	if not parts.has(key): return
	var part: Dictionary=parts[key]
	var node: Node3D=part["node"]
	var existing: Node=node.get_node_or_null("DisplayedLatinVolume")
	if existing!=null: existing.queue_free()
	var volume: String=String(part.get("book_id",""))
	if volume.is_empty(): return
	var display:=Node3D.new()
	display.name="DisplayedLatinVolume"
	display.position=Vector3(0,.05,0)
	node.add_child(display)
	var binding:=ART.mat(Color("52453e"),.85)
	var gilding:=ART.mat(Color("c7ab75"),.68)
	ART.box(display,Vector3(0,0,0),Vector3(.27,.39,.12),binding)
	ART.box(display,Vector3(0,.08,.064),Vector3(.18,.035,.008),gilding)

func shelve_book(key: String, scholar) -> Dictionary:
	if not parts.has(key) or String(parts[key]["kind"])!="shelf":
		return {"ok":false,"message":"That is not a bookcase."}
	if not String(parts[key].get("book_id","")).is_empty():
		return {"ok":false,"message":"This shelf already holds a Latin volume."}
	for book_id in scholar.owned:
		var assigned: bool=false
		for entry in parts.values():
			if String(entry.get("book_id",""))==String(book_id): assigned=true
		if assigned: continue
		parts[key]["book_id"]=String(book_id)
		_update_shelf_visual(key)
		if DisplayServer.get_name()!="headless": world.save_world()
		return {"ok":true,"message":"Shelved %s." % String(scholar.get_book(String(book_id)).get("title",book_id))}
	return {"ok":false,"message":"Find a new Latin book to place here."}

func toggle_door(key: String) -> Dictionary:
	if not parts.has(key) or String(parts[key]["kind"])!="door":
		return {"ok":false,"message":"This is not a tower door."}
	var part: Dictionary=parts[key]
	var node: Node3D=part["node"]
	var pivot: Node3D=node.get_node_or_null("DoorPivot")
	if pivot==null: return {"ok":false,"message":"The door is damaged."}
	part["open"]=not bool(part.get("open",false))
	pivot.rotation.y=-PI*.52 if bool(part["open"]) else 0.0
	if DisplayServer.get_name()!="headless": world.save_world()
	return {"ok":true,"message":"Door opened." if bool(part["open"]) else "Door closed."}


func ensure_preview() -> MeshInstance3D:
	if is_instance_valid(preview):return preview
	preview=MeshInstance3D.new()
	preview.name="TowerPlacementPreview"
	var mat := StandardMaterial3D.new()
	mat.albedo_color=Color(.68,.82,.65,.36)
	mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode=BaseMaterial3D.CULL_DISABLED
	preview.material_override=mat
	preview.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	world.add_child(preview)
	return preview

func show_preview(kind: String,where: Vector3,face: int,inventory: Array) -> Dictionary:
	var p: MeshInstance3D = ensure_preview()
	var cell: Vector2i = _cell_at(where)
	var sizing: Vector3 = _dimensions(kind,posmod(face,4))
	var shape := BoxMesh.new()
	shape.size = sizing
	p.mesh = shape
	p.global_position = _part_center(kind,cell,posmod(face,4))
	var status: Dictionary = inspect(kind,where,face,inventory)
	var material: StandardMaterial3D = p.material_override as StandardMaterial3D
	material.albedo_color = Color(.54,.86,.60,.42) if bool(status.get("ok",false)) else Color(.91,.52,.49,.32)
	p.visible = true
	return status

func hide_preview() -> void:
	if is_instance_valid(preview): preview.visible=false

func snapshot() -> Dictionary:
	var serialized: Array[Dictionary] = []
	for key in parts.keys():
		var part: Dictionary = parts[key]
		serialized.append({"kind":String(part["kind"]),"gx":int(part["gx"]),
			"gz":int(part["gz"]),"face":int(part["face"]),
			"open":bool(part.get("open",false)),"book_id":String(part.get("book_id",""))})
	return {"parts":serialized}

func restore(data: Dictionary) -> void:
	for key in parts.keys():
		var part: Dictionary = parts[key]
		var node: Node3D = part.get("node",null)
		if is_instance_valid(node):
			node.queue_free()
	parts.clear()
	site = Vector2(INF,INF)
	var recovered: Array = data.get("parts",[])
	if recovered.size()>128: return
	# Foundations first: walls/shelves may only exist atop saved floors.
	for kind in ["floor","upper_floor","wall","door","upper_wall","stairs","shelf","roof","lamp"]:
		for row in recovered:
			if not (row is Dictionary) or String(row.get("kind",""))!=kind: continue
			var gx: int = int(row.get("gx",999))
			var gz: int = int(row.get("gz",999))
			if absf(float(gx)*CELL)>LIMIT or absf(float(gz)*CELL)>LIMIT:continue
			var cell := Vector2i(gx,gz)
			if kind!="floor" and not parts.has(_base_key(cell)):continue
			if kind=="floor" and site.x==INF:
				site=Vector2(float(gx)*CELL,float(gz)*CELL)
			place_saved_part({"kind":kind,"gx":gx,"gz":gz,
				"face":clampi(int(row.get("face",0)),0,3),
				"open":bool(row.get("open",false)),
				"book_id":String(row.get("book_id","")) if kind=="shelf" else ""})
