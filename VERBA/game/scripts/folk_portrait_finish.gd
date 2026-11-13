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
	var cheek: float=lerpf(.81,1.25,_v(g,"cheek_fullness"))
	# Independent inherited jaw angle determines squareness at the chin.
	var angle: float=lerpf(-.028,.038,_v(g,"jaw_angle"))
	var profile: float=lerpf(jaw,cheek,smoothstep(1.66+angle,1.79+angle,y))
	nx/=profile
	var shell: float=-.193*sqrt(maxf(.013,1.0-nx*nx-ny*ny))
	var bridge_width: float=lerpf(.029,.070,_v(g,"nose_width"))
	var bridge_height: float=lerpf(1.715,1.746,_v(g,"nose_bridge"))
	# Constrain nasal projection within a face-sized volume. The former
	# maximum of .118 across a .19-deep head made long noses look like
	# spikes extending all the way down the face.
	var nose_projection: float=lerpf(.030,.081,_v(g,"nose_projection"))
	nose_projection*=(.94 if sex=="female" else 1.07 if sex=="male" else 1.0)
	var nose: float=-nose_projection*exp(
		-pow(x/bridge_width,2.0)-pow((y-bridge_height)/.053,2.0))
	var cheek_height: float=lerpf(1.703,1.756,_v(g,"cheek_height"))
	var cheek_softness: float=1.16 if sex=="female" else .93 if sex=="male" else 1.0
	# Cheek fullness is preserved as inherited volume, but the old deep
	# Gaussian relief created two bruised-looking hollows below each eye.
	var cheeks: float=-lerpf(.006,.021,_v(g,"cheek_fullness"))*cheek_softness*exp(
		-pow((absf(x)-.115)/.058,2.0)-pow((y-cheek_height)/.054,2.0))
	var eye_level: float=lerpf(1.779,1.804,_v(g,"brow_height"))
	var socket: float=.0045*exp(-pow(
		(absf(x)-lerpf(.074,.105,_v(g,"eye_spacing")))/.037,2.0)
		-pow((y-eye_level)/.025,2.0))
	var lips: float=-lerpf(.005,.024,_v(g,"lip_fullness"))*exp(
		-pow(x/.076,2.0)-pow((y-1.666)/.019,2.0))
	# Modest supraorbital projection changes the real brow bone, rather
	# than only thickening an eyebrow strip or changing eye makeup.
	var brow_ridge: float=-.0065*exp(
		-pow((absf(x)-.075)/.071,2.0)-pow((y-1.824)/.036,2.0))
	var ridge_factor: float=.36 if sex=="female" else 1.25 if sex=="male" else 1.0
	brow_ridge*=ridge_factor
	return shell+nose+cheeks+socket+lips+brow_ridge-.003

## Use consistent OUTWARD (-Z) normals on the visible front surface.
## These procedural surfaces are intentionally not indexed: sharing
## vertices would invalidate face/eyelid articulation and review topology.
## The old automatic normals followed inconsistent triangle winding and
## turned some exposed mouth and eyelid polygons into dark rear faces.
static func _outward_face_normal(x: float,y: float,g: Dictionary,
		sex: String) -> Vector3:
	const EPS: float=.0035
	var dx: float=(_depth(x+EPS,y,g,sex)-_depth(x-EPS,y,g,sex))/(EPS*2.0)
	var dy: float=(_depth(x,y+EPS,g,sex)-_depth(x,y-EPS,g,sex))/(EPS*2.0)
	# This is a stylized LOW-POLY face, not a displacement-mapped
	# mathematical surface. Sampling the full Gaussian nose/socket
	# gradients turned ordinary skin almost perpendicular to the key
	# light, painting huge black patches into the actual Godot frames.
	# Let the sculpted triangles define profile, but use a gently varied
	# outward lighting normal that never goes grazing across the face.
	var shallow_x: float=clampf(dx*.15,-.22,.22)
	var shallow_y: float=clampf(dy*.15,-.22,.22)
	return Vector3(shallow_x,shallow_y,-1.0).normalized()


## Width of the lower facial outline: the old portrait was a rectangular
## front patch with jaw only affecting surface DEPTH, so the visible cheeks
## and chin never actually narrowed.
static func _jaw_outline(y: float,g: Dictionary,sex: String) -> float:
	var jaw_gene: float=_v(g,"jaw_width")
	var lower: float=1.0-smoothstep(1.66,1.83,y)
	var taper: float=lerpf(.72,1.01,jaw_gene) if sex=="female" else (
		lerpf(.83,1.09,jaw_gene) if sex=="male" else
		lerpf(.82,1.06,jaw_gene))
	# A broad jaw is not a perfectly rectangular chin: even robust
	# inherited mandibles curve inward toward the central chin.
	var chin_rounding: float=lerpf(.73,1.0,smoothstep(1.575,1.675,y))
	return lerpf(1.0,taper,lower)*chin_rounding

# Rather than extruding a rectangular mask over a spherical skull,
# roll the forehead/temple edges into the inherited crown. The face
# remains one contiguous genetic mesh; the forehead is not a pasted card.
static func _forehead_outline(y: float) -> float:
	return lerpf(1.0,.73,smoothstep(1.845,1.945,y))

static func _chin_edge_height(x: float,y: float) -> float:
	# The facial shell used to end as a horizontal shelf. Curve the side
	# boundary toward a central chin rather than a rectangular mask.
	var bottom: float=1.0-smoothstep(1.575,1.69,y)
	return y+.025*pow(clampf(absf(x)/.183,0.0,1.0),2.0)*bottom

## Match the actual calibrated legacy skull rather than letting the
## sculpted front end as a protruding square plaque. ART.orb uses a
## unit-radius .5 SphereMesh, scaled (.42,.49,.39) about (0,1.77,0).
## The whole head and face are scaled together about the throat later.
static func _skull_front_depth(x: float,y: float) -> float:
	var r2: float=pow(x/.21,2.0)+pow((y-1.77)/.245,2.0)
	return -.195*sqrt(maxf(.0,1.0-r2))


static func _seated_face_depth(x: float,y: float,g: Dictionary,
		sex: String,fw: float,fy: float) -> float:
	var skin_z: float=_depth(x,y,g,sex)
	var row_width: float=maxf(.027,.183*fw*
		_jaw_outline(y,g,sex)*_forehead_outline(y))
	var edge_x: float=absf(x)/row_width
	var edge_y: float=(y-1.77)/(.161*fy) if y>=1.77 else (
		(1.77-y)/(.195*fy))
	var rim: float=clampf(maxf(edge_x,edge_y),0.0,1.0)
	# Keep the true inheritable nose, cheeks and chin in the central
	# three-quarters of the sculpt. Only the outer border blends into
	# the old skull. No new collision, no extra rigid head.
	var blend: float=smoothstep(.73,.985,rim)
	return lerpf(skin_z,_skull_front_depth(x,y)-.005,blend)


static func _integrated_face(root: Node3D,skin: Material,g: Dictionary,
		sex: String="unspecified") -> void:
	# A finer continuous facial lattice lets the nose, cheeks and eye sockets
	# share actual surface relief. Generated once for each inherited genome.
	var st:=SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var fw: float=lerpf(.90,1.10,_v(g,"face_width")) * (
		.950 if sex=="female" else 1.025 if sex=="male" else 1.0)
	var fy: float=lerpf(.90,1.11,_v(g,"face_length")) * (
		.985 if sex=="female" else 1.035 if sex=="male" else 1.0)
	const COLS: int=24
	const ROWS: int=28
	for yi in range(ROWS):
		for xi in range(COLS):
			var x0: float=lerpf(-.183,.183,float(xi)/float(COLS))*fw
			var x1: float=lerpf(-.183,.183,float(xi+1)/float(COLS))*fw
			var y0: float=1.77+(lerpf(1.575,1.931,float(yi)/float(ROWS))-1.77)*fy
			var y1: float=1.77+(lerpf(1.575,1.931,float(yi+1)/float(ROWS))-1.77)*fy
			var x0low: float=x0*_jaw_outline(y0,g,sex)*_forehead_outline(y0)
			var x0high: float=x0*_jaw_outline(y1,g,sex)*_forehead_outline(y1)
			var x1low: float=x1*_jaw_outline(y0,g,sex)*_forehead_outline(y0)
			var x1high: float=x1*_jaw_outline(y1,g,sex)*_forehead_outline(y1)
			var pts: Array[Vector3]=[
				Vector3(x0low,_chin_edge_height(x0low,y0),
					_seated_face_depth(x0low,_chin_edge_height(x0low,y0),
						g,sex,fw,fy)),
				Vector3(x0high,_chin_edge_height(x0high,y1),
					_seated_face_depth(x0high,_chin_edge_height(x0high,y1),
						g,sex,fw,fy)),
				Vector3(x1low,_chin_edge_height(x1low,y0),
					_seated_face_depth(x1low,_chin_edge_height(x1low,y0),
						g,sex,fw,fy)),
				Vector3(x1high,_chin_edge_height(x1high,y1),
					_seated_face_depth(x1high,_chin_edge_height(x1high,y1),
						g,sex,fw,fy))]
			for j in [0,1,2,1,3,2]:
				var point: Vector3=pts[j]
				st.set_uv(Vector2((point.x+.20)*2.5,(point.y-1.54)*2.5))
				st.set_normal(_outward_face_normal(point.x,point.y,g,sex))
				st.add_vertex(point)
	var face:=MeshInstance3D.new()
	face.name="IndividualIntegratedFaceMesh"
	face.mesh=st.commit()
	face.material_override=skin
	# The nose, cheek ridge and overlapping inherited skull share this
	# physical space. Dynamic shadows cast by the surface onto itself
	# previously blacked out the ENTIRE lower face in true Godot frames.
	# Retain real directional shading and world lighting, but avoid a
	# separate cosmetic face casting overlapping shadows like a mask.
	face.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	face.set_meta("true_inherited_lower_jaw_silhouette",true)
	root.add_child(face)

static func _anatomical_neck(root: Node3D,skin: Material,g: Dictionary,
		sex: String="unspecified") -> void:
	# Continuous skin-colored bridge below the genetically sculpted jaw.
	# Removing a tall fabric collar without this geometry left heads floating
	# over their shoulders in the real 1280x720 village captures.
	# Six contoured rings connect the clothing to the jaw without the
	# oversized uniform neck pipe visible in orthographic screenshots.
	var jaw_width: float=lerpf(.88,1.13,_v(g,"jaw_width"))
	jaw_width*=(.93 if sex=="female" else 1.055 if sex=="male" else 1.0)
	var depth_scale: float=lerpf(.90,1.11,_v(g,"body_depth"))
	# The clavicle bridge must NOT be a straight pipe above the shirt.
	# It is buried at its base beneath the garment, narrows beneath
	# the throat, then opens naturally into the individual jaw.
	# The anterior neck narrows under the jaw, then disappears into
	# the skull. Earlier widening at the top left an obvious bare pipe.
	var heights: Array[float]=[1.445,1.485,1.525,1.565,1.605,1.655]
	var half_widths: Array[float]=[.132,.119,.100,.088,.096,.119]
	var half_depths: Array[float]=[.121,.112,.098,.096,.104,.126]
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
				var midline: float=lerpf(-.014,.012,smoothstep(.10,1.0,t))
				# The front muscles form two subtle tapering planes, not
				# another pair of cylindrical neck props. Preserve back volume.
				var front: float=maxf(0.0,-sin(angle))
				var tendon: float=.0055*front*pow(absf(cos(angle)),1.5)*sin(PI*t)
				corners.append(Vector3(cos(angle)*radius_x,
					heights[idx],sin(angle)*radius_z+midline-tendon))
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
				# Beard growth is concentrated on the jaw, not a flat
				# coal-black square directly beneath the eye. The inner
				# cheek line begins lower, the outer sideburn remains high.
				var inner: float=1.0-clampf(absf(x)/.14,0.0,1.0)
				var cheek: bool=name.begins_with("GeneticFacialHairCheek")
				var root_y: float=top-.045*inner if cheek else top
				var y: float=lerpf(root_y,bottom+tip,v)
				var z: float=_depth(x,y,g,sex)-.003-.004*weight*v
				quad.append(Vector3(x,y,z))
			# The surface advances from high Y to low Y and left to
			# right, the OPPOSITE winding of the upward-built face.
			# Automatic normals previously pointed into the head, so
			# the lit cheek patch appeared as a black bruise from one
			# camera/light angle despite having correct hair pigment.
			for i in [0,2,1,0,3,2]:
				var p: Vector3=quad[i]
				tool.set_uv(Vector2(p.x*3.0,p.y*2.0))
				tool.set_normal(_outward_face_normal(p.x,p.y,g,sex))
				tool.add_vertex(p)
	var part:=MeshInstance3D.new()
	part.name=name
	part.mesh=tool.commit()
	part.material_override=mat
	# Decorative stubble follows the genetically modeled skin. Duplicate
	# shadows previously created a dark blotch below one eye in Godot.
	part.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	part.set_meta("soft_inherited_facial_hair",true)
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
	var dark:=ART.mat(GENES.hair_color(g).lerp(
		GENES.skin_color(g),.43),.98)
	dark.cull_mode=BaseMaterial3D.CULL_DISABLED
	var stubble:=ART.mat(GENES.skin_color(g).lerp(
		GENES.hair_color(g),.19),.98)
	stubble.cull_mode=BaseMaterial3D.CULL_DISABLED
	var facial_mat: Material=stubble if style=="stubble" else dark
	var weight: float=lerpf(.65,1.35,length)
	if style in ["short","full","stubble","sideburns"]:
		for side in [-1.0,1.0]:
			var edge: float=side*.135
			var near: float=side*.066
			_beard_patch(root,"GeneticFacialHairCheek"+str(side),
				facial_mat,g,sex,minf(edge,near),maxf(edge,near),
				1.708 if style!="sideburns" else 1.727,
				1.628 if style=="full" else 1.659,weight)
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

## A tapered, faceted *surface* for eyelids, brows and lips.
## The earlier CylinderMesh helpers rendered as parallel iron bars across
## the eyes and a protruding rectangular block over the mouth.
## This geometry remains an expressive child of the original joint.
static func _facial_ribbon(parent: Node3D,name: String,material: Material,
		from: Vector3,to: Vector3,half_height: float) -> MeshInstance3D:
	var tool:=SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	tool.set_material(material)
	const BANDS: int=9
	for i in range(BANDS-1):
		var quad: Array[Vector3]=[]
		for pair in [[i,-1.0],[i+1,-1.0],[i+1,1.0],[i,1.0]]:
			var t: float=float(pair[0])/float(BANDS-1)
			var side: float=float(pair[1])
			var center: Vector3=from.lerp(to,t)
			# Barely visible at the corners, fuller at the centre;
			# the gentle arch reads as an organic plane, not a pipe.
			var taper: float=.18+.82*pow(sin(PI*t),.68)
			var contour: float=.0035*sin(PI*t)
			quad.append(center+Vector3(0,side*half_height*taper,
				-contour*(1.0-side*side*.18)))
		# This strip is built left-to-right and bottom-to-top. A normal
		# triangle order faces +Z (inward) and darkens the visible eyelids.
		for k in [0,2,1,0,3,2]:
			var v: Vector3=quad[k]
			tool.set_uv(Vector2(v.x+.5,v.y+.5))
			tool.set_normal(Vector3(0,0,-1))
			tool.add_vertex(v)
	if material is StandardMaterial3D:
		(material as StandardMaterial3D).cull_mode=BaseMaterial3D.CULL_DISABLED
	var ribbon:=MeshInstance3D.new()
	ribbon.name=name
	ribbon.mesh=tool.commit()
	ribbon.material_override=material
	ribbon.set_meta("faceted_anatomical_surface",true)
	ribbon.set_meta("no_new_collision",true)
	parent.add_child(ribbon)
	return ribbon


## Expression-driven lips must remain fitted to the genetically sculpted
## facial surface. The old four planar petals all sat at the same depth,
## producing disconnected light/dark bars on real Godot face close-ups.
## Keep each existing expression joint and its original node name.
static func _fitted_lip(parent: Node3D,name: String,material: Material,
		from: Vector3,to: Vector3,half_height: float,
		g: Dictionary,sex: String,
		mouth_y: float,mouth_front: float) -> MeshInstance3D:
	var st:=SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_material(material)
	const STEPS: int=14
	for i in range(STEPS):
		var corners: Array[Vector3]=[]
		for pair in [[i,-1.0],[i+1,-1.0],[i+1,1.0],[i,1.0]]:
			var t: float=float(pair[0])/float(STEPS)
			var side: float=float(pair[1])
			var center: Vector3=from.lerp(to,t)
			# Each half of the mouth begins/ends at the central seam.
			# Taper ONLY at the OUTER corner. The previous sin(PI*t)
			# also tapered the central Cupid's bow to zero, leaving
			# a pinched four-petal gap in otherwise natural mouths.
			var reach: float=maxf(.001,maxf(absf(from.x),absf(to.x)))
			var outer: float=clampf(absf(center.x)/reach,0.0,1.0)
			var taper: float=.19+.81*sqrt(maxf(0.0,1.0-outer*outer))
			var y: float=center.y+side*half_height*taper
			var relief: float=_depth(center.x,mouth_y+y,g,sex)
			var z: float=relief-mouth_front-.007-.002*taper
			corners.append(Vector3(center.x,y,z))
		# The mouth's visible surface is -Z. Keep the true front-side
		# normal rather than backface-lighting the lip as a black plate.
		for k in [0,2,1,0,3,2]:
			var vertex: Vector3=corners[k]
			st.set_uv(Vector2(vertex.x+.5,vertex.y+.5))
			st.set_normal(_outward_face_normal(vertex.x,
				mouth_y+vertex.y,g,sex))
			st.add_vertex(vertex)
	if material is StandardMaterial3D:
		(material as StandardMaterial3D).cull_mode=BaseMaterial3D.CULL_DISABLED
	var lip:=MeshInstance3D.new()
	lip.name=name
	lip.mesh=st.commit()
	lip.material_override=material
	lip.set_meta("faceted_anatomical_surface",true)
	lip.set_meta("fitted_to_inherited_mouth",true)
	lip.set_meta("no_new_collision",true)
	parent.add_child(lip)
	return lip


## Eyelids are shaped as shallow skin folds on the ACTUAL inherited face,
## not horizontal strips floating ahead of the eyes. Their tapered corners
## disappear into the eye socket; independent blink covers still animate.
static func _fitted_eye_fold(socket: Node3D,name: String,skin: Material,
		g: Dictionary,sex: String,half_span: float,aperture: float,
		upper: bool) -> MeshInstance3D:
	var st:=SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_material(skin)
	const SEGMENTS: int=18
	for i in range(SEGMENTS):
		var quad: Array[Vector3]=[]
		for pair in [[i,0.0],[i+1,0.0],[i+1,1.0],[i,1.0]]:
			var u: float=float(pair[0])/float(SEGMENTS)*2.0-1.0
			var out: float=float(pair[1])
			var fade: float=pow(maxf(0.0,1.0-u*u),.72)
			var x: float=u*half_span
			var eye_edge: float=(.017 if upper else -.017)*aperture
			var arch: float=(.005 if upper else -.002)*fade
			var spread: float=(.011 if upper else -.010)*fade*out
			var y: float=eye_edge+arch+spread
			var face_z: float=_depth(socket.position.x+x,
				socket.position.y+y,g,sex)-socket.position.z
			var z: float=face_z-(.003+.011*(1.0-out))*fade-.001
			quad.append(Vector3(x,y,z))
		# Upper and lower fold bands travel in opposite Y directions.
		# Both must shade from their visible side, toward camera (-Z).
		var winding: Array[int]=[0,1,2,0,2,3]
		if upper:
			winding=[0,2,1,0,3,2]
		for k in winding:
			var p: Vector3=quad[k]
			st.set_uv(Vector2(p.x+.2,p.y+.1))
			st.set_normal(_outward_face_normal(
				socket.position.x+p.x,socket.position.y+p.y,g,sex))
			st.add_vertex(p)
	var fold:=MeshInstance3D.new()
	fold.name=name
	fold.mesh=st.commit()
	fold.material_override=skin
	fold.set_meta("attached_to_inherited_face",true)
	fold.set_meta("anatomical_eye_fold",true)
	fold.set_meta("no_new_collision",true)
	socket.add_child(fold)
	return fold

## Brows are individually groomed but their roots track the cheek and brow
## bone under them. The existing brow rig continues to control expressions.
static func _fitted_brow(brow_rig: Node3D,material: Material,
		g: Dictionary,sex: String,half_span: float,
		brow_tilt: float,half_height: float) -> MeshInstance3D:
	var st:=SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_material(material)
	const SEGMENTS: int=18
	for i in range(SEGMENTS):
		var quad: Array[Vector3]=[]
		for pair in [[i,-1.0],[i+1,-1.0],[i+1,1.0],[i,1.0]]:
			var u: float=float(pair[0])/float(SEGMENTS)*2.0-1.0
			var side: float=float(pair[1])
			var fade: float=pow(maxf(0.0,1.0-u*u),.68)
			var x: float=u*half_span
			var y: float=(brow_tilt*(u+1.0)*.5+.004*fade+
				side*half_height*fade)
			var face_z: float=_depth(brow_rig.position.x+x,
				brow_rig.position.y+y,g,sex)-brow_rig.position.z
			quad.append(Vector3(x,y,face_z-.006*fade-.002))
		for k in [0,2,1,0,3,2]:
			var p: Vector3=quad[k]
			st.set_uv(Vector2(p.x+.2,p.y+.1))
			st.set_normal(_outward_face_normal(
				brow_rig.position.x+p.x,brow_rig.position.y+p.y,g,sex))
			st.add_vertex(p)
	if material is StandardMaterial3D:
		(material as StandardMaterial3D).cull_mode=BaseMaterial3D.CULL_DISABLED
	var mesh:=MeshInstance3D.new()
	mesh.name="InheritedBrow"
	mesh.mesh=st.commit()
	mesh.material_override=material
	mesh.set_meta("attached_to_inherited_brow_bone",true)
	mesh.set_meta("no_new_collision",true)
	brow_rig.add_child(mesh)
	return mesh

## A shallow, continuous triangular nose whose side planes rise from the
## existing genetic nasal bridge. No floating ball for a nose tip.
static func _nose_facet(root: Node3D,skin: Material,g: Dictionary,
		sex: String,nose_y: float,nose_width: float) -> MeshInstance3D:
	var front: float=_depth(0,nose_y,g,sex)-.014
	var tool:=SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	tool.set_material(skin)
	const LEVELS: int=9
	const SIDES: int=9
	for row in range(LEVELS-1):
		for col in range(SIDES-1):
			var quad: Array[Vector3]=[]
			for pair in [[row,col],[row+1,col],
					[row+1,col+1],[row,col+1]]:
				var t: float=float(pair[0])/float(LEVELS-1)
				var lateral: float=float(pair[1])/float(SIDES-1)*2.0-1.0
				var y: float=lerpf(.063,-.045,t)
				var flare: float=smoothstep(.25,.90,t)
				var width: float=nose_width*lerpf(.26,.82,flare)
				var x: float=width*lateral
				var tissue: float=.004+.021*exp(-pow((t-.64)/.23,2.0))
				var z: float=(_depth(x,nose_y+y,g,sex)-
					tissue*(1.0-.57*lateral*lateral))
				quad.append(Vector3(x,y,z-front))
			# Bridge rows descend toward the tip; flip the triangles to
			# expose the real front-facing nose surface instead of its back.
			for k in [0,2,1,0,3,2]:
				var v: Vector3=quad[k]
				tool.set_uv(Vector2(v.x+.25,v.y+.25))
				tool.set_normal(_outward_face_normal(v.x,nose_y+v.y,g,sex))
				tool.add_vertex(v)
	if skin is StandardMaterial3D:
		(skin as StandardMaterial3D).cull_mode=BaseMaterial3D.CULL_DISABLED
	var nose:=MeshInstance3D.new()
	nose.name="ModeledNoseTip"
	nose.mesh=tool.commit()
	nose.position=Vector3(0,nose_y,front)
	nose.material_override=skin
	# The bridge is already sculpted into the continuous skin. Its
	# overlay defines a sharper tip, not a second light-occluding skull.
	nose.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	nose.set_meta("integrated_bridge_and_tip",true)
	nose.set_meta("no_new_collision",true)
	root.add_child(nose)
	return nose


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
	# Subtle vermilion contrast instead of a near-black cartoon mouth.
	var lip_ink:=ART.mat(GENES.skin_color(g).darkened(
		lerpf(.15,.075,_v(g,"lip_fullness"))),.99)
	var ear_scale: float=lerpf(.70,1.33,_v(g,"ear_size"))
	var eye_gap: float=lerpf(.068,.107,_v(g,"eye_spacing"))
	var eye_height: float=lerpf(1.780,1.802,_v(g,"brow_height"))
	# Feature dimensions must read at the standard third-person distance.
	# Larger eye anatomy is inherited rather than painted onto the face.
	var eye_width: float=lerpf(.045,.068,_v(g,"eye_shape")) * (
		1.045 if sex=="female" else 1.0)
	var tilt: float=lerpf(-.22,.22,_v(g,"brow_angle"))
	for sign in [-1.0,1.0]:
		var ear:=ART.orb(root,Vector3(sign*.205,1.762,.010),
			Vector3(.065,.102,.064)*ear_scale,skin,9)
		ear.name="SubtleModeledEar"
		var x: float=sign*eye_gap
		var depth: float=_depth(x,eye_height,g,sex)+.003
		var socket:=Node3D.new()
		socket.name="ExpressionEyeLeft" if sign<0.0 else "ExpressionEyeRight"
		socket.position=Vector3(x,eye_height,depth)
		root.add_child(socket)
		# A real layered eye: modestly recessed sclera, inherited iris,
		# pupil and upper/lower eyelids instead of a black flat square.
		var eye_aperture: float=lerpf(.80,1.28,_v(g,"eye_aperture"))
		var sclera:=ART.orb(socket,Vector3(0,0,-.006),
			Vector3(eye_width*1.18,.025*eye_aperture,.012),
			ART.mat(Color("bdb3a5"),.93),12)
		sclera.name="SmallRecessedEye"
		var iris:=ART.orb(socket,Vector3(0,0,-.013),
			Vector3(eye_width*.56,.018*eye_aperture,.006),iris_ink,12)
		iris.name="InheritedIris"
		var pupil:=ART.orb(socket,Vector3(0,0,-.018),
			Vector3(eye_width*.265,.011*eye_aperture,.004),eye_ink,10)
		pupil.name="AnatomicalPupil"
		var lid:=_fitted_eye_fold(socket,"IndividualUpperEyelid",skin,
			g,sex,eye_width*.94,eye_aperture,true)
		var lower_lid:=_fitted_eye_fold(socket,"AnatomicalLowerEyelid",skin,
			g,sex,eye_width*.89,eye_aperture,false)
		# Blink with actual moving eyelid volumes. The sclera, iris and pupil
		# stay at their anatomical sizes; compressing the entire eye made
		# villagers look like rubber-faced dolls during conversations.
		var upper_cover:=_facial_ribbon(socket,"ExpressionUpperBlinkCover",skin,
			Vector3(-eye_width*.99,0,-.015),
			Vector3(eye_width*.99,0,-.015),.016*eye_aperture)
		upper_cover.position.y=.038*eye_aperture
		upper_cover.set_meta("rest_y",upper_cover.position.y)
		var lower_cover:=_facial_ribbon(socket,"ExpressionLowerBlinkCover",skin,
			Vector3(-eye_width*.96,0,-.015),
			Vector3(eye_width*.96,0,-.015),.016*eye_aperture)
		lower_cover.position.y=-.038*eye_aperture
		lower_cover.set_meta("rest_y",lower_cover.position.y)
		var brow_rig:=Node3D.new()
		brow_rig.name="ExpressionBrowLeft" if sign<0.0 else "ExpressionBrowRight"
		brow_rig.position=Vector3(x,eye_height+.048,_depth(x,eye_height+.048,g,sex)-.010)
		root.add_child(brow_rig)
		var feminine_brow: bool=sex=="female"
		var brow_mesh:=_fitted_brow(brow_rig,brow,g,sex,
			eye_width*.94,sign*tilt*.038+(
				.004 if feminine_brow else 0.0),
			.008 if feminine_brow else .010)
		brow_rig.set_meta("rest_y",brow_rig.position.y)
		brow_rig.set_meta("rest_tilt",sign*tilt*.11)
	# These nose pieces attach directly to the genetically sculpted face.
	# A bridge/tip/nostril pair gives a distinct profile without a giant
	# cartoon bulb or unsupported free-floating cylinder.
	var nose_y: float=lerpf(1.704,1.732,_v(g,"nose_bridge"))
	var nose_width: float=lerpf(.030,.068,_v(g,"nose_width"))
	var nostril_width: float=lerpf(.64,1.28,_v(g,"nostril_width"))
	var nose_front: float=_depth(0,nose_y,g,sex)
	var tip:=_nose_facet(root,skin,g,sex,nose_y,nose_width)
	var nostril_skin:=ART.mat(GENES.skin_color(g).darkened(.39),.99)
	for side in [-1.0,1.0]:
		var wing_x: float=side*nose_width*.72
		var wing_y: float=nose_y-.035
		var wing_front: float=_depth(wing_x,wing_y,g,sex)
		var alar:=ART.orb(root,Vector3(wing_x,wing_y,wing_front-.003),
			Vector3(nose_width*.24,.015,.009),skin,9)
		alar.name="ModeledNoseWing"
		var nostril:=ART.orb(root,
			Vector3(side*nose_width*.68*nostril_width,wing_y-.013,wing_front-.009),
			Vector3(.006*nostril_width,.004,.003),nostril_skin,8)
		nostril.name="InheritedNostril"
	# Faceted cheekbone highlights follow the integrated mesh surface.
	# The underlying skull is continuous, not an attached cheek sphere.
	var cheek_tone:=ART.mat(GENES.skin_color(g).lightened(.029),.99)
	for side in [-1.0,1.0]:
		var ridge_x: float=side*lerpf(.113,.133,_v(g,"cheek_fullness"))
		var ridge_y: float=lerpf(1.727,1.773,_v(g,"cheek_height"))
		var plane:=SurfaceTool.new()
		plane.begin(Mesh.PRIMITIVE_TRIANGLES)
		for offset in [Vector2(-.035,-.026),Vector2(.008,.022),
				Vector2(.051,-.014)]:
			var px: float=ridge_x+offset.x*side
			var py: float=ridge_y+offset.y
			plane.set_uv(Vector2(px*2.0,py*2.0))
			plane.add_vertex(Vector3(px,py,_depth(px,py,g,sex)-.003))
		var highlight:=MeshInstance3D.new()
		highlight.name="InheritedCheekboneFacet"
		highlight.mesh=plane.commit()
		highlight.material_override=cheek_tone
		highlight.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(highlight)
	var mouth_width: float=lerpf(.038,.077,_v(g,"mouth_width"))
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
	var fullness: float=lerpf(.008,.024,_v(g,"lip_fullness"))
	# Lip curve is independent of inherited width and fullness. High
	# alleles lift the neutral mouth corners and Cupid's bow; low alleles
	# produce a flatter, downturned mouth. Expressions animate these
	# inherited shapes rather than replacing them with generic lips.
	var cupid_rise: float=lerpf(.002,.009,_v(g,"lip_curve"))
	var corner_rise: float=lerpf(-.006,.005,_v(g,"lip_curve"))
	mouth.set_meta("rest_cupid_rise",cupid_rise)
	mouth.set_meta("rest_corner_rise",corner_rise)
	# Upper and lower lip bands occupy separate volumes and articulate
	# from their own corners. Very thin lips remain truly thin.
	var left_lip:=_fitted_lip(left_corner,"SmallNaturalLipLine",lip_ink,
		Vector3(-mouth_width,corner_rise,0),Vector3(0,cupid_rise,0),
		fullness*.41,g,sex,lip_height,mouth.position.z)
	var left_lower:=_fitted_lip(lower_rig,"ModeledLowerLipLeft",lip_ink,
		Vector3(-mouth_width,corner_rise-.007,0),Vector3(0,-.010,0),
		fullness*.31,g,sex,lip_height,mouth.position.z)
	var right_corner:=Node3D.new()
	right_corner.name="ExpressionLipRight"
	mouth.add_child(right_corner)
	var right_lip:=_fitted_lip(right_corner,"NaturalLipCorner",lip_ink,
		Vector3(0,cupid_rise,0),Vector3(mouth_width,corner_rise,0),
		fullness*.41,g,sex,lip_height,mouth.position.z)
	var right_lower:=_fitted_lip(lower_rig,"ModeledLowerLipRight",lip_ink,
		Vector3(0,-.010,0),Vector3(mouth_width,corner_rise-.007,0),
		fullness*.31,g,sex,lip_height,mouth.position.z)
	var open_mouth:=_facial_ribbon(mouth,"ExpressionMouthOpening",
		ART.mat(Color("301c1c"),1),
		Vector3(-mouth_width*.89,-.005,.013),
		Vector3(mouth_width*.89,-.005,.013),.0022)
	# A fine oral crease anchors the lips at rest; the old four separate
	# thick petals read like a geometric flower rather than a mouth.
	open_mouth.visible=true
	open_mouth.scale.y=.36
	# Connected scalp shell follows each inherited skull and natural
	# hairline. A huge flattened spherical cap used to resemble a helmet.
	var scalp: MeshInstance3D=HAIR.scalp_cap(root,hair,g,person)
	# The old tiny scalp spheres looked like horns in close-up shots.
	# The groomed mesh now owns curls, fringe and parting instead.
	# Named villagers have recognisable grooming; descendants express
	# inherited follicle properties without being forced into a profession.
	HAIR.finish(root,person,g,sex,hair)
	_facial_hair(root,g,sex,age_years)
	# These tiny expression meshes were casting disproportionately dark
	# contact shadows across the real inherited face. Preserve their
	# volume, depth, animation and material response, but let the single
	# physical skull control the face rather than dozens of local shadow
	# casters. Hair and the anatomical throat keep normal shadow behavior.
	var facial_decoration: Array[String]=[
		"SubtleModeledEar","SmallRecessedEye","InheritedIris",
		"AnatomicalPupil","IndividualUpperEyelid","AnatomicalLowerEyelid",
		"ExpressionUpperBlinkCover","ExpressionLowerBlinkCover",
		"InheritedBrow","ModeledNoseWing","InheritedNostril",
		"InheritedCheekboneFacet","SmallNaturalLipLine",
		"ModeledLowerLipLeft","NaturalLipCorner","ModeledLowerLipRight",
		"ExpressionMouthOpening"
	]
	for part in root.find_children("*","MeshInstance3D",true,false):
		if String(part.name) in facial_decoration:
			(part as MeshInstance3D).cast_shadow=(
				GeometryInstance3D.SHADOW_CASTING_SETTING_OFF)
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
	# Preserve a visible neck column between the clavicles and the jaw.
	# Scaling about the lower collar gave people swallowed, shoulder-level heads.
	const THROAT: float=1.62
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
		speaking: bool=false,conversation_phase: float=0.0,
		gaze: Vector2=Vector2.ZERO) -> void:
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
			# Independent iris and pupil look toward the listener; the white
			# and inherited face geometry are never moved or rescaled.
			for part_name in ["InheritedIris","AnatomicalPupil"]:
				var moving_eye: Node3D=eye.get_node_or_null(part_name)
				if moving_eye!=null:
					moving_eye.position.x=lerpf(moving_eye.position.x,
						clampf(gaze.x,-.006,.006),.22)
					moving_eye.position.y=lerpf(moving_eye.position.y,
						clampf(gaze.y,-.004,.004),.22)
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
			opening_mesh.visible=true
			opening_mesh.scale.y=lerpf(.7,2.5,syllable) if talking else .36+maxf(0.0,-emotion)*1.1
			# Only the lower lip moves with a spoken syllable. The mouth
			# aperture follows it; the face, teeth and nose remain still.
			var lower: Node3D=mouth.get_node_or_null("ExpressionLowerLip")
			if lower!=null:
				var lowered: float=(-.024*syllable if talking else
					-.006*maxf(0.0,-emotion))
				lower.position.y=lerpf(lower.position.y,lowered,.32)
	root.set_meta("expression_blink",eyelid_drop)
	root.set_meta("expression_speaking",speaking)
