extends Node3D

var metal_color = Color(0.8, 0.8, 0.8)
var brown_color = Color(0.6, 0.4, 0.2)
var orange_color = Color(1, 0.5, 0)
var blue_color = Color(0, 0.5, 1)
var green_color = Color(0.5, 1, 0.5)

func _ready():
    box(Vector3(1, 1, 240), Vector3(-6, 0.5, -1000), metal_color)
    box(Vector3(1, 1, 240), Vector3(6, 0.5, -1000), metal_color)
    box(Vector3(45, 15, 35), Vector3(35, 7.5, -1000), brown_color)
    box(Vector3(25, 5, 55), Vector3(0, 2.5, -1000), orange_color)
    box(Vector3(4, 100, 4), Vector3(0, 50, -250), blue_color)
    box(Vector3(4, 100, 4), Vector3(0, 50, -500), blue_color)
    box(Vector3(4, 100, 4), Vector3(0, 50, -700), blue_color)
    box(Vector3(8, 100, 8), Vector3(800, 50, -300), green_color)
    box(Vector3(1600, 0.1, 50), Vector3(0, 0.1, -450), blue_color)
    box(Vector3(150, 30, 180), Vector3(-300, 15, -600), Color(0.4, 0.6, 0.4))
    box(Vector3(150, 30, 180), Vector3(300, 15, -1300), Color(0.4, 0.6, 0.4))

func box(size: Vector3, offset: Vector3, color: Color):
    var mesh = BoxMesh.new()
    mesh.size = size
    var instance = MeshInstance3D.new()
    instance.mesh = mesh
    var material = StandardMaterial3D.new()
    material.albedo_color = color
    instance.material_override = material
    instance.position = offset
    add_child(instance)
