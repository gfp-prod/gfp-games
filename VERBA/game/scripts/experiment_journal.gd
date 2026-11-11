extends RefCounted
## An empirical wizard's field notes: the world, not a dice roll, decides
## whether an invocation works. Observations never award scholarship XP,
## unlock words, or count as a correctly recalled Latin form.
const LATIN = preload("res://scripts/latin_practice.gd")
const MAX_RECORDS := 32
const REASONS := ["grammar", "energy", "world"]

var entries: Array[Dictionary] = []

func observe(utterance: String, outcome: Dictionary, place: String, day: int, cause: String = "world") -> bool:
	var phrase: String = LATIN.normalize(utterance)
	if phrase.is_empty() or phrase.length() > 48 or day < 0 or day > 50000000:
		return false
	if not REASONS.has(cause):
		return false
	var context: String = place.strip_edges().replace("\n", " ").substr(0, 40)
	var note: String = String(outcome.get("message", "")).strip_edges().replace("\n", " ").substr(0, 160)
	if note.is_empty():
		return false
	var worked: bool = bool(outcome.get("ok", false))
	# Repeating the same action in the same circumstances is not another
	# discovery. Changed material behavior or a later dawn may be recorded.
	for previous in entries:
		if int(previous["day"]) == day and String(previous["latin"]) == phrase \
				and bool(previous["worked"]) == worked \
				and String(previous["place"]) == context \
				and String(previous["note"]) == note \
				and String(previous["cause"]) == cause:
			return false
	entries.push_front({"day": day, "latin": phrase, "worked": worked,
		"place": context, "note": note, "cause": cause})
	if entries.size() > MAX_RECORDS:
		entries.resize(MAX_RECORDS)
	return true

func snapshot() -> Dictionary:
	return {"version": 1, "entries": entries.duplicate(true)}

func restore(data: Dictionary) -> bool:
	if data.is_empty():
		entries.clear()
		return true
	if int(data.get("version", -1)) != 1:
		return false
	var raw: Variant = data.get("entries", null)
	if not (raw is Array) or raw.size() > MAX_RECORDS:
		return false
	var verified: Array[Dictionary] = []
	for item in raw:
		if not (item is Dictionary):
			return false
		var phrase: String = String(item.get("latin", ""))
		var place: String = String(item.get("place", ""))
		var note: String = String(item.get("note", ""))
		var cause: String = String(item.get("cause", ""))
		var day: int = int(item.get("day", -1))
		if phrase.is_empty() or phrase.length() > 48 or LATIN.normalize(phrase) != phrase:
			return false
		if day < 0 or day > 50000000 or place.length() > 40 or note.is_empty() or note.length() > 160:
			return false
		if not REASONS.has(cause) or not (item.get("worked", null) is bool):
			return false
		verified.append({"day": day, "latin": phrase,
			"worked": bool(item["worked"]), "place": place,
			"note": note, "cause": cause})
	entries = verified
	return true
