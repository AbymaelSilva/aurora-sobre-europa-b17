extends RefCounted

static var materials: Dictionary = {}

static func material(color: Color) -> StandardMaterial3D:
    if materials.has(color):
        return materials[color]
    var mat = StandardMaterial3D.new()
    mat.albedo_color = color
    mat.roughness = 0.48
    mat.metallic = 0.25
    if color.a < 0.99:
        mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
        mat.metallic = 0
        mat.roughness = 0.2
    materials[color] = mat
    return mat

static func add_mesh(parent: Node3D, label: String, shape: Mesh, offset: Vector3, scale_value: Vector3, color: Color) -> MeshInstance3D:
    var mesh_instance = MeshInstance3D.new()
    mesh_instance.name = label
    mesh_instance.mesh = shape
    mesh_instance.material_override = material(color)
    mesh_instance.position = offset
    mesh_instance.scale = scale_value
    parent.add_child(mesh_instance)
    return mesh_instance
