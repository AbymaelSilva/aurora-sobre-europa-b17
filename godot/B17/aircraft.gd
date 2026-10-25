extends Node3D

var model: Node3D

class EnginesNode extends Node3D:
    var rotors: Array[Node3D] = []

    func _process(delta: float) -> void:
        for r in rotors:
            r.rotate_z(delta * 31.0)

func _ready() -> void:
    model = preload("res://assets/aircraft/models/b17g.glb").instantiate() as Node3D
    add_child(model)

    var engines := EnginesNode.new()
    engines.name = "Engines"
    add_child(engines)

    for r in model.find_children("Rotor_*", "Node3D", true, false):
        engines.rotors.append(r as Node3D)
