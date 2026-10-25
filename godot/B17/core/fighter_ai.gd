extends RefCounted
# Continuous oval passes in the bomber's moving frame. Tangent determines attitude;
# no state transition changes position, heading or speed discontinuously.
const Config = preload("res://core/combat_config.gd")
var position := Vector3.ZERO
var velocity := Vector3.ZERO
var state := "APPROACH"
var timer := 0.0
var speed := 150.0
var side := 1.0
var profile := "FRONTAL"
var lane := 0
var group := 0
var delay := 0.0
var heading := 0.0
var previous_bomber := Vector3.ZERO
var phase := 0.0
var bank := 0.0

func offset_at(t: float) -> Vector3:
	var height := 60.0 + float(lane) * 20.0
	var clearance := 120.0 + float(lane) * 12.0
	var p := Vector3(side * (clearance + 800.0 * (1.0 - sin(t))), height + 350.0 * (1.0 - sin(t)), -1250.0 * cos(t))
	if profile == "COLA":
		p.z = -p.z
		p.y = -120.0 - float(lane) * 18.0 - 350.0 * (1.0 - sin(t))
	elif profile == "LATERAL":
		p = Vector3(side * 1450.0 * cos(t), 180.0 + float(lane) * 13.0, -120.0 - float(lane) * 13.0 - 80.0 * (1.0 - sin(t)))
	return p.rotated(Vector3.UP, heading)

func setup(start: Vector3, attack_side: float = 1.0, attack_profile: String = "FRONTAL", attack_lane: int = 0) -> void:
	position = start
	# 0.0 no es un lado valido (el juego real siempre pasa -1.0 o 1.0); se
	# trata como "sin lado explicito" y cae al lado derecho por defecto.
	side = attack_side if attack_side != 0.0 else 1.0
	profile = attack_profile
	lane = attack_lane
	state = "APPROACH"
	timer = 0.0

func start_pass(bomber: Vector3, yaw: float, group_index: int) -> void:
	heading = yaw
	group = group_index
	delay = float(group_index) * Config.GROUP_STAGGER
	previous_bomber = bomber
	phase = -delay * TAU / Config.PASS_PERIOD
	position = bomber + offset_at(phase)

func step(delta: float, bomber_pos: Vector3) -> void:
	if delta <= 0.0: return
	delta = minf(delta, 0.05)
	timer += delta
	var old := position
	var old_velocity := velocity
	phase = (timer - delay) * TAU / Config.PASS_PERIOD
	position = bomber_pos + offset_at(phase)
	velocity = (position - old) / delta
	speed = velocity.length()
	if old_velocity.length_squared() > 1.0 and velocity.length_squared() > 1.0:
		var turn_rate := old_velocity.normalized().signed_angle_to(velocity.normalized(), Vector3.UP) / delta
		bank = lerpf(bank, clampf(-atan(turn_rate * speed / 9.81), -0.65, 0.65), minf(delta * 2.0, 1.0))
	previous_bomber = bomber_pos
	var cycle := fposmod(timer - delay, Config.PASS_PERIOD)
	var crossing := Config.PASS_PERIOD * 0.25
	if timer < delay or cycle < crossing - 2.55:
		state = "APPROACH"
	elif cycle < crossing - 0.85:
		state = "ATTACK"
	elif cycle < crossing + 5.0:
		state = "BREAK"
	else:
		state = "REPOSITION"

func is_attacking() -> bool:
	return state == "ATTACK"
