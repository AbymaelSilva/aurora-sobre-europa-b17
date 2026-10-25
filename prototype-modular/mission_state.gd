extends RefCounted

var phase: String = "APROXIMACION"
var waypoint_index: int = 0
var waypoints: Array[Vector3] = [Vector3(0, 100, -250), Vector3(0, 100, -500), Vector3(0, 100, -700)]
var target: Vector3 = Vector3(0, 0, -1000)
var exit_point: Vector3 = Vector3(800, 100, -300)

func reset() -> void:
    phase = "APROXIMACION"
    waypoint_index = 0

func update(aircraft_position: Vector3, bomb_result: String) -> void:
    if phase == "APROXIMACION" and waypoint_index < waypoints.size() and aircraft_position.distance_to(waypoints[waypoint_index]) < 65:
        waypoint_index += 1
        if waypoint_index == waypoints.size():
            phase = "BOMBARDEO"

    if phase == "BOMBARDEO":
        if bomb_result == "IMPACTO":
            phase = "REGRESO"
        elif bomb_result == "FALLO":
            phase = "FALLIDA"

    if phase == "REGRESO" and aircraft_position.distance_to(exit_point) < 100:
        phase = "COMPLETADA"

func navigation_target() -> Vector3:
    if phase == "APROXIMACION":
        return waypoints[waypoint_index]
    elif phase == "REGRESO":
        return exit_point
    else:
        return Vector3(target.x, 100, target.z - 500)
