extends RefCounted

var fighters: Array = []
var active_wave: int = 0
var total_kills: int = 0
var defensive_fire_cooldown: float = 0.0
var enemy_shots: Array = []
var defensive_shots: Array = []
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _init() -> void:
	rng.seed = 1945

func reset() -> void:
	fighters.clear()
	effective_attackers = 0
	peak_attackers = 0
	wave_complete = false
	damage_events.clear()
	active_wave = 0
	total_kills = 0
	defensive_fire_cooldown = 0.0
	enemy_shots.clear()
	defensive_shots.clear()
	rng.seed = 1945

const Config = preload("res://core/combat_config.gd")
var effective_attackers := 0
var peak_attackers := 0
var wave_complete := false
var damage_events: Array = []

func spawn_wave(wave_num: int, bomber_pos: Vector3) -> void:
	active_wave = wave_num
	fighters.clear()
	enemy_shots.clear()
	defensive_shots.clear()
	damage_events.clear()
	wave_complete = false
	var yaw := PI if wave_num == 2 else 0.0
	for i in range(Config.ENEMY_COUNT):
		var sector := int(i / Config.SECTOR_COUNT)
		var local := i % Config.SECTOR_COUNT
		var ai = preload("res://core/fighter_ai.gd").new()
		var profile: String = ["FRONTAL", "LATERAL", "COLA"][sector]
		var side := -1.0 if local % 2 == 0 else 1.0
		ai.setup(bomber_pos, side, profile, local)
		ai.start_pass(bomber_pos, yaw, int(i / Config.GROUP_SIZE))
		fighters.append({"ai": ai, "health": 60.0, "alive": true,
			"cooldown": 0.0, "fall_vel": Vector3.ZERO,
			"variant": Config.variant_for(i, rng.seed), "shot_count": 0})

func step(delta: float, bomber_pos: Vector3, bomber_yaw: float, mission_phase: String, damage_sys) -> void:
	delta = clamp(delta, 0.0, 0.05)
	enemy_shots.clear()
	defensive_shots.clear()

	if active_wave == 0 and mission_phase == "APROXIMACION" and bomber_pos.z < -4000.0:
		spawn_wave(1, bomber_pos)
	elif active_wave == 1 and mission_phase == "REGRESO" and bomber_pos.z > -22000.0:
		spawn_wave(2, bomber_pos)

	effective_attackers = 0
	# Bounded firing windows independent of total force.
	for i in range(fighters.size()):
		var fighter = fighters[i]
		if fighter["alive"]:
			fighter["cooldown"] -= delta
			var ai = fighter["ai"]
			ai.step(delta, bomber_pos)
			var dist: float = ai.position.distance_to(bomber_pos)
			if ai.is_attacking() and dist < 650.0 and effective_attackers < Config.MAX_EFFECTIVE_ATTACKERS and ai.velocity.normalized().dot((bomber_pos - ai.position).normalized()) > 0.60:
				effective_attackers += 1
			else:
				continue
			if fighter["cooldown"] <= 0.0:
				fighter["cooldown"] = 0.50
				fighter["shot_count"] += 1
				enemy_shots.append({"origin": ai.position, "target": bomber_pos, "fighter": i, "represented_shots": 4})
				if damage_sys != null:
					var target_engine = int(rng.randi_range(0, 3))
					damage_sys.apply_damage(0.02, target_engine)

	# Físicas de caída para cazas derribados
	for i in range(fighters.size()):
		var fighter = fighters[i]
		if not fighter["alive"]:
			var fall = fighter["fall_vel"] as Vector3
			if fall.length_squared() < 1.0:
				fall = fighter["ai"].velocity
			fall += Vector3(0.0, -3.0, 0.0) * delta
			fighter["fall_vel"] = fall
			var ai = fighter["ai"]
			ai.position += fall * delta

	# Fuego defensivo de las torretas del B-17 (adquisición del caza más cercano)
	defensive_fire_cooldown -= delta
	var nearest_idx := -1
	var nearest_dist := 999999.0

	for i in range(fighters.size()):
		if fighters[i]["alive"]:
			var d: float = fighters[i]["ai"].position.distance_to(bomber_pos)
			if d < nearest_dist:
				nearest_dist = d
				nearest_idx = i

	if nearest_idx >= 0 and nearest_dist < 650.0 and defensive_fire_cooldown <= 0.0:
		defensive_fire_cooldown = 0.20
		var target_f = fighters[nearest_idx]
		defensive_shots.append({"origin": bomber_pos, "target": target_f["ai"].position, "represented_shots": 4})
		target_f["health"] -= 12.0
		target_f["damage_cause"] = "defensive_fire"
		if target_f["health"] <= 0.0:
			target_f["alive"] = false
			target_f["fall_vel"] = target_f["ai"].velocity
			damage_events.append({"fighter": nearest_idx, "cause": "defensive_fire", "effect": "engine_smoke_lift_loss", "health": target_f["health"]})
			if damage_events.size() > 96: damage_events.pop_front()
			total_kills += 1

	peak_attackers = maxi(peak_attackers, effective_attackers)
	wave_complete = not fighters.is_empty() and fighters.all(func(f): return not f["alive"])
