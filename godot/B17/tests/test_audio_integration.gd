extends SceneTree

# Test para Tarea C (Lote 5): integración de audio en game.gd

func _initialize() -> void:
	call_deferred("run_checks")

func fail(msg: String) -> void:
	print("TEST FAIL: ", msg)
	quit(1)

func run_checks() -> void:
	var scene = load("res://game.tscn").instantiate()
	root.add_child(scene)
	scene.set_physics_process(false)

	# 1. Comprobación inicial de motor en PILOTO
	scene.update_presentation(0.016)
	if scene.engine_audio == null or scene.engine_audio.stream == null:
		fail("engine_audio no tiene stream inicial")
		return
	var ext_wav = scene.engine_audio.stream as AudioStreamWAV
	if ext_wav == null:
		fail("engine_audio stream inicial no es AudioStreamWAV")
		return
	if ext_wav.loop_mode != AudioStreamWAV.LOOP_FORWARD:
		fail("engine_audio inicial no tiene loop_mode LOOP_FORWARD (es %d)" % ext_wav.loop_mode)
		return
	if ext_wav.loop_end <= 0:
		fail("engine_audio inicial loop_end no es > 0")
		return
	if not ext_wav.resource_path.ends_with("engine_b17_ext_loop.wav") and ext_wav.resource_name != "engine_b17_ext_loop":
		fail("engine_audio inicial en PILOTO no usa engine_b17_ext_loop.wav (%s / %s)" % [ext_wav.resource_path, ext_wav.resource_name])
		return
	print("1. Motor inicial en PILOTO con bucle verificado (engine_b17_ext_loop)")

	# 2. Al cambiar a BOMBARDERO cambia al int_loop
	scene.controls.set_station("BOMBARDERO", scene.sim)
	scene.update_presentation(0.016)
	if scene.engine_audio.stream == null:
		fail("engine_audio no tiene stream en BOMBARDERO")
		return
	var int_wav = scene.engine_audio.stream as AudioStreamWAV
	if int_wav == null:
		fail("engine_audio stream en BOMBARDERO no es AudioStreamWAV")
		return
	if int_wav.loop_mode != AudioStreamWAV.LOOP_FORWARD:
		fail("engine_audio en BOMBARDERO no tiene loop_mode LOOP_FORWARD")
		return
	if not int_wav.resource_path.ends_with("engine_b17_int_loop.wav") and int_wav.resource_name != "engine_b17_int_loop":
		fail("engine_audio en BOMBARDERO no usa engine_b17_int_loop.wav (%s / %s)" % [int_wav.resource_path, int_wav.resource_name])
		return
	print("2. Cambio de puesto a BOMBARDERO usa engine_b17_int_loop con bucle")

	# 3. Soltar la bomba reproduce bomb_release
	scene.sim.mission.phase = "BOMBARDEO"
	scene.sim.bomb.reset()
	var release_ok = scene.sim.release_bomb()
	if not release_ok:
		fail("No se pudo soltar la bomba en fase BOMBARDEO")
		return
	scene.update_presentation(0.016)
	if scene.bomb_audio.stream == null:
		fail("bomb_audio no tiene stream tras suelta de bomba")
		return
	if not scene.bomb_audio.stream.resource_path.ends_with("bomb_release.wav"):
		fail("bomb_audio tras suelta no es bomb_release.wav (%s)" % scene.bomb_audio.stream.resource_path)
		return
	if scene.sfx_play_counts.get("bomb_release", 0) < 1:
		fail("sfx_play_counts['bomb_release'] no se incrementó")
		return
	print("3. Suelta de bomba reproduce bomb_release verificado")

	# 4. Forzar el flanco de release_now reproduce cue_release_now una sola vez en varios frames
	scene.sim.mission.phase = "BOMBARDEO"
	scene.sim.bomb.reset()
	scene.last_aid_release_now = false
	scene.sfx_play_counts["cue_release_now"] = 0

	# Colocar el avión alineado a velocidad 0 sobre el objetivo para miss_distance <= 55.0
	scene.sim.flight.speed = 0.0
	scene.sim.flight.position = scene.sim.mission.target + Vector3(0, 0, 10.0)
	for i in range(5):
		scene.update_presentation(0.016)
	if scene.sfx_play_counts.get("cue_release_now", 0) != 1:
		fail("cue_release_now se reprodujo %d veces en 5 frames (se esperaba exactamente 1)" % scene.sfx_play_counts.get("cue_release_now", 0))
		return

	# Mover el avión lejos (flanco de bajada)
	scene.sim.flight.position = scene.sim.mission.target + Vector3(0, 0, 3000.0)
	scene.update_presentation(0.016)
	if scene.sfx_play_counts.get("cue_release_now", 0) != 1:
		fail("cue_release_now cambió de contador en bajada")
		return

	# Volver a colocar el avión sobre el objetivo (segundo flanco de subida)
	scene.sim.flight.position = scene.sim.mission.target + Vector3(0, 0, 10.0)
	for i in range(5):
		scene.update_presentation(0.016)
	if scene.sfx_play_counts.get("cue_release_now", 0) != 2:
		fail("cue_release_now no se incrementó en el segundo flanco de subida (es %d)" % scene.sfx_play_counts.get("cue_release_now", 0))
		return
	print("4. Flanco de subida de release_now reproduce cue_release_now exactamente una vez verificado")

	# 5. Entrar en COMPLETADA reproduce el stinger una sola vez
	scene.sfx_play_counts["stinger_mission_complete"] = 0
	scene.mission_stinger_played = false
	scene.sim.mission.phase = "COMPLETADA"
	for i in range(10):
		scene.update_presentation(0.016)
	if scene.sfx_play_counts.get("stinger_mission_complete", 0) != 1:
		fail("stinger_mission_complete se reprodujo %d veces (se esperaba exactamente 1)" % scene.sfx_play_counts.get("stinger_mission_complete", 0))
		return
	if scene.stinger_audio.stream == null or not scene.stinger_audio.stream.resource_path.ends_with("stinger_mission_complete.wav"):
		fail("stinger_audio no tiene asignado stinger_mission_complete.wav")
		return
	print("5. Entrar en COMPLETADA reproduce stinger_mission_complete una sola vez verificado")

	# 6. Motor dañado (< 50%) activa engine_b17_damaged_loop
	scene.sim.mission.phase = "APROXIMACION"
	scene.sim.flight.speed = 85.0
	scene.sim.damage.reset()
	scene.update_presentation(0.016)
	if scene.engine_damaged_audio.playing:
		fail("engine_damaged_audio está sonando con motores al 100%")
		return
	scene.sim.damage.apply_damage(25.0, 0) # Motor 0 baja a 37.5% (< 50%)
	scene.update_presentation(0.016)
	if not scene.engine_damaged_audio.playing:
		fail("engine_damaged_audio no empezó a sonar con motor al 37.5%")
		return
	if scene.engine_damaged_audio.volume_db != -14.0:
		fail("engine_damaged_audio volume_db no es -14.0 (es %f)" % scene.engine_damaged_audio.volume_db)
		return
	print("6. Motor dañado < 50% reproduce engine_b17_damaged_loop a -14 dB verificado")

	scene.free()
	print("TEST PASS: integracion de audio verificada")
	quit(0)
