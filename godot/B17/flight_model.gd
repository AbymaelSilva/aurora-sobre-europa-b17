extends RefCounted

var position: Vector3 = Vector3(0, 100, 0)
var yaw: float = 0.0
var pitch: float = 0.0
var speed: float = 50.0

func step(pitch_input: float, turn_input: float, throttle_input: float, delta: float) -> void:
    delta = clamp(delta, 0, 0.05)
    yaw += clamp(turn_input, -1, 1) * 0.55 * delta
    pitch = move_toward(pitch, clamp(pitch_input, -1, 1) * 0.35, 0.45 * delta)
    speed += clamp(throttle_input, -1, 1) * 12 * delta
    speed = clamp(speed, 25, 90)
    var direction: Vector3 = -Basis.from_euler(Vector3(pitch, yaw, 0)).z
    position += direction * speed * delta
    position.y = max(position.y, 5)

func reset() -> void:
    position = Vector3(0, 100, 0)
    yaw = 0.0
    pitch = 0.0
    speed = 50.0
