class_name SaveGame extends RefCounted

const SAVE_PATH: String = "user://b17_savegame.json"
const ACTIVE_PHASES: Array[String] = ["FORMACION", "APROXIMACION", "BOMBARDEO", "REGRESO"]

static var pending_continue: bool = false

static func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

static func save_checkpoint(sim) -> void:
	if sim.mission.phase in ACTIVE_PHASES:
		_write(sim)
	else:
		clear()

static func _write(sim) -> void:
	var data := {
		"flight": {
			"position": [sim.flight.position.x, sim.flight.position.y, sim.flight.position.z],
			"yaw": sim.flight.yaw, "pitch": sim.flight.pitch, "speed": sim.flight.speed,
		},
		"damage": {
			"hull": sim.damage.hull,
			"engines": Array(sim.damage.engines),
			"engine_feathered": Array(sim.damage.engine_feathered),
			"engine_extinguisher_used": Array(sim.damage.engine_extinguisher_used),
		},
		"mission": {
			"phase": sim.mission.phase, "clock": sim.mission.clock,
			"waypoint_index": sim.mission.waypoint_index,
		},
		"bomb_spent": sim.bomb.spent,
		"bomb_result": sim.bomb.result,
		"autopilot": sim.autopilot,
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(data))
		f.close()

static func load_into(sim) -> bool:
	if not has_save():
		return false
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return false
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return false
	sim.reset()
	var fl: Dictionary = parsed.get("flight", {})
	var pos: Array = fl.get("position", [0.0, 1200.0, 0.0])
	sim.flight.position = Vector3(float(pos[0]), float(pos[1]), float(pos[2]))
	sim.flight.yaw = float(fl.get("yaw", 0.0))
	sim.flight.pitch = float(fl.get("pitch", 0.0))
	sim.flight.speed = float(fl.get("speed", 85.0))
	var dmg: Dictionary = parsed.get("damage", {})
	sim.damage.hull = float(dmg.get("hull", 100.0))
	var engines: Array = dmg.get("engines", [100.0, 100.0, 100.0, 100.0])
	var feathered: Array = dmg.get("engine_feathered", [0, 0, 0, 0])
	var ext_used: Array = dmg.get("engine_extinguisher_used", [0, 0, 0, 0])
	for i in range(4):
		sim.damage.engines[i] = float(engines[i]) if i < engines.size() else 100.0
		sim.damage.engine_feathered[i] = int(feathered[i]) if i < feathered.size() else 0
		sim.damage.engine_extinguisher_used[i] = int(ext_used[i]) if i < ext_used.size() else 0
	var mis: Dictionary = parsed.get("mission", {})
	sim.mission.phase = str(mis.get("phase", "FORMACION"))
	sim.mission.clock = float(mis.get("clock", 0.0))
	sim.mission.waypoint_index = int(mis.get("waypoint_index", 0))
	sim.bomb.spent = bool(parsed.get("bomb_spent", false))
	sim.bomb.result = str(parsed.get("bomb_result", "LISTA"))
	sim.autopilot = bool(parsed.get("autopilot", true))
	return true

static func clear() -> void:
	if has_save():
		DirAccess.remove_absolute(SAVE_PATH)
