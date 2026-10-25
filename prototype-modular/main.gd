extends Node3D

var flight = preload("res://flight_model.gd").new()
var paused: bool = false

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
        if event.physical_keycode == KEY_ESCAPE:
            paused = !paused
        elif event.physical_keycode == KEY_R:
            flight.reset()

func _physics_process(delta: float) -> void:
    var pitch: float = 0.0
    var turn: float = 0.0
    var throttle: float = 0.0

    if Input.is_physical_key_pressed(KEY_W):
        pitch += 1.0
    if Input.is_physical_key_pressed(KEY_S):
        pitch -= 1.0
    if Input.is_physical_key_pressed(KEY_A):
        turn -= 1.0
    if Input.is_physical_key_pressed(KEY_D):
        turn += 1.0
    if Input.is_physical_key_pressed(KEY_UP):
        throttle += 1.0
    if Input.is_physical_key_pressed(KEY_DOWN):
        throttle -= 1.0

    var joypads: Array[int] = Input.get_connected_joypads()
    var joypad_id: int = joypads[0] if not joypads.is_empty() else -1
    if joypad_id != -1:
        var deadzone: float = 0.15
        var left_x: float = Input.get_joy_axis(joypad_id, JOY_AXIS_LEFT_X)
        var left_y: float = -Input.get_joy_axis(joypad_id, JOY_AXIS_LEFT_Y)
        if abs(left_x) > deadzone:
            turn = left_x
        if abs(left_y) > deadzone:
            pitch = left_y

    if not paused:
        flight.step(pitch, turn, throttle, delta)

    $Aircraft.position = flight.position
    $Aircraft.rotation = Vector3(flight.pitch, flight.yaw, 0)

    $Camera3D.global_position = flight.position + Vector3(0, 8, 25).rotated(Vector3.UP, flight.yaw)
    $Camera3D.look_at(flight.position + Vector3.UP, Vector3.UP)

    $HUD.update_hud(flight.speed, flight.position.y, paused)
