extends SceneTree

# Verifica que el menu de pausa abre Opciones, que los cambios de ajustes
# llegan a los objetos vivos (controles/simulacion) y que los botones nuevos
# (menu principal, salir) emiten sus señales sin romper la pausa existente.

func fail(message: String) -> void:
	print("TEST FAIL: ", message)
	quit(1)

func _initialize() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	var scene = load("res://game.tscn").instantiate()
	root.add_child(scene)
	await process_frame

	scene.set_pause(true)
	if not scene.settings_menu.visible:
		fail("la pausa no muestra el menu de ajustes")
		return

	scene.settings_menu.options_requested.emit()
	await process_frame
	if scene.options_menu == null or not scene.options_menu.visible:
		fail("Opciones no se abrio desde la pausa")
		return

	scene._on_setting_changed("pitch_sensitivity", 1.75)
	if scene.controls.pitch_sensitivity != 1.75:
		fail("la sensibilidad de cabeceo no llego a los controles vivos")
		return

	scene._on_setting_changed("invert_pitch", true)
	if not scene.controls.invert_pitch:
		fail("invertir cabeceo no llego a los controles vivos")
		return

	scene._on_setting_changed("flight_assist", true)
	if not scene.controls.flight_assist:
		fail("ayuda de vuelo no llego a los controles vivos")
		return

	var base_flak: float = scene.sim.flak_damage
	scene._on_setting_changed("difficulty", "DIFICIL")
	if scene.sim.flak_damage <= base_flak:
		fail("la dificultad DIFICIL no incremento el daño de flak")
		return
	var attackers_dificil: int = scene.sim.combat.max_effective_attackers
	scene._on_setting_changed("difficulty", "FACIL")
	if scene.sim.combat.max_effective_attackers >= attackers_dificil:
		fail("la dificultad FACIL no redujo atacantes efectivos frente a DIFICIL")
		return

	scene._on_setting_changed("reduce_shake", true)
	if scene.sim.instrument_jitter_scale >= 1.0:
		fail("reducir vibracion no bajo el jitter de instrumentos")
		return

	scene._on_setting_changed("colorblind_mode", "DEUTERANOPIA")
	if scene.overlay.colorblind_mode != "DEUTERANOPIA":
		fail("el modo de color no llego al overlay")
		return

	# Cerrar opciones no debe dejar el juego sin pausa ni romper el menu de pausa.
	scene.options_menu.closed.emit()
	await process_frame
	if scene.options_menu.visible:
		fail("Opciones no se cerro correctamente")
		return
	if not scene.sim.paused:
		fail("cerrar Opciones no debe reanudar la mision")
		return

	# El menu de pausa sigue funcionando con normalidad tras usar Opciones.
	scene.settings_menu.resume_requested.emit()
	if scene.sim.paused:
		fail("Reanudar no funciono tras usar Opciones")
		return

	scene.queue_free()
	print("TEST PASS: integracion de Opciones con pausa y controles vivos verificada")
	quit(0)
