extends RefCounted
## Carefully placed, real CC0 Kenney retro models. Downloaded/pinned in a
## build job; NEVER network access inside the game. Every prop preserves
## existing villagers, crop stock, work goals, magic and save identities.
## We use original model silhouette and source texture, then grade pigment.
const ROOT="res://assets/models/cc0/kenney/"
const SPECS: Array[Dictionary]=[
	{"id":"MarketCordedCrate","pack":"retro-fantasy","file":"detail-crate-ropes.glb",
	 "at":Vector2(2.50,23.48),"height":.83,"yaw":-.35,"tone":Color("8e826d"),"solid":true},
	{"id":"MarketOldDeliveryBox","pack":"retro-fantasy","file":"detail-crate.glb",
	 "at":Vector2(3.85,24.10),"height":.64,"yaw":.19,"tone":Color("7d715c"),"solid":false},
	{"id":"MillwardWaterBarrels","pack":"retro-fantasy","file":"barrels.glb",
	 "at":Vector2(33.60,29.75),"height":1.22,"yaw":.22,"tone":Color("8b806d"),"solid":true},
	{"id":"StonecutterStaveLadder","pack":"retro-fantasy","file":"ladder.glb",
	 "at":Vector2(-10.4,30.30),"height":2.50,"yaw":1.22,"tone":Color("817a6a"),"solid":false},
	{"id":"RuinedNorthKeepColumn","pack":"retro-fantasy","file":"column-damaged.glb",
	 "at":Vector2(-61.3,36.6),"height":2.15,"yaw":-.4,"tone":Color("8b8a82"),"solid":true},
	{"id":"StonecutterOldSteps","pack":"retro-fantasy","file":"stairs-stone.glb",
	 "at":Vector2(-7.5,29.62),"height":.38,"yaw":0.0,"tone":Color("83837b"),"solid":false},
	{"id":"StationWornDumpster","pack":"retro-urban","file":"detail-dumpster-closed.glb",
	 "at":Vector2(-106.90,81.10),"height":1.42,"station_apron":true,"yaw":.60,"tone":Color("68716b"),"solid":true},
	{"id":"StationOldWoodPallet","pack":"retro-urban","file":"pallet.glb",
	 "at":Vector2(-104.45,81.10),"height":.26,"station_apron":true,"yaw":.22,"tone":Color("776f5e"),"solid":true},
	{"id":"StationRetainingBricks","pack":"retro-urban","file":"detail-bricks-type-a.glb",
	 "at":Vector2(-99.50,80.65),"height":.48,"station_apron":true,"yaw":1.14,"tone":Color("7f736c"),"solid":false},
	{"id":"StationAbandonedRoadBarricade","pack":"retro-urban","file":"detail-barrier-strong-damaged.glb",
	 "at":Vector2(-93.45,80.58),"height":1.09,"station_apron":true,"yaw":.35,"tone":Color("73766d"),"solid":true},
	{"id":"StationOldCableTangle","pack":"retro-urban","file":"detail-cables-type-a.glb",
	 "at":Vector2(-102.85,81.35),"height":.46,"station_apron":true,"yaw":.42,"tone":Color("676765"),"solid":false},
	{"id":"StonecutterUsefulBookshelf","pack":"furniture","file":"bookcaseOpen.glb",
	 "at":Vector2(-9.5,36.2),"height":1.74,"yaw":PI,"tone":Color("7c796b"),"solid":true,
	 "requires":"StonecutterHouse"},
	{"id":"StonecutterActualBooks","pack":"furniture","file":"books.glb",
	 "at":Vector2(-9.5,36.2),"height":.18,"yaw":PI,"tone":Color("7f7967"),"solid":false,
	 "requires":"StonecutterHouse"},
	{"id":"MillwardOldBed","pack":"furniture","file":"bedSingle.glb",
	 "at":Vector2(31.25,35.5),"height":.87,"yaw":.55,"tone":Color("827e72"),"solid":true,
	 "requires":"MillwardHouse"},
	{"id":"MillwardWorkingChair","pack":"furniture","file":"chair.glb",
	 "at":Vector2(28.7,35.8),"height":.96,"yaw":-.32,"tone":Color("69675b"),"solid":true,
	 "requires":"MillwardHouse"}
]

static func _bounds_relative(root: Node3D) -> AABB:
	# Imported glTF models may contain nested transformed MeshInstances;
	# source mesh local bounds are insufficient for correct real-world scale.
	var result:=AABB()
	var has_geometry:=false
	for mesh_node in root.find_children("*","MeshInstance3D",true,false):
		var part: MeshInstance3D=mesh_node as MeshInstance3D
		if part.mesh==null:continue
		var transform: Transform3D=root.global_transform.affine_inverse()*part.global_transform
		var source: AABB=part.mesh.get_aabb()
		for x in range(2):
			for y in range(2):
				for z in range(2):
					var p: Vector3=source.position+source.size*Vector3(x,y,z)
					var local: Vector3=transform*p
					result=AABB(local,Vector3.ZERO) if not has_geometry else result.expand(local)
					has_geometry=true
	return result

static func _grade(model: Node3D,color: Color) -> void:
	for mesh_node in model.find_children("*","MeshInstance3D",true,false):
		var part: MeshInstance3D=mesh_node as MeshInstance3D
		if part.mesh==null:continue
		for surface_index in range(part.mesh.get_surface_count()):
			var source: Material=part.get_active_material(surface_index)
			if source is StandardMaterial3D:
				var copy: StandardMaterial3D=source.duplicate() as StandardMaterial3D
				copy.albedo_color=copy.albedo_color*color
				copy.roughness=maxf(copy.roughness,.88)
				copy.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
				part.set_surface_override_material(surface_index,copy)

static func build(world: Node3D) -> void:
	if world.get_node_or_null("LicensedCC0RetroPackArt")!=null:
		return
	var root:=Node3D.new()
	root.name="LicensedCC0RetroPackArt"
	world.add_child(root)
	var installed: int=0
	var missing: Array[String]=[]
	for spec in SPECS:
		var requires: String=String(spec.get("requires",""))
		if not requires.is_empty() and world.get_node_or_null(
				"PhysicalVillageHomesteads/"+requires)==null:
			continue
		var path: String=ROOT+String(spec["pack"])+"/"+String(spec["file"])
		if not ResourceLoader.exists(path):
			missing.append(String(spec["file"]))
			continue
		var source: PackedScene=load(path) as PackedScene
		if source==null:
			missing.append(String(spec["file"]))
			continue
		var p: Vector2=spec["at"]
		var node:=Node3D.new()
		node.name=String(spec["id"])
		# The modern station forecourt is a physically level concrete apron.
		# Placing service props on the noisy terrain height underneath it
		# previously left a dumpster hanging above the steep back slope.
		var ground: float=world.height_at(p.x,p.y)
		if bool(spec.get("station_apron",false)):
			var station: Node3D=world.get_node_or_null(
				"StrangeRoadDistrict/ValeFuelStation") as Node3D
			if station!=null:
				ground=station.global_position.y+.11
		node.position=Vector3(p.x,ground,p.y)
		node.rotation.y=float(spec["yaw"])
		root.add_child(node)
		var geometry: Node3D=source.instantiate() as Node3D
		if geometry==null:
			node.queue_free()
			missing.append(String(spec["file"]))
			continue
		geometry.name="LicensedKenneyOriginalMesh"
		node.add_child(geometry)
		var bounds: AABB=_bounds_relative(geometry)
		# Some authentic retro pack assets are intentionally planar (a
		# hanging cable, ladder or wall sign). They can still render in
		# Godot; do not reject a valid model just because one axis is thin.
		var valid_axes: int=int(bounds.size.x>.002)+int(bounds.size.y>.002)+int(bounds.size.z>.002)
		if valid_axes<2:
			node.queue_free()
			missing.append("invalid geometry bounds:"+String(spec["file"])+":"+str(bounds.size))
			continue
		var primary_height: float=bounds.size.y if bounds.size.y>.005 else maxf(bounds.size.x,bounds.size.z)
		var scale: float=clampf(float(spec["height"])/primary_height,.1,8.0)
		geometry.scale=Vector3.ONE*scale
		geometry.position=Vector3(
			-(bounds.position.x+bounds.size.x*.5)*scale,
			-bounds.position.y*scale,
			-(bounds.position.z+bounds.size.z*.5)*scale)
		_grade(geometry,spec["tone"])
		node.set_meta("real_source_model",path)
		node.set_meta("cc0_license","CC0-1.0")
		node.set_meta("visual_height_meters",float(spec["height"]))
		if bool(spec.get("solid",false)):
			var body_width: float=maxf(.22,bounds.size.x*scale*.78)
			var body_depth: float=maxf(.22,bounds.size.z*scale*.78)
			world.add_solid_box(node,
				Vector3(0,float(spec["height"])*.5,0),
				Vector3(body_width,float(spec["height"])*.92,body_depth),
				"PhysicalImportedRetroProp")
		installed+=1
	root.set_meta("source_license","Kenney Creative Commons CC0 1.0")
	root.set_meta("installed_count",installed)
	root.set_meta("missing_selected_assets",missing)
	root.set_meta("simulation_entities_created",0)
	root.set_meta("source_repository","shorepine/kenney pinned 3694c687")
