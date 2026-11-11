extends SceneTree
## A page turn should be an actual moving 3D sheet with a midpoint
## content swap; it must not silently change text before paper moves.
func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var valley: Node3D = load("res://main.tscn").instantiate()
	root.add_child(valley)
	await process_frame
	var book = valley.player.book
	book.open = true
	book.book_cursor = -1
	book.lift = 1.0
	book.apply_pose(1.0)
	var original_text: String = book.page_labels[0].text
	if book.learned.size() < 5:
		_fail("Need two pages of real learned Latin")
		return
	for label in book.page_labels:
		if label.font_size > 28:
			_fail("Latin lexicon ink is too large for physical pages")
			return
		for physical_line in label.text.split("\n"):
			if physical_line.length() > 24:
				_fail("Ink overflows the physical page: "+physical_line)
				return
	book.turn_page(1)
	if book.page_turn <= 0.0 or book.pending_page_index != 1 or book.page_index != 0:
		_fail("Page turned instantly instead of scheduling physical motion")
		return
	book._process(.28)
	book._process(.13)
	if book.page_index != 1 or book.page_labels[0].text == original_text:
		_fail("Physical sheet passed midpoint without revealing new words")
		return
	if book.turning_leaf == null or not book.turning_leaf.visible:
		_fail("The real moving parchment is absent")
		return
	if absf(book.turning_leaf.rotation.y) < .75:
		_fail("Page was not visibly rotating around its gutter")
		return
	book._process(.65)
	if book.page_turn > 0.0 or book.turning_leaf.visible or not book.page_labels[0].visible:
		_fail("Sheet remained in view or ink failed to reappear after page turn")
		return
	print("PASS: physical grimoire sheet rotates, swaps ink at hinge crossing, and settles into next pages")
	quit(0)

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
