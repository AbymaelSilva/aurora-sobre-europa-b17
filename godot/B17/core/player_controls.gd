extends RefCounted

var deadzone: float = 0.15
var pitch_sensitivity: float = 1.0
var turn_sensitivity: float = 1.0
var throttle_sensitivity: float = 1.0
var flight_assist: bool = false
var station: String = "PILOTO"
var aim: Vector2 = Vector2.ZERO
var profile: String = "TECLADO_RATON"
var joy_fire_cooldown: float = 0.0

# Mejora 1: Emergencias de motores y extintores
var selected_engine: int = 0
var last_engine_action: String = ""
var last_engine_action_timer: float = 0.0

# Mejora 2: Múltiples puestos de ametralladoras
var gunner_station: String = "DORSAL" # "DORSAL" | "COLA" | "VENTRAL"

# Mejora 3: Escoltas P-51D con solicitud por radio
var escort_cover_requested: bool = false
var escort_cover_timer: float = 0.0
var escort_cooldown_timer: float = 0.0
const ESCORT_COVER_DURATION: float = 20.0
const ESCORT_COOLDOWN: float = 45.0

func set_station(name: String, sim) -> void:
	if name in ["PILOTO", "ARTILLERO", "BOMBARDERO"]:
		if station == "ARTILLERO" and name == "ARTILLERO":
			cycle_gunner_station()
		else:
			station = name
		if station != "PILOTO" and sim != null:
			apply_flight_input(sim, 0.0, 0.0, 0.0)

func cycle_gunner_station() -> void:
	match gunner_station:
		"DORSAL":
			gunner_station = "COLA"
			aim = Vector2.ZERO
		"COLA":
			gunner_station = "VENTRAL"
			aim = Vector2(0.0, -deg_to_rad(45.0))
		"VENTRAL":
			gunner_station = "DORSAL"
			aim = Vector2.ZERO

func request_escort_cover() -> bool:
	if escort_cooldown_timer <= 0.0:
		escort_cover_requested = true
		escort_cover_timer = ESCORT_COVER_DURATION
		escort_cooldown_timer = ESCORT_COOLDOWN
		return true
	return false

func toggle_autopilot(sim) -> void:
	sim.autopilot = not sim.autopilot
	sim.pitch_input = 0.0
	sim.turn_input = 0.0
	sim.throttle_input = 0.0

func apply_deadzone(stick: Vector2, dz: float) -> Vector2:
	var l: float = stick.length()
	if l <= dz:
		return Vector2.ZERO
	var factor: float = (l - dz) / (1.0 - dz)
	return stick.normalized() * clampf(factor, 0.0, 1.0)

func apply_flight_input(sim, pitch: float, turn: float, throttle: float) -> void:
	sim.pitch_input = clampf(pitch, -1.0, 1.0)
	sim.turn_input = clampf(turn, -1.0, 1.0)
	sim.throttle_input = clampf(throttle, -1.0, 1.0)

func clamp_aim_by_station() -> void:
	match gunner_station:
		"DORSAL":
			aim.y = clampf(aim.y, -deg_to_rad(20.0), deg_to_rad(85.0))
		"COLA":
			aim.x = clampf(aim.x, -deg_to_rad(35.0), deg_to_rad(35.0))
			aim.y = clampf(aim.y, -deg_to_rad(10.0), deg_to_rad(25.0))
		"VENTRAL":
			aim.y = clampf(aim.y, -deg_to_rad(85.0), -deg_to_rad(10.0))

func fire(sim) -> bool:
	var base_yaw: float = sim.flight.yaw
	var turret_pitch: float = clampf(aim.y, -deg_to_rad(20.0), deg_to_rad(85.0))
	if gunner_station == "COLA":
		base_yaw += PI
		turret_pitch = clampf(aim.y, -deg_to_rad(10.0), deg_to_rad(25.0))
	elif gunner_station == "VENTRAL":
		turret_pitch = clampf(aim.y, -deg_to_rad(85.0), -deg_to_rad(10.0))
	var turret_yaw: float = base_yaw + aim.x
	var dir: Vector3 = -Basis.from_euler(Vector3(turret_pitch, turret_yaw, 0.0)).z.normalized()
	var origin: Vector3 = sim.flight.position
	var target: Vector3 = origin + dir * 800.0
	sim.combat.defensive_shots.append({"origin": origin, "target": target})
	for fighter in sim.combat.fighters:
		if fighter["alive"]:
			var to_f: Vector3 = fighter["ai"].position - origin
			if to_f.length() < 900.0 and dir.dot(to_f.normalized()) > 0.92:
				fighter["health"] -= 25.0
				fighter["damage_cause"] = "manual_M2"
				if fighter["health"] <= 0.0:
					fighter["alive"] = false
					sim.combat.damage_events.append({"fighter": sim.combat.fighters.find(fighter), "cause": "manual_M2", "effect": "engine_smoke_lift_loss"})
					fighter["fall_vel"] = fighter["ai"].velocity
					sim.combat.total_kills += 1
				break
	return true

func handle_event(event: InputEvent, sim) -> bool:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_TAB:
			toggle_autopilot(sim)
			return true
		elif event.physical_keycode == KEY_1:
			set_station("PILOTO", sim)
			return true
		elif event.physical_keycode == KEY_2:
			set_station("ARTILLERO", sim)
			return true
		elif event.physical_keycode == KEY_3:
			set_station("BOMBARDERO", sim)
			return true
		elif event.physical_keycode == KEY_Q and station == "ARTILLERO":
			cycle_gunner_station()
			return true
		elif event.physical_keycode == KEY_E and station in ["PILOTO", "ARTILLERO"]:
			request_escort_cover()
			return true
		elif event.physical_keycode in [KEY_F1, KEY_F2, KEY_F3, KEY_F4] and station == "PILOTO":
			var e_idx: int = event.physical_keycode - KEY_F1
			if event.ctrl_pressed or event.shift_pressed:
				sim.damage.use_extinguisher(e_idx)
				last_engine_action = "EXTINTOR M%d" % (e_idx + 1)
				last_engine_action_timer = 2.0
			else:
				sim.damage.feather_engine(e_idx)
				last_engine_action = "EMBANDERADO M%d" % (e_idx + 1)
				last_engine_action_timer = 2.0
			return true
		elif event.physical_keycode == KEY_B or event.physical_keycode == KEY_SPACE:
			if station == "ARTILLERO":
				return fire(sim)
			elif sim.mission.phase == "BOMBARDEO" and not sim.autopilot and not sim.bomb.spent:
				sim.release_bomb()
				return true
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if station == "ARTILLERO":
				return fire(sim)
			elif station == "BOMBARDERO" and sim.mission.phase == "BOMBARDEO" and not sim.autopilot and not sim.bomb.spent:
				sim.release_bomb()
				return true
	elif event is InputEventMouseMotion:
		if station == "ARTILLERO":
			aim.x -= event.relative.x * 0.003
			aim.y -= event.relative.y * 0.003
			clamp_aim_by_station()
			return true
	elif event is InputEventJoypadButton and event.pressed:
		if profile == "TECLADO_RATON":
			return false
		if event.button_index == JOY_BUTTON_BACK or event.button_index == JOY_BUTTON_MISC1:
			toggle_autopilot(sim)
			return true
		elif event.button_index == JOY_BUTTON_DPAD_UP:
			set_station("PILOTO", sim)
			return true
		elif event.button_index == JOY_BUTTON_DPAD_RIGHT:
			set_station("ARTILLERO", sim)
			return true
		elif event.button_index == JOY_BUTTON_DPAD_DOWN:
			if station == "ARTILLERO":
				cycle_gunner_station()
				return true
			else:
				set_station("BOMBARDERO", sim)
				return true
		elif event.button_index == JOY_BUTTON_RIGHT_SHOULDER or event.button_index == JOY_BUTTON_X:
			if station == "ARTILLERO":
				joy_fire_cooldown = 0.12
				return fire(sim)
			elif station == "PILOTO":
				# Extintor o feathering en mando
				if Input.is_joy_button_pressed(0, JOY_BUTTON_LEFT_SHOULDER):
					sim.damage.feather_engine(selected_engine)
					last_engine_action = "EMBANDERADO M%d" % (selected_engine + 1)
					last_engine_action_timer = 2.0
					return true
		elif event.button_index == JOY_BUTTON_Y and station == "PILOTO" and Input.is_joy_button_pressed(0, JOY_BUTTON_LEFT_SHOULDER):
			sim.damage.use_extinguisher(selected_engine)
			last_engine_action = "EXTINTOR M%d" % (selected_engine + 1)
			last_engine_action_timer = 2.0
			return true
		elif event.button_index == JOY_BUTTON_B or event.button_index == JOY_BUTTON_A:
			if station == "ARTILLERO":
				return fire(sim)
			elif sim.mission.phase == "BOMBARDEO" and not sim.autopilot and not sim.bomb.spent:
				sim.release_bomb()
				return true
	return false

func poll_inputs(sim, delta: float, allow_turret_aim: bool = true) -> void:
	if joy_fire_cooldown > 0.0:
		joy_fire_cooldown = maxf(0.0, joy_fire_cooldown - delta)
	if last_engine_action_timer > 0.0:
		last_engine_action_timer = maxf(0.0, last_engine_action_timer - delta)
	if escort_cover_timer > 0.0:
		escort_cover_timer = maxf(0.0, escort_cover_timer - delta)
		if escort_cover_timer <= 0.0:
			escort_cover_requested = false
	if escort_cooldown_timer > 0.0:
		escort_cooldown_timer = maxf(0.0, escort_cooldown_timer - delta)

	if not sim.autopilot:
		if station == "PILOTO":
			var pitch: float = (1.0 if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN) else 0.0) - (1.0 if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP) else 0.0)
			var turn: float = (1.0 if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT) else 0.0) - (1.0 if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT) else 0.0)
			var throttle: float = (1.0 if Input.is_key_pressed(KEY_SHIFT) else 0.0) - (1.0 if Input.is_key_pressed(KEY_CTRL) else 0.0)
			if profile != "TECLADO_RATON":
				var joy_stick := Vector2(Input.get_joy_axis(0, JOY_AXIS_LEFT_X), Input.get_joy_axis(0, JOY_AXIS_LEFT_Y))
				var filtered_stick := apply_deadzone(joy_stick, deadzone)
				if filtered_stick.length_squared() > 0.0:
					turn -= filtered_stick.x
					pitch += filtered_stick.y
				var trigger_rt: float = Input.get_joy_axis(0, JOY_AXIS_TRIGGER_RIGHT)
				var trigger_lt: float = Input.get_joy_axis(0, JOY_AXIS_TRIGGER_LEFT)
				throttle += (trigger_rt - trigger_lt)
			apply_flight_input(sim, pitch * pitch_sensitivity, turn * turn_sensitivity, throttle * throttle_sensitivity)
		else:
			apply_flight_input(sim, 0.0, 0.0, 0.0)

	if station == "ARTILLERO" and allow_turret_aim:
		if profile != "TECLADO_RATON":
			var joy_right := Vector2(Input.get_joy_axis(0, JOY_AXIS_RIGHT_X), Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y))
			var filtered_right := apply_deadzone(joy_right, deadzone)
			if filtered_right.length_squared() > 0.0:
				aim.x += filtered_right.x * delta * 2.5
				aim.y -= filtered_right.y * delta * 2.5
				clamp_aim_by_station()
			if Input.is_joy_button_pressed(0, JOY_BUTTON_RIGHT_SHOULDER) or Input.is_joy_button_pressed(0, JOY_BUTTON_X):
				if joy_fire_cooldown <= 0.0:
					fire(sim)
					joy_fire_cooldown = 0.12
