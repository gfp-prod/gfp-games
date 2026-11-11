extends SceneTree
## Regression gate for authored hero silhouettes used by the actual game.
const COTTAGE = preload("res://scripts/cottage_hero.gd")
const HANDS = preload("res://scripts/glove_art.gd")
const TREE = preload("res://scripts/landmark_tree.gd")

func _initialize() -> void:
	print("HERO_QA_STAGE cottage_start")
	var cottage := Node3D.new()
	root.add_child(cottage)
	COTTAGE.decorate(cottage)
	var roof := cottage.find_child("HandLaidIrregularSlateRoof",true,false) as MeshInstance3D
	var herb := cottage.find_child("BatchedWindowHerbs",true,false) as MultiMeshInstance3D
	if roof == null or herb == null:
		_fail("Cottage facade lost authored roof or window vegetation")
		return
	var roof_arrays := roof.mesh.surface_get_arrays(0)
	var roof_verts: PackedVector3Array = roof_arrays[Mesh.ARRAY_VERTEX]
	if roof_verts.size() < 1500 or roof.mesh.get_aabb().size.y < 1.5:
		_fail("Shingle silhouette became a flat or sparse placeholder")
		return
	if herb.multimesh == null or herb.multimesh.instance_count != 33:
		_fail("Batched herb planter lost its actual instances")
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
	print("PASS: batched roof/herbs, detailed bilateral gloves and authored willow silhouette")
	quit(0)

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
