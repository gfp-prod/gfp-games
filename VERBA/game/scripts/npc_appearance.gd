extends RefCounted
## Stylized, anatomical low-poly villagers. All body dimensions are driven by
## npc_genetics; occupation props are applied by npc_actor after this builder.
const ART = preload("res://scripts/art.gd")

static func build(figure: Node3D, genes: Dictionary, cloth: Material, trim: Material, skin: Material, leather: Material) -> Dictionary:
	var female := String(genes.get("sex","female")) == "female"
	var h := float(genes.get("height",1.0))
	var shoulder := float(genes.get("shoulders",.6))*.5
	var waist := float(genes.get("waist",.45))*.5
	var hip := float(genes.get("hips",.63))*.5
	var face := float(genes.get("face",1.0))
	var nose := float(genes.get("nose",1.0))
	var eye := float(genes.get("eyes",1.0))
	var brow_size := float(genes.get("brows",1.0))
	var style := String(genes.get("style","short"))
	var outfit := String(genes.get("outfit","tunic"))
	figure.scale = Vector3(1.0,h,1.0)

	# Two contiguous *modeled* contours, not CylinderMesh barrel pieces.
	# Shared join ring at y=1.20 prevents the visible circular chest seam.
	var pelvis := _loft(figure,"AnatomicalWaistAndHips",[
		Vector3(hip*.77,.79,.225),Vector3(hip*.98,.95,.275),
		Vector3(hip*.88,1.08,.252),Vector3(waist*.97,1.20,.225)
	],cloth)
	var chest_depth := .245+float(genes.get("chest",.12))*(.33 if female else .12)
	var upper := _loft(figure,"TaperedVillagerTunic",[
		Vector3(waist*.97,1.20,.225),Vector3(waist*1.03,1.32,.238),
		Vector3(shoulder*.97,1.44,chest_depth),
		Vector3(shoulder*.90,1.54,.216),Vector3(.110,1.625,.108)
	],cloth)
	# Neck is a small continuous anatomical volume, not the exposed white
	# vertical CylinderMesh protruding through the collarbone/chest.
	var neck := ART.orb(figure,Vector3(0,1.645,.018),Vector3(.094,.103,.092),skin,12)
	neck.name = "ModeledNeck"
	# Clothing follows the hip and waist contours, not a second cylindrical robe.
	if outfit in ["dress","coat"]:
		var hem := _loft(figure,"TailoredSkirtOrCoatHem",[
			Vector3(hip*(1.12 if outfit=="dress" else 1.02),.56,.32),
			Vector3(hip*1.08,.75,.294),Vector3(hip*.97,.96,.271)
		],cloth)
		if outfit=="coat":
			ART.box(figure,Vector3(0,.77,-.30),Vector3(.025,.31,.02),trim)
	else:
		_loft(figure,"TailoredTunicHem",[
			Vector3(hip*1.03,.70,.270),Vector3(hip*.99,.84,.255),
			Vector3(hip*.94,.96,.267)
		],cloth)
	ART.bone(figure,Vector3(-waist*.95,1.17,-.235),
		Vector3(waist*.95,1.17,-.235),.014,.014,trim,9)
	# Keep the modeled face but bring it into proportion with longer legs.
	# Scaling around the original face center retains all eye/nose/lip alignment.
	var head_parent := Node3D.new()
	head_parent.name = "ProportionalFaceRig"
	head_parent.scale = Vector3.ONE*.69
	head_parent.position.y = 1.78*(1.0-.69)
	figure.add_child(head_parent)
	var head := ART.orb(head_parent,Vector3(0,1.78,0),
		Vector3((.392 if female else .418)*face,(.475 if female else .455)*face,.355*face),skin,14)
	head.name="ModeledInhabitantHead"
	var hair := ART.mat(Color(String(genes.get("hair","372822"))),.96)
	var brow := ART.mat(Color(String(genes.get("hair","372822"))).darkened(.15),.93)
	var sclera := ART.mat(Color("ded1bd"),.73)
	var iris := ART.mat(Color("66594a" if female else "4b5b56"),.66)
	var pupil := ART.mat(Color("191c1a"),.64)
	var lips := ART.mat(Color(String(genes.get("skin","a98b72"))).darkened(.10),.89)
	var cheek_width := .18*face
	# Actual facial volume: cheekbones, bridge and tip of the nose, lips, ears.
	for side in [-1.0,1.0]:
		ART.orb(head_parent,Vector3(side*cheek_width*.67,1.725,-.139*face),
			Vector3(.10,.090,.075),skin,11)
		ART.orb(head_parent,Vector3(side*.203*face,1.759,0),
			Vector3(.066,.12,.075),skin,9)
		var eyeball := ART.orb(head_parent,Vector3(side*.087*face,1.806,-.179*face),
			Vector3(.070*eye,.048*eye,.036),sclera,12)
		eyeball.name = "VisibleLeftEye" if side<0 else "VisibleRightEye"
		ART.orb(head_parent,Vector3(side*.087*face,1.804,-.211*face),
			Vector3(.033*eye,.037*eye,.017),iris,12)
		ART.orb(head_parent,Vector3(side*.087*face,1.804,-.228*face),
			Vector3(.017*eye,.026*eye,.010),pupil,10)
		ART.bone(head_parent,Vector3(side*.042,1.872,-.185*face),
			Vector3(side*.146,1.879+(brow_size-1.0)*.022,-.167*face),
			(.009 if female else .014)*brow_size,.009*brow_size,brow,8)
	ART.bone(head_parent,Vector3(0,1.84,-.169*face),
		Vector3(0,1.732,-.218*face),.038*nose,.052*nose,skin,10)
	var nose_tip:=ART.orb(head_parent,Vector3(0,1.721,-.225*face),
		Vector3(.085*nose,.058,.052*nose),skin,11)
	nose_tip.name="ModeledNoseTip"
	var upper_lip:=ART.orb(head_parent,Vector3(0,1.648,-.175*face),
		Vector3(.106,.024,.026),lips,12)
	upper_lip.name="ModeledUpperLip"
	var lower_lip:=ART.orb(head_parent,Vector3(0,1.622,-.172*face),
		Vector3(.098,.019,.025),lips,12)
	lower_lip.name="ModeledLowerLip"
	# Styled hair genuinely changes the outline of the head.
	_hair(head_parent,style,hair,face)
	if not female and int(genes.get("beard",0))>0:
		_beard(head_parent,int(genes["beard"]),hair)
	# Cloth trousers should remain readable against dark leather boots; the
	# previous implementation made every leg a featureless dark leather tube.
	var cloth_color := Color("6b665e")
	if cloth is StandardMaterial3D:
		cloth_color = (cloth as StandardMaterial3D).albedo_color
	var trousers := ART.mat(cloth_color.darkened(.24),.99)
	var arms: Dictionary={}
	var legs: Dictionary={}

	for side in [-1.0,1.0]:
		var arm:=Node3D.new()
		arm.name="AnimatedLeftArm" if side<0 else "AnimatedRightArm"
		arm.position=Vector3(side*(shoulder+.022),1.51,0)
		figure.add_child(arm)
		# Shoulder is narrow enough to disappear into the upper chest.
		# Gradual sleeve and wrist tapers avoid the old huge squared guards.
		_loft(arm,"TailoredUpperArm",[
			Vector3(.084,-.385,.087),Vector3(.095,-.235,.092),
			Vector3((.097 if female else .116),-.085,.102),
			Vector3((.091 if female else .114),.025,.102)
		],cloth,12)
		_loft(arm,"TailoredForearm",[
			Vector3(.065,-.750,.068),Vector3(.079,-.590,.082),
			Vector3(.083,-.385,.087)
		],cloth,12)
		var hand:=ART.orb(arm,Vector3(0,-.810,-.022),
			Vector3(.078,.103,.083),skin,12)
		hand.name="AnatomicalHand"
		var leg:=Node3D.new()
		leg.name="AnimatedLeftLeg" if side<0 else "AnimatedRightLeg"
		leg.position=Vector3(side*hip*.51,1.025,.012)
		figure.add_child(leg)
		# The upper legs tuck into the hips, then taper into real knees and
		# calves. They remain individually detachable at their own pivots.
		_loft(leg,"AnatomicalThigh",[
			Vector3(.104,-.505,.102),Vector3(.119,-.405,.115),
			Vector3(.141,-.255,.139),Vector3(.153,-.075,.151),
			Vector3(.148,.025,.148)
		],trousers,12)
		_loft(leg,"AnatomicalCalf",[
			Vector3(.074,-.870,.076),Vector3(.095,-.730,.097),
			Vector3(.111,-.635,.113),Vector3(.107,-.505,.105)
		],trousers,12)
		# Leather has a separate shaped boot, not the same material as
		# the whole leg or an exposed round cylinder at the knee.
		_loft(leg,"FittedLeatherBoot",[
			Vector3(.088,-.936,.096),Vector3(.099,-.842,.102),
			Vector3(.097,-.747,.101)
		],leather,12)
		var boot:=ART.orb(leg,Vector3(0,-.929,-.105),
			Vector3(.123,.087,.215),leather,12)
		boot.name="AnatomicalBootToe"
		if side<0.0:
			arms["left"]=arm
			legs["left"]=leg
		else:
			arms["right"]=arm
			legs["right"]=leg
	# Name these pivots for later injury/medical systems, rather than fusing
	# limbs into the torso mesh. Removing a limb never destroys the actor.
	return {"head":head,"left_arm":arms["left"],"right_arm":arms["right"],
		"left_leg":legs["left"],"right_leg":legs["right"]}


# Low-poly cross-section loft. Multiple anatomical contours share a continuous
# skin/clothing surface instead of identical primitive cylinders. Each ring
# specifies half-width, height, half-depth. Separate meshes preserve limb pivots.
static func _loft(parent: Node3D, node_name: String, rings: Array[Vector3],
		material: Material, sides: int = 12) -> MeshInstance3D:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_material(material)
	for k in range(rings.size()-1):
		var low: Vector3=rings[k]
		var high: Vector3=rings[k+1]
		for i in range(sides):
			var a:=TAU*float(i)/float(sides)
			var b:=TAU*float((i+1)%sides)/float(sides)
			var lo_a:=Vector3(cos(a)*low.x,low.y,sin(a)*low.z)
			var lo_b:=Vector3(cos(b)*low.x,low.y,sin(b)*low.z)
			var hi_a:=Vector3(cos(a)*high.x,high.y,sin(a)*high.z)
			var hi_b:=Vector3(cos(b)*high.x,high.y,sin(b)*high.z)
			# From outside the body the surface must face OUTWARD.
			# The earlier order was clockwise viewed from the exterior:
			# backface culling made the anatomical body disappear, leaving
			# collars and primitive role props sticking through its silhouette.
			for v in [lo_a,hi_a,lo_b,lo_b,hi_a,hi_b]:
				surface.add_vertex(v)
	surface.generate_normals()
	var result:=MeshInstance3D.new()
	result.name=node_name
	result.mesh=surface.commit()
	parent.add_child(result)
	return result

static func _hair(parent: Node3D, style: String, material: Material, face: float) -> void:
	# Hair is built from tapered locks and overlapping strands, not a huge
	# cylindrical helmet. The outline matters at actual game camera distance.
	var crown:=ART.orb(parent,Vector3(0,1.987,.025),
		Vector3(.412*face,.16,.356*face),material,12)
	crown.name="InheritedHairCrown"
	if style=="crop":
		crown.scale.y=.105
	elif style in ["short","messy"]:
		for s in [-1.0,1.0]:
			ART.orb(parent,Vector3(s*.162,1.935,.005),
				Vector3(.11,.105,.19),material,9)
		if style=="messy":
			for i in range(7):
				var a:=TAU*float(i)/7.0
				ART.bone(parent,Vector3(cos(a)*.12,2.035,sin(a)*.12),
					Vector3(cos(a)*.16,2.135,sin(a)*.15),.075,.025,material,7)
	elif style in ["medium","bob","long"]:
		var bottom:=1.71 if style=="medium" else (1.53 if style=="bob" else 1.27)
		for s in [-1.0,1.0]:
			# Face-framing side locks reveal the cheeks and jawline.
			ART.bone(parent,Vector3(s*.172,1.96,-.024),
				Vector3(s*.21,bottom,-.053),.083,.054,material,10)
			if style=="long":
				for j in range(3):
					ART.bone(parent,Vector3(s*(.13+float(j)*.055),1.87,.13),
						Vector3(s*(.13+float(j)*.061),1.12+float(j)*.075,.11),
						.062,.033,material,8)
	elif style=="braid":
		for s in [-1.0,1.0]:
			ART.bone(parent,Vector3(s*.174,1.97,-.027),
				Vector3(s*.199,1.65,-.040),.075,.055,material,10)
			for j in range(5):
				ART.orb(parent,Vector3(s*.205,1.60-float(j)*.098,-.045),
					Vector3(.11,.13,.11),material,9)
	elif style=="bun":
		ART.orb(parent,Vector3(0,2.038,.20),Vector3(.30,.27,.30),material,11)
		for s in [-1.0,1.0]:
			ART.bone(parent,Vector3(s*.188,1.96,.015),
				Vector3(s*.180,1.72,.025),.073,.046,material,9)
	elif style=="curly":
		for i in range(15):
			var a:=TAU*float(i%10)/10.0
			var upper:=i>=10
			var r:=.175 if not upper else .095
			ART.orb(parent,Vector3(cos(a)*r,2.005+(.078 if upper else 0.0),
				sin(a)*r),Vector3(.135,.137,.136),material,9)
		for s in [-1.0,1.0]:
			ART.orb(parent,Vector3(s*.206,1.856,.010),
				Vector3(.109,.165,.125),material,9)

static func _beard(parent: Node3D, length: int, material: Material) -> void:
	var depth:=.14 if length==1 else (.20 if length==2 else .29)
	var chin:=ART.orb(parent,Vector3(0,1.605,-.110),
		Vector3(.29,.17+depth,.20),material,11)
	chin.name="InheritedFacialHair"
	for s in [-1.0,1.0]:
		ART.orb(parent,Vector3(s*.11,1.660,-.170),
			Vector3(.13,.052,.065),material,9)
		if length>=2:
			ART.bone(parent,Vector3(s*.169,1.74,-.082),
				Vector3(s*.125,1.59,-.11),.070,.085,material,8)
