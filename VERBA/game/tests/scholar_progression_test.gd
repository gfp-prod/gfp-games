extends SceneTree
const SCHOLAR = preload("res://scripts/scholar.gd")

func _initialize() -> void:
	var scholar = SCHOLAR.new()
	if scholar.books.size() != 3:
		_fail("Expected three distinct Latin books")
		return
	if scholar.has_book("de_herbis") or scholar.cost_for("crescite") <= scholar.cost_for("cresce"):
		_fail("Unstudied magic should cost more")
		return
	if not scholar.collect_book("de_herbis") or scholar.collect_book("de_herbis"):
		_fail("Physical book should only be collected once")
		return
	var wrong: Dictionary = scholar.answer("de_herbis",1)
	if bool(wrong.get("ok",false)) or scholar.xp != 0:
		_fail("Incorrect answer granted scholarship experience")
		return
	var result: Dictionary = scholar.answer("de_herbis",0)
	if not bool(result.get("ok",false)) or not bool(result.get("first_time",false)):
		_fail("Correct Latin comprehension did not complete the book")
		return
	if scholar.level != 2 or scholar.max_mana <= 26.0 or scholar.cost_for("crescite") >= scholar.cost_for("ardete"):
		_fail("Reading didn't increase level, mana and botany spell fluency")
		return
	var older_xp: int = scholar.xp
	var repeat: Dictionary = scholar.answer("de_herbis",0)
	if int(repeat.get("xp",-1)) != 0 or scholar.xp != older_xp:
		_fail("Rereading a book farmed more XP")
		return
	if scholar.cost_for("crescite, arbores!") != scholar.cost_for("crescite arbores"):
		_fail("Latin punctuation incorrectly changed learned magic mana cost")
		return
	if scholar.cost_for("invalid-latin") != INF:
		_fail("Unknown Latin should not produce a valid magic price")
		return
	if not scholar.pay_cast("crescite") or scholar.mana >= scholar.max_mana:
		_fail("Memorized spell did not consume mana")
		return
	var preserved: Dictionary = scholar.snapshot()
	var restored = SCHOLAR.new()
	restored.restore(preserved)
	if restored.level != scholar.level or absf(restored.mana-scholar.mana)>.001 or not restored.completed.has("de_herbis"):
		_fail("Read knowledge and mana did not survive restoration")
		return
	if restored.cost_for("crescite") != scholar.cost_for("crescite"):
		_fail("Subject spell knowledge did not survive restoration")
		return
	print("PASS: physical Latin book, wrong/correct comprehension, one-time XP, level and mana growth, spell fluency and save/restore")
	quit(0)

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
