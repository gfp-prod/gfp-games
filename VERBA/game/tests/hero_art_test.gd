extends SceneTree
## Regression gate for authored hero silhouettes used by the actual game.
const STORY = preload("res://scripts/storybook_house.gd")
const HANDS = preload("res://scripts/glove_art.gd")
const TREE = preload("res://scripts/landmark_tree.gd")

func _initialize() -> void:
	print("HERO_QA_STAGE cottage_start")
	var roof: ArrayMesh = STORY.make_roof()
	var walls: ArrayMesh = STORY.make_wall_shell()
	var roofs: PackedVector3Array = roof.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var facades: PackedVector3Array = walls.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var roof_bounds: AABB = roof.get_aabb()
	var wall_bounds: AABB = walls.get_aabb()
	if roofs.size() < 4000 or roof_bounds.size.x < 6.3 or roof_bounds.size.y < 2.6:
		_fail("Crooked slate roof lost its real pitched, tessellated geometry")
		return
	if facades.size() < 30 or wall_bounds.size.y < 5.2:
		_fail("Storybook cottage needs a modeled story-and-gable silhouette")
		return
	# These faces were reversed on the first render, leaving the entire roof
	# artificially black despite a correct mesh silhouette.
	var roof_normals: PackedVector3Array = roof.surface_get_arrays(0)[Mesh.ARRAY_NORMAL]
	var wrong: int = 0
	for n in roof_normals:
		if n.y < .20:
			wrong += 1
	if wrong > int(float(roof_normals.size())*.03):
		_fail("Roof normals face down: lighting will make the hero cottage black")
		return
	var hat: ArrayMesh = STORY._turret_hat()
	var hat_normals: PackedVector3Array = hat.surface_get_arrays(0)[Mesh.ARRAY_NORMAL]
	for n in hat_normals:
		if n.y < .15:
			_fail("Turret roof is backfacing the sky")
			return
	var turret: ArrayMesh = STORY._turret_body()
	var turret_vertices: PackedVector3Array = turret.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var turret_normals: PackedVector3Array = turret.surface_get_arrays(0)[Mesh.ARRAY_NORMAL]
	for idx in range(turret_vertices.size()):
		var radial := Vector2(turret_vertices[idx].x,turret_vertices[idx].z).normalized()
		var facing := Vector2(turret_normals[idx].x,turret_normals[idx].z)
		if radial.dot(facing) < .2:
			_fail("Turret masonry is inward-facing and invisible from the ground")
			return
	print("HERO_QA_STAGE gloves_start")
	var gloves := Node3D.new()
	root.add_child(gloves)
	HANDS.add_book_hands(gloves)
	for name in ["LeftHandOnBinding","RightHandOnBinding"]:
		var arm := gloves.find_child(name,true,false)
		if arm == null:
			_fail("Missing supported book grip: "+name)
			return
		var skin := arm.find_child("SculptedLeatherPalmAndFingers",true,false) as MeshInstance3D
		if skin == null or skin.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX].size() < 400:
			_fail("Hand regressed to spheres or cylinder rods: "+name)
			return
	print("HERO_QA_STAGE tree_start")
	var tree := Node3D.new()
	root.add_child(tree)
	TREE.decorate(tree)
	var fronds := tree.find_child("TwentyHangingBranchesOfLeaves",true,false) as MeshInstance3D
	if fronds == null or fronds.mesh.get_aabb().size.y < 2.0 or fronds.mesh.get_aabb().size.x < 3.0:
		_fail("Signature weeping-tree silhouette lost its spatial extent")
		return
	print("HERO_QA_STAGE completed")
	print("PASS: crooked roof and peaked walls, detailed gloves and authored willow silhouette")
	quit(0)

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
