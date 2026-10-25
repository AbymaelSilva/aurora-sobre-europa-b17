extends RefCounted

var timer: float = 0.0
var interval: float = 4.0
var current_interval: float = 4.0
var bursts: int = 0
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var last_burst_proximity: float = 999.0

func _init() -> void:
	rng.seed = 1944
	_pick_interval()

func reset() -> void:
	timer = 0.0
	bursts = 0
	rng.seed = 1944
	last_burst_proximity = 999.0
	_pick_interval()

func _pick_interval() -> void:
	# Media exacta de 4.0 segundos por detonación (15 explosiones por minuto)
	# Dispersión pseudo-estocástica en rango [2.5, 5.5] segundos
	current_interval = rng.randf_range(2.5, 5.5)
	interval = current_interval

func step(delta: float, in_zone: bool) -> bool:
	if not in_zone:
		timer = 0.0
		return false

	timer += clampf(delta, 0.0, 0.05)
	if timer >= current_interval:
		timer -= current_interval
		bursts += 1
		last_burst_proximity = rng.randf_range(15.0, 120.0)
		_pick_interval()
		return true
	return false
