extends RefCounted

# Compatibilidad con consumidores antiguos: siempre usar el WAV M2 vigente.
static func create_gun_stream() -> AudioStreamWAV:
    return load("res://assets/audio/sfx/gun_m2_shot_01.wav") as AudioStreamWAV

static func create_flak_stream() -> AudioStreamWAV:
    var stream = AudioStreamWAV.new()
    var samples = PackedByteArray()
    samples.resize(8000 * 2)
    var rng = RandomNumberGenerator.new()
    rng.randomize()
    
    var rumble = 0.0
    var decay_rate = 0.005
    var noise = 0.0
    
    for i in range(8000):
        rumble *= (1.0 - decay_rate)
        noise = rng.randf() * 2.0 - 1.0
        var sample = int((rumble * 0.5 + noise * 0.2) * 32767)
        samples[i * 2] = sample & 0xFF
        samples[i * 2 + 1] = (sample >> 8) & 0xFF
    
    stream.format = AudioStreamWAV.FORMAT_16_BITS
    stream.mix_rate = 22050
    stream.data = samples
    stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
    return stream

static func create_bomb_stream() -> AudioStreamWAV:
    var stream = AudioStreamWAV.new()
    var samples = PackedByteArray()
    samples.resize(22050 * 2)
    var rng = RandomNumberGenerator.new()
    rng.randomize()
    
    var rumble = 0.0
    var decay_rate = 0.001
    var noise = 0.0
    
    for i in range(22050):
        rumble *= (1.0 - decay_rate)
        noise = rng.randf() * 2.0 - 1.0
        var sample = int((rumble * 0.5 + noise * 0.3) * 32767)
        samples[i * 2] = sample & 0xFF
        samples[i * 2 + 1] = (sample >> 8) & 0xFF
    
    stream.format = AudioStreamWAV.FORMAT_16_BITS
    stream.mix_rate = 22050
    stream.data = samples
    stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
    return stream
