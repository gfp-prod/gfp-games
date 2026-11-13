extends RefCounted
## Distinctive field-worn costume details for the existing animated NPC rigs.
## Tapered garments, occupational wear and garments grounded in construction.
## Not a replacement skeleton: the tested AnimatedLeft/Right limbs and all
## collision, conversations and work roles remain exactly as before.
const ART=preload("res://scripts/art.gd")
const FABRIC=preload("res://scripts/npc_cloth_finish.gd")
const BODY=preload("res://scripts/npc_body_morph.gd")
const GENES=preload("res://scripts/npc_genetics.gd")


## A soft, inherited shoulder cap and tapered sleeve on the EXISTING arm pivot.
## Do not add new bones or physical limbs: the old modular arm node still owns
## hit detection, swing, severing, loading and social-care state.
static func fitted_sleeve(arm: Node3D,sign: float,
		genome: Dictionary,cloth: Material) -> MeshInstance3D:
	var existing:=arm.get_node_or_null("GeneticFittedSleeve") as MeshInstance3D
	if existing!=null: return existing
	var shoulder: float=lerpf(.87,1.17,GENES.value(genome,"shoulder_width"))
	var muscle: float=lerpf(.91,1.10,GENES.value(genome,"muscle_tone"))
	const HEIGHT: Array[float]=[.046,.006,-.060,-.140,-.240,-.330,-.414]
	const CX: Array[float]=[-.058,-.031,-.007,.025,.049,.065,.076]
	const CZ: Array[float]=[-.018,-.024,-.029,-.034,-.042,-.046,-.047]
	const RX: Array[float]=[.094,.121,.125,.117,.106,.098,.087]
	const RZ: Array[float]=[.101,.124,.128,.124,.115,.104,.090]
	var surface:=SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_material(cloth)
	for row in range(HEIGHT.size()-1):
		for segment in range(14):
			var a: float=TAU*float(segment)/14.0
			var b: float=TAU*float(segment+1)/14.0
			var corners: Array[Vector3]=[]
			for ring_and_angle in [[row,a],[row+1,a],[row+1,b],[row,b]]:
				var index: int=int(ring_and_angle[0])
				var angle: float=float(ring_and_angle[1])
				var width: float=RX[index]*shoulder*muscle
				var depth: float=RZ[index]*lerpf(.92,1.12,
					GENES.value(genome,"body_depth"))
				corners.append(Vector3(
					sign*CX[index]+cos(angle)*width,
					HEIGHT[index],
					CZ[index]+sin(angle)*depth))
			for j in [0,1,2,0,2,3]:
				var p: Vector3=corners[j]
				surface.set_uv(Vector2(
					(float(segment)+float(j%3)*.35)/14.0,p.y*1.6))
				surface.add_vertex(p)
	# First-person views from above revealed a hollow ring at the shoulder.
	# Seal the upper aperture with a subtle inward-domed cloth cap; this
	# shares the same material, articulation and detachable limb identity.
	# A separate cylinder/collarbone would only recreate the old problem.
	var top_radius_x: float=RX[0]*shoulder*muscle
	var top_radius_z: float=RZ[0]*lerpf(.92,1.12,
		GENES.value(genome,"body_depth"))
	var dome_center:=Vector3(sign*CX[0],HEIGHT[0]+.022,CZ[0])
	for segment in range(14):
		var a: float=TAU*float(segment)/14.0
		var b: float=TAU*float(segment+1)/14.0
		var rim_a:=Vector3(sign*CX[0]+cos(a)*top_radius_x,
			HEIGHT[0],CZ[0]+sin(a)*top_radius_z)
		var rim_b:=Vector3(sign*CX[0]+cos(b)*top_radius_x,
			HEIGHT[0],CZ[0]+sin(b)*top_radius_z)
		for point in [dome_center,rim_a,rim_b]:
			surface.set_uv(Vector2(point.x*1.6,point.z*1.6))
			surface.add_vertex(point)
	surface.generate_normals()
	var sleeve:=MeshInstance3D.new()
	sleeve.name="GeneticFittedSleeve"
	sleeve.mesh=surface.commit()
	sleeve.material_override=cloth
	sleeve.set_meta("inherits_shoulder",true)
	sleeve.set_meta("sealed_upper_shoulder",true)
	sleeve.set_meta("old_limb_pivot_preserved",true)
	sleeve.set_meta("no_new_collision",true)
	arm.add_child(sleeve)
	return sleeve

## The smith's old apron was a broad rectangular slab suspended ahead of
## the abdomen. This shaped leather panel follows inherited torso curvature
## and retains the same visible name for compatible art reviews.
static func smith_work_apron(figure: Node3D,genome: Dictionary,
		hide: Material,leather: Material,trim: Material) -> MeshInstance3D:
	var existing:=figure.get_node_or_null("VisibleSmithApron") as MeshInstance3D
	if existing!=null: return existing
	const HEIGHT: Array[float]=[1.39,1.35,1.30,1.24,1.17,1.10,1.02,.94,.85,.76,.67,.58]
	const COLS: int=11
	var samples: Array[Vector3]=[]
	for y in HEIGHT:
		var relative: float=clampf((1.39-y)/.81,0.0,1.0)
		var half_width: float=lerpf(.19,.28,smoothstep(.0,1.0,relative))
		var body_section: Vector2=BODY._section(y,genome)
		for col in range(COLS):
			var fraction: float=float(col)/float(COLS-1)*2.0-1.0
			var x: float=fraction*half_width
			var a: float=-PI*.5+asin(clampf(x/body_section.x,-.91,.91))
			var point: Vector3=BODY._point(y,a,genome)
			var drape: float=.108+.020*(1.0-fraction*fraction)
			# Gentle cloth crease at the hem; no unmodeled box corners.
			var wrinkle: float=.008*sin(float(col)*1.85)*relative*relative
			samples.append(Vector3(x,y,point.z-drape-wrinkle))
	var st:=SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_material(hide)
	for row in range(HEIGHT.size()-1):
		for col in range(COLS-1):
			var i: int=row*COLS+col
			for j in [i,i+1,i+COLS,i+1,i+COLS+1,i+COLS]:
				var p: Vector3=samples[j]
				st.set_uv(Vector2(p.x+0.5,p.y))
				st.add_vertex(p)
	st.generate_normals()
	var apron:=MeshInstance3D.new()
	apron.name="VisibleSmithApron"
	apron.mesh=st.commit()
	apron.material_override=hide
	apron.set_meta("fitted_to_inherited_torso",true)
	apron.set_meta("no_new_collision",true)
	figure.add_child(apron)
	# Three small, surface-anchored iron rivets replace giant raised boxes.
	for location in [Vector2(-.155,1.305),Vector2(.155,1.305),
			Vector2(.205,.83)]:
		var p_x: float=location.x
		var p_y: float=location.y
		var width: float=BODY._section(p_y,genome).x
		var angle: float=-PI*.5+asin(clampf(p_x/width,-.91,.91))
		var face_z: float=BODY._point(p_y,angle,genome).z-.14
		var rivet:=ART.orb(figure,Vector3(p_x,p_y,face_z),
			Vector3(.020,.020,.009),trim,8)
		rivet.name="SmithApronIronRivet"
	# Actual leather tie follows the torso circumference, not a block
	# suspended in front of the chest.
	for side in [-1.0,1.0]:
		var ring_a: float=-PI*.5+side*.72
		var ring_b: float=-PI*.5+side*1.33
		var a: Vector3=BODY._point(.995,ring_a,genome)
		var b: Vector3=BODY._point(.995,ring_b,genome)
		a.x*=1.07
		a.z*=1.08
		b.x*=1.07
		b.z*=1.08
		var tie:=ART.bone(figure,a,b,.029,.025,leather,7)
		tie.name="SmithApronSideTie"
	return apron

## Inherited, low-poly lower-leg cloth and a wedge-soled leather boot.
## These are children of the existing amputatable/animated leg pivot;
## they never get their own collider, movement system or save identity.
static func fitted_lower_leg(leg: Node3D,side: float,
		genome: Dictionary,leather: Material) -> MeshInstance3D:
	var existing:=leg.get_node_or_null("GeneticTrouserLeg") as MeshInstance3D
	if existing!=null: return existing
	var cloth:=FABRIC.worn_linen(Color("4a4b45"))
	var hip: float=lerpf(.87,1.15,GENES.value(genome,"hip_width"))
	var depth: float=lerpf(.90,1.10,GENES.value(genome,"body_depth"))
	const H: Array[float]=[.085,.025,-.060,-.160,-.255,-.345,-.435,-.505]
	const W: Array[float]=[.149,.152,.145,.136,.128,.120,.114,.108]
	const D: Array[float]=[.151,.149,.143,.130,.121,.116,.113,.112]
	var tube:=SurfaceTool.new()
	tube.begin(Mesh.PRIMITIVE_TRIANGLES)
	tube.set_material(cloth)
	for row in range(H.size()-1):
		for segment in range(14):
			var a: float=TAU*float(segment)/14.0
			var b: float=TAU*float(segment+1)/14.0
			var corners: Array[Vector3]=[]
			for pair in [[row,a],[row+1,a],[row+1,b],[row,b]]:
				var i: int=int(pair[0])
				var angle: float=float(pair[1])
				var wrinkle: float=.007*sin(float(i)*1.6+angle*3.0)
				corners.append(Vector3(
					cos(angle)*(W[i]*hip+wrinkle),
					H[i],
					sin(angle)*D[i]*depth + .010*sin(float(i)*.58)))
			for index in [0,1,2,0,2,3]:
				var p: Vector3=corners[index]
				tube.set_uv(Vector2((atan2(p.z,p.x)+PI)/TAU,p.y*1.55))
				tube.add_vertex(p)
	tube.generate_normals()
	var trousers:=MeshInstance3D.new()
	trousers.name="GeneticTrouserLeg"
	trousers.mesh=tube.commit()
	trousers.material_override=cloth
	trousers.set_meta("original_detachable_leg",true)
	trousers.set_meta("inherited_hip_width",GENES.value(genome,"hip_width"))
	trousers.set_meta("no_new_collision",true)
	leg.add_child(trousers)

	# The old cube boots floated beneath cylindrical calves. A dedicated
	# leather shoe has an ankle, a sloping instep and a broad toe. Its
	# sole sits at the original physical floor, preserving gait contact.
	var shoemesh:=SurfaceTool.new()
	shoemesh.begin(Mesh.PRIMITIVE_TRIANGLES)
	shoemesh.set_material(leather)
	const SHOE_Y: Array[float]=[-.426,-.492,-.564,-.597]
	const SHOE_W: Array[float]=[.108,.117,.144,.140]
	const SHOE_Z: Array[float]=[-.030,-.068,-.123,-.129]
	const SHOE_D: Array[float]=[.111,.139,.215,.216]
	for row in range(SHOE_Y.size()-1):
		for segment in range(12):
			var a: float=TAU*float(segment)/12.0
			var b: float=TAU*float(segment+1)/12.0
			var vertices: Array[Vector3]=[]
			for pair in [[row,a],[row+1,a],[row+1,b],[row,b]]:
				var idx: int=int(pair[0])
				var angle: float=float(pair[1])
				vertices.append(Vector3(
					cos(angle)*SHOE_W[idx],
					SHOE_Y[idx],
					SHOE_Z[idx]+sin(angle)*SHOE_D[idx]))
			for index in [0,1,2,0,2,3]:
				var p: Vector3=vertices[index]
				shoemesh.set_uv(Vector2(p.x*1.6,p.z*1.6))
				shoemesh.add_vertex(p)
	# Close the sole so low camera angles never see a hollow boot.
	var sole_center:=Vector3(0,SHOE_Y[SHOE_Y.size()-1],
		SHOE_Z[SHOE_Z.size()-1])
	for segment in range(12):
		var a: float=TAU*float(segment)/12.0
		var b: float=TAU*float(segment+1)/12.0
		var rim_a:=Vector3(cos(a)*SHOE_W[3],SHOE_Y[3],
			SHOE_Z[3]+sin(a)*SHOE_D[3])
		var rim_b:=Vector3(cos(b)*SHOE_W[3],SHOE_Y[3],
			SHOE_Z[3]+sin(b)*SHOE_D[3])
		for p in [sole_center,rim_b,rim_a]:
			shoemesh.set_uv(Vector2(p.x,p.z))
			shoemesh.add_vertex(p)
	shoemesh.generate_normals()
	var boot:=MeshInstance3D.new()
	boot.name="GeneticAnkleBoot"
	boot.mesh=shoemesh.commit()
	boot.material_override=leather
	boot.set_meta("no_new_collision",true)
	boot.set_meta("original_detachable_leg",true)
	leg.add_child(boot)
	return trousers


static func dress(figure: Node3D,person: String,
		tunic: Material,trim: Material,leather: Material,
		genome: Dictionary={}) -> void:
	var worn:=FABRIC.worn_linen(Color("514b42"))
	# The external work garment must follow the ACTUAL inherited waist,
	# ribcage and hips. A fixed triangular cone previously hid all visible
	# differences even though a detailed genetic torso existed underneath.
	var hem:=SurfaceTool.new()
	hem.begin(Mesh.PRIMITIVE_TRIANGLES)
	hem.set_material(tunic)
	var levels: Array[float]=[.49,.65,.83,.98,1.17,1.24]
	for j in range(levels.size()-1):
		var low: float=levels[j]
		var high: float=levels[j+1]
		for i in range(16):
			var a: float=TAU*float(i)/16.0
			var b: float=TAU*float(i+1)/16.0
			var p0: Vector3=BODY._point(low,a,genome)
			var p1: Vector3=BODY._point(high,a,genome)
			var p2: Vector3=BODY._point(high,b,genome)
			var p3: Vector3=BODY._point(low,b,genome)
			for point in [p0,p1,p2,p0,p2,p3]:
				var outward: Vector3=Vector3(point.x*1.042,point.y,
					point.z*1.042)
				hem.set_uv(Vector2(outward.x*1.9,outward.y*2.1))
				hem.add_vertex(outward)
	hem.generate_normals()
	var outer:=MeshInstance3D.new()
	outer.name="CutAndRepairedTunicPanels"
	outer.mesh=hem.commit()
	figure.add_child(outer)
	# Real waist measurement also determines the belt circumference and
	# buckle position; neither floats around a differently sized citizen.
	for i in range(16):
		var a: float=TAU*float(i)/16.0
		var b: float=TAU*float(i+1)/16.0
		var p0: Vector3=BODY._point(1.054,a,genome)
		var p1: Vector3=BODY._point(1.054,b,genome)
		p0.x*=1.085
		p0.z*=1.085
		p1.x*=1.085
		p1.z*=1.085
		ART.bone(figure,p0,p1,.048,.035,leather,7)
	var front: Vector3=BODY._point(1.054,-PI*.5,genome)
	var buckle:=ART.box(figure,Vector3(0,1.05,front.z*1.09-.021),
		Vector3(.10,.08,.025),trim)
	buckle.name="SmallTarnishedBeltBuckle"
	var pocket:=ART.box(figure,Vector3(.28,.91,-.20),
		Vector3(.135,.16,.045),leather,Vector3(0,-.22,0))
	pocket.name="WornHipPouchSeam"
	# Removed three exposed shoulder/collar cylinders. Their helper-like
	# ivory bars looked disconnected from the torso when the NPC turned.
	# The tunic owns the shoulder silhouette; cuffs stay rig-attached.
	for sign in [-1.0,1.0]:
		# Cuffs are parented to animated arms and change with each step.
		var arm: Node3D=figure.get_node_or_null(
			"AnimatedLeftArm" if sign<0.0 else "AnimatedRightArm") as Node3D
		if arm!=null:
			# The old rigid dark wrist barrel should not be wider than
			# the fabric directly above it.
			ART.bone(arm,Vector3(sign*.064,-.383,-.045),
				Vector3(sign*.076,-.418,-.047),.089,.084,leather,8)
		var leg: Node3D=figure.get_node_or_null(
			"AnimatedLeftLeg" if sign<0.0 else "AnimatedRightLeg") as Node3D
		# The inherited lower-leg shell and fitted boot already have a
		# tapered ankle; adding another cuff box would recreate stacked cubes.
	# Dye variation belongs to the profession, not to a random rainbow.
	match person:
		"mara":
			var scribe:=ART.mat(Color("716d67"),.98)
			ART.box(figure,Vector3(-.30,1.27,.14),
				Vector3(.18,.66,.18),scribe,Vector3(0,0,-.15))
		"daro":
			# Mud-stained lower apron and practical cloth seam.
			ART.bone(figure,Vector3(-.36,.53,-.15),
				Vector3(.34,.54,-.15),.043,.034,worn,8)
		"orin":
			# Tiny rivets and leather reinforcement around an existing apron.
			for sign in [-1.0,1.0]:
				ART.box(figure,Vector3(sign*.28,.92,-.443),
					Vector3(.045,.045,.035),trim)
		"ida":
			# Former bright rods projected far from the baker's hips.
			# A narrow dark linen knot follows the inherited side waist.
			for sign in [-1.0,1.0]:
				var knot: Vector3=BODY._point(1.045,
					-PI*.5+sign*1.10,genome)
				var loose_end: Vector3=BODY._point(.91,
					-PI*.5+sign*1.18,genome)
				knot.x*=1.055
				knot.z*=1.055
				loose_end.x*=1.065
				loose_end.z*=1.065
				var tie:=ART.bone(figure,knot,loose_end,
					.014,.010,worn,7)
				tie.name="BakerFittedLeftTie" if sign<0.0 else "BakerFittedRightTie"
		_:
			pass

static func dress_attendant(attendant: Node3D) -> void:
	# A station worker should have a uniform silhouette, not a medieval
	# figure with a cap pasted on. Existing independent attendant stays.
	var seam:=ART.mat(Color("333d3c"),.99)
	var faded:=ART.mat(Color("73817b"),.96)
	for sign in [-1.0,1.0]:
		ART.bone(attendant,Vector3(sign*.20,1.54,-.198),
			Vector3(sign*.20,1.18,-.201),.018,.012,seam,7)
		ART.box(attendant,Vector3(sign*.19,1.07,-.226),
			Vector3(.18,.12,.035),faded)
	ART.bone(attendant,Vector3(-.30,.81,-.25),
		Vector3(.30,.81,-.25),.044,.028,seam,7)
	ART.box(attendant,Vector3(.17,1.41,-.194),
		Vector3(.19,.055,.035),faded)
