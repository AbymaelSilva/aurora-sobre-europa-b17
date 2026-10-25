extends RefCounted

var position: Vector3 = Vector3(0, 1200, 0)
var yaw: float = 0
var pitch: float = 0
var speed: float = 85
var turn_bias: float = 0.0

func reset() -> void:
    position = Vector3(0, 1200, 0)
    yaw = 0
    pitch = 0
    speed = 85
    turn_bias = 0.0

func step(pitch_input: float, turn_input: float, throttle_input: float, delta: float) -> void:
    delta = clamp(delta, 0, 0.05)
    yaw += (clamp(turn_input, -1, 1) * deg_to_rad(18) + turn_bias) * delta
    pitch = move_toward(pitch, clamp(pitch_input, -1, 1) * deg_to_rad(10), deg_to_rad(8) * delta)
    speed = clamp(speed + clamp(throttle_input, -1, 1) * 8 * delta, 55, 110)
    position += -Basis.from_euler(Vector3(pitch, yaw, 0)).z * speed * delta
    position.y = max(position.y, 30)
