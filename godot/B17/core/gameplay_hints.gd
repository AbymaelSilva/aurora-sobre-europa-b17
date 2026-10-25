extends RefCounted

static func nearest_threat(fighters: Array, player_position: Vector3, player_yaw: float) -> Dictionary:
	var nearest: Dictionary = {"active": false, "label": ""}
	var best: float = 1500.0
	for fighter in fighters:
		if not bool(fighter.get("alive", false)) or float(fighter.get("health", 1.0)) <= 0.0:
			continue
		var ai = fighter.get("ai")
		if ai == null or not is_instance_valid(ai): continue
		var relative: Vector3 = ai.position - player_position
		var distance: float = relative.length()
		if distance > best: continue
		best = distance
		var local: Vector3 = relative.rotated(Vector3.UP, -player_yaw)
		var direction: float = atan2(local.x, -local.z)
		var clock: int = posmod(roundi(direction * 6.0 / PI), 12)
		if clock == 0: clock = 12
		var height: String = "ALTO" if relative.y > 50.0 else ("BAJO" if relative.y < -50.0 else "A NIVEL")
		var rounded_distance: int = maxi(50, roundi(distance / 50.0) * 50)
		nearest = {"active": true, "clock": clock, "height": height, "distance_m": distance,
			"label": "CAZA · %d EN PUNTO · %s · %d m" % [clock, height, rounded_distance]}
	return nearest

static func immediate_objective(phase: String, station: String, autopilot: bool,
		bomb_spent: bool, bomb_active: bool, release_now: bool) -> String:
	if phase in ["COMPLETADA", "FALLIDA"]:
		return "Consulta el resultado y reinicia cuando estés listo."
	if phase == "BOMBARDEO":
		if bomb_spent or bomb_active:
			return "Observa el resultado de la salva y vigila los cazas."
		if station == "ARTILLERO":
			return "Cubre a la formación durante la pasada de bombardeo."
		if autopilot:
			return "Suelta automática preparada: vigila la pasada o cubre un sector."
		if station == "BOMBARDERO":
			return "¡Suelta las bombas ahora!" if release_now else "Alinea la mira y espera la ventana de suelta."
		return "Mantén rumbo y altura estables durante la pasada."
	if station == "ARTILLERO":
		return "Vigila la cola y protege el regreso." if phase == "REGRESO" else "Vigila los sectores y protege a la formación."
	if phase == "REGRESO":
		return "Autopiloto rumbo a casa: mantén la vigilancia." if autopilot else "Sigue el rumbo de regreso y mantén el vuelo estable."
	if station == "BOMBARDERO":
		return "Localiza el nudo ferroviario y prepara la pasada."
	if phase == "APROXIMACION":
		return "Vigila los cazas o cambia al puesto de artillero." if autopilot else "Sigue el rumbo al objetivo y conserva la altura."
	return "Autopiloto activo: observa la formación o cambia de puesto." if autopilot else "Mantén rumbo y altura junto a la formación."
