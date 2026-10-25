extends SceneTree
func _initialize() -> void:
	for a in ["ui_accept","ui_cancel","ui_down"]:
		var names := []
		for e in InputMap.action_get_events(a):
			names.append(e.as_text())
		print(a, ": ", names)
	quit()
