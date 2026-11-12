extends RefCounted
## Distinctive field-worn costume details for the existing animated NPC rigs.
## Tapered garments, occupational wear and garments grounded in construction.
## Not a replacement skeleton: the tested AnimatedLeft/Right limbs and all
## collision, conversations and work roles remain exactly as before.
const ART=preload("res://scripts/art.gd")
const FABRIC=preload("res://scripts/npc_cloth_finish.gd")
const BODY=preload("res://scripts/npc_body_morph.gd")

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
			ART.bone(arm,Vector3(sign*.052,-.31,-.035),
				Vector3(sign*.075,-.40,-.045),.117,.113,leather,8)
		var leg: Node3D=figure.get_node_or_null(
			"AnimatedLeftLeg" if sign<0.0 else "AnimatedRightLeg") as Node3D
		if leg!=null:
			ART.box(leg,Vector3(0,-.385,-.02),
				Vector3(.245,.16,.260),worn)
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
			# Waist ties are part of the baker's uniform, not floating ornaments.
			for sign in [-1.0,1.0]:
				ART.bone(figure,Vector3(sign*.30,1.04,-.36),
					Vector3(sign*.44,.79,-.25),.019,.015,trim,7)
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
