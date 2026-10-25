extends Node3D

@export var points: PackedVector3Array = PackedVector3Array([
    Vector3(-9000, 0, 8000), Vector3(-3000, 0, -2000), Vector3(1500, 0, -12000),
    Vector3(-1200, 0, -24000), Vector3(900, 0, -30500), Vector3(6000, 0, -40000)
])
@export var width: float = 140.0

var river: MeshInstance3D

func build() -> MeshInstance3D:
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for i in range(points.size() - 1):
        var a: Vector3 = points[i]
        var b: Vector3 = points[i + 1]
        var dir: Vector3 = b - a
        dir.y = 0.0
        if dir.length() < 0.001:
            continue
        var side: Vector3 = dir.normalized().cross(Vector3.UP) * width * 0.5
        var lift: Vector3 = Vector3(0, 0.2, 0)
        var q: Array[Vector3] = [
            a - side + lift, b - side + lift, b + side + lift, a - side + lift,
            b + side + lift, a + side + lift
        ]
        for p in q:
            st.set_normal(Vector3.UP)
            st.add_vertex(p)
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Color(0.16, 0.24, 0.26)
    mat.roughness = 0.08
    mat.metallic = 0.1
    mat.cull_mode = BaseMaterial3D.CULL_DISABLED
    river = MeshInstance3D.new()
    river.name = "River"
    river.mesh = st.commit()
    river.material_override = mat
    river.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    add_child(river)
    return river

func _ready():
    build()
