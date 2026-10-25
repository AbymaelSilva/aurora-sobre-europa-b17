# tests/test_flak_field.gd
extends SceneTree

const FlakField = preload("res://visuals/flak_field.gd")

func _init() -> void:
	print("--- TEST FLAK FIELD ---")
	test_pool_bounded()
	test_density_stabilization()
	test_pause_and_reset()
	test_outside_zone_fadeout()
	test_audio_throttling()
	print("ALL FLAK FIELD TESTS PASSED!")
	quit(0)

func test_pool_bounded() -> void:
	var field = FlakField.new()
	root.add_child(field)
	assert(field.pool.size() == 128, "Pool debe tener exactamente 128 bocanadas")
	assert(field.audio_players.size() == 4, "Debe tener 4 voces de audio")
	field.queue_free()
	print("  [PASS] test_pool_bounded")

func test_density_stabilization() -> void:
	var field = FlakField.new()
	root.add_child(field)
	
	# Simular 10 segundos a 60 fps en zona antiaérea
	var dt: float = 1.0 / 60.0
	for f in range(600):
		field.step(dt, true, Vector3.ZERO, 0.0, null, false)
	
	var active = field.active_burst_count()
	print("  Active bursts after 10s: %d" % active)
	assert(active >= 60 and active <= 100, "Densidad tras 10s debe estar entre 60 y 100 (obtenido: %d)" % active)
	
	# Simular 10 segundos más (20s en total) para comprobar que no desborda el tope
	for f in range(600):
		field.step(dt, true, Vector3.ZERO, 0.0, null, false)
	
	var active2 = field.active_burst_count()
	print("  Active bursts after 20s: %d" % active2)
	assert(active2 <= 128, "Bocanadas activas nunca deben superar el pool de 128")
	assert(active2 >= 60, "Densidad debe mantenerse estable")
	
	field.queue_free()
	print("  [PASS] test_density_stabilization")

func test_pause_and_reset() -> void:
	var field = FlakField.new()
	root.add_child(field)
	
	var dt: float = 1.0 / 60.0
	for f in range(300): # 5s
		field.step(dt, true, Vector3.ZERO, 0.0, null, false)
	
	var count_before = field.active_burst_count()
	assert(count_before > 0, "Debe haber bocanadas activas")
	
	# Simular 60 fotogramas en pausa (frozen = true)
	for f in range(60):
		field.step(dt, true, Vector3.ZERO, 0.0, null, true)
	
	assert(field.active_burst_count() == count_before, "En pausa el recuento debe congelarse")
	
	# Reset
	field.reset()
	assert(field.active_burst_count() == 0, "Reset debe limpiar todas las bocanadas activas")
	assert(field.emit_timer == 0.0, "Reset debe reiniciar el temporizador")
	
	field.queue_free()
	print("  [PASS] test_pause_and_reset")

func test_outside_zone_fadeout() -> void:
	var field = FlakField.new()
	root.add_child(field)
	
	var dt: float = 1.0 / 60.0
	for f in range(300): # 5s
		field.step(dt, true, Vector3.ZERO, 0.0, null, false)
	
	var count_start = field.active_burst_count()
	assert(count_start > 0, "Debe haber bocanadas antes de salir de zona")
	
	# Simular 15 segundos fuera de zona (in_zone = false)
	for f in range(900):
		field.step(dt, false, Vector3.ZERO, 0.0, null, false)
	
	var count_end = field.active_burst_count()
	assert(count_end == 0, "Tras 15s fuera de zona todas las bocanadas deben haberse desvanecido (obtenido: %d)" % count_end)
	
	field.queue_free()
	print("  [PASS] test_outside_zone_fadeout")

func test_audio_throttling() -> void:
	var field = FlakField.new()
	root.add_child(field)
	
	var dt: float = 1.0 / 60.0
	# Simular 3 segundos
	for f in range(180):
		field.step(dt, true, Vector3.ZERO, 0.0, null, false)
	
	# En 3 segundos, a ~0.20-0.35s de cooldown, no puede haber más de ~15 llamadas de audio
	print("  Audio triggers in 3s: %d" % field.audio_play_count)
	assert(field.audio_play_count <= 15, "El audio debe estar limitado por cooldown (obtenido: %d)" % field.audio_play_count)
	assert(field.audio_players.size() == 4, "Máximo 4 voces de audio simultáneas")
	
	field.queue_free()
	print("  [PASS] test_audio_throttling")
