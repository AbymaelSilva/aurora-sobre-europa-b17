extends SceneTree

const Hints = preload("res://core/gameplay_hints.gd")

class Target:
	extends RefCounted
	var position := Vector3.ZERO
	func _init(at: Vector3) -> void:
		position = at

func check(ok: bool, message: String) -> bool:
	if not ok:
		push_error("TEST FAIL: " + message)
		quit(1)
	return ok

func _initialize() -> void:
	for yaw in [0.0, PI / 2.0, -PI / 2.0, PI]:
		for entry in [[Vector3(0, 0, -500), 12], [Vector3(500, 0, 0), 3], [Vector3(0, 0, 500), 6], [Vector3(-500, 0, 0), 9]]:
			var at: Vector3 = entry[0].rotated(Vector3.UP, yaw)
			var actual: Dictionary = Hints.nearest_threat([{"ai": Target.new(at), "alive": true, "health": 60.0}], Vector3.ZERO, yaw)
			if not check(actual.clock == entry[1], "Reloj incorrecto al girar el jugador"): return
	for pair in [[100.0, "ALTO"], [-100.0, "BAJO"], [30.0, "A NIVEL"]]:
		var result: Dictionary = Hints.nearest_threat([{"ai": Target.new(Vector3(0, pair[0], -500)), "alive": true}], Vector3.ZERO, 0)
		if not check(result.height == pair[1], "Altura relativa incorrecta"): return
	if not check(not Hints.nearest_threat([], Vector3.ZERO, 0).active, "Contacto inventado sin enemigos"): return
	if not check(not Hints.nearest_threat([{"ai": Target.new(Vector3(0,0,-2000)), "alive": true}], Vector3.ZERO, 0).active, "Contacto demasiado lejano"): return
	if not check(not Hints.nearest_threat([{"ai": Target.new(Vector3(0,0,-500)), "alive": false}], Vector3.ZERO, 0).active, "Avisa de caza destruido"): return
	var objective: String = Hints.immediate_objective("BOMBARDEO", "BOMBARDERO", false, false, false, true)
	if not check(objective.contains("ahora"), "Falta orden útil en ventana de suelta"): return
	objective = Hints.immediate_objective("BOMBARDEO", "BOMBARDERO", false, true, true, true)
	if not check(not objective.contains("Suelta las bombas"), "Pide soltar una carga gastada"): return
	if not check(Hints.immediate_objective("FORMACION", "PILOTO", true, false, false, false).contains("puesto"), "Falta acción útil en autopiloto"): return
	print("TEST PASS: reloj de amenazas, altura, filtros y objetivos por fase/puesto")
	quit(0)
