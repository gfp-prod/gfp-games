extends SceneTree
## Real world integration: physical dismemberment, observed social consequences,
## voluntary aid, finite stocks and schema-1 save/load identities.
const ANATOMY=preload("res://scripts/npc_anatomy.gd")
const PERSIST=preload("res://scripts/world_persistence.gd")

func _initialize() -> void:
	call_deferred("_run")

func _fail(why: String) -> void:
	push_error("VERBA modular anatomy QA: "+why)
	quit(1)

func _npc(world: Node3D, wanted: String) -> Node3D:
	for actor in world.npcs:
		if String(actor.npc_id)==wanted: return actor
	return null

func _run() -> void:
	var world: Node3D=load("res://main.tscn").instantiate()
	root.add_child(world)
	await process_frame
	var sim=world.village_sim
	var ida: Node3D=_npc(world,"ida")
	var daro: Node3D=_npc(world,"daro")
	var sela: Node3D=_npc(world,"sela")
	if ida==null or daro==null or sela==null:
		_fail("Physical identities unavailable")
		return
	var arm: Node3D=ida.modular_limbs.get("left_arm") as Node3D
	var leg: Node3D=daro.modular_limbs.get("right_leg") as Node3D
	if arm==null or leg==null or ida.limb_hitboxes.size()!=4:
		_fail("The existing villagers are not built from four hit-testable limb modules")
		return
	# Small impacts damage only the addressed limb, not its counterpart.
	var nick: Dictionary=ida.strike_limb("left_arm",10.0,"wizard")
	if not nick.get("ok",false) or nick.get("severed",true):
		_fail("Minor injury should not instantly amputate")
		return
	if float(sim.people["ida"]["anatomy"]["integrity"]["right_arm"])!=50.0:
		_fail("Damage leaked from the struck left arm to the right")
		return
	var torn: Dictionary=ida.strike_limb("left_arm",95.0,"wizard")
	if not torn.get("ok",false) or not torn.get("severed",false):
		_fail("Sufficient physical damage did not detach an arm")
		return
	if arm.visible or not ida.limb_missing("left_arm"):
		_fail("The physical arm remained attached after severance")
		return
	if ida.limb_hitboxes["left_arm"].collision_layer!=0:
		_fail("Invisible amputated limb can still receive strikes")
		return
	var detached:=world.get_node_or_null("Detached_ida_left_arm") as RigidBody3D
	if detached==null or detached.get_node_or_null("SeparatedPhysicalAnatomy")==null:
		_fail("Severed body part did not enter the physics world")
		return
	var ida_body: Dictionary=sim.people["ida"]["anatomy"]
	if float(ida_body["bleeding"])<=0.0 or ida.blood_emitter==null:
		_fail("Amputation has no blood loss or visible particles")
		return
	if float(sim.people["ida"]["trust"].get("wizard",0.0))>=0.0:
		_fail("Being attacked does not change their relationship with the wizard")
		return
	var one_time: Dictionary=ida.strike_limb("left_arm",80.0,"wizard")
	if bool(one_time.get("ok",false)):
		_fail("Already separated anatomy can be amputated twice")
		return
	# Aid requires finite carried goods. Conversations include the option,
	# and social trust changes when a person chooses to accept help.
	var no_supply: Dictionary=sim.player_help("ida",[])
	if no_supply.get("ok",false):
		_fail("Player fabricated dressing supplies from nothing")
		return
	var trust_before_aid: float=float(sim.people["ida"]["trust"].get("wizard",0.0))
	world.player.inventory.clear()
	world.player.inventory.append("herb")
	world.player.refresh_held_model()
	var conversation: Dictionary=world.social.view("ida",world.scholar,world.player.inventory)
	var has_care: bool=false
	for option in conversation.get("options",[]):
		if int(option.get("index",-1))==6: has_care=true
	if not has_care:
		_fail("Wound care is missing from actual conversation choices")
		return
	var helped: Dictionary=world.social.choose("ida",6,world.scholar,world.player)
	if not helped.get("ok",false) or world.player.inventory.has("herb"):
		_fail("The player did not spend real herb supplies to bandage Ida")
		return
	if not bool(ida_body["bandaged"]) or float(ida_body["bleeding"])>.7:
		_fail("The blood loss was not controlled by real treatment")
		return
	if float(sim.people["ida"]["trust"].get("wizard",0.0))<=trust_before_aid:
		_fail("Accepted aid did not improve the damaged relationship")
		return
	if float(sim.people["ida"]["trust"].get("wizard",0.0))>=0.0:
		_fail("One herb dressing should not erase two acts of violence")
		return
	# Daro's missing leg affects his gait. Sela may help her spouse only
	# if she knows, they can meet, and the resource ledger can afford it.
	var leg_injury: Dictionary=daro.strike_limb("right_leg",85.0,"orin")
	if not leg_injury.get("severed",false) or leg.visible:
		_fail("The farmer retained his destroyed leg")
		return
	var daro_body: Dictionary=sim.people["daro"]["anatomy"]
	if ANATOMY.locomotion(daro_body)>.25:
		_fail("Untreated amputee can walk at ordinary speed")
		return
	sim.observe_wound("daro",["sela"])
	sim.nearby_care["sela"]=["daro"]
	# Different levels of supplies lead to different forms of aid. Remove
	# herb in this particular scenario to test a wooden prosthetic;
	# emergency bandaging was independently verified above.
	sim.economy.stocks["herb"]=0
	var wood_before: int=int(sim.economy.stocks["wood"])
	var tools_before: int=int(sim.economy.stocks["tools"])
	if sim._score(sim.people["sela"],"aid")<=0.0:
		_fail("A concerned spouse has no motivation to consider helping")
		return
	if not sim._perform_neighbor_aid("sela","daro"):
		_fail("A nearby willing spouse cannot construct a real mobility aid")
		return
	if String(daro_body["support"])!="peg" or ANATOMY.locomotion(daro_body)<.65:
		_fail("The prosthetic did not affect persistent locomotion")
		return
	if sim.economy.stocks["wood"]!=wood_before-1 or sim.economy.stocks["tools"]!=tools_before-1:
		_fail("Prosthetic materials were invented instead of consumed")
		return
	if float(sim.people["daro"]["trust"].get("sela",0.0))<=0.0:
		_fail("Care did not improve the real patient-helper relationship")
		return
	# The same system permits refusal and resentment, not scripted rescue.
	sim.people["sela"]["trust"]["daro"]=-100.0
	sim.people["sela"]["grievance"]["daro"]=100.0
	ANATOMY.strike(daro_body,"left_leg",8.0,sim.tick_count)
	sim.economy.stocks["herb"]=2
	if sim._score(sim.people["sela"],"aid")>=0.0:
		_fail("Even extreme hostility has no effect on willingness to help")
		return
	# Save a real world and replace the original state, rather than only
	# serializing a detached node that would disappear on reload.
	var saved: Dictionary=PERSIST.snapshot(world)
	if not saved["village"]["people"]["ida"]["anatomy"]["missing"].has("left_arm"):
		_fail("Authoritative save omitted the permanent amputation")
		return
	sim.people["ida"]["anatomy"]=ANATOMY.new_state()
	sim.people["daro"]["anatomy"]=ANATOMY.new_state()
	if not PERSIST.apply_snapshot(world,saved):
		_fail("Real world could not restore saved limb and relationship state")
		return
	if not ida.limb_missing("left_arm") or ida.modular_limbs["left_arm"].visible:
		_fail("Saved arm loss did not reconstruct on the original NPC")
		return
	var restored: Dictionary=sim.people["daro"]["anatomy"]
	if not daro.limb_missing("right_leg") or restored["support"]!="peg":
		_fail("Saved peg leg did not survive reload")
		return
	# Pre-injury schema-1 characters also need to load without resets.
	var legacy: Dictionary=sim.snapshot()
	for id in legacy["people"]:
		legacy["people"][id].erase("anatomy")
		legacy["people"][id].erase("known_wounded")
	if not sim.restore(legacy):
		_fail("Older pre-injury citizen save became incompatible")
		return
	if not ANATOMY.validate(sim.people["ida"]["anatomy"]):
		_fail("Older saves do not receive safe intact anatomy")
		return
	print("PASS: four physical limb modules, observed injury, blood loss, player trust, voluntary neighbor aid, finite timber/tools, peg gait, persistent amputations and legacy saves")
	quit(0)
