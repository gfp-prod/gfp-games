extends RefCounted
## VERBA foliage color-grade.
## Original CC0 tree geometry, UVs, and alpha masks are retained.
## The supplied tree leaf bitmaps contain high-saturation salmon/orange color.
## Multiplying those images by green in the material isn't enough to remove
## that underlying chroma. Bake new pigment from luminance while keeping alpha.
## No imported tree mesh, scene UID, collision, or save identifier is changed.
static var _cache: Dictionary={}

static func _pair(kind: String, variant: int) -> Array[Color]:
	match kind:
		"autumn":
			match variant % 4:
				0: return [Color("394e3c"),Color("849278")] # old olive
				1: return [Color("594c3c"),Color("ad9068")] # golden bronze
				2: return [Color("523f39"),Color("9d715e")] # brown rust
				_: return [Color("505341"),Color("9e9673")] # fading ochre
		_:
			match variant % 3:
				0: return [Color("2e473b"),Color("7f9577")] # shaded canopy
				1: return [Color("394f3e"),Color("99a17c")] # meadow canopy
				_: return [Color("384c44"),Color("809289")] # cool riverside

static func _graded_texture(source: Texture2D,key: String,
		dark: Color,lit: Color) -> Texture2D:
	if _cache.has(key):
		return _cache[key] as Texture2D
	if source==null:
		return null
	var source_image: Image=source.get_image()
	if source_image==null:
		return source
	if source_image.is_compressed() and source_image.decompress()!=OK:
		return source
	source_image.convert(Image.FORMAT_RGBA8)
	# Leaf topology is carried by exact PNG transparency. No new raster silhouettes.
	for y in range(source_image.get_height()):
		for x in range(source_image.get_width()):
			var pixel: Color=source_image.get_pixel(x,y)
			if pixel.a<0.004:
				continue
			var luminance: float=clampf(pixel.r*.2126+pixel.g*.7152+pixel.b*.0722,0.0,1.0)
			# Retain original photographed shadows and vein detail; reset hue.
			var shading: float=clampf(.17+.95*pow(luminance,.83),.0,1.0)
			var pigment: Color=dark.lerp(lit,shading)
			pigment.a=pixel.a
			source_image.set_pixel(x,y,pigment)
	source_image.generate_mipmaps()
	var cooked: ImageTexture=ImageTexture.create_from_image(source_image)
	_cache[key]=cooked
	return cooked

static func dress_tree(imported: Node3D,kind: String,variant: int) -> void:
	var pair: Array[Color]=_pair(kind,variant)
	var tone_id: String=kind+":"+str(variant % (4 if kind=="autumn" else 3))
	for node in imported.find_children("*","MeshInstance3D",true,false):
		var surface_mesh: MeshInstance3D=node as MeshInstance3D
		if surface_mesh==null or surface_mesh.mesh==null:continue
		for surface_id in range(surface_mesh.mesh.get_surface_count()):
			var original: Material=surface_mesh.mesh.surface_get_material(surface_id)
			if not original is StandardMaterial3D:continue
			var original_mat: StandardMaterial3D=original as StandardMaterial3D
			var material_name: String=original_mat.resource_name.to_lower()
			var overlay: StandardMaterial3D=original_mat.duplicate() as StandardMaterial3D
			if material_name.contains("leav") or material_name.contains("foliage") or surface_id==1:
				overlay.albedo_color=Color.WHITE
				overlay.roughness=.98
				overlay.metallic=0.0
				if original_mat.albedo_texture!=null:
					var key: String=material_name+":"+tone_id
					overlay.albedo_texture=_graded_texture(original_mat.albedo_texture,
						key,pair[0],pair[1])
				else:
					overlay.albedo_color=pair[1]
				surface_mesh.set_surface_override_material(surface_id,overlay)
			elif material_name.contains("bark") or surface_id==0:
				# Bleach-white imported birch bark otherwise blows out at noon.
				overlay.albedo_color=original_mat.albedo_color * Color("a69f8d")
				overlay.roughness=.97
				overlay.metallic=0.0
				surface_mesh.set_surface_override_material(surface_id,overlay)
