extends RefCounted
## Nouns are invocation formulae; verbs are morphologically valid singular imperatives.
const ART = preload("res://scripts/art.gd")
var world
var lexicon: Dictionary = {}
var rng:=RandomNumberGenerator.new()
var cast_count:=0
var wildcard_rate:=.14

func _init(w: Node3D) -> void:
	world=w
	rng.seed=3123127
	var raw=JSON.parse_string(FileAccess.get_file_as_string("res://data/lexicon.json"))
	if raw is Array:
		for e in raw:
			if e is Dictionary and e.has("word"):
				lexicon[String(e["word"])]=e

func cast(word: String, eye: Vector3, target: Dictionary) -> Dictionary:
	word=word.strip_edges().to_lower()
	if not lexicon.has(word):
		return {"ok":false,"message":"Unknown utterance: " + word}
	var e:Dictionary=lexicon[word]
	var effect:String=e.get("effect","")
	var point: Vector3=target.get("position",eye+world.player.camera.global_transform.basis.z * -5.0)
	var entity:Node3D=target.get("entity",null)
	var c=null
	if entity != null and entity.has_method("afflict"):
		c=entity
	if c == null:
		var nearest:float=5.0
		for critter in world.creatures:
			if is_instance_valid(critter):
				var d:float=critter.global_position.distance_to(point)
				if d<nearest: nearest=d; c=critter
	cast_count+=1
	var message:=""
	match effect:
		"kindle":
			if entity != null and entity.has_method("flammable") and not entity.flammable():
				entity.apply_effect("heat",.5)
				message="The stone warms, but will not burn."
			elif entity != null and entity.has_method("apply_effect") and not entity.apply_effect("ignite"):
				message="That is too wet to ignite."
			elif world.raining:
				message="Rain suppresses the flame."
			else:
				world.add_fire(point,entity)
				message="A flame takes hold."
		"rain":
			world.set_rain(18.0 + rng.randf_range(-4.0,13.0))
			message="Rain answers the name."
		"light":
			var n:=Node3D.new()
			n.position=point+Vector3.UP*.75
			world.add_child(n)
			ART.orb(n,Vector3.ZERO,Vector3(.12,.13,.12),ART.mat(Color("e1cb95"),.2,Color("c19e55")),14)
			var light:=OmniLight3D.new()
			light.light_color=Color("f0ce8f")
			light.light_energy=1.0
			light.omni_range=7.0
			n.add_child(light)
			world.get_tree().create_timer(30.0).timeout.connect(func(): if is_instance_valid(n): n.queue_free())
			message="A pale light remains."
		"wind":
			world.wind=rng.randf_range(-3.0,3.0)
			for critter in world.creatures:
				if is_instance_valid(critter) and critter.global_position.distance_to(point)<15.0:
					critter.panic=maxf(critter.panic,3.0)
					critter.intent=Vector3(world.wind,0,-1).normalized()
			message="The valley takes a breath."
		"water":
			for obj in world.sim_objects:
				if is_instance_valid(obj) and obj.global_position.distance_to(point)<6.5:
					obj.apply_effect("water",1.0)
			for critter in world.creatures:
				if is_instance_valid(critter) and critter.global_position.distance_to(point)<5.0: critter.afflict("water")
			message="The nearby world takes on water."
		"night":
			world.night_remaining=30.0
			message="The light of day withdraws."
		"grow":
			if entity != null and entity.has_method("apply_effect") and entity.apply_effect("grow",1.0):
				message="The living thing grows."
			elif c != null:
				c.afflict("grow")
				message="The creature grows."
			else:
				var patch=world.spawn_growth_patch(point)
				message="A new living patch takes root." if patch != null else "Nothing takes root."
		"sleep","flee","stop","come","transform","rise":
			if c != null:
				c.afflict(effect)
				message="The creature obeys."
			elif effect=="rise" and entity!=null and entity.has_method("apply_effect"):
				entity.apply_effect("rise",1.0)
				message="The object rises."
			else: message="No creature heard the command."
		"frost":
			world.extinguish()
			for obj in world.sim_objects:
				if is_instance_valid(obj) and obj.global_position.distance_to(point)<12.0:obj.apply_effect("frost",1.0)
			for critter in world.creatures:
				if is_instance_valid(critter) and critter.global_position.distance_to(point)<10.0: critter.stop_time=2.0
			message="Frost stifles warmth and movement."
		_: message="The utterance resonates."
	var surprise:=""
	if rng.randf()<wildcard_rate:
		surprise=wild_result(point)
	return {"ok":true,"message":message,"wild":surprise,"point":point,"word":word}

func wild_result(point: Vector3) -> String:
	match rng.randi_range(0,4):
		0:
			world.wind=rng.randf_range(-5,5)
			return "A second, contrary wind answers."
		1:
			var critter=world.nearest_creature(point,"hare",35.0)
			if critter!=null:
				critter.afflict("transform")
				return "Elsewhere, a life is altered."
		2:
			world.set_rain(7.0)
			return "An unexpected shower follows."
		3:
			var n=world.creatures[rng.randi_range(0,world.creatures.size()-1)]
			if is_instance_valid(n): n.afflict("flee")
			return "Something in the wood bolts."
		4:
			world.night_remaining=8.0
			return "A shadow passes across the sun."
	return ""
