extends Node3D

const GroundMaterial = preload("res://world/ground_material.gd")

@export var size_m: float = 1800.0
var ground: MeshInstance3D

func _ready():
    var plane = PlaneMesh.new()
    plane.size = Vector2(size_m, size_m)
    ground = MeshInstance3D.new()
    ground.name = "RailYardGround"
    ground.mesh = plane
    ground.material_override = GroundMaterial.rail_yard()
    ground.position = Vector3(0, 0.3, 0)
    ground.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    add_child(ground)
