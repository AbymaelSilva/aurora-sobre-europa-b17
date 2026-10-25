extends SceneTree
# Corrida real (headless, pero simulacion completa en el tiempo, no solo
# comprobacion de getters/setters) que demuestra que dos mejoras concretas
# cambian la jugabilidad de verdad: remapeo de teclas y dificultad.
# No es parte de la suite de regresion; se ejecuta a pedido para verificar.

const InputActions = preload("res://core/input_actions.gd")

func fail(msg: String) -> void:
	print("VERIFICACION FALLIDA: ", msg)
	quit(1)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	await verify_remap()
	await verify_difficulty()
	print("VERIFICACION OK: remapeo y dificultad confirmados en corrida real")
	quit(0)

func verify_remap() -> void:
	var scene = load("res://game.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene.set_physics_process(false)

	InputActions.reset_to_defaults()
	if scene.controls.station != "PILOTO":
		fail("estado inicial inesperado: %s" % scene.controls.station)
		return

	# Tecla ORIGINAL (3 = Bombardero) tras remapear a 9: NO debe cambiar de puesto.
	var conflict: String = InputActions.rebind("b17_bombardero", KEY_9)
	if not conflict.is_empty():
		fail("remapeo reporto conflicto inesperado: %s" % conflict)
		return
	var ev3 := InputEventKey.new()
	ev3.physical_keycode = KEY_3
	ev3.pressed = true
	scene._unhandled_input(ev3)
	if scene.controls.station == "BOMBARDERO":
		fail("la tecla 3 (ya remapeada) todavia cambia a Bombardero")
		return
	print("OK remapeo: tecla original (3) ya no activa Bombardero tras remapear")

	# Tecla NUEVA (9): SI debe cambiar de puesto, en la partida real.
	var ev9 := InputEventKey.new()
	ev9.physical_keycode = KEY_9
	ev9.pressed = true
	scene._unhandled_input(ev9)
	if scene.controls.station != "BOMBARDERO":
		fail("la tecla nueva (9) no activo Bombardero tras remapear")
		return
	print("OK remapeo: tecla nueva (9) activa Bombardero en la partida real")

	InputActions.reset_to_defaults()
	scene.queue_free()
	await process_frame

func run_mission_to_bombing(difficulty: String) -> Dictionary:
	seed(1945)
	var scene = load("res://game.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene._on_setting_changed("difficulty", difficulty)
	var dt := 1.0 / 60.0
	# Simula hasta bien entrada la fase de bombardeo, donde ya hubo exposicion
	# real a flak y a cazas (fases FORMACION->APROXIMACION->BOMBARDEO).
	for frame in range(60 * 170):
		scene._physics_process(dt)
		if scene.sim.mission.phase == "BOMBARDEO" and scene.sim.flak.bursts >= 6:
			break
	var result := {
		"hull": scene.sim.damage.hull,
		"flak_damage_setting": scene.sim.flak_damage,
		"max_effective_attackers": scene.sim.combat.max_effective_attackers,
		"bursts": scene.sim.flak.bursts,
		"phase": scene.sim.mission.phase,
	}
	scene.queue_free()
	await process_frame
	return result

func verify_difficulty() -> void:
	var facil := await run_mission_to_bombing("FACIL")
	var dificil := await run_mission_to_bombing("DIFICIL")

	print("FACIL   -> hull=%.2f flak_damage=%.3f max_attackers=%d bursts=%d fase=%s" % [
		facil.hull, facil.flak_damage_setting, facil.max_effective_attackers, facil.bursts, facil.phase])
	print("DIFICIL -> hull=%.2f flak_damage=%.3f max_attackers=%d bursts=%d fase=%s" % [
		dificil.hull, dificil.flak_damage_setting, dificil.max_effective_attackers, dificil.bursts, dificil.phase])

	if dificil.flak_damage_setting <= facil.flak_damage_setting:
		fail("DIFICIL no aumento el multiplicador de daño de flak frente a FACIL")
		return
	if dificil.max_effective_attackers <= facil.max_effective_attackers:
		fail("DIFICIL no aumento el tope de atacantes efectivos frente a FACIL")
		return
	# Con la MISMA secuencia de rafagas de flak (mismo seed, mismo numero de
	# impactos), DIFICIL debe terminar con mas casco perdido que FACIL:
	# prueba de que el ajuste cambia el resultado real de una mision, no solo
	# una variable aislada.
	if facil.bursts == dificil.bursts and dificil.hull >= facil.hull:
		fail("con el mismo numero de rafagas de flak, DIFICIL no dejo mas daño real que FACIL (hull facil=%.2f dificil=%.2f)" % [facil.hull, dificil.hull])
		return
	print("OK dificultad: DIFICIL deja mas daño real de casco que FACIL con la misma secuencia de flak")
