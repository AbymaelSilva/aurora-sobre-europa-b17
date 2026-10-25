extends "res://tools/dashboard/dashboard_main.gd"
# Revisión GPU (Claude): ejecuta el dashboard real de Qwen, captura, añade una línea de prueba al supervisor.log y comprueba el refresco.
var out := ""
func _initialize() -> void:
	out = OS.get_cmdline_user_args()[0]
	super._initialize()
	check.call_deferred()
func shot(label: String) -> void:
	for i in range(3):
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("%s/%s.png" % [out, label])
func check() -> void:
	await shot("dashboard_1")
	var before: String = str(view.model.get("updated"))
	var t0: int = Time.get_ticks_msec()
	await create_timer(3.6).timeout
	print("refresco: updated antes=", before, " después=", view.model.get("updated"), " tras ", Time.get_ticks_msec() - t0, " ms · último completado: ", view.model.get("completed", [{}])[0].get("tag", ""))
	await shot("dashboard_2")
	quit()
