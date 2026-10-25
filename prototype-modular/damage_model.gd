extends RefCounted

var hull: float = 100.0
var engine: float = 100.0

func reset() -> void:
    hull = 100.0
    engine = 100.0

func apply_damage(amount: float) -> void:
    amount = maxf(amount, 0.0)
    hull = clampf(hull - amount, 0, 100)
    engine = clampf(engine - amount * 1.5, 0, 100)

func destroyed() -> bool:
    return hull <= 0.0

func thrust_factor() -> float:
    return 0.5 + 0.5 * engine / 100
