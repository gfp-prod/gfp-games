extends SceneTree
## End-to-end field experiment regression: real casting, physical grimoire,
## bounded persistent observations, and no counterfeit Latin mastery.
const SCHOLAR = preload("res://scripts/scholar.gd")
const PERSIST = preload("res://scripts/world_persistence.gd")

func _initialize() -> void:
	call_deferred("_run")

func fail(message: String) -> void:
	push_error("VERBA experiment journal: "+message)
	quit(1)

func _run() -> void:
	var scholar = SCHOLAR.new()
	var diary = scholar.experiments
	if not diary.observe("  LŪX!  ", {"ok":true, "message":"The lantern glows."}, "tower", 0):
		fail("A real attested invocation cannot be recorded")
		return
	if diary.entries.size()!=1 or String(diary.entries[0]["latin"])!="lux":
		fail("Latin normalization or entry recording failed")
		return
	if diary.observe("lux.", {"ok":true, "message":"The lantern glows."}, "tower", 0):
		fail("Repeated identical trials on one dawn are treated as discoveries")
		return
	if scholar.level!=1 or scholar.xp!=0 or scholar.practice.progress.size()!=0:
		fail("Experiment notes granted counterfeit language mastery")
		return
	var saved: Dictionary=scholar.snapshot()
	var restored=SCHOLAR.new()
	restored.restore(JSON.parse_string(JSON.stringify(saved)))
	if restored.experiments.entries.size()!=1:
		fail("The scholar's authoritative world snapshot lost field notes")
		return
	var legacy: Dictionary=saved.duplicate(true)
	legacy.erase("experiments")
	restored.restore(legacy)
	if not restored.experiments.entries.is_empty():
		fail("Old saves did not migrate to an empty field notebook")
		return
	var forged: Dictionary=saved.duplicate(true)
	forged["experiments"]["entries"][0]["cause"]="mastery_reward"
	restored.restore(forged)
	if not restored.experiments.entries.is_empty():
		fail("A malformed experiment record survived validation")
		return
	for day in range(50):
		diary.observe("lux", {"ok":true,"message":"Visible effect"}, "tower", day+1)
	if diary.entries.size()!=32 or int(diary.entries[0]["day"])!=50:
		fail("The experiment journal grew without bounds")
		return

	# Actual player input goes through the existing parser and physics magic,
	# then appears on actual page geometry rather than a separate quiz overlay.
	var world=load("res://main.tscn").instantiate()
	root.add_child(world)
	await process_frame
	var target: Dictionary={"position":world.player.global_position+Vector3(0,0,-3)}
	var incorrect: Dictionary=world.player.cast_latin("crescite arbor",target)
	if bool(incorrect.get("ok",true)):
		fail("A plural imperative with a singular addressee was accepted")
		return
	if world.scholar.experiments.entries.size()!=1 or String(world.scholar.experiments.entries[0]["cause"])!="grammar":
		fail("A grammar trial was not observed within the real world")
		return
	var mana_before: float=world.scholar.mana
	var successful: Dictionary=world.player.cast_latin("lux",target)
	if not bool(successful.get("ok",false)) or world.scholar.mana>=mana_before:
		fail("The real light spell or its mana accounting regressed")
		return
	if world.scholar.experiments.entries.size()!=2 or not bool(world.scholar.experiments.entries[0]["worked"]):
		fail("Successful physical magic was not recorded")
		return
	world.scholar.mana=0.0
	var out_of_power: Dictionary=world.player.cast_latin("lux",target)
	if bool(out_of_power.get("ok",true)) or String(world.scholar.experiments.entries[0]["cause"])!="energy":
		fail("An exhausted wizard did not record failed magical effort")
		return
	if world.scholar.experiments.entries.size()!=3 or world.scholar.xp!=0:
		fail("Failures generated XP or did not appear in the grimoire")
		return
	var grimoire=world.player.book
	grimoire.toggle()
	if not grimoire.begin_journal() or not grimoire.journal_open:
		fail("The field journal cannot open inside the actual 3D book")
		return
	if not grimoire.page_labels[0].text.contains("LIBER EXPERIMENTORUM") or not grimoire.page_labels[1].text.contains("OBSERVATIONES"):
		fail("Experiment observations are not inscribed on the vellum")
		return
	grimoire.shift_journal(1)
	if not grimoire.page_labels[0].text.contains("LUX") or grimoire.journal_cursor!=1:
		fail("The wizard cannot turn between observed trials")
		return
	var key=InputEventKey.new()
	key.pressed=true
	key.keycode=KEY_J
	key.unicode=106
	world.player._input(key)
	if grimoire.journal_open:
		fail("J does not leave the physical trial folio")
		return
	var world_save: Dictionary=PERSIST.snapshot(world)
	var fresh=load("res://main.tscn").instantiate()
	root.add_child(fresh)
	await process_frame
	if not PERSIST.apply_snapshot(fresh,JSON.parse_string(JSON.stringify(world_save))):
		fail("The world rejected a save containing real spell observations")
		return
	if fresh.scholar.experiments.entries.size()!=3 or String(fresh.scholar.experiments.entries[0]["cause"])!="energy":
		fail("Recorded experiments were lost or changed across world reload")
		return
	print("PASS: empirical Latin experiments appear on 3D vellum, preserve true world outcomes, reject mastery exploits, and survive world saves")
	quit(0)
