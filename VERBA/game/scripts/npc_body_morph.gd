extends RefCounted
## One closed, articulated-compatible clothing surface for an inherited
## ribcage, natural chest/bust volume, tapered waist and pelvic width.
## This is not a collider or a replacement limb: the original detachments,
## wounds, clothing objects, names and saves retain their identity.
const GENES=preload("res://scripts/npc_genetics.gd")
const RINGS: int=16
const HEIGHTS: Array[float]=[.49,.63,.80,.98,1.10,1.20,1.30,1.34,1.375,1.405,1.43,1.455,1.48,1.505]

static func _section(y: float,g: Dictionary,sex: String="unspecified") -> Vector2:
	var shoulders: float=lerpf(.89,1.16,GENES.value(g,"shoulder_width"))
	var chest: float=lerpf(.90,1.15,GENES.value(g,"chest_width"))
	var waist: float=lerpf(.79,1.22,GENES.value(g,"waist_width"))
	var hips: float=lerpf(.83,1.22,GENES.value(g,"hip_width"))
	var depth: float=lerpf(.88,1.14,GENES.value(g,"body_depth"))
	var muscles: float=GENES.value(g,"muscle_tone")
	# Sex-linked silhouette bias alters average body type, never the
	# underlying transmitted alleles. Large-framed daughters can keep
	# broad shoulders and greater stature from either parent.
	var female: bool=sex=="female"
	var hip_shape: float=lerpf(1.025,1.085,GENES.value(g,"hip_width")) if female else 1.0
	var shoulder_shape: float=lerpf(.935,1.01,GENES.value(g,"shoulder_width")) if female else 1.0
	var rib_shape: float=lerpf(.945,1.01,GENES.value(g,"chest_width")) if female else 1.0
	# Continuous inherited pelvis, waist, ribcage and shoulder profile.
	# A former single upper ring pinched into a square, exposed neck pipe.
	var pelvis:=Vector2(.390*hips*hip_shape,.340*depth*(.92+.11*hips))
	var midriff:=Vector2((.314*waist+.025*(1.0-muscles))*(.985 if female else 1.0),.277*depth)
	var ribcage:=Vector2((.353*chest+.024*muscles)*rib_shape,.322*depth)
	var shoulder:=Vector2((.357*shoulders+.012*chest)*shoulder_shape,.304*depth)
	var neckline:=Vector2(.197,.180)
	if y<=.78:
		return pelvis
	if y<1.10:
		return pelvis.lerp(midriff,smoothstep(.78,1.10,y))
	if y<1.30:
		return midriff.lerp(ribcage,smoothstep(1.10,1.30,y))
	if y<1.375:
		return ribcage.lerp(shoulder,smoothstep(1.30,1.375,y))
	# A high tube of linen formerly filled the space under the chin and
	# looked like a disconnected turtleneck. End the cloth below the jaw;
	# shape the shoulder over several rings instead of a flat horizontal cap.
	return shoulder.lerp(neckline,smoothstep(1.375,1.505,y))

static func _point(y: float,angle: float,g: Dictionary,
		sex: String="unspecified") -> Vector3:
	var section: Vector2=_section(y,g,sex)
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
	var chest_expression: float=.17 if sex=="male" else 1.0
	z-=(.006+.113*pow(bust,1.7))*chest_expression*vertical*lobe*facing
	# Straight ribcage and a narrower, real waist survive beneath coats.
	return Vector3(x,y,z)

static func finish(root: Node3D,g: Dictionary,cloth: Material,
		modern: bool=false,sex: String="unspecified") -> MeshInstance3D:
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
			var p0: Vector3=_point(bottom,a,g,sex)
			var p1: Vector3=_point(top,a,g,sex)
			var p2: Vector3=_point(top,b,g,sex)
			var p3: Vector3=_point(bottom,b,g,sex)
			for v in [p0,p1,p2,p0,p2,p3]:
				sculpt.set_uv(Vector2((atan2(v.z,v.x)+PI)/TAU*1.6,v.y*1.1))
				sculpt.add_vertex(v)
	sculpt.generate_normals()
	var garment:=MeshInstance3D.new()
	garment.name="InheritedChestWaistHipCloth"
	garment.mesh=sculpt.commit()
	# The torso is a thin cloth shell with interior visible at the open
	# neck. Render both sides instead of having silhouette patches vanish
	# when the camera is below the inherited garment surface.
	if cloth is StandardMaterial3D:
		(cloth as StandardMaterial3D).cull_mode=BaseMaterial3D.CULL_DISABLED
	garment.material_override=cloth
	garment.set_meta("seamless_ribcage_waist_hips",true)
	garment.set_meta("natural_open_neckline",true)
	garment.set_meta("neck_termination_y",HEIGHTS[HEIGHTS.size()-1])
	garment.set_meta("genetic_bust_shape",GENES.value(g,"bust_volume"))
	garment.set_meta("sex_linked_body_shape",sex)
	garment.set_meta("genetic_waist_shape",GENES.value(g,"waist_width"))
	garment.set_meta("genetic_chest_shape",GENES.value(g,"chest_width"))
	garment.set_meta("no_new_collision",true)
	root.add_child(garment)
	return garment
