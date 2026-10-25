extends Control

var target_screen: Vector2 = Vector2.ZERO
var distance_m: float = 0.0
var show_marker: bool = false

func _ready():
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func set_target(point: Vector2, distance_value: float, enabled: bool):
    target_screen = Vector2(clampf(point.x,20.0,maxf(size.x-20.0,20.0)),clampf(point.y,20.0,maxf(size.y-20.0,20.0)))
    distance_m = distance_value
    show_marker = enabled
    queue_redraw()

func _draw():
    if not show_marker:
        return

    var gold_color = Color(0.88, 0.74, 0.46)
    var diamond_points = [
        target_screen + Vector2(-9, 0),
        target_screen + Vector2(0, -9),
        target_screen + Vector2(9, 0),
        target_screen + Vector2(0, 9),
        target_screen + Vector2(-9, 0)
    ]
    draw_polyline(diamond_points, gold_color, 2)

    var distance_text = "%.1f km" % (distance_m / 1000.0)
    draw_string(ThemeDB.fallback_font, target_screen + Vector2(14, 5), distance_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, gold_color)
