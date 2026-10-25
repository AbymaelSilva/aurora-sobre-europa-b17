extends Node3D

const EngineAnchors = preload("res://visuals/engine_anchors.gd")
const BombingAid = preload("res://core/bombing_aid.gd")
const InputProfile = preload("res://core/input_profile.gd")
const SfxBank = preload("res://audio/sfx_bank.gd")
const OrbitCamera = preload("res://camera/orbit_camera_controller.gd")

var orbit_camera = OrbitCamera.new()
var scene_audio: Node
var flak_field: Node3D

var sim = preload("res://core/simulation.gd").new()
var overlay: Control
var impact_age: float = 0.0
var visual_bursts: int = 0
var radio = preload("res://core/radio_director.gd").new()
var marker: Control
var engine_audio: AudioStreamPlayer
var engine_damaged_audio: AudioStreamPlayer
var gun_audio: AudioStreamPlayer
var flak_audio: AudioStreamPlayer
var bomb_audio: AudioStreamPlayer
var stinger_audio: AudioStreamPlayer
var sfx_pool: Array[AudioStreamPlayer] = []
var sfx_pool_index: int = 0
var sfx_play_counts: Dictionary = {}
var last_engine_station: String = ""
var last_station: String = ""
var last_bomb_spent: bool = false
var bomb_impacted: bool = false
var secondary_explosion_timer: float = -1.0
var last_aid_release_now: bool = false
var last_aid_status: String = ""
var last_radio_text: String = ""
var mission_stinger_played: bool = false
var flak_pool: Array[Node3D] = []
var impact_visual: Node3D
var tracer_pool: Node3D
var fighter_visuals: Array[Node3D] = []
var escort_visuals: Array[Node3D] = []
var bomb_visuals: Array[Node3D] = []
var engine_smokes: Array[Node3D] = []
var controls = preload("res://core/player_controls.gd").new()
var gunsight_rect: TextureRect
var bombsight_rect: TextureRect
var settings_menu: Control
var restart_confirm_timer: float = 0.0

func _ready() -> void:
    get_tree().auto_accept_quit = false

    var has_joy_a := false
    for ev in InputMap.action_get_events("ui_accept"):
        if ev is InputEventJoypadButton and ev.button_index == JOY_BUTTON_A:
            has_joy_a = true
            break
    if not has_joy_a:
        var ev_a := InputEventJoypadButton.new()
        ev_a.button_index = JOY_BUTTON_A
        InputMap.action_add_event("ui_accept", ev_a)

    var has_joy_b := false
    for ev in InputMap.action_get_events("ui_cancel"):
        if ev is InputEventJoypadButton and ev.button_index == JOY_BUTTON_B:
            has_joy_b = true
            break
    if not has_joy_b:
        var ev_b := InputEventJoypadButton.new()
        ev_b.button_index = JOY_BUTTON_B
        InputMap.action_add_event("ui_cancel", ev_b)

    var material := ShaderMaterial.new()
    material.shader = preload("res://world/farmland.gdshader")
    material.set_shader_parameter("farmland_texture", preload("res://assets/terrain/farmland_t1.png"))
    $Ground.material_override = material
    var ground_mesh := PlaneMesh.new()
    ground_mesh.size = Vector2(100000, 100000)
    $Ground.mesh = ground_mesh
    $Sun.rotation_degrees = Vector3(-16.0, -28.0, 0.0)
    $Sun.light_color = Color(0.94, 0.96, 1.0)
    $Sun.light_energy = 1.20
    $Sun.shadow_enabled = true
    $Sun.directional_shadow_max_distance = 600.0
    $Camera3D.fov = 65.0
    $Camera3D.near = 0.5
    $Camera3D.far = 18000.0
    $HUD.label.visible = false
    overlay = preload("res://ui/mission_overlay.gd").new()
    $HUD.add_child(overlay)
    $Scenery.visible = false

    var active_prof: String = "TECLADO_RATON"
    if FileAccess.file_exists("user://b17_settings.cfg"):
        active_prof = InputProfile.load_profile()
    else:
        var joy_names: Array = []
        for joy_id in Input.get_connected_joypads():
            joy_names.append(Input.get_joy_name(joy_id))
        active_prof = InputProfile.suggest_profile(joy_names)
    controls.profile = active_prof

    settings_menu = preload("res://ui/settings_menu.gd").new()
    settings_menu.name = "SettingsMenu"
    settings_menu.visible = false
    settings_menu.set_profile(active_prof)
    $HUD.add_child(settings_menu)

    settings_menu.resume_requested.connect(func():
        set_pause(false)
    )
    settings_menu.restart_requested.connect(func():
        restart_mission()
    )
    settings_menu.profile_changed.connect(func(new_prof: String):
        play_sfx("ui_profile_change", -8.0)
        controls.profile = new_prof
        InputProfile.save_profile(new_prof)
        update_presentation(0.0)
    )
    settings_menu.audio_changed.connect(func(kind: String, enabled: bool):
        if kind == "music": scene_audio.music_enabled = enabled
        elif kind == "voice": scene_audio.voice_enabled = enabled
        update_presentation(0.0)
    )

    gunsight_rect = TextureRect.new()
    gunsight_rect.texture = preload("res://assets/ui/gunsight_ring.png")
    gunsight_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
    gunsight_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    gunsight_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    gunsight_rect.visible = false
    $HUD.add_child(gunsight_rect)

    bombsight_rect = TextureRect.new()
    bombsight_rect.texture = preload("res://assets/ui/bombsight_norden.png")
    bombsight_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
    bombsight_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    bombsight_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    bombsight_rect.visible = false
    $HUD.add_child(bombsight_rect)

    for i in range(4):
        var s = preload("res://visuals/engine_smoke_trail.gd").new()
        add_child(s)
        engine_smokes.append(s)
    tracer_pool = preload("res://visuals/tracer_pool.gd").new()
    add_child(tracer_pool)
    for i in range(preload("res://core/combat_config.gd").ENEMY_COUNT):
        var f_node = preload("res://visuals/fighter.gd").new()
        f_node.variant = preload("res://core/combat_config.gd").variant_for(i)
        f_node.visible = false
        add_child(f_node)
        fighter_visuals.append(f_node)
    for i in range(16):
        var esc = preload("res://visuals/escort.gd").new()
        esc.setup_slot(i)
        add_child(esc)
        escort_visuals.append(esc)
    marker = preload("res://ui/navigation_marker.gd").new()
    $HUD.add_child(marker)

    engine_audio = AudioStreamPlayer.new()
    engine_audio.stream = SfxBank.get_stream("engine_b17_ext_loop")
    engine_audio.volume_db = -12.0
    add_child(engine_audio)
    engine_audio.play()

    engine_damaged_audio = AudioStreamPlayer.new()
    engine_damaged_audio.stream = SfxBank.get_stream("engine_b17_damaged_loop")
    engine_damaged_audio.volume_db = -14.0
    add_child(engine_damaged_audio)

    gun_audio = AudioStreamPlayer.new()
    var gun_variants := AudioStreamRandomizer.new()
    gun_variants.random_pitch = 1.0
    gun_variants.random_volume_offset_db = 0.0
    for variant in range(1, 4):
        gun_variants.add_stream(-1, SfxBank.get_stream("gun_m2_shot_%02d" % variant))
    gun_audio.stream = gun_variants
    gun_audio.max_polyphony = 4
    gun_audio.volume_db = -8.0
    add_child(gun_audio)

    flak_audio = AudioStreamPlayer.new()
    flak_audio.max_polyphony = 4
    flak_audio.volume_db = -6.0
    add_child(flak_audio)

    bomb_audio = AudioStreamPlayer.new()
    bomb_audio.max_polyphony = 4
    bomb_audio.volume_db = -4.0
    add_child(bomb_audio)

    stinger_audio = AudioStreamPlayer.new()
    stinger_audio.volume_db = -6.0
    add_child(stinger_audio)

    for i in range(4):
        var p := AudioStreamPlayer.new()
        add_child(p)
        sfx_pool.append(p)

    var yard_ground := preload("res://world/target_ground.gd").new()
    yard_ground.name = "TargetGround"
    add_child(yard_ground)
    yard_ground.position = sim.mission.target
    var yard := preload("res://world/rail_target.gd").new()
    yard.name = "RailTarget"
    add_child(yard)
    yard.position = sim.mission.target
    var clouds := preload("res://world/cloud_sprites.gd").new()
    clouds.name = "CloudLayer"
    add_child(clouds)
    $Aircraft.add_child(preload("res://visuals/bomber_details.gd").new())
    $Aircraft.add_child(preload("res://visuals/markings.gd").new())

    $BombVisual.mesh = null
    $BombVisual.add_child(preload("res://visuals/bomb_body.gd").new())
    bomb_visuals.append($BombVisual)
    for i in range(1, 30):
        var b_vis := Node3D.new()
        b_vis.name = "BombVisual_%d" % i
        b_vis.add_child(preload("res://visuals/bomb_body.gd").new())
        b_vis.visible = false
        add_child(b_vis)
        bomb_visuals.append(b_vis)

    flak_field = preload("res://visuals/flak_field.gd").new()
    flak_field.name = "DenseFlakField"
    add_child(flak_field)
    flak_pool.assign(flak_field.pool)

    impact_visual = Node3D.new()
    for i in range(4):
        var s := Sprite3D.new()
        var tex_idx := 6 + (i % 4)
        s.texture = load("res://assets/vfx/flak_%02d.png" % tex_idx)
        s.billboard = BaseMaterial3D.BILLBOARD_ENABLED
        s.modulate = Color(1.8, 0.9, 0.4, 1.0)
        s.pixel_size = 0.08
        s.position = Vector3(cos(float(i) * 1.5) * 5.0, 2.0 + float(i) * 2.0, sin(float(i) * 1.5) * 5.0)
        impact_visual.add_child(s)
    impact_visual.visible = false
    add_child(impact_visual)

    orbit_camera.setup($Aircraft, $Formation.wingmen, escort_visuals)
    scene_audio = preload("res://audio/scene_audio_director.gd").new()
    scene_audio.name = "SceneAudioDirector"
    add_child(scene_audio)
    var effects: Array = [engine_audio, engine_damaged_audio, gun_audio, flak_audio, bomb_audio, stinger_audio]
    effects.append_array(sfx_pool)
    effects.append_array(flak_field.audio_players)
    for player in effects:
        player.bus = scene_audio.EFFECTS_BUS
    reset_presentation()
    if "--camera-exterior" in OS.get_cmdline_user_args():
        orbit_camera.set_exterior(true, sim)
        update_presentation(0.0)

func play_sfx(sfx_name: String, volume_db: float = 0.0) -> AudioStreamPlayer:
    var stream = SfxBank.get_stream(sfx_name)
    if stream == null:
        return null
    sfx_play_counts[sfx_name] = sfx_play_counts.get(sfx_name, 0) + 1
    if sfx_pool.is_empty():
        return null
    var player = sfx_pool[sfx_pool_index]
    sfx_pool_index = (sfx_pool_index + 1) % sfx_pool.size()
    player.stream = stream
    player.volume_db = volume_db
    player.play()
    return player

func reset_presentation() -> void:
    orbit_camera.reset()
    if is_instance_valid(scene_audio):
        scene_audio.reset()
    impact_age = 0.0
    restart_confirm_timer = 0.0
    radio.reset()
    visual_bursts = 0
    last_engine_station = ""
    last_station = controls.station if controls != null else ""
    last_bomb_spent = false
    bomb_impacted = false
    secondary_explosion_timer = -1.0
    last_aid_release_now = false
    last_aid_status = ""
    last_radio_text = ""
    mission_stinger_played = false
    if is_instance_valid(engine_damaged_audio) and engine_damaged_audio.playing:
        engine_damaged_audio.stop()
    if is_instance_valid(stinger_audio) and stinger_audio.playing:
        stinger_audio.stop()
    if is_instance_valid(flak_field):
        flak_field.reset()
    if tracer_pool != null:
        tracer_pool.reset()
    for f in fighter_visuals:
        f.reset_effects()
        f.visible = false
    for esc in escort_visuals:
        esc.reset()
    for bv in bomb_visuals:
        bv.visible = false
    for s in engine_smokes:
        s.set_intensity(0.0)
    $FlakVisual.age = 10.0
    $FlakVisual.step(0.0)
    if impact_visual != null:
        impact_visual.visible = false
    update_presentation(0.0)

func set_pause(paused: bool) -> void:
    orbit_camera.reset_drag()
    if sim.paused != paused:
        if paused:
            play_sfx("ui_pause", -8.0)
        else:
            play_sfx("ui_back", -8.0)
    sim.paused = paused
    if settings_menu != null:
        settings_menu.visible = paused
        if paused:
            settings_menu.music_enabled = scene_audio.music_enabled
            settings_menu.voice_enabled = scene_audio.voice_enabled
            settings_menu._update_ui()
            settings_menu.move_to_front()
            settings_menu.set_profile(controls.profile)
            settings_menu.grab_initial_focus()
    update_presentation(0.0)

func restart_mission() -> void:
    set_pause(false)
    sim.reset()
    reset_presentation()

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
        if event.physical_keycode == KEY_F6 or event.keycode == KEY_F6:
            scene_audio.music_enabled = not scene_audio.music_enabled
            update_presentation(0.0)
            return
        elif event.physical_keycode == KEY_F7 or event.keycode == KEY_F7:
            scene_audio.voice_enabled = not scene_audio.voice_enabled
            update_presentation(0.0)
            return
        if event.physical_keycode == KEY_ESCAPE or event.physical_keycode == KEY_P or event.keycode == KEY_ESCAPE or event.keycode == KEY_P:
            set_pause(not sim.paused)
            return
        elif event.physical_keycode == KEY_R or event.keycode == KEY_R:
            if sim.mission.phase in ["COMPLETADA", "FALLIDA"]:
                restart_confirm_timer = 0.0
                restart_mission()
                return
            elif restart_confirm_timer > 0.0:
                restart_confirm_timer = 0.0
                restart_mission()
                return
            else:
                restart_confirm_timer = 2.0
                update_presentation(0.0)
                return
    elif event is InputEventJoypadButton and event.pressed:
        if event.button_index == JOY_BUTTON_START:
            set_pause(not sim.paused)
            return
        elif controls.profile != "TECLADO_RATON" and sim.mission.phase in ["COMPLETADA", "FALLIDA"] and event.button_index == JOY_BUTTON_A:
            restart_mission()
            return

    if settings_menu != null and settings_menu.visible:
        if settings_menu.handle_input(event):
            return

    if not sim.paused:
        if orbit_camera.handle_input(event, sim, controls.profile):
            update_presentation(0.0)
            return
        var previous_station: String = controls.station
        if controls.handle_event(event, sim):
            if controls.station != previous_station:
                orbit_camera.set_exterior(false, sim)
            update_presentation(0.0)
            return

func _physics_process(delta: float) -> void:
    if not sim.paused:
        orbit_camera.poll_input(delta, controls.profile)
        controls.poll_inputs(sim, delta, not orbit_camera.is_exterior)
    sim.step(delta)
    update_presentation(delta)

func update_presentation(delta: float) -> void:
    if sim.mission.phase in ["COMPLETADA", "FALLIDA"]:
        restart_confirm_timer = 0.0
    elif restart_confirm_timer > 0.0 and delta > 0.0:
        restart_confirm_timer = maxf(0.0, restart_confirm_timer - delta)

    var frozen: bool = sim.paused or sim.mission.phase in ["COMPLETADA", "FALLIDA"]
    var flight = sim.flight
    var bomb = sim.bomb

    var in_flak_zone: bool = flight.position.z < -13000.0 and flight.position.z > -26500.0 and absf(flight.position.x) < 1000.0
    flak_field.step(delta, in_flak_zone, flight.position, flight.yaw, $Camera3D, frozen)
    visual_bursts = sim.flak.bursts
    sfx_play_counts["flak"] = flak_field.audio_play_count

    if bomb.spent and not last_bomb_spent:
        bomb_audio.stream = SfxBank.get_stream("bomb_release")
        bomb_audio.play()
        sfx_play_counts["bomb_release"] = sfx_play_counts.get("bomb_release", 0) + 1
    elif bomb.active and "new_releases" in bomb and bomb.new_releases > 0:
        play_sfx("cue_release_tick", -10.0)
    last_bomb_spent = bomb.spent

    if not frozen:
        if "new_impacts" in bomb and bomb.new_impacts > 0:
            play_sfx("bomb_secondary_explosions", -5.0)

        if bomb.spent and not bomb.active:
            if not bomb_impacted:
                bomb_impacted = true
                bomb_audio.stream = SfxBank.get_stream("bomb_impact_distant")
                bomb_audio.play()
                sfx_play_counts["bomb_impact_distant"] = sfx_play_counts.get("bomb_impact_distant", 0) + 1
                if bomb.result == "IMPACTO":
                    secondary_explosion_timer = 0.8
            impact_age += delta

        if secondary_explosion_timer > 0.0:
            secondary_explosion_timer -= delta
            if secondary_explosion_timer <= 0.0:
                secondary_explosion_timer = -1.0
                play_sfx("bomb_secondary_explosions", -4.0)

        var mounts = preload("res://visuals/combat_mounts.gd")
        for shot in sim.combat.enemy_shots:
            var ai = sim.combat.fighters[shot["fighter"]]["ai"]
            var origin: Vector3 = mounts.fighter_mount(ai.position, ai.velocity)
            var dir: Vector3 = (shot["target"] - origin).normalized()
            tracer_pool.fire(origin, dir * 800.0)
            tracer_pool.flash(origin)
        for shot in sim.combat.defensive_shots:
            var origin: Vector3 = mounts.bomber_mount($Aircraft, shot["target"])
            var dir: Vector3 = (shot["target"] - origin).normalized()
            tracer_pool.fire(origin, dir * 850.0)
            tracer_pool.flash(origin)
            gun_audio.play()
            sfx_play_counts["gun_m2_shot"] = sfx_play_counts.get("gun_m2_shot", 0) + 1
        tracer_pool.advance(delta)

    tracer_pool.set_frozen(frozen)
    for i in range(fighter_visuals.size()):
        var f_vis = fighter_visuals[i]
        f_vis.set_process(not frozen)
        if i < sim.combat.fighters.size():
            var f_data = sim.combat.fighters[i]
            if f_data["health"] < 45.0 and not f_data.get("smoke_logged", false):
                f_data["smoke_logged"] = true
                sim.combat.damage_events.append({"fighter": i, "cause": f_data.get("damage_cause", "damage"), "effect": "engine_smoke", "health": f_data["health"]})
                if sim.combat.damage_events.size() > 96: sim.combat.damage_events.pop_front()
            f_vis.update_damage(f_data["health"], frozen)
            var f_pos: Vector3 = f_data["ai"].position
            f_vis.visible = f_pos.y > 0.0
            f_vis.position = f_pos
            if f_data["alive"]:
                var vel: Vector3 = f_data["ai"].velocity
                if vel.length_squared() > 1.0:
                    f_vis.basis = Basis.looking_at(vel.normalized(), Vector3.UP).rotated(vel.normalized(), f_data["ai"].bank)
            elif not frozen:
                var fall: Vector3 = f_data["fall_vel"]
                if fall.length_squared() > 1.0:
                    f_vis.basis = f_vis.basis.orthonormalized().slerp(Basis.looking_at(fall.normalized(), Vector3.UP), minf(delta, 1.0))
                f_vis.rotate_object_local(Vector3.FORWARD, delta * 0.35)
        else:
            f_vis.visible = false

    $Aircraft.position = flight.position
    $Aircraft.rotation = Vector3(flight.pitch, flight.yaw, 0)
    $Formation.follow(flight.position, flight.yaw, flight.pitch)
    for esc in escort_visuals:
        esc.update_combat(delta, flight.position, flight.yaw, flight.pitch, frozen, sim.combat, tracer_pool, controls)
    $Aircraft.get_node("Engines").set_process(not frozen)
    if "wingmen" in $Formation:
        for w in $Formation.wingmen:
            w.get_node("Engines").set_process(not frozen)
    if $Formation.has_method("set_fleet_processing"):
        $Formation.set_fleet_processing(not frozen)

    var smoke_positions: Array[Vector3] = EngineAnchors.get_smoke_positions($Aircraft)
    for i in range(mini(smoke_positions.size(), engine_smokes.size())):
        var s = engine_smokes[i]
        s.from_engine_health(sim.damage.engines[i])
        s.global_position = smoke_positions[i]
        s.rotation.y = flight.yaw
        if s.particles != null:
            s.particles.speed_scale = 0.0 if frozen else 1.0

    $BombVisual.visible = bomb.active
    $BombVisual.position = bomb.position
    $BombVisual.scale = Vector3.ONE * 1.5
    if bomb.active and bomb.velocity.length_squared() > 0.0:
        $BombVisual.quaternion = Quaternion(Vector3.DOWN, bomb.velocity.normalized())

    if "bombs" in bomb:
        for i in range(bomb_visuals.size()):
            var b_vis = bomb_visuals[i]
            if i < bomb.bombs.size():
                var b_data = bomb.bombs[i]
                b_vis.visible = b_data["active"]
                b_vis.position = b_data["position"]
                b_vis.scale = Vector3.ONE * 1.5
                if b_data["active"] and b_data["velocity"].length_squared() > 0.0:
                    b_vis.quaternion = Quaternion(Vector3.DOWN, b_data["velocity"].normalized())
            else:
                if b_vis != $BombVisual:
                    b_vis.visible = false
    else:
        for i in range(1, bomb_visuals.size()):
            bomb_visuals[i].visible = false

    var is_impacting: bool = (bool(bomb.spent) and not bool(bomb.active) and impact_age < 3.0)
    impact_visual.visible = is_impacting
    if is_impacting:
        impact_visual.position = bomb.position + Vector3.UP * 5.0
        impact_visual.scale = Vector3.ONE * (1.0 + minf(impact_age, 3.0) * 2.5)
        var alpha := clampf(1.0 - (impact_age / 3.0), 0.0, 1.0)
        for child in impact_visual.get_children():
            if child is Sprite3D:
                child.modulate.a = alpha

    $Aircraft.visible = orbit_camera.is_exterior or (controls.station != "BOMBARDERO")
    var cam: Camera3D = $Camera3D
    if orbit_camera.is_exterior:
        orbit_camera.update(0.0 if sim.paused else delta, cam, flight.yaw)
    elif bomb.active or (bomb.spent and impact_age < 3.0):
        cam.global_position = bomb.position + Vector3(60.0, 110.0, 85.0)
        cam.look_at(bomb.position + Vector3(0.0, 10.0, 0.0), Vector3.UP)
    elif controls.station == "ARTILLERO":
        var turret_local := Vector3(0.0, 2.8, -1.8)
        var turret_base_yaw: float = flight.yaw
        var turret_pitch: float = clampf(controls.aim.y, -deg_to_rad(20.0), deg_to_rad(85.0))
        if controls.gunner_station == "COLA":
            turret_local = Vector3(0.0, 0.8, 11.8)
            turret_base_yaw += PI
            turret_pitch = clampf(controls.aim.y, -deg_to_rad(10.0), deg_to_rad(25.0))
        elif controls.gunner_station == "VENTRAL":
            turret_local = Vector3(0.0, -1.8, -1.0)
            turret_pitch = clampf(controls.aim.y, -deg_to_rad(85.0), -deg_to_rad(10.0))
        cam.global_position = flight.position + turret_local.rotated(Vector3.UP, flight.yaw)
        var turret_yaw: float = turret_base_yaw + controls.aim.x
        cam.rotation = Vector3(turret_pitch, turret_yaw, 0.0)
    elif controls.station == "BOMBARDERO":
        var nose_local := Vector3(0.0, -0.8, -11.5)
        cam.global_position = flight.position + nose_local.rotated(Vector3.UP, flight.yaw)
        cam.rotation = Vector3(-deg_to_rad(78.0), flight.yaw, 0.0)
    else:
        cam.global_position = flight.position + Vector3(0.0, 22.0, 115.0).rotated(Vector3.UP, flight.yaw)
        cam.look_at(flight.position + Vector3(0.0, 0.0, -20.0).rotated(Vector3.UP, flight.yaw), Vector3.UP)

    scene_audio.update_scene(delta, sim)
    radio.message = scene_audio.subtitle
    if radio.message != last_radio_text:
        if not radio.message.is_empty():
            play_sfx("radio_squelch_open", -10.0)
        last_radio_text = radio.message

    var target_engine_stream_name: String = "engine_b17_ext_loop" if controls.station == "PILOTO" else "engine_b17_int_loop"
    if last_engine_station != controls.station:
        last_engine_station = controls.station
        engine_audio.stream = SfxBank.get_stream(target_engine_stream_name)
        engine_audio.play()

    if controls.station != last_station:
        if not last_station.is_empty():
            orbit_camera.set_exterior(false, sim)
        last_station = controls.station
        play_sfx("station_switch", -10.0)

    var any_engine_damaged: bool = false
    for eh in sim.damage.engines:
        if eh < 50.0:
            any_engine_damaged = true
            break
    if any_engine_damaged and not frozen:
        if not engine_damaged_audio.playing:
            engine_damaged_audio.play()
    else:
        if engine_damaged_audio.playing:
            engine_damaged_audio.stop()

    engine_audio.stream_paused = frozen
    if is_instance_valid(engine_damaged_audio):
        engine_damaged_audio.stream_paused = frozen
        engine_damaged_audio.pitch_scale = clampf(flight.speed / 85.0, 0.65, 1.3)
    gun_audio.stream_paused = frozen
    flak_audio.stream_paused = frozen
    bomb_audio.stream_paused = frozen
    if is_instance_valid(stinger_audio):
        stinger_audio.stream_paused = sim.paused
    for p in sfx_pool:
        if is_instance_valid(p):
            p.stream_paused = sim.paused
    engine_audio.pitch_scale = clampf(flight.speed / 85.0, 0.65, 1.3)

    if gunsight_rect != null and bombsight_rect != null:
        gunsight_rect.visible = not orbit_camera.is_exterior and (controls.station == "ARTILLERO")
        bombsight_rect.visible = not orbit_camera.is_exterior and (controls.station == "BOMBARDERO")
        var vp_size: Vector2 = get_viewport().get_visible_rect().size
        var ret_dim: float = minf(vp_size.x, vp_size.y) * 0.65
        for rect in [gunsight_rect, bombsight_rect]:
            rect.size = Vector2(ret_dim, ret_dim)
            rect.position = (vp_size - rect.size) / 2.0

    var destination: Vector3 = sim.mission.exit_point if sim.mission.phase == "REGRESO" else sim.mission.target
    var show_target: bool = not $Camera3D.is_position_behind(destination) and sim.mission.phase not in ["COMPLETADA", "FALLIDA"]
    var screen_point: Vector2 = $Camera3D.unproject_position(destination) if show_target else Vector2.ZERO
    marker.set_target(screen_point, flight.position.distance_to(destination), show_target)
    var report: Dictionary = preload("res://core/debrief.gd").build(sim.mission.phase, sim.damage.hull, sim.damage.engines, sim.mission.clock, bomb.result) if sim.mission.phase in ["COMPLETADA", "FALLIDA"] else {}
    var reason: String = "DERRIBO" if sim.damage.destroyed() else ("FALLO" if bomb.result == "FALLO" else "")
    var aid_data: Dictionary = BombingAid.calculate(flight, sim.mission.target, bomb.spent, sim.mission.phase)
    var current_release_now: bool = bool(aid_data.get("release_now", false))
    var current_aid_status: String = str(aid_data.get("status", ""))
    if current_release_now and not last_aid_release_now:
        play_sfx("cue_release_now", -8.0)
    last_aid_release_now = current_release_now

    if current_aid_status == "CORREGIR_RUMBO" and last_aid_status != "CORREGIR_RUMBO":
        play_sfx("cue_course_correction", -8.0)
    last_aid_status = current_aid_status

    if not mission_stinger_played:
        if sim.mission.phase == "COMPLETADA":
            mission_stinger_played = true
            stinger_audio.stream = SfxBank.get_stream("stinger_mission_complete")
            stinger_audio.play()
            sfx_play_counts["stinger_mission_complete"] = sfx_play_counts.get("stinger_mission_complete", 0) + 1
        elif sim.mission.phase == "FALLIDA":
            mission_stinger_played = true
            stinger_audio.stream = SfxBank.get_stream("stinger_mission_failed")
            stinger_audio.play()
            sfx_play_counts["stinger_mission_failed"] = sfx_play_counts.get("stinger_mission_failed", 0) + 1

    overlay.set_state({
        "phase": sim.mission.phase,
        "hull": sim.damage.hull,
        "engine": sim.damage.engine,
        "speed": flight.speed,
        "altitude": flight.position.y,
        "heading": fposmod(-rad_to_deg(flight.yaw), 360.0),
        "bomb_active": bomb.active,
        "salvo_count": bomb.released_count if "released_count" in bomb else (1 if bomb.spent else 0),
        "bomb_result": bomb.result,
        "elapsed": sim.mission.clock,
        "paused": sim.paused,
        "menu_visible": settings_menu.visible if settings_menu != null else false,
        "reason": reason,
        "radio": radio.message,
        "report": report,
        "distance": Vector2(flight.position.x, flight.position.z).distance_to(Vector2(sim.mission.target.x, sim.mission.target.z)),
        "autopilot": sim.autopilot,
        "station": controls.station,
        "kills": sim.combat.total_kills,
        "bombing_aid": aid_data,
        "input_profile": controls.profile,
        "restart_confirm": restart_confirm_timer > 0.0,
        "camera_exterior": orbit_camera.is_exterior,
        "camera_target": orbit_camera.target_name,
        "camera_observation": orbit_camera.observation_message,
        "engines_hp": sim.damage.engines,
        "engine_feathered": sim.damage.engine_feathered,
        "engine_action": controls.last_engine_action if controls.last_engine_action_timer > 0.0 else "",
        "gunner_station": controls.gunner_station,
        "altimeter_error": sim.damage.altimeter_error,
        "compass_drift": sim.damage.compass_drift,
        "norden_disabled": sim.damage.norden_disabled,
        "escort_cover_active": controls.escort_cover_requested,
        "escort_cover_timer": controls.escort_cover_timer
    })

func _notification(what: int) -> void:
    if what == NOTIFICATION_APPLICATION_FOCUS_OUT and orbit_camera != null:
        orbit_camera.reset_drag()
    if what == NOTIFICATION_WM_CLOSE_REQUEST:
        var all_audios := [engine_audio, engine_damaged_audio, gun_audio, flak_audio, bomb_audio, stinger_audio]
        all_audios.append_array(sfx_pool)
        for a in all_audios:
            if is_instance_valid(a):
                a.stop()
        await get_tree().create_timer(0.25).timeout
        get_tree().quit()
    elif what == NOTIFICATION_PREDELETE or what == NOTIFICATION_EXIT_TREE:
        var all_audios := [engine_audio, engine_damaged_audio, gun_audio, flak_audio, bomb_audio, stinger_audio]
        all_audios.append_array(sfx_pool)
        for a in all_audios:
            if is_instance_valid(a):
                a.stop()
                a.stream = null

func _exit_tree() -> void:
    var all_audios := [engine_audio, engine_damaged_audio, gun_audio, flak_audio, bomb_audio, stinger_audio]
    all_audios.append_array(sfx_pool)
    for a in all_audios:
        if is_instance_valid(a):
            a.stop()
            a.stream = null
