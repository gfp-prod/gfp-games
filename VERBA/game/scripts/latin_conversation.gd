extends RefCounted
## Deterministic interpretation of a few attested Latin requests.
## This handles complete, authored utterances, not unrestricted Latin prose.
## Word order can vary, but inflection, person, and argument cases must match.
const LATIN = preload("res://scripts/latin_practice.gd")

static func understand(utterance: String, patterns: Array, tier: int) -> Dictionary:
	var normalized: String = LATIN.normalize(utterance)
	if normalized.is_empty():
		return {"ok": false, "message": "The listener waits for your words."}
	if normalized.length() > 72:
		return {"ok": false, "message": "Say one short request at a time."}
	var spoken: PackedStringArray = normalized.split(" ", false)
	if spoken.size() > 7:
		return {"ok": false, "message": "Try a shorter Latin request."}
	var best_hint: String = ""
	var best_overlap: int = 0
	for pattern in patterns:
		if not (pattern is Dictionary):
			continue
		var model: String = LATIN.normalize(String(pattern.get("form", "")))
		var expected: PackedStringArray = model.split(" ", false)
		if model.is_empty() or expected.size() != spoken.size():
			continue
		var remaining: Array[String] = []
		for word in spoken:
			remaining.append(String(word))
		var matched: bool = true
		for word in expected:
			if not remaining.has(String(word)):
				matched = false
				continue
			remaining.erase(String(word))
		if not matched:
			# Specific grammatical feedback belongs to the character, not to
			# a floating school lesson. A partial match never earns rewards.
			if tier >= int(pattern.get("min_stage", 0)):
				var overlap: int = expected.size()-remaining.size()
				if overlap >= 2 and overlap > best_overlap:
					best_overlap = overlap
					best_hint = String(pattern.get("hint", ""))
			continue
		if tier < int(pattern.get("min_stage", 0)):
			return {"ok": false, "message": String(pattern.get("early", "Study the words before making this request."))}
		return {"ok": true, "topic": String(pattern.get("topic", "")),
			"form": model}
	# Do not guess at unattested Latin, and do not reward a malformed case.
	return {"ok": false, "message": best_hint if not best_hint.is_empty() else "The listener hesitates. Try the case and verb forms in the manuscript."}
