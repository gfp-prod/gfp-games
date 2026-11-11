extends RefCounted
## Persistent, graded Latin conversation rules. The content is editable JSON,
## and this tiny deterministic state machine owns no UI/physics resources.
## Topics reward relationship ONCE; revisiting is not a rapport exploit.
const NPC_DATA = "res://data/npcs.json"

var definitions: Dictionary = {}
var memories: Dictionary = {}

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
	return memories.get(id, {"topics": [], "rapport": 0, "traded": false})

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
	var spoken: String = String(introductions[mini(tier, introductions.size()-1)])
	if int(past.get("rapport", 0)) >= 2:
		spoken += "\nYou are remembered here."
	return {"id": id, "name": String(definition["name"]),
		"role": String(definition.get("role", "")),
		"spoken": spoken, "options": menu,
		"rapport": int(past.get("rapport", 0)), "stage": tier}

func _reason(choice: Dictionary, scholar, inventory: Array, past: Dictionary) -> String:
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
	return ""

func choose(id: String, index: int, scholar, player) -> Dictionary:
	var definition: Dictionary = npc(id)
	if definition.is_empty(): return {"ok": false, "message": "There is nobody to speak with."}
	var options: Array = definition.get("choices", [])
	if index < 0 or index >= options.size():
		return {"ok": false, "message": "Choose a spoken response."}
	var choice: Dictionary = options[index]
	var previous: Dictionary = memory(id)
	var blocked: String = _reason(choice, scholar, player.inventory, previous)
	if not blocked.is_empty():
		return {"ok": false, "message": blocked, "changed": false}
	var reward: String = String(choice.get("grants_book", ""))
	var required_item: String = String(choice.get("requires_item", ""))
	# Preconditions above are checked before the item is removed. Collecting
	# a book happens exactly once even across reloads or repeated conversations.
	if not reward.is_empty():
		if not scholar.collect_book(reward):
			return {"ok": false, "message": "You already carry this volume."}
		player.inventory.erase(required_item)
		player.selected_slot = clampi(player.selected_slot, 0,
			maxi(0, player.inventory.size()-1))
		player.refresh_held_model()
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
	if not reward.is_empty():
		speech += "\nDe Igne et Aqua is now among your books. G opens your grimoire."
	return {"ok": true, "changed": true, "message": speech,
		"reward_book": reward, "rapport": int(previous["rapport"])}

func snapshot() -> Dictionary:
	var out: Dictionary = {}
	for id in definitions.keys():
		if not memories.has(id): continue
		var record: Dictionary = memory(String(id))
		out[id] = {"topics": record.get("topics", []).duplicate(),
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
		memories[id] = {"topics": valid_topics,
			"rapport": mini(6, valid_topics.size()),
			"traded": bool(record.get("traded", false)) if id == "tomas" else false}
