extends RefCounted

var active: bool = false
var spent: bool = false
var position: Vector3 = Vector3.ZERO
var velocity: Vector3 = Vector3.ZERO
var result: String = "LISTA"

const TOTAL_BOMBS: int = 30
const RELEASE_INTERVAL: float = 0.08

var released_count: int = 0
var release_timer: float = 0.0
var origin_position: Vector3 = Vector3.ZERO
var release_velocity: Vector3 = Vector3.ZERO
var bombs: Array = []
var new_releases: int = 0
var new_impacts: int = 0

func reset() -> void:
	active = false
	spent = false
	position = Vector3.ZERO
	velocity = Vector3.ZERO
	result = "LISTA"
	released_count = 0
	release_timer = 0.0
	origin_position = Vector3.ZERO
	release_velocity = Vector3.ZERO
	bombs.clear()
	new_releases = 0
	new_impacts = 0

func release(origin: Vector3, initial_velocity: Vector3) -> bool:
	if spent:
		return false
	spent = true
	active = true
	result = "EN_VUELO"
	origin_position = origin
	release_velocity = initial_velocity
	released_count = 0
	release_timer = 0.0
	bombs.clear()
	new_releases = 0
	new_impacts = 0

	_drop_bomb()
	return true

func _drop_bomb() -> void:
	if released_count >= TOTAL_BOMBS:
		return
	var idx := released_count
	# Dispersión balística longitudinal realista según el intervalo de suelta en avance
	var forward_dir := release_velocity.normalized()
	var forward_speed := release_velocity.length()
	var longitudinal_dist := float(idx) * (forward_speed * RELEASE_INTERVAL * 0.95)
	var jitter_lat := sin(float(idx) * 2.7) * 2.2
	var jitter_alt := -float(idx) * 0.4
	
	var b_pos := origin_position + forward_dir * longitudinal_dist + Vector3(jitter_lat, jitter_alt, 0.0)
	var b_vel := release_velocity + Vector3(jitter_lat * 0.1, -float(idx) * 0.02, 0.0)

	bombs.append({
		"id": idx,
		"position": b_pos,
		"velocity": b_vel,
		"active": true,
		"spent": true,
		"hit": false
	})
	released_count += 1
	new_releases += 1
	if bombs.size() == 1:
		position = b_pos
		velocity = b_vel

func step(delta: float, target: Vector3, radius: float) -> void:
	new_releases = 0
	new_impacts = 0
	if not active:
		return
	delta = clampf(delta, 0.0, 0.05)

	# Suelta secuencial en ristra (bomb train) a intervalos de 0.08 s
	if released_count < TOTAL_BOMBS:
		release_timer += delta
		while release_timer >= RELEASE_INTERVAL and released_count < TOTAL_BOMBS:
			release_timer -= RELEASE_INTERVAL
			_drop_bomb()

	var any_airborne := false
	var hits := 0

	for b in bombs:
		if b["active"]:
			b["velocity"].y -= 9.81 * delta
			b["position"] += b["velocity"] * delta
			if b["position"].y <= 0.0:
				b["position"].y = 0.0
				b["active"] = false
				new_impacts += 1
				var d: float = Vector2(b["position"].x, b["position"].z).distance_to(Vector2(target.x, target.z))
				if d <= radius:
					b["hit"] = true
			else:
				any_airborne = true
		if b.get("hit", false):
			hits += 1

	if not bombs.is_empty():
		position = bombs[0]["position"]
		velocity = bombs[0]["velocity"]

	# La salva concluye cuando las 30 bombas han sido liberadas y ninguna permanece en el aire
	if released_count >= TOTAL_BOMBS and not any_airborne:
		active = false
		result = "IMPACTO" if hits > 0 else "FALLO"
