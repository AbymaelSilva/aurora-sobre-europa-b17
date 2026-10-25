extends RefCounted

var flight = preload("res://core/flight.gd").new()
var damage = preload("res://core/damage.gd").new()
var mission = preload("res://core/mission.gd").new()
var bomb = preload("res://bomb_model.gd").new()
var flak = preload("res://flak_model.gd").new()
var combat = preload("res://core/combat_manager.gd").new()

var paused: bool = false
var autopilot: bool = true
var last_flak_burst: bool = false
var flak_damage: float = 1.1
var pitch_input: float = 0
var turn_input: float = 0
var throttle_input: float = 0

func _init():
    pass

func reset():
    flight.reset()
    damage.reset()
    mission.reset()
    bomb.reset()
    flak.reset()
    combat.reset()
    paused = false
    last_flak_burst = false
    pitch_input = 0
    turn_input = 0
    throttle_input = 0

func release_bomb() -> bool:
    if mission.phase != "BOMBARDEO":
        return false
    return bomb.release(flight.position, -Basis.from_euler(Vector3(flight.pitch, flight.yaw, 0)).z * flight.speed)

func step(delta: float):
    last_flak_burst = false
    if paused or mission.phase in ["COMPLETADA", "FALLIDA"]:
        return
    delta = clampf(delta, 0, 0.05)
    mission.step(delta, flight.position, bomb.result, damage.destroyed())
    if mission.phase in ["COMPLETADA", "FALLIDA"]:
        return

    combat.step(delta, flight.position, flight.yaw, mission.phase, damage)

    # Cálculo de empuje asimétrico para turn_bias en flight
    var port_thrust: float = (damage.engines[0] * (0.0 if damage.engine_feathered[0] else 1.0) + damage.engines[1] * (0.0 if damage.engine_feathered[1] else 1.0)) / 200.0
    var stbd_thrust: float = (damage.engines[2] * (0.0 if damage.engine_feathered[2] else 1.0) + damage.engines[3] * (0.0 if damage.engine_feathered[3] else 1.0)) / 200.0
    flight.turn_bias = clampf((port_thrust - stbd_thrust) * 0.12, -0.12, 0.12)

    var pitch: float = pitch_input
    var turn: float = turn_input
    var throttle: float = throttle_input

    if autopilot:
        var offset: Vector3 = mission.navigation_target() - flight.position
        var desired_yaw: float = atan2(-offset.x, -offset.z)
        turn = clampf(wrapf(desired_yaw - flight.yaw, -PI, PI) / deg_to_rad(25), -1, 1)
        pitch = clampf((1200 - flight.position.y) / 80, -1, 1)
        throttle = 0

        flight.speed = move_toward(flight.speed, 85 * damage.thrust_factor(), delta * 2)
    flight.step(pitch, turn, throttle, delta)

    var in_zone: bool = flight.position.z < -13000 and flight.position.z > -26500 and abs(flight.position.x) < 1000
    last_flak_burst = flak.step(delta, in_zone)

    if last_flak_burst:
        damage.apply_instrument_damage(flak.last_burst_proximity)
        if flak.bursts % 3 != 0:
            damage.apply_damage(flak_damage, flak.bursts % 4)
    damage.step_instruments(delta)

    if mission.phase == "BOMBARDEO" and autopilot and not bomb.spent and not damage.norden_disabled:
        var velocity: Vector3 = -Basis.from_euler(Vector3(flight.pitch, flight.yaw, 0)).z * flight.speed
        var falltime: float = (velocity.y + sqrt(velocity.y * velocity.y + 19.62 * flight.position.y)) / 9.81
        var predicted: Vector3 = flight.position + velocity * falltime
        var horizontal_distance: float = Vector2(predicted.x, predicted.z).distance_to(Vector2(mission.target.x, mission.target.z))
        if horizontal_distance < 45:
            release_bomb()

    bomb.step(delta, mission.target, 120)
    mission.step(0, flight.position, bomb.result, damage.destroyed())
