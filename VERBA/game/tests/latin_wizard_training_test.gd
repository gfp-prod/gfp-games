extends SceneTree
## A wizard's ink-and-parchment training: typed recall, morphology,
## spaced dawns, consequences for casting, and save/reload.
const PRACTICE=preload("res://scripts/latin_practice.gd")
const SCHOLAR=preload("res://scripts/scholar.gd")
const PERSIST=preload("res://scripts/world_persistence.gd")
func _initialize() -> void: call_deferred("_run")
func fail(message: String) -> void:
	push_error("Wizard Latin training: "+message)
	quit(1)
func _run() -> void:
	var training=PRACTICE.new()
	if training.cards.size()<24 or training.due_count([],0)!=6:
		fail("World manuscripts did not load sufficient contextual grammar; starter deck missing")
		return
	if not training.next_due([],0).has("prompt") or training.next_due([],0)["source"]!="starter":
		fail("The wizard cannot begin with known starter words")
		return
	if training.cards.has("herbis_herbam") and training.eligible(training.cards["herbis_herbam"],[]):
		fail("Unstudied book words incorrectly available for recollection")
		return
	if PRACTICE.normalize(" HĒRBAM! ")!="herbam":
		fail("Latin macrons and punctuation cannot be normalized")
		return
	var wizard=SCHOLAR.new()
	if not wizard.collect_book("de_herbis") or not wizard.answer("de_herbis",0).get("first_time",false):
		fail("The actual physical De Herbis book did not teach spell forms")
		return
	if training.due_count(wizard.completed,0)<=6:
		fail("Reading the Latin volume did not open contextual practice")
		return
	var cost_before: float=wizard.cost_for("crescite")
	if absf(cost_before-7.0)>.01:
		fail("Latin acquisition unexpectedly changed spell costs before practice")
		return
	var first: Dictionary=wizard.practice.submit("herbis_crescite","CRESCE",wizard.completed,0)
	if not first.get("ok",false) or first.get("correct",true) or not String(first["explanation"]).contains("plural"):
		fail("Singular/plural morphology error lacks corrective explanation")
		return
	if wizard.practice.submit("herbis_crescite","crescite",wizard.completed,0).get("ok",true):
		fail("A wizard farmed the same memory exercise twice without another dawn")
		return
	for day in [1,2,5]:
		var result: Dictionary=wizard.practice.submit("herbis_crescite","Crēscite!",wizard.completed,day)
		if not result.get("ok",false) or not result.get("correct",false):
			fail("Delayed, correctly typed Latin was rejected on dawn "+str(day))
			return
	if wizard.practice.mastery("crescite")!=3 or absf(wizard.cost_for("crescite")-6.0)>.01:
		fail("Mastered, repeatedly recalled imperative does not improve actual mana usage")
		return
	var saved: Dictionary=wizard.snapshot()
	var restored=SCHOLAR.new()
	restored.restore(JSON.parse_string(JSON.stringify(saved)))
	if restored.practice.mastery("crescite")!=3 or absf(restored.cost_for("crescite")-6.0)>.01:
		fail("Grimoire memory and real-world mana discount vanished on reload")
		return
	var old: Dictionary=saved.duplicate(true)
	old.erase("practice")
	restored.restore(old)
	if restored.practice.mastery("crescite")!=0 or restored.practice.due_count(restored.completed,0)<6:
		fail("Legacy scholar saves fail to initialize a legal, fresh grimoire")
		return
	var corrupt: Dictionary=saved.duplicate(true)
	corrupt["practice"]["progress"]["forged"]={"due_day":9999999,"last_day":0,"repetitions":999}
	restored.restore(corrupt)
	if restored.practice.mastery("crescite")!=0:
		fail("A fabricated practice record generated fake spell fluency")
		return
	# Inspect the ACTUAL first-person book: no hidden answer appears before
	# attempting the prompt and the player's normal keyboard routes to ink.
	var world=load("res://main.tscn").instantiate()
	root.add_child(world)
	await process_frame
	var book=world.player.book
	if book==null or book.page_labels.size()!=2: fail("Real grimoire pages missing");return
	book.toggle()
	if not book.begin_practice() or not book.practice_open:
		fail("The player's grimoire does not offer memory exercises")
		return
	if not book.page_labels[0].text.contains("EXERCITIA MEMORIAE") or book.page_labels[1].text.contains("CORRIGENDUM"):
		fail("Exercises were not written on diegetic parchment")
		return
	if not book.write_practice_character("h") or not book.write_practice_character("e"):
		fail("The quill does not accept letter-by-letter Latin")
		return
	book.erase_practice_character()
	if book.practice_buffer!="h": fail("The ink cannot be corrected");return
	# G is normally the open/close grimoire shortcut, but during dictation
	# it must be ink, not a screen transition.
	var letter=InputEventKey.new()
	letter.pressed=true
	letter.keycode=KEY_G
	letter.unicode=103
	world.player._input(letter)
	if not book.open or not book.practice_open or book.practice_buffer!="hg":
		fail("A typed Latin letter triggered a gameplay shortcut")
		return
	book.practice_buffer=""
	for ch in "cresce":
		book.write_practice_character(ch)
	var performed: Dictionary=book.submit_practice()
	if not performed.get("ok",false) or not performed.get("correct",false) or not book.practice_answered:
		fail("Actual book cannot accept a correct imperative")
		return
	if not book.page_labels[1].text.contains("BENE"):
		fail("Master's corrective marginalia absent from the physical page")
		return
	var snapshot: Dictionary=PERSIST.snapshot(world)
	var again=load("res://main.tscn").instantiate()
	root.add_child(again)
	await process_frame
	if not PERSIST.apply_snapshot(again,JSON.parse_string(JSON.stringify(snapshot))):
		fail("A character with new wizard training cannot reload the world")
		return
	var recorded: Dictionary=again.scholar.practice.progress
	if not recorded.has("starter_cresce") or int(recorded["starter_cresce"]["due_day"])!=1:
		fail("Real-game grimoire memory is not persisted across world reload")
		return
	if again.scholar.practice.next_due(again.scholar.completed,again.world_calendar.day).get("id","")=="starter_cresce":
		fail("Memories rescheduled by opening/reloading the same world")
		return
	again.skip_days(1)
	if int(again.scholar.practice.progress["starter_cresce"]["due_day"])>again.world_calendar.day:
		fail("A new in-world dawn did not make the learned imperative due")
		return
	# A learned word recalled through consequential wizard action ALSO
	# counts, but only after the player has stopped consulting the book.
	again.player.book.last_consult=-99999.0
	var field: Vector3=Vector3(18.0,again.height_at(18.0,27.0),27.0)
	again.player.global_position=Vector3(18.0,again.height_at(18.0,25.0)+.15,25.0)
	var real_cast: Dictionary=again.player.cast_latin("cresce",{"position":field})
	if not real_cast.get("ok",false) or again.scholar.practice.mastery("cresce")!=2:
		fail("Actually growing the village farm did not count as delayed Latin output")
		return
	var repeated: Dictionary=again.player.cast_latin("cresce",{"position":field})
	if not repeated.get("ok",false) or again.scholar.practice.mastery("cresce")!=2:
		fail("Spam casting within the same day fabricated language fluency")
		return
	# A fully enchanted field is an actual failed world action. Advance
	# until a recall is DUE, then verify that failure grants no progress.
	again.skip_days(3)
	again.village_sim.bless_field(20)
	var vigor_before: float=again.scholar.mana
	var failed_spell: Dictionary=again.player.cast_latin("cresce",{"position":field})
	if failed_spell.get("ok",true) or again.scholar.practice.mastery("cresce")!=2:
		fail("A failed real-world spell incorrectly counted as Latin competence")
		return
	if absf(again.scholar.mana-vigor_before)>.01:
		fail("A failed Latin spell incorrectly took mana")
		return
	print("PASS: diegetic wizard grimoire, contextual Latin morphology, typed retrieval, applied magical output, spaced dawns, corrective notes, true mastery and save-safe learning")
	quit(0)
