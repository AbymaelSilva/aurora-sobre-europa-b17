extends Control
# Vista del dashboard. Autoría: Claude (supervisor), tras 3 rondas de Qwen con la maqueta incorrecta
# (logs/agy-qwen/*dashboard_view*). Datos y proceso vivo: dashboard_data.gd y dashboard_main.gd (Qwen).

const BG := Color(0.07, 0.08, 0.10)
const PANEL := Color(0.12, 0.13, 0.16)
const GOLD := Color(0.95, 0.78, 0.35)
const OK := Color(0.35, 0.85, 0.45)
const WARN := Color(0.95, 0.40, 0.35)
const AMBER := Color(0.95, 0.70, 0.25)
const TEXT := Color(0.85, 0.86, 0.88)
const MUTED := Color(0.55, 0.57, 0.60)
const TOP := 96.0

var model: Dictionary = {}

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func set_model(m: Dictionary) -> void:
	model = m
	queue_redraw()

func _text(pos: Vector2, s: String, font_size: int, color: Color, width: float) -> void:
	draw_string(ThemeDB.fallback_font, pos, s, HORIZONTAL_ALIGNMENT_LEFT, width, font_size, color)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), BG)
	_draw_header()
	_draw_agents(24.0, 380.0)
	_draw_completed(424.0, 430.0)
	_draw_board(874.0, size.x - 898.0)
	_draw_footer(size.y - 112.0)

func _draw_header() -> void:
	var board: Dictionary = model.get("board", {})
	_text(Vector2(24, 40), "B17 · CENTRO DE OPERACIONES", 22, GOLD, 700)
	draw_string(ThemeDB.fallback_font, Vector2(size.x - 300, 40), "Actualizado " + str(model.get("updated", "—")), HORIZONTAL_ALIGNMENT_RIGHT, 276, 13, MUTED)
	_text(Vector2(24, 70), "Tablero V1   " + DashboardData.progress_bar(int(board.get("done", 0)), int(board.get("total", 0)), 30), 15, TEXT, size.x - 48)

func _draw_agents(x: float, w: float) -> void:
	_text(Vector2(x, TOP), "AGENTES", 15, GOLD, w)
	var row_y: float = TOP + 14.0
	var shown: int = 0
	for agent in model.get("agents", []):
		if shown >= 5:
			break
		var state: String = str(agent.get("state", ""))
		var good: bool = state.contains("running") or state.contains("activo") or state.contains("ENTREGADO") or state.contains("COMPLETADO") or state.contains("47/47") or state.contains("4/4")
		var bad: bool = state.contains("blocked") or state.contains("DEVUELTO") or state.contains("BLOQUEADO")
		draw_rect(Rect2(x - 8, row_y, w + 12, 72), PANEL)
		_text(Vector2(x, row_y + 22), str(agent.get("name", "")), 15, Color.WHITE, w - 90)
		_text(Vector2(x + w - 84, row_y + 22), str(agent.get("time", "")), 12, MUTED, 84)
		_text(Vector2(x, row_y + 42), state, 13, OK if good else (WARN if bad else TEXT), w)
		_text(Vector2(x, row_y + 61), str(agent.get("detail", "")), 12, MUTED, w)
		row_y += 78.0
		shown += 1

func _draw_completed(x: float, w: float) -> void:
	_text(Vector2(x, TOP), "COMPLETADO (más reciente primero)", 15, GOLD, w)
	var row_y: float = TOP + 28.0
	var limit_y: float = size.y - 130.0
	for ev in model.get("completed", []):
		if row_y > limit_y:
			break
		var t: String = str(ev.get("time", ""))
		_text(Vector2(x, row_y), t.right(8) + "  " + str(ev.get("tag", "")), 13, OK, w)
		_text(Vector2(x, row_y + 18), str(ev.get("detail", "")), 12, TEXT, w)
		row_y += 40.0

func _draw_board(x: float, w: float) -> void:
	_text(Vector2(x, TOP), "TABLERO V1", 15, GOLD, w)
	var row_y: float = TOP + 26.0
	var limit_y: float = size.y - 130.0
	for row in model.get("board", {}).get("rows", []):
		if row_y > limit_y:
			break
		var state: String = str(row.get("state", ""))
		var done: bool = state.contains("COMPLETADO") or state.contains("PASS")
		draw_circle(Vector2(x + 5, row_y - 4), 5.0, OK if done else AMBER)
		_text(Vector2(x + 16, row_y), str(row.get("id", "")) + "  " + str(row.get("item", "")), 12, TEXT, w - 16)
		row_y += 22.0

func _draw_footer(y: float) -> void:
	draw_rect(Rect2(16, y - 6, size.x - 32, 100), PANEL)
	_text(Vector2(24, y + 16), "INCIDENCIAS RECIENTES", 15, WARN, size.x * 0.5)
	var line_y: float = y + 38.0
	var shown: int = 0
	for ev in model.get("warnings", []):
		if shown >= 3:
			break
		_text(Vector2(24, line_y), str(ev.get("tag", "")) + ": " + str(ev.get("detail", "")), 12, TEXT, size.x * 0.5 - 40)
		line_y += 18.0
		shown += 1
	var release: Dictionary = model.get("release", {})
	_text(Vector2(size.x * 0.5, y + 16), "PAQUETE ACTUAL", 15, GOLD, size.x * 0.5 - 32)
	_text(Vector2(size.x * 0.5, y + 38), str(release.get("candidate_id", "—")), 13, TEXT, size.x * 0.5 - 32)
	_text(Vector2(size.x * 0.5, y + 56), str(release.get("status", "")), 12, MUTED, size.x * 0.5 - 32)
