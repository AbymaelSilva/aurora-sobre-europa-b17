extends SceneTree
const Combat = preload("res://core/combat_manager.gd")
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var metrics: Array = []
	var slots = preload("res://core/formation_slots.gd").new()
	for seed_value in [1945, 42, 871]:
		var combat = Combat.new()
		combat.rng.seed = seed_value
		var bomber := Vector3(0, 1200, -5000)
		combat.spawn_wave(1, bomber)
		assert(combat.fighters.size() == 48)
		var profiles := {"FRONTAL": 0, "LATERAL": 0, "COLA": 0}
		for f in combat.fighters: profiles[f["ai"].profile] += 1
		assert(profiles.values() == [16, 16, 16])
		var min_player := INF
		var min_pair := INF
		var min_bomber := INF
		var pair_ids := Vector2i.ZERO
		var bomber_ids := Vector2i.ZERO
		var shots := 0
		var min_speed := INF
		var max_speed := 0.0
		var damage = preload("res://core/damage.gd").new()
		# Geometry fixture keeps all 48 alive, checks every 0.05 s for 2 full cycles.
		for tick in range(2000):
			bomber.z -= 85.0 * 0.05
			combat.step(0.05, bomber, 0.0, "APROXIMACION", damage)
			shots += combat.enemy_shots.size()
			assert(combat.effective_attackers <= 8)
			for i in range(48):
				combat.fighters[i]["health"] = 60000.0
				var p: Vector3 = combat.fighters[i]["ai"].position
				min_speed = minf(min_speed, combat.fighters[i]["ai"].speed)
				max_speed = maxf(max_speed, combat.fighters[i]["ai"].speed)
				min_player = minf(min_player, p.distance_to(bomber))
				for j in range(i):
					var d: float = p.distance_to(combat.fighters[j]["ai"].position)
					if d < min_pair:
						min_pair = d
						pair_ids = Vector2i(i, j)
				for k in range(slots.offsets.size()):
					var d: float = p.distance_to(bomber + slots.offsets[k])
					if d < min_bomber:
						min_bomber = d
						bomber_ids = Vector2i(i, k)
		print("GEOMETRY ", min_player, " / ", min_pair, " / ", min_bomber, " ids ", pair_ids, " bomber ", bomber_ids)
		assert(min_player >= 120.0, "player clearance")
		assert(min_pair > 18.0, "fighter separation")
		assert(min_bomber > 25.0, "formation separation")
		assert(shots > 0)
		assert(min_speed > 65.0 and max_speed < 250.0)
		metrics.append({"min_speed_mps": min_speed, "max_speed_mps": max_speed, "seed": seed_value, "min_player_m": min_player, "min_pair_m": min_pair, "min_bomber_m": min_bomber, "peak_attackers": combat.peak_attackers, "enemy_bursts": shots, "hull_100s": damage.hull})
		for f in combat.fighters: f["alive"] = false
		combat.step(0.05, bomber, 0.0, "APROXIMACION", null)
		assert(combat.wave_complete)
		combat.reset()
		assert(combat.fighters.is_empty() and combat.enemy_shots.is_empty() and combat.damage_events.is_empty())
	# Real simulation survival, no invulnerability, both control modes.
	for autopilot in [true, false]:
		for seed_value in [1945, 42, 871]:
			var sim = preload("res://core/simulation.gd").new()
			sim.combat.rng.seed = seed_value
			sim.autopilot = autopilot
			sim.flight.position = Vector3(0, 1200, -5000)
			sim.mission.phase = "APROXIMACION"
			for tick in range(10800): sim.step(1.0 / 60.0)
			assert(not sim.damage.destroyed())
			metrics.append({"autopilot": autopilot, "seed": seed_value, "seconds": 180, "hull": sim.damage.hull, "kills": sim.combat.total_kills, "phase": sim.mission.phase})
			sim.paused = true
			var pos: Vector3 = sim.combat.fighters[0]["ai"].position
			for tick in range(60): sim.step(1.0 / 60.0)
			assert(pos == sim.combat.fighters[0]["ai"].position)
	var pool = preload("res://visuals/tracer_pool.gd").new()
	root.add_child(pool)
	for i in range(100): pool.fire(Vector3.ZERO, Vector3.FORWARD * 800.0)
	assert(pool.active_count() == 48 and pool.dropped == 52)
	pool.advance(0.4)
	assert(pool.active_count() == 0)
	pool.reset()
	pool.queue_free()
	var file := FileAccess.open("res://../../logs/lote9/simulation_metrics.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(metrics, "  "))
	print("TEST PASS: Lote9 48/sector/separation/attack cap/wave/reset/pause/survival/pool ", JSON.stringify(metrics))
	quit()
