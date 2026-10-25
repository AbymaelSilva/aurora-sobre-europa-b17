extends SceneTree
# Diagnóstico independiente de usabilidad: cámara actual, bomba real y entradas latentes.
var scene: Node
var report: Dictionary = {}

func _initialize() -> void:
    run.call_deferred()

func horizontal(a: Vector3,b: Vector3) -> float:
    return Vector2(a.x,a.z).distance_to(Vector2(b.x,b.z))

func cast_to_ground(camera: Camera3D) -> Vector3:
    var center: Vector2 = camera.get_viewport().get_visible_rect().size*0.5
    var origin: Vector3 = camera.project_ray_origin(center)
    var direction: Vector3 = camera.project_ray_normal(center)
    return origin+direction*(-origin.y/direction.y)

func fly_bomb() -> Dictionary:
    scene.sim.release_bomb()
    var elapsed: float = 0.0
    while scene.sim.bomb.active and elapsed<60.0:
        scene.sim.bomb.step(1.0/60.0,scene.sim.mission.target,120.0)
        elapsed += 1.0/60.0
    return {"result":scene.sim.bomb.result,"actual_impact":scene.sim.bomb.position,"horizontal_miss_m":horizontal(scene.sim.bomb.position,scene.sim.mission.target),"flight_seconds":elapsed}

func setup_bombardier() -> void:
    scene.restart_mission()
    scene.sim.autopilot = false
    scene.sim.mission.phase = "BOMBARDEO"
    scene.sim.flight.position = Vector3(0,1200,0)
    scene.sim.flight.pitch = 0.0
    scene.sim.flight.yaw = 0.0
    scene.sim.flight.speed = 85.0
    scene.controls.set_station("BOMBARDERO",scene.sim)
    scene.update_presentation(0.0)

func input_transition(station: String,code: int,label: String) -> Dictionary:
    scene.restart_mission()
    scene.sim.autopilot = false
    scene.controls.set_station("PILOTO",scene.sim)
    var event := InputEventKey.new()
    event.keycode = code
    event.physical_keycode = code
    event.pressed = true
    Input.parse_input_event(event)
    Input.flush_buffered_events()
    scene._physics_process(1.0/60.0)
    var latched := Vector3(scene.sim.pitch_input,scene.sim.turn_input,scene.sim.throttle_input)
    var release_event := event.duplicate() as InputEventKey
    release_event.pressed = false
    Input.parse_input_event(release_event)
    Input.flush_buffered_events()
    scene.controls.set_station(station,scene.sim)
    var at_switch := Vector3(scene.sim.pitch_input,scene.sim.turn_input,scene.sim.throttle_input)
    var yaw_before: float = scene.sim.flight.yaw
    var pitch_before: float = scene.sim.flight.pitch
    var speed_before: float = scene.sim.flight.speed
    for frame in range(120):
        scene._physics_process(1.0/60.0)
    return {"station":station,"released_key":label,"input_before_switch":latched,"input_at_switch":at_switch,"input_after_2s":Vector3(scene.sim.pitch_input,scene.sim.turn_input,scene.sim.throttle_input),"yaw_change_rad":scene.sim.flight.yaw-yaw_before,"pitch_change_rad":scene.sim.flight.pitch-pitch_before,"speed_change_mps":scene.sim.flight.speed-speed_before}

func run() -> void:
    root.size = Vector2i(1280,720)
    scene = load("res://game.tscn").instantiate()
    root.add_child(scene)
    scene.set_physics_process(false)
    setup_bombardier()
    var camera: Camera3D = scene.get_node("Camera3D")
    var initial: Vector3 = scene.sim.flight.position
    var center_ground: Vector3 = cast_to_ground(camera)
    var velocity: Vector3 = -Basis.from_euler(Vector3(scene.sim.flight.pitch,scene.sim.flight.yaw,0)).z*scene.sim.flight.speed
    var falltime: float = (velocity.y+sqrt(velocity.y*velocity.y+19.62*initial.y))/9.81
    var prediction: Vector3 = initial+velocity*falltime
    prediction.y = 0.0
    report["geometry"] = {"altitude_m":initial.y,"speed_mps":scene.sim.flight.speed,"camera_position":camera.global_position,"camera_direction":-camera.global_transform.basis.z,"crosshair_ground_point":center_ground,"crosshair_ground_lead_m":horizontal(initial,center_ground),"analytic_fall_seconds":falltime,"analytic_bomb_lead_m":horizontal(initial,prediction),"ground_discrepancy_m":horizontal(center_ground,prediction),"target_radius_m":120.0}
    var target: Vector3 = scene.sim.mission.target
    var shift: Vector3 = target-center_ground
    shift.y = 0.0
    scene.sim.flight.position += shift
    scene.update_presentation(0.0)
    report["release_when_target_centered"] = fly_bomb()
    setup_bombardier()
    scene.sim.flight.position = Vector3(target.x,1200.0,target.z+horizontal(initial,prediction))
    scene.update_presentation(0.0)
    var screen: Vector2 = camera.unproject_position(target)
    var viewport: Rect2 = camera.get_viewport().get_visible_rect()
    report["release_at_ballistic_solution"] = {"target_screen_position":screen,"viewport":viewport,"target_inside_viewport":viewport.has_point(screen),"actual_bomb":fly_bomb(),"overlay_data_keys":scene.overlay.data.keys()}
    var transitions: Array = []
    for station in ["BOMBARDERO","ARTILLERO"]:
        for entry in [[KEY_D,"D"],[KEY_S,"S"],[KEY_SHIFT,"SHIFT"]]:
            transitions.append(input_transition(station,entry[0],entry[1]))
    report["station_transitions"] = transitions
    print(JSON.stringify(report,"  "))
    for audio in [scene.engine_audio,scene.gun_audio,scene.flak_audio,scene.bomb_audio]:
        audio.stop()
        audio.stream = null
    root.remove_child(scene)
    scene.free()
    scene = null
    for frame in range(6):
        await process_frame
        await physics_frame
    print("DIAGNOSTIC COMPLETE: manual bombing geometry and station transitions; not a human playtest")
    quit(0)
