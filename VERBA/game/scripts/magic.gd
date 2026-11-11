extends RefCounted
## Nouns are invocation formulae; verbs are morphologically valid singular imperatives.
const ART = preload("res://scripts/art.gd")
const GRAMMAR = preload("res://scripts/latin_grammar.gd")
const WORLD_LAWS = preload("res://scripts/world_laws.gd")
const COMMISSIONS = preload("res://scripts/wizard_commissions.gd")
var world
var lexicon: Dictionary = {}
var rng:=RandomNumberGenerator.new()
var cast_count:=0
var wildcard_rate:=0.0 # Surprises come from interacting world states, not arbitrary 14% dice rolls.

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
	var parsed: Dictionary = GRAMMAR.parse(word)
	if not bool(parsed.get("ok",false)):
		return {"ok":false,"message":String(parsed.get("message","Unknown Latin."))}
	# Use the parser's attested normalized Latin, not the user's punctuation,
	# when finding lexical magic. "pluvia!" must behave exactly as "pluvia".
	word = String(parsed.get("surface",word))
	# The same Latin fire used in the wilderness can kindle a real trade
	# station. Charged worksite heat replaces one physical log, rather than
	# spawning a hazardous loose fire on top of the public stone oven.
	var work_target=target.get("entity",null)
	if String(parsed.get("effect",""))=="kindle" and work_target!=null and work_target.has_meta("workplace_kind"):
		var kind: String=String(work_target.get_meta("workplace_kind"))
		if kind in ["bakery","forge"]:
			var lit: Dictionary=world.player.professions.ignite(kind,world.player)
			return {"ok":bool(lit.get("ok",false)),
				"message":String(lit.get("message","")),"point":target.get("position",eye),
				"word":word,"remember_word":String(parsed["command"]),"wild":""}
	if String(parsed.get("form",""))=="composed imperative":
		return cast_composed(parsed,eye,target)
	# Crops are planted terrain meshes, not unrelated magical foliage. A
	# targeted Latin growth command now nurtures Daro\u0027s *actual* field,
	# and its potential is paid out only after a farmer delivers the crop.
	var farm_point: Vector3=target.get("position",eye+Vector3.FORWARD*5.0)
	if String(parsed.get("effect",""))=="grow" and target.get("entity",null)==null and world.workplaces!=null and world.workplaces.is_field_target(farm_point):
		if eye.distance_to(farm_point)>16.0:
			return {"ok":false,"message":"The field is beyond your voice."}
		var field_command: String=String(parsed["command"])
		var field_growth: int=1
		if field_command=="crescite":
			# The plural harvest command has to be learned from the physical
			# botany book; repeating an unknown verb should not skip study.
			if not world.scholar.completed.has("de_herbis"):
				return {"ok":false,"message":"Study De Herbis before addressing the whole field."}
			field_growth=2
		var applied: int=world.village_sim.bless_field(field_growth)
		if applied<=0:
			return {"ok":false,"message":"The furrows cannot hold more growth. Let Daro bring in the harvest."}
		world.workplaces.refresh_from_economy(true)
		COMMISSIONS.spell_applied(world.village_sim,field_command)
		cast_count+=1
		return {"ok":true,"message":"The stalks grow taller. %d extra grain awaits Daro\u0027s next delivery." % applied,
			"point":farm_point,"word":word,"remember_word":field_command,"wild":""}
	if word.contains(" ") or String(parsed.get("number","singular")) == "plural":
		var place: Vector3 = target.get("position",eye + Vector3.FORWARD * 5.0)
		var actor: Node3D = target.get("entity",null)
		var resolution: Dictionary = WORLD_LAWS.new(world).invoke(parsed,place,actor)
		return {"ok":bool(resolution["ok"]), "message":String(resolution["message"]),
			"point":place,"word":word,"wild":"","remember_word":String(parsed["command"]),
			"count":int(resolution["count"])}
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
	var effective: bool = true
	match effect:
		"kindle":
			# Weather must be checked BEFORE applying heat/ignite to the target.
			# Previously rain could return "suppressed" after setting it ablaze.
			if world.raining:
				effective = false
				message="Rain suppresses the flame."
			elif entity != null and entity.has_method("flammable") and not entity.flammable():
				effective = bool(entity.apply_effect("heat",.5))
				message="The stone warms, but will not burn."
			elif entity != null and entity.has_method("apply_effect") and not entity.apply_effect("ignite"):
				effective = false
				message="That is too wet to ignite."
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
				effective = patch != null
				message="A new living patch takes root." if effective else "Nothing takes root."
		"sleep","flee","stop","come","transform","rise":
			if c != null:
				c.afflict(effect)
				message="The creature obeys."
			elif effect=="rise" and entity!=null and entity.has_method("apply_effect"):
				effective = bool(entity.apply_effect("rise",1.0))
				message="The object rises." if effective else "The object cannot rise."
			else:
				effective = false
				message="No creature heard the command."
		"frost":
			world.extinguish()
			for obj in world.sim_objects:
				if is_instance_valid(obj) and obj.global_position.distance_to(point)<12.0:obj.apply_effect("frost",1.0)
			for critter in world.creatures:
				if is_instance_valid(critter) and critter.global_position.distance_to(point)<10.0: critter.stop_time=2.0
			message="Frost stifles warmth and movement."
		_: message="The utterance resonates."
	# A fulfilled promise and a burned field have socially different outcomes.
	# Only a spell that actually took effect can count as sabotage.
	if effective and effect=="kindle" and world.workplaces!=null and world.workplaces.is_field_target(point):
		COMMISSIONS.spell_applied(world.village_sim,"kindle")
	var surprise:=""
	if rng.randf()<wildcard_rate:
		surprise=wild_result(point)
	return {"ok":effective,"message":message,"wild":surprise,"point":point,"word":word,"remember_word":word}

func cast_composed(parsed: Dictionary, eye: Vector3, target: Dictionary) -> Dictionary:
	var point: Vector3 = target.get("position",eye+Vector3.FORWARD*5.0)
	var entity: Node3D = target.get("entity",null)
	var word: String = String(parsed["surface"])
	var command: String = String(parsed["command"])
	var kind: String = String(parsed["kind"])
	var strength: float = float(parsed.get("strength",1.0))
	var effected: bool = false
	var message: String = "Nothing here answers that combination."
	if command=="crea":
		match kind:
			"light":
				var result: Dictionary = cast("lux",eye,target)
				result["word"]=word
				result["remember_word"]=command
				return result
			"plant":
				effected = world.spawn_growth_patch(point)!=null
				message = "A new herb takes root." if effected else "The soil is too crowded."
			"fire":
				world.add_fire(point,null)
				effected=true
				message="A fire begins here."
	elif command=="exstingue" and kind=="fire":
		for flame in world.fires.duplicate():
			if is_instance_valid(flame) and flame.global_position.distance_to(point)<4.0*strength:
				world.fires.erase(flame)
				flame.queue_free()
				effected=true
		for obj in world.sim_objects:
			if is_instance_valid(obj) and obj.global_position.distance_to(point)<4.0*strength and obj.burning:
				obj.apply_effect("cold",strength)
				effected=true
		message="Nearby flames go out." if effected else "There is no fire in reach."
	elif entity!=null and is_instance_valid(entity) and entity.has_method("apply_effect"):
		var real_kind: String = String(entity.kind)
		var matches: bool = (kind=="stone" and real_kind=="stone") or (kind=="wood" and real_kind in ["wood","tree","dead_tree"]) or (kind=="plant" and real_kind in ["grass","fern"])
		if matches:
			match command:
				"move":
					effected=bool(entity.apply_effect("rise",strength))
					message="The object rises." if effected else message
				"accende":
					if kind=="stone":
						effected=bool(entity.apply_effect("heat",strength))
						message="The stone warms, but does not burn."
					elif not world.raining:
						effected=bool(entity.apply_effect("ignite",strength))
						if effected: world.add_fire(point,entity)
						message="The material catches fire." if effected else "Wet fuel refuses the flame."
					else:
						message="Rain suppresses ignition."
				"exstingue":
					effected=bool(entity.apply_effect("water",strength))
					message="The material is drenched." if effected else message
	return {"ok":effected,"message":message,"point":point,"word":word,
		"remember_word":command,"wild":""}

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
