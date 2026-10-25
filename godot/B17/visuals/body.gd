extends Node3D

const Parts = preload("res://visuals/parts.gd")

func ellipsoid(label: String, offset: Vector3, size: Vector3, color: Color) -> void:
    var sphere = SphereMesh.new()
    sphere.radius = 1
    sphere.height = 2
    sphere.radial_segments = 24
    sphere.rings = 12
    Parts.add_mesh(self, label, sphere, offset, size * 0.5, color)

func box(label: String, offset: Vector3, size: Vector3, color: Color) -> void:
    var shape = BoxMesh.new()
    shape.size = size
    Parts.add_mesh(self, label, shape, offset, Vector3.ONE, color)

func _ready() -> void:
    var olive = Color(0.28, 0.33, 0.18)
    var glass = Color(0.22, 0.36, 0.44, 0.65)
    var dark = Color(0.08, 0.09, 0.08)

    ellipsoid("Fuselage", Vector3.ZERO, Vector3(2.7, 3, 20), olive)
    ellipsoid("Rear", Vector3(0, 0.2, 6), Vector3(1.8, 2, 10), olive)
    ellipsoid("Nose", Vector3(0, 0, -9.8), Vector3(2.5, 2.7, 3), glass)
    ellipsoid("Cockpit", Vector3(0, 1.35, -5.8), Vector3(2.2, 1.5, 3.4), glass)
    box("CabinFrame", Vector3(0, 1.4, -5.8), Vector3(0.12, 1.3, 3.4), dark)
    ellipsoid("UpperTurret", Vector3(0, 2.1, -2), Vector3(1.6, 1.3, 1.6), glass)
    ellipsoid("BellyTurret", Vector3(0, -1.8, 0.5), Vector3(1.4, 1.3, 1.4), glass)
    box("HorizontalTail", Vector3(0, 1, 8.5), Vector3(10, 0.3, 2.4), olive)
    ellipsoid("VerticalTail", Vector3(0, 2.4, 8.7), Vector3(0.3, 4.3, 3.8), olive)
    box("TailGun", Vector3(0, 0.3, 11), Vector3(0.35, 0.35, 2), dark)
