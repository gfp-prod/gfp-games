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
		label(player.conversation_name,"title")
		label(player.conversation_body,"dialogue")
		label(player.conversation_options,"options")
		label(player.conversation_footer,"input")
	if player.guide_panel!=null:
		player.guide_panel.add_theme_stylebox_override("panel",frame("help"))
	if player.interaction_plate!=null:
		player.interaction_plate.add_theme_stylebox_override("panel",frame("small"))
		label(player.interaction_hint,"hint")
	if player.survival_plate!=null:
		player.survival_plate.add_theme_stylebox_override("panel",frame("small"))
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
