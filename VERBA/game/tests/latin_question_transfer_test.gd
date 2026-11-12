extends SceneTree
## Comprehensible Latin questions are productive, reusable social language:
## the same question receives DIFFERENT reports depending on witnessed events.
const PERSIST=preload("res://scripts/world_persistence.gd")

func _initialize() -> void:
	call_deferred("_run")

func _fail(reason: String) -> void:
	push_error("Latin question transfer: "+reason)
	quit(1)

func _run() -> void:
	var world=load("res://main.tscn").instantiate()
	root.add_child(world)
	await process_frame
	var social=world.social
	var scholar=world.scholar
	var player=world.player
	# Latin cannot be guessed into fluency before comprehending the real page.
	var early: Dictionary=social.speak("ida","Quid novi?",scholar,player)
	if bool(early.get("ok",false)) or not social.memories.is_empty():
		_fail("Unstudied shared Latin reported news or granted social credit")
		return
	if not scholar.collect_book("de_herbis") or not bool(scholar.answer("de_herbis",0).get("first_time",false)):
		_fail("Required physical primer is unavailable")
		return
	var experience_before: int=scholar.xp
	var ida_model: String=String(social.view("ida",scholar,player.inventory).get("spoken",""))
	var daro_model: String=String(social.view("daro",scholar,player.inventory).get("spoken",""))
	if not ida_model.contains("Ida calls to a customer: 'Quid novi?'") or not daro_model.contains("Daro asks a farmhand, 'Quid facis hodie?'"):
		_fail("Villagers do not model reusable Latin questions naturally in conversation")
		return
	# The same real theft is visible ONLY to its actual witnesses.
	if not world.village_sim.witness_event("theft","orin","ida"):
		_fail("Theft scenario could not be registered by the real village simulation")
		return
	var incident: Dictionary=world.village_sim.events.back()
	if not incident.get("witnesses",[]).has("ida"):
		_fail("The village failed to give the victim knowledge of the theft")
		return
	var informed: Dictionary=social.speak("ida","Quid novi?",scholar,player)
	if not bool(informed.get("ok",false)) or not String(informed.get("message","")).contains("stole"):
		_fail("A witnessed theft was not reported in response to produced Latin")
		return
	if not social.memory("ida").get("spoken_topics",[]).has("rumors"):
		_fail("Real productive Latin was not distinguished from menu help")
		return
	if String(social.view("ida",scholar,player.inventory).get("spoken","")).contains("Ida calls to a customer: 'Quid novi?'"):
		_fail("The novice modeling phrase did not fade after real Latin production")
		return
	var unknown_id: String=""
	for candidate in world.village_sim.people.keys():
		var key: String=String(candidate)
		if not incident.get("witnesses",[]).has(key) and social.npc(key).get("choices",[]) is Array:
			for choice in social.npc(key).get("choices",[]):
				if choice is Dictionary and String(choice.get("id",""))=="rumors":
					unknown_id=key
					break
		if not unknown_id.is_empty():
			break
	if unknown_id.is_empty():
		_fail("Cannot find an uninformed NPC who can discuss local news")
		return
	var uninformed: Dictionary=social.speak(unknown_id,"Novi quid?",scholar,player)
	if not bool(uninformed.get("ok",false)) or String(uninformed.get("message","")).contains("stole"):
		_fail("Word-order tolerant Latin fabricated a report from a non-witness")
		return
	# Another attested syntax moves between NPCs without duplicating content.
	var farm_work: Dictionary=social.speak("daro","Quid facis hodie?",scholar,player)
	if not bool(farm_work.get("ok",false)) or String(social.view("daro",scholar,player.inventory).get("spoken","")).contains("Daro asks a farmhand, 'Quid facis hodie?'"):
		_fail("A farm worker cannot respond to actual Latin or still overexplains a mastered question")
		return
	var tomorrow: Dictionary=social.speak("ida","Quid facis hodie?",scholar,player)
	if not bool(tomorrow.get("ok",false)) or not social.memory("ida").get("spoken_topics",[]).has("work"):
		_fail("The same learned question cannot elicit an NPC's existing work")
		return
	for invalid in ["Quid novi in oppidum?", "Quid novum?", "Quid facit?"]:
		if bool(social.speak("ida",invalid,scholar,player).get("ok",false)):
			_fail("Unauthored or incorrectly inflected Latin was accepted: "+invalid)
			return
	if scholar.xp!=experience_before:
		_fail("Repeating NPC questions granted fake language XP")
		return
	var rapport_before: int=int(social.memory("ida").get("rapport",0))
	social.speak("ida","Quid novi?",scholar,player)
	if int(social.memory("ida").get("rapport",0))!=rapport_before:
		_fail("Repetition farmed friendship")
		return
	var saved: Dictionary=PERSIST.snapshot(world)
	var restored=load("res://main.tscn").instantiate()
	root.add_child(restored)
	await process_frame
	if not PERSIST.apply_snapshot(restored,JSON.parse_string(JSON.stringify(saved))):
		_fail("Produced Latin and witnessed news could not be restored in a fresh world")
		return
	if not restored.social.memory("ida").get("spoken_topics",[]).has("rumors"):
		_fail("Transferred Latin social knowledge was not durable")
		return
	if not String(restored.social.speak("ida","Quid novi in oppido?",restored.scholar,restored.player).get("message","")).contains("stole"):
		_fail("The same witness no longer remembers the witnessed theft after reload")
		return
	print("PASS: learned reusable Latin questions report only witnessed news, preserve grammar, distinguish input, prevent rapport farming and survive fresh-world save")
	quit(0)
