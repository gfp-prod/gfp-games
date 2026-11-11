extends RefCounted
## The wizard's memory exercises live inside the physical grimoire.
## Delayed typed retrieval uses the world's own dawns, never the device date.
## No login-day rewards or education-app terms appear in the fiction.
## Fixed expanding intervals are a simple, testable spacing heuristic.
const DATA_PATH: String = "res://data/latin_review.json"
const INTERVAL_DAYS := [1,3,7,14,30,60]
var cards: Dictionary = {}
var progress: Dictionary = {}
var recent_source: String = ""

func _init() -> void:
	var raw: Variant=JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
	if not (raw is Array):
		push_error("VERBA Latin review: no valid curriculum manifest")
		return
	for entry in raw:
		if not (entry is Dictionary): continue
		var card_id: String=String(entry.get("id",""))
		if card_id.is_empty() or cards.has(card_id): continue
		if String(entry.get("prompt","")).is_empty() or String(entry.get("answer","")).is_empty(): continue
		if String(entry.get("mode","")) not in ["form","cloze"]: continue
		cards[card_id]=entry.duplicate(true)

static func normalize(raw_text: String) -> String:
	# Latin macrons aid pronunciation but are not required for keyboard recall.
	var normalized: String=raw_text.to_lower().strip_edges()
	for pair in [["ā","a"],["ē","e"],["ī","i"],["ō","o"],["ū","u"],["ȳ","y"]]:
		normalized=normalized.replace(pair[0],pair[1])
	for mark in [",",".","!","?",";",":"]:
		normalized=normalized.replace(mark," ")
	while normalized.contains("  "):
		normalized=normalized.replace("  "," ")
	return normalized.strip_edges()

func eligible(card: Dictionary, completed: Array) -> bool:
	var source: String=String(card.get("source",""))
	return source=="starter" or completed.has(source)

func due_count(completed: Array, today: int) -> int:
	var due: int=0
	for key in cards:
		if eligible(cards[key],completed) and int(progress.get(key,{}).get("due_day",0))<=today:
			due+=1
	return due

func next_due(completed: Array, today: int) -> Dictionary:
	var due_cards: Array[Dictionary]=[]
	for key in cards:
		var card: Dictionary=cards[key]
		if not eligible(card,completed): continue
		var due_day: int=int(progress.get(key,{}).get("due_day",0))
		if due_day>today: continue
		var entry: Dictionary=card.duplicate(true)
		entry["due_day"]=due_day
		due_cards.append(entry)
	if due_cards.is_empty(): return {}
	# Prioritize overdue material; mix subjects when several are due.
	due_cards.sort_custom(func(a: Dictionary,b: Dictionary) -> bool:
		if int(a["due_day"])!=int(b["due_day"]):
			return int(a["due_day"])<int(b["due_day"])
		return String(a["id"])<String(b["id"])
	)
	for candidate in due_cards:
		if String(candidate["source"])!=recent_source:
			return candidate
	return due_cards[0]

func submit(card_id: String, response: String, completed: Array, today: int) -> Dictionary:
	if not cards.has(card_id):
		return {"ok":false,"message":"This exercise is not written in your grimoire."}
	var card: Dictionary=cards[card_id]
	if not eligible(card,completed):
		return {"ok":false,"message":"Study the source manuscript first."}
	var record: Dictionary=progress.get(card_id,{})
	if int(record.get("due_day",0))>today:
		return {"ok":false,"message":"That word rests in memory. Return after another dawn."}
	var supplied: String=normalize(response)
	if supplied.is_empty(): return {"ok":false,"message":"The parchment awaits your Latin."}
	var correct: bool=supplied==normalize(String(card["answer"]))
	var repetitions: int=int(record.get("repetitions",0))+1 if correct else 0
	var next_interval: int=INTERVAL_DAYS[mini(repetitions-1,INTERVAL_DAYS.size()-1)] if correct else 1
	progress[card_id]={
		"due_day":today+next_interval,"last_day":today,
		"repetitions":repetitions,
		"successes":int(record.get("successes",0))+(1 if correct else 0),
		"lapses":int(record.get("lapses",0))+(0 if correct else 1)
	}
	recent_source=String(card["source"])
	var label: String="BENE" if correct else "CORRIGENDUM"
	# Corrective feedback includes the full model and morphological reason;
	# never mislabel a guessed/recognized item as genuinely recalled.
	var note: String="%s — %s\n%s\n%s\nRevisit after %d dawn(s)." % [
		label,String(card["answer"]),String(card.get("example","")),
		String(card.get("explanation","")),next_interval]
	return {"ok":true,"correct":correct,"answer":String(card["answer"]),
		"interval_days":next_interval,"repetitions":repetitions,"due_day":today+next_interval,
		"message":note,"example":String(card.get("example","")),
		"translation":String(card.get("translation","")),
		"explanation":String(card.get("explanation",""))}

func acknowledge_world_use(command: String, completed: Array, today: int) -> bool:
	# A successful, typed spell is meaning-focused OUTPUT. If enough time
	# has passed since consulting the book (checked by Player), the wizard
	# may prove a due memory by actually changing the world. Never give
	# credit for an invalid spell, a failed physical action, or another use
	# of the same already-recalled word on the same day.
	var form: String=normalize(command)
	var ordered: Array=cards.keys()
	ordered.sort()
	for id in ordered:
		var card: Dictionary=cards[id]
		if normalize(String(card["answer"]))!=form or not eligible(card,completed):
			continue
		if int(progress.get(id,{}).get("due_day",0))>today:
			continue
		var outcome: Dictionary=submit(String(id),form,completed,today)
		return bool(outcome.get("correct",false))
	return false

func mastery(form: String) -> int:
	# Discount only after three successful recalls across scheduled world days.
	# Reading/repeating a passage or skipping ahead in the calendar alone
	# does not increase mastery. A failure resets the current success streak.
	var high: int=0
	for key in progress:
		if cards.has(key) and normalize(String(cards[key]["answer"]))==normalize(form):
			high=maxi(high,int(progress[key].get("repetitions",0)))
	return high

func snapshot() -> Dictionary:
	return {"version":1,"progress":progress.duplicate(true)}

func restore(data: Dictionary) -> bool:
	if data.is_empty():
		progress.clear()
		recent_source=""
		return true
	if int(data.get("version",0))!=1: return false
	var rows: Variant=data.get("progress",{})
	if not (rows is Dictionary) or rows.size()>cards.size(): return false
	var validated: Dictionary={}
	for id in rows:
		if not cards.has(String(id)) or not (rows[id] is Dictionary): return false
		var row: Dictionary=rows[id]
		var due: int=int(row.get("due_day",-1))
		var last: int=int(row.get("last_day",-1))
		var repetitions: int=int(row.get("repetitions",-1))
		var successes: int=int(row.get("successes",-1))
		var lapses: int=int(row.get("lapses",-1))
		if due<last or last<0 or due>50000000 or repetitions<0 or repetitions>1000 or successes<0 or successes>1000000 or lapses<0 or lapses>1000000:
			return false
		validated[id]={"due_day":due,"last_day":last,"repetitions":repetitions,
			"successes":successes,"lapses":lapses}
	progress=validated
	recent_source=""
	return true
