extends RefCounted
## One closed, articulated-compatible clothing surface for an inherited
## ribcage, natural chest/bust volume, tapered waist and pelvic width.
## The functional shirt ends at the high hip, leaving the articulated legs
## visible instead of reproducing a long cylindrical robe over both knees.
## This is not a collider or a replacement limb: the original detachments,
## wounds, clothing objects, names and saves retain their identity.
const GENES=preload("res://scripts/npc_genetics.gd")
# More supporting rings where the ribs turn into the deltoids and neck.
# A few large, evenly spaced rings made human torsos resemble barrel-shaped
# cylinders and gave the shoulders a hard step in profile. This is still a
# modest, single low-poly cloth mesh with the same detachable arm sockets.
const RINGS: int=24
const HEIGHTS: Array[float]=[.815,.85,.89,.94,.98,1.04,1.10,1.16,
	1.20,1.24,1.28,1.30,1.325,1.34,1.355,1.375,1.395,
	1.42,1.445,1.465,1.48,1.495,1.505]

static func _section(y: float,g: Dictionary,sex: String="unspecified") -> Vector2:
	# Build the *same* inherited skeleton using sex-linked population
	# averages, not two predefined figures. Ratio is more important than
	# raw radius: shoulders relative to pelvis, ribcage relative to waist.
	# Physique alleles are unchanged and can override either average.
	var shoulder_gene: float=GENES.value(g,"shoulder_width")
	var chest_gene: float=GENES.value(g,"chest_width")
	var waist_gene: float=GENES.value(g,"waist_width")
	var hip_gene: float=GENES.value(g,"hip_width")
	var muscle_gene: float=GENES.value(g,"muscle_tone")
	var depth_gene: float=GENES.value(g,"body_depth")
	var shoulders: float=lerpf(.89,1.16,shoulder_gene)
	var chest: float=lerpf(.90,1.15,chest_gene)
	var waist: float=lerpf(.79,1.22,waist_gene)
	var hips: float=lerpf(.86,1.14,hip_gene)
	var depth: float=lerpf(.88,1.10,depth_gene)
	var female: bool=sex=="female"
	var male: bool=sex=="male"
	# The shoulder is proportionally narrower than the pelvis for an
	# average adult woman; this is expressed in the mesh and arm sockets,
	# not by shrinking the entire body or relying on hair/costume cues.
	# Larger adult male-average thorax/shoulder girdle and upper-body
	# musculature; female-average greater pelvic-to-shoulder ratio and
	# a distinct waist indentation. These are modest morph multipliers,
	# not enforced anatomical types, and each is moderated by its genes.
	var shoulder_factor: float=lerpf(.745,1.015,shoulder_gene) if female else (
		lerpf(.985,1.115,shoulder_gene) if male else 1.0)
	var rib_factor: float=lerpf(.830,1.025,chest_gene) if female else (
		lerpf(1.010,1.115,chest_gene) if male else 1.0)
	var waist_factor: float=lerpf(.800,.975,waist_gene) if female else (
		lerpf(.990,1.090,waist_gene) if male else 1.0)
	var hip_factor: float=lerpf(1.050,1.165,hip_gene) if female else (
		lerpf(.958,1.028,hip_gene) if male else 1.0)
	var pelvis_depth: float=lerpf(1.005,1.065,hip_gene) if female else (
		lerpf(.978,1.025,hip_gene) if male else 1.0)
	var upper_muscle: float=(.009+.020*muscle_gene) if male else (
		.003+.012*muscle_gene if female else .020*muscle_gene)
	# Lean baseline, not low-detail anatomy: the original last pass
	# multiplied pelvic width with soft-tissue width and overall X scale,
	# making nearly every resident broad even with moderate alleles.
	# Preserve shape RATIOS and high-allele broad physiques. The current
	# average half-widths are deliberately lean; broadness must come from
	# inherited muscle/frame loci, not a huge default mannequin torso.
	# Distinct, continuous rings at hip crest / waist / ribs / shoulder.
	var pelvis:=Vector2(.241*hips*hip_factor,
		.228*depth*(.92+.11*hips)*pelvis_depth)
	var midriff:=Vector2((.219*waist+.008*(1.0-muscle_gene))*waist_factor,
		.210*depth*(.975 if female else 1.0))
	var ribcage:=Vector2((.249*chest+upper_muscle*.55)*rib_factor,
		.235*depth*(.970 if female else 1.030 if male else 1.0))
	var shoulder:=Vector2((.257*shoulders+.007*chest)*shoulder_factor,
		.226*depth*(.975 if female else 1.035 if male else 1.0))
	# A slender collar opening closes toward the new cranial/throat
	# landmark. An oversized neckline left a hollow dark collar around
	# the smaller, more realistic head.
	var neckline:=Vector2(
		.116*(.93 if female else 1.045 if male else 1.0),
		.112*(.94 if female else 1.04 if male else 1.0))
	if y<=.78:
		# Do not extrude the widest hip section unchanged down to the
		# tunic hem: that produced a rectangular, barrel-shaped skirt.
		# The fabric eases gently inward below the greater trochanter.
		var toward_hem: float=1.0-smoothstep(.61,.78,clampf(y,.61,.78))
		return Vector2(pelvis.x*lerpf(1.0,.935,toward_hem),
			pelvis.y*lerpf(1.0,.965,toward_hem))
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
	var lobe: float=exp(-pow((absf(x)-(.048+.058*chest_width))/.105,2.0))
	var vertical: float=exp(-pow((y-1.265)/.140,2.0))
	var facing: float=pow(maxf(0.0,-sin(angle)),2.0)
	# Breast volume is soft tissue on an uninterrupted ribcage, not
	# separate attached orbs. Men still have a modest pectoral contour.
	# Preserve genuine inherited variety without turning the average
	# everyday tunic into a rigid prow extending far beyond the ribcage.
	# Strong alleles still create visible fullness; ordinary profiles stay
	# integrated with the sternum and taper to the natural waist.
	var breast_profile: float=(.012+.102*pow(bust,1.55)) if sex=="female" else (
		.003+.025*pow(bust,1.6) if sex=="male" else .006+.077*pow(bust,1.7))
	z-=breast_profile*vertical*lobe*facing
	# Gluteal and greater-trochanter curves broaden the lower torso at
	# specific heights. Clothing panels sample these very same points.
	var hip_level: float=exp(-pow((y-.79)/.22,2.0))
	var lateral: float=pow(absf(cos(angle)),2.0)
	var posterior: float=pow(maxf(0.0,sin(angle)),2.0)
	var soft_hip: float=GENES.value(g,"hip_width")
	if sex=="female":
		x*=1.0+(.009+.018*soft_hip)*hip_level*lateral
		z+=(.008+.020*soft_hip)*hip_level*posterior
	elif sex=="male":
		x*=1.0+.011*soft_hip*hip_level*lateral
		z+=.010*soft_hip*hip_level*posterior
	# Sculpt the ribcage and waist in THREE dimensions, not just in the
	# left/right silhouette. Every prior ring was an oval extrusion: the
	# back had no scapulae, sternum and lumbar hollow, so a turned figure
	# resembled a pipe even when its waist and pelvis were correctly sized.
	# All relief stays small relative to the underlying inherited bones.
	var front: float=pow(maxf(0.0,-sin(angle)),2.0)
	var back: float=pow(maxf(0.0,sin(angle)),2.0)
	var sternum_level: float=exp(-pow((y-1.355)/.118,2.0))
	var sternum_center: float=exp(-pow(x/.125,2.0))
	z-=.010*sternum_level*sternum_center*front
	# Posterior shoulder-blade lobes have no equivalent on the front.
	# Their relief fades to zero around the waist and at the collar.
	var scapula_level: float=exp(-pow((y-1.315)/.115,2.0))
	var scapula_lobe: float=exp(-pow((absf(x)-.168)/.088,2.0))
	z+=.017*scapula_level*scapula_lobe*back
	var lumbar_level: float=exp(-pow((y-1.045)/.145,2.0))
	z-=.009*lumbar_level*exp(-pow(x/.105,2.0))*back
	# The oblique flank recedes at the waist while retaining broad hips
	# for those with the inherited width. These small contours do not
	# replace sex-linked averages with a single forced body template.
	var oblique_level: float=exp(-pow((y-1.105)/.130,2.0))
	var waist_inheritance: float=GENES.value(g,"waist_width")
	x*=1.0-(.017+.013*(1.0-waist_inheritance))*oblique_level*lateral
	var abdomen_level: float=exp(-pow((y-1.035)/.185,2.0))
	z-=(.004+.009*waist_inheritance)*abdomen_level*front
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
	garment.set_meta("lean_anatomic_proportions",true)
	garment.set_meta("anatomic_shoulder_hip_ratio",
		_section(1.365,g,sex).x/_section(.80,g,sex).x)
	garment.set_meta("anatomic_waist_hip_ratio",
		_section(1.10,g,sex).x/_section(.80,g,sex).x)
	garment.set_meta("genetic_waist_shape",GENES.value(g,"waist_width"))
	garment.set_meta("genetic_chest_shape",GENES.value(g,"chest_width"))
	garment.set_meta("no_new_collision",true)
	root.add_child(garment)
	return garment
