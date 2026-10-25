extends SceneTree

func _initialize() -> void:
    call_deferred("verify")

func verify() -> void:
    var aircraft = load("res://aircraft.gd").new()
    root.add_child(aircraft)
    var meshes: Array[Node] = aircraft.find_children("*","MeshInstance3D",true,false)
    if meshes.size()<25 or aircraft.get_node("Engines").propellers.size()!=4:
        print("TEST FAIL: bomber assembly missing components")
        quit(1)
        return
    var combined := AABB()
    var first := true
    for node in meshes:
        var instance: MeshInstance3D = node
        if instance.mesh==null or instance.material_override==null:
            print("TEST FAIL: missing mesh or material")
            quit(1)
            return
        var bounds: AABB = instance.global_transform*instance.get_aabb()
        combined = bounds if first else combined.merge(bounds)
        first = false
    if combined.size.x<31.0 or combined.size.x>33.0 or combined.size.z<22.0 or combined.size.z>26.0:
        print("TEST FAIL: bomber dimensions ",combined.size)
        quit(1)
        return
    var rotor: Node3D = aircraft.get_node("Engines").propellers[0]
    var before: float = rotor.rotation.z
    aircraft.get_node("Engines")._process(0.1)
    if is_equal_approx(before,rotor.rotation.z):
        print("TEST FAIL: propeller animation")
        quit(1)
        return
    print("TEST PASS: original bomber geometry, materials, dimensions ",combined.size,", four animated propellers. Meshes=",meshes.size())
    quit(0)
