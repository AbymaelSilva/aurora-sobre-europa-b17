class_name SfxBank
extends RefCounted

const DIR := "res://assets/audio/sfx/"

static func get_stream(name: String) -> AudioStream:
	var clean_name: String = name.trim_suffix(".wav")
	var path: String = DIR + clean_name + ".wav"
	var raw := load(path) as AudioStream
	if raw == null:
		return null
	if clean_name.ends_with("_loop") and raw is AudioStreamWAV:
		var s: AudioStreamWAV = raw.duplicate() as AudioStreamWAV
		s.resource_name = clean_name
		var channels: int = 2 if s.stereo else 1
		s.loop_mode = AudioStreamWAV.LOOP_FORWARD
		s.loop_begin = 0
		# Con compresión QOA (por defecto al importar WAV) data no es PCM: el final del bucle sale de la duración real (corrección del supervisor).
		s.loop_end = int(round(s.get_length() * s.mix_rate))
		return s
	return raw

static func random_variant(base: String, count: int, rng: RandomNumberGenerator = null) -> AudioStream:
	var idx: int = rng.randi_range(1, count) if rng != null else randi_range(1, count)
	var variant_name: String = "%s_%02d" % [base, idx]
	return get_stream(variant_name)
