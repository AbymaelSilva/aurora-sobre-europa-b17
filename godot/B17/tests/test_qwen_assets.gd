extends SceneTree

func _initialize() -> void:
    call_deferred("check_assets")

func fail(message: String) -> void:
    print("TEST FAIL: ",message)
    quit(1)

func check_assets() -> void:
    var yard = load("res://world/rail_target.gd").new()
    root.add_child(yard)
    if yard.get_child_count()!=52 or yard.materials.size()!=4:
        fail("yard geometry or material reuse differs from contract")
        return
    var cloud_a = load("res://world/cloud_layer.gd").new()
    var cloud_b = load("res://world/cloud_layer.gd").new()
    root.add_child(cloud_a)
    root.add_child(cloud_b)
    if cloud_a.get_child_count()!=24:
        fail("expected 24 clouds")
        return
    for i in range(24):
        if cloud_a.get_child(i).position!=cloud_b.get_child(i).position:
            fail("cloud layer is not deterministic")
            return
    var burst = load("res://visuals/flak_burst.gd").new()
    root.add_child(burst)
    burst.trigger(Vector3(3,1200,-100))
    if not burst.visible or not burst.get_child(0).visible:
        fail("flak effect's children remain hidden")
        return
    burst.advance(4.0)
    if burst.active or burst.visible:
        fail("flak does not expire")
        return
    burst.reset()
    if burst.scale!=Vector3.ONE or burst.age!=0:
        fail("flak reset incomplete")
        return
    var markings = load("res://visuals/markings.gd").new()
    root.add_child(markings)
    if markings.get_child_count()!=3:
        fail("missing aircraft markings")
        return
    var bomb = load("res://visuals/bomb_body.gd").new()
    root.add_child(bomb)
    if bomb.get_child_count()!=6:
        fail("bomb geometry incomplete")
        return
    var radio = load("res://core/radio_director.gd").new()
    radio.advance(0.0,"FORMACION",100.0)
    if radio.message.is_empty():
        fail("missing formation radio message")
        return
    radio.advance(9.0,"FORMACION",100.0)
    if not radio.message.is_empty():
        fail("radio message did not expire")
        return
    radio.reset()
    if radio.last_phase!="" or radio.remaining!=0.0:
        fail("radio reset incomplete")
        return
    var report = load("res://core/debrief.gd").build("COMPLETADA",56.0,PackedFloat32Array([100,0,20,100]),783.0,"IMPACTO")
    if not report.success or report.engines_available!=3 or report.duration_seconds!=783.0:
        fail("debrief results do not match outcome")
        return
    var missed = load("res://core/debrief.gd").build("FALLIDA",56.0,PackedFloat32Array([0,0,0,0]),100.0,"FALLO")
    if missed.success or missed.engines_available!=0 or not "bombardeo" in missed.detail:
        fail("debrief miss outcome incorrect")
        return
    var tone = load("res://audio/engine_tone.gd").create_stream()
    if tone.data.size()!=44100 or tone.mix_rate!=22050 or tone.loop_end!=22050 or tone.format!=AudioStreamWAV.FORMAT_16_BITS:
        fail("synthesized audio format or loop incorrect")
        return
    var energy: float = 0.0
    for i in range(22050): energy += absf(float(tone.data.decode_s16(i*2)))
    if energy<100000.0:
        fail("engine tone is silent")
        return
    var trail = load("res://visuals/engine_smoke.gd").new()
    root.add_child(trail)
    trail.set_damage(100.0)
    if trail.get_child(0).visible:
        fail("healthy engines emit smoke")
        return
    trail.set_damage(40.0)
    if not trail.get_child(0).visible or trail.get_child(5).scale.x<=trail.get_child(0).scale.x:
        fail("damage smoke not visible or fails to expand along trail")
        return
    var marker = load("res://ui/navigation_marker.gd").new()
    root.add_child(marker)
    marker.set_target(Vector2(500,300),2000.0,true)
    if not marker.show_marker or marker.distance_m!=2000.0:
        fail("navigation marker does not receive target")
        return
    await process_frame
    for node in [yard,cloud_a,cloud_b,burst,markings,bomb,trail,marker]: node.queue_free()
    await process_frame
    print("TEST PASS: all ten Qwen modules instantiate and satisfy functional contracts")
    quit(0)
