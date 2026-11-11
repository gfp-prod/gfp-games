extends SceneTree
## Photograph the actual first-person grimoire with real book text rendered
## onto its 3D pages. These frames are not mockups or screenshot composites.
const OUT: String = "res://visual-reports"

func _initialize() -> void:
	call_deferred("_capture")

func _capture() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var game: Node3D = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	var player = game.player
	var pages = player.book
	var candidate: Node3D = null
	for pickup in game.items:
		if pickup.item_type == "book" and pickup.word == "de_herbis":
			candidate = pickup
			break
	if candidate == null:
		_fail("No physical Latin volume for visual inspection")
		return
	game.collect(candidate)
	if not pages.open or not pages.page_labels[0].text.contains("Herba in horto"):
		_fail("Book was not actually opened onto readable Latin pages")
		return
	player.guide_visible = false
	player.guide_panel.visible = false
	player.pitch.rotation.x = 0.15
	player.camera.current = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	# Freeze book in the same fully raised 3D pose that gameplay eases into.
	pages.lift = 1.0
	pages.set_process(false)
	pages.apply_pose(1.0)
	await _save_frame("latin_book_passage")
	if not pages.begin_study():
		_fail("Book has no in-world comprehension question")
		return
	await _save_frame("latin_book_question")
	var response: Dictionary = pages.submit_answer(0)
	if not bool(response.get("first_time",false)):
		_fail("Study could not yield a reward")
		return
	await _save_frame("latin_book_reward")
	# The real moving vellum is an actual 3D object and should be inspected
	# mid-flight from the same in-game camera, not an editor mockup.
	pages.book_cursor = -1
	pages.update_pages()
	pages.turn_page(1)
	pages._process(.22)
	pages._process(.14)
	if pages.turning_leaf == null or not pages.turning_leaf.visible:
		_fail("Physical page-turn mesh was not rendered during page change")
		return
	await _save_frame("grimoire_page_turn")
	print("VERBA_BOOK_VISUAL_QA_COMPLETE")
	quit(0)

func _save_frame(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var picture: Image = root.get_texture().get_image()
	if picture == null or picture.is_empty():
		_fail("Godot produced no rendered image for " + name)
		return
	var file: String = OUT + "/" + name + ".png"
	if picture.save_png(file) != OK:
		_fail("Cannot save rendered image for " + name)
		return
	print("VERBA_BOOK_FRAME ",file," ",picture.get_width(),"x",picture.get_height())

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
