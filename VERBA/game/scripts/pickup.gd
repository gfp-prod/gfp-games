extends Node3D
const ART = preload("res://scripts/art.gd")
var item_type: String = "stone"
var word: String = ""
var phase := 0.0
var world

func setup(w: Node3D, kind: String, word_key: String, p: Vector3) -> void:
	world=w
	item_type=kind
	word=word_key
	position=p

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
			m=ART.mat(Color("ad9b72"))
			ART.box(self,Vector3(0,.30,0),Vector3(.28,.38,.045),m,Vector3(0,.16,.15))
			ART.box(self,Vector3(0,.29,.03),Vector3(.01,.29,.005),ART.mat(Color("5f4a36")))
			ART.orb(self,Vector3(.0,.48,.04),Vector3(.06,.04,.02),ART.mat(Color("743c34")))
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
			ART.box(self,Vector3(0,.34,0),Vector3(.23,.34,.23),ART.mat(Color("5e574a")))
			ART.orb(self,Vector3(0,.34,0),Vector3(.11,.15,.11),ART.mat(Color("dbc98b"),.45,Color("86754a")))
			ART.bone(self,Vector3(-.1,.5,0),Vector3(.1,.5,0),.018,.018,ART.mat(Color("252421")))
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
	if item_type in ["leaf","book"]:
		var light:=OmniLight3D.new()
		light.light_color=Color("d9ae65")
		light.light_energy=.3
		light.omni_range=2.0
		light.position.y=.3
		add_child(light)

func _process(delta: float) -> void:
	phase+=delta
	if item_type=="leaf":
		rotation.y=sin(phase*.8)*.15
		position.y=world.height_at(position.x,position.z)+sin(phase*1.5)*.08
