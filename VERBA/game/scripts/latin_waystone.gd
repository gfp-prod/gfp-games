extends Node3D
## A diegetic wayfinder. The stone already exists in the landscape; Mara's
## correctly understood Latin reveals its direction. No new save authority:
## the existing witnessed social topic is the only source of truth.
const ART = preload("res://scripts/art.gd")
var world
var revealed: bool = false
var inscription: Label3D
var ember: OmniLight3D

func setup(owner_world: Node3D) -> void:
	world=owner_world
	name="MaraForestWaystone"
	var x: float=-10.2
	var z: float=31.0
	position=Vector3(x,owner_world.height_at(x,z)+.08,z)

func _ready() -> void:
	var stone:=StaticBody3D.new()
	stone.name="CollidableWaystone"
	stone.collision_layer=16
	stone.collision_mask=0
	add_child(stone)
	var shape:=CollisionShape3D.new()
	var rock:=BoxShape3D.new()
	rock.size=Vector3(.72,1.43,.32)
	shape.shape=rock
	shape.position=Vector3(0,.69,0)
	stone.add_child(shape)
	var granite:=ART.mat(Color("625e59"),.94)
	var edge:=ART.mat(Color("81786b"),.91)
	ART.box(stone,Vector3(0,.69,0),Vector3(.72,1.43,.32),granite)
	ART.box(stone,Vector3(0,1.36,0),Vector3(.85,.13,.41),edge)
	ART.box(stone,Vector3(0,.09,0),Vector3(1.00,.18,.50),granite)
	inscription=Label3D.new()
	inscription.name="LatinForestInscription"
	# Three short carved lines fit the slab at oblique viewing angles;
	# never use a free-facing billboard that can intersect the stone.
	inscription.text="SILVA\nTRANS\nRIVUM"
	inscription.font_size=34
	inscription.pixel_size=.0028
	inscription.modulate=Color("413b34")
	inscription.outline_modulate=Color("28251f")
	inscription.outline_size=4
	inscription.billboard=BaseMaterial3D.BILLBOARD_DISABLED
	inscription.no_depth_test=false
	# Godot Label3D's front surface normally faces +Z. This slab is read
	# from the western path (-Z), so rotate the carving toward its reader.
	inscription.rotation.y=PI
	inscription.position=Vector3(0,.81,-.176)
	add_child(inscription)
	ember=OmniLight3D.new()
	ember.name="RememberedWayGlow"
	ember.position=Vector3(0,1.04,-.32)
	ember.light_color=Color("e0c38c")
	ember.light_energy=.7
	ember.omni_range=3.2
	ember.visible=false
	add_child(ember)
	revealed=false
	update_from_knowledge()

func update_from_knowledge() -> void:
	if world==null or world.social==null or inscription==null:
		return
	var topics: Array=world.social.memory("mara").get("spoken_topics",[])
	var should_reveal: bool=topics.has("forest")
	revealed=should_reveal
	# The existing stone changes; no game UI marker is spawned in the sky.
	inscription.modulate=Color("e6d5a8") if revealed else Color("413b34")
	ember.visible=revealed

func _process(_delta: float) -> void:
	update_from_knowledge()
