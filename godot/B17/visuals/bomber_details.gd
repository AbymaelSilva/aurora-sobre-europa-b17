extends Node3D

const Parts = preload("res://visuals/parts.gd")

func barrel(label: String, offset: Vector3, size: Vector3) -> void:
    var b = BoxMesh.new()
    b.size = size
    Parts.add_mesh(self, label, b, offset, Vector3.ONE, Color(0.06, 0.06, 0.06))

func _ready():
    var dark = Color(0.06, 0.06, 0.06)
    var metal = Color(0.2, 0.17, 0.14)

    var s = SphereMesh.new()
    s.radius = 0.5
    s.height = 1
    Parts.add_mesh(self, "ChinTurret", s, Vector3(0, -1.2, -9.6), Vector3(0.7, 0.6, 0.7), dark)

    barrel("ChinGunL", Vector3(-0.15, -1.25, -10.4), Vector3(0.06, 0.06, 1.2))
    barrel("ChinGunR", Vector3(0.15, -1.25, -10.4), Vector3(0.06, 0.06, 1.2))
    barrel("TopGunL", Vector3(-0.18, 2.2, -2.9), Vector3(0.06, 0.06, 1.4))
    barrel("TopGunR", Vector3(0.18, 2.2, -2.9), Vector3(0.06, 0.06, 1.4))
    barrel("BellyGunL", Vector3(-0.15, -2.0, -0.3), Vector3(0.06, 0.06, 1.3))
    barrel("BellyGunR", Vector3(0.15, -2.0, -0.3), Vector3(0.06, 0.06, 1.3))
    barrel("WaistGunL", Vector3(-1.75, 0.5, 3.5), Vector3(1.1, 0.06, 0.06))
    barrel("WaistGunR", Vector3(1.75, 0.5, 3.5), Vector3(1.1, 0.06, 0.06))
    barrel("TailGunL", Vector3(-0.12, 0.3, 11.2), Vector3(0.06, 0.06, 1.0))
    barrel("TailGunR", Vector3(0.12, 0.3, 11.2), Vector3(0.06, 0.06, 1.0))
    barrel("RadioMast", Vector3(0, 1.9, -3.9), Vector3(0.05, 0.9, 0.05))

    for x in [-7.73, -3.80, 3.80, 7.73]:
        var box = BoxMesh.new()
        box.size = Vector3(0.25, 0.2, 0.8)
        Parts.add_mesh(self, "Exhaust", box, Vector3(x, -0.85, -1.4), Vector3.ONE, metal)
