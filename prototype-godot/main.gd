extends Node3D

var flight_model: FlightModel = preload("res://flight_model.gd").new()
var paused: bool = false
var camera: Camera3D
var label: Label

func _ready() -> void:
    var plane = Spatial.new()
    add_child(plane)

    var fuselage = MeshInstance3D.new()
    fuselage.mesh = BoxMesh.new()
    fuselage.mesh.scale = Vector3(10, 20, 1)
    fuselage.material_override = StandardMaterial3D.new()
    fuselage.material_override.albedo_color = Color(0.5, 0.5, 1)
    plane.add_child(fuselage)

    var wings = MeshInstance3D.new()
    wings.mesh = BoxMesh.new()
    wings.mesh.scale = Vector3(20, 2, 1)
    wings.material_override = StandardMaterial3D.new()
    wings.material_override.albedo_color = Color(0.5, 0.5, 1)
    wings.rotation = Vector3(0, 0, 0.5)
    plane.add_child(wings)

    var tail = MeshInstance3D.new()
    tail.mesh = BoxMesh.new()
    tail.mesh.scale = Vector3(2, 2, 10)
    tail.material_override = StandardMaterial3D.new()
    tail.material_override.albedo_color = Color(0.5, 0.5, 1)
    tail.rotation = Vector3(0, 0, -0.5)
    plane.add_child(tail)

    var ground = MeshInstance3D.new()
    ground.mesh = PlaneMesh.new()
    ground.mesh.size = Vector2(3000, 3000)
    ground.material_override = StandardMaterial3D.new()
    ground.material_override.albedo_color = Color(0.5, 0.5, 0.5)
    add_child(ground)

    var light = DirectionalLight3D.new()
    light.rotation = Vector3(-0.5, -0.5, 0)
    light.energy = 2
    add_child(light)

    var environment = WorldEnvironment.new()
    environment.background_color = Color(0.7, 0.9, 1)
    environment.ambient_light = Color(0.2, 0.2, 0.2)
    add_child(environment)

    camera = Camera3D.new()
    camera.rotation = Vector3(-0.5, 0, 0)
    camera.position = Vector3(0, 150, 100)
    add_child(camera)

    label = Label.new()
    label.text = "W/S: Pitch, A/D: Turn, Arrow Up/Down: Throttle\nSpeed: 0, Altitude: 0"
    label.rect_position = Vector2(10, 10)
    add_child(label)

func _input(event: InputEvent) -> void:
    if event is InputEventKey:
        if event.pressed:
            if event.scancode == KEY_ESCAPE:
                paused = !paused
            elif event.scancode == KEY_R:
                reset()
    elif event is InputEventJoypadMotion:
        if event.axis == JOYPAD_AXIS_LEFT_STICK_X:
            var turn_input = event.value
            if abs(turn_input) < 0.15:
                turn_input = 0
        elif event.axis == JOYPAD_AXIS_LEFT_STICK_Y:
            var pitch_input = event.value
            if abs(pitch_input) < 0.15:
                pitch_input = 0
        elif event.axis == JOYPAD_AXIS_RIGHT_STICK_Y:
            var throttle_input = event.value
            if abs(throttle_input) < 0.15:
                throttle_input = 0
        step(pitch_input, turn_input, throttle_input, get_process_delta())

func _physics_process(delta: float) -> void:
    if not paused:
        var pitch_input = Input.get_action_strength("ui_up") - Input.get_action_strength("ui_down")
        var turn_input = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
        var throttle_input = Input.get_action_strength("ui_accept")
        step(pitch_input, turn_input, throttle_input, delta)
        plane.rotation = Vector3(pitch, yaw, 0)
        plane.translation = position
        label.text = "Speed: {speed:.2f}, Altitude: {position.y:.2f}"

func reset() -> void:
    flight_model.reset()
    position = Vector3(0, 100, 0)
    yaw = 0
    pitch = 0
    speed = 50
    plane.rotation = Vector3(pitch, yaw, 0)
    plane.translation = position
    label.text = "Speed: 0, Altitude: 0"