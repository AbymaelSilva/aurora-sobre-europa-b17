extends Node3D

func _ready():
    var labels: Array[Label3D] = []
    labels.append(_create_label(Vector3(-1.4, 0.4, 3.0), "AURORA • 01", 48, 0.012, Color(0.88, 0.85, 0.68), 4, -90))
    labels.append(_create_label(Vector3(1.4, 0.4, 3.0), "AURORA • 01", 48, 0.012, Color(0.88, 0.85, 0.68), 4, 90))
    labels.append(_create_label(Vector3(0, 2.5, 8.9), "A1", 64, 0.016, Color(1, 1, 1), 0, 90))
    for label in labels:
        add_child(label)

func _create_label(position: Vector3, text: String, font_size: int, pixel_size: float, modulate: Color, outline_size: int, rotation_degrees_y: int) -> Label3D:
    var label = Label3D.new()
    label.position = position
    label.text = text
    label.font_size = font_size
    label.pixel_size = pixel_size
    label.modulate = modulate
    label.outline_size = outline_size
    label.rotation_degrees.y = rotation_degrees_y
    return label
