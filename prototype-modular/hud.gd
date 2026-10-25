extends CanvasLayer

var label: Label

func _ready():
    label = Label.new()
    label.position = Vector2(20, 20)
    label.add_theme_font_size_override("font_size", 22)
    add_child(label)

func update_hud(speed: float, altitude: float, paused: bool):
    label.text = "B-17 PROTOTIPO\nVelocidad: %.1f m/s\nAltitud: %.1f m\nEstado: %s\nControles:\nW/S: Ascender/Descender\nA/D: Girar\n↑/↓: Acelerar/Frenar\nESC: Pausar\nR: Reiniciar\nMando izquierdo: Pitch/Turn" % [speed, altitude, ("Pausado" if paused else "En vuelo")]
