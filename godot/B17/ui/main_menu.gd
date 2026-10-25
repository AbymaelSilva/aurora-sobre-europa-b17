extends Control

const SettingsManager = preload("res://core/settings_manager.gd")
const OptionsMenu = preload("res://ui/options_menu.gd")
const SaveGame = preload("res://core/save_game.gd")
const I18N = preload("res://core/i18n.gd")

var continue_button: Button
var play_button: Button
var options_button: Button
var credits_button: Button
var quit_button: Button
var options_menu: Control
var credits_panel: Control

func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    var app_settings: Dictionary = SettingsManager.load_all()
    SettingsManager.apply_video(app_settings)
    SettingsManager.apply_audio(app_settings)

    var bg := ColorRect.new()
    bg.color = Color(0.05, 0.07, 0.09)
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(bg)

    var vbox := VBoxContainer.new()
    vbox.add_theme_constant_override("separation", 14)
    vbox.set_anchors_preset(Control.PRESET_CENTER)
    add_child(vbox)

    var title := Label.new()
    title.text = I18N.t("title")
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 36)
    title.add_theme_color_override("font_color", Color(0.92, 0.94, 0.94))
    vbox.add_child(title)

    var subtitle := Label.new()
    subtitle.text = I18N.t("subtitle")
    subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    subtitle.add_theme_font_size_override("font_size", 16)
    subtitle.add_theme_color_override("font_color", Color(0.88, 0.74, 0.46))
    vbox.add_child(subtitle)

    var spacer := Control.new()
    spacer.custom_minimum_size = Vector2(0, 20)
    vbox.add_child(spacer)

    play_button = Button.new()
    play_button.name = "PlayButton"
    play_button.text = I18N.t("play")
    play_button.custom_minimum_size = Vector2(260, 44)
    play_button.focus_mode = Control.FOCUS_ALL
    play_button.pressed.connect(func():
        SaveGame.pending_continue = false
        get_tree().change_scene_to_file("res://game.tscn"))
    vbox.add_child(play_button)

    if SaveGame.has_save():
        continue_button = Button.new()
        continue_button.name = "ContinueButton"
        continue_button.text = I18N.t("continue")
        continue_button.custom_minimum_size = Vector2(260, 44)
        continue_button.focus_mode = Control.FOCUS_ALL
        continue_button.pressed.connect(func():
            SaveGame.pending_continue = true
            get_tree().change_scene_to_file("res://game.tscn"))
        vbox.add_child(continue_button)
        vbox.move_child(continue_button, vbox.get_children().find(play_button) + 1)

    options_button = Button.new()
    options_button.name = "OptionsButton"
    options_button.text = I18N.t("options")
    options_button.custom_minimum_size = Vector2(260, 44)
    options_button.focus_mode = Control.FOCUS_ALL
    options_button.pressed.connect(_open_options)
    vbox.add_child(options_button)

    credits_button = Button.new()
    credits_button.name = "CreditsButton"
    credits_button.text = I18N.t("credits")
    credits_button.custom_minimum_size = Vector2(260, 44)
    credits_button.focus_mode = Control.FOCUS_ALL
    credits_button.pressed.connect(_open_credits)
    vbox.add_child(credits_button)

    quit_button = Button.new()
    quit_button.name = "QuitButton"
    quit_button.text = I18N.t("quit")
    quit_button.custom_minimum_size = Vector2(260, 44)
    quit_button.focus_mode = Control.FOCUS_ALL
    quit_button.pressed.connect(func(): get_tree().quit())
    vbox.add_child(quit_button)

    var version_label := Label.new()
    version_label.text = "Godot 4.7.2 · build local %s" % Time.get_date_string_from_system()
    version_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    version_label.add_theme_font_size_override("font_size", 11)
    version_label.add_theme_color_override("font_color", Color(0.6, 0.65, 0.68))
    version_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
    version_label.position.y -= 24
    add_child(version_label)

    if continue_button != null:
        continue_button.grab_focus()
    else:
        play_button.grab_focus()

func _open_options() -> void:
    if options_menu != null and is_instance_valid(options_menu):
        options_menu.visible = true
        options_menu.move_to_front()
        return
    options_menu = OptionsMenu.new()
    options_menu.name = "OptionsMenu"
    add_child(options_menu)
    options_menu.closed.connect(func():
        options_menu.visible = false
        options_button.grab_focus()
    )

func _open_credits() -> void:
    if credits_panel != null and is_instance_valid(credits_panel):
        credits_panel.visible = true
        credits_panel.move_to_front()
        return
    credits_panel = Control.new()
    credits_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    credits_panel.mouse_filter = Control.MOUSE_FILTER_STOP
    add_child(credits_panel)

    var dim := ColorRect.new()
    dim.color = Color(0.0, 0.0, 0.0, 0.6)
    dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
    credits_panel.add_child(dim)

    var panel := PanelContainer.new()
    var sbox := StyleBoxFlat.new()
    sbox.bg_color = Color(0.08, 0.09, 0.11, 0.97)
    sbox.set_corner_radius_all(6)
    sbox.set_content_margin_all(18)
    panel.add_theme_stylebox_override("panel", sbox)
    panel.custom_minimum_size = Vector2(520, 320)
    panel.set_anchors_preset(Control.PRESET_CENTER)
    credits_panel.add_child(panel)

    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation", 8)
    panel.add_child(box)

    var title := Label.new()
    title.text = I18N.t("credits").to_upper()
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 20)
    box.add_child(title)

    var lines := [
        "Aurora sobre Europa — proyecto personal de Abimael Silva.",
        "Motor: Godot Engine 4.7.2.",
        "Arte de terreno y texturas: OpenArt.",
        "Modelos 3D: Meshy.",
        "Voces y música: locución en inglés de época con subtítulos en español.",
        "Construido con apoyo de asistentes de programación (Qwen, Codex, Claude) bajo supervisión humana.",
    ]
    for line in lines:
        var lbl := Label.new()
        lbl.text = line
        lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        box.add_child(lbl)

    var back := Button.new()
    back.text = I18N.t("back")
    back.pressed.connect(func():
        credits_panel.visible = false
        credits_button.grab_focus()
    )
    box.add_child(back)

func _input(event: InputEvent) -> void:
    if (options_menu != null and options_menu.visible) or (credits_panel != null and credits_panel.visible):
        if event.is_action_pressed("ui_cancel") and credits_panel != null and credits_panel.visible:
            credits_panel.visible = false
            credits_button.grab_focus()
            get_viewport().set_input_as_handled()
        return
    var focused: Control = get_viewport().gui_get_focus_owner()
    if focused == null:
        return
    if event.is_action_pressed("ui_down"):
        var next: Control = focused.find_valid_focus_neighbor(SIDE_BOTTOM)
        if next != null:
            next.grab_focus()
    elif event.is_action_pressed("ui_up"):
        var prev: Control = focused.find_valid_focus_neighbor(SIDE_TOP)
        if prev != null:
            prev.grab_focus()
