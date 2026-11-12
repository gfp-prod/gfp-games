extends RefCounted
## One shared, deterministic woven-fabric texture for the entire village.
## The old NPC robe sampled aged vellum (parchment), making cloth resemble
## a shiny flat skin. This coarse linen/heather weave reads on faceted
## silhouettes without the high-frequency noise that shimmers at distance.
const ART=preload("res://scripts/art.gd")
static var _woven: ImageTexture

static func woven_texture() -> ImageTexture:
	if _woven!=null:
		return _woven
	var picture:=Image.create(128,128,false,Image.FORMAT_RGB8)
	for y in range(128):
		for x in range(128):
			# Alternating warp and weft cast shallow, directional shadows.
			# Dust flecks and thread-width irregularities stop the pattern
			# from looking like sterile vector crosshatching.
			var warp: float=.048 if x%6 in [0,1] else (-.020 if x%6==3 else .011)
			var weft: float=.036 if y%7 in [0,1] else (-.019 if y%7==4 else .006)
			var speck: float=(float(posmod(x*97+y*61+x*y*13,137))/137.0-.5)*.045
			var slub: float=-.058 if (x+y*3)%53==0 else 0.0
			var shade: float=clampf(.845+warp+weft+speck+slub,.72,.955)
			picture.set_pixel(x,y,Color(shade,shade*.982,shade*.958))
	_woven=ImageTexture.create_from_image(picture)
	return _woven

static func worn_linen(color: Color, roughness: float=.985) -> StandardMaterial3D:
	var material:=ART.mat(color,roughness)
	material.albedo_texture=woven_texture()
	material.uv1_triplanar=true
	material.uv1_scale=Vector3(1.25,1.25,1.25)
	material.metallic=0.0
	return material
