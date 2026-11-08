extends Node3D
## World-space lettering: occluded by real geometry, not a HUD sprite.
var age := 0.0
var duration := 2.1
var label: Label3D
var light: OmniLight3D
var drift := Vector3.ZERO

func begin(word: String, pos3: Vector3, tint: Color = Color("edce8c")) -> void:
	global_position=pos3
	label = Label3D.new()
	label.text=word.to_upper()
	label.font_size=54 if word.length() < 18 else 32
	label.pixel_size=0.006 if word.length() < 18 else 0.0032
	label.outline_size=10
	label.modulate=tint
	label.outline_modulate=Color("39281d")
	label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test=false
	label.fixed_size=false
	label.double_sided=true
	add_child(label)
	light=OmniLight3D.new()
	light.light_color=tint
	light.light_energy=0.6
	light.omni_range=3.0
	add_child(light)
	drift=Vector3(randf_range(-.09,.09), .53,randf_range(-.09,.09))

func _process(delta: float) -> void:
	age += delta
	position += drift * delta
	rotation.y += delta * 0.16
	if label != null:
		var f: float = clampf((duration-age)/duration,0,1)
		label.modulate.a=f
		label.scale=Vector3.ONE*(0.8 + age*0.15)
	if light != null: light.light_energy=maxf(0.0,.6*(1.0-age/duration))
	if age>duration: queue_free()
