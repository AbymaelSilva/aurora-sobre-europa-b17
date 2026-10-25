class_name EngineAnchors extends RefCounted

const EXHAUST_OFFSET: Vector3 = Vector3(0.0, 0.4, 2.0)

static func get_sorted_rotors(root_node: Node3D) -> Array[Node3D]:
    var result: Array[Node3D] = []
    if root_node == null:
        return result
    var nodes: Array = root_node.find_children("Rotor_*", "Node3D", true, false)
    for n in nodes:
        if n is Node3D:
            result.append(n as Node3D)
    result.sort_custom(func(a: Node3D, b: Node3D) -> bool:
        return root_node.to_local(a.global_position).x < root_node.to_local(b.global_position).x
    )
    return result

static func get_smoke_positions(root_node: Node3D, offset: Vector3 = EXHAUST_OFFSET) -> Array[Vector3]:
    var positions: Array[Vector3] = []
    if root_node == null:
        return positions
    var rotors := get_sorted_rotors(root_node)
    var b: Basis = root_node.global_basis
    for r in rotors:
        positions.append(r.global_position + b * offset)
    return positions
