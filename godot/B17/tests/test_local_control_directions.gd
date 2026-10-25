extends SceneTree
# Revisor independiente: H05/H06 con teclado sintético y vectores físicos/cámara reales.
# No modifica producción ni prueba de Claude. No representa una sesión humana.
var failures: PackedStringArray = []
var scene: Node

func _initialize() -> void:
    run.call_deferred()

func check(condition: bool, message: String) -> void:
    if not condition:
        failures.append(message)
        print("FAIL: ",message)

func press(code: int, down: bool) -> void:
    var event := InputEventKey.new()
    event.keycode = code
    event.physical_keycode = code
    event.pressed = down
    Input.parse_input_event(event)
    Input.flush_buffered_events()

func check_turns() -> void:
    for start_yaw in [0.0,0.8]:
        for entry in [[KEY_D,1.0,"D"],[KEY_A,-1.0,"A"],[KEY_RIGHT,1.0,"RIGHT"],[KEY_LEFT,-1.0,"LEFT"]]:
            scene.restart_mission()
            scene.controls.set_station("PILOTO",scene.sim)
            scene.sim.autopilot = false
            scene.sim.flight.yaw = start_yaw
            scene.update_presentation(0.0)
            var origin: Vector3 = scene.sim.flight.position
            var heading_before: float = float(scene.overlay.data.get("heading",0.0))
            var forward_before: Vector3 = -Basis.from_euler(Vector3(0,start_yaw,0)).z
            var right_before: Vector3 = forward_before.cross(Vector3.UP)
            press(int(entry[0]),true)
            for frame in range(180):
                scene._physics_process(1.0/60.0)
            press(int(entry[0]),false)
            var position_delta: Vector3 = scene.sim.flight.position-origin
            var forward_after: Vector3 = -Basis.from_euler(Vector3(0,scene.sim.flight.yaw,0)).z
            var lateral: float = position_delta.dot(right_before)
            var forward_lateral: float = forward_after.dot(right_before)
            var heading_after: float = float(scene.overlay.data.get("heading",0.0))
            var heading_delta: float = wrapf(deg_to_rad(heading_after-heading_before),-PI,PI)
            var side: float = float(entry[1])
            var label: String = "%s yaw0=%.2f" % [entry[2],start_yaw]
            print("H06 %s displacement_right=%.2fm forward_right=%.3f compass_delta=%.2fdeg" % [label,lateral,forward_lateral,rad_to_deg(heading_delta)])
            check(lateral*side>1.0,label+" moves toward intended side")
            check(forward_lateral*side>0.02,label+" nose turns toward intended side")
            check(heading_delta*side>deg_to_rad(1.0),label+" compass agrees with physical turn")

func check_gun_direction() -> void:
    scene.restart_mission()
    scene.controls.set_station("ARTILLERO",scene.sim)
    scene.sim.autopilot = false
    var worst: float = 0.0
    var cases: int = 0
    for yaw in [0.0,0.8,-0.8,2.4]:
        for aim_x in [-0.6,0.0,0.6]:
            for aim_y in [-0.85,-0.35,0.0,0.35,0.85]:
                scene.sim.flight.yaw = yaw
                scene.controls.aim = Vector2(aim_x,aim_y)
                scene.sim.combat.defensive_shots.clear()
                scene.update_presentation(0.0)
                var camera_direction: Vector3 = -scene.get_node("Camera3D").global_transform.basis.z.normalized()
                var fired: bool = scene.controls.fire(scene.sim)
                check(fired,"manual fire accepted in artillero station")
                check(not scene.sim.combat.defensive_shots.is_empty(),"manual fire creates a real defensive shot")
                if scene.sim.combat.defensive_shots.is_empty():
                    continue
                var shot: Dictionary = scene.sim.combat.defensive_shots[-1]
                var shot_direction: Vector3 = (Vector3(shot["target"])-Vector3(shot["origin"])).normalized()
                var angle: float = rad_to_deg(camera_direction.angle_to(shot_direction))
                check(is_finite(angle),"manual shot/camera angle is finite")
                worst = maxf(worst,angle)
                cases += 1
                check(angle<=1.5,"H05 yaw=%.2f aim=(%.2f,%.2f) shot deviates %.2fdeg from camera" % [yaw,aim_x,aim_y,angle])
    print("H05 cases=%d worst_camera_shot_angle=%.3fdeg limit=1.5deg" % [cases,worst])
    check(cases==60,"all yaw/aim/pitch-boundary cases executed")

func run() -> void:
    var packed := load("res://game.tscn") as PackedScene
    check(packed!=null,"active scene loads")
    if packed==null:
        finish()
        return
    scene = packed.instantiate()
    root.add_child(scene)
    scene.set_physics_process(false)
    check_turns()
    check_gun_direction()
    for code in [KEY_D,KEY_A,KEY_RIGHT,KEY_LEFT]:
        press(code,false)
    for player in [scene.engine_audio,scene.gun_audio,scene.flak_audio,scene.bomb_audio]:
        if is_instance_valid(player):
            player.stop()
            player.stream = null
    root.remove_child(scene)
    scene.free()
    scene = null
    for frame in range(6):
        await process_frame
        await physics_frame
    finish()

func finish() -> void:
    if failures.is_empty():
        print("TEST PASS: local keyboard turn sense and gun direction match compass/camera across yaw and pitch limits")
        quit(0)
    else:
        print("TEST FAIL: local control directions: %d unmet semantic checks" % failures.size())
        quit(1)
