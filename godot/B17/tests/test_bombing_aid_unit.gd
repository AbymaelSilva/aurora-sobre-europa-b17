extends SceneTree
# Test unitario para core/bombing_aid.gd

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	await process_frame
	var BombingAid = load("res://core/bombing_aid.gd")
	if BombingAid == null:
		print("TEST FAIL: no se pudo cargar core/bombing_aid.gd")
		quit(1)
		return

	var Flight = load("res://core/flight.gd")
	var flight = Flight.new()
	flight.position = Vector3(0.0, 1200.0, -28670.5) # 1329.5m antes del blanco en Z = -30000
	flight.pitch = 0.0
	flight.yaw = 0.0
	flight.speed = 85.0

	var target = Vector3(0.0, 0.0, -30000.0)

	# 1. En la solucion exacta
	var res: Dictionary = BombingAid.calculate(flight, target, false, "BOMBARDEO")
	for k in ["release_now", "eta_seconds", "lateral_error_m", "status", "predicted_impact"]:
		if not res.has(k):
			print("TEST FAIL: falta campo %s" % k)
			quit(1)
			return

	if not res["release_now"]:
		print("TEST FAIL: en solucion exacta release_now debio ser true, dio %s (status=%s dist=%.1f)" % [
			res["release_now"], res["status"], res["predicted_impact"].distance_to(target)
		])
		quit(1)
		return

	# 2. Lejos en aproximacion (Z = -25000, ~5000m antes)
	flight.position.z = -25000.0
	var res_far = BombingAid.calculate(flight, target, false, "BOMBARDEO")
	if res_far["release_now"]:
		print("TEST FAIL: lejos en aproximacion no debio ser release_now=true")
		quit(1)
		return
	if res_far["eta_seconds"] <= 10.0:
		print("TEST FAIL: eta_seconds debio ser > 10s, dio %.1f" % res_far["eta_seconds"])
		quit(1)
		return

	# 3. Fuera de eje lateral (X = 200m)
	flight.position = Vector3(200.0, 1200.0, -28670.5)
	var res_off = BombingAid.calculate(flight, target, false, "BOMBARDEO")
	if res_off["release_now"]:
		print("TEST FAIL: fuera de eje no debio ser release_now=true")
		quit(1)
		return
	if absf(res_off["lateral_error_m"]) < 100.0:
		print("TEST FAIL: lateral_error_m debio ser cercano a 200m, dio %.1f" % res_off["lateral_error_m"])
		quit(1)
		return

	# 4. Blanco ya superado (Z = -30500)
	flight.position = Vector3(0.0, 1200.0, -30500.0)
	var res_past = BombingAid.calculate(flight, target, false, "BOMBARDEO")
	if res_past["release_now"]:
		print("TEST FAIL: blanco superado no debio ser release_now=true")
		quit(1)
		return
	if res_past["status"] != "PASADO":
		print("TEST FAIL: status debio ser PASADO, dio %s" % res_past["status"])
		quit(1)
		return

	# 5. Bomba ya gastada
	var res_spent = BombingAid.calculate(flight, target, true, "BOMBARDEO")
	if res_spent["release_now"] or res_spent["status"] != "BOMBAS_FUERA":
		print("TEST FAIL: bomba gastada debio ser BOMBAS_FUERA y release_now=false")
		quit(1)
		return

	print("TEST PASS: core/bombing_aid.gd cumple todas las especificaciones balisticas y de contrato")
	quit(0)
