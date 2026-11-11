extends CanvasLayer
## Opt-in in-game development HUD. F8 show/hide, F9 next NPC, F10 +1 day.
## No production gameplay interaction is intercepted while the panel is hidden.
var world
var panel: PanelContainer
var details: RichTextLabel
var selected: int=0
var visible_debug: bool=false
var elapsed: float=0.0

func setup(owner_world: Node3D) -> void:
	world=owner_world

func _ready() -> void:
	layer=100
	panel=PanelContainer.new()
	panel.name="SimulationLabPanel"
	panel.position=Vector2(16,16)
	panel.custom_minimum_size=Vector2(420,400)
	add_child(panel)
	details=RichTextLabel.new()
	details.name="LiveVillageTelemetry"
	details.custom_minimum_size=Vector2(420,400)
	details.bbcode_enabled=false
	panel.add_child(details)
	panel.visible=false

func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo: return
	match event.keycode:
		KEY_F8:
			visible_debug=not visible_debug
			panel.visible=visible_debug
			get_viewport().set_input_as_handled()
		KEY_F9:
			if visible_debug:
				selected=(selected+1)%world.village_sim.people.size()
				_refresh()
				get_viewport().set_input_as_handled()
		KEY_F10:
			if visible_debug:
				world.skip_days(1)
				_refresh()
				get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	if not visible_debug or world==null or world.village_sim==null: return
	elapsed+=delta
	if elapsed>=0.3:
		elapsed=0.0
		_refresh()

func _refresh() -> void:
	var sim=world.village_sim
	var ids: Array=sim.people.keys()
	ids.sort()
	if ids.is_empty(): return
	var id: String=ids[selected%ids.size()]
	var state: Dictionary=sim.inspector(id)
	var p: Dictionary=state["person"]
	var lines: PackedStringArray=[
		"VERBA | SIMULATION LAB",
		"F8 toggle | F9 next person | F10 advance 1 calendar day",
		world.world_calendar.describe(),
		"Wizard commission: "+String(sim.commissions.get("farm_fertility",{}).get("status","offered")),
		"Day %d  Hour %02d  Treasury %d" % [int(sim.tick_count/24),int(sim.tick_count%24),int(state["treasury"])],
		"",
		"%s — %s  [%s]" % [id.to_upper(),p["role"],p["nature"]],
		"Crow %d  Cat %d  Wolf %d" % [p["crow"],p["cat"],p["wolf"]],
		"Hunger %.0f  Fatigue %.0f  Lonely %.0f" % [p["hunger"],p["fatigue"],p["loneliness"]],
		"Coins %d  Mood %.0f  Last %s" % [p["wealth"],p["mood"],p["last_action"]],
		"Spouse %s  Memories %d" % [p["spouse"],p["known_events"].size()],
		"Wizard trust %.0f" % float(p["trust"].get("wizard",0.0)),
		"",
		"NEXT ACTION SCORES"
	]
	for row in state["ranked_actions"]:
		lines.append("  %-12s %5.1f" % [row["action"],row["score"]])
	lines.append("")
	lines.append("STOCKS: grain %d  bread %d  wood %d  ore %d" % [state["stocks"]["grain"],state["stocks"]["bread"],state["stocks"]["wood"],state["stocks"]["ore"]])
	lines.append("tools %d  herb %d  housing %d" % [state["stocks"]["tools"],state["stocks"]["herb"],state["stocks"]["housing"]])
	details.text="\n".join(lines)
