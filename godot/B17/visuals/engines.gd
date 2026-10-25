extends Node3D

const Parts = preload("res://visuals/parts.gd")

var propellers: Array[Node3D] = []

func _ready():
    for x in [-9.4, -4.4, 4.4, 9.4]:
        var cylinder = CylinderMesh.new()
        cylinder.top_radius = .9
        cylinder.bottom_radius = .9
        cylinder.height = 3.1
        cylinder.radial_segments = 24
        var nacelle = Parts.add_mesh(self, "Nacelle", cylinder, Vector3(x, -.05, -2.8), Vector3.ONE, Color(.27, .3, .17))
        nacelle.rotation.x = PI / 2

        var sphere = SphereMesh.new()
        sphere.radius = .4
        sphere.height = .8
        var propeller = Parts.add_mesh(self, "Propeller", sphere, Vector3(x, 0, -4.5), Vector3(1, 1, 1.4), Color(.15, .16, .16))

        var rotor = Node3D.new()
        rotor.name = "Rotor"
        add_child(rotor)
        rotor.position = Vector3(x, 0, -5)
        propellers.append(rotor)

        for j in range(3):
            var angle = TAU * float(j) / 3
            var box = BoxMesh.new()
            box.size = Vector3(.18, 2.1, .08)
            var blade = Parts.add_mesh(rotor, "Blade", box, (Vector3.UP * 1.05).rotated(Vector3.FORWARD, angle), Vector3.ONE, Color(.07, .07, .07))
            blade.rotation.z = -angle

func _process(delta: float):
    for propeller in propellers:
        propeller.rotation.z += delta * 31
