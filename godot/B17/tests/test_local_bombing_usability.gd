extends SceneTree
# U01/U02: operador sintético usa SOLO la señal compartida con HUD para la suelta.
# No calcula su propia solución balística; no cambia el modelo ni el radio del objetivo.
var failures: PackedStringArray = []
var scene: Node
var operator_cases: int = 0
var impact_cases: int = 0
var transition_cases: int = 0

func _initialize() -> void:
    run.call_deferred()

func check(condition: bool,message: String) -> void:
    if not condition:
        failures.append(message)
        print("FAIL: ",message)

func key(code: int,down: bool) -> void:
    var event := InputEventKey.new()
    event.physical_keycode = code
    event.keycode = code
    event.pressed = down
    Input.parse_input_event(event)
    Input.flush_buffered_events()

func read_aid() -> Dictionary:
    if scene.overlay.data.has("bombing_aid") and scene.overlay.data["bombing_aid"] is Dictionary:
        return {"data":scene.overlay.data["bombing_aid"],"view":scene.overlay}
    for node in scene.find_children("*","Control",true,false):
        if node.get_script()!=null and node.get_script().resource_path=="res://ui/bombing_cue.gd" and "data" in node and node.data is Dictionary:
            return {"data":node.data,"view":node}
    return {}

func schema(exposed: Dictionary,label: String) -> bool:
    if exposed.is_empty():
        check(false,label+": no real HUD provider exposes bombing_aid/cue.data")
        return false
    var data: Dictionary = exposed["data"]
    for field in ["release_now","eta_seconds","lateral_error_m","status","predicted_impact"]:
        if not data.has(field):
            check(false,label+": missing cue field "+field)
            return false
    var valid: bool = data.release_now is bool and data.status is String and data.predicted_impact is Vector3
    valid = valid and typeof(data.eta_seconds) in [TYPE_FLOAT,TYPE_INT] and typeof(data.lateral_error_m) in [TYPE_FLOAT,TYPE_INT]
    if not valid:
        check(false,label+": cue field types differ from agreed contract")
        return false
    check(is_finite(float(data.eta_seconds)) and is_finite(float(data.lateral_error_m)) and data.predicted_impact.is_finite(),label+": cue values are finite")
    check(not str(data.status).is_empty(),label+": visible status text is nonempty")
    check(exposed["view"].is_inside_tree() and exposed["view"].is_visible_in_tree(),label+": actual HUD provider is active/visible")
    return true

func setup(altitude: float,speed: float,x_offset: float=0.0,lead: float=4000.0) -> void:
    for code in [KEY_D,KEY_A,KEY_S,KEY_W,KEY_SHIFT,KEY_CTRL,KEY_SPACE]:
        key(code,false)
    scene.restart_mission()
    scene.sim.autopilot = false
    scene.sim.mission.phase = "BOMBARDEO"
    scene.sim.flight.position = scene.sim.mission.target+Vector3(x_offset,altitude,lead)
    scene.sim.flight.yaw = 0.0
    scene.sim.flight.pitch = 0.0
    scene.sim.flight.speed = speed
    scene.controls.set_station("BOMBARDERO",scene.sim)
    scene.update_presentation(0.0)

func check_operator(altitude: float,speed: float) -> void:
    setup(altitude,speed)
    var label: String = "alt=%.0f speed=%.0f" % [altitude,speed]
    operator_cases += 1
    if not schema(read_aid(),label):
        return
    var released: bool = false
    var cue_at_release: Dictionary = {}
    for frame in range(60*100):
        var exposed: Dictionary = read_aid()
        if exposed.is_empty():
            check(false,label+": cue disappeared during approach")
            return
        var aid: Dictionary = exposed["data"]
        if scene.sim.bomb.spent:
            check(false,label+": bomb released automatically before operator Space")
            return
        if bool(aid.get("release_now",false)):
            cue_at_release = aid.duplicate()
            key(KEY_SPACE,true)
            await process_frame
            key(KEY_SPACE,false)
            await process_frame
            released = scene.sim.bomb.spent
            check(released,label+": physical Space event releases bomb when HUD says release_now")
            break
        scene._physics_process(1.0/60.0)
    check(released,label+": HUD offers an attainable manual release window")
    if not released:
        return
    spent_aid_check(label)
    for frame in range(60*60):
        if not scene.sim.bomb.active:
            break
        scene._physics_process(1.0/60.0)
    check(scene.sim.bomb.result=="IMPACTO",label+": actual bomb model hits after HUD-directed manual release")
    check(not scene.sim.autopilot,label+": operator remains manual")
    if scene.sim.bomb.result=="IMPACTO":
        impact_cases += 1
    print("U01 ",label," result=",scene.sim.bomb.result," cue_status=",cue_at_release.get("status")," eta=",cue_at_release.get("eta_seconds")," lateral=",cue_at_release.get("lateral_error_m"))

func spent_aid_check(label: String) -> void:
    var after: Dictionary = read_aid()
    check(not after.is_empty() and not bool(after.get("data",{}).get("release_now",true)),label+": spent bomb immediately clears release signal")

func check_false_positives() -> void:
    for case in [{"label":"off-axis900m","x":900.0,"lead":2000.0,"frames":60*50},{"label":"target-passed500m","x":0.0,"lead":-500.0,"frames":120}]:
        setup(1200.0,85.0,float(case.x),float(case.lead))
        if not schema(read_aid(),str(case.label)):
            continue
        var offered: bool = false
        for frame in range(int(case.frames)):
            var exposed: Dictionary = read_aid()
            if exposed.is_empty():
                check(false,str(case.label)+": cue data unavailable")
                break
            if bool(exposed["data"].get("release_now",false)):
                offered = true
                break
            scene._physics_process(1.0/60.0)
        check(not offered,str(case.label)+": no false-positive release_now")
        check(not scene.sim.bomb.spent,str(case.label)+": no automatic release in manual mode")

func commands() -> Vector3:
    return Vector3(scene.sim.pitch_input,scene.sim.turn_input,scene.sim.throttle_input)

func check_transitions() -> void:
    for station in ["ARTILLERO","BOMBARDERO"]:
        for entry in [[KEY_D,"D"],[KEY_S,"S"],[KEY_SHIFT,"SHIFT"]]:
            setup(1200.0,85.0)
            scene.controls.set_station("PILOTO",scene.sim)
            key(int(entry[0]),true)
            scene._physics_process(1.0/60.0)
            key(int(entry[0]),false)
            check(commands().length()>0.5,"precondition: actual key sets a flight command")
            scene.controls.set_station(station,scene.sim)
            check(commands().length()<0.0001,"U02 "+station+" after "+entry[1]+": commands neutralized immediately")
            var yaw_before: float = scene.sim.flight.yaw
            var pitch_before: float = scene.sim.flight.pitch
            var speed_before: float = scene.sim.flight.speed
            for frame in range(120):
                scene._physics_process(1.0/60.0)
            check(commands().length()<0.0001,"U02 "+station+" after "+entry[1]+": no latent command after2s")
            check(absf(scene.sim.flight.yaw-yaw_before)<0.005,"U02 no continued yaw from released key")
            check(absf(scene.sim.flight.speed-speed_before)<0.05,"U02 no continued throttle from released key")
            check(absf(scene.sim.flight.pitch)<=absf(pitch_before)+0.01,"U02 existing pitch settles instead of continuing pull")
            check(not scene.sim.autopilot,"U02 station change preserves manual mode")
            scene.controls.set_station("PILOTO",scene.sim)
            var forward_before: Vector3 = -Basis.from_euler(Vector3(0,scene.sim.flight.yaw,0)).z
            var right_before: Vector3 = forward_before.cross(Vector3.UP)
            key(KEY_A,true)
            scene._physics_process(1.0/60.0)
            var forward_after: Vector3 = -Basis.from_euler(Vector3(0,scene.sim.flight.yaw,0)).z
            check(absf(scene.sim.turn_input)>0.5,"U02 return to pilot polls currently held A")
            check(forward_after.dot(right_before)<-0.001,"U02 current A turns physically left after returning to pilot")
            key(KEY_A,false)
            scene._physics_process(1.0/60.0)
            check(commands().length()<0.0001,"U02 release A clears current command without stale history")
            transition_cases += 1

func run() -> void:
    root.size = Vector2i(1280,720)
    scene = load("res://game.tscn").instantiate()
    root.add_child(scene)
    scene.set_physics_process(false)
    for altitude in [1000.0,1200.0,1400.0]:
        for speed in [70.0,85.0,100.0]:
            await check_operator(altitude,speed)
    check_false_positives()
    check_transitions()
    for code in [KEY_D,KEY_A,KEY_S,KEY_W,KEY_SHIFT,KEY_CTRL,KEY_SPACE]:
        key(code,false)
    for player in [scene.engine_audio,scene.gun_audio,scene.flak_audio,scene.bomb_audio]:
        player.stop()
        player.stream = null
    root.remove_child(scene)
    scene.free()
    scene = null
    for frame in range(6):
        await process_frame
        await physics_frame
    print("U01 operator_cases=",operator_cases," actual_hits=",impact_cases," U02 transitions=",transition_cases)
    check(operator_cases==9 and impact_cases==9,"nine HUD-directed ballistic scenarios hit with Space")
    check(transition_cases==6,"six station/flight-input transition scenarios executed")
    if failures.is_empty():
        print("TEST PASS: shared HUD cue guides real manual bomb release; no off-axis/passed false positive; six station transitions neutralize and repoll inputs")
        quit(0)
    else:
        print("TEST FAIL: local bombing usability: %d unmet checks" % failures.size())
        quit(1)
