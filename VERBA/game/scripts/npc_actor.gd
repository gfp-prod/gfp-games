extends CharacterBody3D
## A physical inhabitant, targetable with the player's normal world ray.
## Existing authored characters retain their landmarks; village citizens
## physically navigate based on independent simulated economic/social actions.
const ART = preload("res://scripts/art.gd")
const COSTUME = preload("res://scripts/folk_costume_finish.gd")
const PORTRAIT = preload("res://scripts/folk_portrait_finish.gd")
const ANATOMY = preload("res://scripts/npc_anatomy.gd")
const NAV_BUILDER = preload("res://scripts/navigation_builder.gd")
# Reuse existing villagers and the two physically enterable houses.
# This has no effect on save IDs, simulated spouses or work locations.
# Residents approach off-center so they do not block the front doorway.
const PHYSICAL_HOME_APPROACHES := {
	"brin": {"house":"StonecutterHouse","x":1.25},
	"daro": {"house":"MillwardHouse","x":-1.25},
	"sela": {"house":"MillwardHouse","x":1.25}
}

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
var name_label: Label3D
var left_arm: Node3D
var right_arm: Node3D
var left_leg: Node3D
var right_leg: Node3D
var harvest_sack: Node3D
var motion_clock: float = 0.0
var visual_figure: Node3D
var visual_attendant: Node3D
var previous_footstep_position: Vector3=Vector3.ZERO
var has_footstep_origin: bool=false
var distance_gait_phase: float=0.0
var gait_weight: float=0.0
var work_dwell: float = 0.0
var active_work_token: String = ""
var modular_limbs: Dictionary={}
var limb_hitboxes: Dictionary={}
var anatomy_visual_signature: String=""
var blood_emitter: CPUParticles3D
var support_visual: Node3D
var anatomy_visual_elapsed: float=0.0

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
	visual_figure=figure
	var cloth := ART.mat(Color(String(definition.get("robe","746c60"))),.98)
	# Worn linen uses the same bundled fiber grain as the study vellum,
	# tinted per profession rather than perfectly smooth plastic robes.
	cloth.albedo_texture=load("res://assets/textures/authored/aged_vellum.png")
	cloth.uv1_triplanar=true
	cloth.uv1_scale=Vector3(2.0,2.0,2.0)
	var trim := ART.mat(Color(String(definition.get("trim","c0aa86"))),.95)
	# A human should read as a particular person, not an identical tan
	# mannequin re-dressed for each job.
	var complexion: String="a98b72"
	match npc_id:
		"ida": complexion="b69b82"
		"orin": complexion="8d6c57"
		"daro": complexion="ad896b"
		"titus": complexion="997b67"
		"cass": complexion="c2a18a"
		"sela": complexion="9c745e"
		"nima": complexion="75564b"
		"lena": complexion="bb957b"
		"mara": complexion="b09a85"
		_: pass
	var skin := ART.mat(Color(complexion),.94)
	var leather := ART.mat(Color("463f37"),.99)
	# A separate torso, narrower tunic hem and jointed legs replace the
	# one-piece walking cone. Props remain on their own worker identities.
	# Twelve-sided fitted tunic with a broad shoulder and a shaped hem:
	# these surfaces replace the previous square torso and floating eyes.
	var tunic:=ART.cone(figure,Vector3(0,1.24,0),.32,.73,cloth,.275,12)
	tunic.name="TaperedVillagerTunic"
	ART.cone(figure,Vector3(0,.79,0),.36,.58,cloth,.265,12)
	ART.bone(figure,Vector3(0,1.45,0),Vector3(0,1.63,0),
		.19,.16,cloth,10)
	var head:=ART.orb(figure,Vector3(0,1.77,0),
		Vector3(.42,.49,.39),skin,13)
	head.name="ModeledInhabitantHead"
	# Individual anatomy replaces the floating eyes and identical hair
	# caps, retaining the original tested head and collision silhouette.
	var hair:=ART.mat(Color("3e302a"),.96)
	var brow:=ART.mat(Color("3a3029"),.95)
	PORTRAIT.finish(figure,npc_id,skin,hair,brow)
	for side in [-1.0,1.0]:
		var arm:=Node3D.new()
		arm.name="AnimatedLeftArm" if side<0.0 else "AnimatedRightArm"
		arm.position=Vector3(side*.345,1.49,0)
		figure.add_child(arm)
		ART.bone(arm,Vector3.ZERO,Vector3(side*.075,-.42,-.045),.116,.084,cloth,9)
		ART.orb(arm,Vector3(side*.075,-.46,-.045),Vector3(.093,.12,.088),skin,10)
		var leg:=Node3D.new()
		leg.name="AnimatedLeftLeg" if side<0.0 else "AnimatedRightLeg"
		leg.position=Vector3(side*.17,.61,.015)
		figure.add_child(leg)
		ART.bone(leg,Vector3.ZERO,Vector3(0,-.46,0),.115,.10,leather,8)
		ART.box(leg,Vector3(0,-.52,-.095),Vector3(.25,.13,.42),leather)
		var limb_arm: String="left_arm" if side<0.0 else "right_arm"
		var limb_leg: String="left_leg" if side<0.0 else "right_leg"
		modular_limbs[limb_arm]=arm
		modular_limbs[limb_leg]=leg
		_install_limb_hitbox(arm,limb_arm)
		_install_limb_hitbox(leg,limb_leg)
		if side<0.0:
			left_arm=arm
			left_leg=leg
		else:
			right_arm=arm
			right_leg=leg
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
			# A shaped cloth bib, a tied waist and a pocket replace the
			# vertical white rectangle that used to obscure the whole body.
			_make_baker_apron(figure,flour,trim)
			var bonnet:=ART.orb(figure,Vector3(0,1.989,.025),
				Vector3(.46,.24,.40),flour,12)
			bonnet.name="VisibleBakerBonnet"
			ART.bone(figure,Vector3(-.22,1.94,-.08),
				Vector3(-.20,1.75,-.10),.037,.022,flour,8)
			ART.bone(figure,Vector3(.22,1.94,-.08),
				Vector3(.20,1.75,-.10),.037,.022,flour,8)
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
			hammer.position=Vector3(.105,-.44,-.16)
			right_arm.add_child(hammer)
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
			staff.position=Vector3(-.19,-.52,-.11)
			left_arm.add_child(staff)
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
	# A real work-in-progress harvest sack belongs to the farmer, not to
	# the village's available grain stock. It becomes available only at cart.
	if npc_id=="daro":
		harvest_sack=ART.orb(figure,Vector3(0,1.16,-.37),
			Vector3(.30,.38,.29),ART.mat(Color("c6ad78"),.98),12)
		harvest_sack.name="CarriedHarvestPendingDelivery"
		harvest_sack.visible=false
	# A petrol-station attendant looks like a twentieth-century worker,
	# not a medieval pilgrim. A slim uniform, two separate legs and a
	# peaked cap keep the silhouette readable without an external installer.
	if npc_id=="juno":
		figure.visible=false
		var attendant:=Node3D.new()
		attendant.name="DistinctModernAttendant"
		add_child(attendant)
		visual_attendant=attendant
		var shirt:=ART.mat(Color("5c7373"),.94)
		var denim:=ART.mat(Color("485461"),.98)
		var apron:=ART.mat(Color("b2a17e"),.95)
		ART.box(attendant,Vector3(0,1.13,0),Vector3(.74,.88,.37),shirt)
		ART.box(attendant,Vector3(0,.84,-.21),Vector3(.68,.63,.08),apron)
		for side in [-1.0,1.0]:
			var side_name: String="left" if side<0.0 else "right"
			var modern_leg:=Node3D.new()
			modern_leg.name="ModularModern"+side_name.capitalize()+"Leg"
			modern_leg.position=Vector3(side*.19,.70,0)
			attendant.add_child(modern_leg)
			ART.box(modern_leg,Vector3(0,-.31,0),Vector3(.27,.79,.27),denim)
			ART.box(modern_leg,Vector3(side*.01,-.64,-.10),Vector3(.31,.15,.46),leather)
			modular_limbs[side_name+"_leg"]=modern_leg
			_install_limb_hitbox(modern_leg,side_name+"_leg")
			var modern_arm:=Node3D.new()
			modern_arm.name="ModularModern"+side_name.capitalize()+"Arm"
			modern_arm.position=Vector3(side*.43,1.42,0)
			attendant.add_child(modern_arm)
			ART.bone(modern_arm,Vector3.ZERO,Vector3(side*.08,-.43,-.06),.115,.081,shirt,10)
			ART.orb(modern_arm,Vector3(side*.09,-.47,-.06),Vector3(.095,.105,.084),skin,10)
			modular_limbs[side_name+"_arm"]=modern_arm
			_install_limb_hitbox(modern_arm,side_name+"_arm")
		ART.orb(attendant,Vector3(0,1.76,0),Vector3(.23,.27,.21),skin,12)
		ART.box(attendant,Vector3(0,2.04,-.03),Vector3(.51,.15,.45),denim)
		ART.box(attendant,Vector3(0,2.01,-.26),Vector3(.40,.052,.27),denim)
		COSTUME.dress_attendant(attendant)
	else:
		COSTUME.dress(figure,npc_id,cloth,trim,leather)
	# All existing authored NPCs—including the roadside attendant—use
	# individually detachable physical limb modules.
	refresh_anatomy_visuals()
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
	title.font_size = 31
	title.pixel_size = .00265
	title.modulate = Color("d8cbb0")
	title.outline_modulate = Color("252b2a")
	title.outline_size = 3
	title.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	title.no_depth_test = false
	title.position = Vector3(0,2.29,0)
	add_child(title)
	name_label=title

func _make_baker_apron(parent: Node3D, fabric: Material, tie: Material) -> void:
	# A front-facing trapezoidal cloth panel follows shoulders, waist, hem.
	# Its surface normal points toward the player (-Z); it does not add
	# collision to a character whose collider already works.
	# Three cross-sectional columns curve the cloth around a real torso,
	# keeping the bottom hem from disappearing inside the flared tunic.
	var vertices: Array[Vector3]=[
		Vector3(-.20,1.41,-.265),Vector3(0,1.41,-.34),Vector3(.20,1.41,-.265),
		Vector3(-.24,1.04,-.285),Vector3(0,1.04,-.39),Vector3(.24,1.04,-.285),
		Vector3(-.285,.55,-.248),Vector3(0,.55,-.415),Vector3(.285,.55,-.248)]
	var surface:=SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_material(fabric)
	for row in range(2):
		for column in range(2):
			var i: int=row*3+column
			for j in [i,i+1,i+3,i+1,i+4,i+3]:
				surface.add_vertex(vertices[j])
	surface.generate_normals()
	var apron:=MeshInstance3D.new()
	apron.name="VisibleBakerApron"
	apron.mesh=surface.commit()
	parent.add_child(apron)
	ART.bone(parent,Vector3(-.35,1.04,-.33),
		Vector3(.35,1.04,-.33),.028,.028,tie,8)
	var pocket:=ART.box(parent,Vector3(-.08,.75,-.419),
		Vector3(.17,.14,.022),fabric)
	pocket.name="BakerWorkPocket"
	ART.bone(parent,Vector3(-.17,.83,-.424),
		Vector3(.01,.83,-.424),.009,.009,tie,7)

func _process(delta: float) -> void:
	# World labels are discovery aids, not floating billboards visible across
	# the entire valley. Spoken names remain in the dialogue when nearby.
	if name_label != null and is_instance_valid(world) and world.player != null:
		# While speaking, the character is already named in the dialogue.
		# Do not superimpose the big floating title on their head.
		var talking: bool = world.player.conversation_actor == self
		name_label.visible = not talking and global_position.distance_squared_to(
			world.player.global_position) <= 8.0*8.0
	# Conversation interrupts a citizen's walk, without altering their
	# job order or moving the player. They turn and address the listener.
	if is_instance_valid(world) and world.player != null and world.player.conversation_actor == self:
		var toward: Vector3=world.player.global_position-global_position
		toward.y=0.0
		if toward.length_squared()>.05:
			rotation.y=lerp_angle(rotation.y,atan2(-toward.x,-toward.z),minf(1.0,delta*8.0))
	if left_arm==null or world==null or world.village_sim==null: return
	anatomy_visual_elapsed+=delta
	if anatomy_visual_elapsed>=.30:
		anatomy_visual_elapsed=0.0
		refresh_anatomy_visuals()
	motion_clock+=delta
	var order: Dictionary=world.village_sim.work_orders.get(npc_id,{})
	var phase: String=String(order.get("phase",""))
	# Drive gait from actual world displacement, never just an animation
	# clock. Feet no longer keep cycling while a villager hits a wall or
	# stands in conversation. Teleports/save loads do not advance gait.
	if not has_footstep_origin:
		previous_footstep_position=global_position
		has_footstep_origin=true
	var traveled: float=Vector2(global_position.x-previous_footstep_position.x,
		global_position.z-previous_footstep_position.z).length()
	previous_footstep_position=global_position
	var talking: bool=world.player!=null and world.player.conversation_actor==self
	var walking: bool=mobile and not talking and traveled>.002 and traveled<.38
	if walking:
		distance_gait_phase+=traveled*8.3
		gait_weight=move_toward(gait_weight,1.0,delta*7.0)
	else:
		gait_weight=move_toward(gait_weight,0.0,delta*7.0)
	var working: bool=not order.is_empty() and phase=="labor" and _near_work_goal()
	var stride: float=sin(distance_gait_phase)*.44*gait_weight
	# A quiet breathing/sway pass animates only visual mesh roots; the
	# CharacterBody3D, ray collider, navigation and saved positions do not bob.
	if visual_figure!=null:
		var breath: float=sin(motion_clock*1.78+float(absi(npc_id.hash())%7))*.010
		visual_figure.position.y=breath+absf(sin(distance_gait_phase))*.028*gait_weight
		visual_figure.rotation.z=sin(distance_gait_phase)*.016*gait_weight
	if visual_attendant!=null:
		visual_attendant.position.y=sin(motion_clock*1.55)*.008
	left_leg.rotation.x=lerpf(left_leg.rotation.x,stride,minf(1.0,delta*9.0))
	right_leg.rotation.x=lerpf(right_leg.rotation.x,-stride,minf(1.0,delta*9.0))
	var reach: float=0.0
	var offhand: float=0.0
	if working:
		var beat: float=sin(motion_clock*(8.5 if npc_id=="orin" else 4.4))
		reach=-.65-.52*beat if npc_id=="orin" else -.48-.25*beat
		offhand=-.34-.19*sin(motion_clock*4.4+1.2)
	elif walking:
		reach=-stride*.68
		offhand=stride*.68
	elif phase=="delivery" and npc_id=="daro":
		reach=-.78
		offhand=-.78
	left_arm.rotation.x=lerpf(left_arm.rotation.x,offhand,minf(1.0,delta*8.0))
	right_arm.rotation.x=lerpf(right_arm.rotation.x,reach,minf(1.0,delta*8.0))
	if harvest_sack!=null:
		harvest_sack.visible=phase=="delivery" and not limb_missing("right_arm")

func anatomy_state() -> Dictionary:
	if world==null or world.village_sim==null or not world.village_sim.people.has(npc_id):
		return ANATOMY.new_state()
	return world.village_sim.people[npc_id]["anatomy"]

func limb_missing(part: String) -> bool:
	return anatomy_state()["missing"].has(part)

func _install_limb_hitbox(limb: Node3D, part: String) -> void:
	var area:=Area3D.new()
	area.name="Hitbox_"+part
	area.collision_layer=4
	area.collision_mask=0
	area.set_meta("npc_ref",self)
	area.set_meta("hit_limb",part)
	limb.add_child(area)
	var shape:=CollisionShape3D.new()
	var capsule:=CapsuleShape3D.new()
	capsule.height=.42
	capsule.radius=.135
	shape.shape=capsule
	shape.position=Vector3(0,-.23,0)
	area.add_child(shape)
	limb_hitboxes[part]=area

func _drop_severed_limb(part: String) -> void:
	if not modular_limbs.has(part) or world==null: return
	var source: Node3D=modular_limbs[part]
	var piece:=RigidBody3D.new()
	piece.name="Detached_"+npc_id+"_"+part
	piece.collision_layer=8
	piece.collision_mask=16
	piece.mass=1.25 if part.ends_with("leg") else .65
	world.add_child(piece)
	piece.global_position=source.global_position
	piece.global_rotation=source.global_rotation
	var mesh_clone: Node3D=source.duplicate()
	mesh_clone.name="SeparatedPhysicalAnatomy"
	mesh_clone.position=Vector3.ZERO
	mesh_clone.rotation=Vector3.ZERO
	for area in mesh_clone.find_children("*","Area3D",true,false):
		area.queue_free()
	piece.add_child(mesh_clone)
	var collider:=CollisionShape3D.new()
	var capsule:=CapsuleShape3D.new()
	capsule.radius=.12
	capsule.height=.52
	collider.shape=capsule
	collider.position=Vector3(0,-.25,0)
	piece.add_child(collider)
	piece.apply_central_impulse(Vector3(
		-.9 if part.begins_with("left") else .9,.75,-.5))
	# Separated remains a real finite-lived rigid body. Person status is
	# authoritative and permanent; this loose physics object is not a
	# second simulation citizen or something resurrected by loading.
	var timer:=get_tree().create_timer(75.0)
	timer.timeout.connect(func() -> void:
		if is_instance_valid(piece): piece.queue_free())

func strike_limb(part: String, force: float, attacker: String="wizard") -> Dictionary:
	if part not in ANATOMY.PARTS or world==null or world.village_sim==null:
		return {"ok":false,"severed":false}
	var observers: Array=[]
	if world.has_method("physical_witnesses_of"):
		observers=world.physical_witnesses_of(self)
	var result: Dictionary=world.village_sim.injure_person(
		npc_id,part,force,attacker,observers)
	if not bool(result.get("ok",false)): return result
	if bool(result.get("severed",false)):
		_drop_severed_limb(part)
	refresh_anatomy_visuals()
	return result

func refresh_anatomy_visuals() -> void:
	if world==null or world.village_sim==null: return
	var anatomy: Dictionary=anatomy_state()
	if not ANATOMY.validate(anatomy): return
	var signature: String=str(anatomy["missing"])+":"+str(anatomy["bandaged"])+":"+str(anatomy["support"])
	for part in ANATOMY.PARTS:
		if modular_limbs.has(part):
			(modular_limbs[part] as Node3D).visible=not anatomy["missing"].has(part)
		if limb_hitboxes.has(part):
			(limb_hitboxes[part] as Area3D).collision_layer=(
				0 if anatomy["missing"].has(part) else 4)
	if signature!=anatomy_visual_signature:
		anatomy_visual_signature=signature
		_build_support_visual(anatomy)
	var flow: float=float(anatomy["bleeding"])
	if flow>.25 and blood_emitter==null:
		blood_emitter=CPUParticles3D.new()
		blood_emitter.name="ActualWoundBloodParticles"
		blood_emitter.amount=12
		blood_emitter.lifetime=.8
		blood_emitter.emission_shape=CPUParticles3D.EMISSION_SHAPE_SPHERE
		blood_emitter.emission_sphere_radius=.07
		blood_emitter.direction=Vector3(.12,.4,0)
		blood_emitter.spread=55.0
		blood_emitter.gravity=Vector3(0,-5,0)
		blood_emitter.initial_velocity_min=.3
		blood_emitter.initial_velocity_max=1.2
		blood_emitter.color=Color("5b1717")
		var globule:=SphereMesh.new()
		globule.radius=.018
		globule.height=.035
		blood_emitter.mesh=globule
		add_child(blood_emitter)
	if blood_emitter!=null:
		blood_emitter.emitting=flow>.25
		blood_emitter.position=Vector3(.32,.9,0) if anatomy["missing"].has("right_arm") else Vector3(-.32,.9,0)

func _build_support_visual(anatomy: Dictionary) -> void:
	if support_visual!=null and is_instance_valid(support_visual):
		support_visual.queue_free()
	support_visual=Node3D.new()
	support_visual.name="AnatomicalAftercareVisuals"
	# Keep support on the same visual root; ambient breathing must not
	# leave a crutch behind in the world while its person sways.
	var root: Node3D=visual_attendant if visual_attendant!=null else visual_figure
	if root==null: return
	root.add_child(support_visual)
	var pale:=ART.mat(Color("8b7e69"),.99)
	var timber:=ART.mat(Color("62503c"),.99)
	var iron:=ART.mat(Color("5d5c55"),.86)
	for part in ANATOMY.PARTS:
		if not anatomy["missing"].has(part): continue
		var side: float=-1.0 if part.begins_with("left") else 1.0
		var joint_y: float=1.43 if part.ends_with("arm") else .57
		var joint_x: float=side*(.35 if part.ends_with("arm") else .17)
		var stump: MeshInstance3D=ART.orb(support_visual,
			Vector3(joint_x,joint_y,0),
			Vector3(.19,.15,.19),pale if anatomy["bandaged"] else iron,10)
		stump.name="DetachableJoint_"+part
	if not ANATOMY.needs_support(anatomy): return
	var lost_left: bool=anatomy["missing"].has("left_leg")
	var side: float=-1.0 if lost_left else 1.0
	match String(anatomy["support"]):
		"crutch":
			ART.bone(support_visual,Vector3(side*.45,1.28,-.08),
				Vector3(side*.62,.03,-.09),.052,.039,timber,8).name="BuiltWalkingCrutch"
		"peg":
			ART.bone(support_visual,Vector3(side*.17,.55,0),
				Vector3(side*.17,.035,-.035),.11,.075,timber,10).name="FittedPegLeg"
			ART.box(support_visual,Vector3(side*.17,.52,0),
				Vector3(.27,.09,.27),iron)

func _near_work_goal() -> bool:
	if world==null or npc_id.is_empty(): return false
	var goal: Vector3=_destination_for("work")
	return Vector2(global_position.x-goal.x,global_position.z-goal.z).length()<2.2

func _destination_for(action: String) -> Vector3:
	# Care is a physical visit to a particular person, not work magically
	# completed at an invisible village ledger. The usual navigation and
	# collision rules carry the helper to their chosen patient.
	if action=="aid" and world!=null and world.village_sim!=null:
		var patient_id: String=world.village_sim._care_target(npc_id)
		if not patient_id.is_empty():
			for other in world.npcs:
				if is_instance_valid(other) and String(other.npc_id)==patient_id:
					return other.global_position
	var key: String = "home"
	match action:
		"work": key = "work"
		"socialize", "court", "investigate": key = "market"
	# Only after the Blender house is present can a resident's home be
	# the real, navigable porch. Without the optional asset use the original
	# authored home coordinates; never create an invisible goal in bare builds.
	if key=="home" and PHYSICAL_HOME_APPROACHES.has(npc_id):
		var residence: Dictionary=PHYSICAL_HOME_APPROACHES[npc_id]
		var building: Node3D=world.get_node_or_null(
			"PhysicalVillageHomesteads/"+String(residence["house"])) as Node3D
		if building!=null and building.get_node_or_null("BlenderAuthoredVernacularHouse")!=null:
			# Tree growth and the planted village garden can make one precise
			# porch tile unavailable. Sample short, side-stepped approaches
			# against the SAME navigation law used to build the real nav mesh.
			# The first candidate preserves each resident's own side.
			for nudge in [
				Vector2.ZERO,Vector2(.95,-.45),Vector2(-.95,-.45),
				Vector2(1.4,-1.1),Vector2(-1.4,-1.1)
			]:
				var threshold: Vector3=building.to_global(Vector3(
					float(residence["x"])+nudge.x,0.0,-4.35+nudge.y))
				if NAV_BUILDER.traversable(world,threshold.x,threshold.z):
					return Vector3(threshold.x,
						world.height_at(threshold.x,threshold.z)+.1,threshold.z)
			# If all porch approaches are impassable in a saved/modified
			# landscape, the original authored home remains the safe goal.
	# Work faces the actual crop plot, oven approach or anvil, not a generic
	# point in the middle of the old market. Deliveries go to the grain cart.
	if action=="work":
		match npc_id:
			"daro":
				var job: Dictionary=world.village_sim.work_orders.get(npc_id,{})
				var place: Vector2=Vector2(14.6,22.6) if String(job.get("phase",""))=="delivery" else Vector2(17.5,24.0)
				return Vector3(place.x,world.height_at(place.x,place.y)+.1,place.y)
			"ida": return Vector3(8.9,world.height_at(8.9,14.4)+.1,14.4)
			"orin": return Vector3(20.4,world.height_at(20.4,16.2)+.1,16.2)
	var spot: Array = definition.get(key,definition.get("position",[0.0,0.0]))
	var x: float = float(spot[0])
	var z: float = float(spot[1])
	return Vector3(x,world.height_at(x,z)+0.1,z)

func _physics_process(delta: float) -> void:
	if not mobile or route == null or world == null or world.village_sim == null: return
	if world.player != null and world.player.conversation_actor == self:
		# An NPC cannot walk away in the middle of a live exchange.
		velocity.x=0.0
		velocity.z=0.0
		velocity.y=-0.1 if is_on_floor() else velocity.y-16.0*delta
		move_and_slide()
		return
	var state: Dictionary = world.village_sim.people.get(npc_id,{})
	if state.is_empty(): return
	var action: String = String(state.get("last_action","rest"))
	# Replan when the farmer finishes cutting and starts carrying the real
	# harvest. A pending delivery changes the goal without changing action.
	var order: Dictionary=world.village_sim.work_orders.get(npc_id,{})
	var token: String="%d:%s" % [int(order.get("tick",0)),String(order.get("phase",""))] if not order.is_empty() else ""
	if token!=active_work_token:
		active_work_token=token
		work_dwell=0.0
	var desired: Vector3=_destination_for(action)
	if last_sim_action!=action or current_goal.distance_to(desired)>.55:
		last_sim_action=action
		current_goal=desired
		replan_elapsed=0.0
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
	# Do not walk in tiny circles while working; physical presence is the
	# gate for the work timer and the resource transaction.
	if not order.is_empty() and Vector2(global_position.x-current_goal.x,global_position.z-current_goal.z).length()<1.75:
		move_dir=Vector3.ZERO
	if move_dir.length_squared() > 0.01:
		var origin: Vector3 = global_position + Vector3.UP * 0.85
		var obstacle: Dictionary = get_world_3d().direct_space_state.intersect_ray(
			PhysicsRayQueryParameters3D.create(origin,origin+move_dir*1.4,16,[get_rid()]))
		if not obstacle.is_empty():
			var normal: Vector3 = obstacle["normal"]
			var along: Vector3 = Vector3(-normal.z,0.0,normal.x)
			if along.dot(move_dir)<0.0: along = -along
			move_dir = along.normalized()
	var anatomy: Dictionary=anatomy_state()
	var movement: float=ANATOMY.locomotion(anatomy)
	velocity.x = move_dir.x * 1.55 * movement
	velocity.z = move_dir.z * 1.55 * movement
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
	# Travel -> genuine work animation -> stock production. Daro must walk
	# from the field to the physical cart before the village gains grain.
	if not order.is_empty():
		var near_destination: bool=Vector2(global_position.x-current_goal.x,global_position.z-current_goal.z).length()<2.2
		if near_destination and Vector2(velocity.x,velocity.z).length()<.3:
			work_dwell+=delta
		else:
			work_dwell=0.0
		var task_seconds: float=1.8 if npc_id=="daro" and String(order.get("phase",""))=="labor" and world.village_sim.field_fertility>0 else 3.0
		if work_dwell>=task_seconds:
			if npc_id=="daro" and String(order.get("phase",""))=="labor":
				world.village_sim.advance_work(npc_id)
			else:
				world.village_sim.complete_work(npc_id)
			work_dwell=0.0
