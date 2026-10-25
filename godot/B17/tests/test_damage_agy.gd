extends SceneTree

func _initialize() -> void:
	var model = load("res://core/damage.gd").new()
	model.apply_damage(-10, 0)
	if model.hull != 100.0:
		print("TEST FAIL: hull not 100 after negative damage")
		quit(1); return
	model.apply_damage(20, 2)
	if model.hull != 80.0 or model.engines[2] != 50.0 or model.engines[0] != 100.0 or model.engines[1] != 100.0 or model.engines[3] != 100.0 or model.thrust_factor() >= 1.0:
		print("TEST FAIL: engine 2 damage mismatch")
		quit(1); return
	model.apply_damage(1000, 2)
	if not model.destroyed() or model.hull != 0.0 or model.engines[2] != 0.0:
		print("TEST FAIL: destroyed state mismatch")
		quit(1); return
	model.reset()
	if model.hull != 100.0 or model.engine != 100.0 or model.destroyed() or model.engines[0] != 100.0 or model.engines[1] != 100.0 or model.engines[2] != 100.0 or model.engines[3] != 100.0:
		print("TEST FAIL: reset state mismatch")
		quit(1); return
	print("TEST PASS: Agy four-engine damage checks")
	quit(0)
