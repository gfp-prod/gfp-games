extends SceneTree
## Appearance and inheritance are gameplay state, not random per-frame cosmetics.
const GENES=preload("res://scripts/npc_genetics.gd")
func _initialize() -> void:
	call_deferred("_run")
func _fail(message: String) -> void:
	push_error("NPC gene/art regression: "+message)
	quit(1)
func _run() -> void:
	var ida: Dictionary=GENES.profile({"id":"ida"})
	var orin: Dictionary=GENES.profile({"id":"orin"})
	var lena: Dictionary=GENES.profile({"id":"lena"})
	if String(ida["sex"])!="female" or String(orin["sex"])!="male":
		_fail("Founder phenotype metadata changed")
		return
	if float(ida["shoulders"])>=float(orin["shoulders"]) or float(ida["hips"])<=float(ida["shoulders"]):
		_fail("Inherited male and female silhouettes collapsed into the same proportions")
		return
	if float(lena["waist"])>=float(lena["hips"])*.75:
		_fail("Painter's fitted waist and hips disappeared")
		return
	var child_data: Dictionary={"id":"test_child","sex":"female"}
	var child: Dictionary=GENES.profile(child_data,ida,orin)
	var child_again: Dictionary=GENES.profile(child_data,ida,orin)
	if child!=child_again:
		_fail("Inherited genetics change on reload")
		return
	if float(child["height"])<minf(float(ida["height"]),float(orin["height"]))-.04 or float(child["height"])>maxf(float(ida["height"]),float(orin["height"]))+.04:
		_fail("Offspring height escaped plausible parental range")
		return
	var world=load("res://main.tscn").instantiate()
	root.add_child(world)
	await process_frame
	var faces: Dictionary={}
	for actor in world.npcs:
		if actor.npc_id not in ["ida","orin","lena","nima","titus","juno"]:
			continue
		var figure:=actor.find_child("VisibleInhabitant",true,false) as Node3D
		var upper:=actor.find_child("TaperedVillagerTunic",true,false) as MeshInstance3D
		var pelvis: Node = actor.find_child("AnatomicalWaistAndHips",true,false)
		var eyes: Node = actor.find_child("VisibleLeftEye",true,false)
		var nose: Node = actor.find_child("ModeledNoseTip",true,false)
		var lip: Node = actor.find_child("ModeledUpperLip",true,false)
		var hair: Node = actor.find_child("InheritedHairCrown",true,false)
		if figure==null or upper==null or pelvis==null or eyes==null or nose==null or lip==null or hair==null:
			_fail("Incomplete body/face/hair: "+actor.npc_id)
			return
		if actor.left_arm==null or actor.right_arm==null or actor.left_leg==null or actor.right_leg==null:
			_fail("Four independent limb pivots missing: "+actor.npc_id)
			return
		# Regression for the specific disappearing-body bug: every loft must
		# face OUTWARD, so backface culling cannot hide the anatomical mesh.
		for body_part in [upper,
			actor.find_child("AnatomicalThigh",true,false),
			actor.find_child("AnatomicalCalf",true,false),
			actor.find_child("TailoredUpperArm",true,false)]:
			if not body_part is MeshInstance3D or body_part.mesh==null:
				_fail("Missing visible anatomical surface: "+actor.npc_id)
				return
			var vertices: PackedVector3Array=body_part.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
			if vertices.size()<3:
				_fail("Empty anatomical triangle mesh: "+actor.npc_id)
				return
			var p0: Vector3=vertices[0]
			var normal: Vector3=(vertices[1]-p0).cross(vertices[2]-p0)
			var radial:=Vector3(p0.x,0.0,p0.z)
			if normal.dot(radial)<=0.00001:
				_fail("Inward-facing body triangles (backface culling regression): "+actor.npc_id)
				return
		if actor.find_child("FittedLeatherBoot",true,false)==null:
			_fail("Independent shaped boot disappeared: "+actor.npc_id)
			return
		if actor.find_child("ModeledNeck",true,false) is MeshInstance3D:
			var neck_mesh: Mesh=(actor.find_child("ModeledNeck",true,false) as MeshInstance3D).mesh
			if neck_mesh is CylinderMesh:
				_fail("Cylindrical collarbone/neck returned: "+actor.npc_id)
				return
		if actor.npc_id=="juno" and not figure.visible:
			_fail("Modern attendant still uses the discarded duplicate mannequin")
			return
		faces[actor.npc_id]=[figure.scale.y,upper.scale.x,actor.inherited_genes["nose"]]
	if faces.size()!=6 or faces["ida"]==faces["orin"]:
		_fail("NPC anatomy did not vary across the six test characters")
		return
	print("PASS: heritable stable NPC profiles, distinct anatomy, complete facial meshes, role-safe modular limbs")
	quit(0)
