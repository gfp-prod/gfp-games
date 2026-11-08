from pathlib import Path
p=Path(__file__).resolve().parents[1]/'scripts'/'world.gd'
s=p.read_text()
s=s.replace('const ART = preload("res://scripts/art.gd")','const ART = preload("res://scripts/art.gd")\nconst FOLIAGE = preload("res://scripts/foliage.gd")')
s=s.replace('build_water()\n\tmagic=', 'build_water()\n\tFOLIAGE.populate_grass(self)\n\tFOLIAGE.populate_ferns(self)\n\tFOLIAGE.populate_litter(self)\n\tmagic=')
s=s.replace('stone_mat=textured("res://assets/textures/stone.png",Color("a29d86"))','stone_mat=textured("res://assets/textures/stone.png",Color("e5e0d4"))')
s=s.replace('bark_mat=textured("res://assets/textures/bark.png",Color("86715e"))','bark_mat=textured("res://assets/textures/bark.png",Color("d4c2a8"))')
s=s.replace('bark_dark=textured("res://assets/textures/bark.png",Color("554c45"))','bark_dark=textured("res://assets/textures/bark.png",Color("a99e91"))')
start=s.index('func textured(')
end=s.index('func setup_atmosphere()',start)
s=s[:start]+'''func textured(path: String, tint: Color) -> StandardMaterial3D:
	var m := ART.mat(tint)
	var tex: Texture2D = load(path)
	if tex != null: m.albedo_texture=tex
	var normal_path := path.replace(".png", "_normal.png")
	if ResourceLoader.exists(normal_path):
		m.normal_enabled=true
		m.normal_texture=load(normal_path)
	m.uv1_triplanar=true
	m.uv1_scale=Vector3(2.4,2.4,2.4)
	m.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	return m

''' +s[end:]
s=s.replace('e.ambient_light_energy=.85','e.ambient_light_energy=1.05')
s=s.replace('e.fog_density=.0045','e.fog_density=.0032')
s=s.replace('light_node.light_energy=1.75','light_node.light_energy=1.9')
start=s.index('\tvar m:=StandardMaterial3D.new()',s.index('func build_terrain()'))
end=s.index('\tground.material_override=m',start)
s=s[:start]+'''\t# World-space multi-material shader. Fixes the missing ground_detail.png in v0.5.
	var m:=ShaderMaterial.new()
	m.shader=load("res://assets/materials/terrain.gdshader")
	m.set_shader_parameter("meadow_tex",load("res://assets/textures/meadow_ground.png"))
	m.set_shader_parameter("forest_tex",load("res://assets/textures/woodland_ground.png"))
	m.set_shader_parameter("amber_tex",load("res://assets/textures/amber_ground.png"))
	m.set_shader_parameter("silt_tex",load("res://assets/textures/river_silt.png"))
''' +s[end:]
s=s.replace('material.albedo_texture=load("res://assets/textures/ground_detail.png")','material.albedo_texture=load("res://assets/textures/earth_path.png")')
# actual trees
start=s.index('func spawn_tree(')
end=s.index('func build_scatter()',start)
s=s[:start]+'''func spawn_tree(p: Vector3,kind: String,scale_factor: float=1.0) -> Node3D:
	# Irregular tapered bole, three-dimensional crown, twigs and articulated leaves.
	# Authored canopy gaps keep the animal silhouettes visible through the grove.
	var node:=Node3D.new()
	node.name="%sTree" % kind.capitalize()
	node.position=p
	node.scale=Vector3.ONE*scale_factor
	node.set_meta("kind",kind)
	node.set_meta("wetness",0.0)
	node.set_meta("burning",false)
	node.set_meta("growth",1.0)
	add_child(node)
	flora.append(node)
	var r:=RandomNumberGenerator.new()
	r.seed=int(absf(p.x*261.7+p.z*991.2))+rng.randi_range(0,8000)
	var trunk_h:float=7.5 if kind=="pine" else 5.0 if kind!="dead" else 8.7
	var dark:Material=bark_dark if kind=="pine" or kind=="dead" else bark_mat
	var trunk_width:float = .31 if kind=="pine" else .45
	ART.bone(node,Vector3(0,-.1,0),Vector3(.09,trunk_h,0),trunk_width,trunk_width*.38,dark,11)
	for root_i in range(5):
		var a:float=TAU*float(root_i)/5.0+r.randf_range(-.25,.25)
		ART.bone(node,Vector3(.06,.54,0),Vector3(cos(a)*r.randf_range(.65,1.2),.02,sin(a)*r.randf_range(.65,1.2)),.13,.018,dark,6)
	var ends:Array=[]
	if kind == "pine":
		for level in range(7):
			var f:float=float(level)/7.0
			var height:float=1.8+f*6.3
			for branch_i in range(8):
				var angle:float=TAU*float(branch_i)/8.0+f*2.5
				var reach:float=3.0*(1.0-f*.82)*r.randf_range(.78,1.14)
				var tip:=Vector3(cos(angle)*reach,height-.35+f*.25,sin(angle)*reach)
				ART.bone(node,Vector3(.05,height,0),tip,.13*(1.0-f*.5),.026,dark,7)
				ends.append(tip)
		FOLIAGE.make_conifer_needles(node,ends,r.randi())
	else:
		for b in range(7):
			var theta:float=TAU*float(b)/7.0+r.randf_range(-.25,.25)
			var start:=Vector3(.07,trunk_h*r.randf_range(.52,.78),0)
			var end:=Vector3(cos(theta)*r.randf_range(2.1,3.6),trunk_h+r.randf_range(-.3,1.9),sin(theta)*r.randf_range(1.9,3.45))
			ART.bone(node,start,end,.20,.045,dark,8)
			for twig in range(3):
				var twig_theta:float=theta+r.randf_range(-.75,.75)
				var twig_tip:=end+Vector3(cos(twig_theta)*r.randf_range(.45,1.4),r.randf_range(-.25,1.1),sin(twig_theta)*r.randf_range(.45,1.5))
				ART.bone(node,end,twig_tip,.07,.015,dark,6)
				ends.append(twig_tip)
		if kind!="dead":FOLIAGE.make_broadleaf_crown(node,ends,kind,r.randi())
	var collider:=StaticBody3D.new()
	collider.name="TrunkCollider"
	collider.collision_layer=5
	collider.collision_mask=0
	collider.set_meta("flora_ref",node)
	var shape:=CollisionShape3D.new()
	var cylinder:=CylinderShape3D.new()
	cylinder.height=trunk_h*.85
	cylinder.radius=trunk_width
	shape.shape=cylinder
	shape.position.y=trunk_h*.42
	collider.add_child(shape)
	node.add_child(collider)
	return node

''' +s[end:]
# Remove cheap spiky grass or stone scatter; replace with spaced stones/saplings and use foliage for grass.
start=s.index('func build_scatter(')
end=s.index('func setup_rain()',start)
s=s[:start]+'''func build_scatter() -> void:
	# Rocks grow in groups beside gullies and old masonry, not a random grid of props.
	var mossy := textured("res://assets/textures/moss.png",Color("d5d9c7"))
	for cluster in [Vector2(-15,-19),Vector2(-31,11),Vector2(22,-27),Vector2(50,37),Vector2(-44,-36),Vector2(9,-51)]:
		for i in range(rng.randi_range(4,9)):
			var x:float=cluster.x+rng.randf_range(-4.5,4.5)
			var z:float=cluster.y+rng.randf_range(-4.5,4.5)
			var width:float=rng.randf_range(.25,1.2)
			ART.stone(self,Vector3(x,height_at(x,z)+.18*width,z),Vector3(width,width*rng.randf_range(.5,.95),width*rng.randf_range(.65,1.4)),stone_mat if i%3 else mossy)
	for z in range(-54,56,8):
		var x:float=stream_x(float(z))
		for side in [-1,1]:
			var px:float=x+float(side)*rng.randf_range(2.7,5.1)
			ART.stone(self,Vector3(px,height_at(px,float(z))+.1,float(z)),Vector3(.56,.32,.48),stone_mat)
	# One intentionally placed log: richer silhouette, textured bark, branching roots.
	var log:=Node3D.new();log.name="FallenSplitOak"
	log.position=Vector3(-4,height_at(-4,-18),-18)
	add_child(log)
	ART.bone(log,Vector3(-2,.43,0),Vector3(2,.54,1.3),.43,.32,bark_mat,12)
	for i in range(6):
		var t:float=float(i)/6.0
		ART.bone(log,Vector3(t*3.2-1.7,.5,t*.9),Vector3(t*3.2-1.9,.35,t*.9+1.35),.095,.014,bark_dark,7)

''' +s[end:]
s=s.replace('var wood=textured("res://assets/textures/wood.png",Color("c7ab86"))','var wood=textured("res://assets/textures/wood.png",Color("e8d3b0"))')
s=s.replace('Vector3(5.8,.26,3.15),bark_dark','Vector3(5.8,.26,3.15),textured("res://assets/textures/roof_slate.png",Color("e3e2dc"))')
# ensure code gets written
p.write_text(s)
print('Patched',p)
