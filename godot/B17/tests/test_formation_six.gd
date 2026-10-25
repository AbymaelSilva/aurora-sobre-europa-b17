extends SceneTree

func _initialize() -> void:
    call_deferred("run_checks")

func fail(msg: String) -> void:
    print("TEST FAIL: ", msg)
    quit(1)

func run_checks() -> void:
    var form_script = load("res://formation.gd")
    if not form_script:
        fail("could not load formation.gd")
        return

    var form = form_script.new()
    root.add_child(form)

    if form.wingmen.size() != 5:
        fail("expected 5 wingmen in formation (total 6 with leader)")
        return

    # Check backwards compatibility
    if form.left == null or form.right == null:
        fail("left and right references must be preserved")
        return

    form.follow(Vector3(0, 1000, 0), 0.5, 0.1)

    var count := 0
    for w in form.wingmen:
        if w.has_node("Engines"):
            count += 1
    if count != 5:
        fail("all 5 wingmen must have Engines node")
        return

    # Verificar compatibilidad de la gran armada de 300 aviones en vuelo (Lote 7)
    if form.slots.slot_count() != 300:
        fail("formation_slots must provide 300 coordinates (found %d)" % form.slots.slot_count())
        return

    if form.get_total_aircraft() != 300:
        fail("total aircraft in armada must be 300 (found %d)" % form.get_total_aircraft())
        return

    print("TEST PASS: formation of 6 bombers verified")
    quit(0)
