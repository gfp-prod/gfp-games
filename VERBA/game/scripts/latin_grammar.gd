extends RefCounted
const COMPOSITION = preload("res://scripts/latin_composition.gd")
## A deliberately small, checked Latin grammar, not an AI guessing Latin.
## More forms can be generated offline from audited morphology tables.
## A verb addresses its subject in the vocative, so "venite, lupi" is
## meaningful Latin ("Come, wolves!") rather than an English word-order hack.

const IMPERATIVES := {
	"cresce": {"effect":"grow","number":"singular","meaning":"grow!"},
	"crescite": {"effect":"grow","number":"plural","meaning":"grow! (plural)"},
	"veni": {"effect":"come","number":"singular","meaning":"come!"},
	"venite": {"effect":"come","number":"plural","meaning":"come! (plural)"},
	"dormi": {"effect":"sleep","number":"singular","meaning":"sleep!"},
	"dormite": {"effect":"sleep","number":"plural","meaning":"sleep! (plural)"},
	"fuge": {"effect":"flee","number":"singular","meaning":"flee!"},
	"fugite": {"effect":"flee","number":"plural","meaning":"flee! (plural)"},
	"siste": {"effect":"stop","number":"singular","meaning":"stop!"},
	"sistite": {"effect":"stop","number":"plural","meaning":"stop! (plural)"},
	"muta": {"effect":"transform","number":"singular","meaning":"change!"},
	"mutate": {"effect":"transform","number":"plural","meaning":"change! (plural)"},
	"arde": {"effect":"kindle","number":"singular","meaning":"burn!"},
	"ardete": {"effect":"kindle","number":"plural","meaning":"burn! (plural)"},
	"surge": {"effect":"rise","number":"singular","meaning":"rise!"},
	"surgite": {"effect":"rise","number":"plural","meaning":"rise! (plural)"}
}
const NAMINGS := {
	"ignis":"kindle", "flamma":"kindle", "pluvia":"rain",
	"lux":"light", "ventus":"wind", "aqua":"water", "nox":"night",
	"gelu":"frost"
}
# Written-out Latin vocatives, explicitly reviewed; no blind suffix guessing.
const VOCATIVES := {
	"arbor":{"kind":"tree","number":"singular"},
	"arbores":{"kind":"tree","number":"plural"},
	"lupe":{"kind":"wolf","number":"singular"},
	"lupi":{"kind":"wolf","number":"plural"},
	"cerve":{"kind":"deer","number":"singular"},
	"cervi":{"kind":"deer","number":"plural"},
	"vulpes":{"kind":"fox","number":"either"},
	"lepus":{"kind":"hare","number":"singular"},
	"lepores":{"kind":"hare","number":"plural"},
	"corve":{"kind":"crow","number":"singular"},
	"corvi":{"kind":"crow","number":"plural"},
	"herba":{"kind":"grass","number":"singular"},
	"herbae":{"kind":"grass","number":"plural"},
	"lapis":{"kind":"stone","number":"singular"},
	"lapides":{"kind":"stone","number":"plural"}
}
const PLURAL_FORMS := ["crescite","venite","dormite","fugite","sistite","mutate","ardete","surgite"]

static func parse(input_text: String) -> Dictionary:
	var normalized: String = input_text.strip_edges().to_lower()
	normalized = normalized.replace(",", " ").replace(".", " ").replace("!", " ")
	normalized = normalized.replace("?", " ").replace(";", " ")
	# Punctuation may introduce leading/trailing whitespace after the first
	# strip. The canonical form must never contain a phantom space.
	normalized = normalized.strip_edges()
	while normalized.contains("  "): normalized = normalized.replace("  ", " ")
	var bits: PackedStringArray = normalized.split(" ", false)
	if bits.is_empty() or bits.size() > 3:
		return {"ok":false,"message":"Speak one Latin invocation, optionally addressing a creature or plant."}
	var verb: String = bits[0]
	if COMPOSITION.knows_verb(verb):
		return COMPOSITION.parse(bits,normalized)
	if bits.size() == 1 and NAMINGS.has(verb):
		return {"ok":true,"surface":normalized,"command":verb,"number":"singular",
			"kind":"","effect":String(NAMINGS[verb]),"meaning":"Naming invocation","form":"noun invocation"}
	if not IMPERATIVES.has(verb):
		return {"ok":false,"message":"The grimoire has no attested form for '" + verb + "'."}
	var entry: Dictionary = IMPERATIVES[verb]
	var audience: String = ""
	if bits.size() == 2:
		var vocative: String = bits[1]
		if not VOCATIVES.has(vocative):
			return {"ok":false,"message":"'"+vocative+"' is not a known Latin vocative."}
		var noun: Dictionary = VOCATIVES[vocative]
		if String(noun["number"]) != "either" and String(noun["number"]) != String(entry["number"]):
			return {"ok":false,"message":"The imperative and its addressee disagree in number."}
		audience = String(noun["kind"])
	return {"ok":true,"surface":normalized,"command":verb,"number":String(entry["number"]),
		"kind":audience,"effect":String(entry["effect"]),"meaning":String(entry["meaning"]),
		"form":"present active imperative"}
