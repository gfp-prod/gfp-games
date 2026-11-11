extends SceneTree
## A learned, spoken Latin direction changes a real physical object in the
## valley; its state is derived from existing social memory, not duplicated.
const PERSIST=preload("res://scripts/world_persistence.gd")

func _initialize() -> void:
	call_deferred("_run")

func _fail(reason: String) -> void:
	push_error("Latin waystone: "+reason)
	quit(1)

func _run() -> void:
	var world=load("res://main.tscn").instantiate()
	root.add_child(world)
	await process_frame
	var stone=world.forest_waystone
	if stone==null or stone.inscription==null or stone.ember==null:
		_fail("Mara's world stone does not exist")
		return
	# Physical inscription is a three-line inlaid carving, not a billboard
	# that can clip through its own narrow stone in first-person.
	var carved_lines: PackedStringArray=stone.inscription.text.split("\n")
	if carved_lines.size()!=3 or carved_lines[0]!="SILVA" or carved_lines[1]!="TRANS" or carved_lines[2]!="RIVUM":
		_fail("Forest inscription no longer fits as three individually carved lines")
		return
	if stone.inscription.billboard!=BaseMaterial3D.BILLBOARD_DISABLED:
		_fail("Forest inscription has become a clipping camera-facing billboard")
		return
	if not is_equal_approx(stone.inscription.rotation.y,PI):
		_fail("The inlaid inscription no longer faces the approach path")
		return
	var collider=stone.find_child("CollidableWaystone",true,false) as StaticBody3D
	if collider==null or collider.get_child_count()==0 or collider.collision_layer!=16:
		_fail("The stone is not collidable physical scenery")
		return
	if stone.revealed or stone.ember.visible:
		_fail("The forest inscription was revealed before language understanding")
		return
	var prior: Dictionary=world.social.speak("mara","Ubi est silva?",world.scholar,world.player)
	stone.update_from_knowledge()
	if bool(prior.get("ok",false)) or stone.revealed or stone.ember.visible:
		_fail("Guessing an unstudied phrase revealed the ancient route")
		return
	# English assistance must remain useful to a beginner but cannot
	# counterfeit actually producing Latin in the physical world.
	var assisted: Dictionary=world.social.choose("mara",1,world.scholar,world.player)
	stone.update_from_knowledge()
	if not bool(assisted.get("ok",false)) or stone.revealed or world.social.memory("mara")["topics"].has("forest"):
		_fail("English scaffold either stopped working or faked Latin knowledge")
		return
	# Legacy pre-production dialogue saved an English-obtained 'forest'
	# topic. It must not be silently upgraded into spoken Latin mastery.
	world.social.restore({"mara":{"topics":["forest"],"rapport":1,"traded":false}})
	stone.update_from_knowledge()
	if stone.revealed or world.social.memory("mara").get("spoken_topics",[]).has("forest"):
		_fail("Legacy English directions were mistaken for produced Latin")
		return
	world.social.memories.clear()
	if not world.scholar.collect_book("de_herbis") or not bool(world.scholar.answer("de_herbis",0).get("first_time",false)):
		_fail("The real beginner manuscript cannot be understood")
		return
	var aided: Dictionary=world.social.choose("mara",1,world.scholar,world.player)
	stone.update_from_knowledge()
	if not bool(aided.get("ok",false)) or stone.revealed:
		_fail("Menu directions after reading still bypassed Latin production")
		return
	var answer: Dictionary=world.social.speak("mara","Ubi silva est?",world.scholar,world.player)
	if not bool(answer.get("ok",false)):
		_fail("The world did not recognize the same valid Latin question in free order")
		return
	stone.update_from_knowledge()
	if not stone.revealed or not stone.ember.visible:
		_fail("Mara's Latin directions did not illuminate the physical waystone")
		return
	var past: Dictionary=world.social.memory("mara")
	if not past.get("topics",[]).has("forest") or not past.get("spoken_topics",[]).has("forest") or int(past.get("rapport",0))!=1:
		_fail("The revealed waystone is not grounded in a one-time social fact")
		return
	world.social.speak("mara","Ubi est silva?",world.scholar,world.player)
	stone.update_from_knowledge()
	if int(world.social.memory("mara").get("rapport",0))!=1:
		_fail("Repeated speech exploits the social relationship")
		return
	var saved: Dictionary=PERSIST.snapshot(world)
	world.social.memories.clear()
	stone.update_from_knowledge()
	if stone.revealed or stone.ember.visible:
		_fail("The waystone retained an out-of-sync local state")
		return
	if not PERSIST.apply_snapshot(world,JSON.parse_string(JSON.stringify(saved))):
		_fail("The real valley cannot reload its learned language encounter")
		return
	stone.update_from_knowledge()
	if not stone.revealed or not stone.ember.visible or not world.social.memory("mara").get("spoken_topics",[]).has("forest"):
		_fail("The visible world forgot proven Latin across save/load")
		return
	# Fresh launch, not just reusing the same live world instance.
	var new_world=load("res://main.tscn").instantiate()
	root.add_child(new_world)
	await process_frame
	if not PERSIST.apply_snapshot(new_world,JSON.parse_string(JSON.stringify(saved))):
		_fail("A fresh world cannot load the Latin forest wayfinding record")
		return
	new_world.forest_waystone.update_from_knowledge()
	if not new_world.forest_waystone.revealed or not new_world.forest_waystone.ember.visible:
		_fail("The forest inscription does not illuminate after restarting")
		return
	print("PASS: understood Latin reveals collidable forest waystone, resists guessing and repetition, persists through unified social save")
	quit(0)
