extends Node3D
## A single mutable thing in the world, not an effect-only prop.
## World drives these at a low fixed simulation frequency rather than running
## one _process per object. Decorative grass blades are batched for rendering;
## interactive grass clumps, ferns, stones, wood and trees are independent nodes.

var world: Node3D
var kind: String = "wood"
var uid: int = 0
var base_size: float = 1.0
var water: float = 0.08
var heat: float = 0.0
var fuel: float = 1.0
var health: float = 1.0
var growth: float = 1.0
var food: float = 0.7
var brittleness: float = 0.1
var burning: bool = false
var dead: bool = false
var original_canopy_scale: Vector3 = Vector3.ONE
var _char_visual: MeshInstance3D
var time_since_fire: float = 0.0
var rng := RandomNumberGenerator.new()

func configure(w: Node3D, object_kind: String, object_id: int, base: float=1.0) -> void:
	world = w
	kind = object_kind
	uid = object_id
	base_size = base
	rng.seed = int(object_id * 1009 + 43)
	match kind:
		"tree": fuel=1.0; health=1.0; food=0.5; water=0.24
		"dead_tree": fuel=0.7; health=0.45; food=0.0; water=0.04
		"fern": fuel=0.25; health=0.70; food=0.6; water=0.45
		"grass": fuel=0.14; health=0.55; food=0.8; water=0.24
		"wood": fuel=0.65; health=0.66; food=0.0; water=0.1
		"stone": fuel=0.0; health=1.0; food=0.0; water=0.02; brittleness=0.09
	set_meta("wetness",water)
	set_meta("burning",burning)
	set_meta("growth",growth)
	set_meta("kind",kind)
	set_meta("sim_id",uid)

func flammable() -> bool:
	return kind != "stone" and fuel > 0.01 and not dead

func get_state_report() -> String:
	var flags: PackedStringArray = PackedStringArray()
	if burning: flags.append("burning")
	elif heat >= 0.60: flags.append("hot")
	if water >= 0.65: flags.append("soaked")
	elif water >= 0.36: flags.append("damp")
	if growth > 1.15: flags.append("overgrown")
	if health < 0.28: flags.append("dying")
	if dead: flags.append("spent")
	if kind == "stone" and brittleness > 0.58: flags.append("cracked")
	if flags.is_empty(): flags.append("healthy" if kind != "stone" else "cold")
	return kind.replace("_", " ") + " · " + ", ".join(flags)

func apply_effect(effect: String, strength: float=1.0) -> bool:
	match effect:
		"water", "rain", "wet":
			water = clampf(water + strength * 0.60, 0.0, 1.0)
			heat = maxf(0.0, heat - strength * 0.75)
			if burning and water > 0.50:
				burning = false
				time_since_fire = 0.0
		"ignite", "kindle", "fire":
			if not flammable() or water > 0.72: return false
			burning = true
			heat = maxf(heat, 0.80)
		"heat":
			heat = clampf(heat + strength * 0.48, 0.0, 1.0)
			if kind == "stone":
				if water > 0.40 and heat > 0.75:
					brittleness=clampf(brittleness + strength*.25,0.0,1.0)
			elif flammable() and heat > 0.76 and water < 0.38:
				burning = true
		"cold", "frost":
			heat = maxf(0.0,heat - strength*.8)
			burning = false
			if kind == "stone": brittleness=clampf(brittleness + water*strength*.25,0.0,1.0)
		"grow":
			if kind not in ["tree","dead_tree","grass","fern"] or dead: return false
			growth = minf(1.95,growth + 0.15*strength)
			food = minf(1.0,food + 0.1*strength)
			health = minf(1.0,health + .07*strength)
		"eat":
			if kind not in ["fern","grass"] or dead or food < 0.05: return false
			food = maxf(0.0,food - .30*strength)
			health = maxf(0.0,health - .075*strength)
		"impact":
			if kind == "stone":
				brittleness = clampf(brittleness + strength * (.22 + heat*.12),0.0,1.0)
			else:
				health = maxf(0.0,health - .15*strength)
		"rise":
			position.y += strength*.25
		_:
			return false
	update_visual_state()
	return true

func simulate(dt: float, is_raining: bool, local_fire: float, wind: float) -> void:
	# Each object has its own history. The weather is shared; its consequences are not.
	if is_raining: apply_effect("water", dt*.24)
	else: water = maxf(0.0,water - dt*(.018 + absf(wind)*.003))
	heat = maxf(0.0,heat - dt*(.08 if water < .45 else .20))
	if local_fire < (3.4 if kind in ["tree","dead_tree"] else 1.9):
		apply_effect("heat", dt*(1.3 if local_fire < 1.5 else .5))
	if burning:
		time_since_fire += dt
		water = maxf(0.0,water-dt*.14)
		fuel = maxf(0.0,fuel-dt*(.025+absf(wind)*.004))
		health = maxf(0.0,health-dt*.042)
		if water > .65 or fuel < .015:
			burning = false
	elif not dead and kind in ["tree","grass","fern"] and water > .28:
		# Recovery is slower than destruction; grazed patches regrow.
		food=minf(1.0,food + dt*.004*water)
		health=minf(1.0,health + dt*.0018*water)
	if health <= .005 and kind != "stone": dead = true; burning = false
	set_meta("wetness",water)
	set_meta("burning",burning)
	set_meta("growth",growth)
	update_visual_state()

func update_visual_state() -> void:
	scale = Vector3.ONE * base_size * growth
	var canopy = get_node_or_null("LivingCanopy") as Node3D
	if canopy != null:
		canopy.visible = not dead and health > .05
		canopy.scale = Vector3.ONE * clampf(health * .78 + .22,.20,1.0)
	# A world-object-specific, persistent scorch marker. It is not an overlay.
	if kind in ["tree","dead_tree","wood"]:
		if (burning or health < .65) and _char_visual == null:
			var mesh:=CylinderMesh.new()
			mesh.top_radius=.23; mesh.bottom_radius=.34; mesh.height=1.2
			_char_visual=MeshInstance3D.new()
			_char_visual.name="ScorchedBark"
			_char_visual.mesh=mesh
			var mat:=StandardMaterial3D.new()
			mat.albedo_color=Color("211e1b")
			mat.roughness=1.0
			_char_visual.material_override=mat
			_char_visual.position.y=.59 if kind != "wood" else .24
			add_child(_char_visual)
		if _char_visual != null:
			_char_visual.visible = burning or health < .65
	if kind in ["grass","fern"]:
			var visual = get_node_or_null("PlantVisual") as MeshInstance3D
			if visual != null: visual.scale.y = clampf(food*.75+.25,.15,1.0)
