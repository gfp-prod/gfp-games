extends RefCounted
## Faceted, genetically individualized faces. One consistent art style;
## dozens of independent inherited proportions rather than three presets.
## Face/eyes/brows/mouth are separate visual controls for expression.
const ART=preload("res://scripts/art.gd")
const GENES=preload("res://scripts/npc_genetics.gd")
const HAIR=preload("res://scripts/folk_hair_finish.gd")

static func _v(g: Dictionary,key: String) -> float:
	return GENES.value(g,key)

static func _depth(x: float,y: float,g: Dictionary,
		sex: String="unspecified") -> float:
	var width: float=.197+_v(g,"face_width")*.037
	var length: float=.215+_v(g,"face_length")*.061
	var nx: float=x/width
	var ny: float=(y-1.77)/length
	# Narrower chin versus broader lower jaw is inherited independently
	# of cheekbones. All vertices remain part of a single coherent surface.
	var jaw_gene: float=_v(g,"jaw_width")
	var jaw: float=lerpf(.76,1.26,jaw_gene)
	# Jaw shape has overlapping population averages. The inherited jaw
	# allele can still make a broad-jawed woman or fine-boned man.
	var jaw_factor: float=lerpf(.815,1.035,jaw_gene) if sex=="female" else (
		lerpf(.985,1.125,jaw_gene) if sex=="male" else 1.0)
	jaw*=jaw_factor
	var cheek: float=lerpf(.83,1.21,_v(g,"cheek_fullness"))
	# Independent inherited jaw angle determines squareness at the chin.
	var angle: float=lerpf(-.028,.038,_v(g,"jaw_angle"))
	var profile: float=lerpf(jaw,cheek,smoothstep(1.66+angle,1.79+angle,y))
	nx/=profile
	var shell: float=-.193*sqrt(maxf(.013,1.0-nx*nx-ny*ny))
	var bridge_width: float=lerpf(.026,.065,_v(g,"nose_width"))
	var bridge_height: float=lerpf(1.715,1.746,_v(g,"nose_bridge"))
	var nose_projection: float=lerpf(.034,.118,_v(g,"nose_projection"))
	nose_projection*=(.94 if sex=="female" else 1.07 if sex=="male" else 1.0)
	var nose: float=-nose_projection*exp(
		-pow(x/bridge_width,2.0)-pow((y-bridge_height)/.070,2.0))
	var cheek_height: float=lerpf(1.703,1.756,_v(g,"cheek_height"))
	var cheek_softness: float=1.16 if sex=="female" else .93 if sex=="male" else 1.0
	var cheeks: float=-lerpf(.004,.031,_v(g,"cheek_fullness"))*cheek_softness*exp(
		-pow((absf(x)-.115)/.058,2.0)-pow((y-cheek_height)/.054,2.0))
	var eye_level: float=lerpf(1.779,1.804,_v(g,"brow_height"))
	var socket: float=.008*exp(-pow(
		(absf(x)-lerpf(.074,.105,_v(g,"eye_spacing")))/.037,2.0)
		-pow((y-eye_level)/.025,2.0))
	var lips: float=-lerpf(.005,.024,_v(g,"lip_fullness"))*exp(
		-pow(x/.076,2.0)-pow((y-1.666)/.019,2.0))
	# Modest supraorbital projection changes the real brow bone, rather
	# than only thickening an eyebrow strip or changing eye makeup.
	var brow_ridge: float=-.010*exp(
		-pow((absf(x)-.075)/.071,2.0)-pow((y-1.824)/.036,2.0))
	var ridge_factor: float=.36 if sex=="female" else 1.25 if sex=="male" else 1.0
	brow_ridge*=ridge_factor
	return shell+nose+cheeks+socket+lips+brow_ridge-.003

## Width of the lower facial outline: the old portrait was a rectangular
## front patch with jaw only affecting surface DEPTH, so the visible cheeks
## and chin never actually narrowed.
static func _jaw_outline(y: float,g: Dictionary,sex: String) -> float:
	var jaw_gene: float=_v(g,"jaw_width")
	var lower: float=1.0-smoothstep(1.66,1.83,y)
	var taper: float=lerpf(.72,1.01,jaw_gene) if sex=="female" else (
		lerpf(.83,1.09,jaw_gene) if sex=="male" else
		lerpf(.82,1.06,jaw_gene))
	return lerpf(1.0,taper,lower)

static func _integrated_face(root: Node3D,skin: Material,g: Dictionary,
		sex: String="unspecified") -> void:
	# 14*16*6 = 1344 vertices per head. This is a small mesh per
	# genome, generated only once when a character is instantiated.
	var st:=SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var fw: float=lerpf(.90,1.10,_v(g,"face_width")) * (
		.950 if sex=="female" else 1.025 if sex=="male" else 1.0)
	var fy: float=lerpf(.90,1.11,_v(g,"face_length")) * (
		.985 if sex=="female" else 1.035 if sex=="male" else 1.0)
	for yi in range(16):
		for xi in range(14):
			var x0: float=lerpf(-.183,.183,float(xi)/14.0)*fw
			var x1: float=lerpf(-.183,.183,float(xi+1)/14.0)*fw
			var y0: float=1.77+(lerpf(1.575,1.931,float(yi)/16.0)-1.77)*fy
			var y1: float=1.77+(lerpf(1.575,1.931,float(yi+1)/16.0)-1.77)*fy
			var x0low: float=x0*_jaw_outline(y0,g,sex)
			var x0high: float=x0*_jaw_outline(y1,g,sex)
			var x1low: float=x1*_jaw_outline(y0,g,sex)
			var x1high: float=x1*_jaw_outline(y1,g,sex)
			var pts: Array[Vector3]=[
				Vector3(x0low,y0,_depth(x0low,y0,g,sex)),
				Vector3(x0high,y1,_depth(x0high,y1,g,sex)),
				Vector3(x1low,y0,_depth(x1low,y0,g,sex)),
				Vector3(x1high,y1,_depth(x1high,y1,g,sex))]
			for j in [0,1,2,1,3,2]:
				var point: Vector3=pts[j]
				st.set_uv(Vector2((point.x+.20)*2.5,(point.y-1.54)*2.5))
				st.add_vertex(point)
	st.generate_normals()
	var face:=MeshInstance3D.new()
	face.name="IndividualIntegratedFaceMesh"
	face.mesh=st.commit()
	face.material_override=skin
	face.set_meta("true_inherited_lower_jaw_silhouette",true)
	root.add_child(face)

static func _anatomical_neck(root: Node3D,skin: Material,g: Dictionary,
		sex: String="unspecified") -> void:
	# Continuous skin-colored bridge below the genetically sculpted jaw.
	# Removing a tall fabric collar without this geometry left heads floating
	# over their shoulders in the real 1280x720 village captures.
	# A six-ring silhouette avoids the replacement artifact of a rigid neck pipe.
	var jaw_width: float=lerpf(.88,1.13,_v(g,"jaw_width"))
	jaw_width*=(.93 if sex=="female" else 1.055 if sex=="male" else 1.0)
	var depth_scale: float=lerpf(.90,1.11,_v(g,"body_depth"))
	# The clavicle bridge must NOT be a straight pipe above the shirt.
	# It is buried at its base beneath the garment, narrows beneath
	# the throat, then opens naturally into the individual jaw.
	var heights: Array[float]=[1.445,1.485,1.525,1.565,1.605,1.655]
	var half_widths: Array[float]=[.164,.154,.142,.136,.151,.177]
	var half_depths: Array[float]=[.155,.145,.133,.128,.142,.154]
	var surface:=SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_material(skin)
	for row in range(heights.size()-1):
		for segment in range(16):
			var a: float=TAU*float(segment)/16.0
			var b: float=TAU*float(segment+1)/16.0
			var corners: Array[Vector3]=[]
			for tuple in [[row,a],[row+1,a],[row+1,b],[row,b]]:
				var idx: int=int(tuple[0])
				var t: float=float(idx)/float(heights.size()-1)
				var angle: float=float(tuple[1])
				var radius_x: float=half_widths[idx]*jaw_width
				var radius_z: float=half_depths[idx]*depth_scale
				var midline: float=lerpf(-.012,.030,smoothstep(.10,1.0,t))
				corners.append(Vector3(cos(angle)*radius_x,
					heights[idx],sin(angle)*radius_z+midline))
			for index in [0,1,2,0,2,3]:
				var v: Vector3=corners[index]
				surface.set_uv(Vector2(float(segment)/16.0,v.y))
				surface.add_vertex(v)
	surface.generate_normals()
	var neck:=MeshInstance3D.new()
	neck.name="IndividualAnatomicalNeck"
	neck.mesh=surface.commit()
	neck.material_override=skin
	neck.set_meta("inherited_neck_bridge",true)
	neck.set_meta("no_new_collision",true)
	root.add_child(neck)

## Faceted hair shapes use real contour geometry. They are groomed
## choices whose length, curl, thickness and pattern are inherited.
## Do not build hair from giant unsupported eggs stuck to the skull.
static func _hair_lock(root: Node3D,name: String,hair: Material,
		x: float,z: float,end_y: float,volume: float,curl: float,
		back: bool=false) -> MeshInstance3D:
	var st:=SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_material(hair)
	const STEPS: int=10
	const SIDES: int=9
	for i in range(STEPS-1):
		for k in range(SIDES):
			var corners: Array[Vector3]=[]
			for pair in [[i,k],[i+1,k],[i+1,k+1],[i,k+1]]:
				var row: int=int(pair[0])
				var a: float=TAU*float(pair[1])/float(SIDES)
				var t: float=float(row)/float(STEPS-1)
				var radius: float=(.036+.023*volume)*lerpf(1.10,.38,
					smoothstep(.55,1.0,t))
				var sway: float=sin(t*TAU*(.70+curl*.65))*.026*curl
				var root_y: float=1.945
				var yy: float=lerpf(root_y,end_y,t)
				# Move the strand around the real ribcage, rather than
				# burying all long hair inside the tunic's front/back.
				var xx: float=x+sway+signf(x)*.092*smoothstep(.14,.76,t)
				var zz: float=lerpf(z-.050,
					.345 if back else -.325,smoothstep(.16,.83,t))
				corners.append(Vector3(xx+cos(a)*radius,yy,
					zz+sin(a)*radius*.85))
			for index in [0,1,2,0,2,3]:
				var v: Vector3=corners[index]
				st.set_uv(Vector2(float(k)/float(SIDES),v.y*1.3))
				st.add_vertex(v)
	st.generate_normals()
	var strand:=MeshInstance3D.new()
	strand.name=name
	strand.mesh=st.commit()
	strand.material_override=hair
	strand.set_meta("inherited_hair_length",end_y)
	strand.set_meta("no_new_collision",true)
	root.add_child(strand)
	return strand

## A single layered curtain of back hair: large soft planes rather than
## separate noodle-like cylinders. Wind-torn hem creates a dark-fantasy
## painterly silhouette while keeping the face and ears visible.
static func _long_hair_curtain(root: Node3D,hair: Material,
		end_y: float,volume: float,curl: float) -> MeshInstance3D:
	var st:=SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_material(hair)
	const ROWS: int=11
	const COLS: int=15
	for row in range(ROWS-1):
		for col in range(COLS-1):
			var corners: Array[Vector3]=[]
			for tuple in [[row,col],[row+1,col],[row+1,col+1],[row,col+1]]:
				var t: float=float(tuple[0])/float(ROWS-1)
				var a: float=PI*float(tuple[1])/float(COLS-1)
				var width: float=lerpf(.177,.268+.026*volume,
					smoothstep(.1,.9,t))
				var x: float=cos(a)*width
				var z: float=lerpf(.088,.322,t)+sin(a)*.048
				var flicker: float=.013*sin(a*5.5+t*4.4)*curl*t
				var y: float=lerpf(1.948,end_y,t)+(
					.016*sin(a*6.0)*pow(t,1.5))
				corners.append(Vector3(x+flicker,y,z))
			for k in [0,1,2,0,2,3]:
				var p: Vector3=corners[k]
				st.set_uv(Vector2((p.x+.28)*1.8,p.y*1.6))
				st.add_vertex(p)
	st.generate_normals()
	var curtain:=MeshInstance3D.new()
	curtain.name="HereditaryLongHairCurtain"
	curtain.mesh=st.commit()
	if hair is StandardMaterial3D:
		(hair as StandardMaterial3D).cull_mode=BaseMaterial3D.CULL_DISABLED
	curtain.material_override=hair
	curtain.set_meta("no_new_collision",true)
	curtain.set_meta("genetically_styled_length",end_y)
	root.add_child(curtain)
	return curtain

static func _layered_hair(root: Node3D,person: String,
		hair: Material,g: Dictionary,sex: String) -> void:
	var shape: Dictionary=GENES.hair_profile(g,sex,person)
	var style: String=String(shape["style"])
	var volume: float=float(shape["volume"])
	var curl: float=float(shape["curl"])
	var length: float=float(shape["length"])
	root.set_meta("inherited_hair_style",style)
	root.set_meta("inherited_hair_length",length)
	if style in ["loose","wave","braids","bun","ponytail"]:
		var end_y: float=lerpf(1.52,1.30,length)
		if person=="sela": end_y=1.39
		if person=="lena": end_y=1.32
		if person=="mara": end_y=1.37
		for side in [-1.0,1.0]:
			var strand_end: float=end_y if style not in ["bun","ponytail"] else 1.72
			if style=="braids":
				strand_end=end_y-.045
			var lock:=_hair_lock(root,
				"HereditaryLeftHairDrape" if side<0.0 else
				"HereditaryRightHairDrape",hair,side*.180,
				-.008 if style=="braids" else .075,
				strand_end,volume,curl,style!="braids")
			if style=="braids":
				# Braids lie in front of the garment; surface geometry
				# already moves them forward as they pass the jaw.
				lock.set_meta("front_of_clothing",true)
				var wrap:=ART.bone(root,
					Vector3(side*.19,end_y+.018,-.158),
					Vector3(side*.19,end_y-.004,-.158),
					.019,.014,ART.mat(Color("927356"),.99),8)
				wrap.name="HairBraidTie"
		if style in ["loose","wave"]:
			_long_hair_curtain(root,hair,end_y-.045,volume,curl)
			for side in [-1.0,1.0]:
				_hair_lock(root,"SecondaryLayeredBackHair",hair,side*.092,
					.180,end_y-.045,volume*.81,curl,true)
		if style=="bun":
			# Low tied knot behind the skull, not a second helmet.
			var knot:=ART.orb(root,Vector3(0,1.80,.225),
				Vector3(.25,.24,.17),hair,11)
			knot.name="TiedLowHairBun"
		if style=="ponytail":
			_hair_lock(root,"TiedBackHereditaryPonytail",hair,0,.218,
				end_y-.10,volume,curl,true)
			var cord:=ART.bone(root,Vector3(-.08,1.846,.205),
				Vector3(.08,1.846,.205),.018,.018,
				ART.mat(Color("574334"),.99),8)
			cord.name="HairPonytailCord"
	elif style in ["shaggy","swept"]:
		for side in [-1.0,1.0]:
			_hair_lock(root,"MasculineSideSweptHair",hair,side*.176,
				.035,1.735,volume*.78,curl)
		var part:=ART.bone(root,Vector3(-.12,1.998,-.110),
			Vector3(.11,2.015,-.106),.013,.013,hair,9)
		part.name="ShortSideSweptParting"
	elif style=="curly_crop":
		for side in [-1.0,1.0]:
			var taper:=ART.orb(root,Vector3(side*.157,1.950,-.035),
				Vector3(.112,.087,.112),hair,9)
			taper.name="CurledTempleFade"
	# The inherited crown still exists. Long hair reads through layered
	# silhouettes and works with hats and bonnets.

## Low-poly facial hair follows the existing facial surface. No floating
## beards, flat front-facing billboards, or extra facial physics. Alleles
## determine growth and distribution; adult grooming alters style.
static func _beard_patch(root: Node3D,name: String,mat: Material,
		g: Dictionary,sex: String,left: float,right: float,
		top: float,bottom: float,weight: float=1.0) -> MeshInstance3D:
	var tool:=SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	tool.set_material(mat)
	const COLS: int=6
	const ROWS: int=5
	for row in range(ROWS-1):
		for col in range(COLS-1):
			var quad: Array[Vector3]=[]
			for point in [[row,col],[row+1,col],[row+1,col+1],[row,col+1]]:
				var v: float=float(point[0])/float(ROWS-1)
				var u: float=float(point[1])/float(COLS-1)
				# A scalloped lower edge follows the jaw and cheek planes.
				var x: float=lerpf(left,right,u)*lerpf(1.0,.78,v)
				var tip: float=.007*sin(float(col)*2.6)
				var y: float=lerpf(top,bottom+tip,v)
				var z: float=_depth(x,y,g,sex)-.007-.011*weight*v
				quad.append(Vector3(x,y,z))
			for i in [0,1,2,0,2,3]:
				var p: Vector3=quad[i]
				tool.set_uv(Vector2(p.x*3.0,p.y*2.0))
				tool.add_vertex(p)
	tool.generate_normals()
	var part:=MeshInstance3D.new()
	part.name=name
	part.mesh=tool.commit()
	part.material_override=mat
	part.set_meta("no_new_collision",true)
	part.set_meta("inherited_facial_hair",true)
	root.add_child(part)
	return part

static func _facial_hair(root: Node3D,g: Dictionary,sex: String,
		age_years: float=30.0) -> void:
	var expression: Dictionary=GENES.beard_profile(g,sex,age_years)
	var style: String=String(expression["style"])
	root.set_meta("facial_hair_style",style)
	root.set_meta("heritable_beard_style",style)
	root.set_meta("facial_hair_density",float(expression["density"]))
	root.set_meta("heritable_beard_density",float(expression["density"]))
	if style=="clean": return
	var density: float=float(expression["density"])
	var length: float=float(expression["length"])
	var dark:=ART.mat(GENES.hair_color(g).darkened(.12),.99)
	dark.cull_mode=BaseMaterial3D.CULL_DISABLED
	var stubble:=ART.mat(GENES.hair_color(g).lerp(
		GENES.skin_color(g),.28),.98)
	stubble.cull_mode=BaseMaterial3D.CULL_DISABLED
	var facial_mat: Material=stubble if style=="stubble" else dark
	var weight: float=lerpf(.65,1.35,length)
	if style in ["short","full","stubble","sideburns"]:
		for side in [-1.0,1.0]:
			var edge: float=side*.135
			var near: float=side*.066
			_beard_patch(root,"GeneticFacialHairCheek"+str(side),
				facial_mat,g,sex,minf(edge,near),maxf(edge,near),
				1.730,1.628 if style=="full" else 1.665,weight)
	if style in ["short","full","goatee","stubble"]:
		var chin_bottom: float=1.575 if style=="full" else (
			1.610 if style=="short" else 1.628)
		_beard_patch(root,"GeneticFacialHairChin",facial_mat,g,sex,
			-.096,.096,1.660,chin_bottom,weight)
	if style in ["moustache","short","full","goatee","stubble"]:
		var mustache_width: float=lerpf(.050,.095,
			float(expression["mustache"]))
		for side in [-1.0,1.0]:
			_beard_patch(root,"GeneticMoustache"+str(side),facial_mat,
				g,sex,minf(0.0,side*mustache_width),
				maxf(0.0,side*mustache_width),
				1.693,1.680,weight*.65)
	root.set_meta("beard_geometry_from_genes",true)

static func finish(figure: Node3D,person: String,skin: Material,
		hair: Material,brow: Material,genome: Dictionary={},
		sex: String="unspecified",age_years: float=28.0) -> void:
	if figure.get_node_or_null("IndividualFaceConstruction")!=null:
		return
	var g: Dictionary=genome if GENES.validate(genome) else GENES.founder(person)
	var root:=Node3D.new()
	root.name="IndividualFaceConstruction"
	root.set_meta("professionally_distinct_face",person)
	root.set_meta("no_new_collision",true)
	root.set_meta("facial_variation",int(round(_v(g,"face_width")*100)))
	root.set_meta("genetic_face",true)
	root.set_meta("anatomic_sex_profile",sex)
	figure.add_child(root)
	_integrated_face(root,skin,g,sex)
	_anatomical_neck(root,skin,g,sex)
	var eye_ink:=ART.mat(Color("201c1a"),1.0)
	var iris_ink:=ART.mat(GENES.eye_color(g),.98)
	var lip_ink:=ART.mat(GENES.skin_color(g).darkened(
		lerpf(.31,.18,_v(g,"lip_fullness"))),.99)
	var ear_scale: float=lerpf(.70,1.33,_v(g,"ear_size"))
	var eye_gap: float=lerpf(.068,.113,_v(g,"eye_spacing"))
	var eye_height: float=lerpf(1.780,1.802,_v(g,"brow_height"))
	var eye_width: float=lerpf(.033,.055,_v(g,"eye_shape")) * (
		1.055 if sex=="female" else 1.0)
	var tilt: float=lerpf(-.22,.22,_v(g,"brow_angle"))
	for sign in [-1.0,1.0]:
		var ear:=ART.orb(root,Vector3(sign*.205,1.762,.010),
			Vector3(.065,.102,.064)*ear_scale,skin,9)
		ear.name="SubtleModeledEar"
		var x: float=sign*eye_gap
		var depth: float=_depth(x,eye_height,g,sex)-.011
		var socket:=Node3D.new()
		socket.name="ExpressionEyeLeft" if sign<0.0 else "ExpressionEyeRight"
		socket.position=Vector3(x,eye_height,depth)
		root.add_child(socket)
		# A real layered eye: recessed sclera, genetically colored iris,
		# pupil and upper/lower eyelids instead of a black flat square.
		var eye_aperture: float=lerpf(.73,1.26,_v(g,"eye_aperture"))
		var sclera:=ART.orb(socket,Vector3(0,0,-.004),
			Vector3(eye_width*1.55,.031*eye_aperture,.017),
			ART.mat(Color("d5cab7"),.89),12)
		sclera.name="SmallRecessedEye"
		var iris:=ART.orb(socket,Vector3(0,0,-.015),
			Vector3(.021,.021*eye_aperture,.008),iris_ink,12)
		iris.name="InheritedIris"
		var pupil:=ART.orb(socket,Vector3(0,0,-.021),
			Vector3(.010,.014*eye_aperture,.005),eye_ink,10)
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
		brow_rig.position=Vector3(x,eye_height+.044,_depth(x,eye_height+.044,g,sex)-.012)
		root.add_child(brow_rig)
		var feminine_brow: bool=sex=="female"
		var brow_mesh:=ART.bone(brow_rig,
			Vector3(-eye_width*.82,0,0),
			Vector3(eye_width*.82,sign*tilt*.034+(
				.006 if feminine_brow else 0.0),0),
			.006 if feminine_brow else .008,
			.007 if feminine_brow else .009,brow,8)
		brow_mesh.name="InheritedBrow"
		brow_rig.set_meta("rest_y",brow_rig.position.y)
		brow_rig.set_meta("rest_tilt",sign*tilt*.11)
	# These nose pieces attach directly to the genetically sculpted face.
	# A bridge/tip/nostril pair gives a distinct profile without a giant
	# cartoon bulb or unsupported free-floating cylinder.
	var nose_y: float=lerpf(1.704,1.732,_v(g,"nose_bridge"))
	var nose_width: float=lerpf(.027,.058,_v(g,"nose_width"))
	var nostril_width: float=lerpf(.64,1.28,_v(g,"nostril_width"))
	var nose_front: float=_depth(0,nose_y,g,sex)
	var tip:=ART.orb(root,Vector3(0,nose_y-.012,nose_front-.007),
		Vector3(nose_width*.68,.029,.017),skin,10)
	tip.name="ModeledNoseTip"
	var nostril_skin:=ART.mat(GENES.skin_color(g).darkened(.39),.99)
	for side in [-1.0,1.0]:
		var wing_x: float=side*nose_width*.72
		var wing_y: float=nose_y-.035
		var wing_front: float=_depth(wing_x,wing_y,g,sex)
		var alar:=ART.orb(root,Vector3(wing_x,wing_y,wing_front-.004),
			Vector3(nose_width*.38,.018,.012),skin,9)
		alar.name="ModeledNoseWing"
		var nostril:=ART.orb(root,
			Vector3(side*nose_width*.68*nostril_width,wing_y-.013,wing_front-.009),
			Vector3(.006*nostril_width,.004,.003),nostril_skin,8)
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
			plane.add_vertex(Vector3(px,py,_depth(px,py,g,sex)-.003))
		var highlight:=MeshInstance3D.new()
		highlight.name="InheritedCheekboneFacet"
		highlight.mesh=plane.commit()
		highlight.material_override=cheek_tone
		root.add_child(highlight)
	var mouth_width: float=lerpf(.028,.069,_v(g,"mouth_width"))
	var lip_height: float=1.65+(_v(g,"face_length")-.5)*.017
	var mouth:=Node3D.new()
	mouth.name="ExpressionMouth"
	mouth.position=Vector3(0,lip_height,_depth(0,lip_height,g,sex)-.019)
	root.add_child(mouth)
	# Two independently articulated lip corners make smiles, frowns,
	# exhaustion and uncertainty readable on even a blocky face.
	var left_corner:=Node3D.new()
	left_corner.name="ExpressionLipLeft"
	mouth.add_child(left_corner)
	var lower_rig:=Node3D.new()
	lower_rig.name="ExpressionLowerLip"
	mouth.add_child(lower_rig)
	var fullness: float=lerpf(.005,.016,_v(g,"lip_fullness"))
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
	var scalp:=ART.orb(root,Vector3(0,1.959,.036),
		Vector3(lerpf(.355,.420,volume),lerpf(.083,.155,volume),
			lerpf(.330,.381,volume)),hair,13)
	scalp.name="NaturalHairline"
	# Keep genetic hair in the genome, but tuck it beneath a working
	# bonnet or straw hat instead of letting black curls poke through.
	if person in ["ida","daro"]:
		scalp.visible=false
	# The old tiny scalp spheres looked like horns in close-up shots.
	# The groomed mesh now owns curls, fringe and parting instead.
	# Named villagers have recognisable grooming; descendants express
	# inherited follicle properties without being forced into a profession.
	HAIR.finish(root,person,g,sex,hair)
	_facial_hair(root,g,sex,age_years)
	if _v(g,"freckles")>.68:
		for i in range(4):
			var side: float=-1.0 if i<2 else 1.0
			var px: float=side*(.09+.030*float(i%2))
			var py: float=1.722+float(i%2)*.016
			var dot:=ART.orb(root,Vector3(px,py,_depth(px,py,g,sex)-.009),
				Vector3(.012,.011,.005),brow,7)
			dot.name="InheritedFreckle"
	root.set_meta("expression_blink",0.0)

## Figure-drawing landmark calibration for the existing procedural skull.
## One silhouette module governs skull, modeled face, hair and hats without
## rescaling the physics body, the actual genetics, or the detachable limbs.
## The shared throat origin stays seated inside the open inherited collar.
## Adult heads are intentionally stylized (~5.7 skull heights per stature),
## rather than the previous near-4-head mannequin. Young NPCs keep the
## naturally larger head-to-body ratio characteristic of childhood.
static func skull_scale(g: Dictionary,age_years: float) -> Vector3:
	var maturity: float=smoothstep(8.0,19.0,maxf(0.0,age_years))
	var skull_gene: float=GENES.value(g,"face_width")
	var height_gene: float=GENES.value(g,"face_length")
	return Vector3(
		lerpf(.94,.83,maturity)*lerpf(.97,1.035,skull_gene),
		lerpf(.87,.68,maturity)*lerpf(.985,1.025,height_gene),
		lerpf(.93,.85,maturity))


static func fit_skull_landmarks(figure: Node3D,g: Dictionary,
		age_years: float) -> void:
	if bool(figure.get_meta("skull_landmarks_fitted",false)): return
	var face: Node3D=figure.get_node_or_null("IndividualFaceConstruction")
	if face==null: return
	var dimensions: Vector3=skull_scale(g,age_years)
	const THROAT: float=1.49
	# Body/face generators both use absolute pre-growth coordinates.
	# Affine scaling about the THROAT marker keeps mouth, eyes, hair
	# and skin-colored neck mutually registered. An arbitrary scale
	# about the feet would leave a floating jaw.
	face.scale=dimensions
	face.position.y=THROAT*(1.0-dimensions.y)
	face.set_meta("landmark_calibrated_skull",true)
	face.set_meta("anatomical_head_scale",dimensions)
	for node_name in ["ModeledInhabitantHead","ModernGeneticHead",
			"VisibleBakerBonnet","VisibleFarmerHat","VisibleFarmerCrown",
			"FittedAttendantCapCrown","ShortAttendantVisor"]:
		var part: MeshInstance3D=figure.get_node_or_null(
			node_name) as MeshInstance3D
		if part==null: continue
		part.position.y=THROAT+(part.position.y-THROAT)*dimensions.y
		part.scale=part.scale*dimensions
		part.set_meta("skull_landmark_fitted",true)
	figure.set_meta("skull_landmarks_fitted",true)
	figure.set_meta("sculpt_skull_to_stature",true)


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
