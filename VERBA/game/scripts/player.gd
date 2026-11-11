extends CharacterBody3D
## Minecraft-style pointer lock. NO drag-look; mouse X yaw, mouse Y pitch.
const ART = preload("res://scripts/art.gd")
const GRIMOIRE = preload("res://scripts/grimoire.gd")
const INCANTATION = preload("res://scripts/incantation.gd")
const GRAMMAR = preload("res://scripts/latin_grammar.gd")
var world
var camera: Camera3D
var pitch: Node3D
var book
var held: Node3D
var held_type: String = ""
var inventory: Array[String] = []
var selected_slot := 0
var typing := false
var buffer := ""
var echo: Label3D
var cast_hand: Node3D
var reticle: Label
var interaction_hint: Label
var prompt_time:=0.0
var speed:=5.0
var run_speed:=8.6
var max_health: float = 100.0
var health: float = 100.0
var max_stamina: float = 100.0
var stamina: float = 100.0
var damage_immunity: float = 0.0
var death_count: int = 0
var survival_label: Label
var jump_speed:=5.5
var gravity:=16.0
var mouse_sensitivity:=.0022
var shake_time:=0.0
var info_elapsed:=0.0
var guide_panel: PanelContainer
var guide_visible := false  # Diegetic first view; H opens the help card on demand
var guide_clock := 0.0
var jump_offset: float = 0.0
var rise_velocity: float = 0.0
var diagnostics: Label
var diagnostics_visible := false
var last_motion: Vector2 = Vector2.ZERO
var conversation_actor: Node3D
var conversation_panel: PanelContainer
var conversation_name: Label
var conversation_body: Label
var conversation_options: Label
var conversation_reply: String = ""
var build_mode: bool = false
var build_kind: String = "floor"
var build_face: int = 0


func _ready() -> void:
	configure_inputs()
	var capsule:=CollisionShape3D.new()
	var shape:=CapsuleShape3D.new()
	shape.height=1.75
	shape.radius=.34
	capsule.shape=shape
	capsule.position.y=.9
	add_child(capsule)
	collision_layer=2
	collision_mask=16 | 32  # world + real wildlife bodies: never walk through a deer's mesh
	floor_snap_length=.45
	pitch=Node3D.new()
	pitch.name="Neck"
	pitch.position.y=1.58
	add_child(pitch)
	camera=Camera3D.new()
	camera.name="POVCamera"
	camera.fov=79.0
	camera.near=.04
	camera.far=140.0
	camera.current=true
	pitch.add_child(camera)
	book=GRIMOIRE.new()
	book.name="PhysicalBookInHand"
	book.setup(self,world.magic.lexicon)
	camera.add_child(book)
	book.restore()
	create_hands()
	echo=Label3D.new()
	echo.name="LettersSuspendedByThePalm"
	echo.text=""
	echo.font_size=45
	echo.pixel_size=.0029
	echo.modulate=Color("edc98c")
	echo.outline_modulate=Color("38241e")
	echo.outline_size=12
	echo.no_depth_test=false
	echo.position=Vector3(0,-.26,-1.13)
	camera.add_child(echo)
	create_minimal_reticle()
	create_first_steps()
	create_diagnostics()
	create_conversation_panel()
	Input.mouse_mode=Input.MOUSE_MODE_CAPTURED

func configure_inputs() -> void:
	# Physical key positions: layout-independent FPS controls. Do not gate movement on pointer lock.
	var bindings := {
		"verba_forward": KEY_W,
		"verba_backward": KEY_S,
		"verba_left": KEY_A,
		"verba_right": KEY_D,
		"verba_sprint": KEY_SHIFT,
		"verba_jump": KEY_SPACE
	}
	for action in bindings.keys():
		if not InputMap.has_action(action): InputMap.add_action(action)
		InputMap.action_erase_events(action)
		var event := InputEventKey.new()
		event.physical_keycode = bindings[action]
		InputMap.action_add_event(action,event)

func create_hands() -> void:
	held=Node3D.new()
	held.name="ObjectHeldInRightHand"
	held.position=Vector3(.57,-.60,-.86)
	camera.add_child(held)
	cast_hand=Node3D.new()
	held.add_child(cast_hand)
	var sleeve=ART.mat(Color("3f3f39"))
	var leather=ART.mat(Color("75533e"))
	ART.bone(cast_hand,Vector3(.25,-.32,.20),Vector3(.06,-.03,.0),.15,.11,sleeve,10)
	ART.orb(cast_hand,Vector3(0,.015,-.035),Vector3(.145,.09,.12),leather,14)
	refresh_held_model()

func refresh_held_model() -> void:
	for child in held.get_children():
		if child != cast_hand: child.queue_free()
	if inventory.is_empty():
		held_type=""
		return
	selected_slot=clampi(selected_slot,0,inventory.size()-1)
	held_type=inventory[selected_slot]
	var prop=Node3D.new()
	prop.name="Held"+held_type.capitalize()
	held.add_child(prop)
	var handle=ART.mat(Color("665040"))
	match held_type:
		"lantern":
			# Distinct hexagonal antique oil lantern, rather than the old unreadable block.
			var brass=ART.mat(Color("887050"),.55)
			var metal=ART.mat(Color("3d3f3a"),.66)
			var glass=ART.mat(Color("e5c48a",.43),.26,Color("7b4c27"))
			var wick=ART.mat(Color("ffdb8c"),.4,Color("b66f35"))
			ART.cone(prop,Vector3(0,.07,0),.21,.12,metal,.18,8)
			ART.cone(prop,Vector3(0,.49,0),.24,.13,metal,.13,8)
			ART.cone(prop,Vector3(0,.61,0),.10,.13,brass,.07,8)
			for k in range(6):
				var a:float=float(k)*TAU/6.0
				var x:float=cos(a)*.16
				var z:float=sin(a)*.16
				ART.bone(prop,Vector3(x,.1,z),Vector3(x,.51,z),.018,.018,brass,7)
				ART.bone(prop,Vector3(x,.14,z),Vector3(cos(a+TAU/6.0)*.16,.14,sin(a+TAU/6.0)*.16),.012,.012,brass,6)
				ART.bone(prop,Vector3(x,.46,z),Vector3(cos(a+TAU/6.0)*.16,.46,sin(a+TAU/6.0)*.16),.012,.012,brass,6)
			ART.orb(prop,Vector3(0,.30,0),Vector3(.118,.165,.11),glass,15)
			ART.orb(prop,Vector3(0,.26,0),Vector3(.033,.08,.032),wick,9)
			ART.bone(prop,Vector3(-.09,.59,0),Vector3(-.09,.76,0),.017,.016,brass,7)
			ART.bone(prop,Vector3(.09,.59,0),Vector3(.09,.76,0),.017,.016,brass,7)
			ART.bone(prop,Vector3(-.09,.76,0),Vector3(.09,.76,0),.016,.016,brass,7)
			var l:=OmniLight3D.new()
			l.light_color=Color("f4ca8c")
			l.light_energy=.95
			l.omni_range=7.5
			l.position=Vector3(0,.28,0)
			prop.add_child(l)
		"torch":
			ART.bone(prop,Vector3(0,-.2,0),Vector3(0,.55,0),.068,.044,handle)
			ART.orb(prop,Vector3(0,.56,0),Vector3(.14,.18,.13),ART.mat(Color("df9d5d"),.3,Color("a8502b")))
			var l:=OmniLight3D.new()
			l.light_color=Color("e8a063")
			l.light_energy=.75
			l.omni_range=4.5
			l.position=Vector3(0,.56,0)
			prop.add_child(l)
		"wood": ART.box(prop,Vector3(0,.22,-.13),Vector3(.21,.18,.45),ART.mat(Color("81694f")))
		"grain": ART.box(prop,Vector3(0,.17,-.13),Vector3(.25,.32,.22),ART.mat(Color("bb9c69")))
		"bread": ART.orb(prop,Vector3(0,.17,-.13),Vector3(.25,.15,.21),ART.mat(Color("a76a3f")),12)
		"stone": ART.stone(prop,Vector3(0,.12,-.13),Vector3(.19,.15,.22),ART.mat(Color("74766e")))
		"herb":
			ART.bone(prop,Vector3(0,-.1,0),Vector3(0,.5,-.02),.03,.01,ART.mat(Color("67795a")))
			for side in [-1,1]: ART.orb(prop,Vector3(side*.12,.27,0),Vector3(.16,.035,.07),ART.mat(Color("71845c")))
		"amber": ART.orb(prop,Vector3(0,.16,-.09),Vector3(.14,.18,.15),ART.mat(Color("b7884a"),.3,Color("78522f")),12)

func create_minimal_reticle() -> void:
	var layer:=CanvasLayer.new()
	layer.name="OnlyNecessaryScreenUI"
	add_child(layer)
	reticle=Label.new()
	reticle.text="·"
	reticle.mouse_filter=Control.MOUSE_FILTER_IGNORE
	reticle.set_anchors_preset(Control.PRESET_CENTER)
	reticle.offset_left=-8; reticle.offset_top=-21
	reticle.add_theme_font_size_override("font_size",28)
	reticle.add_theme_color_override("font_color",Color("d3c5ab"))
	layer.add_child(reticle)
	interaction_hint=Label.new()
	interaction_hint.mouse_filter=Control.MOUSE_FILTER_IGNORE
	interaction_hint.set_anchors_preset(Control.PRESET_CENTER)
	interaction_hint.offset_left=-200;interaction_hint.offset_right=200
	interaction_hint.offset_top=44;interaction_hint.offset_bottom=77
	interaction_hint.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	interaction_hint.add_theme_font_size_override("font_size",14)
	interaction_hint.add_theme_color_override("font_color",Color("c6bba9",.87))
	interaction_hint.text=""
	layer.add_child(interaction_hint)
	survival_label = Label.new()
	survival_label.name = "VitaEtVigorWhenNeeded"
	survival_label.position = Vector2(26,651)
	survival_label.add_theme_font_size_override("font_size",16)
	survival_label.add_theme_color_override("font_color",Color("dcc9a6"))
	survival_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	survival_label.visible = false
	layer.add_child(survival_label)

func create_first_steps() -> void:
	# One compact introductory card, hidden after play begins; H brings it back.
	var layer := CanvasLayer.new()
	layer.name = "FirstStepsOnly"
	layer.layer = 4
	add_child(layer)
	guide_panel = PanelContainer.new()
	guide_panel.name = "FirstSteps"
	guide_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	guide_panel.position = Vector2(26, 25)
	guide_panel.custom_minimum_size = Vector2(310, 0)
	guide_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.055, 0.074, 0.070, 0.91)
	style.border_color = Color(0.53, 0.43, 0.29, 0.85)
	style.set_border_width_all(1)
	style.set_content_margin_all(16)
	guide_panel.add_theme_stylebox_override("panel", style)
	layer.add_child(guide_panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	guide_panel.add_child(v)
	var head := Label.new()
	head.text = "V E R B A"
	head.add_theme_font_size_override("font_size", 19)
	head.add_theme_color_override("font_color", Color("f0d9ad"))
	v.add_child(head)
	var sub := Label.new()
	sub.text = "WASD move · Mouse look · E interact\nG grimoire · B books · N study\n1-3 answers/dialogue · Enter cast\nC familiar orders · V build · H help"
	sub.add_theme_font_size_override("font_size", 14)
	sub.add_theme_color_override("font_color", Color("ded6bf"))
	v.add_child(sub)
	guide_clock = 0.0
	guide_panel.visible = false

func toggle_build_mode() -> void:
	if typing or book.open or conversation_actor != null: return
	build_mode = not build_mode
	if not build_mode and world.construction != null:
		world.construction.hide_preview()

func place_tower_piece() -> Dictionary:
	if not build_mode or world.construction == null:
		return {"ok":false,"message":"Enter build mode with V."}
	var hit: Dictionary = look_hit(15.0)
	var point: Vector3 = hit.get("position",global_position)
	var placed: Dictionary = world.construction.build(build_kind,point,build_face,self)
	say_world(String(placed.get("message","")),
		camera.global_position-camera.global_transform.basis.z*2.4,
		Color("d5d2a2") if bool(placed.get("ok",false)) else Color("d18f84"))
	return placed

func create_conversation_panel() -> void:
	# Appears ONLY while speaking to a person in the world, unlike a
	# permanent RPG dialogue HUD that spoils the exploration.
	var layer := CanvasLayer.new()
	layer.name = "WorldConversationOverlay"
	layer.layer = 6
	add_child(layer)
	conversation_panel = PanelContainer.new()
	conversation_panel.name = "LatinConversation"
	conversation_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	conversation_panel.offset_left = -378
	conversation_panel.offset_right = 378
	conversation_panel.offset_top = -302
	conversation_panel.offset_bottom = -20
	var frame := StyleBoxFlat.new()
	frame.bg_color = Color(.055,.066,.062,.94)
	frame.border_color = Color(.55,.46,.32,.90)
	frame.set_border_width_all(1)
	frame.set_content_margin_all(16)
	conversation_panel.add_theme_stylebox_override("panel",frame)
	layer.add_child(conversation_panel)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation",9)
	conversation_panel.add_child(stack)
	conversation_name = Label.new()
	conversation_name.add_theme_font_size_override("font_size",21)
	conversation_name.add_theme_color_override("font_color",Color("ead3a7"))
	stack.add_child(conversation_name)
	conversation_body = Label.new()
	conversation_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	conversation_body.add_theme_font_size_override("font_size",16)
	conversation_body.add_theme_color_override("font_color",Color("e2dac9"))
	stack.add_child(conversation_body)
	conversation_options = Label.new()
	conversation_options.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	conversation_options.add_theme_font_size_override("font_size",15)
	conversation_options.add_theme_color_override("font_color",Color("cbbda4"))
	stack.add_child(conversation_options)
	conversation_panel.visible = false

func _npc_in_conversation_reach(actor: Node3D) -> bool:
	if not is_instance_valid(actor) or camera == null: return false
	if global_position.distance_to(actor.global_position) > 4.3:
		return false
	# Actor collider is a physical ray target. The line of sight must hit
	# that collider BEFORE any wall; this prevents talking through houses.
	var origin: Vector3 = camera.global_position
	var target: Vector3 = actor.global_position + Vector3.UP*1.28
	var ray := PhysicsRayQueryParameters3D.create(origin,target)
	ray.collision_mask = 4 | 16
	ray.exclude = [get_rid()]
	var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(ray)
	var body = hit.get("collider",null)
	return body != null and body.has_meta("npc_ref") and body.get_meta("npc_ref") == actor

func begin_conversation(actor: Node3D) -> bool:
	if typing or book.open or conversation_actor != null:
		return false
	if not is_instance_valid(actor): return false
	if not actor.has_method("is_talkable") or not actor.is_talkable():
		return false
	if not _npc_in_conversation_reach(actor): return false
	conversation_actor = actor
	conversation_reply = ""
	refresh_conversation()
	return true

func refresh_conversation() -> void:
	if conversation_actor == null or not is_instance_valid(conversation_actor):
		conversation_panel.visible = false
		return
	var state: Dictionary = world.social.view(
		conversation_actor.npc_id,world.scholar,inventory)
	conversation_name.text = String(state.get("name","")) + "  /  " + String(state.get("role",""))
	conversation_body.text = conversation_reply if not conversation_reply.is_empty() else String(state.get("spoken",""))
	var choices: Array = state.get("options",[])
	var lines: PackedStringArray = PackedStringArray()
	for choice in choices:
		var suffix: String = "" if bool(choice.get("available",true)) else "   [unavailable]"
		lines.append("%d. %s%s" % [int(choice.get("index",0))+1,
			String(choice.get("label","")),suffix])
	conversation_options.text = "\n".join(lines) + "\n\n1–4 respond     Esc / E leave"
	conversation_panel.visible = true

func choose_conversation_option(index: int) -> Dictionary:
	if conversation_actor == null or not is_instance_valid(conversation_actor):
		return {"ok":false,"message":"No conversation is open."}
	var result: Dictionary = world.social.choose(
		conversation_actor.npc_id,index,world.scholar,self)
	conversation_reply = String(result.get("message",""))
	refresh_conversation()
	if bool(result.get("changed",false)) and DisplayServer.get_name() != "headless":
		world.save_world()
	return result

func end_conversation() -> void:
	conversation_actor = null
	conversation_reply = ""
	if is_instance_valid(conversation_panel): conversation_panel.visible = false

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index==MOUSE_BUTTON_LEFT and event.pressed and build_mode and Input.mouse_mode==Input.MOUSE_MODE_CAPTURED:
			place_tower_piece()
			get_viewport().set_input_as_handled()
			return
		if event.button_index==MOUSE_BUTTON_LEFT and event.pressed and Input.mouse_mode!=Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode=Input.MOUSE_MODE_CAPTURED
			get_viewport().set_input_as_handled()
			return
		if event.pressed and book.open:
			if event.button_index==MOUSE_BUTTON_WHEEL_DOWN:
				book.turn_page(1);get_viewport().set_input_as_handled();return
			if event.button_index==MOUSE_BUTTON_WHEEL_UP:
				book.turn_page(-1);get_viewport().set_input_as_handled();return
	if event is InputEventMouseMotion and Input.mouse_mode==Input.MOUSE_MODE_CAPTURED and not book.open and conversation_actor == null:
		rotation.y-=event.relative.x*mouse_sensitivity
		pitch.rotation.x=clampf(pitch.rotation.x-event.relative.y*mouse_sensitivity,-1.44,1.44)
		get_viewport().set_input_as_handled()
		return
	if not (event is InputEventKey) or not event.pressed or event.echo: return
	if build_mode:
		if event.keycode in [KEY_ESCAPE,KEY_V]:
			toggle_build_mode()
		elif event.keycode==KEY_R:
			build_face=posmod(build_face+1,4)
		elif event.keycode >= KEY_1 and event.keycode <= KEY_9:
			build_kind=world.construction.get_build_choices()[event.keycode-KEY_1]
		elif event.keycode==KEY_E:
			interact()
		get_viewport().set_input_as_handled()
		return
	if conversation_actor != null:
		if event.keycode == KEY_ESCAPE or event.keycode == KEY_E:
			end_conversation()
		elif event.keycode >= KEY_1 and event.keycode <= KEY_4:
			choose_conversation_option(event.keycode-KEY_1)
		get_viewport().set_input_as_handled()
		return
	if event.keycode==KEY_ESCAPE:
		if typing:
			typing=false;buffer="";echo.text=""
		elif book.open: book.toggle()
		else: Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
		get_viewport().set_input_as_handled()
		return
	if typing:
		if event.keycode==KEY_ENTER or event.keycode==KEY_KP_ENTER:
			finish_cast()
		elif event.keycode==KEY_BACKSPACE:
			if buffer.length()>0: buffer=buffer.substr(0,buffer.length()-1)
		elif event.unicode>=32 and event.unicode<127 and buffer.length()<48:
			buffer+=String.chr(event.unicode).to_lower()
		echo.text=buffer.to_upper()+"  ◦"
		get_viewport().set_input_as_handled()
		return
	if event.keycode==KEY_F3:
		diagnostics_visible = not diagnostics_visible
		if is_instance_valid(diagnostics): diagnostics.visible = diagnostics_visible
		get_viewport().set_input_as_handled()
		return
	if event.keycode==KEY_H:
		guide_visible = not guide_visible
		guide_clock = 0.0
		if is_instance_valid(guide_panel): guide_panel.visible = guide_visible
		get_viewport().set_input_as_handled()
		return
	if event.keycode==KEY_G:
		guide_visible = false
		if is_instance_valid(guide_panel): guide_panel.visible = false
		book.toggle()
		get_viewport().set_input_as_handled()
		return
	if book.open:
		if book.quiz_open and event.keycode >= KEY_1 and event.keycode <= KEY_3:
			book.submit_answer(event.keycode - KEY_1)
		elif event.keycode == KEY_B:
			book.cycle_books()
		elif event.keycode == KEY_N:
			book.begin_study()
		elif event.keycode==KEY_A or event.keycode==KEY_LEFT:
			book.turn_page(-1)
		elif event.keycode==KEY_D or event.keycode==KEY_RIGHT:
			book.turn_page(1)
		elif event.keycode==KEY_S:
			var preserved: bool = world.save_world()
			say_world("The vale remembers." if preserved else "The record could not be kept.",
				camera.global_position-camera.global_transform.basis.z*2.5,
				Color("e1ce9f"))
		elif event.keycode==KEY_L:
			var recalled: bool = world.load_world()
			say_world("The vale remembers." if recalled else "No earlier world is recorded.",
				camera.global_position-camera.global_transform.basis.z*2.5,
				Color("e1ce9f"))
		get_viewport().set_input_as_handled()
		return
	if event.keycode==KEY_ENTER or event.keycode==KEY_KP_ENTER:
		typing=true
		buffer=""
		echo.text="  ◦"
		get_viewport().set_input_as_handled()
	elif event.keycode==KEY_E:
		interact()
		get_viewport().set_input_as_handled()
	elif event.keycode==KEY_V:
		toggle_build_mode()
		get_viewport().set_input_as_handled()
	elif event.keycode==KEY_C:
		var order: Dictionary = world.cycle_familiar_order()
		say_world(String(order.get("message","")),camera.global_position-camera.global_transform.basis.z*2.3,Color("c2d4b8"))
		get_viewport().set_input_as_handled()
	elif event.keycode==KEY_F:
		use_item()
		get_viewport().set_input_as_handled()
	elif event.keycode==KEY_Q:
		drop_item()
		get_viewport().set_input_as_handled()
	elif event.keycode>=KEY_1 and event.keycode<=KEY_6:
		selected_slot=clampi(event.keycode-KEY_1,0,maxi(0,inventory.size()-1))
		refresh_held_model()
		get_viewport().set_input_as_handled()

func _physics_process(delta: float) -> void:
	damage_immunity = maxf(0.0,damage_immunity-delta)
	if damage_immunity <= 0.0 and health < max_health:
		# Slow natural recovery gives herbs a reason to matter.
		health = minf(max_health,health+delta*.045)
	# Actual CharacterBody3D movement: floor snapping, gravity, wall sliding, jumping.
	# Unlike v1.1, nothing teleports the player to a procedural terrain-height
	# function; ground and objects are real physics colliders.
	var horizontal: float = float(int(_is_move_key(KEY_D, "verba_right")) - int(_is_move_key(KEY_A, "verba_left")))
	var vertical: float = float(int(_is_move_key(KEY_S, "verba_backward")) - int(_is_move_key(KEY_W, "verba_forward")))
	var axes := Vector2(horizontal, vertical).normalized()
	last_motion = axes
	var direction := global_transform.basis * Vector3(axes.x, 0.0, axes.y)
	var active: bool = not typing and not book.open and conversation_actor == null
	var sprinting: bool = active and axes.length_squared() > .02 and stamina > 4.0 and _is_move_key(KEY_SHIFT, "verba_sprint")
	if sprinting:
		stamina = maxf(0.0,stamina-delta*14.0)
	else:
		stamina = minf(max_stamina,stamina+delta*11.0)
	var target_speed: float = (run_speed if sprinting else speed) if active else 0.0
	velocity.x = direction.x * target_speed if active else 0.0
	velocity.z = direction.z * target_speed if active else 0.0
	if is_on_floor():
		if velocity.y < 0.0: velocity.y = -0.15
		if active and stamina >= 9.0 and _is_move_key(KEY_SPACE, "verba_jump"):
			velocity.y = jump_speed
			stamina = maxf(0.0,stamina-9.0)
	else:
		velocity.y -= gravity * delta
	move_and_slide()
	if active and axes.length_squared() > 0.001:
		guide_clock += delta * 3.0
	# Safety recovery only; ordinary movement never uses a height snap.
	if global_position.y < -35.0 and is_instance_valid(world):
		global_position = Vector3(0.0, world.height_at(0.0, 26.0) + 0.45, 26.0)
		velocity = Vector3.ZERO

func _is_move_key(key_code: Key, action_name: String) -> bool:
	return Input.is_key_pressed(key_code) or Input.is_physical_key_pressed(key_code) or Input.is_action_pressed(action_name)

func create_diagnostics() -> void:
	var layer := CanvasLayer.new()
	layer.name = "OptionalMovementDiagnostics"
	add_child(layer)
	diagnostics = Label.new()
	diagnostics.name = "F3Diagnostics"
	diagnostics.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	diagnostics.offset_left = -410
	diagnostics.offset_right = -15
	diagnostics.offset_top = 15
	diagnostics.offset_bottom = 70
	diagnostics.add_theme_color_override("font_color",Color("e5d7a9"))
	diagnostics.add_theme_font_size_override("font_size",15)
	diagnostics.visible = false
	layer.add_child(diagnostics)

func _process(delta: float) -> void:
	if not is_instance_valid(world): return
	if world.scholar != null: world.scholar.regenerate(delta)
	if build_mode:
		var spot: Vector3 = look_hit(15.0)["position"]
		var assessment: Dictionary = world.construction.show_preview(build_kind,spot,build_face,inventory)
		interaction_hint.text = "BUILD %s  ·  %s  ·  Click place / 1-3 part / R rotate / V exit" % [
			build_kind,String(assessment.get("message",""))]
	elif not typing and not book.open and conversation_actor == null:
		var nearest:Dictionary=look_hit(3.8)
		if nearest.has("entity") and nearest["entity"]!=null:
			var n=nearest["entity"]
			if n.has_method("is_talkable"): interaction_hint.text="E  ·  Speak with "+n.display_name
			elif n.has_method("afflict"):
				if String(n.persistent_id) == world.familiar_id:
					interaction_hint.text="Your familiar  ·  C orders / Enter Latin"
				elif world.familiar_id.is_empty() and n.species in ["hare","crow"]:
					interaction_hint.text="E  ·  Befriend "+n.species+"  /  Enter cast"
				else:
					interaction_hint.text=n.species.capitalize()+"  ·  Enter to cast"
			elif n.has_meta("workplace_kind"): interaction_hint.text="E  ·  Inspect workshop"
			elif n.has_meta("resource_deposit"): interaction_hint.text="E  ·  Salvage wood"
			elif n.has_method("apply_effect") and String(n.kind)=="stone": interaction_hint.text="E  ·  Gather stone"
			elif n.has_method("apply_effect") and String(n.kind) in ["grass","fern"]:
				interaction_hint.text="E  ·  Harvest herb" if not n.dead and not n.burning and n.food>=.65 else n.get_state_report()
			elif n.has_method("get_state_report"): interaction_hint.text=n.get_state_report()
			elif n.has_method("setup") and n.item_type=="leaf": interaction_hint.text="E  ·  Study manuscript leaf"
			elif n.has_method("setup") and n.item_type=="book": interaction_hint.text="E  ·  Read Latin volume"
			elif n.has_method("setup"): interaction_hint.text="E  ·  Take "+n.item_type
			else: interaction_hint.text=""
		else: interaction_hint.text=""
	else: interaction_hint.text=""
	guide_clock += delta
	if guide_visible and guide_clock > 5.0:
		guide_visible = false
	if is_instance_valid(guide_panel): guide_panel.visible = guide_visible
	if is_instance_valid(diagnostics) and diagnostics_visible:
		diagnostics.text = "WASD: %s  pos: %.1f, %.1f, %.1f\nMouse: %s  Book: %s  Typing: %s" % [str(last_motion),global_position.x,global_position.y,global_position.z,str(Input.mouse_mode),str(book.open),str(typing)]
	if is_instance_valid(survival_label):
		survival_label.visible = health < max_health-.05 or stamina < max_stamina-.5
		if survival_label.visible:
			survival_label.text = "VITA  %d / %d     VIGOR  %d / %d" % [
				ceili(health),int(max_health),ceili(stamina),int(max_stamina)]
			survival_label.add_theme_color_override("font_color",
				Color("df9187") if health < 35.0 else Color("dcc9a6"))
	reticle.visible=not book.open and not typing and conversation_actor == null and Input.mouse_mode==Input.MOUSE_MODE_CAPTURED
	held.visible=not book.open and conversation_actor == null and not held_type.is_empty()
	if held.visible:
		held.position.y=-.60+sin(Time.get_ticks_msec()*.001*2)*.012
	# No permanent mouse-look tutorial overlay spoiling first-person composition.

func look_hit(distance: float=18.0) -> Dictionary:
	var eye=camera.global_position
	var forward=-camera.global_transform.basis.z
	var query=PhysicsRayQueryParameters3D.create(eye,eye+forward*distance)
	query.collision_mask=1|4|16
	query.exclude=[get_rid()]
	var hit=get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty(): return {"position":eye+forward*distance,"entity":null}
	var body=hit.get("collider",null)
	var entity:Node3D=null
	if body !=null:
		for meta_key in ["creature_ref","flora_ref","pickup_ref","npc_ref","harvest_ref","tower_ref"]:
			if body.has_meta(meta_key): entity=body.get_meta(meta_key);break
		if entity==null and body.has_meta("workplace_kind"): entity=body
	return {"position":hit["position"],"entity":entity}

func interact() -> void:
	var r=look_hit(4.0)
	var n=r.get("entity",null)
	# Nearby fallback: looking at a tiny object should not require pixel-perfect aim.
	if n == null:
		var nearest_dist:float = 2.6
		for candidate in world.items:
			if not is_instance_valid(candidate): continue
			var distance_to_item:float = global_position.distance_to(candidate.global_position)
			if distance_to_item < nearest_dist and _pickup_visible(candidate):
				nearest_dist = distance_to_item
				n = candidate
	if n==null or not is_instance_valid(n): return
	if n.has_meta("tower_door_key"):
		if global_position.distance_to(n.global_position)>3.5: return
		var door: Dictionary=world.construction.toggle_door(String(n.get_meta("tower_door_key")))
		say_world(String(door.get("message","")),camera.global_position-camera.global_transform.basis.z*2.4,Color("d9cda9"))
		return
	if n.has_meta("tower_shelf_key"):
		if global_position.distance_to(n.global_position)>3.5: return
		var shelved: Dictionary=world.construction.shelve_book(String(n.get_meta("tower_shelf_key")),world.scholar)
		say_world(String(shelved.get("message","")),camera.global_position-camera.global_transform.basis.z*2.4,Color("d9cda9"))
		return
	if n.has_method("is_talkable"):
		begin_conversation(n)
		return
	if n.has_meta("workplace_kind"):
		say_world(world.workplaces.inspect_workplace(String(n.get_meta("workplace_kind"))),
			camera.global_position-camera.global_transform.basis.z*2.4,Color("d9c4a2"))
		return
	if n.has_meta("resource_deposit") or (n.has_method("apply_effect") and String(n.kind) in ["stone","grass","fern"]):
		var gathered: Dictionary = world.harvest_resource(n)
		say_world(String(gathered.get("message","")),
			camera.global_position-camera.global_transform.basis.z*2.2,
			Color("b8cd9d") if bool(gathered.get("ok",false)) else Color("c5a08b"))
		return
	if n.has_method("afflict"):
		var bond: Dictionary = world.bond_animal(n)
		say_world(String(bond.get("message","")),camera.global_position-camera.global_transform.basis.z*2.5,
			Color("c3d3a0") if bool(bond.get("ok",false)) else Color("c3a18b"))
		return
	if n.has_method("setup") and n.has_method("_process") and n.has_method("_ready") and n.get("item_type")!=null:
		world.collect(n)

func _pickup_visible(candidate: Node3D) -> bool:
	# Mouse aim gets a small 2.6m generosity radius, but nearby loot must
	# have line-of-sight. Otherwise items could be stolen through cottage walls.
	var origin: Vector3 = camera.global_position
	var target: Vector3 = candidate.global_position + Vector3.UP*.28
	var query := PhysicsRayQueryParameters3D.create(origin,target)
	query.collision_mask = 4 | 16
	query.exclude = [get_rid()]
	var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return true
	var obstacle = hit.get("collider",null)
	if obstacle == null: return false
	return obstacle.has_meta("pickup_ref") and obstacle.get_meta("pickup_ref") == candidate

func add_item(item_type: String) -> void:
	if inventory.size()>=6:
		say_world("Hands full",camera.global_position-camera.global_transform.basis.z*1.7,Color("c4a98a"))
		return
	inventory.append(item_type)
	selected_slot=inventory.size()-1
	refresh_held_model()

func use_item() -> void:
	if inventory.is_empty(): return
	var point=camera.global_position-camera.global_transform.basis.z*3.2
	var hit=look_hit(4.5)
	var target=hit.get("entity",null)
	match held_type:
		"torch": world.add_fire(hit.get("position",point),target)
		"lantern": say_world("The lantern casts its quiet light.",point,Color("f0d7ac"))
		"herb":
			if target!=null and target.has_method("afflict"):
				target.panic=0;target.asleep=0
			var healed: float = minf(max_health-health,32.0)
			health = minf(max_health,health+32.0)
			say_world("The herb is crushed. Vita +%d" % int(healed),
				point,Color("a4bc8a"))
			inventory.remove_at(selected_slot)
			selected_slot=0;refresh_held_model()
		"bread":
			var recovered: float=minf(max_stamina-stamina,45.0)
			stamina=minf(max_stamina,stamina+45.0)
			say_world("A warm loaf. Vigor +%d" % int(recovered),point,Color("d6b98b"))
			inventory.remove_at(selected_slot)
			selected_slot=0;refresh_held_model()
		"stone":
			var body=RigidBody3D.new()
			body.position=camera.global_position-camera.global_transform.basis.z*1.2
			body.mass=.7
			var collision=CollisionShape3D.new()
			var sphere=SphereShape3D.new()
			sphere.radius=.16
			collision.shape=sphere
			body.add_child(collision)
			ART.stone(body,Vector3.ZERO,Vector3(.17,.13,.19),ART.mat(Color("777a75")))
			world.add_child(body)
			body.linear_velocity=-camera.global_transform.basis.z*11.0+Vector3.UP*1.3
			inventory.remove_at(selected_slot)
			selected_slot=0;refresh_held_model()
		"amber": say_world("Warm amber, held to the light.",point,Color("d6a56f"))

func drop_item() -> void:
	if inventory.is_empty(): return
	var item=held_type
	inventory.remove_at(selected_slot)
	selected_slot=0
	refresh_held_model()
	var p=camera.global_position-camera.global_transform.basis.z*1.9
	world.spawn_item(item,"",Vector3(p.x,world.height_at(p.x,p.z),p.z),true)

func take_damage(amount: float, source: String) -> bool:
	# The wolf's attack cooldown and this separate invulnerability gate
	# prevent multi-frame hits from turning a fair encounter into instant death.
	if amount <= 0.0 or damage_immunity > 0.0 or health <= 0.0:
		return false
	health = maxf(0.0,health-amount)
	damage_immunity = 1.4
	if health <= 0.0:
		_recover_from_defeat(source)
	else:
		say_world("Wounded by %s. Vita %d" % [source,ceili(health)],
			camera.global_position-camera.global_transform.basis.z*2.3,
			Color("d08b7f"))
	if DisplayServer.get_name() != "headless":
		world.save_world()
	return true

func _recover_from_defeat(source: String) -> void:
	# Failure has a persistent cost, but never destroys accumulated Latin
	# scholarship or turns an open sandbox into a compulsory reload.
	var fallen_at: Vector3 = global_position
	death_count += 1
	if not inventory.is_empty():
		selected_slot = clampi(selected_slot,0,inventory.size()-1)
		var lost: String = inventory[selected_slot]
		inventory.remove_at(selected_slot)
		world.spawn_item(lost,"",Vector3(fallen_at.x,
			world.height_at(fallen_at.x,fallen_at.z)+.1,fallen_at.z),true)
		selected_slot = 0
		refresh_held_model()
	position = Vector3(0.0,world.height_at(0.0,26.0)+.22,26.0)
	velocity = Vector3.ZERO
	health = 60.0
	stamina = 65.0
	damage_immunity = 5.0
	say_world("You survived %s, but something was lost." % source,
		position+Vector3.UP*1.7,Color("e0bd9f"))

func cast_latin(spoken: String, target: Dictionary) -> Dictionary:
	# Check resources BEFORE applying a physical spell to the world.
	# Failures consume no mana; a successful action pays exactly once.
	if world == null or world.scholar == null:
		return {"ok":false,"message":"No magic source is available."}
	# Grammar mistakes should be reported as grammar mistakes, not disguised
	# as insufficient mana when the player happens to be exhausted.
	var parsed: Dictionary = GRAMMAR.parse(spoken)
	if not bool(parsed.get("ok",false)):
		return {"ok":false,"message":String(parsed.get("message","Unknown Latin."))}
	if not world.scholar.can_cast(spoken):
		return {"ok":false,"message":"Not enough mana. Read, rest, or remember the words."}
	var result: Dictionary = world.magic.cast(spoken,camera.global_position,target)
	if bool(result.get("ok",false)):
		world.scholar.pay_cast(spoken)
	return result

func finish_cast() -> void:
	typing=false
	echo.text=""
	var text_cast=buffer.strip_edges().to_lower()
	buffer=""
	if text_cast.is_empty(): return
	var hit=look_hit(16.0)
	var result: Dictionary = cast_latin(text_cast,hit)
	var display_pos: Vector3=hit.get("position",camera.global_position-camera.global_transform.basis.z*4.0)
	if not result["ok"]:
		say_world(String(result["message"]),camera.global_position-camera.global_transform.basis.z*2.8,Color("c38b7e"))
		return
	var remembered:bool=book.mark_cast(String(result.get("remember_word",text_cast)))
	say_world(text_cast,display_pos+Vector3.UP*1.3,Color("f7dda1") if remembered else Color("d5a869"))
	if not result["message"].is_empty():
		say_world(result["message"],display_pos+Vector3.UP*.35,Color("c9b68d"))
	if not result["wild"].is_empty():
		say_world(result["wild"],camera.global_position-camera.global_transform.basis.z*4.0,Color("a6c7c6"))

func say_world(text_msg: String,where: Vector3,tint: Color=Color("dec48c")) -> void:
	var n=INCANTATION.new()
	world.add_child(n)
	n.begin(text_msg,where,tint)
