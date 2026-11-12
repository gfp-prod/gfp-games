extends SceneTree
## Inspect meshes responsible for unexpectedly tall, dark head occluders
## in real NPC screenshot captures. This is instrumentation, not a fake render.
func _initialize() -> void: call_deferred("_run")

func _run() -> void:
	var world: Node3D=load("res://main.tscn").instantiate()
	root.add_child(world)
	await process_frame
	var child: Dictionary=world.birth_child("ida","orin","Milo")
	var names: Array[String]=["ida","orin","juno",String(child.get("id",""))]
	var counted: int=0
	for actor in world.npcs:
		var id: String=String(actor.npc_id)
		if id not in names: continue
		var inverse: Transform3D=actor.global_transform.affine_inverse()
		for node in actor.find_children("*","MeshInstance3D",true,false):
			var mesh: MeshInstance3D=node as MeshInstance3D
			if mesh.mesh==null: continue
			var bounds: AABB=mesh.get_aabb()
			var to_actor: Transform3D=inverse*mesh.global_transform
			var ymin: float=INF
			var ymax: float=-INF
			var xhalf: float=0.0
			var front: float=INF
			for z in [0.0,1.0]:
				for y in [0.0,1.0]:
					for x in [0.0,1.0]:
						var point: Vector3=to_actor*(bounds.position+
							Vector3(bounds.size.x*x,bounds.size.y*y,bounds.size.z*z))
						ymin=minf(ymin,point.y)
						ymax=maxf(ymax,point.y)
						xhalf=maxf(xhalf,absf(point.x))
						front=minf(front,point.z)
			if ymax>2.55 or (ymax-ymin>1.35 and front<-.03):
				var material: Material=mesh.material_override
				var color: String=""
				if material is StandardMaterial3D:
					color=str((material as StandardMaterial3D).albedo_color)
				print("SUSPECT_MESH ",id," ",mesh.get_path(),
					" y=",snapped(ymin,.01),"..",snapped(ymax,.01),
					" xextent=",snapped(xhalf,.01),
					" front=",snapped(front,.01)," tint=",color)
				counted+=1
	print("PASS: inspected exceptional full-body mesh extents, suspects=",counted)
	quit(0)
