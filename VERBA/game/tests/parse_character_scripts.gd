extends SceneTree
## Parse the source as a GDScript resource directly, rather than relying
## on indirect world.gd preload errors which erase the original line.
func _initialize() -> void:
	for script_name in ["npc_genetics.gd","folk_portrait_finish.gd",
		"folk_costume_finish.gd","npc_actor.gd"]:
		var script: GDScript=GDScript.new()
		script.source_code=FileAccess.get_file_as_string(
			"res://scripts/"+script_name)
		var status: Error=script.reload()
		print("SCRIPT_PROBE ",script_name," ",error_string(status))
		if status!=OK:
			quit(1)
			return
	print("PASS: direct character script parser")
	quit(0)
