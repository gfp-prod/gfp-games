extends RefCounted
## A small compositional Latin grammar: verb + accusative object + adverb.
## Tables are explicit attested forms. Never infer Latin declensions by suffix.
const VERBS := {
	"crea":"create",
	"move":"move",
	"accende":"ignite",
	"exstingue":"extinguish"
}
const OBJECTS := {
	"lucem":"light",
	"herbam":"plant",
	"ignem":"fire",
	"lignum":"wood",
	"lapidem":"stone"
}
const ADVERBS := {"celeriter":1.5,"leniter":0.6}
# Whitelist represents physical capabilities implemented by the world.
const COMPATIBLE := {
	"crea":["light","plant","fire"],
	"move":["stone","wood","plant"],
	"accende":["wood","plant","stone"],
	"exstingue":["fire","wood","plant"]
}

static func knows_verb(word: String) -> bool:
	return VERBS.has(word)

static func parse(words: PackedStringArray, surface: String) -> Dictionary:
	if words.size()<2 or words.size()>3:
		return {"ok":false,"message":"Use a Latin imperative, an accusative object, and optionally an adverb."}
	var verb: String = words[0]
	var noun: String = words[1]
	if not VERBS.has(verb):
		return {"ok":false,"message":"Unknown compositional imperative."}
	if not OBJECTS.has(noun):
		return {"ok":false,"message":"That is not an attested accusative object. Review your Latin book."}
	var kind: String = OBJECTS[noun]
	if not COMPATIBLE[verb].has(kind):
		return {"ok":false,"message":"Those meanings cannot yet interact under the world's physical laws."}
	var modifier: String = ""
	if words.size()==3:
		modifier = words[2]
		if not ADVERBS.has(modifier):
			return {"ok":false,"message":"The third word must be an attested Latin adverb."}
		if verb=="crea":
			return {"ok":false,"message":"Speed does not modify creation; remove the adverb."}
	return {"ok":true,"surface":surface,"command":verb,"effect":VERBS[verb],
		"kind":kind,"number":"singular","modifier":modifier,
		"strength":float(ADVERBS.get(modifier,1.0)),
		"meaning":"Composed Latin invocation","form":"composed imperative"}
