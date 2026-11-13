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
		Vector3(.405*face,.455*face,.355*face),skin,14)
	head.name="ModeledInhabitantHead"
	var hair := ART.mat(Color(String(genes.get("hair","372822"))),.96)
	var brow := ART.mat(Color(String(genes.get("hair","372822"))).darkened(.15),.93)
	var sclera := ART.mat(Color("ded1bd"),.73)
	var iris := ART.mat(Color("66594a" if female else "4b5b56"),.66)
	var pupil := ART.mat(Color("191c1a"),.64)
	var lips := ART.mat(Color(String(genes.get("skin","a98b72"))).darkened(.20),.89)
	var cheek_width := .205*face
	# Actual facial volume: cheekbones, bridge and tip of the nose, lips, ears.
	for side in [-1.0,1.0]:
		ART.orb(figure,Vector3(side*cheek_width*.67,1.725,-.139*face),
			Vector3(.155,.115,.096),skin,11)
		ART.orb(figure,Vector3(side*.203*face,1.759,0),
			Vector3(.085,.17,.10),skin,9)
		var eyeball := ART.orb(figure,Vector3(side*.087*face,1.806,-.179*face),
			Vector3(.092*eye,.067*eye,.052),sclera,12)
		eyeball.name = "VisibleLeftEye" if side<0 else "VisibleRightEye"
		ART.orb(figure,Vector3(side*.087*face,1.804,-.211*face),
			Vector3(.048*eye,.052*eye,.024),iris,12)
		ART.orb(figure,Vector3(side*.087*face,1.804,-.228*face),
			Vector3(.023*eye,.036*eye,.013),pupil,10)
		ART.bone(figure,Vector3(side*.042,1.872,-.185*face),
			Vector3(side*.146,1.879+(brow_size-1.0)*.022,-.167*face),
			.017*brow_size,.012*brow_size,brow,8)
	ART.bone(figure,Vector3(0,1.84,-.169*face),
		Vector3(0,1.732,-.218*face),.050*nose,.066*nose,skin,10)
	var nose_tip:=ART.orb(figure,Vector3(0,1.721,-.225*face),
		Vector3(.124*nose,.074,.079*nose),skin,11)
	nose_tip.name="ModeledNoseTip"
	var upper_lip:=ART.orb(figure,Vector3(0,1.648,-.175*face),
		Vector3(.148,.043,.049),lips,12)
	upper_lip.name="ModeledUpperLip"
	var lower_lip:=ART.orb(figure,Vector3(0,1.622,-.172*face),
		Vector3(.136,.030,.042),lips,12)
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
		ART.bone(arm,Vector3.ZERO,Vector3(side*.035,-.365,-.005),.116,.094,cloth,10)
		ART.orb(arm,Vector3(side*.035,-.382,-.005),Vector3(.095,.085,.09),trim,9)
		ART.bone(arm,Vector3(side*.035,-.385,-.005),
			Vector3(side*.053,-.745,-.045),.090,.070,cloth,9)
		ART.orb(arm,Vector3(side*.054,-.78,-.045),Vector3(.119,.145,.102),skin,11)
		var leg:=Node3D.new()
		leg.name="AnimatedLeftLeg" if side<0 else "AnimatedRightLeg"
		leg.position=Vector3(side*hip*.52,.76,.02)
		figure.add_child(leg)
		ART.bone(leg,Vector3.ZERO,Vector3(0,-.30,.005),.135,.114,leather,10)
		ART.bone(leg,Vector3(0,-.31,.005),Vector3(0,-.63,.005),.106,.083,leather,9)
		ART.box(leg,Vector3(0,-.67,-.09),Vector3(.24,.13,.40),leather)
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
	var crown:=ART.orb(parent,Vector3(0,1.992,.027),
		Vector3(.435*face,.20,.373*face),material,12)
	crown.name="InheritedHairCrown"
	if style=="crop":
		crown.scale.y=.12
	elif style in ["short","messy","medium","bob","long","braid","bun","curly"]:
		if style=="short":
			for s in [-1.0,1.0]:
				ART.orb(parent,Vector3(s*.18,1.935,.002),Vector3(.14,.15,.30),material,9)
		if style=="messy":
			for i in range(7):
				var angle:=TAU*float(i)/7.0
				ART.orb(parent,Vector3(cos(angle)*.14,2.066,sin(angle)*.13),
					Vector3(.20,.17,.16),material,8)
		if style in ["medium","bob","long"]:
			var end_y:=1.70 if style=="medium" else (1.59 if style=="bob" else 1.29)
			for s in [-1.0,1.0]:
				ART.bone(parent,Vector3(s*.202,1.975,.028),Vector3(s*.225,end_y,.035),
					.128,.101,material,10)
		if style=="long":
			for s in [-1.0,1.0]:
				ART.bone(parent,Vector3(s*.15,1.96,.13),
					Vector3(s*.18,1.16,.22),.125,.085,material,10)
		if style=="braid":
			ART.bone(parent,Vector3(0,1.98,.18),
				Vector3(0,1.37,.22),.14,.082,material,9)
			for i in range(5):
				ART.orb(parent,Vector3(0,1.82-float(i)*.12,.24),
					Vector3(.16-float(i)*.012,.11,.13),material,9)
		if style=="bun":
			ART.orb(parent,Vector3(0,2.08,.23),Vector3(.36,.31,.34),material,11)
		if style=="curly":
			for i in range(18):
				var a:=TAU*float(i)/9.0
				var ring:=0 if i<9 else 1
				ART.orb(parent,Vector3(cos(a)*(.17+ring*.03),
					2.045+ring*.11,sin(a)*(.13+ring*.04)),
					Vector3(.19,.20,.18),material,8)

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
