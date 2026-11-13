extends RefCounted
## Faceted, painterly dressmaking. The inherited mesh determines where
## a waist, ribcage, pelvis and thigh actually are. Different silhouettes
## come from the CUT of a garment, not an inflatable "woman" body preset.
const ART=preload("res://scripts/art.gd")
const GENES=preload("res://scripts/npc_genetics.gd")
const BODY=preload("res://scripts/npc_body_morph.gd")
const FABRIC=preload("res://scripts/npc_cloth_finish.gd")

static func garment_style(person: String,sex: String,
		genome: Dictionary) -> String:
	match person:
		"ida": return "apron_dress"
		"mara": return "scribe_layers"
		"sela": return "merchant_skirt"
		"lena": return "painter_smock"
		"nima": return "traveller_dress"
		"juno": return "work_dress"
		"orin": return "smith_vest"
		"titus": return "guard_tunic"
		"daro": return "field_waistcoat"
	if sex=="female":
		return "traveller_dress" if GENES.value(genome,"hip_width")<.47 else "scribe_layers"
	return "field_waistcoat" if GENES.value(genome,"chest_width")>.64 else "guard_tunic"

static func _dress_skirt(root: Node3D,genome: Dictionary,
		sex: String,style: String,cloth: Material) -> MeshInstance3D:
	var st:=SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_material(cloth)
	const ROWS: int=14
	const SIDES: int=20
	var floor_y: float=.48 if style in ["traveller_dress","work_dress"] else .365
	var extra_flare: float=.035 if style in ["scribe_layers","work_dress"] else (
		.068 if style in ["merchant_skirt","painter_smock"] else .050)
	for row in range(ROWS-1):
		for seg in range(SIDES):
			var points: Array[Vector3]=[]
			for combo in [[row,seg],[row+1,seg],[row+1,seg+1],[row,seg+1]]:
				var r: int=int(combo[0])
				var angle: float=TAU*float(combo[1])/float(SIDES)
				var t: float=float(r)/float(ROWS-1)
				var y: float=lerpf(1.075,floor_y,t)
				var waist_to_hip: float=clampf((1.075-y)/.28,0.0,1.0)
				var section: Vector2=BODY._section(maxf(.785,y),genome,sex)
				# Subtle flare BELOW the upper hip, not a cone starting at
				# the shoulders. Hip curvature remains visibly inherited.
				var flare: float=extra_flare*smoothstep(.36,1.0,t)
				var pleat: float=.012*sin(angle*7.0+float(r)*.16)*t*t
				var asym: float=.011*sin(angle*2.0+.8)*t
				var x: float=cos(angle)*(section.x*1.065+flare+pleat)
				var z: float=sin(angle)*(section.y*1.085+flare*.66+asym)
				# A few planes at the lower hem follow separate cloth
				# folds; nobody gets an unsupported perfect bell shape.
				var hem_y: float=y+.009*t*t*sin(angle*6.0+.5)
				points.append(Vector3(x,hem_y,z))
			for k in [0,1,2,0,2,3]:
				var v: Vector3=points[k]
				st.set_uv(Vector2((atan2(v.z,v.x)+PI)/TAU*1.4,v.y*1.3))
				st.add_vertex(v)
	st.generate_normals()
	var skirt:=MeshInstance3D.new()
	skirt.name="InheritedCutDressSkirt"
	skirt.mesh=st.commit()
	if cloth is StandardMaterial3D:
		(cloth as StandardMaterial3D).cull_mode=BaseMaterial3D.CULL_DISABLED
	skirt.material_override=cloth
	skirt.set_meta("cut",style)
	skirt.set_meta("genetic_hips",GENES.value(genome,"hip_width"))
	skirt.set_meta("not_body_shape",true)
	skirt.set_meta("no_new_collision",true)
	root.add_child(skirt)
	return skirt

static func _drape(root: Node3D,name: String,genome: Dictionary,
		sex: String,material: Material,offset: float,
		from_y: float,to_y: float,half_width: float,flare: float) -> void:
	var st:=SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_material(material)
	const ROWS: int=8
	const COLS: int=9
	for row in range(ROWS-1):
		for col in range(COLS-1):
			var quad: Array[Vector3]=[]
			for rc in [[row,col],[row+1,col],[row+1,col+1],[row,col+1]]:
				var r: int=int(rc[0])
				var u: float=float(rc[1])/float(COLS-1)*2.0-1.0
				var t: float=float(r)/float(ROWS-1)
				var y: float=lerpf(from_y,to_y,t)
				var ww: float=half_width+flare*t
				var x: float=offset+u*ww
				var base: Vector2=BODY._section(maxf(.79,y),genome,sex)
				var a: float=-PI*.5+asin(clampf(x/base.x,-.95,.95))
				var p: Vector3=BODY._point(maxf(.79,y),a,genome,sex)
				var z: float=p.z-.045-.014*t*t
				var wrinkle: float=.013*sin(float(rc[1])*2.0)*t*t
				quad.append(Vector3(x,y+.008*sin(u*PI)*t,z-wrinkle))
			for k in [0,1,2,0,2,3]:
				var pt: Vector3=quad[k]
				st.set_uv(Vector2(pt.x*2.2,pt.y*1.6))
				st.add_vertex(pt)
	st.generate_normals()
	var piece:=MeshInstance3D.new()
	piece.name=name
	piece.mesh=st.commit()
	if material is StandardMaterial3D:
		(material as StandardMaterial3D).cull_mode=BaseMaterial3D.CULL_DISABLED
	piece.material_override=material
	piece.set_meta("no_new_collision",true)
	root.add_child(piece)

static func _waist_wrap(root: Node3D,genome: Dictionary,
		sex: String,material: Material) -> void:
	# The sash repeats the waist shape rather than circling a sphere.
	for seg in range(18):
		var a: float=TAU*float(seg)/18.0
		var b: float=TAU*float(seg+1)/18.0
		var p0: Vector3=BODY._point(1.068,a,genome,sex)
		var p1: Vector3=BODY._point(1.068,b,genome,sex)
		p0.x*=1.089
		p1.x*=1.089
		p0.z*=1.09
		p1.z*=1.09
		var seam:=ART.bone(root,p0,p1,.013,.011,material,6)
		seam.name="WovenWaistCord"+str(seg)

static func finish(figure: Node3D,person: String,
		genome: Dictionary,sex: String) -> Node3D:
	var existing:=figure.get_node_or_null("RoleWardrobeLayers") as Node3D
	if existing!=null: return existing
	var style: String=garment_style(person,sex,genome)
	var root:=Node3D.new()
	root.name="RoleWardrobeLayers"
	root.set_meta("wardrobe_style",style)
	root.set_meta("no_new_collision",true)
	root.set_meta("heritable_body_cut",true)
	figure.add_child(root)
	var bone:=FABRIC.worn_linen(Color("b4a68b"))
	var ash:=FABRIC.worn_linen(Color("5d5c62"))
	var moss:=FABRIC.worn_linen(Color("48534a"))
	var rust:=FABRIC.worn_linen(Color("70484b"))
	var dusky:=FABRIC.worn_linen(Color("4b5360"))
	var brass:=ART.mat(Color("9d8054"),.95)
	# A single fitted dress from COSTUME already follows the inherited
	# pelvis. Do not stack a second opaque skirt: two overlapping shells
	# made every woman look broad and caused z-fighting in screenshots.
	var has_tailored: bool=figure.get_node_or_null("TailoredHereditaryDress")!=null
	match style:
		"apron_dress":
			if not has_tailored: _dress_skirt(root,genome,sex,style,rust)
			# A flour-stained front apron is already worn over the torso;
			# narrow under-dress side gores show past the apron hem.
			_drape(root,"BakerApronDressGore",genome,sex,bone,.175,
				1.02,.455,.034,.012)
			# Baker apron already includes tied waist strings and an apron seam.
		"scribe_layers":
			if not has_tailored: _dress_skirt(root,genome,sex,style,dusky)
			_drape(root,"ScribeInkStainedStole",genome,sex,ash,-.095,
				1.35,.445,.067,-.007)
			_drape(root,"ScribeFineFrontHem",genome,sex,moss,.145,
				1.10,.530,.037,.009)
			_waist_wrap(root,genome,sex,brass)
		"merchant_skirt":
			if not has_tailored: _dress_skirt(root,genome,sex,style,moss)
			_drape(root,"MerchantLayeredOverskirt",genome,sex,rust,-.075,
				1.08,.485,.113,.036)
			_drape(root,"MerchantGoldSash",genome,sex,bone,.152,
				1.15,.720,.027,.015)
			_waist_wrap(root,genome,sex,brass)
		"painter_smock":
			if not has_tailored: _dress_skirt(root,genome,sex,style,ash)
			_drape(root,"PainterPigmentedWorkSmock",genome,sex,bone,
				.015,1.31,.625,.122,.019)
			_drape(root,"PainterAsymmetricClothHem",genome,sex,dusky,
				-.125,.92,.470,.061,.023)
		"traveller_dress":
			if not has_tailored: _dress_skirt(root,genome,sex,style,dusky)
			_drape(root,"TravellerCrossWrap",genome,sex,rust,-.110,
				1.25,.655,.085,-.019)
			_waist_wrap(root,genome,sex,brass)
		"work_dress":
			# Twentieth-century utility clothing over the station jeans;
			# this is a close A-line layer, not a medieval bell skirt.
			if not has_tailored: _dress_skirt(root,genome,sex,style,dusky)
			_waist_wrap(root,genome,sex,ash)
		"guard_tunic":
			_drape(root,"GuardWornTabard",genome,sex,dusky,
				-.010,1.37,.660,.130,-.014)
		"smith_vest":
			_drape(root,"SmithSleevelessOverlayer",genome,sex,ash,
				-.145,1.42,1.045,.064,-.012)
		"field_waistcoat":
			_drape(root,"FieldWorkerLeftVest",genome,sex,moss,
				-.118,1.39,1.05,.070,-.012)
			_drape(root,"FieldWorkerRightVest",genome,sex,ash,
				.118,1.38,1.05,.070,-.012)
	return root
