extends SceneTree

func check(ok: bool, msg: String) -> bool:
	if not ok:
		push_error("TEST FAIL: " + msg)
		quit(1)
	return ok

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var sim = load("res://core/simulation.gd").new()
	var director = load("res://audio/scene_audio_director.gd").new()
	root.add_child(director)
	if not check(director.catalog.size() == 28, "Catálogo de 28 líneas incompleto"): return
	if not check(director.music_catalog.size() == 7, "Faltan cues musicales"): return
	for id in director.catalog:
		var entry: Dictionary = director.catalog[id]
		if not check(entry.get("spoken_language", "") == "en-US" and entry.get("subtitle_language", "") == "es", "Idioma de voz/subtítulo incorrecto: " + str(id)): return
		if not check(not str(entry.get("spoken_text", "")).is_empty(), "Falta parlamento inglés: " + str(id)): return
		var audio := load(director.VOICE_DIR + str(entry.file)) as AudioStreamWAV
		if not check(audio != null and audio.mix_rate == 44100 and audio.get_length() > 1.0, "Voz inválida: " + str(id)): return
	director.update_scene(0.1, sim)
	if not check(director.current_id == "formation_lead", "Falta conversación inicial"): return
	if not check(director.subtitle.contains(director.catalog[director.current_id].text), "Subtítulo distinto de voz"): return
	if not check(director.current_music == "formation", "Falta música inicial"): return
	var count: int = director.voice_start_count
	for i in range(30): director.update_scene(0.0, sim)
	if not check(director.voice_start_count == count, "Repite voz cada fotograma"): return
	sim.paused = true
	var subtitle: String = director.subtitle
	var gap: float = director.gap
	director.update_scene(3.0, sim)
	if not check(director.voice_player.stream_paused and director.subtitle == subtitle and director.gap == gap, "Pausa no conserva reproducción/subtítulo"): return
	sim.paused = false
	director.update_scene(0.0, sim)
	if not check(not director.voice_player.stream_paused, "No reanuda voz"): return
	sim.damage.hull = 50
	director.update_scene(0.2, sim)
	if not check(director.current_id == "damage_hull", "Daño no prioriza conversación urgente"): return
	if not check(director.pending.size() <= 8, "Cola no acotada"): return
	sim.mission.phase = "FALLIDA"
	sim.bomb.result = "FALLO"
	director.update_scene(0.2, sim)
	if not check(director.current_id == "miss_bombardier", "Fallo de objetivo anuncia emergencia incorrecta"): return
	if not check(director.current_music == "failed", "No cambia música de desenlace"): return
	director.voice_player.stop()
	director._voice_finished()
	if not check(director.subtitle.is_empty(), "Subtítulo persiste tras voz"): return
	director.reset()
	sim.reset()
	director.update_scene(0.1, sim)
	if not check(director.current_id == "formation_lead" and director.used.size() == 3, "Reinicio no limpia diálogo"): return
	director.queue_free()
	await process_frame
	var scene = load("res://game.tscn").instantiate()
	root.add_child(scene)
	scene.set_physics_process(false)
	if not check(scene.radio.message == scene.scene_audio.subtitle and not scene.radio.message.is_empty(), "Subtítulos no conectados al juego"): return
	if not check(scene.gun_audio.bus == scene.scene_audio.EFFECTS_BUS, "Efectos no conectados a mezcla"): return
	scene.set_pause(true)
	scene.settings_menu.music_button.pressed.emit()
	scene.settings_menu.voice_button.pressed.emit()
	if not check(not scene.scene_audio.music_enabled and not scene.scene_audio.voice_enabled, "Menú no silencia música/voces"): return
	scene.set_pause(false)
	if not check(not scene.scene_audio.subtitle.is_empty(), "Silenciar voces elimina subtítulos"): return
	var lines: PackedStringArray = scene.overlay.subtitle_lines("Bombardero: Impactos confirmados sobre el objetivo ferroviario.")
	if not check(lines.size() <= 2, "Subtítulo no cabe en dos líneas"): return
	if "--capture" in OS.get_cmdline_user_args():
		scene.orbit_camera.set_exterior(true, scene.sim)
		scene.update_presentation(0.2)
		for i in range(12):
			await process_frame
			await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://../../logs/dialogue_music/subtitles_camera.png")
	scene.queue_free()
	await process_frame
	print("TEST PASS: voces, guion/subtítulos, no repetición, prioridad, música, pausa y reinicio")
	quit(0)
