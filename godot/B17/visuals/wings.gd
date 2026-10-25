extends Node3D

func _ready():
    build(1.0)
    build(-1.0)

func quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, normal: Vector3):
    var points = [a, b, c, a, c, d]
    for point in points:
        st.set_normal(normal)
        st.add_vertex(point)

func build(side: float):
    var a = Vector3(1.1 * side, .2, -2.2)
    var b = Vector3(15.8 * side, 1, -.5)
    var c = Vector3(15.8 * side, 1, 1.6)
    var d = Vector3(1.1 * side, .2, 3.7)
    var e = a - Vector3(0, .25, 0)
    var f = b - Vector3(0, .25, 0)
    var g = c - Vector3(0, .25, 0)
    var h = d - Vector3(0, .25, 0)

    var st = SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)

    quad(st, a, b, c, d, Vector3.UP)
    quad(st, e, h, g, f, Vector3.DOWN)
    quad(st, a, e, f, b, Vector3.FORWARD)
    quad(st, b, f, g, c, Vector3.RIGHT * side)
    quad(st, c, g, h, d, Vector3.BACK)
    quad(st, d, h, e, a, Vector3.LEFT * side)

    var mesh = st.commit()
    var mat = StandardMaterial3D.new()
    mat.albedo_color = Color(.28, .33, .18)
    mat.metallic = .25
    mat.roughness = .48
    mat.cull_mode = BaseMaterial3D.CULL_DISABLED
    var mesh_instance = MeshInstance3D.new()
    mesh_instance.mesh = mesh
    mesh_instance.material_override = mat
    add_child(mesh_instance)
