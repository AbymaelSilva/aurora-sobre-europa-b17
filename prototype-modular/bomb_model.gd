extends RefCounted

var active: bool = false
var spent: bool = false
var position: Vector3 = Vector3.ZERO
var velocity: Vector3 = Vector3.ZERO
var result: String = "LISTA"

func reset() -> void:
    active = false
    spent = false
    position = Vector3.ZERO
    velocity = Vector3.ZERO
    result = "LISTA"

func release(origin: Vector3, initial_velocity: Vector3) -> bool:
    if spent:
        return false
    spent = true
    active = true
    position = origin
    velocity = initial_velocity
    result = "EN_VUELO"
    return true

func step(delta: float, target: Vector3, radius: float) -> void:
    if not active:
        return
    delta = clampf(delta, 0, 0.05)
    velocity.y -= 9.81 * delta
    position += velocity * delta
    if position.y <= 0:
        position.y = 0
        active = false
        var distance = Vector2(position.x, position.z).distance_to(Vector2(target.x, target.z))
        result = "IMPACTO" if distance <= radius else "FALLO"
