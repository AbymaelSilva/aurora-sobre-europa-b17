extends RefCounted

class_name BombingAid

static func calculate(flight, target: Vector3, bomb_spent: bool, phase: String, bomb_ref = null) -> Dictionary:
	if phase != "BOMBARDEO":
		return {
			"release_now": false,
			"eta_seconds": 999.0,
			"lateral_error_m": 0.0,
			"status": "FUERA_DE_FASE",
			"predicted_impact": Vector3.ZERO
		}

	if bomb_spent:
		var spent_res := {
			"release_now": false,
			"eta_seconds": 0.0,
			"lateral_error_m": 0.0,
			"status": "BOMBAS_FUERA",
			"predicted_impact": Vector3.ZERO
		}
		if bomb_ref != null:
			spent_res["salvo_count"] = bomb_ref.released_count if "released_count" in bomb_ref else 30
			spent_res["salvo_active"] = bomb_ref.active if "active" in bomb_ref else false
			spent_res["salvo_result"] = bomb_ref.result if "result" in bomb_ref else ""
		return spent_res

	var altitude: float = max(flight.position.y, 0.0)
	var velocity: Vector3 = -Basis.from_euler(Vector3(flight.pitch, flight.yaw, 0.0)).z * flight.speed
	var disc: float = velocity.y * velocity.y + 19.62 * altitude
	var falltime: float = (velocity.y + sqrt(max(disc, 0.0))) / 9.81
	var predicted: Vector3 = flight.position + velocity * falltime
	predicted.y = 0.0

	var horiz_vel := Vector2(velocity.x, velocity.z)
	var horiz_speed: float = horiz_vel.length()
	var track_dir: Vector2
	if horiz_speed > 0.1:
		track_dir = horiz_vel / horiz_speed
	else:
		track_dir = Vector2(-sin(flight.yaw), -cos(flight.yaw)).normalized()

	var track_normal := Vector2(-track_dir.y, track_dir.x)

	var to_target := Vector2(target.x - predicted.x, target.z - predicted.z)
	var along_track: float = to_target.dot(track_dir)
	var lateral_error: float = to_target.dot(track_normal)
	var eta: float = along_track / horiz_speed if horiz_speed > 1.0 else 0.0
	var miss_distance: float = to_target.length()

	var release_now: bool = false
	var status: String = "APROXIMANDO"

	if miss_distance <= 55.0:
		release_now = true
		status = "SUELTA_AHORA"
	elif along_track < -55.0:
		release_now = false
		status = "PASADO"
	elif abs(lateral_error) > 45.0:
		release_now = false
		status = "CORREGIR_RUMBO"
	else:
		release_now = false
		status = "APROXIMANDO"

	return {
		"release_now": release_now,
		"eta_seconds": eta,
		"lateral_error_m": lateral_error,
		"status": status,
		"predicted_impact": predicted
	}
