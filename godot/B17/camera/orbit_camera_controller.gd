# camera/orbit_camera_controller.gd
# Controlador de cámara exterior orbital y seguimiento de aeronaves (Lote 8)
class_name OrbitCameraController extends RefCounted

enum Mode {
	SEGUIMIENTO_PROPIO,
	ORBITA_PROPIA,
	OBSERVAR_AVION
}

const MIN_DISTANCE: float = 45.0
const MAX_DISTANCE: float = 320.0
const DEFAULT_DISTANCE: float = 115.0
const MIN_PITCH: float = -0.4363323   # -25° en radianes
const MAX_PITCH: float = 1.22173      # +70° en radianes
const DEFAULT_PITCH: float = 0.2094395 # +12° en radianes
const YAW_SPEED: float = 1.74533      # 100°/s en radianes
const PITCH_SPEED: float = 1.22173    # 70°/s en radianes
const ZOOM_SPEED_JOY: float = 60.0    # 60 m/s
const ZOOM_STEP_WHEEL: float = 10.0   # 10 m por paso de rueda
const DEADZONE_RADIAL: float = 0.18

var is_exterior: bool = false
var mode: Mode = Mode.SEGUIMIENTO_PROPIO
var target_node: Node3D = null
var target_name: String = "Aurora Uno"
var target_index: int = 0
var observation_message: String = ""

# Estado orbital suavizado
var current_yaw: float = 0.0
var current_pitch: float = DEFAULT_PITCH
var current_distance: float = DEFAULT_DISTANCE

# Objetivos de interpolación
var target_yaw: float = 0.0
var target_pitch: float = DEFAULT_PITCH
var target_distance: float = DEFAULT_DISTANCE

# Estado de arrastre y botones
var rmb_dragging: bool = false
var lb_held: bool = false

# Lista de objetivos registrados: Array de Dictionaries { "node": Node3D, "name": String }
var target_list: Array[Dictionary] = []

func setup(player_node: Node3D, wingmen_nodes: Array, escort_nodes: Array) -> void:
	target_list.clear()
	# 0: Avión del jugador
	target_list.append({"node": player_node, "name": "Aurora Uno"})
	
	# 1..5: Compañeros de la escuadrilla
	var wing_names: Array[String] = ["Aurora Dos", "Aurora Tres", "Aurora Cuatro", "Aurora Cinco", "Aurora Seis"]
	for i in range(wingmen_nodes.size()):
		var w_node: Node3D = wingmen_nodes[i] as Node3D
		var w_name: String = wing_names[i] if i < wing_names.size() else ("Aurora %d" % (i + 2))
		target_list.append({"node": w_node, "name": w_name})
	
	# 6..N: Escoltas P-51
	for i in range(escort_nodes.size()):
		var esc_node: Node3D = escort_nodes[i] as Node3D
		target_list.append({"node": esc_node, "name": "Escolta P-51 #%d" % (i + 1)})
	
	target_index = 0
	target_node = player_node
	target_name = "Aurora Uno"

func set_exterior(active: bool, sim) -> void:
	if is_exterior == active:
		return
	is_exterior = active
	rmb_dragging = false
	if is_exterior:
		# Al pasar a exterior, inicializar yaw al rumbo del avión observado
		var base_yaw: float = _get_target_yaw()
		target_yaw = base_yaw
		current_yaw = base_yaw
		target_pitch = DEFAULT_PITCH
		current_pitch = DEFAULT_PITCH
		target_distance = clampf(current_distance, MIN_DISTANCE, MAX_DISTANCE)
		if target_index == 0:
			mode = Mode.SEGUIMIENTO_PROPIO
		else:
			mode = Mode.OBSERVAR_AVION
			_activate_autopilot_on_observation(sim)
	else:
		mode = Mode.SEGUIMIENTO_PROPIO
		observation_message = ""

func toggle_exterior(sim) -> bool:
	set_exterior(not is_exterior, sim)
	return is_exterior

func center_camera() -> void:
	var base_yaw: float = _get_target_yaw()
	target_yaw = base_yaw
	target_pitch = DEFAULT_PITCH
	if target_index == 0:
		mode = Mode.SEGUIMIENTO_PROPIO

func reset() -> void:
	is_exterior = false
	mode = Mode.SEGUIMIENTO_PROPIO
	target_index = 0
	if not target_list.is_empty():
		target_node = target_list[0].get("node") as Node3D
	target_name = "Aurora Uno"
	observation_message = ""
	current_yaw = 0.0
	target_yaw = 0.0
	current_pitch = DEFAULT_PITCH
	target_pitch = DEFAULT_PITCH
	current_distance = DEFAULT_DISTANCE
	target_distance = DEFAULT_DISTANCE
	lb_held = false
	reset_drag()

func cycle_target(direction: int, sim) -> void:
	if target_list.is_empty():
		return
	_validate_targets()
	for _attempt in range(target_list.size()):
		target_index = posmod(target_index + direction, target_list.size())
		if is_instance_valid(target_list[target_index].get("node")):
			break
	
	_apply_target_selection(sim)

func set_target_index(idx: int, sim) -> void:
	if target_list.is_empty():
		return
	_validate_targets()
	target_index = clampi(idx, 0, target_list.size() - 1)
	_apply_target_selection(sim)

func _apply_target_selection(sim) -> void:
	var entry: Dictionary = target_list[target_index]
	target_node = entry.get("node") as Node3D
	target_name = entry.get("name", "Avión") as String
	
	if target_index == 0:
		if is_exterior:
			mode = Mode.SEGUIMIENTO_PROPIO
		observation_message = ""
	else:
		mode = Mode.OBSERVAR_AVION
		is_exterior = true
		_activate_autopilot_on_observation(sim)
	
	# Centrar suavemente detrás del nuevo objetivo
	var base_yaw: float = _get_target_yaw()
	target_yaw = base_yaw
	target_pitch = DEFAULT_PITCH

func _activate_autopilot_on_observation(sim) -> void:
	if sim != null and not sim.autopilot:
		sim.autopilot = true
		sim.pitch_input = 0.0
		sim.turn_input = 0.0
		sim.throttle_input = 0.0
	observation_message = "PILOTO AUTOMÁTICO · OBSERVANDO %s" % target_name.to_upper()

func _validate_targets() -> void:
	if target_list.is_empty():
		target_node = null
		return
	if target_index >= target_list.size():
		target_index = 0
	var cur: Dictionary = target_list[target_index]
	var node = cur.get("node")
	if not is_instance_valid(node):
		# Revalidar objetivo eliminado y volver al avión propio sin referencias inválidas
		target_index = 0
		target_node = target_list[0].get("node") as Node3D
		target_name = "Aurora Uno"
		mode = Mode.SEGUIMIENTO_PROPIO
		observation_message = ""

func _get_target_yaw() -> float:
	_validate_targets()
	if target_node != null and is_instance_valid(target_node):
		return target_node.rotation.y
	return 0.0

func _get_target_position() -> Vector3:
	_validate_targets()
	if target_node != null and is_instance_valid(target_node):
		if target_node.is_inside_tree():
			return target_node.global_position
		return target_node.position
	return Vector3.ZERO

func handle_input(event: InputEvent, sim, profile: String) -> bool:
	# Teclado y ratón
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_V or event.keycode == KEY_V:
			toggle_exterior(sim)
			return true
		elif is_exterior and (event.physical_keycode == KEY_C or event.keycode == KEY_C):
			center_camera()
			return true
		elif is_exterior and (event.physical_keycode == KEY_BRACKETLEFT or event.keycode == KEY_BRACKETLEFT):
			cycle_target(-1, sim)
			return true
		elif is_exterior and (event.physical_keycode == KEY_BRACKETRIGHT or event.keycode == KEY_BRACKETRIGHT):
			cycle_target(1, sim)
			return true
	
	elif event is InputEventMouseButton:
		if is_exterior:
			if event.button_index == MOUSE_BUTTON_RIGHT:
				rmb_dragging = event.pressed
				return true
			elif event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
				target_distance = clampf(target_distance - ZOOM_STEP_WHEEL, MIN_DISTANCE, MAX_DISTANCE)
				return true
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
				target_distance = clampf(target_distance + ZOOM_STEP_WHEEL, MIN_DISTANCE, MAX_DISTANCE)
				return true
	
	elif event is InputEventMouseMotion:
		if is_exterior and rmb_dragging:
			# Arrastre del ratón orbita
			target_yaw -= event.relative.x * 0.005
			target_pitch = clampf(target_pitch - event.relative.y * 0.005, MIN_PITCH, MAX_PITCH)
			if target_index == 0:
				mode = Mode.ORBITA_PROPIA
			return true
		if is_exterior:
			return true # El ratón de cámara no mueve la torreta del puesto.
	
	# Mando / ROG Ally X
	elif event is InputEventJoypadButton:
		if profile == "TECLADO_RATON":
			return false
		if event.button_index == JOY_BUTTON_LEFT_SHOULDER:
			lb_held = event.pressed
			return false # Dejar que pase para estado interno
		
		if event.pressed:
			if event.button_index == JOY_BUTTON_Y:
				toggle_exterior(sim)
				return true
			
			if is_exterior and event.button_index == JOY_BUTTON_RIGHT_STICK:
				center_camera()
				return true
			
			# Combinaciones con LB (deben consumirse antes del cambio de puesto)
			if lb_held:
				if event.button_index == JOY_BUTTON_DPAD_LEFT:
					cycle_target(-1, sim)
					return true
				elif event.button_index == JOY_BUTTON_DPAD_RIGHT:
					cycle_target(1, sim)
					return true
				elif event.button_index == JOY_BUTTON_DPAD_UP or event.button_index == JOY_BUTTON_DPAD_DOWN:
					# Consumir para zoom continuo en poll_inputs
					return true
	
	return false

func poll_input(delta: float, profile: String) -> void:
	if not is_exterior:
		return
	
	# Mando joypad
	if profile != "TECLADO_RATON":
		lb_held = Input.is_joy_button_pressed(0, JOY_BUTTON_LEFT_SHOULDER)
		
		# Zoom con LB + cruceta arriba / abajo a 60 m/s
		if lb_held:
			if Input.is_joy_button_pressed(0, JOY_BUTTON_DPAD_UP):
				target_distance = clampf(target_distance - ZOOM_SPEED_JOY * delta, MIN_DISTANCE, MAX_DISTANCE)
			elif Input.is_joy_button_pressed(0, JOY_BUTTON_DPAD_DOWN):
				target_distance = clampf(target_distance + ZOOM_SPEED_JOY * delta, MIN_DISTANCE, MAX_DISTANCE)
		
		# Stick derecho para órbita con zona muerta radial 0.18
		var joy_rx: float = Input.get_joy_axis(0, JOY_AXIS_RIGHT_X)
		var joy_ry: float = Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y)
		var stick := Vector2(joy_rx, joy_ry)
		var stick_len: float = stick.length()
		
		if stick_len > DEADZONE_RADIAL:
			var factor: float = (stick_len - DEADZONE_RADIAL) / (1.0 - DEADZONE_RADIAL)
			var filtered: Vector2 = stick.normalized() * clampf(factor, 0.0, 1.0)
			
			# Yaw libre hasta 100°/s y pitch hasta 70°/s multiplicado por delta
			target_yaw -= filtered.x * YAW_SPEED * delta
			target_pitch = clampf(target_pitch - filtered.y * PITCH_SPEED * delta, MIN_PITCH, MAX_PITCH)
			if target_index == 0:
				mode = Mode.ORBITA_PROPIA

func reset_drag() -> void:
	rmb_dragging = false
	lb_held = false

func update(delta: float, cam: Camera3D, flight_yaw: float) -> void:
	if not is_exterior:
		return
	
	_validate_targets()
	
	# Si estamos en SEGUIMIENTO_PROPIO y el usuario no está orbitando activamente,
	# el target_yaw sigue el rumbo del avión
	if mode == Mode.SEGUIMIENTO_PROPIO and not rmb_dragging:
		target_yaw = flight_yaw
	
	# Suavizado exponencial con 1.0 - exp(-8.0 * delta)
	var smooth_factor: float = 1.0 - exp(-8.0 * maxf(delta, 0.0))
	
	# Interpolación de ángulo correcta evitando la vuelta larga
	current_yaw = lerp_angle(current_yaw, target_yaw, smooth_factor)
	current_pitch = lerpf(current_pitch, target_pitch, smooth_factor)
	current_distance = lerpf(current_distance, target_distance, smooth_factor)
	
	var target_pos: Vector3 = _get_target_position()
	
	# Cálculo de posición orbital:
	# El yaw 0 sitúa la cámara detrás del avión (+Z respecto al rumbo)
	# pitch positivo eleva la cámara por encima (+Y)
	var cos_p: float = cos(current_pitch)
	var sin_p: float = sin(current_pitch)
	var sin_y: float = sin(current_yaw)
	var cos_y: float = cos(current_yaw)
	
	var offset := Vector3(
		sin_y * cos_p * current_distance,
		sin_p * current_distance,
		cos_y * cos_p * current_distance
	)
	
	var desired_cam_pos: Vector3 = target_pos + offset
	if cam.is_inside_tree():
		cam.global_position = desired_cam_pos
	else:
		cam.position = desired_cam_pos
	
	# Look at hacia el objetivo con margen seguro para evitar vector nulo
	var look_target: Vector3 = target_pos + Vector3(0.0, 2.0, 0.0) # Apuntar ligeramente sobre el centro
	var cam_pos: Vector3 = cam.global_position if cam.is_inside_tree() else cam.position
	if cam_pos.distance_to(look_target) > 0.1:
		if cam.is_inside_tree():
			cam.look_at(look_target, Vector3.UP)
		else:
			cam.look_at_from_position(cam_pos, look_target, Vector3.UP)
