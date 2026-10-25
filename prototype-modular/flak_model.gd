extends RefCounted

var timer: float = 0
var interval: float = 1.2
var bursts: int = 0

func reset() -> void:
	timer = 0
	bursts = 0

func step(delta: float, in_zone: bool) -> bool:
	if not in_zone:
		timer = 0
		return false
	
	timer += clampf(delta, 0, 0.05)
	if timer >= interval:
		timer -= interval
		bursts += 1
		return true
	else:
		return false
