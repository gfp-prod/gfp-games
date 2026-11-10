extends Node3D
const ART = preload("res://scripts/art.gd")
var item_type: String = "stone"
var word: String = ""
var phase := 0.0
var world
# Stable keys prevent collected ambient loot from magically respawning.
# Dropped loot uses a separately assigned serial, not its coordinates.
var persistent_id: String = ""
var is_dropped: bool = false

func setup(w: Node3D, kind: String, word_key: String, p: Vector3,
		key: String = "", dropped: bool = false) -> void:
	world=w
	item_type=kind
	word=word_key
	position=p
	is_dropped=dropped
	persistent_id = key if not key.is_empty() else (
		"world:%s:%s:%d:%d" % [kind, word_key, roundi(p.x * 100.0), roundi(p.z * 100.0)])

func _ready() -> void:
	var m=ART.mat(Color("a39678"))
	match item_type:
		"book":
			# An actual bound three-dimensional volume, not a glowing menu card.
			var volume: PackedScene = load("res://assets/models/authored/Grimoire_Closed.glb")
			var book_mesh: Node3D = volume.instantiate()
			book_mesh.name = "FoundLatinVolume"
			book_mesh.scale = Vector3.ONE * 0.44
			book_mesh.rotation_degrees = Vector3(0,22,-7)
			book_mesh.position = Vector3(0,0.23,0)
			add_child(book_mesh)
		"leaf":
			# Discovered grammar is a sealed physical manuscript scroll.
			# The old thin glowing yellow card hovered like a debug icon.
			var paper := StandardMaterial3D.new()
			paper.albedo_texture=load("res://assets/textures/authored/vellum_cream.png")
			paper.albedo_color=Color("c4b8a8")
			paper.roughness=1.0
			ART.bone(self,Vector3(-.18,.16,0),Vector3(.18,.16,0),
				.072,.072,paper,14)
			var binding := ART.mat(Color("584032"),.94)
			for x in [-.115,.115]:
				ART.bone(self,Vector3(x-.015,.16,0),Vector3(x+.015,.16,0),
					.078,.078,binding,12)
			var seal := ART.mat(Color("753f32"),.75)
			ART.orb(self,Vector3(.0,.20,.064),Vector3(.053,.032,.018),seal,12)
		"stone": ART.stone(self,Vector3(0,.18,0),Vector3(.22,.16,.27),ART.mat(Color("62665e")))
		"herb":
			ART.bone(self,Vector3(0,.07,0),Vector3(0,.55,0),.024,.008,ART.mat(Color("66805a")))
			for i in range(5):
				ART.orb(self,Vector3(sin(i*2.4)*.15,.15+i*.07,cos(i*2.4)*.15),Vector3(.13,.045,.065),ART.mat(Color("688c66")))
		"amber": ART.orb(self,Vector3(0,.22,0),Vector3(.15,.20,.11),ART.mat(Color("b77b3d"),.3,Color("774719")))
		"torch":
			ART.bone(self,Vector3(0,.13,0),Vector3(0,.68,0),.065,.048,ART.mat(Color("574332")))
			ART.orb(self,Vector3(0,.72,0),Vector3(.12,.15,.1),ART.mat(Color("e7a44f"),.4,Color("ae4b17")))
		"lantern":
			# Old model was literally a gray cube floating near the first
			# Latin lesson. Give even loose loot a readable crafted silhouette.
			var old_iron: Material = ART.mat(Color("4d4c42"),.65)
			var tinted_glass: Material = ART.mat(Color("b4a17c"),.37,
				Color("3e2d1a"))
			for y in [.165,.525]:
				ART.box(self,Vector3(0,y,0),Vector3(.33,.05,.30),old_iron)
			for x in [-.145,.145]:
				for z in [-.13,.13]:
					ART.bone(self,Vector3(x,.185,z),Vector3(x,.51,z),
						.014,.014,old_iron,8)
			ART.box(self,Vector3(0,.35,0),Vector3(.24,.28,.21),tinted_glass)
			ART.bone(self,Vector3(0,.56,0),Vector3(0,.67,0),
				.025,.022,old_iron,8)
			ART.bone(self,Vector3(-.13,.67,0),Vector3(.13,.67,0),
				.02,.02,old_iron,8)
	var body:=StaticBody3D.new()
	body.collision_layer=4
	body.collision_mask=0
	body.set_meta("pickup_ref",self)
	add_child(body)
	var s:=SphereShape3D.new()
	s.radius=.35
	var c:=CollisionShape3D.new()
	c.shape=s
	c.position.y=.30
	body.add_child(c)
	# Avoid ten costly point lights and cheap video-game glow around paper.
	# Use one subtle unlit wax emblem, with discoverability from interaction.

func _process(delta: float) -> void:
	# Collected physical loot stays on the earth; it does not levitate in
	# a looping debug-pickup animation. Kept for future authored motion.
	phase += delta
