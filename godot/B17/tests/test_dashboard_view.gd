extends SceneTree
# Prueba del supervisor (Claude) para tools/dashboard/dashboard_view.gd y la carga de dashboard_main.gd (PROMPT_DASHBOARD_QWEN.md §2.2–2.3).
# El modelo de ejemplo fija el CONTRATO del diccionario que construye dashboard_main.refresh().

func _initialize() -> void:
	run.call_deferred()

static func sample_model() -> Dictionary:
	return {
		"updated": "14:50:03",
		"board": {"total": 20, "done": 15, "rows": [
			{"id": "1.1.1.1", "item": "B17 texturizado", "owner": "Qwen", "state": "COMPLETADO_VERIFICADO"},
			{"id": "1.1.4.4", "item": "Ajustes locales", "owner": "Qwen", "state": "ASIGNADO"}]},
		"agents": [
			{"name": "Agy", "state": "running", "detail": "ronda 1 · read_file", "time": "14:49:58"},
			{"name": "Qwen", "state": "ENTREGADO_PARA_REVISION", "detail": "ui/settings_menu.gd", "time": "14:03:00"},
			{"name": "Claude audio", "state": "WAV 12/47", "detail": "grupo A terminado", "time": "14:48:00"},
			{"name": "Claude Meshy", "state": "candidatos 0/4", "detail": "piloto B-17 descargado", "time": "14:46:14"},
			{"name": "Supervisor", "state": "activo", "detail": "T1 terreno aceptado", "time": "14:45:00"}],
		"completed": [{"time": "2026-10-24T14:39:00", "tag": "LOTE3", "status": "COMPLETADO_VERIFICADO", "detail": "Perfiles de control"}],
		"warnings": [{"time": "2026-10-24T14:20:00", "tag": "LOTE3", "status": "DEVUELTO", "detail": "A/B no activan el menú"}],
		"release": {"candidate_id": "local-20261024-9ab47106d654", "status": "CANDIDATO_LOCAL_VERIFICADO_PENDIENTE_PARTIDA_HUMANA"},
	}

func run() -> void:
	var V = load("res://tools/dashboard/dashboard_view.gd")
	if V == null:
		print("TEST FAIL: no se pudo cargar res://tools/dashboard/dashboard_view.gd")
		quit(1)
		return
	var view: Control = V.new()
	root.add_child(view)
	if not view.has_method("set_model"):
		print("TEST FAIL: dashboard_view sin set_model")
		quit(1)
		return
	view.set_model(sample_model())
	for i in range(3):
		await process_frame
	if not ("model" in view) or view.model.get("updated", "") != "14:50:03":
		print("TEST FAIL: set_model no guardó el modelo")
		quit(1)
		return
	view.set_model({})
	await process_frame
	if FileAccess.file_exists("res://tools/dashboard/dashboard_main.gd") and load("res://tools/dashboard/dashboard_main.gd") == null:
		print("TEST FAIL: dashboard_main.gd no carga")
		quit(1)
		return
	root.remove_child(view)
	view.free()
	print("TEST PASS: dashboard_view acepta el modelo de ejemplo y uno vacío sin errores")
	quit(0)
