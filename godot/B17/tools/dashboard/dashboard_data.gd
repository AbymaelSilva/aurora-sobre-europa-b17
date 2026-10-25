extends RefCounted
class_name DashboardData

static func parse_supervisor(text: String) -> Array[Dictionary]:
  var result: Array[Dictionary] = []
  for raw in text.split("\n"):
    var line: String = raw.strip_edges()
    if not (line.contains("[SUPERVISOR]") and line.begins_with("[") and line.get_slice_count("[") >= 4):
      continue
    var time: String = line.substr(1, 19)
    var tag: String = line.get_slice("[", 3).get_slice("]", 0)
    var after: String = line.get_slice("[", 3).get_slice("]", 1).strip_edges()
    var status: String = after.get_slice(" ", 0).strip_edges()
    var detail: String = ""
    if line.get_slice_count("|") >= 2:
      detail = line.get_slice("|", 1).strip_edges().left(110)
    result.append({"time": time, "tag": tag, "status": status, "detail": detail})
  return result

static func classify(status: String) -> String:
  if status.begins_with("COMPLETADO") or status.begins_with("ENTREGADO_ACEPTADO"):
    return "ok"
  if status.contains("DEVUELTO") or status.contains("BLOQUEO") or status.contains("RECHAZADO"):
    return "warn"
  return "info"

static func parse_board(text: String) -> Dictionary:
  var rows: Array[Dictionary] = []
  var done: int = 0
  for raw in text.split("\n"):
    var line: String = raw.strip_edges()
    if not line.begins_with("| 1."):
      continue
    var parts: PackedStringArray = line.split("|")
    if parts.size() < 8:
      continue
    var cells: Array[String] = []
    for i in range(1, parts.size() - 1):
      cells.append(parts[i].strip_edges())
    var last: String = cells[cells.size() - 1]
    if last.contains("COMPLETADO") or last.contains("PASS"):
      done += 1
    rows.append({"id": cells[0], "item": cells[1], "owner": cells[2], "state": last.left(60)})
  return {"total": rows.size(), "done": done, "rows": rows}

static func parse_bridge(text: String, limit: int) -> Array[Dictionary]:
  var all: Array[Dictionary] = []
  for raw in text.split("\n"):
    var line: String = raw.strip_edges()
    if not (line.contains("[QWEN_BRIDGE]") and line.get_slice_count("[") >= 5):
      continue
    all.append({"time": line.substr(1, 19), "path": line.get_slice("[", 3).get_slice("]", 0), "status": line.get_slice("[", 4).get_slice("]", 0)})
  if all.size() > limit:
    return all.slice(all.size() - limit, all.size())
  return all

static func tail_lines(text: String, n: int) -> PackedStringArray:
  var out: PackedStringArray = []
  for raw in text.split("\n"):
    var s: String = raw.strip_edges()
    if s != "":
      out.append(s)
  if out.size() > n:
    return out.slice(out.size() - n, out.size())
  return out

static func progress_bar(done: int, total: int, width: int) -> String:
  if total <= 0:
    return "—"
  var filled: int = clampi(int(round(float(done) / float(total) * float(width))), 0, width)
  return "█".repeat(filled) + "░".repeat(width - filled) + " " + str(done) + "/" + str(total)
