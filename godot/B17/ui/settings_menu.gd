extends Control

const InputProfile = preload("res://core/input_profile.gd")

signal resume_requested
signal restart_requested
signal profile_changed(name: String)
signal audio_changed(kind: String, enabled: bool)
signal options_requested
signal main_menu_requested
signal quit_requested

var current_profile: String = "TECLADO_RATON"
var resume_button: Button
var profile_button: Button
var restart_button: Button
var options_button: Button
var main_menu_button: Button
var quit_button: Button
var hint_label: Label
var back_hint_label: Label
var music_button: Button
var voice_button: Button
var music_enabled: bool = true
var voice_enabled: bool = true
var restart_armed: bool = false
var restart_confirm_timer: float = 0.0

func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    mouse_filter = Control.MOUSE_FILTER_STOP
    set_process(true)
    var bg := ColorRect.new()
    bg.color = Color(0.0, 0.0, 0.0, 0.5)
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(bg)

    var panel := PanelContainer.new()
    var sbox := StyleBoxFlat.new()
    sbox.bg_color = Color(0.08, 0.09, 0.11, 0.96)
    sbox.set_corner_radius_all(6)
    sbox.set_content_margin_all(16)
    panel.add_theme_stylebox_override("panel", sbox)
    panel.custom_minimum_size = Vector2(480, 420)
    panel.set_anchors_preset(Control.PRESET_CENTER)
    panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
    panel.grow_vertical = Control.GROW_DIRECTION_BOTH
    add_child(panel)

    var vbox := VBoxContainer.new()
    vbox.add_theme_constant_override("separation", 10)
    panel.add_child(vbox)

    var title := Label.new()
    title.text = "PAUSA"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 20)
    vbox.add_child(title)

    resume_button = Button.new()
    resume_button.name = "ResumeButton"
    resume_button.text = "Reanudar"
    resume_button.focus_mode = Control.FOCUS_ALL
    resume_button.pressed.connect(func(): resume_requested.emit())
    vbox.add_child(resume_button)

    options_button = Button.new()
    options_button.name = "OptionsButton"
    options_button.text = "Opciones"
    options_button.focus_mode = Control.FOCUS_ALL
    options_button.pressed.connect(func(): options_requested.emit())
    vbox.add_child(options_button)

    restart_button = Button.new()
    restart_button.name = "RestartButton"
    restart_button.text = "Reiniciar misión"
    restart_button.focus_mode = Control.FOCUS_ALL
    restart_button.pressed.connect(_on_restart_pressed)
    vbox.add_child(restart_button)

    var separator := HSeparator.new()
    vbox.add_child(separator)

    var quick_label := Label.new()
    quick_label.text = "AJUSTES RÁPIDOS"
    quick_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    quick_label.add_theme_font_size_override("font_size", 12)
    vbox.add_child(quick_label)

    profile_button = Button.new()
    profile_button.name = "ProfileButton"
    profile_button.focus_mode = Control.FOCUS_ALL
    profile_button.pressed.connect(func(): cycle_profile(1))
    profile_button.gui_input.connect(_on_profile_button_gui_input)
    vbox.add_child(profile_button)

    music_button = Button.new()
    music_button.name = "MusicButton"
    music_button.pressed.connect(func():
        music_enabled = not music_enabled
        audio_changed.emit("music", music_enabled)
        _update_ui()
    )
    vbox.add_child(music_button)
    voice_button = Button.new()
    voice_button.name = "VoiceButton"
    voice_button.pressed.connect(func():
        voice_enabled = not voice_enabled
        audio_changed.emit("voice", voice_enabled)
        _update_ui()
    )
    vbox.add_child(voice_button)

    var separator2 := HSeparator.new()
    vbox.add_child(separator2)

    main_menu_button = Button.new()
    main_menu_button.name = "MainMenuButton"
    main_menu_button.text = "Volver al menú principal"
    main_menu_button.focus_mode = Control.FOCUS_ALL
    main_menu_button.pressed.connect(func(): main_menu_requested.emit())
    vbox.add_child(main_menu_button)

    quit_button = Button.new()
    quit_button.name = "QuitButton"
    quit_button.text = "Salir del juego"
    quit_button.focus_mode = Control.FOCUS_ALL
    quit_button.pressed.connect(func(): quit_requested.emit())
    vbox.add_child(quit_button)

    hint_label = Label.new()
    hint_label.name = "HintLabel"
    hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    hint_label.add_theme_font_size_override("font_size", 12)
    vbox.add_child(hint_label)

    back_hint_label = Label.new()
    back_hint_label.name = "BackHintLabel"
    back_hint_label.text = "Esc / B: cerrar este menú"
    back_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    back_hint_label.add_theme_font_size_override("font_size", 11)
    vbox.add_child(back_hint_label)

    _update_ui()

func _on_restart_pressed() -> void:
    if restart_armed:
        restart_armed = false
        restart_confirm_timer = 0.0
        restart_button.text = "Reiniciar misión"
        restart_requested.emit()
    else:
        restart_armed = true
        restart_confirm_timer = 3.0
        restart_button.text = "¿Reiniciar? Pulsa otra vez"

func _process(delta: float) -> void:
    if not visible:
        return
    if restart_confirm_timer > 0.0:
        restart_confirm_timer = maxf(0.0, restart_confirm_timer - delta)
        if restart_confirm_timer <= 0.0 and restart_armed:
            restart_armed = false
            if restart_button != null:
                restart_button.text = "Reiniciar misión"

func _on_profile_button_gui_input(ev: InputEvent) -> void:
    if ev.is_action_pressed("ui_left"):
        cycle_profile(-1)
        accept_event()
    elif ev.is_action_pressed("ui_right"):
        cycle_profile(1)
        accept_event()

func set_profile(name: String) -> void:
    current_profile = name
    _update_ui()

func cycle_profile(step: int = 1) -> void:
    var idx: int = InputProfile.PROFILES.find(current_profile)
    if idx < 0:
        idx = 0
    idx = (idx + step + InputProfile.PROFILES.size()) % InputProfile.PROFILES.size()
    current_profile = InputProfile.PROFILES[idx]
    _update_ui()
    profile_changed.emit(current_profile)

func _update_ui() -> void:
    if music_button != null:
        music_button.text = "Música: " + ("Activada" if music_enabled else "Silenciada")
    if voice_button != null:
        voice_button.text = "Voces: " + ("Activadas" if voice_enabled else "Silenciadas") + " · Subtítulos activos"
    if profile_button != null:
        profile_button.text = "Controles: ◀ %s ▶" % InputProfile.display_name(current_profile)
    if hint_label != null:
        var p_pilot: String = InputProfile.prompt("piloto", current_profile)
        var p_gun: String = InputProfile.prompt("disparar", current_profile)
        var p_bomb: String = InputProfile.prompt("soltar", current_profile)
        var p_pause: String = InputProfile.prompt("pausa", current_profile)
        hint_label.text = ("Piloto: %s · Disparo: %s · Bomba: %s · Pausa: %s\n" +
            "Motores: F1-F4 embanderar, Ctrl+F1-F4 extintor · Torretas: Q alterna · Escoltas: E") % [p_pilot, p_gun, p_bomb, p_pause]

func grab_initial_focus() -> void:
    if resume_button != null:
        resume_button.grab_focus()

func handle_input(event: InputEvent) -> bool:
    if not visible:
        return false
    var focused: Control = get_viewport().gui_get_focus_owner()
    if event.is_action_pressed("ui_down"):
        if focused != null:
            var next: Control = focused.find_valid_focus_neighbor(SIDE_BOTTOM)
            if next != null:
                next.grab_focus()
        return true
    elif event.is_action_pressed("ui_up"):
        if focused != null:
            var prev: Control = focused.find_valid_focus_neighbor(SIDE_TOP)
            if prev != null:
                prev.grab_focus()
        return true
    elif event.is_action_pressed("ui_left"):
        if focused == profile_button:
            cycle_profile(-1)
            return true
        return false
    elif event.is_action_pressed("ui_right"):
        if focused == profile_button:
            cycle_profile(1)
            return true
        return false
    elif event.is_action_pressed("ui_accept"):
        if focused is Button:
            focused.emit_signal("pressed")
            return true
        return false
    elif event.is_action_pressed("ui_cancel"):
        resume_requested.emit()
        return true
    return false
