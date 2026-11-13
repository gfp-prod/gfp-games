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
		genome: Dictionary,cloth: Material,
		sex: String="unspecified") -> MeshInstance3D:
	var existing:=arm.get_node_or_null("GeneticFittedSleeve") as MeshInstance3D
	if existing!=null: return existing
	var shoulder: float=lerpf(.87,1.17,GENES.value(genome,"shoulder_width"))
	var muscle_gene: float=GENES.value(genome,"muscle_tone")
	var muscle: float=lerpf(.78,.97,muscle_gene) if sex=="female" else (
		lerpf(.98,1.13,muscle_gene) if sex=="male" else
		lerpf(.91,1.10,muscle_gene))
	const HEIGHT: Array[float]=[.046,.006,-.060,-.140,-.240,-.330,-.414]
	const CX: Array[float]=[-.058,-.031,-.007,.025,.049,.065,.076]
	const CZ: Array[float]=[-.018,-.024,-.029,-.034,-.042,-.046,-.047]
	const RX: Array[float]=[.067,.072,.079,.076,.070,.066,.062]
	const RZ: Array[float]=[.069,.078,.083,.086,.083,.076,.071]
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
	sleeve.set_meta("anatomic_upper_arm_radius",RX[3]*shoulder*muscle)
	sleeve.set_meta("anatomic_sex_profile",sex)
	sleeve.set_meta("lean_shoulder_taper",true)
	sleeve.set_meta("sealed_upper_shoulder",true)
	sleeve.set_meta("old_limb_pivot_preserved",true)
	sleeve.set_meta("no_new_collision",true)
	arm.add_child(sleeve)
	return sleeve

## The smith's old apron was a broad rectangular slab suspended ahead of
## the abdomen. This shaped leather panel follows inherited torso curvature
## and retains the same visible name for compatible art reviews.
static func smith_work_apron(figure: Node3D,genome: Dictionary,
		hide: Material,leather: Material,trim: Material,
		sex: String="unspecified") -> MeshInstance3D:
	var existing:=figure.get_node_or_null("VisibleSmithApron") as MeshInstance3D
	if existing!=null: return existing
	const HEIGHT: Array[float]=[1.39,1.35,1.30,1.24,1.17,1.10,1.02,.94,.85,.76,.67,.58]
	const COLS: int=11
	var samples: Array[Vector3]=[]
	for y in HEIGHT:
		var relative: float=clampf((1.39-y)/.81,0.0,1.0)
		var half_width: float=lerpf(.19,.28,smoothstep(.0,1.0,relative))
		var body_section: Vector2=BODY._section(y,genome,sex)
		for col in range(COLS):
			var fraction: float=float(col)/float(COLS-1)*2.0-1.0
			var x: float=fraction*half_width
			var a: float=-PI*.5+asin(clampf(x/body_section.x,-.91,.91))
			var point: Vector3=BODY._point(y,a,genome,sex)
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
		var width: float=BODY._section(p_y,genome,sex).x
		var angle: float=-PI*.5+asin(clampf(p_x/width,-.91,.91))
		var face_z: float=BODY._point(p_y,angle,genome,sex).z-.14
		var rivet:=ART.orb(figure,Vector3(p_x,p_y,face_z),
			Vector3(.020,.020,.009),trim,8)
		rivet.name="SmithApronIronRivet"
	# Actual leather tie follows the torso circumference, not a block
	# suspended in front of the chest.
	for side in [-1.0,1.0]:
		var ring_a: float=-PI*.5+side*.72
		var ring_b: float=-PI*.5+side*1.33
		var a: Vector3=BODY._point(.995,ring_a,genome,sex)
		var b: Vector3=BODY._point(.995,ring_b,genome,sex)
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
## An actual elbow and a forearm, independent from the shoulder swing.
## Everything is still a visual child of the original arm limb; an injury
## detaches the whole connected chain. Genetic limb ratio sets the wrist.
static func fitted_forearm(pivot: Node3D,side: float,
		genome: Dictionary,cloth: Material,skin: Material) -> MeshInstance3D:
	var existing:=pivot.get_node_or_null("InheritedForearmSleeve") as MeshInstance3D
	if existing!=null: return existing
	var length: float=GENES.forearm_length(genome)
	var body_depth: float=lerpf(.92,1.09,GENES.value(genome,"body_depth"))
	var mesh_tool:=SurfaceTool.new()
	mesh_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	mesh_tool.set_material(cloth)
	const LEVELS: int=8
	const SIDES: int=14
	for row in range(LEVELS-1):
		for sector in range(SIDES):
			var points: Array[Vector3]=[]
			for pair in [[row,sector],[row+1,sector],[row+1,sector+1],[row,sector+1]]:
				var k: int=int(pair[0])
				var angle: float=TAU*float(pair[1])/float(SIDES)
				var t: float=float(k)/float(LEVELS-1)
				var y: float=lerpf(.050,-length+.067,t)
				var taper: float=lerpf(.061,.054,smoothstep(0.0,1.0,t))
				var bulge: float=.010*sin(PI*t)
				points.append(Vector3(
					side*.016*t+cos(angle)*(taper+bulge),
					y,
					-.012*t+sin(angle)*(taper+bulge)*body_depth))
			for index in [0,1,2,0,2,3]:
				var p: Vector3=points[index]
				mesh_tool.set_uv(Vector2((atan2(p.z,p.x)+PI)/TAU, p.y*1.8))
				mesh_tool.add_vertex(p)
	mesh_tool.generate_normals()
	var sleeve:=MeshInstance3D.new()
	sleeve.name="InheritedForearmSleeve"
	sleeve.mesh=mesh_tool.commit()
	sleeve.material_override=cloth
	sleeve.set_meta("detaches_with_parent_arm",true)
	sleeve.set_meta("inherited_wrist_reach",length)
	sleeve.set_meta("no_new_collision",true)
	pivot.add_child(sleeve)
	# Low-poly anatomical palm instead of the old detached egg-shaped
	# hand. The palm, fingers and thumb are all children of the original
	# movable forearm and the entire arm remains ONE detachable limb.
	var hand: MeshInstance3D=_modeled_hand(pivot,side,genome,skin,length)
	hand.set_meta("detaches_with_parent_arm",true)
	return sleeve

## Twelve-sided palm with real fingers and a thumb, all free of physics.
## Its wrist starts INSIDE the sleeve, eliminating the old bright cuff ring.
static func _modeled_hand(pivot: Node3D,side: float,genome: Dictionary,
		skin: Material,length: float) -> MeshInstance3D:
	var hand_scale: float=lerpf(.92,1.09,GENES.value(genome,"stature"))
	var hand_anchor:=Vector3(side*.016,-length,-.012)
	var st:=SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_material(skin)
	const SIDES: int=12
	var Y: Array[float]=[-length+.073,-length+.041,
		-length-.005,-length-.045,-length-.078]
	var WIDTH: Array[float]=[.038,.044,.050,.049,.042]
	var DEPTH: Array[float]=[.033,.034,.033,.031,.024]
	for row in range(Y.size()-1):
		for sector in range(SIDES):
			var a: float=TAU*float(sector)/float(SIDES)
			var b: float=TAU*float(sector+1)/float(SIDES)
			var corners: Array[Vector3]=[]
			for pair in [[row,a],[row+1,a],[row+1,b],[row,b]]:
				var idx: int=int(pair[0])
				var theta: float=float(pair[1])
				var dx: float=cos(theta)*WIDTH[idx]*hand_scale
				var dz: float=sin(theta)*DEPTH[idx]*hand_scale
				corners.append(Vector3(side*.016+dx,Y[idx],-.012+dz))
			for k in [0,1,2,0,2,3]:
				var p: Vector3=corners[k]
				st.set_uv(Vector2(p.x*3.0,p.y*3.0))
				st.add_vertex(p-hand_anchor)
	# Close the palm underneath the individual finger roots.
	var center:=Vector3(side*.016,Y[-1],-.012)
	for sector in range(SIDES):
		var a: float=TAU*float(sector)/float(SIDES)
		var b: float=TAU*float(sector+1)/float(SIDES)
		for p in [center,
				Vector3(center.x+cos(b)*WIDTH[-1]*hand_scale,
					Y[-1],center.z+sin(b)*DEPTH[-1]*hand_scale),
				Vector3(center.x+cos(a)*WIDTH[-1]*hand_scale,
					Y[-1],center.z+sin(a)*DEPTH[-1]*hand_scale)]:
			st.set_uv(Vector2(p.x*3.0,p.z*3.0))
			st.add_vertex(p-hand_anchor)
	st.generate_normals()
	var palm:=MeshInstance3D.new()
	palm.name="InheritedArticulatedHand"
	palm.position=hand_anchor
	palm.mesh=st.commit()
	palm.material_override=skin
	palm.set_meta("anatomic_palm",true)
	palm.set_meta("detaches_with_parent_arm",true)
	palm.set_meta("no_new_collision",true)
	palm.set_meta("modeled_fingers",4)
	pivot.add_child(palm)
	# Staggered fingertips produce a recognizable hand silhouette at
	# conversational distance; finger scale overlaps inherited stature.
	var lengths: Array[float]=[.062,.077,.073,.056]
	for finger in range(4):
		var offset: float=(float(finger)-1.5)*.022*hand_scale
		var x: float=side*.016+offset
		var begin:=Vector3(x,-length-.066,-.013)
		var end:=Vector3(x+side*.003,
			-length-.076-lengths[finger]*hand_scale,-.018)
		var phalanx:=ART.bone(pivot,begin,end,
			.014*hand_scale,.010*hand_scale,skin,8)
		phalanx.name="Finger"+str(finger)+"LowPolyPhalanges"
		phalanx.set_meta("detaches_with_parent_arm",true)
		phalanx.set_meta("no_new_collision",true)
	# The fifth digit projects forward and folds toward the palm; it is
	# not an extra straight fifth vertical tube.
	var thumb_base:=Vector3(side*.055*hand_scale,-length-.024,-.031)
	var thumb_joint:=Vector3(side*.083*hand_scale,-length-.056,-.050)
	var thumb_tip:=Vector3(side*.080*hand_scale,-length-.094,-.061)
	var thumb_a:=ART.bone(pivot,thumb_base,thumb_joint,
		.017*hand_scale,.013*hand_scale,skin,8)
	thumb_a.name="AnatomicalThumbMetacarpal"
	var thumb_b:=ART.bone(pivot,thumb_joint,thumb_tip,
		.012*hand_scale,.009*hand_scale,skin,8)
	thumb_b.name="AnatomicalThumbDistal"
	thumb_a.set_meta("no_new_collision",true)
	thumb_b.set_meta("no_new_collision",true)
	return palm


static func fitted_lower_leg(leg: Node3D,side: float,
		genome: Dictionary,sex: String="unspecified") -> MeshInstance3D:
	# The entire parent leg remains the ONE existing severable part.
	# Its separately deforming knee is visual-only: no additional hitbox,
	# save identity, simulation limb, or collision shape.
	var existing:=leg.get_node_or_null("GeneticTrouserLeg") as MeshInstance3D
	if existing!=null: return existing
	var cloth:=FABRIC.worn_linen(Color("565951"))
	var boot_hide:=FABRIC.worn_leather(Color("372d28"))
	var hip_gene: float=GENES.value(genome,"hip_width")
	var muscle_gene: float=GENES.value(genome,"muscle_tone")
	var mass: float=lerpf(.88,1.13,hip_gene)
	var thigh_factor: float=lerpf(.99,1.09,hip_gene) if sex=="female" else (
		lerpf(.97,1.09,muscle_gene) if sex=="male" else 1.0)
	var depth: float=lerpf(.91,1.09,GENES.value(genome,"body_depth"))
	# Defined relative to the inherited femoral-head pivot at y=.98.
	# The shin starts INSIDE the lower thigh (not on an open cylinder rim);
	# it can swing independently without a hollow black joint appearing.
	const H: Array[float]=[.092,.019,-.075,-.186,-.297,-.402,-.476,
		-.568,-.665,-.759,-.846]
	const W: Array[float]=[.135,.139,.133,.123,.112,.105,.108,.112,.106,.092,.084]
	const D: Array[float]=[.133,.138,.134,.127,.117,.108,.112,.115,.110,.098,.088]
	const KNEE_Y: float=-.420
	const SEGMENTS: int=16
	var upper:=SurfaceTool.new()
	var lower:=SurfaceTool.new()
	upper.begin(Mesh.PRIMITIVE_TRIANGLES)
	lower.begin(Mesh.PRIMITIVE_TRIANGLES)
	upper.set_material(cloth)
	lower.set_material(cloth)
	# Both use the same inherited leg dimensions. The lower section
	# overlaps slightly inside its upper neighbor at the patella.
	for row in range(H.size()-1):
		var surface: SurfaceTool=upper if row<=5 else lower
		for segment in range(SEGMENTS):
			var a: float=TAU*float(segment)/float(SEGMENTS)
			var b: float=TAU*float(segment+1)/float(SEGMENTS)
			var corners: Array[Vector3]=[]
			for pair in [[row,a],[row+1,a],[row+1,b],[row,b]]:
				var i: int=int(pair[0])
				var angle: float=float(pair[1])
				var wrinkle: float=.005*sin(float(i)*1.6+angle*3.0+side*.35)
				var width: float=W[i]*mass*thigh_factor+wrinkle
				var profile: float=D[i]*depth*lerpf(1.0,thigh_factor,.55)
				var calf: float=1.0+.013*sin(float(i)*1.3)
				var p:=Vector3(cos(angle)*width,
					H[i],sin(angle)*profile*calf+.008*sin(float(i)*.53))
				if row>5: p.y-=KNEE_Y
				corners.append(p)
			for index in [0,1,2,0,2,3]:
				var p: Vector3=corners[index]
				surface.set_uv(Vector2((atan2(p.z,p.x)+PI)/TAU,p.y*1.55))
				surface.add_vertex(p)
	# The first shin ring is tucked into the thigh, avoiding a bright
	# detached-looking upper/lower cylinder seam in straight stance.
	# It follows the same underlying knee pivot and inherited radius.
	for segment in range(SEGMENTS):
		var a: float=TAU*float(segment)/float(SEGMENTS)
		var b: float=TAU*float(segment+1)/float(SEGMENTS)
		var points: Array[Vector3]=[]
		for entry in [[5,a],[6,a],[6,b],[5,b]]:
			var i: int=int(entry[0])
			var theta: float=float(entry[1])
			var radius_factor: float=.945
			points.append(Vector3(
				cos(theta)*(W[i]*mass*thigh_factor)*radius_factor,
				H[i]-KNEE_Y,
				sin(theta)*D[i]*depth*radius_factor))
		for index in [0,1,2,0,2,3]:
			var p: Vector3=points[index]
			lower.set_uv(Vector2((atan2(p.z,p.x)+PI)/TAU,p.y*1.55))
			lower.add_vertex(p)
	upper.generate_normals()
	lower.generate_normals()
	var trousers:=MeshInstance3D.new()
	trousers.name="GeneticTrouserLeg"
	trousers.mesh=upper.commit()
	trousers.material_override=cloth
	trousers.set_meta("original_detachable_leg",true)
	trousers.set_meta("inherited_hip_width",hip_gene)
	trousers.set_meta("anatomic_thigh_factor",thigh_factor)
	trousers.set_meta("true_femoral_length",true)
	trousers.set_meta("no_new_collision",true)
	leg.add_child(trousers)
	var knee:=Node3D.new()
	knee.name="AnatomicalKneeHinge"
	knee.position=Vector3(0,KNEE_Y,0)
	knee.set_meta("articulates_with_stride",true)
	knee.set_meta("detaches_with_original_leg",true)
	knee.set_meta("no_new_collision",true)
	leg.add_child(knee)
	var shin:=MeshInstance3D.new()
	shin.name="InheritedCalfAndShin"
	shin.mesh=lower.commit()
	shin.material_override=cloth
	shin.set_meta("genetic_calf_radius",mass*thigh_factor)
	shin.set_meta("no_new_collision",true)
	knee.add_child(shin)
	# The boot is under the shin pivot, so flexing the knee also moves
	# the ankle and foot; it is never a second physical limb.
	var shoemesh:=SurfaceTool.new()
	shoemesh.begin(Mesh.PRIMITIVE_TRIANGLES)
	shoemesh.set_material(boot_hide)
	const SHOE_Y: Array[float]=[-.756,-.846,-.924,-.973]
	const SHOE_W: Array[float]=[.086,.097,.118,.119]
	const SHOE_Z: Array[float]=[-.022,-.058,-.122,-.128]
	const SHOE_D: Array[float]=[.093,.116,.171,.172]
	for row in range(SHOE_Y.size()-1):
		for segment in range(12):
			var a: float=TAU*float(segment)/12.0
			var b: float=TAU*float(segment+1)/12.0
			var corners: Array[Vector3]=[]
			for pair in [[row,a],[row+1,a],[row+1,b],[row,b]]:
				var i: int=int(pair[0])
				var angle: float=float(pair[1])
				corners.append(Vector3(
					cos(angle)*SHOE_W[i],
					SHOE_Y[i]-KNEE_Y,
					SHOE_Z[i]+sin(angle)*SHOE_D[i]))
			for index in [0,1,2,0,2,3]:
				var point: Vector3=corners[index]
				shoemesh.set_uv(Vector2(point.x*1.6,point.z*1.6))
				shoemesh.add_vertex(point)
	var sole:=Vector3(0,SHOE_Y[-1]-KNEE_Y,SHOE_Z[-1])
	for segment in range(12):
		var a: float=TAU*float(segment)/12.0
		var b: float=TAU*float(segment+1)/12.0
		var rim_a:=Vector3(cos(a)*SHOE_W[-1],SHOE_Y[-1]-KNEE_Y,
			SHOE_Z[-1]+sin(a)*SHOE_D[-1])
		var rim_b:=Vector3(cos(b)*SHOE_W[-1],SHOE_Y[-1]-KNEE_Y,
			SHOE_Z[-1]+sin(b)*SHOE_D[-1])
		for p in [sole,rim_b,rim_a]:
			shoemesh.set_uv(Vector2(p.x,p.z))
			shoemesh.add_vertex(p)
	shoemesh.generate_normals()
	var boot:=MeshInstance3D.new()
	boot.name="GeneticAnkleBoot"
	boot.mesh=shoemesh.commit()
	boot.material_override=boot_hide
	boot.set_meta("weathered_leather",true)
	boot.set_meta("original_detachable_leg",true)
	boot.set_meta("no_new_collision",true)
	knee.add_child(boot)
	return trousers

static func dress(figure: Node3D,person: String,
		tunic: Material,trim: Material,leather: Material,
		genome: Dictionary={},sex: String="unspecified") -> void:
	var worn:=FABRIC.worn_linen(Color("514b42"))
	# The external work garment must follow the ACTUAL inherited waist,
	# ribcage and hips. A fixed triangular cone previously hid all visible
	# differences even though a detailed genetic torso existed underneath.
	var hem:=SurfaceTool.new()
	hem.begin(Mesh.PRIMITIVE_TRIANGLES)
	hem.set_material(tunic)
	var levels: Array[float]=[.61,.70,.83,.98,1.17,1.24]
	for j in range(levels.size()-1):
		var low: float=levels[j]
		var high: float=levels[j+1]
		for i in range(16):
			var a: float=TAU*float(i)/16.0
			var b: float=TAU*float(i+1)/16.0
			var p0: Vector3=BODY._point(low,a,genome,sex)
			var p1: Vector3=BODY._point(high,a,genome,sex)
			var p2: Vector3=BODY._point(high,b,genome,sex)
			var p3: Vector3=BODY._point(low,b,genome,sex)
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
		var p0: Vector3=BODY._point(1.054,a,genome,sex)
		var p1: Vector3=BODY._point(1.054,b,genome,sex)
		p0.x*=1.045
		p0.z*=1.055
		p1.x*=1.045
		p1.z*=1.055
		ART.bone(figure,p0,p1,.019,.017,leather,7)
	var front: Vector3=BODY._point(1.054,-PI*.5,genome,sex)
	var buckle:=ART.box(figure,Vector3(0,1.05,front.z*1.05-.017),
		Vector3(.085,.061,.020),trim)
	buckle.name="SmallTarnishedBeltBuckle"
	var pocket_anchor: Vector3=BODY._point(.93,-.52,genome,sex)
	var pocket:=ART.box(figure,
		Vector3(pocket_anchor.x*1.06,.91,pocket_anchor.z*1.06-.034),
		Vector3(.104,.13,.035),leather,Vector3(0,-.22,0))
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
				Vector3(sign*.076,-.418,-.047),.056,.053,leather,8)
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
					-PI*.5+sign*1.10,genome,sex)
				var loose_end: Vector3=BODY._point(.91,
					-PI*.5+sign*1.18,genome,sex)
				knot.x*=1.055
				knot.z*=1.055
				loose_end.x*=1.065
				loose_end.z*=1.065
				var tie:=ART.bone(figure,knot,loose_end,
					.014,.010,worn,7)
				tie.name="BakerFittedLeftTie" if sign<0.0 else "BakerFittedRightTie"
		_:
			pass

## A station apron draped over a real inherited torso rather than two
## rectangular primitives. It preserves the waist and the lateral outline
## of ribs and hips, which were hidden by the old uniform box.
static func fitted_station_apron(figure: Node3D,genome: Dictionary,
		fabric: Material,sex: String="unspecified") -> MeshInstance3D:
	var existing:=figure.get_node_or_null("FittedStationWorkApron") as MeshInstance3D
	if existing!=null: return existing
	const HEIGHT: Array[float]=[1.40,1.35,1.29,1.19,1.10,1.02,.95,.87,.78,.67,.61]
	const HALF_WIDTH: Array[float]=[.160,.190,.185,.180,.170,.164,.183,.207,.226,.248,.251]
	const COLS: int=13
	var source: Array[Vector3]=[]
	for row in range(HEIGHT.size()):
		var y: float=HEIGHT[row]
		var section: float=BODY._section(y,genome,sex).x
		for col in range(COLS):
			var u: float=float(col)/float(COLS-1)*2.0-1.0
			var x: float=u*HALF_WIDTH[row]
			var angle: float=-PI*.5+asin(clampf(x/section,-.91,.91))
			var body: Vector3=BODY._point(y,angle,genome,sex)
			var drape: float=.090+.026*(1.0-u*u)
			var hem_fold: float=.006*sin(float(col)*1.85) if row>6 else 0.0
			source.append(Vector3(x,y,body.z-drape-hem_fold))
	var st:=SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_material(fabric)
	for row in range(HEIGHT.size()-1):
		for col in range(COLS-1):
			var i: int=row*COLS+col
			for index in [i,i+COLS,i+1,i+1,i+COLS,i+COLS+1]:
				var p: Vector3=source[index]
				st.set_uv(Vector2((p.x+.26)*2.1,(p.y-.59)*1.1))
				st.add_vertex(p)
	st.generate_normals()
	var bib:=MeshInstance3D.new()
	bib.name="FittedStationWorkApron"
	bib.mesh=st.commit()
	if fabric is StandardMaterial3D:
		(fabric as StandardMaterial3D).cull_mode=BaseMaterial3D.CULL_DISABLED
	bib.material_override=fabric
	bib.set_meta("anatomic_body_profile",sex)
	bib.set_meta("contoured_to_hips_and_waist",true)
	bib.set_meta("no_new_collision",true)
	figure.add_child(bib)
	return bib

## Individually shaped period garments, not a waistless cone. Dresses
## expose the inherited waist and high hip before falling into a gently
## pleated hem. Distinct silhouettes come from work and taste as well
## as genes: a baker, scribe, merchant and painter look different.
static func tailored_womenswear(figure: Node3D,person: String,
		genome: Dictionary,sex: String,base: Material) -> MeshInstance3D:
	var old:=figure.get_node_or_null("TailoredHereditaryDress") as MeshInstance3D
	if old!=null: return old
	if sex!="female": return null
	var style: String="field_dress"
	var hem_y: float=.34
	match person:
		"ida": style="baker_apron_dress"; hem_y=.51
		"mara": style="scribe_gown"; hem_y=.38
		"sela": style="layered_merchant_skirt"; hem_y=.54
		"lena": style="painter_smock"; hem_y=.68
		"juno": style="attendant_work_dress"; hem_y=.78
		_: hem_y=lerpf(.39,.66,GENES.value(genome,"hair_style"))
	var trim_color: Color=Color("574138")
	var skirt_color: Color=Color("56534c")
	match style:
		"baker_apron_dress": skirt_color=Color("616255"); trim_color=Color("98846b")
		"scribe_gown": skirt_color=Color("474f49"); trim_color=Color("9c8468")
		"layered_merchant_skirt": skirt_color=Color("5e4947"); trim_color=Color("af8661")
		"painter_smock": skirt_color=Color("526069"); trim_color=Color("b59d72")
		"attendant_work_dress": skirt_color=Color("404c51"); trim_color=Color("868580")
		_: skirt_color=Color("655d51")
	var fabric:=FABRIC.worn_linen(skirt_color)
	if fabric is StandardMaterial3D:
		(fabric as StandardMaterial3D).cull_mode=BaseMaterial3D.CULL_DISABLED
	var detail:=ART.mat(trim_color,.98)
	var st:=SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_material(fabric)
	const RING_COUNT: int=20
	var rows: Array[float]=[]
	for level in [1.07,1.035,1.015,.995,.955,.91,.875,.835,.795,.73,.69,.61,.57,.51,.46,.41,.33]:
		if float(level)>hem_y+.001: rows.append(float(level))
	rows.append(hem_y)
	# The high-hip tunic exposes the original weight-bearing femurs;
	# optional tailored skirts remain distinct garments and lengths.
	# No visible torus at the waist; continuity in the fitted cloth
	# is more important than adding more extraneous belts.
	for row in range(rows.size()-1):
		for i in range(RING_COUNT):
			var corners: Array[Vector3]=[]
			for entry in [[row,i],[row+1,i],[row+1,i+1],[row,i+1]]:
				var ring: int=int(entry[0])
				var k: int=int(entry[1])
				var y: float=rows[ring]
				var theta: float=TAU*float(k)/float(RING_COUNT)
				var p: Vector3=BODY._point(maxf(y,.61),theta,genome,sex)
				var below: float=clampf((.61-y)/maxf(.16,.61-hem_y),0.0,1.0)
				var pleat: float=.012*sin(theta*7.0)*pow(below,1.2)
				var fullness: float=lerpf(1.015,1.235,below)
				# Avoid a generic bell skirt; the waist is close-fitting,
				# the upper hip follows anatomy, and only the hem opens.
				p.x=p.x*fullness+cos(theta)*pleat
				p.z=p.z*fullness+sin(theta)*pleat
				p.y=y+.007*sin(theta*3.0)*below
				corners.append(p)
			for k in [0,1,2,0,2,3]:
				var p: Vector3=corners[k]
				st.set_uv(Vector2((atan2(p.z,p.x)+PI)/TAU*1.4,p.y*1.8))
				st.add_vertex(p)
	st.generate_normals()
	var gown:=MeshInstance3D.new()
	gown.name="TailoredHereditaryDress"
	gown.mesh=st.commit()
	gown.material_override=fabric
	gown.set_meta("tailored_style",style)
	gown.set_meta("body_genes_preserved",true)
	gown.set_meta("separate_sleeves_and_limbs",true)
	gown.set_meta("no_new_collision",true)
	figure.add_child(gown)
	# Thin seam following the true waist; no bright cinching bar.
	var waist: float=1.064
	for i in range(RING_COUNT):
		var a: float=TAU*float(i)/float(RING_COUNT)
		var b: float=TAU*float(i+1)/float(RING_COUNT)
		var pa: Vector3=BODY._point(waist,a,genome,sex)*Vector3(1.03,1.0,1.03)
		var pb: Vector3=BODY._point(waist,b,genome,sex)*Vector3(1.03,1.0,1.03)
		var piping:=ART.bone(figure,pa,pb,.010,.010,detail,7)
		piping.name="TailoredBeltStitch"
	# Work and story details distinguish professions without reusing a
	# huge breastplate or cuboid chest hanging from the body.
	if person in ["sela","mara","lena"]:
		var side: float=-1.0 if person=="mara" else 1.0
		var anchor: Vector3=BODY._point(.925,-PI*.5+side*1.10,genome,sex)
		var pendant:=ART.orb(figure,Vector3(anchor.x*1.06,.92,
			anchor.z*1.07-.012),Vector3(.046,.07,.023),detail,8)
		pendant.name="MerchantOrScholarTalismans"
		if person=="sela":
			var fold:=ART.bone(figure,
				Vector3(side*.15,.985,-.265),
				Vector3(side*.28,.565,-.215),.014,.012,detail,8)
			fold.name="TravelSashDrape"
		elif person=="mara":
			var clasp:=ART.orb(figure,Vector3(0,1.42,-.245),
				Vector3(.045,.055,.020),detail,8)
			clasp.name="ScribeCollarPin"
		else:
			var paint:=ART.orb(figure,
				Vector3(side*.16,.72,-.273),
				Vector3(.047,.065,.009),
				ART.mat(Color("73594c"),.99),8)
			paint.name="PainterWorkStain"
	return gown


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
