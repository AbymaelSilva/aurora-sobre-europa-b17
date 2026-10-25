extends SceneTree

# Prueba de humo: el menu principal carga, construye sus botones y arranca
# con foco en Jugar, sin errores de script.

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var scene := load("res://main_menu.tscn")
	if scene == null:
		print("TEST FAIL: no se pudo cargar main_menu.tscn")
		quit(1)
		return
	var inst: Control = scene.instantiate()
	root.add_child(inst)
	await process_frame
	await process_frame

	if inst.play_button == null or inst.options_button == null or inst.credits_button == null or inst.quit_button == null:
		print("TEST FAIL: faltan botones del menu principal")
		inst.queue_free()
		quit(1)
		return
	if not inst.play_button.has_focus():
		print("TEST FAIL: Jugar no tiene el foco inicial")
		inst.queue_free()
		quit(1)
		return

	inst._open_options()
	await process_frame
	if inst.options_menu == null or not inst.options_menu.visible:
		print("TEST FAIL: Opciones no se abrio desde el menu principal")
		inst.queue_free()
		quit(1)
		return
	inst.options_menu.closed.emit()
	await process_frame
	if inst.options_menu.visible:
		print("TEST FAIL: Opciones no se cerro")
		inst.queue_free()
		quit(1)
		return

	inst._open_credits()
	await process_frame
	if inst.credits_panel == null or not inst.credits_panel.visible:
		print("TEST FAIL: Creditos no se abrio")
		inst.queue_free()
		quit(1)
		return

	inst.queue_free()
	print("TEST PASS: menu principal, opciones y creditos verificados")
	quit(0)
