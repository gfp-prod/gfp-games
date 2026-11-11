extends RefCounted
## Data-only wizard work orders. Commission state lives exclusively in village_sim
## and so saves through the existing authoritative village snapshot.
## Every answer has a social consequence; payment debits finite stock.
const FARM := "farm_fertility"
const STATES := ["offered","accepted","ready","rewarded","declined","abandoned"]

static func _order(sim) -> Dictionary:
	if not sim.commissions.has(FARM):
		sim.commissions[FARM]={"status":"offered","cycle":1,"since_day":sim.current_day,
			"resolved_day":-1}
	return sim.commissions[FARM]

static func state(sim) -> String:
	return String(_order(sim)["status"])

static func _affinity(sim,amount: float) -> void:
	if not sim.people.has("daro"): return
	var farmer: Dictionary=sim.people["daro"]
	var trust: Dictionary=farmer["trust"]
	trust["wizard"]=clampf(float(trust.get("wizard",0.0))+amount,-100.0,100.0)
	if amount<0.0:
		var grudge: Dictionary=farmer["grievance"]
		grudge["wizard"]=clampf(float(grudge.get("wizard",0.0))-amount,0.0,100.0)

static func accept(sim) -> Dictionary:
	if state(sim)!="offered": return {"ok":false,"message":"That request has already been answered."}
	var order: Dictionary=_order(sim)
	order["status"]="accepted"
	order["since_day"]=sim.current_day
	sim.witness_event("wizard_commission_accepted","daro")
	return {"ok":true,"changed":true,
		"message":"Daro: The field is failing. Find De Herbis and learn 'crescite, herbae'. Speak it over my furrows. I'll repay you after I see the growth."}

static func refuse(sim) -> Dictionary:
	if state(sim)!="offered": return {"ok":false,"message":"There is no unanswered request."}
	var order: Dictionary=_order(sim)
	order["status"]="declined"
	order["resolved_day"]=sim.current_day
	_affinity(sim,-9.0)
	sim.witness_event("wizard_commission_refused","daro")
	return {"ok":true,"changed":true,
		"message":"Daro looks away. 'Then I'll have to manage alone.' Your refusal will be remembered."}

static func spell_applied(sim,spell: String) -> void:
	if state(sim)!="accepted": return
	if spell=="crescite":
		var order: Dictionary=_order(sim)
		order["status"]="ready"
		order["resolved_day"]=sim.current_day
		_affinity(sim,12.0)
		sim.witness_event("wizard_field_help","daro")
	elif spell=="kindle":
		var order: Dictionary=_order(sim)
		order["status"]="abandoned"
		order["resolved_day"]=sim.current_day
		_affinity(sim,-27.0)
		sim.witness_event("wizard_field_damage","daro")

static func receive_payment(sim,player) -> Dictionary:
	if state(sim)!="ready": return {"ok":false,"message":"There is no finished job to settle."}
	if player.inventory.size()>=6:
		return {"ok":false,"message":"Your hands are full. Make room for the grain."}
	if int(sim.economy.stocks.get("grain",0))<1:
		return {"ok":false,"message":"Daro promises payment once the village has grain to spare."}
	sim.economy.stocks["grain"]=int(sim.economy.stocks["grain"])-1
	sim.economy._record("wizard_service_payment","daro","grain",1)
	player.inventory.append("grain")
	player.selected_slot=player.inventory.size()-1
	player.refresh_held_model()
	var order: Dictionary=_order(sim)
	order["status"]="rewarded"
	order["resolved_day"]=sim.current_day
	_affinity(sim,8.0)
	sim.witness_event("wizard_commission_paid","daro")
	return {"ok":true,"changed":true,
		"message":"Daro presses a real sack of grain into your hands. 'You came back. I'll remember that.' +1 grain; his trust grows."}

static func day_passed(sim) -> void:
	var order: Dictionary=_order(sim)
	var status: String=String(order["status"])
	if status=="accepted" and sim.current_day-int(order["since_day"])>=5:
		order["status"]="abandoned"
		order["resolved_day"]=sim.current_day
		_affinity(sim,-6.0)
		sim.witness_event("wizard_commission_abandoned","daro")
	elif status in ["rewarded","declined","abandoned"] and sim.current_day-int(order["resolved_day"])>=3:
		order["cycle"]=int(order["cycle"])+1
		order["status"]="offered"
		order["since_day"]=sim.current_day

static func describe(sim) -> String:
	match state(sim):
		"offered": return "Daro's field needs assistance. Ask him about the work."
		"accepted": return "Your promise stands. Study De Herbis and speak 'crescite, herbae' over the field."
		"ready": return "The grain answers your Latin. Return to Daro for your reward."
		"rewarded": return "Daro remembers that you helped the harvest."
		"declined": return "Daro remembers your refusal."
		"abandoned": return "Daro remembers what went wrong."
	return ""
