extends SceneTree
## Geometry QA for the *actual* held book, not a screenshot mockup.
## The old build had a detached vellum canopy, inverted face normals,
## ink floating above the paper and a completely flat turning QuadMesh.
const VISUAL = preload("res://scripts/grimoire_visual.gd")

func _initialize() -> void:
	var binding: Node3D = VISUAL.make_open_binding()
	root.add_child(binding)
	var left := binding.find_child("SlightlyCurledVellumLeft",true,false) as MeshInstance3D
	var right := binding.find_child("SlightlyCurledVellumRight",true,false) as MeshInstance3D
	if left == null or right == null:
		_fail("Missing separate left/right 3D parchment wings")
		return
	for wing in [left,right]:
		var arrays: Array = wing.mesh.surface_get_arrays(0)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		if vertices.size() < 1000 or normals.size() != vertices.size():
			_fail("The paper must be a proper tessellated, lit surface")
			return
		for v in vertices:
			if v.z < .036 or v.z > .046:
				_fail("Physical leaf floats above the book's bound signatures")
				return
			if wing == left and v.x > -.026:
				_fail("Left wing crossed the center gutter")
				return
			if wing == right and v.x < .026:
				_fail("Right wing crossed the center gutter")
				return
		for n in normals:
			if n.z < .90:
				_fail("Parchment face has reversed/unlit normals")
				return
	var hinge: Node3D = VISUAL.make_turning_leaf()
	root.add_child(hinge)
	var sheet := hinge.get_node("PageTurningVellumSheet") as MeshInstance3D
	if sheet == null or not (sheet.mesh is ArrayMesh):
		_fail("Page-turn leaf is still a flat QuadMesh, not authored parchment")
		return
	if hinge.position.z < .04 or hinge.position.z > .055:
		_fail("The page hinge is visibly detached from the binding")
		return
	var extent: AABB = sheet.mesh.get_aabb()
	if extent.size.x < .70 or extent.size.y < 1.0 or extent.size.z < .003:
		_fail("Turned leaf has the wrong dimensions or no visible curvature")
		return
	if hinge.position.z + extent.position.z < .047 or hinge.position.z + extent.end.z > .060:
		_fail("Turned leaf intersects the leaf block or hovers too high")
		return
	for side in [-1.0,1.0]:
		var ink_z: float = .046
		for u in [.15,.45,.80]:
			var paper_z: float = VISUAL._page_vertex(side,u,.5).z
			if paper_z >= ink_z or ink_z-paper_z > .010:
				_fail("3D ink is buried or visibly floating above paper")
				return
	print("PASS: physical grimoire signature/leaf clearance, correct paired normals, ink contact and curved two-sided page turn")
	quit(0)

func _fail(reason: String) -> void:
	push_error(reason)
	quit(1)
