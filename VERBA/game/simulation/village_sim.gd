extends RefCounted
## Deterministic, headless-friendly village simulation. No scene dependencies.
## Decisions are utility-scored; events are observable; state is serializable.
const ACTIONS := ["work", "eat", "rest", "socialize", "court", "report_crime", "patrol", "steal"]
var rng := RandomNumberGenerator.new()
var villagers: Dictionary = {}
var events: Array[Dictionary] = []
var tick_number := 0

func _init(seed_value: int = 1) -> void:
    rng.seed = seed_value

func add_villager(id: String, role: String, crow: float, cat: float, wolf: float) -> void:
    assert(not villagers.has(id))
    villagers[id] = {
        "id": id, "role": role, "crow": clampf(crow, 0, 100),
        "cat": clampf(cat, 0, 100), "wolf": clampf(wolf, 0, 100),
        "hunger": 20.0, "fatigue": 10.0, "loneliness": 20.0,
        "money": 10, "relationships": {}, "memories": [],
        "last_action": "", "action_age": 0, "known_crimes": []
    }

func relationship(a: String, b: String) -> Dictionary:
    var links: Dictionary = villagers[a]["relationships"]
    if not links.has(b):
        links[b] = {"affection": 0.0, "trust": 0.0, "attraction": 0.0}
    return links[b]

func score(v: Dictionary, action: String) -> float:
    var crow: float = v["crow"] / 100.0
    var cat: float = v["cat"] / 100.0
    var wolf: float = v["wolf"] / 100.0
    match action:
        "eat": return v["hunger"] * 1.6
        "rest": return v["fatigue"] * 1.5
        "work": return 20.0 + crow * 45.0 + (10.0 if v["money"] < 4 else 0.0)
        "socialize": return v["loneliness"] + cat * 35.0
        "court": return (10.0 + cat * 30.0) if not v["relationships"].is_empty() else -1000.0
        "patrol": return 25.0 + wolf * 35.0 if v["role"] == "guard" else -1000.0
        "report_crime": return 95.0 if not v["known_crimes"].is_empty() else -1000.0
        "steal": return (wolf * 32.0 + (20.0 if v["money"] < 3 else 0.0) - crow * 18.0)
    return -1000.0

func choose_action(id: String) -> String:
    var v: Dictionary = villagers[id]
    var best := "rest"
    var best_score := -INF
    for action in ACTIONS:
        var value := score(v, action)
        if v["last_action"] == action and v["action_age"] < 2:
            value += 8.0
        value += rng.randf_range(-4.0, 4.0)
        if value > best_score:
            best_score = value
            best = action
    return best

func step() -> void:
    tick_number += 1
    var ids := villagers.keys()
    ids.sort()
    for id in ids:
        var v: Dictionary = villagers[id]
        v["hunger"] = minf(100.0, v["hunger"] + 4.0)
        v["fatigue"] = minf(100.0, v["fatigue"] + 3.0)
        v["loneliness"] = minf(100.0, v["loneliness"] + 2.0)
        var action := choose_action(id)
        if action == v["last_action"]:
            v["action_age"] += 1
        else:
            v["action_age"] = 0
        v["last_action"] = action
        match action:
            "eat":
                if v["money"] > 0:
                    v["money"] -= 1
                    v["hunger"] = maxf(0.0, v["hunger"] - 50.0)
            "rest": v["fatigue"] = maxf(0.0, v["fatigue"] - 55.0)
            "work":
                v["money"] += 2
                v["fatigue"] = minf(100.0, v["fatigue"] + 8.0)
            "socialize", "court":
                v["loneliness"] = maxf(0.0, v["loneliness"] - 30.0)
                var others := ids.filter(func(other): return other != id)
                if not others.is_empty():
                    var other: String = others[rng.randi_range(0, others.size() - 1)]
                    var link := relationship(id, other)
                    link["affection"] = clampf(link["affection"] + (4.0 if action == "socialize" else 2.0), -100, 100)
                    if action == "court":
                        link["attraction"] = clampf(link["attraction"] + 3.0, -100, 100)
            "steal":
                if v["money"] < 5:
                    v["money"] += 2
                    emit_event("theft", id, {"amount": 2})
            "report_crime":
                emit_event("crime_report", id, {"crime": v["known_crimes"].pop_front()})
        emit_event("decision", id, {"action": action})

func witness_crime(witness: String, crime: Dictionary) -> void:
    if not villagers.has(witness):
        return
    villagers[witness]["known_crimes"].append(crime.duplicate(true))
    villagers[witness]["memories"].append({"tick": tick_number, "event": "witnessed_crime", "actor": crime.get("actor", "")})

func emit_event(kind: String, actor: String, data: Dictionary) -> void:
    events.append({"tick": tick_number, "kind": kind, "actor": actor, "data": data.duplicate(true)})

func snapshot() -> Dictionary:
    return {"version": 1, "tick": tick_number, "rng_seed": rng.seed, "rng_state": rng.state,
        "villagers": villagers.duplicate(true), "events": events.duplicate(true)}

func restore(data: Dictionary) -> bool:
    if data.get("version") != 1 or not data.has("villagers") or not data.has("rng_state"):
        return false
    tick_number = int(data["tick"])
    villagers = data["villagers"].duplicate(true)
    events.clear()
    for event in data.get("events", []):
        events.append(event.duplicate(true))
    rng.seed = int(data["rng_seed"])
    rng.state = int(data["rng_state"])
    return true
