extends Node3D
## A physical inhabitant, targetable with the player's normal world ray.
## These first two NPCs are stationary until the schedule/AI milestone;
## neither is a fake menu accessed from anywhere on the map.
const ART = preload("res://scripts/art.gd")

var npc_id: String = ""
var display_name: String = ""
var role: String = ""
var world
var definition: Dictionary = {}

func setup(owner_world: Node3D, data: Dictionary) -> void:
	world = owner_world
	definition = data
	npc_id = String(data.get("id", ""))
	display_name = String(data.get("name", "Traveler"))
	role = String(data.get("role", "Wanderer"))
	var spot: Array = data.get("position", [0.0, 0.0])
	var x: float = float(spot[0])
	var z: float = float(spot[1])
	position = Vector3(x,owner_world.height_at(x,z)+.06,z)
	rotation.y = float(data.get("yaw", 0.0))
	name = "NPC_" + npc_id

func is_talkable() -> bool:
	return not npc_id.is_empty()

func _ready() -> void:
	var figure := Node3D.new()
	figure.name = "VisibleInhabitant"
	add_child(figure)
	var cloth := ART.mat(Color(String(definition.get("robe","746c60"))),.98)
	var trim := ART.mat(Color(String(definition.get("trim","c0aa86"))),.95)
	var skin := ART.mat(Color("aa8a70"),.93)
	var leather := ART.mat(Color("463f37"),.99)
	# Worn knee-length robe, slightly flared in the wind. It has a
	# recognizable human scale from the path, not a billboard portrait.
	ART.cone(figure,Vector3(0,.85,0),.47,1.28,cloth,.26,12)
	ART.bone(figure,Vector3(0,1.37,0),Vector3(0,1.64,0),
		.23,.18,cloth,10)
	ART.orb(figure,Vector3(0,1.77,0),
		Vector3(.23,.28,.22),skin,12)
	ART.orb(figure,Vector3(0,1.94,-.017),
		Vector3(.235,.12,.23),leather,11)
	for side in [-1.0,1.0]:
		ART.bone(figure,Vector3(side*.28,1.47,0),
			Vector3(side*.42,1.03,.09),.12,.075,cloth,9)
		ART.orb(figure,Vector3(side*.42,1.00,.09),
			Vector3(.091,.12,.083),skin,10)
		ART.bone(figure,Vector3(side*.17,.31,0),
			Vector3(side*.18,.10,.06),.105,.10,leather,8)
	# Cloth mantle and a small side bag distinguish scribe from keeper.
	ART.bone(figure,Vector3(-.34,1.48,-.14),
		Vector3(.30,1.46,-.13),.065,.062,trim,7)
	if npc_id == "mara":
		ART.bone(figure,Vector3(-.54,.15,.12),
			Vector3(-.48,2.43,.16),.048,.037,leather,8)
		ART.orb(figure,Vector3(-.48,2.44,.16),
			Vector3(.075,.09,.071),trim,9)
	else:
		ART.box(figure,Vector3(.46,.89,.18),
			Vector3(.26,.38,.21),leather,
			Vector3(0,-.22,-.11))
		ART.bone(figure,Vector3(-.12,1.47,.04),
			Vector3(.50,.99,.17),.052,.045,trim,7)
	var collider := StaticBody3D.new()
	collider.name = "LivingNPCConversationCollider"
	collider.collision_layer = 4 | 16
	collider.collision_mask = 0
	collider.set_meta("npc_ref",self)
	add_child(collider)
	var capsule := CapsuleShape3D.new()
	capsule.radius = .43
	capsule.height = 1.95
	var shape := CollisionShape3D.new()
	shape.shape = capsule
	shape.position.y = 1.0
	collider.add_child(shape)
	var title := Label3D.new()
	title.name = "InWorldPersonName"
	title.text = display_name + "\n" + role
	title.font_size = 38
	title.pixel_size = .0035
	title.modulate = Color("d8cbb0")
	title.outline_modulate = Color("252b2a")
	title.outline_size = 7
	title.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	title.no_depth_test = false
	title.position = Vector3(0,2.29,0)
	add_child(title)
