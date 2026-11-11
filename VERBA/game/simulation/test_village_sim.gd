extends SceneTree
## Run: godot --headless --path VERBA/game --script res://simulation/test_village_sim.gd
const Village = preload("res://simulation/village_sim.gd")
func _initialize() -> void:
    var a = Village.new(4242)
    var b = Village.new(4242)
    for sim in [a, b]:
        sim.add_villager("marcus", "blacksmith", 85, 25, 40)
        sim.add_villager("livia", "baker", 30, 90, 35)
        sim.add_villager("titus", "guard", 65, 20, 75)
        sim.relationship("livia", "marcus")["affection"] = 25.0
    for i in range(500):
        a.step()
        b.step()
    assert(a.snapshot() == b.snapshot(), "same seed must reproduce identical world")
    var saved = a.snapshot()
    var c = Village.new(1)
    assert(c.restore(saved), "save must restore")
    for i in range(100):
        a.step()
        c.step()
    assert(a.snapshot() == c.snapshot(), "restored RNG and simulation must continue identically")
    assert(not c.restore({"version": 999}), "unsupported save must fail safely")
    c.witness_crime("titus", {"actor": "marcus", "kind": "theft"})
    assert(c.villagers["titus"]["known_crimes"].size() == 1)
    assert(c.villagers["livia"]["known_crimes"].is_empty(), "no omniscient crime knowledge")
    print("VERBA village simulation: PASS (determinism, 600 ticks, restore, witnesses)")
    quit(0)
