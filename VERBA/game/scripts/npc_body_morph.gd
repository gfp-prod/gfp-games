extends RefCounted
## One closed, articulated-compatible clothing surface for an inherited
## ribcage, natural chest/bust volume, tapered waist and pelvic width.
## This is not a collider or a replacement limb: the original detachments,
## wounds, clothing objects, names and saves retain their identity.
const GENES=preload("res://scripts/npc_genetics.gd")
const RINGS: int=16
const HEIGHTS: Array[float]=[.49,.63,.80,.98,1.14,1.28,1.42,1.51,1.56]

static func _section(y: float,g: Dictionary) -> Vector2:
	var shoulders: float=lerpf(.89,1.16,GENES.value(g,"shoulder_width"))
	var chest: float=lerpf(.90,1.15,GENES.value(g,"chest_width"))
	var waist: float=lerpf(.79,1.22,GENES.value(g,"waist_width"))
	var hips: float=lerpf(.83,1.22,GENES.value(g,"hip_width"))
	var depth: float=lerpf(.88,1.14,GENES.value(g,"body_depth"))
	var muscles: float=GENES.value(g,"muscle_tone")
	var x: float=.29
	var z: float=.29
	if y<.78:
		x=.390*hips
		z=.340*depth*(.92+.11*hips)
	elif y<1.10:
		x=.314*waist+.025*(1.0-muscles)
		z=.277*depth
	elif y<1.34:
		x=.353*chest+.024*muscles
		z=.322*depth
	elif y<1.50:
		x=.357*shoulders+.012*chest
		z=.304*depth
	else:
		# Form a neckline fitted around a visible neck, rather than
		# an enormous brown pipe reaching the bottom of the face.
		x=.155
		z=.162
	return Vector2(x,z)

static func _point(y: float,angle: float,g: Dictionary) -> Vector3:
	var section: Vector2=_section(y,g)
	var x: float=cos(angle)*section.x
	var z: float=sin(angle)*section.y
	# Two smoothly curved bust volumes become part of the same shirt
	# surface rather than two detached globes. This morphology is
	# inherited independently of profession, skin tone, and social role.
	var bust: float=GENES.value(g,"bust_volume")
	var chest_width: float=GENES.value(g,"chest_width")
	var lobe: float=exp(-pow((absf(x)-.14*chest_width)/.135,2.0))
	var vertical: float=exp(-pow((y-1.265)/.140,2.0))
	var facing: float=pow(maxf(0.0,-sin(angle)),2.0)
	z-=(.006+.113*pow(bust,1.7))*vertical*lobe*facing
	# Straight ribcage and a narrower, real waist survive beneath coats.
	return Vector3(x,y,z)

static func finish(root: Node3D,g: Dictionary,cloth: Material,
		modern: bool=false) -> MeshInstance3D:
	var existing: MeshInstance3D=root.get_node_or_null(
		"InheritedChestWaistHipCloth") as MeshInstance3D
	if existing!=null: return existing
	var sculpt:=SurfaceTool.new()
	sculpt.begin(Mesh.PRIMITIVE_TRIANGLES)
	sculpt.set_material(cloth)
	for row in range(HEIGHTS.size()-1):
		var bottom: float=HEIGHTS[row]
		var top: float=HEIGHTS[row+1]
		for i in range(RINGS):
			var a: float=TAU*float(i)/float(RINGS)
			var b: float=TAU*float(i+1)/float(RINGS)
			var p0: Vector3=_point(bottom,a,g)
			var p1: Vector3=_point(top,a,g)
			var p2: Vector3=_point(top,b,g)
			var p3: Vector3=_point(bottom,b,g)
			for v in [p0,p1,p2,p0,p2,p3]:
				sculpt.set_uv(Vector2((atan2(v.z,v.x)+PI)/TAU*1.6,v.y*1.1))
				sculpt.add_vertex(v)
	sculpt.generate_normals()
	var garment:=MeshInstance3D.new()
	garment.name="InheritedChestWaistHipCloth"
	garment.mesh=sculpt.commit()
	garment.material_override=cloth
	garment.set_meta("seamless_ribcage_waist_hips",true)
	garment.set_meta("genetic_bust_shape",GENES.value(g,"bust_volume"))
	garment.set_meta("genetic_waist_shape",GENES.value(g,"waist_width"))
	garment.set_meta("genetic_chest_shape",GENES.value(g,"chest_width"))
	garment.set_meta("no_new_collision",true)
	root.add_child(garment)
	return garment
