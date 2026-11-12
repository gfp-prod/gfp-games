extends RefCounted
## Distinctive, continuous low-poly face planes for the existing animated
## citizens. Face anatomy is cut from one mesh rather than protruding spheres.
## No change to gameplay, capsule dimensions, hair/occupation IDs or dialogue.
const ART=preload("res://scripts/art.gd")

static func _face_depth(x: float, y: float) -> float:
	# Mathematically follow the original ellipsoidal head, then sculpt
	# cheekbones, sockets and a central nose from continuous vertices.
	# Center (0,1.77,0), radii (.21,.245,.195), facing negative local Z.
	var nx: float=x/.215
	var ny: float=(y-1.77)/.247
	var shell: float=-.196*sqrt(maxf(.012,1.0-nx*nx-ny*ny))
	var nose: float=-.061*exp(-pow(x/.043,2.0)
		-pow((y-1.724)/.076,2.0))
	var cheek: float=-.009*exp(-pow((absf(x)-.115)/.057,2.0)
		-pow((y-1.711)/.060,2.0))
	var eye: float=.008*exp(-pow((absf(x)-.086)/.044,2.0)
		-pow((y-1.792)/.028,2.0))
	var lip: float=-.006*exp(-pow(x/.076,2.0)
		-pow((y-1.663)/.019,2.0))
	return shell+nose+cheek+eye+lip-.002

static func _make_integrated_face(root: Node3D, skin: Material) -> void:
	var tool:=SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var base_color: Color=(skin as StandardMaterial3D).albedo_color
	var columns: int=22
	var rows: int=22
	for yi in range(rows):
		for xi in range(columns):
			var x0: float=lerpf(-.183,.183,float(xi)/float(columns))
			var x1: float=lerpf(-.183,.183,float(xi+1)/float(columns))
			var y0: float=lerpf(1.575,1.931,float(yi)/float(rows))
			var y1: float=lerpf(1.575,1.931,float(yi+1)/float(rows))
			# The elliptical mesh fades inside the head along its outer
			# rim. No separate cardboard rectangle around the portrait.
			var pts: Array[Vector3]=[
				Vector3(x0,y0,_face_depth(x0,y0)),
				Vector3(x0,y1,_face_depth(x0,y1)),
				Vector3(x1,y0,_face_depth(x1,y0)),
				Vector3(x1,y1,_face_depth(x1,y1))
			]
			for j in [0,1,2,1,3,2]:
				var p: Vector3=pts[j]
				var cheek_light: float=clampf(.022+(p.y-1.575)*.07,0.0,.055)
				var pigment: Color=base_color.lerp(Color.WHITE,cheek_light)
				tool.set_color(pigment)
				tool.set_uv(Vector2((p.x+.183)*2.73,(p.y-1.575)*2.82))
				tool.add_vertex(p)
	tool.generate_normals()
	var material: StandardMaterial3D=(skin as StandardMaterial3D).duplicate()
	material.albedo_color=Color.WHITE
	material.vertex_color_use_as_albedo=true
	material.roughness=.98
	var face:=MeshInstance3D.new()
	face.name="IndividualIntegratedFaceMesh"
	face.mesh=tool.commit()
	face.material_override=material
	root.add_child(face)

static func finish(figure: Node3D, person: String,
		skin: Material, hair: Material, brow: Material) -> void:
	if figure.get_node_or_null("IndividualFaceConstruction")!=null:
		return
	var root:=Node3D.new()
	root.name="IndividualFaceConstruction"
	figure.add_child(root)
	_make_integrated_face(root,skin)
	var variation: int=absi(person.hash())%4
	var eye_ink:=ART.mat(Color("352d27"),1.0)
	var lip_ink:=ART.mat(Color("6b5146"),.99)
	# Ears are modest, attached to the skull, and never decorative rings.
	# Both eyes are narrow, dark shapes tucked under modeled upper lids.
	for sign in [-1.0,1.0]:
		var ear:=ART.orb(root,Vector3(sign*.208,1.762,.007),
			Vector3(.071,.115,.076),skin,10)
		ear.name="SubtleModeledEar"
		var x: float=sign*.085
		var eye_depth: float=_face_depth(x,1.791)
		var pupil:=ART.box(root,Vector3(x,1.790,eye_depth-.009),
			Vector3(.040,.013,.009),eye_ink)
		pupil.name="SmallRecessedEye"
		var eyelid:=ART.bone(root,Vector3(x-.027,1.804,eye_depth-.006),
			Vector3(x+.027,1.806,eye_depth-.006),
			.008,.008,skin,8)
		eyelid.name="IndividualUpperEyelid"
		var brow_depth: float=_face_depth(x,1.839)
		ART.bone(root,Vector3(x-.032,1.835,brow_depth-.003),
			Vector3(x+.032,1.834,brow_depth-.003),
			.009,.009,brow,8)
	var mouth:=ART.bone(root,Vector3(-.038,1.651,_face_depth(-.038,1.651)-.005),
		Vector3(.038,1.651,_face_depth(.038,1.651)-.005),
		.006,.006,lip_ink,8)
	mouth.name="SmallNaturalLipLine"
	var scalp:=ART.orb(root,Vector3(0,1.969,.035),
		Vector3(.442,.146,.390),hair,13)
	scalp.name="NaturalHairline"
	if person in ["ida","daro"]:
		scalp.scale.y=.100
	# Individual silhouette differences use close-fitting growth and
	# restrained attached hair, never the old crown of spherical marbles.
	match person:
		"orin":
			ART.bone(root,Vector3(-.125,1.610,-.117),
				Vector3(.125,1.610,-.117),.014,.014,hair,9)
		"sela":
			var tie:=ART.orb(root,Vector3(0,1.798,.196),
				Vector3(.145,.172,.139),hair,11)
			tie.name="BoundHairAtNape"
		"mara":
			var swept:=ART.bone(root,Vector3(-.175,1.963,.015),
				Vector3(-.181,1.757,.055),.036,.024,hair,8)
			swept.name="ScribeHairAtTemple"
		"brin":
			ART.bone(root,Vector3(-.187,1.973,-.030),
				Vector3(.135,1.981,-.018),.024,.017,hair,8)
		_:
			pass
	root.set_meta("professionally_distinct_face",person)
	root.set_meta("no_new_collision",true)
	root.set_meta("facial_variation",variation)
