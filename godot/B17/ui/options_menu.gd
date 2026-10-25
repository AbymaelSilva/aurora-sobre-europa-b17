extends Control

const SettingsManager = preload("res://core/settings_manager.gd")
const InputActions = preload("res://core/input_actions.gd")
const InputProfile = preload("res://core/input_profile.gd")
const I18N = preload("res://core/i18n.gd")

signal closed
signal setting_changed(key: String, value)

var data: Dictionary = {}
var awaiting_rebind_action: String = ""
var rebind_buttons: Dictionary = {}
var conflict_label: Label

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	data = SettingsManager.load_all()
	InputActions.ensure_defaults()

	var bg := ColorRect.new()
	bg.color = Color(0.0, 0.0, 0.0, 0.6)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var panel := PanelContainer.new()
	var sbox := StyleBoxFlat.new()
	sbox.bg_color = Color(0.07, 0.08, 0.1, 0.97)
	sbox.set_corner_radius_all(6)
	sbox.set_content_margin_all(18)
	panel.add_theme_stylebox_override("panel", sbox)
	panel.custom_minimum_size = Vector2(760, 520)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	add_child(panel)

	var root_box := VBoxContainer.new()
	root_box.add_theme_constant_override("separation", 10)
	panel.add_child(root_box)

	var title := Label.new()
	title.text = I18N.t("options_title")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	root_box.add_child(title)

	var tabs := TabContainer.new()
	tabs.name = "Tabs"
	tabs.custom_minimum_size = Vector2(720, 420)
	root_box.add_child(tabs)

	tabs.add_child(_build_audio_tab())
	tabs.add_child(_build_video_tab())
	tabs.add_child(_build_controls_tab())
	tabs.add_child(_build_gameplay_tab())
	tabs.add_child(_build_accessibility_tab())
	tabs.set_tab_title(0, I18N.t("tab_audio"))
	tabs.set_tab_title(1, I18N.t("tab_video"))
	tabs.set_tab_title(2, I18N.t("tab_controls"))
	tabs.set_tab_title(3, I18N.t("tab_gameplay"))
	tabs.set_tab_title(4, I18N.t("tab_accessibility"))

	conflict_label = Label.new()
	conflict_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	conflict_label.add_theme_color_override("font_color", Color(0.95, 0.4, 0.3))
	root_box.add_child(conflict_label)

	var back_row := HBoxContainer.new()
	back_row.alignment = BoxContainer.ALIGNMENT_CENTER
	var back_btn := Button.new()
	back_btn.name = "BackButton"
	back_btn.text = "%s (Esc)" % I18N.t("back")
	back_btn.pressed.connect(func(): closed.emit())
	back_row.add_child(back_btn)
	root_box.add_child(back_row)

func _slider_row(label_text: String, min_v: float, max_v: float, step: float, value: float, on_change: Callable) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var lbl := Label.new()
	lbl.text = label_text
	lbl.custom_minimum_size = Vector2(220, 0)
	row.add_child(lbl)
	var slider := HSlider.new()
	slider.min_value = min_v
	slider.max_value = max_v
	slider.step = step
	slider.value = value
	slider.custom_minimum_size = Vector2(300, 0)
	slider.value_changed.connect(on_change)
	row.add_child(slider)
	return row

func _check_row(label_text: String, pressed: bool, on_change: Callable) -> HBoxContainer:
	var row := HBoxContainer.new()
	var check := CheckButton.new()
	check.text = label_text
	check.button_pressed = pressed
	check.toggled.connect(on_change)
	row.add_child(check)
	return row

func _option_row(label_text: String, options: Array[String], display_names: Array, current: String, on_change: Callable) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var lbl := Label.new()
	lbl.text = label_text
	lbl.custom_minimum_size = Vector2(220, 0)
	row.add_child(lbl)
	var opt := OptionButton.new()
	for i in range(options.size()):
		opt.add_item(str(display_names[i]))
	var idx: int = options.find(current)
	opt.selected = maxi(idx, 0)
	opt.item_selected.connect(func(index: int): on_change.call(options[index]))
	row.add_child(opt)
	return row

func _apply_and_emit(key: String, value) -> void:
	data[key] = value
	SettingsManager.save_one(key, value)
	setting_changed.emit(key, value)

func _build_audio_tab() -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	box.name = "AudioTab"
	box.add_child(_slider_row("Volumen general", 0.0, 1.0, 0.01, data.master_volume, func(v):
		_apply_and_emit("master_volume", v)
		SettingsManager.apply_audio(data)))
	box.add_child(_slider_row("Música", 0.0, 1.0, 0.01, data.music_volume, func(v):
		_apply_and_emit("music_volume", v)
		SettingsManager.apply_audio(data)))
	box.add_child(_slider_row("Efectos", 0.0, 1.0, 0.01, data.effects_volume, func(v):
		_apply_and_emit("effects_volume", v)
		SettingsManager.apply_audio(data)))
	box.add_child(_slider_row("Voces", 0.0, 1.0, 0.01, data.voice_volume, func(v):
		_apply_and_emit("voice_volume", v)
		SettingsManager.apply_audio(data)))
	box.add_child(_check_row("Música activada", data.music_enabled, func(p):
		_apply_and_emit("music_enabled", p)))
	box.add_child(_check_row("Voces activadas (subtítulos siempre visibles)", data.voice_enabled, func(p):
		_apply_and_emit("voice_enabled", p)))
	return box

func _build_video_tab() -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	box.name = "VideoTab"
	var res_names: Array = []
	for r in SettingsManager.RESOLUTIONS:
		res_names.append("%d x %d" % [r.x, r.y])
	var res_keys: Array[String] = []
	for i in range(SettingsManager.RESOLUTIONS.size()):
		res_keys.append(str(i))
	box.add_child(_option_row("Resolución", res_keys, res_names, str(data.resolution_index), func(v):
		_apply_and_emit("resolution_index", int(v))
		SettingsManager.apply_video(data)))
	box.add_child(_option_row("Modo de pantalla", SettingsManager.WINDOW_MODES,
		["Ventana", "Pantalla completa", "Sin bordes"], data.window_mode, func(v):
		_apply_and_emit("window_mode", v)
		SettingsManager.apply_video(data)))
	box.add_child(_check_row("V-Sync", data.vsync, func(p):
		_apply_and_emit("vsync", p)
		SettingsManager.apply_video(data)))
	box.add_child(_option_row("Calidad gráfica", SettingsManager.QUALITIES,
		["Bajo", "Medio", "Alto"], data.graphics_quality, func(v):
		_apply_and_emit("graphics_quality", v)
		SettingsManager.apply_video(data)))
	return box

func _build_controls_tab() -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	box.name = "ControlsTab"
	box.add_child(_option_row("Perfil de control", InputProfile.PROFILES,
		[InputProfile.display_name("TECLADO_RATON"), InputProfile.display_name("XBOX"), InputProfile.display_name("ROG_ALLY_X")],
		InputProfile.load_profile(), func(v):
		InputProfile.save_profile(v)
		setting_changed.emit("profile", v)))
	box.add_child(_slider_row("Sensibilidad cabeceo", 0.5, 2.0, 0.05, data.pitch_sensitivity, func(v):
		_apply_and_emit("pitch_sensitivity", v)))
	box.add_child(_slider_row("Sensibilidad giro", 0.5, 2.0, 0.05, data.turn_sensitivity, func(v):
		_apply_and_emit("turn_sensitivity", v)))
	box.add_child(_slider_row("Sensibilidad potencia", 0.5, 2.0, 0.05, data.throttle_sensitivity, func(v):
		_apply_and_emit("throttle_sensitivity", v)))
	box.add_child(_check_row("Invertir cabeceo", data.invert_pitch, func(p):
		_apply_and_emit("invert_pitch", p)))

	var remap_title := Label.new()
	remap_title.text = "Remapeo de teclas (motores, torretas y disparo mantienen su tecla fija)"
	box.add_child(remap_title)
	for action in InputActions.REMAPPABLE:
		box.add_child(_remap_row(action))
	var reset_btn := Button.new()
	reset_btn.text = "Restaurar controles por defecto"
	reset_btn.pressed.connect(func():
		InputActions.reset_to_defaults()
		for action in rebind_buttons.keys():
			rebind_buttons[action].text = InputActions.key_label(action))
	box.add_child(reset_btn)
	return box

func _remap_row(action: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var lbl := Label.new()
	lbl.text = InputActions.LABELS.get(action, action)
	lbl.custom_minimum_size = Vector2(220, 0)
	row.add_child(lbl)
	var btn := Button.new()
	btn.text = InputActions.key_label(action)
	btn.custom_minimum_size = Vector2(160, 0)
	btn.pressed.connect(func():
		awaiting_rebind_action = action
		conflict_label.text = ""
		btn.text = "Pulsa una tecla…")
	rebind_buttons[action] = btn
	row.add_child(btn)
	return row

func _build_gameplay_tab() -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	box.name = "GameplayTab"
	box.add_child(_option_row("Dificultad", SettingsManager.DIFFICULTIES,
		["Fácil", "Normal", "Difícil"], data.difficulty, func(v):
		_apply_and_emit("difficulty", v)))
	box.add_child(_check_row("Ayudas de vuelo (controles más suaves)", data.flight_assist, func(p):
		_apply_and_emit("flight_assist", p)))
	return box

func _build_accessibility_tab() -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	box.name = "AccessibilityTab"
	box.add_child(_slider_row("Tamaño de subtítulos", 0.8, 1.6, 0.05, data.subtitle_scale, func(v):
		_apply_and_emit("subtitle_scale", v)))
	box.add_child(_slider_row("Opacidad de subtítulos", 0.3, 1.0, 0.05, data.subtitle_opacity, func(v):
		_apply_and_emit("subtitle_opacity", v)))
	box.add_child(_check_row("Reducir vibración de cámara e instrumentos (flak)", data.reduce_shake, func(p):
		_apply_and_emit("reduce_shake", p)))
	box.add_child(_option_row("Modo de color (daltonismo)", SettingsManager.COLORBLIND_MODES,
		["Ninguno", "Protanopía", "Deuteranopía", "Tritanopía"], data.colorblind_mode, func(v):
		_apply_and_emit("colorblind_mode", v)))
	box.add_child(_option_row("Idioma de interfaz", SettingsManager.UI_LANGUAGES,
		["Español", "English"], data.ui_language, func(v):
		_apply_and_emit("ui_language", v)))
	return box

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if not awaiting_rebind_action.is_empty():
		if event is InputEventKey and event.pressed and not event.echo:
			var action: String = awaiting_rebind_action
			var conflict: String = InputActions.rebind(action, event.physical_keycode)
			if conflict.is_empty():
				rebind_buttons[action].text = InputActions.key_label(action)
				conflict_label.text = ""
			else:
				rebind_buttons[action].text = InputActions.key_label(action)
				conflict_label.text = "Esa tecla ya está asignada a: %s" % InputActions.LABELS.get(conflict, conflict)
			awaiting_rebind_action = ""
			get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("ui_cancel"):
		closed.emit()
		get_viewport().set_input_as_handled()
