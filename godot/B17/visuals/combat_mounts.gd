extends RefCounted
# Imported GLBs have no named weapon sockets. Use aircraft-local hardpoint
# coordinates matching existing bomber_details barrels; never the model origin.
static func bomber_mount(aircraft: Node3D, target: Vector3) -> Vector3:
	var local := aircraft.to_local(target)
	var offset := Vector3(-0.18, 2.2, -3.6)
	if local.y < -30.0:
		offset = Vector3(-0.15, -2.0, -0.95)
	elif local.z > absf(local.x):
		offset = Vector3(-0.12, 0.3, 11.7)
	elif absf(local.x) > absf(local.z) and local.y < 80.0:
		offset = Vector3(signf(local.x) * 2.3, 0.5, 3.5)
	return aircraft.to_global(offset)

static func turret_mount(aircraft: Node3D, station_name: String) -> Vector3:
	var offset := Vector3(-0.18, 2.2, -3.6)
	match station_name:
		"COLA":
			offset = Vector3(0.0, 0.6, 11.8)
		"VENTRAL":
			offset = Vector3(0.0, -2.0, -0.95)
		_:
			offset = Vector3(-0.18, 2.2, -3.6)
	return aircraft.to_global(offset) if aircraft.is_inside_tree() else aircraft.position + offset

static func fighter_mount(pos: Vector3, velocity: Vector3, allied: bool = false) -> Vector3:
	if velocity.length_squared() < 1.0: return pos + Vector3(0.6, 0.1, -2.6)
	var basis := Basis.looking_at(velocity.normalized(), Vector3.UP)
	return pos + basis * Vector3(2.1 if allied else 0.6, 0.1, -2.6)
