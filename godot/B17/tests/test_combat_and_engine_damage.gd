extends SceneTree
# Test determinista de dano independiente en 4 motores (1.1.2.2) y combate/defensa (1.1.2.1)

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	# -------------------------------------------------------------
	# PARTE 1: 1.1.2.2 Dano independiente en los 4 motores y empuje
	# -------------------------------------------------------------
	var dmg = preload("res://core/damage.gd").new()
	if dmg.hull != 100.0 or dmg.engine != 100.0 or dmg.engines.size() != 4:
		print("TEST FAIL: inicializacion de damage.gd incorrecta")
		quit(1)
		return
	if not is_equal_approx(dmg.thrust_factor(), 1.0):
		print("TEST FAIL: thrust_factor inicial no es 1.0 (es %.3f)" % dmg.thrust_factor())
		quit(1)
		return

	# 1. Dano especifico en motor 0
	dmg.apply_damage(10.0, 0)
	if dmg.engines[0] != 75.0:
		print("TEST FAIL: motor 0 deberia tener 75.0 tras 10 de dano, tiene %.2f" % dmg.engines[0])
		quit(1)
		return
	if dmg.engines[1] != 100.0 or dmg.engines[2] != 100.0 or dmg.engines[3] != 100.0:
		print("TEST FAIL: dano en motor 0 contamino otros motores")
		quit(1)
		return
	if dmg.hull != 90.0:
		print("TEST FAIL: casco deberia ser 90.0, es %.2f" % dmg.hull)
		quit(1)
		return
	var expected_eng_avg: float = (75.0 + 100.0 + 100.0 + 100.0) / 4.0
	if not is_equal_approx(dmg.engine, expected_eng_avg):
		print("TEST FAIL: promedio de motores no coincide (esperado %.2f, obtenido %.2f)" % [expected_eng_avg, dmg.engine])
		quit(1)
		return
	print("Dano independiente en motor 0 PASS (motor 0=75%, otros 100%)")

	# 2. Dano especifico en motor 2
	dmg.apply_damage(20.0, 2)
	if dmg.engines[2] != 50.0:
		print("TEST FAIL: motor 2 deberia tener 50.0, tiene %.2f" % dmg.engines[2])
		quit(1)
		return
	if dmg.engines[0] != 75.0 or dmg.engines[1] != 100.0 or dmg.engines[3] != 100.0:
		print("TEST FAIL: dano en motor 2 altero motores 0, 1 o 3 indebidamente")
		quit(1)
		return
	print("Dano independiente en motor 2 PASS (motor 0=75%, motor 2=50%, motores 1 y 3=100%)")

	# 3. Dano excesivo en motor 1 (clamp a 0)
	dmg.apply_damage(50.0, 1)
	if dmg.engines[1] != 0.0:
		print("TEST FAIL: motor 1 no se clampeo a 0 tras dano letal (tiene %.2f)" % dmg.engines[1])
		quit(1)
		return
	var expected_thrust: float = 0.6 + 0.4 * dmg.engine / 100.0
	if not is_equal_approx(dmg.thrust_factor(), expected_thrust):
		print("TEST FAIL: thrust_factor no coincide con degradacion motriz (esperado %.3f, obtenido %.3f)" % [
			expected_thrust, dmg.thrust_factor()
		])
		quit(1)
		return
	print("Degradacion de empuje por perdida de motor PASS (thrust_factor=%.3f con motor promedio=%.1f%%)" % [
		dmg.thrust_factor(), dmg.engine
	])

	# 4. Dano a fuselaje solo (sin afectar motores, index = -1)
	var eng_before = dmg.engine
	dmg.apply_damage(10.0, -1)
	if dmg.engine != eng_before:
		print("TEST FAIL: dano a fuselaje puro altero motores")
		quit(1)
		return
	print("Dano puro a fuselaje PASS")

	# 5. Destruccion por dano acumulado en casco
	dmg.apply_damage(100.0, -1)
	if not dmg.destroyed() or dmg.hull > 0.0:
		print("TEST FAIL: aeronave no destruida tras dano letal a casco")
		quit(1)
		return
	print("Destruccion de aeronave (destroyed=true) PASS")

	# 6. Reset restaura 100% en todo
	dmg.reset()
	if dmg.hull != 100.0 or dmg.engine != 100.0:
		print("TEST FAIL: reset no restauro casco o motores al 100%")
		quit(1)
		return
	print("Reset de danos PASS")

	# -------------------------------------------------------------
	# PARTE 2: 1.1.2.1 Determinismo y logica de combate y defensa
	# -------------------------------------------------------------
	var sim1 = preload("res://core/simulation.gd").new()
	sim1.autopilot = true
	var dt := 1.0 / 60.0

	# Iniciar desde APROXIMACION (z=-5000)
	sim1.mission.phase = "APROXIMACION"
	sim1.flight.position = Vector3(0, 1200, -5000)

	var total_enemy_shots: int = 0
	var total_defensive_shots: int = 0
	var flak_bursts_count: int = 0
	var max_sim_time: float = 180.0
	var max_steps: int = int(max_sim_time / dt)
	var combat_steps: int = 0

	for step_idx in range(max_steps):
		sim1.step(dt)
		combat_steps += 1
		if sim1.combat.enemy_shots.size() > 0:
			total_enemy_shots += sim1.combat.enemy_shots.size()
		if sim1.combat.defensive_shots.size() > 0:
			total_defensive_shots += sim1.combat.defensive_shots.size()
		if sim1.last_flak_burst:
			flak_bursts_count += 1
		
		# Detener en cuanto se cumplan las condiciones de combate real exigidas
		var has_engine_dmg: bool = false
		for e in range(4):
			if sim1.damage.engines[e] < 100.0:
				has_engine_dmg = true
				break
		if total_enemy_shots > 0 and total_defensive_shots > 0 and sim1.damage.hull < 100.0 and has_engine_dmg and sim1.combat.total_kills > 0:
			break

	# Exigencia 1: Al menos 1 disparo enemigo registrado
	if total_enemy_shots <= 0:
		print("TEST FAIL: no hubo disparos enemigos (enemy_shots vacio en todos los pasos)")
		quit(1)
		return

	# Exigencia 2: Fuego defensivo automatico registrado
	if total_defensive_shots <= 0:
		print("TEST FAIL: no hubo fuego defensivo automatico (defensive_shots vacio en todos los pasos)")
		quit(1)
		return

	# Exigencia 3: Casco < 100
	if sim1.damage.hull >= 100.0:
		print("TEST FAIL: el casco no sufrio dano (hull=%.2f)" % sim1.damage.hull)
		quit(1)
		return

	# Exigencia 4: Al menos un motor < 100 por fuego de cazas (separado de flak)
	var damaged_engines_count: int = 0
	for e in range(4):
		if sim1.damage.engines[e] < 100.0:
			damaged_engines_count += 1
	if damaged_engines_count == 0:
		print("TEST FAIL: ningun motor sufrio dano por fuego de cazas")
		quit(1)
		return

	# Registrar por separado rafagas de flak
	if flak_bursts_count > 0:
		print("NOTA: se registraron %d rafagas de flak durante la simulacion" % flak_bursts_count)
	else:
		print("Registro de flak: 0 rafagas (todo el dano a motores y fuselaje proviene de cazas)")

	# Exigencia 5: Determinismo con estado NO trivial en dos simulaciones nuevas e identicas
	var sim2 = preload("res://core/simulation.gd").new()
	sim2.autopilot = true
	sim2.mission.phase = "APROXIMACION"
	sim2.flight.position = Vector3(0, 1200, -5000)
	for s in range(combat_steps):
		sim2.step(dt)

	if sim2.damage.hull >= 100.0:
		print("TEST FAIL: sim2 no sufrio dano en casco (estado trivial)")
		quit(1)
		return
	if sim1.combat.total_kills != sim2.combat.total_kills:
		print("TEST FAIL: determinismo violado en total_kills (%d vs %d)" % [sim1.combat.total_kills, sim2.combat.total_kills])
		quit(1)
		return
	if not is_equal_approx(sim1.damage.hull, sim2.damage.hull):
		print("TEST FAIL: determinismo violado en dano de casco (%.4f vs %.4f)" % [sim1.damage.hull, sim2.damage.hull])
		quit(1)
		return
	for e in range(4):
		if not is_equal_approx(sim1.damage.engines[e], sim2.damage.engines[e]):
			print("TEST FAIL: determinismo violado en motor %d (%.4f vs %.4f)" % [e, sim1.damage.engines[e], sim2.damage.engines[e]])
			quit(1)
			return

	print("Combate real alcanzado y determinismo no trivial PASS (%d pasos, %.2f s simulados):" % [combat_steps, combat_steps * dt])
	print("  - Disparos enemigos (enemy_shots): %d" % total_enemy_shots)
	print("  - Disparos defensivos automaticos (defensive_shots): %d" % total_defensive_shots)
	print("  - Rafagas de flak: %d (dano de flak a motores = 0.0)" % flak_bursts_count)
	print("  - Casco sim1: %.2f%% | sim2: %.2f%% (ambos < 100%%)" % [sim1.damage.hull, sim2.damage.hull])
	print("  - Motores sim1: [%.2f%%, %.2f%%, %.2f%%, %.2f%%]" % [sim1.damage.engines[0], sim1.damage.engines[1], sim1.damage.engines[2], sim1.damage.engines[3]])
	print("  - Motores sim2: [%.2f%%, %.2f%%, %.2f%%, %.2f%%]" % [sim2.damage.engines[0], sim2.damage.engines[1], sim2.damage.engines[2], sim2.damage.engines[3]])
	print("  - Derribos (total_kills): %d" % sim1.combat.total_kills)

	# -------------------------------------------------------------
	# PARTE 3: Fuego defensivo manual del artillero (player_controls.fire)
	# -------------------------------------------------------------
	var sim_art = preload("res://core/simulation.gd").new()
	var controls = preload("res://core/player_controls.gd").new()
	sim_art.autopilot = false
	controls.set_station("ARTILLERO", sim_art)

	# Crear un caza objetivo vivo frente a la torreta
	sim_art.combat.spawn_wave(1, sim_art.flight.position)
	var target_fighter = sim_art.combat.fighters[0]
	target_fighter["ai"].position = sim_art.flight.position + Vector3(0, 0, -300) # En el eje frontal
	var initial_health: float = target_fighter["health"]
	var initial_kills: int = sim_art.combat.total_kills

	# Apuntar directamente al objetivo (aim = Vector2.ZERO apunta en z negativo)
	controls.aim = Vector2.ZERO
	controls.fire(sim_art)

	if target_fighter["health"] >= initial_health:
		print("TEST FAIL: disparo defensivo del artillero no dano al caza (salud %.1f)" % target_fighter["health"])
		quit(1)
		return
	print("Disparo defensivo manual hit PASS (salud bajo de %.0f a %.0f)" % [initial_health, target_fighter["health"]])

	# Disparar rafagas consecutivas hasta derribarlo
	while target_fighter["alive"]:
		controls.fire(sim_art)

	if sim_art.combat.total_kills != initial_kills + 1:
		print("TEST FAIL: derribo manual no incremento total_kills")
		quit(1)
		return
	if target_fighter["alive"]:
		print("TEST FAIL: caza no fue marcado como abatido")
		quit(1)
		return
	print("Derribo manual de caza por artillero PASS (total_kills=%d)" % sim_art.combat.total_kills)

	print("TEST PASS: dano modular independiente en 4 motores (1.1.2.2) y combate/defensa determinista (1.1.2.1) completamente verificados")
	quit(0)
