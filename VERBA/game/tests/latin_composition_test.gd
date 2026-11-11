extends SceneTree
## Native-engine Latin composition tests, including actual state and book gating.
const GRAMMAR = preload("res://scripts/latin_grammar.gd")

func _initialize() -> void:
	call_deferred("_run")
func _fail(message: String) -> void:
	push_error("Latin composition: "+message)
	quit(1)

func _run() -> void:
	for spoken in ["crea herbam","move lapidem","accende lignum","exstingue ignem","move lapidem leniter"]:
		if not bool(GRAMMAR.parse(spoken).get("ok",false)):
			_fail("Valid Latin was rejected: "+spoken)
			return
	for spoken in ["move lapis","crea lapidem","accende lucem","move lapidem frugaliter","crea herbam celeriter","move lapidem velocitas"]:
		if bool(GRAMMAR.parse(spoken).get("ok",true)):
			_fail("Invalid grammar or unavailable effect was accepted: "+spoken)
			return
	var world = load("res://main.tscn").instantiate()
	root.add_child(world)
	await process_frame
	var scholar=world.scholar
	if scholar.can_cast("crea herbam"):
		_fail("Player can compose creation magic without studying Latin")
		return
	if not scholar.collect_book("de_herbis"):
		_fail("Missing herbal volume")
		return
	if not bool(scholar.answer("de_herbis",0).get("first_time",false)):
		_fail("Herbal comprehension not recorded")
		return
	if not scholar.can_cast("crea herbam"):
		_fail("Compositional creation was not unlocked by study")
		return
	var starting: int = world.sim_objects.size()
	var location: Vector3 = Vector3(7,world.height_at(7,3),3)
	var first: Dictionary = world.magic.cast("crea herbam",world.player.camera.global_position,{"position":location})
	if not bool(first.get("ok",false)) or world.sim_objects.size()!=starting+1:
		_fail("Creating a plant did not change actual world objects")
		return
	var herb=world.sim_objects.back()
	if not herb.is_generated or herb.kind!="grass":
		_fail("Created plant lacks persistent simulation identity")
		return
	var mana: float = scholar.mana
	if not scholar.pay_cast("crea herbam") or scholar.mana >= mana:
		_fail("Composed magic is not charged once")
		return
	if not scholar.collect_book("de_motu") or not bool(scholar.answer("de_motu",1).get("first_time",false)):
		_fail("Could not master motion book")
		return
	var stone = null
	for obj in world.sim_objects:
		if obj.kind=="stone":
			stone = obj
			break
	if stone==null:
		_fail("No real stone available to move")
		return
	var prior: float = stone.position.y
	var moved: Dictionary = world.magic.cast("move lapidem leniter",world.player.camera.global_position,{"position":stone.global_position,"entity":stone})
	if not bool(moved.get("ok",false)) or stone.position.y <= prior:
		_fail("Motion did not manipulate a real stone")
		return
	if not scholar.collect_book("de_igne_et_aqua") or not bool(scholar.answer("de_igne_et_aqua",1).get("first_time",false)):
		_fail("Could not master fire and water book")
		return
	var wood = null
	for obj in world.sim_objects:
		if obj.kind=="wood":
			wood=obj
			break
	if wood==null:
		_fail("No physical fuel exists")
		return
	wood.water=0.0
	var lit: Dictionary = world.magic.cast("accende lignum",world.player.camera.global_position,{"position":wood.global_position,"entity":wood})
	if not bool(lit.get("ok",false)) or not wood.burning:
		_fail("Ignition failed to change fuel state")
		return
	var extinguished: Dictionary = world.magic.cast("exstingue ignem",world.player.camera.global_position,{"position":wood.global_position})
	if not bool(extinguished.get("ok",false)) or wood.burning:
		_fail("Targeted fire extinguishing did not stop the blaze")
		return
	print("PASS: Latin grammar, invalid forms, study-gated verb combination, persistent plants, moving stones, fuel ignition and localized extinguishing")
	quit(0)
