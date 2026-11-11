extends RefCounted
## Deterministic, bounded stock-flow model. Currency is never minted by "work".
## A workplace consumes inputs and deposits outputs; exchange transfers coins.
const VERSION := 1
const CAP := 500
const RECIPES := {
	"farmer":{"inputs":{},"outputs":{"grain":3,"herb":1}},
	"baker":{"inputs":{"grain":2},"outputs":{"bread":2}},
	"blacksmith":{"inputs":{"ore":1,"wood":1},"outputs":{"tools":1}},
	"builder":{"inputs":{"wood":2,"tools":1},"outputs":{"housing":1}},
	"scribe":{"inputs":{"wood":1},"outputs":{"pages":2}},
	"keeper":{"inputs":{"herb":1},"outputs":{"medicine":1}},
	"painter":{"inputs":{"herb":1},"outputs":{"paint":1}},
	"bard":{"inputs":{},"outputs":{"song":1}},
	"guard":{"inputs":{},"outputs":{"safety":1}},
	"priest":{"inputs":{},"outputs":{"care":1}},
	"mayor":{"inputs":{},"outputs":{"order":1}},
	"merchant":{"inputs":{},"outputs":{}}
}
var stocks: Dictionary = {}
var treasury: int = 120
var transactions: Array[Dictionary] = []
var tick: int = 0

func _init() -> void:
	for item in ["grain","herb","bread","ore","wood","tools","housing","pages","medicine","paint","song","safety","care","order"]:
		stocks[item] = 0
	stocks["grain"]=12
	stocks["bread"]=12
	stocks["ore"]=9
	stocks["wood"]=18
	stocks["tools"]=4

func _record(kind: String, who: String, item: String, amount: int) -> void:
	transactions.append({"tick":tick,"kind":kind,"actor":who,"item":item,"amount":amount})
	if transactions.size()>128: transactions.pop_front()

func can_work(role: String) -> bool:
	if not RECIPES.has(role): return false
	if role=="merchant": return int(stocks.get("grain",0))>0 and int(stocks.get("bread",0))<CAP
	var recipe: Dictionary=RECIPES[role]
	for item in recipe["inputs"]:
		if int(stocks.get(item,0))<int(recipe["inputs"][item]): return false
	for item in recipe["outputs"]:
		if int(stocks.get(item,0))+int(recipe["outputs"][item])>CAP: return false
	return true

func work(id: String, role: String, person: Dictionary) -> bool:
	if not RECIPES.has(role): return false
	var recipe: Dictionary = RECIPES[role]
	if role=="merchant":
		# Move real inventory through the market; no goods are fabricated.
		if not can_work(role): return false
		stocks["grain"]=int(stocks["grain"])-1
		stocks["bread"]=int(stocks["bread"])+1
		_record("distribution",id,"grain",1)
		return true
	var inputs: Dictionary = recipe["inputs"]
	for item in inputs:
		if int(stocks.get(item,0)) < int(inputs[item]): return false
	var outputs: Dictionary = recipe["outputs"]
	for item in outputs:
		if int(stocks.get(item,0)) + int(outputs[item]) > CAP: return false
	for item in inputs: stocks[item] = int(stocks[item])-int(inputs[item])
	for item in outputs: stocks[item] = int(stocks[item])+int(outputs[item])
	# Public wages transfer finite village treasury, never appear from nowhere.
	if treasury>0 and int(person["wealth"])<100:
		treasury-=1
		person["wealth"]=int(person["wealth"])+1
	_record("production",id,role,1)
	return true

func eat(id: String, person: Dictionary) -> bool:
	if int(stocks.get("bread",0))<=0 or int(person["wealth"])<=0: return false
	stocks["bread"]=int(stocks["bread"])-1
	person["wealth"]=int(person["wealth"])-1
	treasury+=1
	person["hunger"]=maxf(0.0,float(person["hunger"])-48.0)
	_record("purchase",id,"bread",1)
	return true

func player_exchange(npc_id: String, take: String, give: String, inventory: Array) -> bool:
	# The player's item is the input; the village's finite stock is the output.
	# Grain deliveries go back into the same public resource ledger.
	if not inventory.has(take) or not stocks.has(take) or not stocks.has(give): return false
	if int(stocks[give])<=0 or int(stocks[take])>=CAP: return false
	var slot: int=inventory.find(take)
	inventory.remove_at(slot)
	inventory.append(give)
	stocks[take]=int(stocks[take])+1
	stocks[give]=int(stocks[give])-1
	_record("player_trade",npc_id,take,1)
	return true

func shortage(item: String, amount: int) -> int:
	if not stocks.has(item): return 0
	var removed: int=mini(int(stocks[item]),maxi(0,amount))
	stocks[item]=int(stocks[item])-removed
	_record("shortage","village",item,removed)
	return removed

func snapshot() -> Dictionary:
	return {"version":VERSION,"stocks":stocks.duplicate(true),"treasury":treasury,
		"transactions":transactions.duplicate(true),"tick":tick}

func restore(record: Dictionary) -> bool:
	if int(record.get("version",0))!=VERSION: return false
	var inventory: Variant=record.get("stocks",{})
	if not (inventory is Dictionary) or inventory.size()!=stocks.size(): return false
	for item in stocks:
		if not inventory.has(item) or int(inventory[item])<0 or int(inventory[item])>CAP: return false
	var funds: int=int(record.get("treasury",-1))
	if funds<0 or funds>100000: return false
	var ledger: Variant=record.get("transactions",[])
	if not (ledger is Array) or ledger.size()>128: return false
	stocks=inventory.duplicate(true)
	treasury=funds
	transactions.clear()
	for entry in ledger:
		if not (entry is Dictionary): return false
		transactions.append(entry.duplicate(true))
	tick=maxi(0,int(record.get("tick",0)))
	return true
