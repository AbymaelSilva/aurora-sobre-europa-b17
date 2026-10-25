extends SceneTree

# Test para Tarea B (Lote 5): audio/sfx_bank.gd

func _initialize() -> void:
	call_deferred("run_checks")

func fail(msg: String) -> void:
	print("TEST FAIL: ", msg)
	quit(1)

func run_checks() -> void:
	var SfxBankClass = load("res://audio/sfx_bank.gd")
	if SfxBankClass == null:
		fail("No se pudo cargar res://audio/sfx_bank.gd")
		return

	# 1. engine_b17_ext_loop tiene loop_mode FORWARD y loop_end > 0
	var ext_stream = SfxBankClass.get_stream("engine_b17_ext_loop")
	if ext_stream == null:
		fail("get_stream('engine_b17_ext_loop') devolvió null")
		return
	if not (ext_stream is AudioStreamWAV):
		fail("engine_b17_ext_loop no es AudioStreamWAV")
		return
	var ext_wav: AudioStreamWAV = ext_stream as AudioStreamWAV
	if ext_wav.loop_mode != AudioStreamWAV.LOOP_FORWARD:
		fail("engine_b17_ext_loop loop_mode no es LOOP_FORWARD (es %d)" % ext_wav.loop_mode)
		return
	if ext_wav.loop_begin != 0:
		fail("engine_b17_ext_loop loop_begin no es 0 (es %d)" % ext_wav.loop_begin)
		return
	if ext_wav.loop_end <= 0:
		fail("engine_b17_ext_loop loop_end no es > 0 (es %d)" % ext_wav.loop_end)
		return
	# Supervisor: el bucle debe cubrir la duración completa (con QOA, data.size() daba 1.6 s en vez de 8 s).
	var expected_end: int = int(round(ext_wav.get_length() * ext_wav.mix_rate))
	if absi(ext_wav.loop_end - expected_end) > 1:
		fail("engine_b17_ext_loop loop_end %d no cubre la duración completa (esperado %d)" % [ext_wav.loop_end, expected_end])
		return
	print("engine_b17_ext_loop loop verificado: mode=FORWARD, end=%d" % ext_wav.loop_end)

	# 2. bomb_release no tiene bucle
	var bomb_stream = SfxBankClass.get_stream("bomb_release")
	if bomb_stream == null:
		fail("get_stream('bomb_release') devolvió null")
		return
	var bomb_wav: AudioStreamWAV = bomb_stream as AudioStreamWAV
	if bomb_wav != null and bomb_wav.loop_mode != AudioStreamWAV.LOOP_DISABLED:
		fail("bomb_release tiene bucle (loop_mode=%d)" % bomb_wav.loop_mode)
		return
	print("bomb_release sin bucle verificado")

	# 3. random_variant("flak_near", 3, rng) devuelve uno de los tres
	var rng := RandomNumberGenerator.new()
	rng.seed = 98765
	var valid_paths := [
		"res://assets/audio/sfx/flak_near_01.wav",
		"res://assets/audio/sfx/flak_near_02.wav",
		"res://assets/audio/sfx/flak_near_03.wav"
	]
	for i in range(10):
		var flak_stream = SfxBankClass.random_variant("flak_near", 3, rng)
		if flak_stream == null:
			fail("random_variant('flak_near', 3, rng) devolvió null")
			return
		if not flak_stream.resource_path in valid_paths:
			fail("stream inesperado de random_variant: %s" % flak_stream.resource_path)
			return

	# Comprobar variante sin rng explicito (usando default)
	var gun_stream = SfxBankClass.random_variant("gun_m2_shot", 3)
	if gun_stream == null:
		fail("random_variant('gun_m2_shot', 3) sin rng devolvió null")
		return
	var valid_gun_paths := [
		"res://assets/audio/sfx/gun_m2_shot_01.wav",
		"res://assets/audio/sfx/gun_m2_shot_02.wav",
		"res://assets/audio/sfx/gun_m2_shot_03.wav"
	]
	if not gun_stream.resource_path in valid_gun_paths:
		fail("stream de disparo inesperado: %s" % gun_stream.resource_path)
		return
	print("random_variant verificado con y sin rng")

	# 4. Comprobacion de bucle estereo (wind_altitude_loop)
	var wind_stream = SfxBankClass.get_stream("wind_altitude_loop")
	if wind_stream is AudioStreamWAV:
		var wind_wav: AudioStreamWAV = wind_stream as AudioStreamWAV
		if not wind_wav.stereo:
			fail("wind_altitude_loop debería ser estéreo")
			return
		if wind_wav.loop_mode != AudioStreamWAV.LOOP_FORWARD:
			fail("wind_altitude_loop loop_mode no es LOOP_FORWARD")
			return
		if wind_wav.loop_end <= 0:
			fail("wind_altitude_loop loop_end no es > 0")
			return
		print("wind_altitude_loop estéreo loop verificado: end=%d" % wind_wav.loop_end)

	print("TEST PASS: banco de sonidos SfxBank verificado")
	quit(0)
