extends Node3D
## The book is geometry under the camera, not a CanvasLayer or menu.
const ART = preload("res://scripts/art.gd")
const BOOK_VISUAL = preload("res://scripts/grimoire_visual.gd")
var player
var book
var left_cover: Node3D
var closed_visual: Node3D
var open_visual: Node3D
var page_labels: Array[Label3D] = []
var learned: Array[String] = ["ignis", "cresce", "pluvia", "lux", "veni", "dormi"]
var page_index := 0
var open := false
var lift := 0.0
var page_turn := 0.0
var page_turn_direction: int = 1
var pending_page_index: int = -1
var turning_leaf: Node3D
var last_consult := -9999.0
var recall_streak := 0
var total_casts := 0
var title_label: Label3D
var header_label: Label3D
var lexicon: Dictionary = {}
var scholar
var book_cursor: int = -1  # -1 means the spell lexicon; 0+ means a collected physical book
var quiz_open: bool = false
var study_feedback: String = ""

func setup(p: CharacterBody3D, vocabulary: Dictionary) -> void:
	player=p
	lexicon=vocabulary
	scholar=p.world.scholar

func _ready() -> void:
	# Two authored GLB states, both visible as world geometry attached to camera.
	# The book physically raises before unfolding its covers and pages.
	book=Node3D.new()
	book.name="LeatherGrimoire"
	add_child(book)
	var closed_asset: PackedScene = load("res://assets/models/authored/Grimoire_Closed.glb")

	closed_visual=closed_asset.instantiate()
	closed_visual.name="ClosedBindingAndClasp"
	book.add_child(closed_visual)
	open_visual=BOOK_VISUAL.make_open_binding()
	open_visual.name="OpenedCoversAndPhysicalPages"
	book.add_child(open_visual)
	turning_leaf = BOOK_VISUAL.make_turning_leaf()
	open_visual.add_child(turning_leaf)
	# Native layered binding replaces the former flat imported book geometry.
	# Ink labels occupy the surface of each physical page; no HTML overlay.
	# Prefer ordinary OS-installed serif faces, avoiding font download hassles
	# while keeping every letter as ink geometry attached to the 3D page.
	var in_world_serif := SystemFont.new()
	in_world_serif.font_names = PackedStringArray(["Georgia","Liberation Serif","DejaVu Serif"])
	for side in [-1,1]:
		var l:=Label3D.new()
		l.name="InkWrittenOnParchment"
		l.font=in_world_serif
		l.font_size=34
		l.pixel_size=.00175
		l.modulate=Color("332922")
		l.outline_size=0
		l.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		l.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
		# Ink follows the actual vellum. It used to hover three to five
		# centimetres above the physical leaf, casting obvious false depth.
		l.position=Vector3(side*.36,-.02,.046)
		l.no_depth_test=false
		l.double_sided=false
		book.add_child(l)
		page_labels.append(l)
	update_pages()
	apply_pose(0.0)

func learn(word: String) -> void:
	if not learned.has(word):
		learned.append(word)
		learned.sort()
		update_pages()
		# The authoritative world save, not a second file, owns learned words.

func has_word(word: String) -> bool:
	return learned.has(word)

func toggle() -> void:
	open = not open
	if open:
		last_consult = Time.get_ticks_msec() / 1000.0
		recall_streak=0
	update_pages()

func open_book(book_id: String) -> void:
	if scholar == null or not scholar.has_book(book_id): return
	book_cursor = scholar.owned.find(book_id)
	quiz_open = false
	study_feedback = ""
	open = true
	last_consult = Time.get_ticks_msec() / 1000.0
	update_pages()

func cycle_books() -> void:
	if scholar == null or scholar.owned.is_empty():
		study_feedback = "No books found yet."
		update_pages()
		return
	book_cursor += 1
	if book_cursor >= scholar.owned.size(): book_cursor = -1
	quiz_open = false
	study_feedback = ""
	update_pages()

func begin_study() -> bool:
	if scholar == null or book_cursor < 0 or book_cursor >= scholar.owned.size():
		return false
	quiz_open = true
	study_feedback = ""
	update_pages()
	return true

func submit_answer(answer_index: int) -> Dictionary:
	if not quiz_open or scholar == null or book_cursor < 0:
		return {"ok":false,"message":"Open a Latin question in the book."}
	var book_id: String = scholar.owned[book_cursor]
	var outcome: Dictionary = scholar.answer(book_id,answer_index)
	study_feedback = String(outcome.get("message",""))
	if bool(outcome.get("first_time",false)):
		for word in outcome.get("new_words",[]):
			learn(String(word))
		if DisplayServer.get_name() != "headless" and player != null:
			player.world.save_world()
	if bool(outcome.get("ok",false)): quiz_open = false
	update_pages()
	return outcome

func turn_page(dir: int) -> void:
	if not open or page_turn > 0.0 or book_cursor >= 0: return
	var pages_total: int = maxi(1,ceili(float(learned.size())/4.0))
	if pages_total <= 1 or dir == 0: return
	page_turn_direction = 1 if dir > 0 else -1
	pending_page_index = posmod(page_index+page_turn_direction,pages_total)
	page_turn = 1.0
	if turning_leaf != null:
		turning_leaf.visible = true
		turning_leaf.rotation.y = 0.0
		turning_leaf.scale.x = float(page_turn_direction)

func update_pages() -> void:
	if page_labels.size()<2: return
	if scholar != null and book_cursor >= 0 and book_cursor < scholar.owned.size():
		for label in page_labels: label.font_size = 34
		var id: String = scholar.owned[book_cursor]
		var volume: Dictionary = scholar.get_book(id)
		page_labels[0].text = String(volume.get("title","Liber")) + "\n" + \
			String(volume.get("passage","")) + "\n\nB: other books"
		if quiz_open:
			var choices: Array = volume.get("options",[])
			page_labels[1].text = String(volume.get("question","")) + "\n\n" + \
				"1. " + String(choices[0]) + "\n2. " + String(choices[1]) + "\n3. " + String(choices[2]) + \
				"\n\n" + study_feedback
		else:
			var glosses: PackedStringArray = PackedStringArray(volume.get("glossary",[]))
			var mastered: String = "STUDIED" if scholar.completed.has(id) else "UNREAD"
			page_labels[1].text = String(volume.get("subject","")).to_upper() + "  |  " + mastered + "\n" + \
				"\n".join(glosses) + "\n\nN: comprehension\n" + \
				"Scholar " + str(scholar.level) + " XP " + str(scholar.xp) + "/" + str(scholar.next_level_xp()) + "\nMana " + str(int(scholar.mana)) + "/" + str(int(scholar.max_mana)) + \
				"\n" + study_feedback
		# Book passage, answer feedback and glosses share the same real
		# paper-space width gate as the lexicon, not an overflowing HUD.
		for label in page_labels:
			label.text = _ink_wrap(label.text,22)
		return
	for side in range(2):
		# The Latin lexicon has longer definitions than the graded story text.
		# Its smaller type and hard word-wrap must fit the physical vellum.
		page_labels[side].font_size = 27
		var line := ""
		if side == 0:
			line = "LIBER VERBORUM\n\n"
		else:
			line = "MEMORIA  •  %d\n\n" % total_casts
		for i in range(2):
			var idx := page_index*4+side*2+i
			if idx>=learned.size(): continue
			var w: String=learned[idx]
			var def: Dictionary=lexicon.get(w,{})
			line += w.to_upper()+"\n"+_ink_wrap(String(def.get("meaning","?")),22)+"\n\n"
		if side == 1:
			line += "─────\n"+str(page_index+1)+" / "+str(maxi(1,ceili(float(learned.size())/4.0)))
			line += "\nB: Books   S: Save\nL: Load"
			if scholar != null:
				line += "\nScholar " + str(scholar.level) + " XP " + str(scholar.xp) + "/" + str(scholar.next_level_xp()) + "\nMana " + str(int(scholar.mana)) + "/" + str(int(scholar.max_mana))
		page_labels[side].text=_ink_wrap(line,22)

func _ink_wrap(paragraph: String, max_columns: int) -> String:
	# Real page-space column limit. Label3D has no reliable automatic
	# wrapping on a changing, curved first-person book surface.
	var result: PackedStringArray = PackedStringArray()
	for paragraph_line in paragraph.split("\n"):
		var current: String = ""
		for raw_word in paragraph_line.split(" ",false):
			var word: String = String(raw_word)
			if current.is_empty():
				current = word
			elif current.length()+1+word.length() <= max_columns:
				current += " "+word
			else:
				result.append(current)
				current = word
		if not current.is_empty(): result.append(current)
		elif paragraph_line.is_empty(): result.append("")
	return "\n".join(result)

func mark_cast(word: String) -> bool:
	total_casts += 1
	var remembered := (Time.get_ticks_msec()/1000.0 - last_consult)>30.0
	if remembered: recall_streak += 1
	learn(word)
	update_pages()
	# A valid cast changes both world state and knowledge; save them together.
	if DisplayServer.get_name() != "headless" and player != null and player.world != null:
		player.world.save_world()
	return remembered

func restore() -> void:
	# Read the pre-world-save legacy cache only when migrating an old profile.
	# Existing world saves must never merge unrelated global spell knowledge.
	if FileAccess.file_exists("user://verba_living_world_v1.json"): return
	if not FileAccess.file_exists("user://verba_grimoire.json"): return
	var d=JSON.parse_string(FileAccess.get_file_as_string("user://verba_grimoire.json"))
	if not (d is Dictionary): return
	for v in d.get("learned",[]):
		if v is String and lexicon.has(v) and not learned.has(v): learned.append(v)
	total_casts=int(d.get("total_casts",0))
	learned.sort()
	update_pages()

func apply_pose(alpha: float) -> void:
	# The player starts empty-handed. Book comes up from below eye-line.
	# A smaller, tilted book reads as a volume held in the player's hands.
	# The former full-screen pages resembled two yellow UI panels.
	book.position=Vector3(.39,-1.11,-.91).lerp(Vector3(.005,-.17,-1.02),alpha)
	book.rotation=Vector3(.66,-.35,-.20).lerp(Vector3(-.26,-.026,.014),alpha)
	book.scale=Vector3.ONE * lerpf(.67,.96,alpha)
	book.visible = alpha > .005
	# At halfway the covers fold outward. The two GLB versions give a genuinely
	# physical model throughout the animation instead of a static UI card.
	if closed_visual != null:
		closed_visual.visible = alpha < .63
		closed_visual.rotation.y = lerpf(.20, -.14, minf(1.0, alpha/.63))
	if open_visual != null:
		open_visual.visible = alpha >= .38
		open_visual.scale.x = clampf((alpha-.38)/.40,.005,1.0)
	for l in page_labels: l.visible=alpha>.86

func _process(delta: float) -> void:
	lift=move_toward(lift,1.0 if open else 0.0,delta*2.4)
	# Ease both raising and lowering; no popping book on screen.
	var ease=lift*lift*(3.0-2.0*lift)
	apply_pose(ease)
	if page_turn > 0.0:
		var progress: float = 1.0-page_turn
		if turning_leaf != null:
			turning_leaf.visible = open
			turning_leaf.rotation.y = float(page_turn_direction)*progress*PI
		# The new text appears when the paper crosses the binding.
		if pending_page_index >= 0 and progress >= .52:
			page_index = pending_page_index
			pending_page_index = -1
			update_pages()
		# Keep the stationary page legible while the other leaf swings.
		# Hiding BOTH pages made the book flash blank during animation.
		var turning_side: int = 1 if page_turn_direction > 0 else 0
		for i in range(page_labels.size()):
			var moving_ink: bool = progress < .12 or progress > .88
			page_labels[i].visible = open and lift > .87 and (i != turning_side or moving_ink)
		page_turn = move_toward(page_turn,0.0,delta*2.0)
		if page_turn <= 0.0:
			if pending_page_index >= 0:
				page_index = pending_page_index
				pending_page_index = -1
				update_pages()
			if turning_leaf != null:
				turning_leaf.visible = false
			for label in page_labels:
				label.visible = open and lift > .87
	elif turning_leaf != null:
		turning_leaf.visible = false
