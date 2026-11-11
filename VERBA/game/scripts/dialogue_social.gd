extends RefCounted
## Persistent, graded Latin conversation rules. The content is editable JSON,
## and this tiny deterministic state machine owns no UI/physics resources.
## Topics reward relationship ONCE; revisiting is not a rapport exploit.
const NPC_DATA = "res://data/npcs.json"
const COMMISSIONS = preload("res://scripts/wizard_commissions.gd")
const LATIN_SPEECH = preload("res://scripts/latin_conversation.gd")

var definitions: Dictionary = {}
var memories: Dictionary = {}
var village_sim = null # shared authoritative world; no competing relationship save

func _init() -> void:
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(NPC_DATA))
	if not (data is Array):
		push_error("VERBA social: NPC manifest is missing or invalid")
		return
	for row in data:
		if row is Dictionary and row.has("id"):
			var id: String = String(row["id"])
			if not definitions.has(id):
				definitions[id] = row

func npc(id: String) -> Dictionary:
	return definitions.get(id, {})

func stage(scholar) -> int:
	if scholar == null: return 0
	# The authored Latin percentage responds to BOOK COMPREHENSION, not
	# repeatedly opening a volume, casting a spell, or clicking an NPC.
	return mini(2, scholar.completed.size())

func memory(id: String) -> Dictionary:
	return memories.get(id, {"topics": [], "spoken_topics": [], "rapport": 0, "traded": false})

func view(id: String, scholar, inventory: Array) -> Dictionary:
	var definition: Dictionary = npc(id)
	if definition.is_empty(): return {}
	var tier: int = stage(scholar)
	var past: Dictionary = memory(id)
	var introductions: Array = definition.get("intro", [])
	var lines: Array = definition.get("choices", [])
	var menu: Array[Dictionary] = []
	for idx in range(lines.size()):
		var choice: Dictionary = lines[idx]
		var variants: Array = choice.get("text", [])
		var label: String = String(variants[mini(tier, variants.size()-1)])
		var blocked: String = _reason(choice, scholar, inventory, past)
		menu.append({"index": idx, "label": label,
			"available": blocked.is_empty(), "reason": blocked})
	# Commission choices are generated from authoritative village state, not
	# detached dialogue flags. Never put inaccessible choices in player UI.
	if id=="daro" and village_sim!=null:
		var request_status: String=COMMISSIONS.state(village_sim)
		if request_status=="offered":
			menu.append({"index":4,"label":"Help Daro restore the harvest.","available":true,"reason":""})
			menu.append({"index":5,"label":"Refuse the request.","available":true,"reason":""})
		elif request_status=="ready":
			menu.append({"index":4,"label":"Collect payment for the magical harvest.","available":true,"reason":""})
	var spoken: String = String(introductions[mini(tier, introductions.size()-1)])
	if id=="daro" and village_sim!=null:
		spoken+="\n"+COMMISSIONS.describe(village_sim)
		var confidence: float=float(village_sim.people["daro"]["trust"].get("wizard",0.0))
		if confidence>15.0: spoken+=" Daro speaks to you warmly."
		elif confidence < -8.0: spoken+=" His words have become guarded."
	if id=="tomas" and tier==1 and not bool(past.get("traded",false)):
		spoken += "\nTomas points to his book. 'Da mihi librum.' Give me the book: da, mihi, librum."
	if id=="ida" and tier==1:
		spoken += "\nIda hefts a sack. 'Frumentum tibi fero' means I bring you grain."
	if id=="ida" and village_sim!=null:
		var grain: int=int(village_sim.economy.stocks.get("grain",0))
		if grain<2:
			spoken += "\nThe grain stores are nearly empty. Without flour, the ovens will go cold."
		else:
			spoken += "\nThe ovens have grain enough for another batch."
	if int(past.get("rapport", 0)) >= 2:
		spoken += "\nYou are remembered here."
	return {"id": id, "name": String(definition["name"]),
		"role": String(definition.get("role", "")),
		"spoken": spoken, "options": menu,
		"rapport": int(past.get("rapport", 0)), "stage": tier}

func _reason(choice: Dictionary, scholar, inventory: Array, past: Dictionary, spoken_latin: bool = false) -> String:
	var required_book: String = String(choice.get("requires_completed", ""))
	if not required_book.is_empty() and (scholar == null or not scholar.completed.has(required_book)):
		return String(choice.get("locked", "You have not studied that lesson."))
	var reward: String = String(choice.get("grants_book", ""))
	if not reward.is_empty():
		if scholar == null or not scholar.books.has(reward):
			return "That volume is unavailable."
		if bool(past.get("traded", false)):
			return String(choice.get("already_traded", "That trade is finished."))
		if scholar.has_book(reward):
			return String(choice.get("already_owned", "You already own this book."))
	var required_item: String = String(choice.get("requires_item", ""))
	if not required_item.is_empty() and not inventory.has(required_item):
		return String(choice.get("locked", "You do not have the necessary item."))
	var market_good: String=String(choice.get("market_give",""))
	if not market_good.is_empty():
		if village_sim==null: return "The market is not operating."
		if String(choice.get("id",""))=="grain_exchange" and float(village_sim.people["daro"]["trust"].get("wizard",0.0))<=-15.0:
			return "Daro will not trade until you repair his trust."
		if int(village_sim.economy.stocks.get(market_good,0))<int(choice.get("market_min",1)):
			return "The village has no %s left to exchange." % market_good
		var offered: String=String(choice.get("market_take",""))
		if int(village_sim.economy.stocks.get(offered,0))>=village_sim.economy.CAP:
			return "The storehouse cannot accept more supplies."
	# After the first understood manuscript, a real request replaces the
	# corresponding prewritten trade choice. The beginner route stays open.
	if stage(scholar)>=1 and not spoken_latin and String(choice.get("id","")) in ["trade","baker_delivery"]:
		return "The trader awaits a request in Latin. Press Enter to speak."
	return ""

func speak(id: String, utterance: String, scholar, player) -> Dictionary:
	var definition: Dictionary = npc(id)
	if definition.is_empty():
		return {"ok":false,"changed":false,"message":"Nobody answers."}
	var heard: Dictionary = LATIN_SPEECH.understand(utterance,definition.get("speech",[]),stage(scholar))
	if not bool(heard.get("ok",false)):
		return {"ok":false,"changed":false,"message":String(heard.get("message","The words were not understood."))}
	var topic: String = String(heard.get("topic",""))
	var choices: Array = definition.get("choices",[])
	for index in range(choices.size()):
		if String(choices[index].get("id",""))==topic:
			var response: Dictionary = choose(id,index,scholar,player,true)
			response["latin_understood"] = bool(response.get("ok",false))
			# Genuine productive Latin is a different remembered fact from
			# having heard directions through an English dialogue choice.
			if bool(response["latin_understood"]):
				var record: Dictionary=memory(id)
				var spoken: Array=record.get("spoken_topics",[]).duplicate()
				if not spoken.has(topic): spoken.append(topic)
				record["spoken_topics"]=spoken
				memories[id]=record
			return response
	return {"ok":false,"changed":false,"message":"The listener cannot act upon that request."}

func choose(id: String, index: int, scholar, player, spoken_latin: bool = false) -> Dictionary:
	var definition: Dictionary = npc(id)
	if definition.is_empty(): return {"ok": false, "message": "There is nobody to speak with."}
	if id=="daro" and village_sim!=null and index>=4:
		var status: String=COMMISSIONS.state(village_sim)
		if status=="offered" and index==4: return COMMISSIONS.accept(village_sim)
		if status=="offered" and index==5: return COMMISSIONS.refuse(village_sim)
		if status=="ready" and index==4: return COMMISSIONS.receive_payment(village_sim,player)
		return {"ok":false,"changed":false,"message":"Daro has no such offer at present."}
	var options: Array = definition.get("choices", [])
	if index < 0 or index >= options.size():
		return {"ok": false, "message": "Choose a spoken response."}
	var choice: Dictionary = options[index]
	var previous: Dictionary = memory(id)
	var blocked: String = _reason(choice, scholar, player.inventory, previous, spoken_latin)
	if not blocked.is_empty():
		return {"ok": false, "message": blocked, "changed": false}
	# Asking in English is still a legitimate way to explore. However,
	# only productive Latin establishes the remembered linguistic guidance
	# that can illuminate Mara's physical waystone.
	if id=="mara" and String(choice.get("id",""))=="forest" and not spoken_latin:
		var directions: Array=choice.get("reply",[])
		return {"ok":true,"changed":false,
			"message":String(directions[mini(stage(scholar),directions.size()-1)])}
	var reward: String = String(choice.get("grants_book", ""))
	var required_item: String = String(choice.get("requires_item", ""))
	var market_good: String=String(choice.get("market_give",""))
	if not market_good.is_empty():
		var offered: String=String(choice.get("market_take",""))
		if village_sim==null or not village_sim.economy.player_exchange(id,offered,market_good,player.inventory):
			return {"ok":false,"changed":false,"message":"That exchange is no longer possible."}
		player.selected_slot=clampi(player.selected_slot,0,maxi(0,player.inventory.size()-1))
		player.refresh_held_model()
		var market_replies: Array=choice.get("reply",[])
		var market_speech: String=String(market_replies[mini(stage(scholar),market_replies.size()-1)])
		# The transaction is public to its participants, not globally omniscient.
		village_sim.witness_event("market_trade",id)
		return {"ok":true,"changed":true,"message":market_speech,
			"market_give":market_good,"market_take":offered}
	# Preconditions above are checked before the item is removed. Collecting
	# a book happens exactly once even across reloads or repeated conversations.
	if not reward.is_empty():
		if not scholar.collect_book(reward):
			return {"ok": false, "message": "You already carry this volume."}
		player.inventory.erase(required_item)
		player.selected_slot = clampi(player.selected_slot, 0,
			maxi(0, player.inventory.size()-1))
		player.refresh_held_model()
		if player.world != null:
			player.world.retire_book_pickup(reward)
		if player.book != null:
			player.book.book_cursor = scholar.owned.find(reward)
			player.book.update_pages()
	var topics: Array = previous.get("topics", []).duplicate()
	var topic_id: String = String(choice["id"])
	if not topics.has(topic_id):
		topics.append(topic_id)
	previous["topics"] = topics
	previous["rapport"] = mini(6, topics.size())
	if not reward.is_empty():
		previous["traded"] = true
	memories[id] = previous
	var tier: int = stage(scholar)
	var replies: Array = choice.get("reply", [])
	var speech: String = String(replies[mini(tier, replies.size()-1)])
	if id=="ida" and topic_id=="work" and village_sim!=null:
		if int(village_sim.economy.stocks.get("grain",0))<2:
			speech="There is not enough grain for the ovens. Ask Daro about the harvest."
	if topic_id == "rumors":
		var rumor: String = heard_report(id)
		speech = rumor if not rumor.is_empty() else "I have heard nothing certain. Ask someone who saw it."
	if not reward.is_empty():
		speech += "\nDe Igne et Aqua is now among your books. G opens your grimoire."
	return {"ok": true, "changed": true, "message": speech,
		"reward_book": reward, "rapport": int(previous["rapport"])}

func heard_report(id: String) -> String:
	if village_sim == null or not village_sim.people.has(id): return ""
	var person: Dictionary = village_sim.people[id]
	var known: Array = person.get("known_events",[])
	for i in range(known.size()-1,-1,-1):
		for event in village_sim.events:
			if int(event["id"])!=int(known[i]): continue
			var actor_id: String = String(event["actor"])
			var target_id: String = String(event.get("target",""))
			var actor_name: String = String(npc(actor_id).get("name",actor_id.capitalize()))
			var target_name: String = String(npc(target_id).get("name",target_id.capitalize()))
			match String(event["type"]):
				"theft":
					return "%s stole from %s. I know the people involved." % [actor_name,target_name]
				"law_response":
					return "%s investigated %s over a theft." % [actor_name,target_name]
				"shortage":
					return "Daro lost grain in the harvest. Ida may have trouble baking."
				"courtship":
					return "%s has been courting %s." % [actor_name,target_name]
				"rejection":
					return "%s turned down %s." % [target_name,actor_name]
	return ""

func snapshot() -> Dictionary:
	var out: Dictionary = {}
	for id in definitions.keys():
		if not memories.has(id): continue
		var record: Dictionary = memory(String(id))
		out[id] = {"topics": record.get("topics", []).duplicate(),
			"spoken_topics": record.get("spoken_topics", []).duplicate(),
			"rapport": int(record.get("rapport", 0)),
			"traded": bool(record.get("traded", false))}
	return out

func restore(source: Dictionary) -> void:
	memories.clear()
	for key in definitions.keys():
		var id: String = String(key)
		var record: Variant = source.get(id, {})
		if not (record is Dictionary): continue
		var valid_topics: Array[String] = []
		var legal: Dictionary = {}
		for option in definitions[id].get("choices", []):
			legal[String(option.get("id", ""))] = true
		for topic in record.get("topics", []):
			if topic is String and legal.has(topic) and not valid_topics.has(topic):
				valid_topics.append(topic)
		# Older saves can contain a forest topic earned through English
		# menu assistance. Never infer a Latin production event from it.
		var legal_speech: Dictionary={}
		for phrase in definitions[id].get("speech",[]):
			if phrase is Dictionary:
				legal_speech[String(phrase.get("topic",""))]=true
		var validated_speech: Array[String]=[]
		var stored_speech: Variant=record.get("spoken_topics",[])
		if stored_speech is Array:
			for phrase_topic in stored_speech:
				if phrase_topic is String and legal_speech.has(phrase_topic) and not validated_speech.has(phrase_topic):
					validated_speech.append(phrase_topic)
		memories[id] = {"topics": valid_topics,
			"spoken_topics": validated_speech,
			"rapport": mini(6, valid_topics.size()),
			"traded": bool(record.get("traded", false)) if id == "tomas" else false}
