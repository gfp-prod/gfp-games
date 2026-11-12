extends SceneTree
## Every visible interface belongs to one material language without
## obscuring the actual 3D world or losing the Latin text-entry controls.
const STYLE=preload("res://scripts/visual_language.gd")

func _initialize() -> void: call_deferred("_run")
func _fail(message: String) -> void:
	push_error("Worn UI: "+message)
	quit(1)

func _run() -> void:
	root.size=Vector2i(1280,720)
	var world=load("res://main.tscn").instantiate()
	root.add_child(world)
	await process_frame
	var player=world.player
	for node in [player.interaction_plate,player.survival_plate,
			player.guide_panel,player.conversation_panel]:
		if node==null or not (node is PanelContainer):
			_fail("An active UI mode has no coherent physical panel")
			return
		var style: StyleBoxFlat=node.get_theme_stylebox("panel") as StyleBoxFlat
		if style==null or style.border_width_left<1:
			_fail("A user interface surface lost its aged-iron frame")
			return
		var grit: TextureRect=node.get_node_or_null("AuthoredIronAndVellumGrain")
		if grit==null or grit.texture==null or grit.mouse_filter!=Control.MOUSE_FILTER_IGNORE:
			_fail("A panel is still an untextured flat debug rectangle")
			return
	var dialogue_style: StyleBoxFlat=player.conversation_panel.get_theme_stylebox("panel") as StyleBoxFlat
	if dialogue_style.bg_color.a < .89 or dialogue_style.border_color.r<.25:
		_fail("The dialogue reverted to a translucent flat game HUD")
		return
	if player.interaction_plate.visible or player.survival_plate.visible:
		_fail("Floating prompts or survival bars cover a peaceful scene")
		return
	if player.survival_plate.anchor_top < .99:
		_fail("Survival status is tied to a fixed pixel height, not viewport")
		return
	var folio_rules: int=0
	# UI controls are instantiated from code at runtime, without a packed
	# scene owner. Inspect the real VBox children instead of ownership-filtered
	# scene traversal.
	for child in player.conversation_name.get_parent().get_children():
		if child is HSeparator:
			folio_rules+=1
	if folio_rules<2:
		_fail("Dialogue has no visual hierarchy between speech, choices and writing")
		return
	if player.conversation_speech_scroll==null or player.conversation_footer==null:
		_fail("Long NPC speech no longer has independently readable text and Latin entry")
		return
	if player.conversation_footer.get_theme_font_size("font_size")<14:
		_fail("Latin typing has become too small to read")
		return
	if player.book==null or player.book.page_labels.size()!=2:
		_fail("The physical manuscript has no readable written pages")
		return
	for page in player.book.page_labels:
		if page.modulate.r>.35 or page.outline_size!=0:
			_fail("The book still has luminous, thick outlined HUD text")
			return
	if not player.guide_panel.has_theme_stylebox_override("panel") or not player.conversation_panel.has_theme_stylebox_override("panel"):
		_fail("Help and dialogue do not share material styling")
		return
	var fascia=world.workplaces.find_child("MarketTimberNameFascia",true,false)
	var market_sign=world.workplaces.find_child("CarvedWorkplaceSign",true,false)
	if fascia==null or market_sign==null:
		_fail("The village lost its physically backed iron-and-timber signs")
		return
	var signs: Array=world.workplaces.find_children("CarvedWorkplaceSign","Label3D",true,false)
	for sign in signs:
		if sign.font_size>36 or sign.pixel_size>.0027:
			_fail("A shop name has regressed into floating billboard-sized lettering")
			return
	print("PASS: unified worn iron UI, real timber signs, responsive survival, diegetic grimoire, pinned Latin entry and minimal prompts")
	quit(0)
