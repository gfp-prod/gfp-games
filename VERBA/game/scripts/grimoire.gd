extends Node3D
## The book is geometry under the camera, not a CanvasLayer or menu.
const ART = preload("res://scripts/art.gd")
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
var last_consult := -9999.0
var recall_streak := 0
var total_casts := 0
var title_label: Label3D
var header_label: Label3D
var lexicon: Dictionary = {}

func setup(p: CharacterBody3D, vocabulary: Dictionary) -> void:
	player=p
	lexicon=vocabulary

func _ready() -> void:
	# Two authored GLB states, both visible as world geometry attached to camera.
	# The book physically raises before unfolding its covers and pages.
	book=Node3D.new()
	book.name="LeatherGrimoire"
	add_child(book)
	var closed_asset: PackedScene = load("res://assets/models/authored/Grimoire_Closed.glb")
	var open_asset: PackedScene = load("res://assets/models/authored/Grimoire_Open.glb")
	closed_visual=closed_asset.instantiate()
	closed_visual.name="ClosedBindingAndClasp"
	book.add_child(closed_visual)
	open_visual=open_asset.instantiate()
	open_visual.name="OpenedCoversAndPhysicalPages"
	book.add_child(open_visual)
	# Ink labels occupy the surface of each physical page; no HTML overlay.
	for side in [-1,1]:
		var l:=Label3D.new()
		l.name="InkWrittenOnParchment"
		l.font_size=24
		l.pixel_size=.00145
		l.modulate=Color("332922")
		l.outline_size=0
		l.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		l.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
		l.position=Vector3(side*.36,-.02,.117)
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
		persist()

func has_word(word: String) -> bool:
	return learned.has(word)

func toggle() -> void:
	open = not open
	if open:
		last_consult = Time.get_ticks_msec() / 1000.0
		recall_streak=0
	update_pages()

func turn_page(dir: int) -> void:
	if not open: return
	var pages_total: int = maxi(1, ceili(float(learned.size()) / 4.0))
	page_index = posmod(page_index+dir,pages_total)
	page_turn = 1.0
	update_pages()

func update_pages() -> void:
	if page_labels.size()<2: return
	for side in range(2):
		var line := ""
		if side == 0:
			line = "L I B E R   V E R B O R U M\n\n"
		else:
			line = "M E M O R I A    •    %d\n\n" % total_casts
		for i in range(2):
			var idx := page_index*4+side*2+i
			if idx>=learned.size(): continue
			var w: String=learned[idx]
			var def: Dictionary=lexicon.get(w,{})
			line += w.to_upper()+"\n"+String(def.get("meaning","?"))+"\n\n"
		if side == 1:
			line += "─────\n"+str(page_index+1)+" / "+str(maxi(1,ceili(float(learned.size())/4.0)))
			line += "\nS: Preserve   L: Recall"
		page_labels[side].text=line

func mark_cast(word: String) -> bool:
	total_casts += 1
	var remembered := (Time.get_ticks_msec()/1000.0 - last_consult)>30.0
	if remembered: recall_streak += 1
	learn(word)
	update_pages()
	persist()
	return remembered

func persist() -> void:
	var file := FileAccess.open("user://verba_grimoire.json",FileAccess.WRITE)
	if file == null: return
	file.store_string(JSON.stringify({"learned":learned,"total_casts":total_casts},"\t"))

func restore() -> void:
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
	book.position=Vector3(.39,-1.11,-.91).lerp(Vector3(.005,-.21,-1.02),alpha)
	book.rotation=Vector3(.66,-.35,-.20).lerp(Vector3(-.20,0,0),alpha)
	book.scale=Vector3.ONE * lerpf(.67,1.0,alpha)
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
	page_turn=move_toward(page_turn,0,delta*3.0)
	if page_turn>0.0 and book != null:
		book.rotation.z += sin(page_turn*PI)*.02
