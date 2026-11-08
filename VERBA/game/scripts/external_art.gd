extends RefCounted
## Opt-in author-supplied CC0 GLBs, normalized to a chosen height in meters.
static func attach_scaled(parent: Node3D, resource_path: String, desired_height: float) -> bool:
	if not ResourceLoader.exists(resource_path): return false
	var resource: Resource = load(resource_path)
	if not (resource is PackedScene): return false
	var instance: Node3D = (resource as PackedScene).instantiate() as Node3D
	if instance == null: return false
	parent.add_child(instance)
	instance.name = "CC0ImportedArt"
	var minimum: float = INF
	var maximum: float = -INF
	var inv: Transform3D = instance.global_transform.affine_inverse()
	for child in instance.find_children("*", "MeshInstance3D", true, false):
		var mesh_node := child as MeshInstance3D
		if mesh_node.mesh == null: continue
		var bounds := mesh_node.mesh.get_aabb()
		for ix in range(2):
			for iy in range(2):
				for iz in range(2):
					var local := bounds.position + bounds.size * Vector3(float(ix), float(iy), float(iz))
					var in_root: Vector3 = inv * (mesh_node.global_transform * local)
					minimum = minf(minimum, in_root.y)
					maximum = maxf(maximum, in_root.y)
	if minimum == INF or maximum - minimum < 0.01:
		instance.queue_free()
		return false
	var factor: float = desired_height / (maximum - minimum)
	instance.scale = Vector3.ONE * factor
	instance.position.y = -minimum * factor
	return true
