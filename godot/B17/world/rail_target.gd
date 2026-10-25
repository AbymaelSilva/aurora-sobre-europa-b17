extends Node3D

var materials: Dictionary = {}

func box(at: Vector3, size_value: Vector3, color: Color) -> void:
    var node = MeshInstance3D.new()
    var mesh = BoxMesh.new()
    mesh.size = size_value
    node.mesh = mesh
    if not materials.has(color):
        var material := StandardMaterial3D.new()
        material.albedo_color = color
        material.roughness = 0.85
        materials[color] = material
    node.material_override = materials[color]
    node.position = at
    add_child(node)

func _ready():
    var track_length = 500
    var sleeper_spacing = 40
    var sleeper_size = Vector3(10, 0.8, 2)
    var sleeper_color = Color(0.3, 0.15, 0.05)
    var warehouse_size = Vector3(60, 24, 50)
    var warehouse_color = Color(0.6, 0.3, 0.1)
    var roof_size = Vector3(64, 2, 54)
    var roof_color = Color(0.2, 0.2, 0.2)

    if !materials.has(sleeper_color):
        materials[sleeper_color] = StandardMaterial3D.new()
        materials[sleeper_color].albedo_color = sleeper_color
    if !materials.has(warehouse_color):
        materials[warehouse_color] = StandardMaterial3D.new()
        materials[warehouse_color].albedo_color = warehouse_color
    if !materials.has(roof_color):
        materials[roof_color] = StandardMaterial3D.new()
        materials[roof_color].albedo_color = roof_color

    for x in [-30, 0, 30]:
        for rail_offset in [-3.0,3.0]:
            box(Vector3(x+rail_offset, 1.4, 0), Vector3(1, 1, track_length), Color(0.5, 0.5, 0.5))
        for z in range(12):
            box(Vector3(x, 1, -track_length / 2 + z * sleeper_spacing), sleeper_size, sleeper_color)

    var warehouse_positions = [Vector3(100, 12, -160), Vector3(100, 12, -80), Vector3(100, 12, 0), Vector3(100, 12, 80), Vector3(100, 12, 160)]
    for pos in warehouse_positions:
        box(pos, warehouse_size, warehouse_color)
        box(pos + Vector3(0, 13, 0), roof_size, roof_color)

func reset():
    pass
