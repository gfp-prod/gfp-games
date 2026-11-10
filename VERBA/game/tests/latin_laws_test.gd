extends SceneTree
## Regressions for real Latin number agreement and actual ecological effects.
const GRAMMAR = preload("res://scripts/latin_grammar.gd")

func _initialize() -> void:
	call_deferred("_test")

func _test() -> void:
	for pair in [
		["cresce","grow","singular"], ["crescite","grow","plural"],
		["venite lupi","come","plural"], ["dormi lupe","sleep","singular"],
		["crescite arbores","grow","plural"], ["arde arbor","kindle","singular"],
		["ignis","kindle","singular"], ["dormite vulpes","sleep","plural"]
	]:
		var form: Dictionary = GRAMMAR.parse(String(pair[0]))
		if not form.get("ok",false) or form.get("effect","") != pair[1] or form.get("number","") != pair[2]:
			_fail("Wrong Latin parsing for: " + str(pair))
			return
	for wrong in ["dormi lupi","crescite arbor","venite lupe","hello","arbor ignis"]:
		if bool(GRAMMAR.parse(wrong).get("ok",false)):
			_fail("Unattested or mismatched Latin accepted: " + wrong)
			return
	var stage: PackedScene = load("res://main.tscn")
	if stage == null:
		_fail("Main world missing")
		return
	var game: Node3D = stage.instantiate()
	root.add_child(game)
	await process_frame
	var world = game
	if world.magic == null or world.player == null:
		_fail("World did not initialize magic and player")
		return
	var wolf: Node3D = null
	for c in world.creatures:
		if c.species == "wolf":
			wolf = c
			break
	if wolf == null:
		_fail("Wolf missing in living valley")
		return
	var plural_result: Dictionary = world.magic.cast(
		"dormite lupi",world.player.camera.global_position,
		{"position":wolf.global_position,"entity":wolf})
	if not bool(plural_result.get("ok",false)) or float(wolf.asleep) < 5.0:
		_fail("Plural Latin did not alter living wolf state")
		return
	if String(plural_result.get("remember_word","")) != "dormite":
		_fail("Grimoire missing plural recall form")
		return
	var oak = null
	for t in world.flora:
		if is_instance_valid(t) and String(t.kind) == "tree":
			oak = t
			break
	if oak == null:
		_fail("Tree not found in valley")
		return
	var old_growth: float = float(oak.growth)
	var grow_result: Dictionary = world.magic.cast(
		"cresce arbor",world.player.camera.global_position,
		{"position":oak.global_position,"entity":oak})
	if not bool(grow_result.get("ok",false)) or float(oak.growth) <= old_growth:
		_fail("Latin address did not change that particular living tree")
		return
	var with_punctuation: Dictionary = world.magic.cast(
		"pluvia!",world.player.camera.global_position,
		{"position":world.player.global_position,"entity":null})
	if not bool(with_punctuation.get("ok",false)) or not world.raining:
		_fail("Punctuated Latin noun naming failed despite valid grammar")
		return
	print("PASS: Latin singular/plural grammar, noun punctuation, targeted wolf sleep and tree growth")
	quit(0)

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
