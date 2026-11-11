extends RefCounted
## VERBA: a single signature riverbank tree, rather than another repeated
## imported canopy.  Swept crooked trunk and hand-placed leaf curtains have
## a readable silhouette in both sunshine and moonlight.
const ART = preload("res://scripts/art.gd")

static func decorate(tree: Node3D) -> void:
	var stem := Node3D.new()
	stem.name = "WeepingStoryAsh"
	tree.add_child(stem)
	var bark: StandardMaterial3D = ART.mat(Color("5e594c"),.99)
	bark.albedo_texture = load("res://assets/textures/bark.png")
	bark.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var wood_dark := ART.mat(Color("514a43"),.98)
	var spine: Array[Vector3] = [
		Vector3(0,0,0),Vector3(.12,.72,.04),
		Vector3(-.16,1.67,.04),Vector3(.21,2.74,.10),
		Vector3(.44,3.94,-.08),Vector3(.34,5.09,.07),
		Vector3(.22,5.88,.12)
	]
	var widths: Array = [.52,.47,.39,.30,.24,.16,.08]
	for i in range(spine.size()-1):
		ART.bone(stem,spine[i],spine[i+1],widths[i],widths[i+1],
			bark,9)
	# Root buttresses make the silhouette belong to the bank; no circular
	# urn base, magic glow, or floating decorative platform.
	for j in range(8):
		var angle: float = TAU*float(j)/8.0
		var outward: Vector3 = Vector3(cos(angle),0,sin(angle))
		ART.bone(stem,Vector3(.04,.50,.02)+outward*.22,
			outward*(.80+.21*float(j%3))+Vector3.UP*.05,
			.19,.055,wood_dark,7)
	var ends: Array[Vector3] = []
	for i in range(15):
		var angle: float = TAU*float(i)/15.0
		var dir := Vector3(cos(angle),0,sin(angle))
		var height: float = 3.74 + .26*float(i%6)
		var radius: float = 2.35 + .30*float(i%4)
		var origin := Vector3(.34,height,.02)
		var p1 := origin + dir*radius*.48+Vector3.UP*(.72+float(i%3)*.11)
		var tip := origin+dir*radius+Vector3.UP*(.26-float(i%4)*.15)
		ART.bone(stem,origin,p1,.115,.067,bark,7)
		ART.bone(stem,p1,tip,.065,.023,wood_dark,7)
		ends.append(tip)
	# The hanging canopy is deliberately one mesh, so authored silhouette
	# does not mean hundreds of leaf objects or per-frame allocations.
	var curtain := MeshInstance3D.new()
	curtain.name = "TwentyHangingBranchesOfLeaves"
	curtain.mesh = make_curtain_leaves(ends)
	var leaves := ART.mat(Color("9da995"),1.0)
	leaves.vertex_color_use_as_albedo = true
	leaves.cull_mode = BaseMaterial3D.CULL_DISABLED
	curtain.material_override = leaves
	stem.add_child(curtain)

static func make_curtain_leaves(ends: Array[Vector3]) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1126
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for branch in range(ends.size()):
		var tip: Vector3 = ends[branch]
		for tassel in range(9):
			var shift := Vector3(rng.randf_range(-.33,.33),0,
				rng.randf_range(-.33,.33))
			var origin: Vector3 = tip+shift
			var fall: float = rng.randf_range(1.22,2.38)
			for leaf_id in range(15):
				var t: float = float(leaf_id)/15.0
				var center: Vector3 = origin+Vector3(
					sin(t*PI)*(.12+.08*float(tassel%2)),
					-t*fall,
					cos(t*PI*1.3)*.085)
				var lean: Vector3 = Vector3(
					rng.randf_range(-.095,.095),-.118,
					rng.randf_range(-.095,.095))
				var across := Vector3(-lean.z,0,lean.x).normalized()
				if across.length_squared() < .001:
					across=Vector3.RIGHT
				var width: float = rng.randf_range(.022,.046)
				var tip_leaf: Vector3 = center+lean
				var mid: Vector3 = center+lean*.54+Vector3.UP*.018
				var color: Color = Color("788c6f").lerp(
					Color("a99c7e"),rng.randf_range(.03,.42))
				if branch%5==0:
					color = color.lerp(Color("9b9978"),.25)
				_tri(st,center,mid+across*width,tip_leaf,color)
				_tri(st,center,tip_leaf,mid-across*width,color.darkened(.075))
	st.generate_normals()
	return st.commit()

static func _tri(st: SurfaceTool,a: Vector3,b: Vector3,c: Vector3,tint: Color) -> void:
	for v in [a,b,c]:
		st.set_color(tint)
		st.add_vertex(v)
