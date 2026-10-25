extends RefCounted

var phase: String = "FORMACION"
var waypoint_index: int = 0
var clock: float = 0
var waypoints: Array[Vector3] = [Vector3(0, 1200, -6000), Vector3(0, 1200, -14000), Vector3(0, 1200, -22000)]
var target: Vector3 = Vector3(0, 0, -30000)
var exit_point: Vector3 = Vector3(28000, 1200, -15000)

func reset():
    phase = "FORMACION"
    waypoint_index = 0
    clock = 0

func step(delta: float, aircraft_position: Vector3, bomb_result: String, is_destroyed: bool):
    if phase == "COMPLETADA" or phase == "FALLIDA":
        return
    if is_destroyed:
        phase = "FALLIDA"
        return
    clock += maxf(delta, 0)
    if phase == "FORMACION" and clock >= 35:
        phase = "APROXIMACION"
    if phase == "APROXIMACION":
        if waypoint_index < waypoints.size() and aircraft_position.distance_to(waypoints[waypoint_index]) < 300:
            waypoint_index += 1
        if waypoint_index == waypoints.size():
            phase = "BOMBARDEO"
    if phase == "BOMBARDEO":
        if bomb_result == "IMPACTO":
            phase = "REGRESO"
        elif bomb_result == "FALLO":
            phase = "FALLIDA"
    if phase == "REGRESO":
        if aircraft_position.distance_to(exit_point) < 500:
            phase = "COMPLETADA"

func navigation_target() -> Vector3:
    if phase == "FORMACION":
        return waypoints[0]
    elif phase == "APROXIMACION":
        return waypoints[min(waypoint_index, waypoints.size() - 1)]
    elif phase == "REGRESO":
        return exit_point
    else:
        return target + Vector3(0, 1200, -4000)
