extends SceneTree
# Sonda H-11 (Claude): game.tscn como escena actual, como el lanzador real. Modos:
#   inmediato : 600 frames y quit() directo (equivale a --quit-after / cerrar ventana hoy)
#   parar     : 600 frames, stop() de los 4 AudioStreamPlayer, esperar 0,25 s y quit() (corrección propuesta)
var mode := "inmediato"
var frames := 0
var done := false

func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0:
		mode = a[0]
	change_scene_to_file("res://game.tscn")

func _process(_d: float) -> bool:
	frames += 1
	if frames == 600 and not done:
		done = true
		finish.call_deferred()
	return false

func finish() -> void:
	if mode == "parar":
		var g = current_scene
		for p in [g.engine_audio, g.gun_audio, g.flak_audio, g.bomb_audio]:
			p.stop()
		await create_timer(0.25).timeout
	quit(0)
