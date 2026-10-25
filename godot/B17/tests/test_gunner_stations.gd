extends SceneTree

func _init() -> void:
	print("--- TEST GUNNER STATIONS ---")
	var PlayerControls = load("res://core/player_controls.gd")
	var ctrl = PlayerControls.new()
	ctrl.station = "ARTILLERO"
	assert(ctrl.gunner_station == "DORSAL", "Estación por defecto debe ser DORSAL")

	ctrl.cycle_gunner_station()
	assert(ctrl.gunner_station == "COLA", "Primer ciclo debe cambiar a COLA")

	ctrl.cycle_gunner_station()
	assert(ctrl.gunner_station == "VENTRAL", "Segundo ciclo debe cambiar a VENTRAL")

	ctrl.cycle_gunner_station()
	assert(ctrl.gunner_station == "DORSAL", "Tercer ciclo debe retornar a DORSAL")

	# Clamp de apuntado en COLA
	ctrl.gunner_station = "COLA"
	ctrl.aim = Vector2(deg_to_rad(90.0), deg_to_rad(60.0))
	ctrl.clamp_aim_by_station()
	assert(ctrl.aim.x <= deg_to_rad(35.0) + 0.001, "Yaw de COLA debe estar acotado a +/-35 deg")
	assert(ctrl.aim.y <= deg_to_rad(25.0) + 0.001, "Pitch de COLA debe estar acotado a +25 deg")

	# Origen de montantes en combat_mounts.gd
	var CombatMounts = load("res://visuals/combat_mounts.gd")
	var dummy = Node3D.new()
	var d_pos = CombatMounts.turret_mount(dummy, "DORSAL")
	var c_pos = CombatMounts.turret_mount(dummy, "COLA")
	var v_pos = CombatMounts.turret_mount(dummy, "VENTRAL")
	assert(d_pos.y > 0.0, "Dorsal debe estar sobre el fuselaje")
	assert(c_pos.z > 0.0, "Cola debe estar en la popa (+Z)")
	assert(v_pos.y < 0.0, "Ventral debe estar bajo el fuselaje")

	print("TEST PASS: test_gunner_stations")
	quit(0)
