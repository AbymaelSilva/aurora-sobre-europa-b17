extends Node3D

var age: float = 10.0
var clouds: Array[MeshInstance3D] = []

func _ready():
    for i in range(6):
        var mesh = MeshInstance3D.new()
        var sphere_mesh = SphereMesh.new()
        sphere_mesh.radius = 1.8
        sphere_mesh.height = 3.6
        mesh.mesh = sphere_mesh
        var material = StandardMaterial3D.new()
        material.albedo_color = Color(0.08, 0.08, 0.08)
        mesh.material_override = material
        add_child(mesh)
        mesh.visible = false
        clouds.append(mesh)

func burst(center: Vector3):
    age = 0
    for i in range(clouds.size()):
        clouds[i].position = center + Vector3(float(i % 3 - 1) * 18, float(i % 2) * 12 - 6, float(i - 3) * 11)
        clouds[i].visible = true

func step(delta: float):
    age += maxf(delta, 0)
    for cloud in clouds:
        cloud.visible = age < 1.8
        cloud.scale = Vector3.ONE * (1 + minf(age, 1.8) * 1.8)
