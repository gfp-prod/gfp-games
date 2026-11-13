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

static func _back_panels(root: Node3D,main: Material,shine: Material,
		tip_y: float,curl: float) -> void:
	# Individually cut ribbon panels give a soft mantle silhouette, not
	# the straight dangling cylinders that made older villagers look robotic.
	for i in range(5):
		var x: float=(float(i)-2.0)*.072
		var variation: float=.038*sin(float(i)*1.87+curl*3.0)
		var mat: Material=shine if i in [1,3] else main
		_strand(root,"FacetedBackHairPanel"+str(i),mat,
			Vector3(x,1.987,.151+absf(x)*.15),
			tip_y+variation,1.0 if i%2==0 else -1.0,
			.065,curl, x*.14)

static func _side_framing(root: Node3D,main: Material,shine: Material,
		tip_y: float,curl: float,wide: float=.047) -> void:
	for side in [-1.0,1.0]:
		var name: String="Left" if side<0.0 else "Right"
		_strand(root,"Faceted"+name+"HairFrame",main,
			Vector3(side*.172,1.968,-.022),
			tip_y,side,wide,curl,side*.026)
		_strand(root,"Fine"+name+"HairUnderlayer",shine,
			Vector3(side*.189,1.939,.046),
			tip_y+.082,side,wide*.62,curl,side*.011)

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
		_strand(root,"SweptLowPolyTop"+str(i),
			shine if i==1 else main,
			Vector3(x-side*.085,2.033,-.057),
			1.925,side,.055,curl,side*(.073+.009*float(i)))

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
			var bun:=ART.orb(root,Vector3(0,1.925,.210),
				Vector3(.272,.205,.218),deep,12)
			bun.name="TiedLowHairBun"
			for side in [-1.0,1.0]:
				_braid(root,hair,shine,side,
					Vector3(side*.126,1.962,.158),1.68,curl)
		"ponytail":
			var knot:=ART.orb(root,Vector3(0,1.949,.200),
				Vector3(.120,.105,.118),deep,10)
			knot.name="LowPonytailRootTie"
			for i in range(3):
				_strand(root,"LongPonytailTail"+str(i),
					shine if i==1 else hair,
					Vector3((float(i)-1.0)*.046,1.914,.224),
					lerpf(1.32,1.48,1.0-gene_length),
					1.0,.060,curl,(float(i)-1.0)*.026)
			_side_framing(root,hair,shine,1.81,curl,.028)
		"swept":
			_swept_top(root,hair,shine,curl,-1.0)
			_side_framing(root,hair,shine,1.817,curl,.024)
		"shaggy":
			_swept_top(root,hair,shine,curl,1.0)
			_back_panels(root,hair,deep,1.77,curl)
			_side_framing(root,hair,shine,1.755,curl,.036)
		"curly_crop":
			# The seven long, identical downward locks used to form a
			# hovering black dinner-plate over the head in the side-view QA.
			# Sculpt small overlapping polygonal curls around a rounded crown,
			# with inherited volume and no new physical collision bodies.
			var density: float=lerpf(.89,1.10,
				GENES.value(genome,"hair_volume"))
			for row in range(3):
				var count: int=8 if row==0 else 7 if row==1 else 5
				var radius: float=.170-.053*float(row)
				for i in range(count):
					var phase: float=TAU*(float(i)+.28*float(row))/float(count)
					var center:=Vector3(
						cos(phase)*radius,
						2.018+.019*float(row)+.008*sin(phase*2.7+float(row)),
						-.024+sin(phase)*radius*.74)
					var curl_mesh:=ART.orb(root,center,
						Vector3(.050,.040,.048)*density,
						shine if i%5==0 else hair,9)
					curl_mesh.name="TightFacetedCurl"+str(row)+"_"+str(i)
					curl_mesh.set_meta("grown_from_original_face",true)
					curl_mesh.set_meta("no_new_collision",true)
		_:
			_swept_top(root,hair,deep,curl,1.0)
			if style=="crop":
				# The bald scalp cap remains the crown; the short fringe
				# adds an intentionally asymmetrical temple silhouette.
				_side_framing(root,hair,shine,1.88,curl,.017)
	return root
