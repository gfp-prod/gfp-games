extends RefCounted
## Distinctive field-worn costume details for the existing animated NPC rigs.
## Tapered garments, occupational wear and garments grounded in construction.
## Not a replacement skeleton: the tested AnimatedLeft/Right limbs and all
## collision, conversations and work roles remain exactly as before.
const ART=preload("res://scripts/art.gd")

static func dress(figure: Node3D,person: String,
		tunic: Material,trim: Material,leather: Material) -> void:
	var variant: int=absi(person.hash())%4
	var worn:=ART.mat(Color("514b42"),.99)
	var cloth_dark: StandardMaterial3D=ART.mat(
		Color("635c54") if variant%2==0 else Color("6c675b"),.98)
	cloth_dark.albedo_texture=load("res://assets/textures/authored/aged_vellum.png")
	cloth_dark.uv1_triplanar=true
	cloth_dark.uv1_scale=Vector3(2.4,2.4,2.4)
	# Overlapping fabric planes on a mannequin cause z-fighting. This 12-sided
	# shaped silhouette sits outside the existing tunic and pinches at waist.
	var hem:=SurfaceTool.new()
	hem.begin(Mesh.PRIMITIVE_TRIANGLES)
	hem.set_material(tunic)
	for i in range(12):
		var a: float=TAU*float(i)/12.0
		var b: float=TAU*float(i+1)/12.0
		var top_a:=Vector3(cos(a)*.295,1.23,sin(a)*.295)
		var top_b:=Vector3(cos(b)*.295,1.23,sin(b)*.295)
		var bottom_a:=Vector3(cos(a)*(.41+.017*sin(float(i)*2.2)),.48+.025*sin(float(i)*1.3),sin(a)*.40)
		var bottom_b:=Vector3(cos(b)*(.41+.017*sin(float(i+1)*2.2)),.48+.025*sin(float(i+1)*1.3),sin(b)*.40)
		for p in [top_a,bottom_a,top_b,top_b,bottom_a,bottom_b]:
			hem.set_uv(Vector2(p.x*1.9,p.y*2.1))
			hem.add_vertex(p)
	hem.generate_normals()
	var outer:=MeshInstance3D.new()
	outer.name="CutAndRepairedTunicPanels"
	outer.mesh=hem.commit()
	figure.add_child(outer)
	# Leather belt segmented around the body at the actual waist.
	for i in range(12):
		var a: float=TAU*float(i)/12.0
		var b: float=TAU*float(i+1)/12.0
		var p:=Vector3(cos(a)*.332,1.055,sin(a)*.332)
		var q:=Vector3(cos(b)*.332,1.055,sin(b)*.332)
		ART.bone(figure,p,q,.064,.043,leather,6)
	var buckle:=ART.box(figure,Vector3(0,1.05,-.352),
		Vector3(.10,.08,.025),trim)
	buckle.name="SmallTarnishedBeltBuckle"
	var pocket:=ART.box(figure,Vector3(.28,.91,-.20),
		Vector3(.135,.16,.045),leather,Vector3(0,-.22,0))
	pocket.name="WornHipPouchSeam"
	# Stitch-repaired collar and shaped shoulder pieces break the plain cone.
	ART.bone(figure,Vector3(-.26,1.47,-.12),Vector3(.26,1.47,-.12),
		.065,.046,cloth_dark,8)
	for sign in [-1.0,1.0]:
		ART.bone(figure,Vector3(sign*.18,1.49,-.12),
			Vector3(sign*.34,1.39,.02),.075,.060,cloth_dark,8)
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
