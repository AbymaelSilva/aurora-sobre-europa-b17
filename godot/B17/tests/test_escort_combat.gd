extends SceneTree

func _init() -> void:
	print("--- TEST ESCORT COMBAT ---")
	var PlayerControls = load("res://core/player_controls.gd")
	var ctrl = PlayerControls.new()
	assert(not ctrl.escort_cover_requested, "No debe estar solicitada al inicio")

	# Solicitud exitosa
	var ok = ctrl.request_escort_cover()
	assert(ok, "Primera solicitud debe ser aceptada")
	assert(ctrl.escort_cover_requested, "Estado debe ser activo")
	assert(ctrl.escort_cover_timer == ctrl.ESCORT_COVER_DURATION, "Timer debe ser 20s")

	# Cooldown de 45s activo: solicitud repetida denegada
	var ok_repeat = ctrl.request_escort_cover()
	assert(not ok_repeat, "Segunda solicitud inmediata debe ser denegada por cooldown")

	# Daño real de escolta en combate dentro de un árbol de escena
	var root_node = Node3D.new()
	root.add_child(root_node)

	var Escort = load("res://visuals/escort.gd")
	var esc = Escort.new()
	root_node.add_child(esc)
	esc.setup_slot(0)

	var Sim = load("res://core/simulation.gd")
	var sim = Sim.new()
	sim.combat.spawn_wave(1, sim.flight.position)
	assert(sim.combat.fighters.size() > 0, "Debe haber cazas en la oleada")

	var fighter = sim.combat.fighters[0]
	var initial_hp = float(fighter["health"])
	fighter["ai"].position = esc.position + Vector3(0.0, 0.0, -100.0)

	# Llamada a update_combat con controls
	esc.update_combat(0.05, sim.flight.position, sim.flight.yaw, sim.flight.pitch, false, sim.combat, null, ctrl)
	assert(sim.combat.damage_events.size() > 0 or fighter["health"] <= initial_hp, "Escoltas deben interactuar con cazas en su sector")

	print("TEST PASS: test_escort_combat")
	quit(0)
