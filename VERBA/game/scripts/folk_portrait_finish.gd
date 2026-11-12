extends RefCounted
## Faceted, genetically individualized faces. One consistent art style;
## dozens of independent inherited proportions rather than three presets.
## Face/eyes/brows/mouth are separate visual controls for expression.
const ART=preload("res://scripts/art.gd")
const GENES=preload("res://scripts/npc_genetics.gd")

static func _v(g: Dictionary,key: String) -> float:
	return GENES.value(g,key)

static func _depth(x: float,y: float,g: Dictionary) -> float:
	var width: float=.197+_v(g,"face_width")*.037
	var length: float=.215+_v(g,"face_length")*.061
	var nx: float=x/width
	var ny: float=(y-1.77)/length
	# Narrower chin versus broader lower jaw is inherited independently
	# of cheekbones. All vertices remain part of a single coherent surface.
	var jaw: float=lerpf(.76,1.26,_v(g,"jaw_width"))
	var cheek: float=lerpf(.83,1.21,_v(g,"cheek_fullness"))
	# Independent inherited jaw angle determines squareness at the chin.
	var angle: float=lerpf(-.028,.038,_v(g,"jaw_angle"))
	var profile: float=lerpf(jaw,cheek,smoothstep(1.66+angle,1.79+angle,y))
	nx/=profile
	var shell: float=-.193*sqrt(maxf(.013,1.0-nx*nx-ny*ny))
	var bridge_width: float=lerpf(.026,.065,_v(g,"nose_width"))
	var bridge_height: float=lerpf(1.715,1.746,_v(g,"nose_bridge"))
	var nose: float=-lerpf(.034,.118,_v(g,"nose_projection"))*exp(
		-pow(x/bridge_width,2.0)-pow((y-bridge_height)/.070,2.0))
	var cheek_height: float=lerpf(1.703,1.756,_v(g,"cheek_height"))
	var cheeks: float=-lerpf(.004,.031,_v(g,"cheek_fullness"))*exp(
		-pow((absf(x)-.115)/.058,2.0)-pow((y-cheek_height)/.054,2.0))
	var eye_level: float=lerpf(1.779,1.804,_v(g,"brow_height"))
	var socket: float=.008*exp(-pow(
		(absf(x)-lerpf(.074,.105,_v(g,"eye_spacing")))/.037,2.0)
		-pow((y-eye_level)/.025,2.0))
	var lips: float=-lerpf(.005,.024,_v(g,"lip_fullness"))*exp(
		-pow(x/.076,2.0)-pow((y-1.666)/.019,2.0))
	return shell+nose+cheeks+socket+lips-.003

static func _integrated_face(root: Node3D,skin: Material,g: Dictionary) -> void:
	# 14*16*6 = 1344 vertices per head. This is a small mesh per
	# genome, generated only once when a character is instantiated.
	var st:=SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var fw: float=lerpf(.90,1.10,_v(g,"face_width"))
	var fy: float=lerpf(.90,1.11,_v(g,"face_length"))
	for yi in range(16):
		for xi in range(14):
			var x0: float=lerpf(-.183,.183,float(xi)/14.0)*fw
			var x1: float=lerpf(-.183,.183,float(xi+1)/14.0)*fw
			var y0: float=1.77+(lerpf(1.575,1.931,float(yi)/16.0)-1.77)*fy
			var y1: float=1.77+(lerpf(1.575,1.931,float(yi+1)/16.0)-1.77)*fy
			var pts: Array[Vector3]=[
				Vector3(x0,y0,_depth(x0,y0,g)),
				Vector3(x0,y1,_depth(x0,y1,g)),
				Vector3(x1,y0,_depth(x1,y0,g)),
				Vector3(x1,y1,_depth(x1,y1,g))]
			for j in [0,1,2,1,3,2]:
				var point: Vector3=pts[j]
				st.set_uv(Vector2((point.x+.20)*2.5,(point.y-1.54)*2.5))
				st.add_vertex(point)
	st.generate_normals()
	var face:=MeshInstance3D.new()
	face.name="IndividualIntegratedFaceMesh"
	face.mesh=st.commit()
	face.material_override=skin
	root.add_child(face)

static func finish(figure: Node3D,person: String,skin: Material,
		hair: Material,brow: Material,genome: Dictionary={}) -> void:
	if figure.get_node_or_null("IndividualFaceConstruction")!=null:
		return
	var g: Dictionary=genome if GENES.validate(genome) else GENES.founder(person)
	var root:=Node3D.new()
	root.name="IndividualFaceConstruction"
	root.set_meta("professionally_distinct_face",person)
	root.set_meta("no_new_collision",true)
	root.set_meta("facial_variation",int(round(_v(g,"face_width")*100)))
	root.set_meta("genetic_face",true)
	figure.add_child(root)
	_integrated_face(root,skin,g)
	var eye_ink:=ART.mat(Color("201c1a"),1.0)
	var iris_ink:=ART.mat(GENES.eye_color(g),.98)
	var lip_ink:=ART.mat(GENES.skin_color(g).darkened(
		lerpf(.31,.18,_v(g,"lip_fullness"))),.99)
	var ear_scale: float=lerpf(.70,1.33,_v(g,"ear_size"))
	var eye_gap: float=lerpf(.068,.113,_v(g,"eye_spacing"))
	var eye_height: float=lerpf(1.780,1.802,_v(g,"brow_height"))
	var eye_width: float=lerpf(.033,.055,_v(g,"eye_shape"))
	var tilt: float=lerpf(-.22,.22,_v(g,"brow_angle"))
	for sign in [-1.0,1.0]:
		var ear:=ART.orb(root,Vector3(sign*.205,1.762,.010),
			Vector3(.065,.102,.064)*ear_scale,skin,9)
		ear.name="SubtleModeledEar"
		var x: float=sign*eye_gap
		var depth: float=_depth(x,eye_height,g)-.011
		var socket:=Node3D.new()
		socket.name="ExpressionEyeLeft" if sign<0.0 else "ExpressionEyeRight"
		socket.position=Vector3(x,eye_height,depth)
		root.add_child(socket)
		# A real layered eye: recessed sclera, genetically colored iris,
		# pupil and upper/lower eyelids instead of a black flat square.
		var eye_aperture: float=lerpf(.73,1.26,_v(g,"eye_aperture"))
		var sclera:=ART.orb(socket,Vector3(0,0,-.004),
			Vector3(eye_width*1.64,.036*eye_aperture,.020),
			ART.mat(Color("d5cab7"),.89),12)
		sclera.name="SmallRecessedEye"
		var iris:=ART.orb(socket,Vector3(0,0,-.015),
			Vector3(.022,.023*eye_aperture,.009),iris_ink,12)
		iris.name="InheritedIris"
		var pupil:=ART.orb(socket,Vector3(0,0,-.021),
			Vector3(.011,.015*eye_aperture,.005),eye_ink,10)
		pupil.name="AnatomicalPupil"
		var lid:=ART.bone(socket,Vector3(-eye_width*.83,.015*eye_aperture,-.010),
			Vector3(eye_width*.83,.015*eye_aperture,-.010),.009,.008,skin,9)
		lid.name="IndividualUpperEyelid"
		var lower_lid:=ART.bone(socket,Vector3(-eye_width*.75,-.015*eye_aperture,-.007),
			Vector3(eye_width*.75,-.015*eye_aperture,-.007),.006,.006,skin,9)
		lower_lid.name="AnatomicalLowerEyelid"
		# Blink with actual moving eyelid volumes. The sclera, iris and pupil
		# stay at their anatomical sizes; compressing the entire eye made
		# villagers look like rubber-faced dolls during conversations.
		var upper_cover:=ART.orb(socket,
			Vector3(0,.028*eye_aperture,-.026),
			Vector3(eye_width*1.92,.021*eye_aperture,.015),skin,12)
		upper_cover.name="ExpressionUpperBlinkCover"
		upper_cover.set_meta("rest_y",upper_cover.position.y)
		var lower_cover:=ART.orb(socket,
			Vector3(0,-.027*eye_aperture,-.026),
			Vector3(eye_width*1.88,.019*eye_aperture,.015),skin,12)
		lower_cover.name="ExpressionLowerBlinkCover"
		lower_cover.set_meta("rest_y",lower_cover.position.y)
		var brow_rig:=Node3D.new()
		brow_rig.name="ExpressionBrowLeft" if sign<0.0 else "ExpressionBrowRight"
		brow_rig.position=Vector3(x,eye_height+.044,_depth(x,eye_height+.044,g)-.012)
		root.add_child(brow_rig)
		var brow_mesh:=ART.bone(brow_rig,Vector3(-eye_width*.82,0,0),
			Vector3(eye_width*.82,sign*tilt*.034,0),
			.008,.010,brow,8)
		brow_mesh.name="InheritedBrow"
		brow_rig.set_meta("rest_y",brow_rig.position.y)
		brow_rig.set_meta("rest_tilt",sign*tilt*.11)
	# These nose pieces attach directly to the genetically sculpted face.
	# A bridge/tip/nostril pair gives a distinct profile without a giant
	# cartoon bulb or unsupported free-floating cylinder.
	var nose_y: float=lerpf(1.704,1.732,_v(g,"nose_bridge"))
	var nose_width: float=lerpf(.027,.058,_v(g,"nose_width"))
	var nostril_width: float=lerpf(.64,1.28,_v(g,"nostril_width"))
	var nose_front: float=_depth(0,nose_y,g)
	var tip:=ART.orb(root,Vector3(0,nose_y-.012,nose_front-.007),
		Vector3(nose_width*.84,.036,.023),skin,10)
	tip.name="ModeledNoseTip"
	var nostril_skin:=ART.mat(GENES.skin_color(g).darkened(.39),.99)
	for side in [-1.0,1.0]:
		var wing_x: float=side*nose_width*.72
		var wing_y: float=nose_y-.035
		var wing_front: float=_depth(wing_x,wing_y,g)
		var alar:=ART.orb(root,Vector3(wing_x,wing_y,wing_front-.004),
			Vector3(nose_width*.48,.024,.017),skin,9)
		alar.name="ModeledNoseWing"
		var nostril:=ART.orb(root,
			Vector3(side*nose_width*.68*nostril_width,wing_y-.013,wing_front-.009),
			Vector3(.008*nostril_width,.005,.004),nostril_skin,8)
		nostril.name="InheritedNostril"
	# Faceted cheekbone highlights follow the integrated mesh surface.
	# The underlying skull is continuous, not an attached cheek sphere.
	var cheek_tone:=ART.mat(GENES.skin_color(g).lightened(.038),.99)
	for side in [-1.0,1.0]:
		var ridge_x: float=side*lerpf(.113,.133,_v(g,"cheek_fullness"))
		var ridge_y: float=lerpf(1.727,1.773,_v(g,"cheek_height"))
		var plane:=SurfaceTool.new()
		plane.begin(Mesh.PRIMITIVE_TRIANGLES)
		for offset in [Vector2(-.028,-.018),Vector2(.013,.016),
				Vector2(.039,-.010)]:
			var px: float=ridge_x+offset.x*side
			var py: float=ridge_y+offset.y
			plane.set_uv(Vector2(px*2.0,py*2.0))
			plane.add_vertex(Vector3(px,py,_depth(px,py,g)-.003))
		var highlight:=MeshInstance3D.new()
		highlight.name="InheritedCheekboneFacet"
		highlight.mesh=plane.commit()
		highlight.material_override=cheek_tone
		root.add_child(highlight)
	var mouth_width: float=lerpf(.028,.069,_v(g,"mouth_width"))
	var lip_height: float=1.65+(_v(g,"face_length")-.5)*.017
	var mouth:=Node3D.new()
	mouth.name="ExpressionMouth"
	mouth.position=Vector3(0,lip_height,_depth(0,lip_height,g)-.019)
	root.add_child(mouth)
	# Two independently articulated lip corners make smiles, frowns,
	# exhaustion and uncertainty readable on even a blocky face.
	var left_corner:=Node3D.new()
	left_corner.name="ExpressionLipLeft"
	mouth.add_child(left_corner)
	var lower_rig:=Node3D.new()
	lower_rig.name="ExpressionLowerLip"
	mouth.add_child(lower_rig)
	var fullness: float=lerpf(.006,.021,_v(g,"lip_fullness"))
	# Lip curve is independent of inherited width and fullness. High
	# alleles lift the neutral mouth corners and Cupid's bow; low alleles
	# produce a flatter, downturned mouth. Expressions animate these
	# inherited shapes rather than replacing them with generic lips.
	var cupid_rise: float=lerpf(.003,.013,_v(g,"lip_curve"))
	var corner_rise: float=lerpf(-.009,.007,_v(g,"lip_curve"))
	mouth.set_meta("rest_cupid_rise",cupid_rise)
	mouth.set_meta("rest_corner_rise",corner_rise)
	# Upper and lower lip bands occupy separate volumes and articulate
	# from their own corners. Very thin lips remain truly thin.
	var left_lip:=ART.bone(left_corner,
		Vector3(-mouth_width,corner_rise,0),Vector3(0,cupid_rise,0),
		fullness,fullness*.75,lip_ink,9)
	left_lip.name="SmallNaturalLipLine"
	var left_lower:=ART.bone(lower_rig,
		Vector3(-mouth_width,corner_rise-.007,0),Vector3(0,-.010,0),
		fullness*.67,fullness*.85,lip_ink,9)
	left_lower.name="ModeledLowerLipLeft"
	var right_corner:=Node3D.new()
	right_corner.name="ExpressionLipRight"
	mouth.add_child(right_corner)
	var right_lip:=ART.bone(right_corner,
		Vector3(0,cupid_rise,0),Vector3(mouth_width,corner_rise,0),
		fullness*.75,fullness,lip_ink,9)
	right_lip.name="NaturalLipCorner"
	var right_lower:=ART.bone(lower_rig,
		Vector3(0,-.010,0),Vector3(mouth_width,corner_rise-.007,0),
		fullness*.85,fullness*.67,lip_ink,9)
	right_lower.name="ModeledLowerLipRight"
	var open_mouth:=ART.orb(mouth,Vector3(0,-.005,-.002),
		Vector3(mouth_width*1.7,.007,.009),ART.mat(Color("301c1c"),1),8)
	open_mouth.name="ExpressionMouthOpening"
	# Close-fitting hair, inherited volume and curl. Not a wig made of
	# giant floating spheres. Color is inherited separately from shape.
	var volume: float=_v(g,"hair_volume")
	var scalp:=ART.orb(root,Vector3(0,1.964,.029),
		Vector3(lerpf(.406,.462,volume),lerpf(.105,.205,volume),
			lerpf(.366,.423,volume)),hair,12)
	scalp.name="NaturalHairline"
	# Keep genetic hair in the genome, but tuck it beneath a working
	# bonnet or straw hat instead of letting black curls poke through.
	if person in ["ida","daro"]:
		scalp.visible=false
	var curl: float=_v(g,"hair_curl")
	if curl>.46 and person not in ["ida","daro"]:
		# Hair texture comes from small overlapping facets embedded inside
		# the crown. Large vertical egg-shaped spheres looked like horns.
		var count: int=4+int(floor(curl*3.0))
		for i in range(count):
			var lateral: float=float(i)-float(count-1)*.5
			var cx: float=lateral*(.31/float(maxi(1,count-1)))
			var irregular: float=sin(float(i)*2.4+volume*8.0)
			var crown: float=-.010+volume*.017+irregular*.006
			var curl_piece:=ART.orb(root,
				Vector3(cx,1.973+crown,-.114),
				Vector3(.042+volume*.009,.027+curl*.020,.044),hair,8)
			curl_piece.name="GeneticCurlCluster"
	elif curl<.31 and person not in ["ida","daro"]:
		var part:=ART.bone(root,Vector3(-.15,1.975,-.14),
			Vector3(.11,2.011,-.14),.014,.014,brow,8)
		part.name="InheritedHairPart"
	if _v(g,"freckles")>.68:
		for i in range(4):
			var side: float=-1.0 if i<2 else 1.0
			var px: float=side*(.09+.030*float(i%2))
			var py: float=1.722+float(i%2)*.016
			var dot:=ART.orb(root,Vector3(px,py,_depth(px,py,g)-.009),
				Vector3(.012,.011,.005),brow,7)
			dot.name="InheritedFreckle"
	root.set_meta("expression_blink",0.0)

static func expression(figure: Node3D,feel: float,blink: float=0.0,
		speaking: bool=false,conversation_phase: float=0.0) -> void:
	var root: Node3D=figure.get_node_or_null("IndividualFaceConstruction")
	if root==null: return
	var emotion: float=clampf(feel,-1.0,1.0)
	var eyelid_drop: float=clampf(blink,0.0,1.0)
	var tension: float=maxf(0.0,-emotion)
	for part in ["ExpressionEyeLeft","ExpressionEyeRight"]:
		var eye: Node3D=root.get_node_or_null(part)
		if eye!=null:
			# Sclera and inherited iris keep their real dimensions even
			# when someone blinks or narrows their eyes in distrust.
			eye.scale.y=lerpf(eye.scale.y,1.0,.29)
			var closure: float=clampf(eyelid_drop+tension*.19,0.0,1.0)
			for lid_name in ["ExpressionUpperBlinkCover","ExpressionLowerBlinkCover"]:
				var lid: Node3D=eye.get_node_or_null(lid_name)
				if lid==null: continue
				var rest: float=float(lid.get_meta("rest_y",lid.position.y))
				var sealed: float=.002 if lid_name=="ExpressionUpperBlinkCover" else -.002
				lid.position.y=lerpf(lid.position.y,lerpf(rest,sealed,closure),.37)
	for part in ["ExpressionBrowLeft","ExpressionBrowRight"]:
		var brow: Node3D=root.get_node_or_null(part)
		if brow!=null:
			# Preserve the actual inherited eyebrow height: older animation
			# reset every person's brow to the same Y after one frame.
			var rest: float=float(brow.get_meta("rest_y",brow.position.y))
			var inherited_tilt: float=float(brow.get_meta("rest_tilt",0.0))
			var side: float=-1.0 if part.ends_with("Left") else 1.0
			brow.position.y=lerpf(brow.position.y,
				rest+emotion*.016+(side*.005 if speaking else 0.0),.20)
			brow.rotation.z=lerpf(brow.rotation.z,
				inherited_tilt+side*emotion*.20,.20)
	var mouth: Node3D=root.get_node_or_null("ExpressionMouth")
	if mouth!=null:
		mouth.scale.x=lerpf(mouth.scale.x,1.0+maxf(0.0,emotion)*.18,.18)
		mouth.scale.y=lerpf(mouth.scale.y,1.0+absf(emotion)*.31,.18)
		var left: Node3D=mouth.get_node_or_null("ExpressionLipLeft") as Node3D
		var right: Node3D=mouth.get_node_or_null("ExpressionLipRight") as Node3D
		if left!=null: left.rotation.z=lerpf(left.rotation.z,-emotion*.45,.25)
		if right!=null: right.rotation.z=lerpf(right.rotation.z,emotion*.45,.25)
		var opening_mesh: MeshInstance3D=mouth.get_node_or_null("ExpressionMouthOpening") as MeshInstance3D
		if opening_mesh!=null:
			var syllable: float=absf(sin(conversation_phase*7.5))
			var talking: bool=speaking and syllable>.38
			opening_mesh.visible=talking or emotion<-.64
			opening_mesh.scale.y=lerpf(.7,2.5,syllable) if talking else .6+absf(emotion)*2.0
			# Only the lower lip moves with a spoken syllable. The mouth
			# aperture follows it; the face, teeth and nose remain still.
			var lower: Node3D=mouth.get_node_or_null("ExpressionLowerLip")
			if lower!=null:
				var lowered: float=(-.024*syllable if talking else
					-.006*maxf(0.0,-emotion))
				lower.position.y=lerpf(lower.position.y,lowered,.32)
	root.set_meta("expression_blink",eyelid_drop)
	root.set_meta("expression_speaking",speaking)
