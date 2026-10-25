extends RefCounted

static func create_stream() -> AudioStreamWAV:
    var stream = AudioStreamWAV.new()
    var bytes = PackedByteArray()
    bytes.resize(22050 * 2)
    var t = 0.0
    var value = 0.0
    
    for i in range(22050):
        t = float(i) / 22050.0
        value = (sin(TAU * 90.0 * t) * 0.45 + sin(TAU * 180.0 * t) * 0.2 + sin(TAU * 270.0 * t) * 0.1) * 0.18
        bytes.encode_s16(i * 2, int(clamp(value, -1.0, 1.0) * 32767.0))
    
    stream.format = AudioStreamWAV.FORMAT_16_BITS
    stream.mix_rate = 22050
    stream.stereo = false
    stream.data = bytes
    stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
    stream.loop_begin = 0
    stream.loop_end = 22050
    
    return stream
