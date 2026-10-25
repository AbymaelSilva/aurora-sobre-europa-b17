extends SceneTree

func _init() -> void:
	print("--- TEST FLAK INSTRUMENTS ---")
	var Damage = load("res://core/damage.gd")
	var d = Damage.new()

	# Detonación lejana (>80m): ningún impacto en instrumentos
	d.apply_instrument_damage(100.0)
	assert(d.altimeter_error == 0.0, "Detonación lejana no altera altímetro")
	assert(d.compass_drift == 0.0, "Detonación lejana no altera brújula")
	assert(not d.norden_disabled, "Detonación lejana no avería Norden")

	# Detonación muy cercana (<30m) múltiples veces para forzar evento
	d.apply_instrument_damage(20.0)
	assert(d.instrument_damage_timer > 0.0, "Detonación cercana debe activar timer de avería")

	# Limpieza con step_instruments
	d.step_instruments(30.0)
	assert(d.instrument_damage_timer == 0.0, "Timer debe llegar a cero")
	assert(d.altimeter_error == 0.0, "Altímetro restaurado tras expirar timer")
	assert(not d.norden_disabled, "Norden restaurado tras expirar timer")

	# Verificación de simulación: inhibición de suelta automática si Norden averiado
	var Sim = load("res://core/simulation.gd")
	var sim = Sim.new()
	sim.mission.phase = "BOMBARDEO"
	sim.autopilot = true
	sim.flight.position = sim.mission.target + Vector3(0.0, 1200.0, 10.0)
	sim.damage.norden_disabled = true
	sim.step(0.02)
	assert(not sim.bomb.active and not sim.bomb.spent, "Suelta automática debe estar bloqueada si Norden está averiado")

	print("TEST PASS: test_flak_instruments")
	quit(0)
