extends Node3D

# Adaptador de escena: Codex. Vuelo, balística y estados de misión: Qwen.
var flight = preload("res://flight_model.gd").new()
var bomb = preload("res://bomb_model.gd").new()
var mission = preload("res://mission_state.gd").new()
var paused: bool = false
var elapsed: float = 0.0
var impact_age: float = 0.0
var release_position: Vector3 = Vector3.ZERO

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
        if event.physical_keycode == KEY_ESCAPE:
            paused = not paused
        elif event.physical_keycode == KEY_R:
            flight.reset()
            bomb.reset()
            mission.reset()
            elapsed = 0.0
            impact_age = 0.0
            release_position = Vector3.ZERO

func _physics_process(delta: float) -> void:
    if not paused and mission.phase not in ["COMPLETADA", "FALLIDA"]:
        elapsed += delta
        mission.update(flight.position, bomb.result)
        var destination: Vector3 = mission.navigation_target()
        var offset: Vector3 = destination - flight.position
        var desired_yaw: float = atan2(-offset.x, -offset.z)
        var turn: float = clampf(wrapf(desired_yaw-flight.yaw, -PI, PI)*2.0, -1.0, 1.0)
        var pitch: float = clampf((100.0-flight.position.y)*0.03, -1.0, 1.0)
        flight.step(pitch, turn, 0.0, delta)
        var velocity: Vector3 = -Basis.from_euler(Vector3(flight.pitch,flight.yaw,0)).z*flight.speed
        var fall_time: float = sqrt(2.0*maxf(flight.position.y,0.0)/9.81)
        var predicted: Vector3 = flight.position+velocity*fall_time
        var miss: float = Vector2(predicted.x,predicted.z).distance_to(Vector2(mission.target.x,mission.target.z))
        if mission.phase == "BOMBARDEO" and not bomb.spent and miss < 12.0:
            bomb.release(flight.position, velocity)
            release_position = flight.position
        bomb.step(delta, mission.target, 55.0)
        mission.update(flight.position,bomb.result)
    if bomb.spent and not bomb.active and not paused:
        impact_age += delta
    $Aircraft.position = flight.position
    $Aircraft.rotation = Vector3(flight.pitch,flight.yaw,0)
    $BombVisual.visible = bomb.active or (bomb.spent and impact_age<3.0)
    $BombVisual.position = bomb.position
    $BombVisual.scale = Vector3.ONE*(1.0 if bomb.active else minf(12.0,1.0+impact_age*6.0))
    var focus: Vector3 = flight.position
    if bomb.active:
        focus = bomb.position
        $Camera3D.global_position = focus+Vector3(18,18,30)
    else:
        $Camera3D.global_position = focus+Vector3(0,12,32).rotated(Vector3.UP,flight.yaw)
    $Camera3D.look_at(focus+Vector3.UP,Vector3.UP)
    var distance: float = flight.position.distance_to(mission.target)
    $HUD.label.text = "B-17 | DEMOSTRACION DE MISION\nVuelo automatico - observa el ataque\nFase: %s\nRuta: %d / 3\nBlanco: estacion ferroviaria\nDistancia: %.0f m | Altitud: %.0f m\nBomba: %s\nTiempo: %.1f s\nESC pausa | R reinicia" % [mission.phase,mission.waypoint_index,distance,flight.position.y,bomb.result,elapsed]
    if paused:
        $HUD.label.text += "\nPAUSADO"
    elif mission.phase == "COMPLETADA":
        $HUD.label.text += "\nOBJETIVO DESTRUIDO - ZONA SEGURA ALCANZADA"
    elif mission.phase == "FALLIDA":
        $HUD.label.text += "\nEL BOMBARDEO NO ALCANZO EL OBJETIVO"
