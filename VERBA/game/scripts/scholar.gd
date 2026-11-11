extends RefCounted
## Knowledge is progression. No repeated XP by rereading a completed page.
## Stored state contains data only, so it survives Godot scene rebuilds.
const BOOK_PATH: String = "res://data/books.json"
const GRAMMAR = preload("res://scripts/latin_grammar.gd")
const LATIN_PRACTICE = preload("res://scripts/latin_practice.gd")
const EXPERIMENT_JOURNAL = preload("res://scripts/experiment_journal.gd")

var books: Dictionary = {}
var practice = LATIN_PRACTICE.new()
var experiments = EXPERIMENT_JOURNAL.new()
var owned: Array[String] = []
var completed: Array[String] = []
var studied_forms: Array[String] = ["ignis","cresce","pluvia","lux","veni","dormi"]
var subjects: Dictionary = {}
var level: int = 1
var xp: int = 0
var mana: float = 26.0
var max_mana: float = 26.0

func _init() -> void:
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(BOOK_PATH))
	if raw is Array:
		for entry in raw:
			if entry is Dictionary and entry.has("id"):
				books[String(entry["id"])] = entry

func get_book(id: String) -> Dictionary:
	return books.get(id,{})

func has_book(id: String) -> bool:
	return owned.has(id)

func collect_book(id: String) -> bool:
	if not books.has(id) or owned.has(id):
		return false
	owned.append(id)
	return true

func next_level_xp() -> int:
	return 20 + (level-1) * 15

func answer(book_id: String, option_index: int) -> Dictionary:
	if not owned.has(book_id):
		return {"ok":false,"message":"First find the physical book."}
	var entry: Dictionary = get_book(book_id)
	if entry.is_empty():
		return {"ok":false,"message":"Those pages have no meaning."}
	if option_index < 0 or option_index >= entry["options"].size():
		return {"ok":false,"message":"Choose one of the three answers."}
	if option_index != int(entry["answer"]):
		return {"ok":false,"message":"Not quite. Read the passage again."}
	if completed.has(book_id):
		return {"ok":true,"first_time":false,"xp":0,
			"message":String(entry["explanation"]) + "\nAlready mastered."}
	completed.append(book_id)
	var reward: int = int(entry["xp"])
	xp += reward
	var topic: String = String(entry["subject"])
	subjects[topic] = int(subjects.get(topic,0)) + 1
	for form in entry["teaches"]:
		var word: String = String(form)
		if not studied_forms.has(word):
			studied_forms.append(word)
	var level_ups: int = 0
	while xp >= next_level_xp():
		xp -= next_level_xp()
		level += 1
		level_ups += 1
		max_mana += 12.0
	mana = max_mana
	var message: String = String(entry["explanation"]) + "\n+" + str(reward) + " scholarship XP"
	if level_ups > 0:
		message += " | Scholar level " + str(level) + " | Mana " + str(int(max_mana))
	return {"ok":true,"first_time":true,"xp":reward,
		"new_words":entry["teaches"].duplicate(),"levels":level_ups,
		"message":message}

func cost_for(spoken_form: String) -> float:
	# Use the SAME actual Latin parser as casting, not naïve splitting:
	# "crescite, arbores!" and "crescite arbores" have identical mana costs.
	var parsed: Dictionary = GRAMMAR.parse(spoken_form)
	if not bool(parsed.get("ok",false)):
		return INF
	var command: String = String(parsed["command"])
	if String(parsed.get("form",""))=="composed imperative":
		# The first compositional spell is earned through actual manuscript study.
		if not studied_forms.has(command): return INF
		var base: float=9.0+(3.0 if not String(parsed.get("modifier","")).is_empty() else 0.0)
		return base-(1.0 if practice.mastery(command)>=3 else 0.0)
	var base: float=7.0 if studied_forms.has(command) else 16.0
	# A small tangible advantage after actual delayed typed recall, not
	# after simply clicking vocabulary or advancing the game calendar.
	return base-(1.0 if practice.mastery(command)>=3 else 0.0)

func can_cast(spoken_form: String) -> bool:
	return mana >= cost_for(spoken_form)

func pay_cast(spoken_form: String) -> bool:
	var cost: float = cost_for(spoken_form)
	if mana < cost: return false
	mana = maxf(0.0,mana-cost)
	return true

func regenerate(delta: float) -> void:
	mana = minf(max_mana,mana + maxf(0.0,delta)*0.65)

func snapshot() -> Dictionary:
	return {"level":level,"xp":xp,"mana":mana,"max_mana":max_mana,
		"owned":owned.duplicate(),"completed":completed.duplicate(),
		"studied_forms":studied_forms.duplicate(),"subjects":subjects.duplicate(),
		"practice":practice.snapshot(),
		"experiments":experiments.snapshot()}

func restore(data: Dictionary) -> void:
	# Ignore unknown books and reject invented saved words.
	owned.clear()
	completed.clear()
	for id in data.get("owned",[]):
		if books.has(String(id)) and not owned.has(String(id)): owned.append(String(id))
	for id in data.get("completed",[]):
		if owned.has(String(id)) and not completed.has(String(id)): completed.append(String(id))
	studied_forms = ["ignis","cresce","pluvia","lux","veni","dormi"]
	for id in completed:
		var entry: Dictionary = books[id]
		for spell in entry["teaches"]:
			if not studied_forms.has(String(spell)): studied_forms.append(String(spell))
	level = clampi(int(data.get("level",1)),1,99)
	xp = clampi(int(data.get("xp",0)),0,100000)
	max_mana = 26.0 + float(level-1)*12.0
	mana = clampf(float(data.get("mana",max_mana)),0.0,max_mana)
	subjects = {}
	for id in completed:
		var topic: String = String(books[id]["subject"])
		subjects[topic] = int(subjects.get(topic,0)) + 1
	# Existing saves without practice history get a fresh, unlocked review
	# deck; malformed progress cannot create fake wizard mastery bonuses.
	var stored_practice: Variant=data.get("practice",{})
	if not (stored_practice is Dictionary) or not practice.restore(stored_practice):
		practice.restore({})
	# These notes have no effect on study, spells or mana. Legacy and
	# malformed saves safely start with a fresh field record.
	var stored_experiments: Variant = data.get("experiments", {})
	if not (stored_experiments is Dictionary) or not experiments.restore(stored_experiments):
		experiments.restore({})
