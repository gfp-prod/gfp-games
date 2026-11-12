extends RefCounted
## Individual, physically modeled facial features for existing village people.
## Low-poly surfaces use diffuse pigment, real depth and local face planes.
## The original head, capsule, jobs, identities and conversations remain.
const ART=preload("res://scripts/art.gd")

static func finish(figure: Node3D, person: String,
		skin: Material, hair: Material, brow: Material) -> void:
	if figure.get_node_or_null("IndividualFaceConstruction")!=null:
		return
	var root:=Node3D.new()
	root.name="IndividualFaceConstruction"
	figure.add_child(root)
	var variation: int=absi(person.hash())%4
	var shade: StandardMaterial3D=ART.mat(Color("54443a"),.99)
	var lip: StandardMaterial3D=ART.mat(Color("6d5148"),.97)
	var pupil: StandardMaterial3D=ART.mat(Color("302c27"),.88)
	var cheek: StandardMaterial3D=ART.mat(Color("917562"),1.0)
	# Ears and cheek facets sit on the curved scalp rather than levitating
	# in front of an opaque spherical head.
	for sign in [-1.0,1.0]:
		var ear:=ART.orb(root,Vector3(sign*.224,1.755,.012),
			Vector3(.125,.184,.103),skin,10)
		ear.name="ModeledEar"
		ART.orb(root,Vector3(sign*.234,1.748,-.043),
			Vector3(.036,.068,.021),cheek,8)
		var cheek_point:=ART.orb(root,
			Vector3(sign*.132,1.710,-.152),
			Vector3(.092,.074,.048),skin,10)
		cheek_point.name="NaturalCheekPlane"
		# Narrow lids and dark socket recesses; no protruding glass marbles.
		var eye:=ART.orb(root,Vector3(sign*.082,1.788,-.194),
			Vector3(.062,.033,.022),shade,10)
		eye.name="RecessedEyeSocket"
		var glint:=ART.orb(root,Vector3(sign*.083,1.786,-.208),
			Vector3(.030,.017,.009),pupil,9)
		glint.name="SmallDarkEye"
		var lid:=ART.bone(root,
			Vector3(sign*.048,1.811,-.207),
			Vector3(sign*.117,1.812,-.200),.012,.009,skin,9)
		lid.name="UpperEyelid"
		ART.bone(root,Vector3(sign*.052,1.840,-.189),
			Vector3(sign*.127,1.833,-.177),.017,.011,brow,9)
	# A proper bridge and tip cast a readable profile shadow. The curved
	# eye-to-nose transition is more credible than the old bead nose.
	var bridge:=ART.orb(root,Vector3(0,1.739,-.174),
		Vector3(.081,.182,.112),skin,12)
	bridge.name="NoseBridgeAndPlane"
	ART.orb(root,Vector3(0,1.691,-.227),
		Vector3(.095,.062,.081),skin,10)
	ART.bone(root,Vector3(-.034,1.638,-.173),
		Vector3(.036,1.637,-.174),.008,.008,lip,8)
	var chin:=ART.orb(root,Vector3(0,1.595,-.121),
		Vector3(.160,.061,.070),skin,11)
	chin.name="ShapedJawAndChin"
	# A close, varied head of hair; the existing occupation bonnet or
	# farmer's hat remains the visible outer headwear where provided.
	var scalp: MeshInstance3D=ART.orb(root,
		Vector3(0,1.961,.034),Vector3(.448,.160,.386),hair,14)
	scalp.name="NaturalHairline"
	if person in ["ida","daro"]:
		scalp.scale.y=.102
	else:
		for i in range(7 if variation==0 else 10):
			var a: float=TAU*float(i)/float(7 if variation==0 else 10)
			var crown:=ART.orb(root,
				Vector3(cos(a)*.174,2.000+.015*float(i%3),sin(a)*.143+.015),
				Vector3(.140,.085,.118),hair,9)
			crown.name="UnevenHairMass"
	# Small individual details distinguish silhouettes by occupation
	# without moving their physics body or rewriting social identity.
	match person:
		"orin":
			# Flattened sideburns and a short dark beard on the smith.
			for sign in [-1.0,1.0]:
				ART.bone(root,Vector3(sign*.172,1.724,-.128),
					Vector3(sign*.126,1.619,-.114),.018,.022,hair,8)
			ART.bone(root,Vector3(-.092,1.594,-.128),
				Vector3(.092,1.594,-.128),.022,.019,hair,9)
		"sela":
			# Wrapped hair at the nape; this is a lived-in trader, not
			# another identical crown worn by every profession.
			ART.orb(root,Vector3(0,1.798,.205),
				Vector3(.238,.258,.175),hair,12).name="BoundHairAtNape"
			ART.bone(root,Vector3(-.180,1.908,.072),
				Vector3(.180,1.912,.072),.035,.036,hair,9)
		"mara":
			ART.orb(root,Vector3(-.208,1.750,.074),
				Vector3(.113,.258,.101),hair,11).name="ScribeHairAtTemple"
		"brin":
			ART.bone(root,Vector3(-.24,1.978,-.051),
				Vector3(.19,1.984,-.056),.053,.040,hair,9)
		_:
			pass
	root.set_meta("professionally_distinct_face",person)
	root.set_meta("no_new_collision",true)
	root.set_meta("facial_variation",variation)
