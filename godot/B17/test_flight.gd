extends SceneTree
func _initialize() -> void:
    var model = load("res://flight_model.gd").new()
    for i in range(36000):
        model.step(sin(float(i)*0.01), cos(float(i)*0.01), sin(float(i)*0.05), 1.0/60.0)
        if not model.position.is_finite() or not is_finite(model.speed) or model.speed < 25.0 or model.speed > 90.0 or model.position.y < 5.0:
            print("TEST FAIL: invalid state at tick ", i)
            quit(1)
            return
    model.reset()
    if model.position != Vector3(0,100,0) or model.speed != 50.0 or model.yaw != 0.0 or model.pitch != 0.0:
        print("TEST FAIL: reset")
        quit(1)
        return
    for i in range(600):
        model.step(0.0,0.0,0.0,1.0/60.0)
    if absf(model.position.y-100.0)>0.01 or model.position.z > -490.0:
        print("TEST FAIL: straight and level flight")
        quit(1)
        return
    model.reset()
    for i in range(120):
        model.step(1.0,0.0,0.0,1.0/60.0)
    if model.position.y <= 110.0:
        print("TEST FAIL: pitch does not produce climb")
        quit(1)
        return
    print("TEST PASS: 10min finite state/speed/height bounds, reset, level flight and climb")
    quit(0)
