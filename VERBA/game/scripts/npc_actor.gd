extends CharacterBody3D
## A physical inhabitant, targetable with the player's normal world ray.
## Existing authored characters retain their landmarks; village citizens
## physically navigate based on independent simulated economic/social actions.
const ART = preload("res://scripts/art.gd")
const COSTUME = preload("res://scripts/folk_costume_finish.gd")
const WARDROBE = preload("res://scripts/folk_wardrobe_finish.gd")
const PORTRAIT = preload("res://scripts/folk_portrait_finish.gd")
const BODY = preload("res://scripts/npc_body_morph.gd")
const FABRIC = preload("res://scripts/npc_cloth_finish.gd")
const ANATOMY = preload("res://scripts/npc_anatomy.gd")
const GENES = preload("res://scripts/npc_genetics.gd")
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
var left_forearm: Node3D
var right_forearm: Node3D
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
var inherited_body_dimensions: Vector3=Vector3.ONE
var last_body_age_day: int=-999999

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
	# Profession-specific dye on one coherent, coarse woven cloth. Do not
	# use the aged parchment texture for clothing or a glossy material.
	var cloth := FABRIC.worn_linen(Color(String(definition.get("robe","746c60"))))
	var genome: Dictionary=GENES.founder(npc_id)
	var sex: String="unspecified"
	var stage: String="adult"
	var age_years: float=28.0
	if world!=null and world.village_sim!=null and world.village_sim.people.has(npc_id):
		var record: Dictionary=world.village_sim.people[npc_id]
		genome=record.get("genome",genome)
		sex=String(record.get("sex","unspecified"))
		stage=String(record.get("life_stage","adult"))
		var birth: int=int(record.get("family",{}).get("birth_day",-365*28))
		age_years=maxf(0.0,float(world.village_sim.current_day-birth)/365.0)
	if not GENES.validate(genome):
		genome=GENES.founder(npc_id)
	set_meta("genome_traits",true)
	set_meta("body_sex",sex)
	set_meta("bloodline_generation",
		int(world.village_sim.people[npc_id]["family"].get("generation",0)) if
		world!=null and world.village_sim!=null and world.village_sim.people.has(npc_id) else 0)
	var trim := ART.mat(Color(String(definition.get("trim","c0aa86"))),.95)
	# A human should read as a particular person, not an identical tan
	# mannequin re-dressed for each job.
	var skin := ART.mat(GENES.skin_color(genome),.96)
	var leather := ART.mat(Color("463f37"),.99)
	# A separate torso, narrower tunic hem and jointed legs replace the
	# one-piece walking cone. Props remain on their own worker identities.
	# Twelve-sided fitted tunic with a broad shoulder and a shaped hem:
	# these surfaces replace the previous square torso and floating eyes.
	# Hide the obsolete fixed cone shells that cover inherited waist,
	# hips and torso geometry. Retain nodes temporarily for old scene
	# references; the visible clothes come from fitted BODY and COSTUME.
	var tunic:=ART.cone(figure,Vector3(0,1.125,0),.285,.56,cloth,.205,12)
	tunic.name="TaperedVillagerTunic"
	tunic.visible=false
	tunic.set_meta("legacy_hidden_by_genetic_torso",true)
	var old_lower_tunic:=ART.cone(figure,Vector3(0,.79,0),.315,.52,cloth,.255,12)
	old_lower_tunic.name="LegacyLowerTunicHidden"
	old_lower_tunic.visible=false
	# Shoulder, neck opening and trapezius now come from the inherited
	# single cloth surface. No exposed helper cylinder beneath the chin.
	var head:=ART.orb(figure,Vector3(0,1.77,0),
		Vector3(.42,.49,.39),skin,13)
	head.name="ModeledInhabitantHead"
	# Individual anatomy replaces the floating eyes and identical hair
	# caps, retaining the original tested head and collision silhouette.
	var hair:=ART.mat(GENES.hair_color(genome),.96)
	var brow:=ART.mat(GENES.hair_color(genome).darkened(.12),.95)
	PORTRAIT.finish(figure,npc_id,skin,hair,brow,genome,sex,age_years)
	for side in [-1.0,1.0]:
		var arm:=Node3D.new()
		arm.name="AnimatedLeftArm" if side<0.0 else "AnimatedRightArm"
		# Shoulder sockets are measured from this person's inherited upper
		# thorax. A fixed x=.345 made both sexes look broad-shouldered.
		var socket_width: float=BODY._section(1.365,genome,sex).x
		arm.position=Vector3(side*(.030+.88*socket_width),1.405,0)
		# A slightly relaxed, inherited resting stance instead of two
		# vertical mannequin rods; gait and reaching still drive rotation.x.
		arm.rotation.z=side*lerpf(.050,.090,
			GENES.value(genome,"shoulder_width"))
		figure.add_child(arm)
		# Shoulder cap and upper sleeve have a sculpted circumference and
		# attach to the old detachable, animated physical arm pivot.
		COSTUME.fitted_sleeve(arm,side,genome,cloth,sex)
		# Genuine elbow articulation. The longer inherited forearm and hand
		# remain children of this original severable arm, not new body modules.
		var forearm:=Node3D.new()
		forearm.name="AnimatedLeftForearm" if side<0.0 else "AnimatedRightForearm"
		forearm.position=Vector3(side*.072,-.410,-.045)
		forearm.rotation.x=-.11
		arm.add_child(forearm)
		COSTUME.fitted_forearm(forearm,side,genome,cloth,skin)
		var leg:=Node3D.new()
		leg.name="AnimatedLeftLeg" if side<0.0 else "AnimatedRightLeg"
		# Femoral spacing follows the *pelvis* rather than a shared template.
		var pelvic_half_width: float=BODY._section(.78,genome,sex).x
		# Femoral heads sit at the anatomical pelvis, not at the tunic hem.
		# Keeping the pivot at .61 shortened both legs by almost 40 cm.
		leg.position=Vector3(side*.455*pelvic_half_width,.98,.015)
		figure.add_child(leg)
		# Genetically sized trouser and sculpted boot are mounted on this
		# same animated, hit-detectable, independently detachable leg.
		COSTUME.fitted_lower_leg(leg,side,genome,sex)
		var limb_arm: String="left_arm" if side<0.0 else "right_arm"
		var limb_leg: String="left_leg" if side<0.0 else "right_leg"
		modular_limbs[limb_arm]=arm
		modular_limbs[limb_leg]=leg
		_install_limb_hitbox(arm,limb_arm)
		_install_limb_hitbox(leg,limb_leg)
		if side<0.0:
			left_arm=arm
			left_forearm=forearm
			left_leg=leg
		else:
			right_arm=arm
			right_forearm=forearm
			right_leg=leg
	# Keep the scribe's distinct staff; other professions already have
	# their own fitted belt pouch in COSTUME.dress. The former universal
	# oversized box-and-strap satchel hung in the same place on every
	# villager, intersected sleeves, and obscured the aprons in game views.
	if npc_id == "mara":
		ART.bone(figure,Vector3(-.54,.15,.12),
			Vector3(-.48,2.43,.16),.048,.037,leather,8)
		ART.orb(figure,Vector3(-.48,2.44,.16),
			Vector3(.075,.09,.071),trim,9)
	# Role identity belongs to the person: the same figure carries these
	# tools whether travelling, trading or standing at the workplace.
	# Do not replace every citizen with the same cone-robe silhouette.
	match npc_id:
		"ida":
			var flour:=ART.mat(Color("d2c4a1"),.98)
			# A shaped cloth bib, a tied waist and a pocket replace the
			# vertical white rectangle that used to obscure the whole body.
			_make_baker_apron(figure,flour,trim,genome,sex)
			var bonnet:=ART.orb(figure,Vector3(0,1.989,.025),
				Vector3(.46,.24,.40),flour,12)
			bonnet.name="VisibleBakerBonnet"
			# Avoid two unsupported ivory rods sticking out beside the face.
			# The bonnet silhouette is readable without fake face-hanging bones.
		"orin":
			var hide:=FABRIC.worn_leather(Color("775b42"))
			var metal:=ART.mat(Color("737e81"),.52)
			# Shaped leather hangs in front of the actual inherited torso.
			# Retain original occupational identity and arm-mounted hammer.
			COSTUME.smith_work_apron(figure,genome,hide,leather,metal,sex)
			var hammer:=Node3D.new()
			hammer.name="VisibleSmithHammer"
			# A work hammer hangs by the wrist at rest. The previous
			# giant bright rectangular head sat near eye height, reading
			# as a floating white bar across the first-person view.
			hammer.position=Vector3(.015,-GENES.forearm_length(genome)+.08,-.012)
			right_forearm.add_child(hammer)
			var handle:=ART.bone(hammer,Vector3(0,-.20,0),
				Vector3(0,.12,0),.031,.027,leather,8)
			handle.name="SmithHammerTimberHandle"
			var head_mesh:=ART.box(hammer,Vector3(0,-.15,0),
				Vector3(.24,.13,.14),metal)
			head_mesh.name="SmithHammerWorkingHead"
		"daro":
			var straw:=ART.mat(Color("b8a477"),.99)
			var brim:=ART.cone(figure,Vector3(0,2.02,0),.49,.075,
				straw,.41,14)
			brim.name="VisibleFarmerHat"
			ART.cone(figure,Vector3(0,2.14,0),.29,.23,straw,.21,12)
			var staff:=Node3D.new()
			staff.name="VisibleFarmerRake"
			staff.position=Vector3(-.08,-GENES.forearm_length(genome)+.065,-.08)
			left_forearm.add_child(staff)
			ART.bone(staff,Vector3(0,-.77,0),Vector3(0,1.03,0),
				.039,.029,leather,8)
			ART.box(staff,Vector3(0,1.02,0),Vector3(.47,.10,.09),trim)
		"sela":
			# The old .38 x .45 golden box floated beside her body.
			# This compact worn-leather bag follows the inherited hip.
			WARDROBE.merchant_satchel(figure,genome,sex)
		"nima":
			var instrument:=ART.orb(figure,Vector3(-.22,1.03,-.40),
				Vector3(.28,.37,.11),ART.mat(Color("926849"),.91),12)
			instrument.name="VisibleBardLute"
			ART.bone(figure,Vector3(-.33,1.17,-.40),
				Vector3(.18,1.55,-.40),.065,.053,leather,9)
		"titus":
			# Muted faceted shield follows the original detachable left arm.
			WARDROBE.guard_shield(left_arm)
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
		# This uniform used to be two large identical cuboids on every
		# worker, concealing the genetic torso below. Keep named, hidden
		# compatibility meshes; the fitted shirt and apron are rendered.
		var old_shirt:=ART.box(attendant,Vector3(0,1.13,0),
			Vector3(.74,.88,.37),shirt)
		old_shirt.name="HiddenOldStationShirtBox"
		old_shirt.visible=false
		var old_apron:=ART.box(attendant,Vector3(0,.84,-.21),
			Vector3(.68,.63,.08),apron)
		old_apron.name="HiddenOldStationApronBox"
		old_apron.visible=false
		COSTUME.fitted_station_apron(attendant,genome,apron,sex)
		for side in [-1.0,1.0]:
			var side_name: String="left" if side<0.0 else "right"
			var modern_leg:=Node3D.new()
			modern_leg.name="ModularModern"+side_name.capitalize()+"Leg"
			modern_leg.position=Vector3(side*.47*
				BODY._section(.78,genome,sex).x,.98,0)
			attendant.add_child(modern_leg)
			# Jeans and ankle boots use the same inherited hip/thigh shape
			# without introducing extra limbs or changing the physical rig.
			COSTUME.fitted_lower_leg(modern_leg,side,genome,sex)
			modular_limbs[side_name+"_leg"]=modern_leg
			_install_limb_hitbox(modern_leg,side_name+"_leg")
			var modern_arm:=Node3D.new()
			modern_arm.name="ModularModern"+side_name.capitalize()+"Arm"
			modern_arm.position=Vector3(side*(.034+
				.91*BODY._section(1.365,genome,sex).x),1.405,0)
			attendant.add_child(modern_arm)
			modern_arm.rotation.z=side*lerpf(.050,.090,GENES.value(genome,"shoulder_width"))
			COSTUME.fitted_sleeve(modern_arm,side,genome,shirt,sex)
			var modern_forearm:=Node3D.new()
			modern_forearm.name="AnimatedLeftForearm" if side<0.0 else "AnimatedRightForearm"
			modern_forearm.position=Vector3(side*.072,-.410,-.045)
			modern_forearm.rotation.x=-.11
			modern_arm.add_child(modern_forearm)
			COSTUME.fitted_forearm(modern_forearm,side,genome,shirt,skin)
			modular_limbs[side_name+"_arm"]=modern_arm
			_install_limb_hitbox(modern_arm,side_name+"_arm")
			# The real visible uniform limbs must receive gait and arm-swing,
			# not the hidden medieval base rig underneath them.
			if side<0.0:
				left_arm=modern_arm
				left_forearm=modern_forearm
				left_leg=modern_leg
			else:
				right_arm=modern_arm
				right_forearm=modern_forearm
				right_leg=modern_leg
		var modern_head:=ART.orb(attendant,Vector3(0,1.76,0),
			Vector3(.42,.49,.39),skin,12)
		modern_head.name="ModernGeneticHead"
		# The former two huge head-level boxes became a floating roof in
		# close-up. A close crown and shallow visor preserve the station
		# worker's hat without hiding the genetic face beneath it.
		var crown:=ART.box(attendant,Vector3(0,2.040,-.015),
			Vector3(.43,.105,.34),denim)
		crown.name="FittedAttendantCapCrown"
		var peak:=ART.box(attendant,Vector3(0,2.018,-.207),
			Vector3(.34,.025,.13),denim)
		peak.name="ShortAttendantVisor"
		COSTUME.dress_attendant(attendant)
		BODY.finish(attendant,genome,shirt,true,sex)
		COSTUME.tailored_womenswear(attendant,npc_id,genome,sex,shirt)
		WARDROBE.finish(attendant,npc_id,genome,sex)
	else:
		COSTUME.dress(figure,npc_id,cloth,trim,leather,genome,sex)
		BODY.finish(figure,genome,cloth,false,sex)
		COSTUME.tailored_womenswear(figure,npc_id,genome,sex,cloth)
		WARDROBE.finish(figure,npc_id,genome,sex)
	# Mild-to-noticeable, inherited body dimensions. The faceted look is
	# deliberate; we change proportions, not topology or collision IDs.
	inherited_body_dimensions=GENES.body_scale(genome,sex)
	_apply_genetic_growth()
	if visual_attendant!=null:
		PORTRAIT.finish(visual_attendant,npc_id,skin,hair,brow,genome,sex,age_years)
	# Both face and limb models inherit the same body shape, and child
	# models use the existing detachable body-part system.
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
	shape.name="LivingInteractionCapsule"
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
	# Conversation target and navigation hit volume must match the
	# actual inherited growth stage, including newborn villagers.
	_apply_genetic_growth()

func _fit_growth_colliders(physical_scale: Vector3) -> void:
	# Scale ONLY the capsule dimensions; nonuniform CollisionShape3D
	# transforms produce unreliable physics in Godot. The original
	# collider nodes, collision layers and hitbox identities survive.
	var walker: CollisionShape3D=get_node_or_null(
		"PhysicalCitizenCollider") as CollisionShape3D
	if walker!=null and walker.shape is CapsuleShape3D:
		var capsule: CapsuleShape3D=walker.shape as CapsuleShape3D
		capsule.radius=clampf(.34*physical_scale.x,.23,.45)
		capsule.height=maxf(1.75*physical_scale.y,2.0*capsule.radius+.05)
		walker.position.y=.90*physical_scale.y
	var conversation: CollisionShape3D=get_node_or_null(
		"LivingNPCConversationCollider/LivingInteractionCapsule") as CollisionShape3D
	if conversation!=null and conversation.shape is CapsuleShape3D:
		var target: CapsuleShape3D=conversation.shape as CapsuleShape3D
		target.radius=clampf(.43*physical_scale.x,.24,.53)
		target.height=maxf(1.95*physical_scale.y,2.0*target.radius+.05)
		conversation.position.y=1.0*physical_scale.y
	if name_label!=null:
		name_label.position.y=2.29*physical_scale.y

func _apply_genetic_growth() -> void:
	# Juveniles physically grow toward their own inherited adult body
	# proportions over calendar years; there is no 18th-birthday pop.
	if world==null or world.village_sim==null or not world.village_sim.people.has(npc_id):
		return
	var person: Dictionary=world.village_sim.people[npc_id]
	var age_days: int=maxi(0,world.village_sim.current_day-int(person["family"]["birth_day"]))
	var years_progress: float=clampf(float(age_days)/(18.0*365.0),0.0,1.0)
	var growth: float=pow(years_progress,.74)
	var shape: Vector3=inherited_body_dimensions
	if String(person.get("life_stage","adult"))=="child":
		shape.x*=lerpf(.67,1.0,growth)
		shape.y*=lerpf(.54,1.0,growth)
		shape.z*=lerpf(.73,1.0,growth)
	if visual_figure!=null:
		visual_figure.scale=shape
	if visual_attendant!=null:
		visual_attendant.scale=shape
	_fit_growth_colliders(shape)
	last_body_age_day=world.village_sim.current_day

func _make_baker_apron(parent: Node3D, fabric: Material,
		tie: Material, genome: Dictionary, sex: String) -> void:
	# The chest has its own anatomical curve. Sampling only at the
	# top and waist lets the physical ribcage and bust protrude through
	# the flat apron, creating a giant brown hole in the actual render.
	# A genuine conformal surface follows inherited chest/waist/hips
	# across many sampled heights and lateral points, without new colliders.
	const COLUMNS: int=11
	const HEIGHTS: Array[float]=[1.40,1.365,1.33,1.29,1.255,1.22,1.17,1.11,1.055,.99,.93,.84,.77,.70,.64,.55]
	var vertices: Array[Vector3]=[]
	for y in HEIGHTS:
		var t: float=clampf((1.40-y)/.85,0.0,1.0)
		var half_width: float=lerpf(.185,.260,t)
		var torso_section: Vector2=BODY._section(y,genome,sex)
		for col in range(COLUMNS):
			var fraction: float=float(col)/float(COLUMNS-1)*2.0-1.0
			var x: float=half_width*fraction
			var angle: float=-PI*.5+asin(clampf(x/torso_section.x,-.89,.89))
			var point: Vector3=BODY._point(y,angle,genome,sex)
			# Dense sampling follows the convex bust and lower ribs. The
			# old five-column panel cut across the curved chest: the opaque
			# shirt pierced the apron, leaving a jagged brown hole.
			# A center-weighted air gap clears the outer cloth while the
			# panel still follows inherited body geometry.
			var drape_gap: float=.105+.024*(1.0-absf(fraction))
			vertices.append(Vector3(x,y,point.z-drape_gap))
	var surface:=SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_material(fabric)
	for row in range(HEIGHTS.size()-1):
		for column in range(COLUMNS-1):
			var i: int=row*COLUMNS+column
			for j in [i,i+1,i+COLUMNS,i+1,i+COLUMNS+1,i+COLUMNS]:
				surface.set_uv(Vector2(vertices[j].x+.5,vertices[j].y))
				surface.add_vertex(vertices[j])
	surface.generate_normals()
	var apron:=MeshInstance3D.new()
	apron.name="VisibleBakerApron"
	apron.mesh=surface.commit()
	# A single-sided facing can disappear at oblique close-up camera angles.
	# Protect the apron on both sides; the cream fabric itself carries its
	# visible color rather than borrowing the dark undergarment material.
	if fabric is StandardMaterial3D:
		(fabric as StandardMaterial3D).cull_mode=BaseMaterial3D.CULL_DISABLED
	apron.material_override=fabric
	apron.set_meta("drapes_over_inherited_torso",true)
	parent.add_child(apron)
	var waist_front: float=BODY._point(1.04,-PI*.5,genome,sex).z-.155
	# A stitched waist seam, not a broad yellow bar projecting across
	# the entire abdomen.
	var stitch:=ART.bone(parent,Vector3(-.20,1.04,waist_front),
		Vector3(.20,1.04,waist_front),.013,.013,tie,8)
	stitch.name="BakerCloseFittedWaistSeam"
	var pocket_z: float=BODY._point(.75,-PI*.5,genome,sex).z-.152
	var pocket:=ART.box(parent,Vector3(-.08,.75,pocket_z),
		Vector3(.17,.14,.022),fabric)
	pocket.name="BakerWorkPocket"
	ART.bone(parent,Vector3(-.17,.83,pocket_z-.011),
		Vector3(.01,.83,pocket_z-.011),.009,.009,tie,7)

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
	if last_body_age_day!=world.village_sim.current_day:
		_apply_genetic_growth()
	# Facial animation reacts to the person's own mood and memories of
	# the player, without changing any inherited genetic trait.
	var me: Dictionary=world.village_sim.people.get(npc_id,{})
	if not me.is_empty():
		var opinion: float=float(me["trust"].get("wizard",0.0))
		var feeling: float=clampf((float(me["mood"])-50.0)/75.0+opinion*.009,-1,1)
		if world.player!=null and world.player.conversation_actor==self:
			feeling=clampf(feeling+.18,-1,1)
		var time_in_blink: float=fposmod(motion_clock+float(posmod(npc_id.hash(),11))*.33,4.25)
		var blink: float=clampf(1.0-absf(time_in_blink-3.72)/.13,0,1)
		if visual_attendant!=null:
			PORTRAIT.expression(visual_attendant,feeling,blink,
				world.player!=null and world.player.conversation_actor==self,motion_clock)
		else:
			PORTRAIT.expression(visual_figure,feeling,blink,
				world.player!=null and world.player.conversation_actor==self,motion_clock)
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
	var body: Dictionary=anatomy_state()
	var missing_left_leg: bool=body["missing"].has("left_leg")
	var missing_right_leg: bool=body["missing"].has("right_leg")
	var limping: bool=missing_left_leg or missing_right_leg
	# A peg makes contact with the ground on a slower, uneven stride.
	# No injury: preserve the baseline distance-driven walk exactly.
	var stride: float=sin(distance_gait_phase)*(.31 if limping else .44)*gait_weight
	# A quiet breathing/sway pass animates only visual mesh roots; the
	# CharacterBody3D, ray collider, navigation and saved positions do not bob.
	if visual_figure!=null:
		var breath: float=sin(motion_clock*1.78+float(absi(npc_id.hash())%7))*.010
		var foot_lift: float=absf(sin(distance_gait_phase))*(.012 if limping else .028)*gait_weight
		visual_figure.position.y=breath+foot_lift
		# Lean toward the remaining leg or fitted aid; no hopping
		# oscillation on an amputated leg's invisible animation bone.
		var lean: float=(.060 if missing_left_leg else (-.060 if missing_right_leg else 0.0))
		visual_figure.rotation.z=lean*gait_weight+sin(distance_gait_phase)*(.026 if limping else .016)*gait_weight
	if visual_attendant!=null:
		visual_attendant.position.y=sin(motion_clock*1.55)*.008
	if left_leg!=null and not missing_left_leg:
		left_leg.rotation.x=lerpf(left_leg.rotation.x,stride,minf(1.0,delta*9.0))
	if right_leg!=null and not missing_right_leg:
		right_leg.rotation.x=lerpf(right_leg.rotation.x,-stride,minf(1.0,delta*9.0))
	if support_visual!=null and is_instance_valid(support_visual):
		var peg: Node3D=support_visual.get_node_or_null("FittedPegPivot") as Node3D
		if peg!=null:
			peg.rotation.x=lerpf(peg.rotation.x,
				(-stride*.70 if missing_left_leg else stride*.70),minf(1.0,delta*8.0))
		var crutch: Node3D=support_visual.get_node_or_null("WalkingCrutchPivot") as Node3D
		if crutch!=null:
			crutch.rotation.x=lerpf(crutch.rotation.x,
				-stride*.22,minf(1.0,delta*7.0))
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
	# The elbows bend in response to reaching, working and gait. They
	# never animate an invisible or separately detachable forearm.
	if left_forearm!=null and not limb_missing("left_arm"):
		var left_bend: float=-.11-maxf(0.0,-offhand)*.28-absf(stride)*.20
		left_forearm.rotation.x=lerpf(left_forearm.rotation.x,left_bend,minf(1.0,delta*8.0))
	if right_forearm!=null and not limb_missing("right_arm"):
		var right_bend: float=-.11-maxf(0.0,-reach)*.32-absf(stride)*.20
		right_forearm.rotation.x=lerpf(right_forearm.rotation.x,right_bend,minf(1.0,delta*8.0))
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
	# One capsule per arm retains the original limb identity while
	# covering the full inherited shoulder-to-wrist reach.
	capsule.height=1.18 if part.ends_with("_arm") else .88
	capsule.radius=.119 if part.ends_with("_arm") else .135
	shape.shape=capsule
	shape.position=Vector3(0,-.57 if part.ends_with("_arm") else -.425,0)
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
	capsule.height=.98 if part.ends_with("leg") else .52
	collider.shape=capsule
	collider.position=Vector3(0,-.45 if part.ends_with("leg") else -.25,0)
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
		observers=world.physical_witnesses_of(self,attacker)
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
		blood_emitter.amount=25
		blood_emitter.lifetime=1.05
		blood_emitter.emission_shape=CPUParticles3D.EMISSION_SHAPE_SPHERE
		blood_emitter.emission_sphere_radius=.07
		blood_emitter.direction=Vector3(.15,.25,0)
		blood_emitter.spread=63.0
		blood_emitter.gravity=Vector3(0,-7.5,0)
		blood_emitter.initial_velocity_min=.25
		blood_emitter.initial_velocity_max=1.45
		blood_emitter.color=Color("681f20")
		var globule:=SphereMesh.new()
		globule.radius=.018
		globule.height=.035
		blood_emitter.mesh=globule
		add_child(blood_emitter)
	if blood_emitter!=null:
		# Blood comes from the actual injured joint, not a generic point
		# around the character's stomach. Bandaging visibly stops drops.
		blood_emitter.emitting=flow>.45 and not bool(anatomy["bandaged"])
		var wound: String=String(anatomy.get("last_hit_part",""))
		if wound.is_empty() and anatomy["missing"].size()>0:
			wound=String(anatomy["missing"][0])
		if wound in ANATOMY.PARTS:
			var side: float=-1.0 if wound.begins_with("left") else 1.0
			var from_leg: bool=wound.ends_with("_leg")
			blood_emitter.position=Vector3(side*(.17 if from_leg else .35),
				.955 if from_leg else 1.43,-.035)

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
	var linen:=ART.mat(Color("aba090"),.99)
	var wound:=ART.mat(Color("6f2927"),.98)
	var timber:=ART.mat(Color("62503c"),.99)
	var iron:=ART.mat(Color("5d5c55"),.86)
	for part in ANATOMY.PARTS:
		if not anatomy["missing"].has(part): continue
		var side: float=-1.0 if part.begins_with("left") else 1.0
		var joint_y: float=1.43 if part.ends_with("arm") else .975
		var joint_x: float=side*(.35 if part.ends_with("arm") else .17)
		var stump: MeshInstance3D=ART.orb(support_visual,
			Vector3(joint_x,joint_y,0),
			Vector3(.19,.13,.19),linen if anatomy["bandaged"] else wound,10)
		stump.name="DetachableJoint_"+part
	if not ANATOMY.needs_support(anatomy): return
	var lost_left: bool=anatomy["missing"].has("left_leg")
	var side: float=-1.0 if lost_left else 1.0
	match String(anatomy["support"]):
		"crutch":
			var crutch_pivot:=Node3D.new()
			crutch_pivot.name="WalkingCrutchPivot"
			crutch_pivot.position=Vector3(side*.45,1.28,-.08)
			support_visual.add_child(crutch_pivot)
			ART.bone(crutch_pivot,Vector3.ZERO,
				Vector3(side*.17,-1.25,-.01),.052,.039,timber,8).name="BuiltWalkingCrutch"
			ART.bone(crutch_pivot,Vector3(-side*.10,-.11,0),
				Vector3(side*.10,-.11,0),.033,.033,linen,8)
			ART.bone(crutch_pivot,Vector3(-side*.08,-.40,0),
				Vector3(side*.09,-.40,0),.033,.027,timber,8)
		"peg":
			var peg_pivot:=Node3D.new()
			peg_pivot.name="FittedPegPivot"
			peg_pivot.position=Vector3(side*.17,.96,0)
			support_visual.add_child(peg_pivot)
			ART.bone(peg_pivot,Vector3.ZERO,
				Vector3(0,-.925,-.035),.11,.075,timber,10).name="FittedPegLeg"
			ART.box(peg_pivot,Vector3(0,-.03,0),
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
