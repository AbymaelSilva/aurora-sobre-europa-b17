extends SceneTree

func _init() -> void:
	print("--- TEST ENGINE EMERGENCIES ---")
	var Damage = load("res://core/damage.gd")
	var d = Damage.new()
	assert(d.thrust_factor() == 1.0, "Thrust factor inicial debe ser 1.0")

	# Daño a motor 1
	d.engines[0] = 10.0
	var tf_damaged = d.thrust_factor()
	assert(tf_damaged < 1.0, "Thrust factor debe reducirse con motor dañado")

	# Extintor en motor con fuego (<25)
	d.use_extinguisher(0)
	assert(d.engine_extinguisher_used[0] == 1, "Extintor debe quedar marcado como usado")
	assert(d.engines[0] > 10.0, "Extintor debe haber sofocado y recuperado ligeramente el motor")

	# No se puede reutilizar extintor en el mismo motor
	var hp_after_first = d.engines[0]
	d.use_extinguisher(0)
	assert(d.engines[0] == hp_after_first, "No se puede reutilizar el extintor")

	# Feathering
	d.feather_engine(0)
	assert(d.engine_feathered[0] == 1, "Motor 0 debe estar embanderado")
	var tf_feathered = d.thrust_factor()
	assert(tf_feathered < tf_damaged, "Motor embanderado no genera empuje")

	# Simulación de sesgo de giro (turn_bias) por empuje asimétrico
	var Sim = load("res://core/simulation.gd")
	var sim = Sim.new()
	sim.damage.engines[0] = 0.0
	sim.damage.engine_feathered[0] = 1
	sim.damage.engines[1] = 0.0
	sim.damage.engine_feathered[1] = 1
	# Babor (0,1) = 0 empuje; Estribor (2,3) = 100 empuje -> gira a la izquierda (turn_bias < 0)
	sim.step(0.02)
	assert(sim.flight.turn_bias < 0.0, "Empuje mayor a estribor debe provocar sesgo de giro negativo")

	print("TEST PASS: test_engine_emergencies")
	quit(0)
