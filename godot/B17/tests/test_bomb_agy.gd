extends SceneTree

func _initialize() -> void:
	var bomb = load("res://bomb_model.gd").new()
	if not bomb.release(Vector3(0, 100, 0), Vector3(0, 0, -50)):
		print("TEST FAIL: initial release failed"); quit(1); return
	if bomb.release(Vector3(0, 100, 0), Vector3(0, 0, -50)):
		print("TEST FAIL: duplicate release allowed"); quit(1); return
	bomb.step(1.0 / 60.0, Vector3(0, 0, -225), 12.0)
	if not (bomb.active and bomb.result == "EN_VUELO"):
		print("TEST FAIL: state not airborne after step"); quit(1); return
	for i in range(600):
		bomb.step(1.0 / 60.0, Vector3(0, 0, -225), 12.0)
	if bomb.active or not bomb.spent or bomb.result != "IMPACTO" or bomb.position.y != 0.0:
		print("TEST FAIL: expected impact state mismatch"); quit(1); return
	bomb.reset()
	if not bomb.release(Vector3(0, 100, 0), Vector3(0, 0, -50)):
		print("TEST FAIL: release after reset failed"); quit(1); return
	for i in range(600):
		bomb.step(1.0 / 60.0, Vector3(1000, 0, -225), 12.0)
	if bomb.result != "FALLO":
		print("TEST FAIL: expected miss result"); quit(1); return
	bomb.reset()
	if bomb.spent or bomb.active or bomb.result != "LISTA":
		print("TEST FAIL: final reset state invalid"); quit(1); return
	print("TEST PASS: Agy bomb airborne hit miss and ammunition")
	quit(0)
