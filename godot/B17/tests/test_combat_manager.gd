extends SceneTree

func _initialize() -> void:
    call_deferred("run_checks")

func fail(msg: String) -> void:
    print("TEST FAIL: ", msg)
    quit(1)

func run_checks() -> void:
    var script = load("res://core/combat_manager.gd")
    if not script:
        fail("could not load res://core/combat_manager.gd")
        return

    var mgr = script.new()
    var damage = load("res://core/damage.gd").new()
    var dt: float = 1.0 / 60.0

    # 1. Estado inicial
    if mgr.active_wave != 0 or mgr.total_kills != 0 or mgr.fighters.size() != 0:
        fail("initial state not zeroed")
        return

    # 2. Spawn oleada 1 en APROXIMACION (48 cazas de intercepcion masiva)
    var bomber_pos = Vector3(0, 1200, -4500)
    mgr.step(dt, bomber_pos, 0.0, "APROXIMACION", damage)
    if mgr.fighters.size() != 48 or mgr.active_wave != 1:
        fail("wave 1 did not spawn 48 fighters (found %d)" % mgr.fighters.size())
        return

    # 3. Simular combate durante varios segundos
    var initial_hull = damage.hull
    var shot_recorded = false
    var defensive_shot_recorded = false

    for i in range(60 * 15): # 15 segundos de simulación
        # Acercar el bombardero gradualmente hacia el frente
        bomber_pos.z -= 85.0 * dt
        mgr.step(dt, bomber_pos, 0.0, "APROXIMACION", damage)
        if mgr.enemy_shots.size() > 0:
            shot_recorded = true
        if mgr.defensive_shots.size() > 0:
            defensive_shot_recorded = true

    if not shot_recorded:
        fail("enemy fighters never fired within attack range")
        return

    if not defensive_shot_recorded:
        fail("defensive turrets never fired back at enemy fighters")
        return

    # Daño al B17 debe haberse recibido
    if damage.hull >= initial_hull:
        fail("B17 took no damage from enemy fighter attacks")
        return

    # 4. Derribo de cazas
    # Forzar daño a un caza para comprobar transición a derribado y conteo de bajas
    var f0 = mgr.fighters[0]
    f0["health"] = 5.0
    for i in range(120):
        mgr.step(dt, bomber_pos, 0.0, "APROXIMACION", damage)
        if not f0["alive"]:
            break

    if f0["alive"] or mgr.total_kills < 1:
        fail("damaged fighter was not downed by defensive fire")
        return

    # 5. Determinismo y reset
    mgr.reset()
    if mgr.active_wave != 0 or mgr.total_kills != 0 or mgr.fighters.size() != 0 or mgr.enemy_shots.size() != 0:
        fail("reset did not clear combat manager state")
        return

    print("TEST PASS: combat_manager wave spawning, dogfighting, damage delivery, defensive fire and reset")
    quit(0)
