extends SceneTree

const ROOT := "/home/test-bench/Documents/B17-project/"
const DashboardView = preload("res://tools/dashboard/dashboard_view.gd")
# DashboardData is a GLOBAL class_name: call it directly, never preload it.
var view: Control
var timer: Timer

func _initialize() -> void:
    DisplayServer.window_set_title("B17 — DASHBOARD DE OPERACIONES")
    view = DashboardView.new()
    root.add_child(view)
    timer = Timer.new()
    timer.wait_time = 3.0
    timer.one_shot = false
    root.add_child(timer)
    timer.timeout.connect(refresh)
    timer.autostart = true  # start() falla en _initialize: el Timer aún no está en el árbol (parche del supervisor)
    refresh()

func _process(_delta: float) -> bool:
    if Input.is_key_pressed(KEY_ESCAPE):
        quit()
    return false

func read(rel: String) -> String:
    var p: String = ROOT + rel
    if FileAccess.file_exists(p):
        return FileAccess.get_file_as_string(p)
    return ""

func count_files(rel_dir: String, ext: String) -> int:
    var abs_dir: String = ROOT + rel_dir
    if not DirAccess.dir_exists_absolute(abs_dir):
        return 0
    var n: int = 0
    for f in DirAccess.get_files_at(abs_dir):
        if String(f).ends_with(ext):
            n += 1
    return n

func last_line(rel: String) -> String:
    var lines: PackedStringArray = DashboardData.tail_lines(read(rel), 1)
    if lines.size() == 0:
        return ""
    return lines[0]

func latest_release() -> Dictionary:
    var base: String = ROOT + "release/"
    if not DirAccess.dir_exists_absolute(base):
        return {}
    var best_path: String = ""
    var best_time: int = -1
    for name in DirAccess.get_directories_at(base):
        var status_path: String = base + String(name) + "/CANDIDATE_STATUS.json"
        if FileAccess.file_exists(status_path):
            var t: int = FileAccess.get_modified_time(status_path)
            if t > best_time:
                best_time = t
                best_path = status_path
    if best_path == "":
        return {}
    var parsed = JSON.parse_string(FileAccess.get_file_as_string(best_path))
    if typeof(parsed) != TYPE_DICTIONARY:
        return {}
    return {"candidate_id": str(parsed.get("candidate_id", "")), "status": str(parsed.get("status", ""))}

func filter_events(events: Array, kind: String, limit: int) -> Array:
    # newest first
    var out: Array = []
    var i: int = events.size() - 1
    while i >= 0 and out.size() < limit:
        if DashboardData.classify(String(events[i]["status"])) == kind:
            out.append(events[i])
        i -= 1
    return out

func agy_agent() -> Dictionary:
    var parsed = JSON.parse_string(read("logs/agy-coordinador/status.json"))
    var agy: Dictionary = parsed if typeof(parsed) == TYPE_DICTIONARY else {}
    return {"name": "Agy", "state": str(agy.get("status", "?")), "detail": "ronda " + str(agy.get("round", "-")) + " · " + str(agy.get("last_tool", agy.get("reason", ""))), "time": str(agy.get("last_activity_utc", agy.get("updated_utc", ""))).right(9)}

func qwen_agent() -> Dictionary:
    var bridge: Array = DashboardData.parse_bridge(read("logs/orquestacion/qwen.log"), 1)
    if bridge.is_empty():
        return {"name": "Qwen", "state": "sin actividad", "detail": "", "time": ""}
    return {"name": "Qwen", "state": String(bridge[0]["status"]), "detail": String(bridge[0]["path"]), "time": String(bridge[0]["time"]).right(8)}

func supervisor_agent(events: Array) -> Dictionary:
    if events.is_empty():
        return {"name": "Supervisor", "state": "activo", "detail": "", "time": ""}
    var last: Dictionary = events[events.size() - 1]
    return {"name": "Supervisor", "state": "activo", "detail": String(last["tag"]) + " " + String(last["status"]), "time": String(last["time"]).right(8)}

func refresh() -> void:
    var events: Array = DashboardData.parse_supervisor(read("logs/orquestacion/supervisor.log"))
    var agents: Array = []
    agents.append(agy_agent())
    agents.append(qwen_agent())
    agents.append({"name": "Claude audio", "state": "WAV %d/47" % count_files("godot/B17/assets/audio/sfx", ".wav"), "detail": last_line("logs/orquestacion/claude_audio.log").left(60), "time": ""})
    agents.append({"name": "Claude Meshy", "state": "candidatos %d/4" % count_files("art/meshy/candidatos", ".glb"), "detail": last_line("logs/orquestacion/claude_meshy.log").left(60), "time": ""})
    agents.append(supervisor_agent(events))
    var model: Dictionary = {"updated": Time.get_time_string_from_system(), "board": DashboardData.parse_board(read("planning/orquestacion/TABLERO.md")), "agents": agents, "completed": filter_events(events, "ok", 12), "warnings": filter_events(events, "warn", 3), "release": latest_release()}
    view.set_model(model)
