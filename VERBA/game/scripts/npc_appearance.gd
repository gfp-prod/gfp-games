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
	# Upper chest tapers into waist. Lower garment widens again over the hips.
	# This replaces the shared barrel/cone torso rather than hiding it.
	var upper := ART.cone(figure,Vector3(0,1.31,0),waist,.49,cloth,shoulder*.98,14)
	upper.name = "TaperedVillagerTunic"
	var pelvis := ART.cone(figure,Vector3(0,.91,0),hip,.36,cloth,waist,14)
	pelvis.name = "AnatomicalWaistAndHips"
	ART.bone(figure,Vector3(0,1.52,0),Vector3(0,1.61,0),.12,.11,skin,10)
	if female:
		# Modest clothed volume, not two exposed spheres or a broad male barrel.
		for side in [-1.0,1.0]:
			ART.orb(figure,Vector3(side*.11,1.30,-shoulder*.48),
				Vector3(.19,.16,.115+float(genes.get("chest",.12))*.23),cloth,11)
	# Body-shape-driven clothing is separate from inherited anatomy.
	if outfit in ["dress","coat"]:
		var skirt := ART.cone(figure,Vector3(0,.61,0),hip*(1.19 if outfit=="dress" else 1.07),.48,
			cloth,hip*.99,12)
		skirt.name = "TailoredSkirtOrCoatHem"
		if outfit=="coat":
			ART.box(figure,Vector3(0,.81,-hip*.97),Vector3(.045,.36,.018),trim)
	else:
		ART.cone(figure,Vector3(0,.69,0),hip*.99,.20,cloth,hip*.97,12)
	ART.bone(figure,Vector3(-waist*.98,1.10,-waist*.81),
		Vector3(waist*.98,1.10,-waist*.81),.020,.020,trim,9)
	var head := ART.orb(figure,Vector3(0,1.78,0),
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
		ART.orb(figure,Vector3(side*cheek_width*.67,1.725,-.139*face),
			Vector3(.10,.090,.075),skin,11)
		ART.orb(figure,Vector3(side*.203*face,1.759,0),
			Vector3(.066,.12,.075),skin,9)
		var eyeball := ART.orb(figure,Vector3(side*.087*face,1.806,-.179*face),
			Vector3(.070*eye,.048*eye,.036),sclera,12)
		eyeball.name = "VisibleLeftEye" if side<0 else "VisibleRightEye"
		ART.orb(figure,Vector3(side*.087*face,1.804,-.211*face),
			Vector3(.033*eye,.037*eye,.017),iris,12)
		ART.orb(figure,Vector3(side*.087*face,1.804,-.228*face),
			Vector3(.017*eye,.026*eye,.010),pupil,10)
		ART.bone(figure,Vector3(side*.042,1.872,-.185*face),
			Vector3(side*.146,1.879+(brow_size-1.0)*.022,-.167*face),
			(.009 if female else .014)*brow_size,.009*brow_size,brow,8)
	ART.bone(figure,Vector3(0,1.84,-.169*face),
		Vector3(0,1.732,-.218*face),.038*nose,.052*nose,skin,10)
	var nose_tip:=ART.orb(figure,Vector3(0,1.721,-.225*face),
		Vector3(.085*nose,.058,.052*nose),skin,11)
	nose_tip.name="ModeledNoseTip"
	var upper_lip:=ART.orb(figure,Vector3(0,1.648,-.175*face),
		Vector3(.106,.024,.026),lips,12)
	upper_lip.name="ModeledUpperLip"
	var lower_lip:=ART.orb(figure,Vector3(0,1.622,-.172*face),
		Vector3(.098,.019,.025),lips,12)
	lower_lip.name="ModeledLowerLip"
	# Styled hair genuinely changes the outline of the head.
	_hair(figure,style,hair,face)
	if not female and int(genes.get("beard",0))>0:
		_beard(figure,int(genes["beard"]),hair)
	var arms: Dictionary={}
	var legs: Dictionary={}
	for side in [-1.0,1.0]:
		var arm:=Node3D.new()
		arm.name="AnimatedLeftArm" if side<0 else "AnimatedRightArm"
		arm.position=Vector3(side*(shoulder+.015),1.51,0)
		figure.add_child(arm)
		ART.bone(arm,Vector3.ZERO,Vector3(side*.035,-.385,-.005),(.080 if female else .115),(.071 if female else .096),cloth,10)
		ART.orb(arm,Vector3(side*.035,-.392,-.005),Vector3(.075,.065,.071),cloth,9)
		ART.bone(arm,Vector3(side*.035,-.385,-.005),
			Vector3(side*.053,-.790,-.045),(.073 if female else .092),(.059 if female else .072),cloth,9)
		ART.orb(arm,Vector3(side*.054,-.808,-.045),Vector3(.099,.129,.089),skin,11)
		var leg:=Node3D.new()
		leg.name="AnimatedLeftLeg" if side<0 else "AnimatedRightLeg"
		leg.position=Vector3(side*hip*.52,.76,.02)
		figure.add_child(leg)
		ART.bone(leg,Vector3.ZERO,Vector3(0,-.30,.005),.135,.114,leather,10)
		ART.bone(leg,Vector3(0,-.31,.005),Vector3(0,-.63,.005),.106,.083,leather,9)
		ART.box(leg,Vector3(0,-.67,-.09),Vector3(.22,.12,.36),leather)
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
