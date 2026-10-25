extends Node3D

var spheres: Array[MeshInstance3D] = []

func _ready():
    for i in range(6):
        var sphere = MeshInstance3D.new()
        sphere.mesh = SphereMesh.new()
        sphere.mesh.radius = 1
        sphere.mesh.height = 2
        sphere.mesh.radial_segments = 8
        sphere.mesh.rings = 4
        var material = StandardMaterial3D.new()
        material.albedo_color = Color(0.1, 0.1, 0.1)
        material.roughness = 1
        sphere.material_override = material
        sphere.position = Vector3(0, float(i) * 0.7, float(i) * 3)
        sphere.scale = Vector3.ONE * (1.0 + float(i) * 0.5)
        sphere.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
        sphere.visible = false
        add_child(sphere)
        spheres.append(sphere)

func set_damage(engine_health: float):
    for sphere in spheres:
        sphere.visible = engine_health < 85.0
        sphere.scale = Vector3.ONE * (1.0+float(spheres.find(sphere))*0.5) * clampf((100.0 - engine_health) / 30.0, 0.5, 3.0)
