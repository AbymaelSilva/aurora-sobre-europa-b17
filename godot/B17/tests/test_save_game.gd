extends SceneTree

const SaveGame = preload("res://core/save_game.gd")
const SAVE_PATH := "user://b17_savegame.json"

var original_existed: bool = false
var original_data: PackedByteArray = []

func fail(message: String) -> void:
	print("TEST FAIL: ", message)
	_restore()
	quit(1)

func _restore() -> void:
	if original_existed:
		var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
		if f != null:
			f.store_buffer(original_data)
			f.close()
	elif FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)

func _initialize() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	original_existed = FileAccess.file_exists(SAVE_PATH)
	if original_existed:
		original_data = FileAccess.get_file_as_bytes(SAVE_PATH)
	SaveGame.clear()

	if SaveGame.has_save():
		fail("has_save() deberia ser falso tras clear()")
		return

	var sim = load("res://core/simulation.gd").new()
	sim.flight.position = Vector3(123.0, 1500.0, -4500.0)
	sim.flight.yaw = 0.42
	sim.damage.hull = 61.0
	sim.damage.engines[1] = 30.0
	sim.damage.engine_feathered[1] = 1
	sim.mission.phase = "APROXIMACION"
	sim.mission.clock = 40.0
	sim.mission.waypoint_index = 1
	sim.autopilot = false

	SaveGame.save_checkpoint(sim)
	if not SaveGame.has_save():
		fail("save_checkpoint no escribio el archivo en fase activa")
		return

	var sim2 = load("res://core/simulation.gd").new()
	if not SaveGame.load_into(sim2):
		fail("load_into devolvio false con un guardado valido")
		return

	if sim2.flight.position.distance_to(Vector3(123.0, 1500.0, -4500.0)) > 0.01:
		fail("posicion no se restauro: %s" % sim2.flight.position)
		return
	if absf(sim2.flight.yaw - 0.42) > 0.001:
		fail("yaw no se restauro")
		return
	if absf(sim2.damage.hull - 61.0) > 0.01:
		fail("hull no se restauro")
		return
	if absf(sim2.damage.engines[1] - 30.0) > 0.01 or sim2.damage.engine_feathered[1] != 1:
		fail("estado de motor no se restauro")
		return
	if sim2.mission.phase != "APROXIMACION" or sim2.mission.waypoint_index != 1:
		fail("fase/waypoint de mision no se restauro")
		return
	if sim2.autopilot:
		fail("autopilot no se restauro")
		return

	# Al completar la mision, el checkpoint debe borrarse (no se ofrece "Continuar").
	sim.mission.phase = "COMPLETADA"
	SaveGame.save_checkpoint(sim)
	if SaveGame.has_save():
		fail("el guardado deberia borrarse al completar la mision")
		return

	_restore()
	print("TEST PASS: guardado y carga de progreso de mision verificados")
	quit(0)
