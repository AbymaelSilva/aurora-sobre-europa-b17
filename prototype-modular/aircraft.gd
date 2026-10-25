extends Node3D

var fuselage_size: Vector3 = Vector3(2, 2, 12)
var wing_size: Vector3 = Vector3(22, 0.4, 3)
var tail_size: Vector3 = Vector3(8, 0.3, 2)
var fin_size: Vector3 = Vector3(0.4, 3, 2)
var engine_size: Vector3 = Vector3(1, 1, 3)
var engine_offset: Vector3 = Vector3(0, 0, -1.5)
var engine_positions: Array[Vector3] = [Vector3(-7, 0, engine_offset.z), Vector3(-3, 0, engine_offset.z), Vector3(3, 0, engine_offset.z), Vector3(7, 0, engine_offset.z)]
var body_color: Color = Color(0.3, 0.4, 0.2)
var engine_color: Color = Color(0.2, 0.3, 0.1)

func _ready():
    add_box(fuselage_size, Vector3.ZERO, body_color)
    add_box(wing_size, Vector3.ZERO, body_color)
    add_box(tail_size, Vector3(0, 0.5, 4), body_color)
    add_box(fin_size, Vector3(0, 1.5, 4), body_color)
    for pos in engine_positions:
        add_box(engine_size, pos, engine_color)

func add_box(size: Vector3, offset: Vector3, color: Color):
    var mesh = MeshInstance3D.new()
    var box_mesh = BoxMesh.new()
    box_mesh.size = size
    mesh.mesh = box_mesh
    var material = StandardMaterial3D.new()
    material.albedo_color = color
    mesh.material_override = material
    mesh.position = offset
    add_child(mesh)
