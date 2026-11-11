extends CharacterBody3D
## A physical inhabitant, targetable with the player's normal world ray.
## Existing authored characters retain their landmarks; village citizens
## physically navigate based on independent simulated economic/social actions.
const ART = preload("res://scripts/art.gd")

var npc_id: String = ""
var display_name: String = ""
var role: String = ""
var world
var definition: Dictionary = {}
var route: NavigationAgent3D
var current_goal: Vector3 = Vector3.ZERO
var last_sim_action: String = ""
var replan_elapsed: float = 0.0
var blocked_seconds: float = 0.0
var mobile: bool = false

func setup(owner_world: Node3D, data: Dictionary) -> void:
	world = owner_world
	definition = data
	npc_id = String(data.get("id", ""))
	display_name = String(data.get("name", "Traveler"))
	role = String(data.get("role", "Wanderer"))
	mobile = data.has("home") and data.has("work")
	var spot: Array = data.get("position", [0.0, 0.0])
	var x: float = float(spot[0])
	var z: float = float(spot[1])
	position = Vector3(x,owner_world.height_at(x,z)+.06,z)
	rotation.y = float(data.get("yaw", 0.0))
	name = "NPC_" + npc_id

func is_talkable() -> bool:
	return not npc_id.is_empty()

func _ready() -> void:
	if mobile:
		collision_layer = 32
		collision_mask = 16
		floor_snap_length = 0.35
		var physical := CollisionShape3D.new()
		physical.name = "PhysicalCitizenCollider"
		var profile := CapsuleShape3D.new()
		profile.radius = 0.34
		profile.height = 1.75
		physical.shape = profile
		physical.position.y = 0.90
		add_child(physical)
		route = NavigationAgent3D.new()
		route.name = "CitizenNavigation"
		route.path_desired_distance = 0.75
		route.target_desired_distance = 1.1
		route.avoidance_enabled = false
		add_child(route)
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
	# Role identity belongs to the person: the same figure carries these
	# tools whether travelling, trading or standing at the workplace.
	# Do not replace every citizen with the same cone-robe silhouette.
	match npc_id:
		"ida":
			var flour:=ART.mat(Color("d2c4a1"),.98)
			var apron:=ART.box(figure,Vector3(0,.94,-.33),
				Vector3(.56,.95,.10),flour)
			apron.name="VisibleBakerApron"
			ART.cone(figure,Vector3(0,2.09,0),.27,.28,flour,.17,11)
			ART.bone(figure,Vector3(-.22,1.37,-.34),
				Vector3(.22,1.37,-.34),.03,.03,trim,7)
		"orin":
			var hide:=ART.mat(Color("775b42"),.99)
			var metal:=ART.mat(Color("737e81"),.52)
			var apron:=ART.box(figure,Vector3(0,.98,-.35),
				Vector3(.65,1.08,.13),hide)
			apron.name="VisibleSmithApron"
			ART.box(figure,Vector3(0,.71,-.42),
				Vector3(.61,.13,.18),leather)
			var hammer:=Node3D.new()
			hammer.name="VisibleSmithHammer"
			hammer.position=Vector3(.46,1.05,-.16)
			figure.add_child(hammer)
			ART.bone(hammer,Vector3(0,-.33,0),
				Vector3(0,.31,0),.048,.036,leather,8)
			ART.box(hammer,Vector3(0,.27,0),Vector3(.41,.17,.23),metal)
		"daro":
			var straw:=ART.mat(Color("b8a477"),.99)
			var brim:=ART.cone(figure,Vector3(0,2.02,0),.49,.075,
				straw,.41,14)
			brim.name="VisibleFarmerHat"
			ART.cone(figure,Vector3(0,2.14,0),.29,.23,straw,.21,12)
			var staff:=Node3D.new()
			staff.name="VisibleFarmerRake"
			staff.position=Vector3(-.54,.96,-.11)
			figure.add_child(staff)
			ART.bone(staff,Vector3(0,-.77,0),Vector3(0,1.03,0),
				.039,.029,leather,8)
			ART.box(staff,Vector3(0,1.02,0),Vector3(.47,.10,.09),trim)
		"sela":
			var purse:=ART.mat(Color("b89a61"),.93)
			var bag:=ART.box(figure,Vector3(-.47,.73,-.23),
				Vector3(.38,.45,.24),purse)
			bag.name="VisibleMerchantPouch"
			for side in [-1.0,1.0]:
				ART.bone(figure,Vector3(-.47+side*.14,1.00,-.29),
					Vector3(-.47+side*.14,.85,-.29),.023,.023,leather,7)
		"nima":
			var instrument:=ART.orb(figure,Vector3(-.22,1.03,-.40),
				Vector3(.28,.37,.11),ART.mat(Color("926849"),.91),12)
			instrument.name="VisibleBardLute"
			ART.bone(figure,Vector3(-.33,1.17,-.40),
				Vector3(.18,1.55,-.40),.065,.053,leather,9)
		"titus":
			var iron:=ART.mat(Color("7d8180"),.56)
			var shield:=ART.box(figure,Vector3(-.44,1.05,-.20),
				Vector3(.14,.83,.54),iron)
			shield.name="VisibleGuardShield"
		_:
			pass
	# A petrol-station attendant looks like a twentieth-century worker,
	# not a medieval pilgrim. A slim uniform, two separate legs and a
	# peaked cap keep the silhouette readable without an external installer.
	if npc_id=="juno":
		figure.visible=false
		var attendant:=Node3D.new()
		attendant.name="DistinctModernAttendant"
		add_child(attendant)
		var shirt:=ART.mat(Color("5c7373"),.94)
		var denim:=ART.mat(Color("485461"),.98)
		var apron:=ART.mat(Color("b2a17e"),.95)
		ART.box(attendant,Vector3(0,1.13,0),Vector3(.74,.88,.37),shirt)
		ART.box(attendant,Vector3(0,.84,-.21),Vector3(.68,.63,.08),apron)
		for side in [-1.0,1.0]:
			ART.box(attendant,Vector3(side*.19,.39,0),Vector3(.27,.79,.27),denim)
			ART.box(attendant,Vector3(side*.20,.06,-.10),Vector3(.31,.15,.46),leather)
			ART.bone(attendant,Vector3(side*.43,1.42,0),
				Vector3(side*.51,.99,-.06),.115,.081,shirt,10)
			ART.orb(attendant,Vector3(side*.52,.94,-.06),Vector3(.095,.105,.084),skin,10)
		ART.orb(attendant,Vector3(0,1.76,0),Vector3(.23,.27,.21),skin,12)
		ART.box(attendant,Vector3(0,2.04,-.03),Vector3(.51,.15,.45),denim)
		ART.box(attendant,Vector3(0,2.01,-.26),Vector3(.40,.052,.27),denim)
	var collider := StaticBody3D.new()
	collider.name = "LivingNPCConversationCollider"
	collider.collision_layer = 4 if mobile else (4 | 16)
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

func _destination_for(action: String) -> Vector3:
	var key: String = "home"
	match action:
		"work": key = "work"
		"socialize", "court", "investigate": key = "market"
	var spot: Array = definition.get(key,definition.get("position",[0.0,0.0]))
	var x: float = float(spot[0])
	var z: float = float(spot[1])
	return Vector3(x,world.height_at(x,z)+0.1,z)

func _physics_process(delta: float) -> void:
	if not mobile or route == null or world == null or world.village_sim == null: return
	var state: Dictionary = world.village_sim.people.get(npc_id,{})
	if state.is_empty(): return
	var action: String = String(state.get("last_action","rest"))
	# Destinations are consequences of the simulation, not scripted time-of-day loops.
	if last_sim_action != action:
		last_sim_action = action
		current_goal = _destination_for(action)
		replan_elapsed = 0.0
	replan_elapsed -= delta
	if replan_elapsed <= 0.0:
		route.target_position = current_goal
		replan_elapsed = 2.0
	var move_dir := Vector3.ZERO
	if NavigationServer3D.map_get_iteration_id(route.get_navigation_map()) > 0 and not route.is_navigation_finished():
		var next_point: Vector3 = route.get_next_path_position()
		move_dir = next_point - global_position
		move_dir.y = 0.0
		if move_dir.length_squared() > 0.16: move_dir = move_dir.normalized()
		else: move_dir = Vector3.ZERO
	if move_dir.length_squared() > 0.01:
		var origin: Vector3 = global_position + Vector3.UP * 0.85
		var obstacle: Dictionary = get_world_3d().direct_space_state.intersect_ray(
			PhysicsRayQueryParameters3D.create(origin,origin+move_dir*1.4,16,[get_rid()]))
		if not obstacle.is_empty():
			var normal: Vector3 = obstacle["normal"]
			var along: Vector3 = Vector3(-normal.z,0.0,normal.x)
			if along.dot(move_dir)<0.0: along = -along
			move_dir = along.normalized()
	velocity.x = move_dir.x * 1.55
	velocity.z = move_dir.z * 1.55
	if is_on_floor(): velocity.y = -0.1
	else: velocity.y -= 16.0*delta
	move_and_slide()
	if move_dir.length_squared() > 0.01:
		rotation.y = lerp_angle(rotation.y,atan2(-move_dir.x,-move_dir.z),minf(1.0,delta*5.0))
		blocked_seconds = blocked_seconds+delta if Vector2(velocity.x,velocity.z).length()<0.05 else 0.0
	else:
		blocked_seconds = 0.0
	if is_on_wall() or blocked_seconds>2.0:
		replan_elapsed = 0.0
		blocked_seconds = 0.0
