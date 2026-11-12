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
	var jaw: float=lerpf(.83,1.18,_v(g,"jaw_width"))
	var cheek: float=lerpf(.91,1.11,_v(g,"cheek_fullness"))
	var profile: float=lerpf(jaw,cheek,smoothstep(1.64,1.79,y))
	nx/=profile
	var shell: float=-.193*sqrt(maxf(.013,1.0-nx*nx-ny*ny))
	var bridge_width: float=lerpf(.030,.057,_v(g,"nose_width"))
	var bridge_height: float=lerpf(1.715,1.746,_v(g,"nose_bridge"))
	var nose: float=-lerpf(.033,.097,_v(g,"nose_projection"))*exp(
		-pow(x/bridge_width,2.0)-pow((y-bridge_height)/.070,2.0))
	var cheek_height: float=lerpf(1.703,1.756,_v(g,"cheek_height"))
	var cheeks: float=-lerpf(.003,.019,_v(g,"cheek_fullness"))*exp(
		-pow((absf(x)-.115)/.058,2.0)-pow((y-cheek_height)/.054,2.0))
	var eye_level: float=lerpf(1.779,1.804,_v(g,"brow_height"))
	var socket: float=.008*exp(-pow(
		(absf(x)-lerpf(.074,.105,_v(g,"eye_spacing")))/.037,2.0)
		-pow((y-eye_level)/.025,2.0))
	var lips: float=-lerpf(.003,.013,_v(g,"lip_fullness"))*exp(
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
	var lip_ink:=ART.mat(Color("513934").lerp(Color("91675c"),_v(g,"pigment")*.5),.99)
	var ear_scale: float=lerpf(.75,1.25,_v(g,"ear_size"))
	var eye_gap: float=lerpf(.071,.111,_v(g,"eye_spacing"))
	var eye_height: float=lerpf(1.780,1.802,_v(g,"brow_height"))
	var eye_width: float=lerpf(.033,.051,_v(g,"eye_shape"))
	var tilt: float=lerpf(-.14,.14,_v(g,"brow_angle"))
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
		var eye:=ART.box(socket,Vector3.ZERO,
			Vector3(eye_width,.018,.010),eye_ink)
		eye.name="SmallRecessedEye"
		var iris:=ART.box(socket,Vector3(0,0,-.006),
			Vector3(.011,.012,.004),iris_ink)
		iris.name="InheritedIris"
		var lid:=ART.bone(socket,Vector3(-eye_width*.64,.012,-.007),
			Vector3(eye_width*.64,.012,-.007),.008,.008,skin,8)
		lid.name="IndividualUpperEyelid"
		var brow_rig:=Node3D.new()
		brow_rig.name="ExpressionBrowLeft" if sign<0.0 else "ExpressionBrowRight"
		brow_rig.position=Vector3(x,eye_height+.044,_depth(x,eye_height+.044,g)-.012)
		root.add_child(brow_rig)
		var brow_mesh:=ART.bone(brow_rig,Vector3(-eye_width*.82,0,0),
			Vector3(eye_width*.82,sign*tilt*.034,0),
			.008,.010,brow,8)
		brow_mesh.name="InheritedBrow"
	var mouth_width: float=lerpf(.024,.063,_v(g,"mouth_width"))
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
	var left_lip:=ART.bone(left_corner,Vector3(-mouth_width,0,0),
		Vector3(0,0,0),.006,.006,lip_ink,8)
	left_lip.name="SmallNaturalLipLine"
	var right_corner:=Node3D.new()
	right_corner.name="ExpressionLipRight"
	mouth.add_child(right_corner)
	var right_lip:=ART.bone(right_corner,Vector3(0,0,0),
		Vector3(mouth_width,0,0),.006,.006,lip_ink,8)
	right_lip.name="NaturalLipCorner"
	var open_mouth:=ART.orb(mouth,Vector3(0,-.005,-.002),
		Vector3(.075,.007,.009),ART.mat(Color("301c1c"),1),8)
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
		for i in range(5):
			var cx: float=(float(i)-2.0)*.080
			var curl_piece:=ART.orb(root,Vector3(cx,2.011+volume*.09,-.121),
				Vector3(.092,.092+curl*.09,.083),hair,9)
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

static func expression(figure: Node3D,feel: float,blink: float=0.0) -> void:
	var root: Node3D=figure.get_node_or_null("IndividualFaceConstruction")
	if root==null: return
	var emotion: float=clampf(feel,-1.0,1.0)
	var eyelid_drop: float=clampf(blink,0.0,1.0)
	for part in ["ExpressionEyeLeft","ExpressionEyeRight"]:
		var eye: Node3D=root.get_node_or_null(part)
		if eye!=null:
			eye.scale.y=lerpf(1.0,.09,eyelid_drop)
	for part in ["ExpressionBrowLeft","ExpressionBrowRight"]:
		var brow: Node3D=root.get_node_or_null(part)
		if brow!=null:
			brow.position.y=lerpf(brow.position.y,
				1.843+emotion*.009,0.18)
			brow.rotation.z=lerpf(brow.rotation.z,
				(-.14 if part.ends_with("Left") else .14)*emotion,0.18)
	var mouth: Node3D=root.get_node_or_null("ExpressionMouth")
	if mouth!=null:
		mouth.scale.x=lerpf(mouth.scale.x,1.0+maxf(0,emotion)*.22,.16)
		mouth.scale.y=lerpf(mouth.scale.y,1.0+absf(emotion)*.48,.16)
		var left: Node3D=mouth.get_node_or_null("ExpressionLipLeft") as Node3D
		var right: Node3D=mouth.get_node_or_null("ExpressionLipRight") as Node3D
		if left!=null: left.rotation.z=lerpf(left.rotation.z,-emotion*.40,.22)
		if right!=null: right.rotation.z=lerpf(right.rotation.z,emotion*.40,.22)
		var opening: MeshInstance3D=mouth.get_node_or_null("ExpressionMouthOpening") as MeshInstance3D
		if opening!=null:
			opening.visible=emotion<-.42
			opening.scale.y=.6+absf(emotion)*2.0
	root.set_meta("expression_blink",eyelid_drop)
