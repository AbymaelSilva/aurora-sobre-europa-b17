extends RefCounted

static func build(phase: String, hull: float, engines: PackedFloat32Array, elapsed: float, bomb_result: String) -> Dictionary:
    var success = phase == "COMPLETADA"
    var engines_available: int = 0
    for engine in engines:
        if engine>0.0: engines_available += 1
    var title = "MISIÓN COMPLETADA" if success else "MISIÓN INTERRUMPIDA"
    var detail = "Tripulación en zona segura" if success else ("El bombardeo no alcanzó el objetivo" if bomb_result == "FALLO" else "El avión no pudo regresar")
    hull = clamp(hull, 0, 100)
    var duration_seconds = max(elapsed, 0)
    return {
        "title": title,
        "detail": detail,
        "hull": hull,
        "engines_available": engines_available,
        "duration_seconds": duration_seconds,
        "success": success
    }
