"""Static integration review (not a substitute for running Godot).

Designed for the CURRENT codebase, not old prototype book-GLBs and dead roads.
"""
from pathlib import Path
import json

root = Path(__file__).resolve().parents[1]
needed = (
    "project.godot", "main.tscn", "data/lexicon.json", "data/books.json",
    "scripts/world.gd", "scripts/world_persistence.gd", "scripts/creature.gd",
    "scripts/player.gd", "scripts/magic.gd", "scripts/latin_grammar.gd",
    "scripts/grimoire.gd", "scripts/grimoire_visual.gd",
    "scripts/home_dressing.gd", "scripts/ruin_art.gd", "scripts/foliage.gd",
    "scripts/pickup.gd", "assets/textures/real/vale_terrain_blend.jpg",
    "assets/textures/authored/vellum_cream.png",
)
for rel in needed:
    assert (root / rel).is_file(), f"Missing runtime source: {rel}"

word_list = json.loads((root / "data/lexicon.json").read_text())
words = [e["word"] for e in word_list]
assert len(words) >= 20 and len(words) == len(set(words))

player = (root / "scripts/player.gd").read_text()
for key in ("move_and_slide()", "PhysicsRayQueryParameters3D",
            "_pickup_visible(", "cast_latin(", "MOUSE_MODE_CAPTURED"):
    assert key in player, f"Player integration missing {key}"

world = (root / "scripts/world.gd").read_text()
for marker in ("HOME_DRESSING.populate", "RUIN_ART.add_broken_wall",
               "RUIN_ART.add_wall_collision", "night_visual_blend",
               "spawn_growth_patch", "populate_collectibles"):
    assert marker in world, marker
assert "func build_old_road(" not in world, "Obsolete floating-road generator resurfaced"

book = (root / "scripts/grimoire.gd").read_text()
for marker in ("BOOK_VISUAL.make_open_binding", "open_book", "begin_study",
               "submit_answer", "world.save_world()", "Label3D"):
    assert marker in book, marker
assert 'FileAccess.open("user://verba_grimoire.json"' not in book, (
    "Two writable sources of grimoire truth would corrupt saves"
)

save = (root / "scripts/world_persistence.gd").read_text()
for marker in ('"collected_pickups"', '"dropped_pickups"', '"inventory"',
               '"generated"', 'path + ".bak"', 'path + ".tmp"',
               '"id":String(animal.persistent_id)'):
    assert marker in save, f"Critical save invariant missing {marker}"

print("PASS: current VERBA source integration, unique lexicon, art/physics modules, and single world-save authority")
print("NOTE: This static check is supplemented by real Godot engine and OpenGL tests.")
