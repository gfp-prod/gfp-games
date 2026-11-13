extends RefCounted
## Silhouette-driven, faceted grooming shared by the living village.
## Hair growth/colour/curl are inherited; styling is a chosen presentation.
## Every mesh sits under the existing face root and adds no hitboxes.
const ART=preload("res://scripts/art.gd")
const GENES=preload("res://scripts/npc_genetics.gd")

## Keep a grown lock outside the inherited torso as it passes the shoulder.
## The old straight ribbons went through the chest/back beneath their roots.
## Hair stays part of the same non-colliding face rig; no rigid wig or hitbox.
static func _routed_depth(at: Vector3,t: float,tip_y: float,
		x: float,curl: float) -> float:
	var z: float=at.z+.045*t+.010*curl*sin(t*TAU*1.2)
	if tip_y>=1.70:
		return z
	var shoulder_turn: float=smoothstep(.14,.64,t)
	if at.z>.10:
		# Long loose hair and ponytails clear the back of a fitted tunic.
		z=lerpf(z,maxf(z,.358+.035*absf(x)),shoulder_turn)
	else:
		# Face-framing locks and braids ride forward over the chest.
		z=lerpf(z,minf(z,-.344+.045*absf(x)),shoulder_turn)
	return z

static func _strand(root: Node3D,name: String,material: Material,
		at: Vector3,tip_y: float,side: float,wide: float,
		curl: float,sweep: float=0.0) -> MeshInstance3D:
	var tool:=SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	tool.set_material(material)
	const ROWS: int=10
	const SIDES: int=9
	for i in range(ROWS-1):
		for j in range(SIDES):
			var vertices: Array[Vector3]=[]
			for pair in [[i,j],[i+1,j],[i+1,j+1],[i,j+1]]:
				var row: int=int(pair[0])
				var sector: int=int(pair[1])
				var t: float=float(row)/float(ROWS-1)
				var theta: float=TAU*float(sector)/float(SIDES)
				var taper: float=lerpf(.91,.32,pow(t,1.55))
				var wave: float=.017*curl*sin(t*TAU*1.45+side*.83)
				var x: float=at.x+sweep*t+wave+cos(theta)*wide*taper
				var z: float=_routed_depth(at,t,tip_y,x,curl)+(
					sin(theta)*wide*.73*taper)
				vertices.append(Vector3(x,lerpf(at.y,tip_y,t),z))
			for k in [0,1,2,0,2,3]:
				var p: Vector3=vertices[k]
				tool.set_uv(Vector2(float(j)/float(SIDES),p.y*.9))
				tool.add_vertex(p)
	tool.generate_normals()
	var mesh:=MeshInstance3D.new()
	mesh.name=name
	mesh.mesh=tool.commit()
	mesh.material_override=material
	mesh.set_meta("grown_from_original_face",true)
	mesh.set_meta("no_new_collision",true)
	root.add_child(mesh)
	return mesh

## A continuous low-poly hairline. The skull is wrapped with a fitted
## dome whose perimeter is higher at the temples and lower at the forehead.
## This is a single SurfaceTool hair mass, not a huge scaled sphere/helmet.
static func scalp_cap(face_root: Node3D, hair: Material, genome: Dictionary,
		person: String) -> MeshInstance3D:
	var existing:=face_root.get_node_or_null("NaturalHairline") as MeshInstance3D
	if existing!=null: return existing
	var volume: float=GENES.value(genome,"hair_volume")
	var part: float=GENES.value(genome,"hair_parting")
	var width: float=lerpf(.187,.209,volume)
	var depth: float=lerpf(.159,.185,volume)
	var top: float=lerpf(2.048,2.085,volume)
	var surface:=SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_material(hair)
	const SECTORS: int=22
	const RINGS: int=9
	for row in range(RINGS-1):
		for sector in range(SECTORS):
			var quad: Array[Vector3]=[]
			for pair in [[row,sector],[row+1,sector],
					[row+1,sector+1],[row,sector+1]]:
				var k: int=int(pair[0])
				var theta: float=TAU*float(pair[1])/float(SECTORS)
				var t: float=float(k)/float(RINGS-1)
				var circumference: float=pow(maxf(.0,1.0-t*t),.68)
				var hairline: float=1.924+.014*maxf(.0,-sin(theta))
				hairline+=.015*absf(cos(theta))
				hairline+=.009*(part-.5)*cos(theta)
				quad.append(Vector3(
					cos(theta)*width*circumference,
					lerpf(hairline,top,t)+.004*(1.0-t)*sin(theta*3.0+t*5.0),
					.030+sin(theta)*depth*circumference))
			for k in [0,1,2,0,2,3]:
				var p: Vector3=quad[k]
				surface.set_uv(Vector2((p.x+.25)*2.0,(p.z+.25)*2.0))
				surface.add_vertex(p)
	surface.generate_normals()
	var cap:=MeshInstance3D.new()
	cap.name="NaturalHairline"
	cap.mesh=surface.commit()
	cap.material_override=hair
	cap.visible=not (person in ["ida","daro"])
	cap.set_meta("coherent_sculpted_hair_mass",true)
	cap.set_meta("hairline_follows_skull",true)
	cap.set_meta("inherited_volume",volume)
	cap.set_meta("no_new_collision",true)
	face_root.add_child(cap)
	return cap


## A broad, tapered polygonal tress with irregular edges and volume.
## These sculpted sheets replace hanging cylinders for loose/waved hair.
## Genuine braids retain their separate woven elements where appropriate.
static func _hair_sheet(root: Node3D,name: String,material: Material,
		at: Vector3,tip_y: float,half_width: float,
		curl: float,sweep: float=0.0) -> MeshInstance3D:
	var tool:=SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	tool.set_material(material)
	const ROWS: int=12
	const SPANS: int=7
	for row in range(ROWS-1):
		for col in range(SPANS-1):
			var corners: Array[Vector3]=[]
			for pair in [[row,col],[row+1,col],
					[row+1,col+1],[row,col+1]]:
				var t: float=float(pair[0])/float(ROWS-1)
				var u: float=float(pair[1])/float(SPANS-1)*2.0-1.0
				var flow: float=pow(sin(PI*t),2.0)
				var width: float=half_width*lerpf(.65,1.10,
					smoothstep(.0,.35,t))*(1.0-.22*t)
				var ripple: float=.012*curl*sin(t*TAU*1.4+u*2.1)
				var x: float=at.x+u*width+sweep*t+ripple
				var center_z: float=_routed_depth(at,t,tip_y,x,curl)
				# The raised central ridge makes a continuous curved
				# hair panel rather than a paper-flat plane.
				var z: float=center_z-.022*(1.0-u*u)*flow
				z+=.007*sin(u*PI*1.8+t*4.1)*t
				corners.append(Vector3(x,lerpf(at.y,tip_y,t),z))
			for k in [0,1,2,0,2,3]:
				var p: Vector3=corners[k]
				tool.set_uv(Vector2((p.x+.5),p.y*.9))
				tool.add_vertex(p)
	tool.generate_normals()
	var panel:=MeshInstance3D.new()
	panel.name=name
	panel.mesh=tool.commit()
	if material is StandardMaterial3D:
		(material as StandardMaterial3D).cull_mode=BaseMaterial3D.CULL_DISABLED
	panel.material_override=material
	panel.set_meta("sculpted_continuous_tress",true)
	panel.set_meta("hair_flow_top_to_bottom",true)
	panel.set_meta("no_new_collision",true)
	root.add_child(panel)
	return panel


## A single asymmetrically sculpted hair mass instead of a spherical bun.
## Longitudinal ridges suggest gathered strands converging from the head.
static func _gathered_knot(root: Node3D,name: String,mat: Material,
		volume: float) -> MeshInstance3D:
	var tool:=SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	tool.set_material(mat)
	const SIDES: int=18
	const RINGS: int=9
	for row in range(RINGS-1):
		for sector in range(SIDES):
			var corners: Array[Vector3]=[]
			for pair in [[row,sector],[row+1,sector],
					[row+1,sector+1],[row,sector+1]]:
				var t: float=float(pair[0])/float(RINGS-1)
				var a: float=TAU*float(pair[1])/float(SIDES)
				var shape: float=pow(sin(PI*t),.74)
				var r: float=(.077+.027*volume)*shape
				var striation: float=.008*sin(a*6.0+t*7.5)*shape
				corners.append(Vector3(
					cos(a)*(r+striation),
					1.897+t*.134,
					.183+sin(a)*(r*.64+striation*.40)+.030*shape))
			for k in [0,1,2,0,2,3]:
				var v: Vector3=corners[k]
				tool.set_uv(Vector2(v.x+.5,v.y))
				tool.add_vertex(v)
	tool.generate_normals()
	var knot:=MeshInstance3D.new()
	knot.name=name
	knot.mesh=tool.commit()
	knot.material_override=mat
	knot.set_meta("gathered_strand_mass",true)
	knot.set_meta("no_new_collision",true)
	root.add_child(knot)
	return knot


## A faceted *connected* crop shell with a scalloped perimeter.
## No twenty separate spheres orbiting the scalp and no free-ended rods.
static func _curly_crown(root: Node3D,mat: Material,g: Dictionary) -> MeshInstance3D:
	var density: float=lerpf(.92,1.12,GENES.value(g,"hair_volume"))
	var curl: float=GENES.value(g,"hair_curl")
	var st:=SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_material(mat)
	const SECTORS: int=26
	const ROWS: int=11
	for row in range(ROWS-1):
		for sector in range(SECTORS):
			var quad: Array[Vector3]=[]
			for pair in [[row,sector],[row+1,sector],
					[row+1,sector+1],[row,sector+1]]:
				var t: float=float(pair[0])/float(ROWS-1)
				var a: float=TAU*float(pair[1])/float(SECTORS)
				var scallop: float=.011*curl*sin(a*10.0+t*9.0)
				var radius: float=(.185*pow(maxf(0.0,1.0-t*t),.7)+
					scallop*(1.0-t))*density
				var edge: float=1.944+.014*maxf(0.0,-sin(a))
				quad.append(Vector3(
					cos(a)*radius,
					lerpf(edge,2.101+.020*curl,t)+
						.008*sin(a*7.0+t*12.0)*sin(PI*t),
					.026+sin(a)*radius*.81))
			for k in [0,1,2,0,2,3]:
				var v: Vector3=quad[k]
				st.set_uv(Vector2((v.x+.24)*2.0,(v.z+.24)*2.0))
				st.add_vertex(v)
	st.generate_normals()
	var crown:=MeshInstance3D.new()
	crown.name="SculptedCurlyCrown"
	crown.mesh=st.commit()
	crown.material_override=mat
	crown.set_meta("one_connected_curl_silhouette",true)
	crown.set_meta("individual_curl_genetics",curl)
	crown.set_meta("no_new_collision",true)
	root.add_child(crown)
	return crown


static func _back_panels(root: Node3D,main: Material,shine: Material,
		tip_y: float,curl: float) -> void:
	# Individually cut ribbon panels give a soft mantle silhouette, not
	# the straight dangling cylinders that made older villagers look robotic.
	for i in range(5):
		var x: float=(float(i)-2.0)*.072
		var variation: float=.038*sin(float(i)*1.87+curl*3.0)
		var mat: Material=shine if i in [1,3] else main
		_hair_sheet(root,"FacetedBackHairPanel"+str(i),mat,
			Vector3(x,1.987,.151+absf(x)*.15),
			tip_y+variation,.079,curl,x*.14)

static func _side_framing(root: Node3D,main: Material,shine: Material,
		tip_y: float,curl: float,wide: float=.047) -> void:
	for side in [-1.0,1.0]:
		var name: String="Left" if side<0.0 else "Right"
		_hair_sheet(root,"Faceted"+name+"HairFrame",main,
			Vector3(side*.172,1.968,-.022),
			tip_y,wide*1.5,curl,side*.026)
		_hair_sheet(root,"Fine"+name+"HairUnderlayer",shine,
			Vector3(side*.189,1.939,.046),
			tip_y+.082,wide*.90,curl,side*.011)

static func _braid(root: Node3D,main: Material,highlight: Material,
		side: float,top: Vector3,tip_y: float,curl: float) -> void:
	var side_name: String="Left" if side<0.0 else "Right"
	_strand(root,"Woven"+side_name+"HairCore",main,
		top,tip_y,side,.040,curl,side*.018)
	# Six alternating overlapping plaits define a readable woven strand.
	for i in range(6):
		var t: float=(float(i)+.42)/6.0
		var plait_x: float=top.x+side*.015*t
		var center:=Vector3(plait_x,
			lerpf(top.y,tip_y,t),
			_routed_depth(top,t,tip_y,plait_x,curl))
		var plait:=ART.bone(root,
			center+Vector3(-side*.035,.043,0),
			center+Vector3(side*.035,-.039,.012),
			.038*(1.0-t*.40),.027*(1.0-t*.35),
			highlight if i%2==0 else main,8)
		plait.name=side_name+"WovenBraidPlait"+str(i)
	var tie_x: float=top.x+side*.018
	var tie_depth: float=_routed_depth(top,1.0,tip_y,tie_x,curl)
	var end:=ART.bone(root,
		Vector3(tie_x,tip_y+.043,tie_depth),
		Vector3(tie_x,tip_y+.023,tie_depth+.004),
		.028,.025,highlight,8)
	end.name=side_name+"BraidedLeatherTie"

static func _swept_top(root: Node3D,main: Material,shine: Material,
		curl: float,side: float=1.0) -> void:
	for i in range(4):
		var x: float=(float(i)-1.5)*.071
		_hair_sheet(root,"SweptLowPolyTop"+str(i),
			shine if i==1 else main,
			Vector3(x-side*.085,2.033,-.057),
			1.925,.066,curl,side*(.073+.009*float(i)))

static func finish(face_root: Node3D,person: String,genome: Dictionary,
		sex: String,hair: Material) -> Node3D:
	var existing:=face_root.get_node_or_null("GroomedHairStudio") as Node3D
	if existing!=null: return existing
	var profile: Dictionary=GENES.hair_profile(genome,sex,person)
	var style: String=String(profile["style"])
	var curl: float=float(profile["curl"])
	var gene_length: float=float(profile["length"])
	var root:=Node3D.new()
	root.name="GroomedHairStudio"
	root.set_meta("hairstyle",style)
	root.set_meta("hair_length_alleles",gene_length)
	root.set_meta("inherited_hair_curl",curl)
	root.set_meta("styling_is_a_choice",true)
	root.set_meta("no_new_collision",true)
	face_root.add_child(root)
	var shine:=ART.mat(GENES.hair_color(genome).lightened(.085),.97)
	var deep:=ART.mat(GENES.hair_color(genome).darkened(.10),.98)
	match style:
		"loose","wave":
			var length_end: float=lerpf(1.47,1.29,gene_length)
			_back_panels(root,hair,shine,length_end,curl)
			_side_framing(root,hair,shine,length_end+.09,curl)
			if style=="wave":
				for side in [-1.0,1.0]:
					_strand(root,"SinuousOverShoulder"+str(side),shine,
						Vector3(side*.196,1.845,-.005),length_end+.105,
						side,.047,maxf(.52,curl),side*.055)
		"braids":
			_back_panels(root,deep,hair,1.65,curl)
			for side in [-1.0,1.0]:
				_braid(root,hair,shine,side,
					Vector3(side*.178,1.939,.032),1.34,curl)
		"bun":
			_side_framing(root,hair,shine,1.745,curl,.029)
			var bun:=_gathered_knot(root,"TiedLowHairBun",deep,
				GENES.value(genome,"hair_volume"))
			for side in [-1.0,1.0]:
				_hair_sheet(root,"GatheredSideHair"+str(side),hair,
					Vector3(side*.105,2.013,.082),1.92,.082,curl,
					-side*.050)
		"ponytail":
			var knot:=_gathered_knot(root,"LowPonytailRootTie",deep,
				GENES.value(genome,"hair_volume")*.62)
			for i in range(3):
				_hair_sheet(root,"LongPonytailTail"+str(i),
					shine if i==1 else hair,
					Vector3((float(i)-1.0)*.046,1.914,.224),
					lerpf(1.32,1.48,1.0-gene_length),
					.061,curl,(float(i)-1.0)*.026)
			_side_framing(root,hair,shine,1.81,curl,.028)
		"swept":
			_swept_top(root,hair,shine,curl,-1.0)
			_side_framing(root,hair,shine,1.817,curl,.024)
		"shaggy":
			_swept_top(root,hair,shine,curl,1.0)
			_back_panels(root,hair,deep,1.77,curl)
			_side_framing(root,hair,shine,1.755,curl,.036)
		"curly_crop":
			_curly_crown(root,hair,genome)
			# Scalp-hugging temples retain the silhouette from three-quarter
			# angles while remaining part of the hair, not decorative rods.
			for side in [-1.0,1.0]:
				_hair_sheet(root,"CurlyTemple"+str(side),deep,
					Vector3(side*.166,2.018,-.021),1.946,.044,curl,
					side*.006)
		_:
			_swept_top(root,hair,deep,curl,1.0)
			if style=="crop":
				# The bald scalp cap remains the crown; the short fringe
				# adds an intentionally asymmetrical temple silhouette.
				_side_framing(root,hair,shine,1.88,curl,.017)
	return root
