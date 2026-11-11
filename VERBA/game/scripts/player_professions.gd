extends RefCounted
## Shared player artisan careers. Real ingredients, worksite proximity,
## finite village demand, physical vigor or magical heat: one authority.
## First two playable trades reuse the village's actual kiln and anvil.
const RECIPES := {
	"baker":{
		"grain":{"id":"rustic_bread","product":"bread","ingredients":{"grain":1},"rank":0,"vigor":18.0,"description":"Rustic loaf"},
		"bread":{"id":"herbal_loaf","product":"herb_bread","ingredients":{"bread":1,"herb":1},"rank":2,"vigor":25.0,"description":"Restorative herb loaf"}
	},
	"blacksmith":{
		"ore":{"id":"hammer_tool","product":"tools","ingredients":{"ore":1},"rank":0,"vigor":22.0,"description":"Iron tool"},
		"tools":{"id":"forge_lantern","product":"lantern","ingredients":{"tools":1,"ore":1},"rank":2,"vigor":30.0,"description":"Forged lantern"}
	}
}
const WORKSITE := {"baker":Vector2(8.9,16.25),"blacksmith":Vector2(21.8,19.1)}
const SALES := {"ida":{"item":"bread","stock":"bread","price":2},
	"orin":{"item":"tools","stock":"tools","price":4}}
var experience: Dictionary={"baker":0,"blacksmith":0}
var charged_hearths: Dictionary={"baker":0,"blacksmith":0}

func _career_for(workplace: String) -> String:
	return "baker" if workplace=="bakery" else "blacksmith" if workplace=="forge" else ""

func near(workplace: String,player) -> bool:
	var career: String=_career_for(workplace)
	if career.is_empty() or player==null: return false
	var xy: Vector2=WORKSITE[career]
	return Vector2(player.global_position.x-xy.x,player.global_position.z-xy.y).length()<=4.3

func ignite(workplace: String,player) -> Dictionary:
	var career: String=_career_for(workplace)
	if career.is_empty() or not near(workplace,player):
		return {"ok":false,"message":"The kiln is beyond your reach."}
	if int(charged_hearths[career])>=1:
		return {"ok":false,"message":"The hearth already holds a prepared magical flame."}
	charged_hearths[career]=1
	return {"ok":true,"message":"Ignis kindles the %s. The next craft needs no timber." % ("kiln" if career=="baker" else "forge")}

func recipe(workplace: String,held: String) -> Dictionary:
	var career: String=_career_for(workplace)
	if career.is_empty(): return {}
	return RECIPES[career].get(held,{})

func describe(workplace: String,player) -> String:
	var career: String=_career_for(workplace)
	if career.is_empty(): return ""
	var progress: int=int(experience[career])
	var flame: String=" · magical embers prepared" if int(charged_hearths[career])>0 else ""
	var want: String="grain → bread, bread + herb → herbal loaf" if career=="baker" else "ore → tool, tool + ore → lantern"
	return "%s apprenticeship (%d works)%s. Hold an ingredient, F to craft. Recipes: %s. Timber fuels the fire, or cast IGNIS at the furnace. Advanced work opens after two pieces." % [career.capitalize(),progress,flame,want]

func craft(workplace: String,player) -> Dictionary:
	var career: String=_career_for(workplace)
	if career.is_empty() or not near(workplace,player):
		return {"ok":false,"message":"Approach the actual oven or forge to work."}
	if player.inventory.is_empty():
		return {"ok":false,"message":"Hold grain, bread, ore, or a forged tool to select a recipe."}
	var held: String=String(player.inventory[player.selected_slot])
	var work: Dictionary=recipe(workplace,held)
	if work.is_empty():
		return {"ok":false,"message":"That material does not belong to this trade."}
	if int(experience[career])<int(work["rank"]):
		return {"ok":false,"message":"Practice the basic craft twice before attempting %s." % String(work["description"])}
	var needs: Dictionary=work["ingredients"]
	for ingredient in needs:
		if player.inventory.count(ingredient)<int(needs[ingredient]):
			return {"ok":false,"message":"Missing %s for %s." % [ingredient,work["description"]]}
	var magic_fire: bool=int(charged_hearths[career])>0
	if not magic_fire and player.inventory.count("wood")<int(needs.get("wood",0))+1:
		return {"ok":false,"message":"The hearth needs a log, or the Latin IGNIS to kindle it."}
	var vigor: float=maxf(5.0,float(work["vigor"])-float(mini(5,int(experience[career])))) * (.40 if magic_fire else 1.0)
	if player.stamina<vigor:
		return {"ok":false,"message":"Your arms are exhausted. Rest before working."}
	var total_inputs: int=0
	for ingredient in needs: total_inputs+=int(needs[ingredient])
	var fuel_count: int=0 if magic_fire else 1
	if player.inventory.size()-total_inputs-fuel_count+1>6:
		return {"ok":false,"message":"Your hands cannot hold the finished craft."}
	# Passed all preconditions. Commit exactly once; fire never burns without
	# consuming a finite charge and no materials vanish on a failed attempt.
	for ingredient in needs:
		for i in range(int(needs[ingredient])):
			player.inventory.erase(ingredient)
	if magic_fire: charged_hearths[career]=0
	else: player.inventory.erase("wood")
	player.stamina-=vigor
	player.inventory.append(String(work["product"]))
	player.selected_slot=player.inventory.size()-1
	player.refresh_held_model()
	experience[career]=mini(100000,int(experience[career])+1)
	var new_rank: String=" You can now make advanced work." if int(experience[career])==2 else ""
	return {"ok":true,"message":"Crafted %s: −%d vigor%s. %s%s" % [
		String(work["description"]),ceili(vigor),
		" · magical flame spent" if magic_fire else " · timber burned",
		"Your hands grow surer.",new_rank],
		"product":work["product"],"magic_fire":magic_fire,"career":career}

func sale_available(npc_id: String,player) -> bool:
	if not SALES.has(npc_id) or player==null: return false
	var offer: Dictionary=SALES[npc_id]
	return player.inventory.has(String(offer["item"]))

func sell_to(npc_id: String,player) -> Dictionary:
	if not sale_available(npc_id,player):
		return {"ok":false,"message":"Bring a finished item from your own craft."}
	var offer: Dictionary=SALES[npc_id]
	var economy=player.world.village_sim.economy
	var stock_name: String=String(offer["stock"])
	var price: int=int(offer["price"])
	if economy.treasury<price:
		return {"ok":false,"message":"The village treasury cannot pay that commission."}
	if int(economy.stocks[stock_name])>=economy.CAP:
		return {"ok":false,"message":"The village warehouse is full."}
	player.inventory.erase(String(offer["item"]))
	player.selected_slot=clampi(player.selected_slot,0,maxi(0,player.inventory.size()-1))
	player.refresh_held_model()
	economy.stocks[stock_name]=int(economy.stocks[stock_name])+1
	economy.treasury-=price
	player.coins+=price
	economy._record("artisan_purchase",npc_id,stock_name,1)
	var person: Dictionary=player.world.village_sim.people[npc_id]
	var trust: Dictionary=person["trust"]
	trust["wizard"]=clampf(float(trust.get("wizard",0.0))+3.0,-100.0,100.0)
	player.world.village_sim.witness_event("artisan_delivery",npc_id)
	return {"ok":true,"changed":true,
		"message":"A fair exchange: %d coins paid from the village treasury. The %s enters the real public stock; your work is remembered." % [price,stock_name]}

func snapshot() -> Dictionary:
	return {"version":1,"experience":experience.duplicate(true),
		"charged_hearths":charged_hearths.duplicate(true)}

func restore(data: Dictionary) -> bool:
	if data.is_empty():
		experience={"baker":0,"blacksmith":0}
		charged_hearths={"baker":0,"blacksmith":0}
		return true
	if int(data.get("version",0))!=1: return false
	var saved: Variant=data.get("experience",{})
	var flames: Variant=data.get("charged_hearths",{})
	if not (saved is Dictionary) or not (flames is Dictionary): return false
	var out_x: Dictionary={}
	var out_f: Dictionary={}
	for career in ["baker","blacksmith"]:
		if not saved.has(career) or not flames.has(career): return false
		var xp: int=int(saved[career])
		var heat: int=int(flames[career])
		if xp<0 or xp>100000 or heat<0 or heat>1: return false
		out_x[career]=xp
		out_f[career]=heat
	experience=out_x
	charged_hearths=out_f
	return true
