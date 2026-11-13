extends RefCounted
## VISUAL LANGUAGE: ash-black iron, bruised leather, smoked parchment and
## aged brass. Shared by every visible screen control; no neon HUD widgets.
## Fonts remain OS-installed; no bundled proprietary font files.
static func palette(key: String) -> Color:
	match key:
		"iron": return Color("171b1b")
		"charcoal": return Color("242727")
		"brass": return Color("ad9270")
		"chalk": return Color("dbd0bb")
		"paper": return Color("c6b79f")
		"muted": return Color("999d92")
		"blood": return Color("a96e67")
		"moss": return Color("7e9183")
		"ash": return Color("464b47")
	return Color("d4c8b3")

static func frame(kind: String="dialogue") -> StyleBoxFlat:
	var style:=StyleBoxFlat.new()
	style.bg_color=Color("15191a",.94) if kind!="help" else Color("202321",.94)
	style.border_color=Color("80715a",.92) if kind=="dialogue" else Color("646255",.86)
	style.set_border_width_all(1)
	style.set_corner_radius_all(2)
	style.set_content_margin_all(14 if kind=="dialogue" else 11)
	style.shadow_color=Color(0,0,0,.56)
	style.shadow_size=5 if kind=="dialogue" else 3
	return style

# An authored, repeatable ash/dust grain on the inside of every panel:
# subtle enough for Latin to stay readable. Created in-memory once and
# shared, not loaded from a third-party UI texture pack.
static var _grit: Texture2D

static func _grit_texture() -> Texture2D:
	if _grit!=null:
		return _grit
	var noise:=RandomNumberGenerator.new()
	noise.seed=194612
	var picture:=Image.create(128,128,false,Image.FORMAT_RGBA8)
	for y in range(128):
		for x in range(128):
			var variation: float=noise.randf()
			var line: bool=(x+y*3)%97==0 or (y==31 and x>22 and x<71)
			var transparency: float=.022+variation*.035
			if line: transparency+=.065
			if noise.randf()<.003:
				transparency+=.13
			picture.set_pixel(x,y,Color(.65,.59,.48,transparency))
	_grit=ImageTexture.create_from_image(picture)
	return _grit

static func _grained(panel: PanelContainer) -> void:
	if panel.get_node_or_null("AuthoredIronAndVellumGrain")!=null:
		return
	# A PanelContainer lays out two children in the same inset region.
	# The grain is first, behind its text; it never intercepts input.
	var shade:=TextureRect.new()
	shade.name="AuthoredIronAndVellumGrain"
	shade.texture=_grit_texture()
	shade.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	shade.stretch_mode=TextureRect.STRETCH_TILE
	shade.mouse_filter=Control.MOUSE_FILTER_IGNORE
	shade.custom_minimum_size=Vector2.ZERO
	panel.add_child(shade)
	panel.move_child(shade,0)
	panel.clip_contents=true

static func rule() -> HSeparator:
	var divider:=HSeparator.new()
	divider.name="ThinBrassRule"
	var style:=StyleBoxLine.new()
	style.color=Color("95836b",.62)
	style.thickness=1
	divider.add_theme_stylebox_override("separator",style)
	divider.custom_minimum_size.y=5
	return divider

static func label(node: Label, role: String="body") -> void:
	var font_size: int=15
	var pigment: Color=palette("chalk")
	match role:
		"title":
			font_size=19
			pigment=palette("brass")
		"dialogue":
			font_size=16
			pigment=palette("chalk")
		"options":
			font_size=14
			pigment=palette("paper")
		"input":
			font_size=15
			pigment=Color("d9b98e")
		"status":
			font_size=14
			pigment=palette("chalk")
		"hint":
			font_size=13
			pigment=Color("d5c4aa")
		"quiet":
			font_size=13
			pigment=palette("muted")
	node.add_theme_font_size_override("font_size",font_size)
	node.add_theme_color_override("font_color",pigment)
	node.add_theme_color_override("font_shadow_color",Color("080a0a",.48))
	node.add_theme_constant_override("shadow_offset_x",1)
	node.add_theme_constant_override("shadow_offset_y",1)

static func dress_player(player) -> void:
	if player.conversation_panel!=null:
		player.conversation_panel.add_theme_stylebox_override("panel",frame("dialogue"))
		_grained(player.conversation_panel)
		label(player.conversation_name,"title")
		label(player.conversation_body,"dialogue")
		label(player.conversation_options,"options")
		label(player.conversation_footer,"input")
	if player.guide_panel!=null:
		player.guide_panel.add_theme_stylebox_override("panel",frame("help"))
		_grained(player.guide_panel)
		# The first-day field notes belong to the same carved-iron typography
		# as Latin conversation and the physical grimoire. Keep the text
		# accessible and compact at 720p instead of an unrelated bright HUD.
		for child in player.guide_panel.find_children("*","Label",true,false):
			var sheet: Label=child as Label
			if sheet==null: continue
			var major: bool=sheet.text.begins_with("V E R B A")
			label(sheet,"title" if major else "hint")
			if major:
				sheet.add_theme_color_override("font_color",Color("c1a07a"))
			else:
				sheet.add_theme_color_override("font_color",Color("d6cab3"))
	if player.interaction_plate!=null:
		player.interaction_plate.add_theme_stylebox_override("panel",frame("small"))
		_grained(player.interaction_plate)
		label(player.interaction_hint,"hint")
	if player.survival_plate!=null:
		player.survival_plate.add_theme_stylebox_override("panel",frame("small"))
		_grained(player.survival_plate)
		label(player.survival_label,"status")
	if player.reticle!=null:
		label(player.reticle,"quiet")
		player.reticle.text="·"
		player.reticle.add_theme_font_size_override("font_size",22)
	if player.diagnostics!=null:
		label(player.diagnostics,"quiet")
	if player.echo!=null:
		player.echo.modulate=Color("bc9e7d")

static func dress_grimoire(book) -> void:
	for index in range(book.page_labels.size()):
		var leaf: Label3D=book.page_labels[index]
		leaf.modulate=Color("312821") if index==0 else Color("393027")
		leaf.outline_size=0
