extends SceneTree

const InputActions = preload("res://core/input_actions.gd")
const SETTINGS_PATH := "user://b17_settings.cfg"

var original_existed: bool = false
var original_data: PackedByteArray = []

func fail(message: String) -> void:
	print("TEST FAIL: ", message)
	_restore()
	quit(1)

func _restore() -> void:
	InputActions.reset_to_defaults()
	if original_existed:
		var f := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
		if f != null:
			f.store_buffer(original_data)
			f.close()
	elif FileAccess.file_exists(SETTINGS_PATH):
		DirAccess.remove_absolute(SETTINGS_PATH)

func _initialize() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	original_existed = FileAccess.file_exists(SETTINGS_PATH)
	if original_existed:
		original_data = FileAccess.get_file_as_bytes(SETTINGS_PATH)

	InputActions.ensure_defaults()
	if InputActions.key_label("b17_piloto") != "1":
		fail("tecla por defecto de piloto deberia ser 1, es %s" % InputActions.key_label("b17_piloto"))
		return

	# Reasignar artillero a la tecla 9 (libre) debe funcionar sin conflicto.
	var conflict: String = InputActions.rebind("b17_artillero", KEY_9)
	if not conflict.is_empty():
		fail("remapeo a tecla libre reporto conflicto: %s" % conflict)
		return
	if InputActions.key_label("b17_artillero") != "9":
		fail("el remapeo de artillero no se aplico")
		return

	# Intentar asignar bombardero a una tecla ya usada (piloto=1) debe reportar conflicto
	# y NO debe tocar la asignacion de bombardero.
	var conflict2: String = InputActions.rebind("b17_bombardero", KEY_1)
	if conflict2 != "b17_piloto":
		fail("remapeo en conflicto no reporto la accion correcta (obtuvo '%s')" % conflict2)
		return
	if InputActions.key_label("b17_bombardero") == "1":
		fail("el remapeo en conflicto no debio aplicarse")
		return

	# El remapeo debe persistir a traves de un nuevo ensure_defaults() (simulando otra sesion).
	for action in InputActions.REMAPPABLE:
		InputMap.erase_action(action)
	InputActions.ensure_defaults()
	if InputActions.key_label("b17_artillero") != "9":
		fail("el remapeo guardado no persistio tras recargar")
		return

	InputActions.reset_to_defaults()
	if InputActions.key_label("b17_artillero") != "2":
		fail("restaurar valores por defecto no funciono")
		return

	_restore()
	print("TEST PASS: remapeo de teclas, deteccion de conflictos y persistencia verificados")
	quit(0)
