extends SceneTree
# Prueba del supervisor (Claude) para tools/dashboard/dashboard_data.gd, escrita antes que el código (PROMPT_DASHBOARD_QWEN.md §2.1).
var failures := 0

func _initialize() -> void:
	run.call_deferred()

func check(cond: bool, label: String) -> void:
	if not cond:
		failures += 1
		print("TEST FAIL: " + label)

func run() -> void:
	var D = load("res://tools/dashboard/dashboard_data.gd")
	if D == null:
		print("TEST FAIL: no se pudo cargar res://tools/dashboard/dashboard_data.gd")
		quit(1)
		return

	var sup := "[2026-10-24T12:15:39-07:00] [SUPERVISOR] [1.1.2.1] COMPLETADO_VERIFICADO | Combate real en 7.87 s | evidencia=x\n" \
		+ "basura sin formato\n" \
		+ "[2026-10-24T12:20:00-07:00] [SUPERVISOR] [LOTE3] DEVUELTO_CON_5_HALLAZGOS | A/B no activan el menú | evidencia=y\n" \
		+ "[2026-10-24T12:21:00-07:00] [QWEN_BRIDGE] [x.gd] [EN_EJECUCION] evidencia=z\n" \
		+ "[2026-10-24T12:22:00-07:00] [SUPERVISOR] [AGY] RELANZADO | Nueva ronda\n"
	var ev: Array = D.parse_supervisor(sup)
	check(ev.size() == 3, "parse_supervisor: 3 eventos válidos (obtenidos %d)" % ev.size())
	if ev.size() == 3:
		check(ev[0]["time"] == "2026-10-24T12:15:39", "time = 19 caracteres tras '[' (%s)" % ev[0]["time"])
		check(ev[0]["tag"] == "1.1.2.1", "tag (%s)" % ev[0]["tag"])
		check(ev[0]["status"] == "COMPLETADO_VERIFICADO", "status (%s)" % ev[0]["status"])
		check(ev[0]["detail"] == "Combate real en 7.87 s", "detail recortado entre | | (%s)" % ev[0]["detail"])
		check(ev[2]["detail"] == "Nueva ronda", "detail sin segundo | (%s)" % ev[2]["detail"])
	var long_line := "[2026-10-24T12:15:39-07:00] [SUPERVISOR] [X] COMPLETADO | " + "a".repeat(300) + " | evidencia=x"
	var lev: Array = D.parse_supervisor(long_line)
	check(lev.size() == 1 and String(lev[0]["detail"]).length() <= 110, "detail ≤ 110 caracteres")
	check(D.parse_supervisor("").is_empty(), "parse_supervisor vacío")

	check(D.classify("COMPLETADO_VERIFICADO") == "ok", "classify COMPLETADO → ok")
	check(D.classify("ENTREGADO_ACEPTADO_CONDICIONAL") == "ok", "classify ENTREGADO_ACEPTADO → ok")
	check(D.classify("DEVUELTO_CON_5_HALLAZGOS") == "warn", "classify DEVUELTO → warn")
	check(D.classify("BLOQUEO_RUTA_RELATIVA") == "warn", "classify BLOQUEO → warn")
	check(D.classify("RECHAZADO_Y_REVERTIDO") == "warn", "classify RECHAZADO → warn")
	check(D.classify("RELANZADO") == "info", "classify otro → info")

	var board := "# Tablero\n| Punto | Entregable | Dueño | Revisor | Dep | Contrato | Ejecución |\n|---|---|---|---|---|---|---|\n" \
		+ "| 1.1.1.1 | B17 texturizado | Qwen | Codex | Inv | ACEPTADO | COMPLETADO_VERIFICADO |\n" \
		+ "| 1.1.3.1 | Misión manual | Agy | Codex | F1 | ACEPTADO | PASS_SINTÉTICO (724 s); falta partida humana |\n" \
		+ "| 1.1.4.4 | Ajustes locales | Qwen | Agy | 1.1.4.3 | ACEPTADO | ASIGNADO |\n| 1.1.5 | corta |\n"
	var b: Dictionary = D.parse_board(board)
	check(int(b.get("total", -1)) == 3, "parse_board total 3 (%s)" % str(b.get("total")))
	check(int(b.get("done", -1)) == 2, "parse_board done 2 (%s)" % str(b.get("done")))
	var rows: Array = b.get("rows", [])
	check(rows.size() == 3 and rows[0]["id"] == "1.1.1.1" and rows[0]["owner"] == "Qwen", "parse_board filas e id/owner")
	check(rows.size() == 3 and String(rows[1]["state"]).length() <= 60, "state ≤ 60 caracteres")
	check(int(D.parse_board("").get("total", -1)) == 0, "parse_board vacío")

	var q := "[2026-10-24T21:03:00Z] [QWEN_BRIDGE] [ui/settings_menu.gd] [ENTREGADO_PARA_REVISION] evidencia=a\n" \
		+ "[2026-10-24T21:04:00Z] [QWEN_BRIDGE] [core/input_profile.gd] [EN_EJECUCION] evidencia=b\n" \
		+ "[2026-10-24T21:05:00Z] [QWEN_BRIDGE] [core/x.gd] [DEVUELTO_TRAS_TRES_INTENTOS] evidencia=c\n"
	var br: Array = D.parse_bridge(q, 2)
	check(br.size() == 2, "parse_bridge limit 2 (%d)" % br.size())
	if br.size() == 2:
		check(br[1]["path"] == "core/x.gd" and br[1]["status"] == "DEVUELTO_TRAS_TRES_INTENTOS", "parse_bridge última línea al final")
		check(br[0]["time"] == "2026-10-24T21:04:00", "parse_bridge time 19 caracteres (%s)" % br[0]["time"])

	var t: PackedStringArray = D.tail_lines("a\n\nb\nc\n\n", 2)
	check(t.size() == 2 and t[0] == "b" and t[1] == "c", "tail_lines ignora vacías")
	check(D.tail_lines("", 3).size() == 0, "tail_lines vacío")

	var pb: String = D.progress_bar(8, 12, 12)
	check(pb.ends_with("8/12") and pb.count("█") == 8 and pb.count("░") == 4, "progress_bar 8/12 ancho 12 (%s)" % pb)
	check(D.progress_bar(0, 0, 10) == "—", "progress_bar total 0")
	check(D.progress_bar(5, 5, 4).count("█") == 4, "progress_bar completo")

	if failures == 0:
		print("TEST PASS: dashboard_data (parse_supervisor, classify, parse_board, parse_bridge, tail_lines, progress_bar)")
	quit(1 if failures > 0 else 0)
