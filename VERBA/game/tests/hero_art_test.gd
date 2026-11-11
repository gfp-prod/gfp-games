extends SceneTree
## Regression gate for authored hero silhouettes used by the actual game.
const STORY = preload("res://scripts/storybook_house.gd")
const ROOM = preload("res://scripts/cottage_interior.gd")
const HANDS = preload("res://scripts/glove_art.gd")
const TREE = preload("res://scripts/landmark_tree.gd")

func _initialize() -> void:
	print("HERO_QA_STAGE cottage_start")
	var floor: ArrayMesh = ROOM.make_floor_mesh()
	var floor_bounds: AABB = floor.get_aabb()
	if floor_bounds.size.x < 5.3 or floor_bounds.size.z < 4.7:
		_fail("Cottage has no full-size solid-looking interior deck")
		return
	if floor_bounds.position.y + floor_bounds.size.y < .30:
		_fail("Interior deck sits below the existing invisible floor collider")
		return
	var roof: ArrayMesh = STORY.make_roof()
	var underlay: ArrayMesh = STORY.make_roof_underlay()
	var walls: ArrayMesh = STORY.make_wall_shell()
	# A one-sided plaster skin disappears from the player's front or flank
	# even though collision blocks movement. Test the actual material flags.
	var plaster: StandardMaterial3D = STORY.make_opaque_plaster()
	if plaster.cull_mode != BaseMaterial3D.CULL_DISABLED:
		_fail("Cottage walls vanish from one side because of backface culling")
		return
	if plaster.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED or plaster.albedo_color.a < .999:
		_fail("Cottage plaster must remain fully opaque in every lighting state")
		return
	var roofs: PackedVector3Array = roof.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var facades: PackedVector3Array = walls.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var roof_bounds: AABB = roof.get_aabb()
	var wall_bounds: AABB = walls.get_aabb()
	var underlay_bounds: AABB = underlay.get_aabb()
	if underlay.surface_get_arrays(0)[Mesh.ARRAY_VERTEX].size() < 4000:
		_fail("Shingle gaps would reveal bright walls without a continuous roof liner")
		return
	if absf(roof_bounds.size.x-underlay_bounds.size.x) > .08:
		_fail("Underlay no longer follows both pitched roof slopes")
		return
	if roofs.size() < 4000 or roof_bounds.size.x < 6.3 or roof_bounds.size.y < 2.6:
		_fail("Crooked slate roof lost its real pitched, tessellated geometry")
		return
	if facades.size() < 30 or wall_bounds.size.y < 5.2:
		_fail("Storybook cottage needs a modeled story-and-gable silhouette")
		return
	# The six facade panels must cover all four directions, not merely
	# decorate the edges of a missing building.
	var panel_triangles: int = int(facades.size()/3)
	if panel_triangles < 10:
		_fail("Facade has missing exterior wall or gable triangles")
		return
	var front: int = 0
	var rear: int = 0
	var left: int = 0
	var right: int = 0
	for i in range(0,facades.size(),3):
		var center: Vector3 = (facades[i]+facades[i+1]+facades[i+2])/3.0
		if center.z > 2.49:
			front += 1
		elif center.z < -2.49:
			rear += 1
		if center.x > 2.55:
			right += 1
		elif center.x < -2.55:
			left += 1
	if mini(mini(front,rear),mini(left,right)) < 2:
		_fail("One or more of the four exterior walls is not fully modeled")
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
