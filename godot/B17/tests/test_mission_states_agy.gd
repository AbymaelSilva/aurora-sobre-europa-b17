extends SceneTree

func _initialize() -> void:
	var m = load("res://core/mission.gd").new()
	if not m or m.phase != "FORMACION":
		print("TEST FAIL: Initial formation")
		quit(1); return
	m.step(35.0, Vector3(0, 1200, 0), "LISTA", false)
	if m.phase != "APROXIMACION":
		print("TEST FAIL: Aproximacion transition")
		quit(1); return
	for pt in m.waypoints:
		m.step(0.0, pt, "LISTA", false)
	if m.phase != "BOMBARDEO" or m.waypoint_index != 3:
		print("TEST FAIL: Waypoint completion to bombardeo")
		quit(1); return
	m.step(0.0, m.target, "EN_VUELO", false)
	if m.phase != "BOMBARDEO":
		print("TEST FAIL: En vuelo phase retention")
		quit(1); return
	m.step(0.0, m.target, "IMPACTO", false)
	if m.phase != "REGRESO":
		print("TEST FAIL: Regreso transition")
		quit(1); return
	m.step(0.0, m.exit_point, "IMPACTO", false)
	if m.phase != "COMPLETADA":
		print("TEST FAIL: Completada transition")
		quit(1); return
	m.reset()
	if m.phase != "FORMACION" or m.waypoint_index != 0 or m.clock != 0.0:
		print("TEST FAIL: Reset state")
		quit(1); return
	m.phase = "BOMBARDEO"
	m.step(0.0, Vector3.ZERO, "FALLO", false)
	if m.phase != "FALLIDA":
		print("TEST FAIL: Fallo transition")
		quit(1); return
	m.reset()
	m.step(0.0, Vector3.ZERO, "LISTA", true)
	if m.phase != "FALLIDA":
		print("TEST FAIL: Destroyed transition")
		quit(1); return
	print("TEST PASS: Agy mission states")
	quit(0)
