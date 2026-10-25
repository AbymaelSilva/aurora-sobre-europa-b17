extends RefCounted

var hull: float = 100
var engines: PackedFloat32Array = PackedFloat32Array([100, 100, 100, 100])
var engine_feathered: PackedByteArray = PackedByteArray([0, 0, 0, 0])
var engine_extinguisher_used: PackedByteArray = PackedByteArray([0, 0, 0, 0])

var altimeter_error: float = 0.0
var compass_drift: float = 0.0
var norden_disabled: bool = false
var instrument_damage_timer: float = 0.0

var engine: float:
    get:
        return (engines[0] + engines[1] + engines[2] + engines[3]) / 4.0

func reset():
    hull = 100
    engines = PackedFloat32Array([100, 100, 100, 100])
    engine_feathered = PackedByteArray([0, 0, 0, 0])
    engine_extinguisher_used = PackedByteArray([0, 0, 0, 0])
    altimeter_error = 0.0
    compass_drift = 0.0
    norden_disabled = false
    instrument_damage_timer = 0.0

func apply_damage(amount: float, engine_index: int = -1):
    amount = max(amount, 0)
    hull = clamp(hull - amount, 0, 100)
    if engine_index >= 0 and engine_index < 4:
        # Si el extintor fue usado, el motor no sigue degradándose por daños indirectos leves
        engines[engine_index] = clamp(engines[engine_index] - amount * 2.5, 0, 100)

func feather_engine(idx: int) -> void:
    if idx >= 0 and idx < 4 and not engine_feathered[idx]:
        engine_feathered[idx] = 1

func use_extinguisher(idx: int) -> void:
    if idx >= 0 and idx < 4 and not engine_extinguisher_used[idx] and engines[idx] < 25.0:
        engine_extinguisher_used[idx] = 1
        engines[idx] = clampf(engines[idx] + 8.0, 0.0, 25.0)

func apply_instrument_damage(proximity: float, jitter_scale: float = 1.0) -> void:
    if proximity > 80.0:
        return
    var severity: float = (1.0 - (proximity / 80.0)) * clampf(jitter_scale, 0.0, 1.0)
    if randf() < severity * 0.45:
        altimeter_error = randf_range(-40.0, 40.0) * severity
        compass_drift = randf_range(-0.08, 0.08) * severity
    if randf() < severity * 0.20 and proximity < 30.0:
        norden_disabled = true
    instrument_damage_timer = randf_range(8.0, 25.0) * severity

func step_instruments(delta: float) -> void:
    if instrument_damage_timer > 0.0:
        instrument_damage_timer = maxf(0.0, instrument_damage_timer - delta)
        if instrument_damage_timer <= 0.0:
            altimeter_error = 0.0
            compass_drift = 0.0
            norden_disabled = false

func destroyed() -> bool:
    return hull <= 0

func thrust_factor() -> float:
    var total: float = 0.0
    for i in 4:
        var contrib: float = engines[i] / 100.0
        if engine_feathered[i]:
            contrib = 0.0
        total += contrib
    return 0.6 + 0.4 * (total / 4.0)
