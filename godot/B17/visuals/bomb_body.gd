extends Node3D

func _ready():
    var bomb = MeshInstance3D.new()
    bomb.mesh = SphereMesh.new()
    bomb.mesh.radius = 0.28
    bomb.mesh.height = 1.4
    bomb.mesh.radial_segments = 12
    bomb.mesh.rings = 6
    bomb.material_override = StandardMaterial3D.new()
    bomb.material_override.albedo_color = Color(0.5, 0.4, 0.3)
    bomb.material_override.roughness = 0.7
    add_child(bomb)

    var material = StandardMaterial3D.new()
    material.albedo_color = Color(0.2, 0.2, 0.2)

    for i in range(4):
        var fin = MeshInstance3D.new()
        fin.mesh = BoxMesh.new()
        fin.mesh.size = Vector3(0.7, 0.35, 0.05)
        fin.position.y = 0.55
        fin.rotation_degrees.y = float(i) * 90
        fin.material_override = material
        add_child(fin)

    var band = MeshInstance3D.new()
    band.mesh = CylinderMesh.new()
    band.mesh.top_radius = 0.285
    band.mesh.bottom_radius = 0.285
    band.mesh.height = 0.08
    band.position.y = -0.2
    band.material_override = StandardMaterial3D.new()
    band.material_override.albedo_color = Color(1, 1, 0)
    add_child(band)
