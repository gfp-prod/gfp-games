extends RefCounted
## Long-range painterly ridge silhouettes outside the 256m physical playfield.
## The original 256m terrain/collision/save coordinates remain untouched.
## Decorative only: no NPC IDs, nav blockers, spells, or physics bodies.
const INNER: float=128.0
const OUTER: float=416.0

static func _height(world: Node3D,x: float,z: float) -> float:
	var core_x: float=clampf(x,-INNER,INNER)
	var core_z: float=clampf(z,-INNER,INNER)
	var edge_height: float=world.height_at(core_x,core_z)
	var beyond: float=maxf(maxf(absf(x),absf(z))-INNER,0.0)
	# A gradual, mineral ridgeline beyond the actual walkable valley.
	# Using the exact game height along the seam avoids floating terrain.
	var emergence: float=smoothstep(0.0,188.0,beyond)
	var large: float=absf(world.terrain_noise.get_noise_2d(x*.42,z*.42))
	var middle: float=sin(x*.022+z*.011)*cos(z*.024)
	var lift: float=9.0+16.0*large+4.3*middle+3.0*sin(x*.048-z*.023)
	return edge_height+emergence*lift

static func build(world: Node3D) -> void:
	if world.get_node_or_null("DistantVisualHorizon")!=null:
		return
	var original: MeshInstance3D=world.get_node_or_null(
		"VisibleTexturedGround/OpenMeadow") as MeshInstance3D
	if original==null or original.material_override==null:
		push_warning("VERBA horizon: missing original ground material")
		return
	var mesh:=SurfaceTool.new()
	mesh.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Four adjoining exterior strips, exactly matching the 256m square.
	# No mesh is laid over the playable center: it remains fully collidable.
	var strips: Array[Dictionary]=[
		{"from":Vector2(-OUTER,-OUTER),"to":Vector2(-INNER,OUTER),"nx":22,"nz":56},
		{"from":Vector2(INNER,-OUTER),"to":Vector2(OUTER,OUTER),"nx":22,"nz":56},
		{"from":Vector2(-INNER,-OUTER),"to":Vector2(INNER,-INNER),"nx":20,"nz":22},
		{"from":Vector2(-INNER,INNER),"to":Vector2(INNER,OUTER),"nx":20,"nz":22}
	]
	for strip in strips:
		var start: Vector2=strip["from"]
		var finish: Vector2=strip["to"]
		var nx: int=strip["nx"]
		var nz: int=strip["nz"]
		for iz in range(nz):
			for ix in range(nx):
				var fx: float=float(ix)/float(nx)
				var fx2: float=float(ix+1)/float(nx)
				var fz: float=float(iz)/float(nz)
				var fz2: float=float(iz+1)/float(nz)
				var x0: float=lerpf(start.x,finish.x,fx)
				var x1: float=lerpf(start.x,finish.x,fx2)
				var z0: float=lerpf(start.y,finish.y,fz)
				var z1: float=lerpf(start.y,finish.y,fz2)
				var a:=Vector3(x0,_height(world,x0,z0),z0)
				var b:=Vector3(x1,_height(world,x1,z0),z0)
				var c:=Vector3(x0,_height(world,x0,z1),z1)
				var d:=Vector3(x1,_height(world,x1,z1),z1)
				for point in [a,c,b,b,c,d]:
					# Same world-space texture scale and shared six-soil shader.
					mesh.set_uv(Vector2(point.x*.119,point.z*.119))
					mesh.add_vertex(point)
	mesh.generate_normals()
	var scenery:=Node3D.new()
	scenery.name="DistantVisualHorizon"
	world.add_child(scenery)
	var ridge:=MeshInstance3D.new()
	ridge.name="BeyondTheWalkableVale"
	ridge.mesh=mesh.commit()
	ridge.material_override=original.material_override
	ridge.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	scenery.add_child(ridge)
	scenery.set_meta("visual_only",true)
	scenery.set_meta("physical_half_extent",INNER)
	scenery.set_meta("render_half_extent",OUTER)
