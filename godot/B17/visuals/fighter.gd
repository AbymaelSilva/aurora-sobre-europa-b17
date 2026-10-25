extends Node3D

@export var variant: String = "bf109g"
var rotor: Node3D
var smoke: Node3D
var model: Node3D

func _ready():
    var path: String = "res://assets/aircraft/models/fw190a.glb" if variant == "fw190a" else "res://assets/aircraft/models/bf109g.glb"
    var scene: PackedScene = load(path) as PackedScene
    model = scene.instantiate() as Node3D
    add_child(model)
    smoke = preload("res://visuals/engine_smoke_trail.gd").new()
    smoke.position = Vector3(0, 0, -2.5)
    add_child(smoke)
    smoke.particles.amount = 12
    smoke.particles.scale_amount_min = 0.4
    smoke.particles.scale_amount_max = 1.6
    
    var rotors: Array = model.find_children("Rotor_*", "Node3D", true, false)
    if not rotors.is_empty():
        rotor = rotors[0] as Node3D

func _process(delta: float):
    if rotor != null:
        rotor.rotate_z(delta * 40.0)

func update_damage(health: float, frozen: bool) -> void:
    smoke.set_intensity(clampf((45.0 - health) / 45.0, 0.0, 1.0))
    smoke.particles.speed_scale = 0.0 if frozen else 1.0

func reset_effects() -> void:
    smoke.set_intensity(0.0)
    smoke.particles.restart()
