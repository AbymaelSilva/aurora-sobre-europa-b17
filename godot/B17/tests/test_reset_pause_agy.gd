extends SceneTree

func _initialize():
	var Sim = load("res://core/simulation.gd")
	if not Sim:
		print("TEST FAIL: Failed to load simulation.gd")
		quit(1)
		return
	var sim = Sim.new()
	var initial_pos = Vector3(0, 1200, 0)

	sim.paused = true
	for i in 120:
		sim.step(1.0 / 60.0)
	if sim.mission.clock != 0 or sim.flight.position != initial_pos:
		print("TEST FAIL: Simulation advanced while paused")
		quit(1)
		return

	sim.paused = false
	for i in 600:
		sim.step(1.0 / 60.0)
	if sim.mission.clock <= 0 or sim.flight.position == initial_pos:
		print("TEST FAIL: Simulation did not advance while unpaused")
		quit(1)
		return

	sim.damage.hull = 40
	sim.damage.engines[0] = 0
	sim.mission.phase = "REGRESO"
	sim.mission.waypoint_index = 3
	sim.flak.bursts = 17
	sim.pitch_input = 0.5
	sim.turn_input = 0.5
	sim.throttle_input = 0.5

	sim.reset()

	var engines_ok = true
	for eng in sim.damage.engines:
		if eng != 100:
			engines_ok = false
	if sim.damage.hull != 100 or not engines_ok or sim.mission.phase != "FORMACION" or sim.mission.clock != 0 or sim.mission.waypoint_index != 0 or sim.flak.bursts != 0 or sim.flight.position != initial_pos or sim.flight.speed != 85 or sim.pitch_input != 0 or sim.turn_input != 0 or sim.throttle_input != 0 or sim.paused != false:
		print("TEST FAIL: Reset failed to restore initial state")
		quit(1)
		return

	sim.step(1.0 / 60.0)
	if sim.mission.clock <= 0:
		print("TEST FAIL: Simulation stuck after reset")
		quit(1)
		return

	print("TEST PASS: Agy full simulator reset and pause")
	quit(0)
