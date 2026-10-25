extends Node3D

var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var mesh: SphereMesh = SphereMesh.new()
var material: StandardMaterial3D = StandardMaterial3D.new()

func _ready():
    rng.seed = 1944
    mesh.radius = 1
    mesh.height = 2
    mesh.radial_segments = 12
    mesh.rings = 6
    material.albedo_color = Color(0.85, 0.87, 0.88)
    material.roughness = 1
    material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL

    for i in range(24):
        var instance: MeshInstance3D = MeshInstance3D.new()
        instance.mesh = mesh
        instance.material_override = material
        instance.position.x = rng.randf_range(-10000, 10000)
        instance.position.y = rng.randf_range(1800, 2400)
        instance.position.z = rng.randf_range(-35000, 5000)
        instance.scale.x = rng.randf_range(250, 600)
        instance.scale.y = rng.randf_range(60, 100)
        instance.scale.z = rng.randf_range(100, 250)
        instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
        add_child(instance)
