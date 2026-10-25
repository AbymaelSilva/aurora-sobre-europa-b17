extends RefCounted

var position: Vector3 = Vector3(0, 100, 0)
var yaw: float = 0
var pitch: float = 0
var speed: float = 50

func step(pitch_input: float, turn_input: float, throttle_input: float, delta: float) -> void:
    pitch_input = clamp(pitch_input, -0.5, 0.5)
    turn_input = clamp(turn_input, -1, 1)
    throttle_input = clamp(throttle_input, 0, 1)
    speed = clamp(speed + throttle_input * 100 * delta, 25, 90)
    yaw += turn_input * 10 * delta
    pitch += pitch_input * 10 * delta
    position.z -= speed * delta

func reset() -> void:
    position = Vector3(0, 100, 0)
    yaw = 0
    pitch = 0
    speed = 50