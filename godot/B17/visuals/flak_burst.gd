# visuals/flak_burst.gd
# Bocanada individual de flak optimizada (2-3 Sprite3D, diámetro real 10-22 m, sin sombras)
extends Node3D

var age: float = 0.0
var lifetime: float = 10.0
var active: bool = false
var sprites: Array[Sprite3D] = []
var base_scale: float = 1.0
var max_scale: float = 2.2

# Texturas cacheadas compartidas para evitar recargas
static var cached_textures: Array[Texture2D] = []

static func _get_flak_texture(idx: int) -> Texture2D:
	if cached_textures.is_empty():
		for t in range(1, 10):
			var path := "res://assets/vfx/flak_%02d.png" % t
			if ResourceLoader.exists(path):
				cached_textures.append(load(path) as Texture2D)
	if cached_textures.is_empty():
		return null
	return cached_textures[idx % cached_textures.size()]

func _ready() -> void:
	# 3 sprites ligeramente desplazados y rotados para volumen sin excesivo overdraw
	for i in range(3):
		var s := Sprite3D.new()
		var tex := _get_flak_texture(i)
		if tex != null:
			s.texture = tex
		s.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		s.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		s.pixel_size = 0.02 # Con textura ~400px: 400 * 0.02 = 8m base
		s.position = Vector3(
			sin(float(i) * 2.1) * 0.8,
			cos(float(i) * 1.7) * 0.6,
			cos(float(i) * 2.5) * 0.8
		)
		s.modulate = Color(0.92, 0.92, 0.92, 0.85)
		add_child(s)
		sprites.append(s)
	visible = false

func trigger(origin: Vector3, burst_lifetime: float = 10.0, tex_offset: int = 0) -> void:
	if is_inside_tree():
		global_position = origin
	else:
		position = origin
	age = 0.0
	lifetime = maxf(burst_lifetime, 1.0)
	active = true
	visible = true
	var rng := RandomNumberGenerator.new()
	rng.seed = 1944 + tex_offset
	base_scale = rng.randf_range(1.1, 1.4)
	max_scale = rng.randf_range(2.0, 2.4)
	scale = Vector3.ONE * base_scale
	
	# Variar texturas por bocanada
	for i in range(sprites.size()):
		var s := sprites[i]
		var tex := _get_flak_texture(i + tex_offset)
		if tex != null:
			s.texture = tex
		s.rotation.z = rng.randf_range(0.0, TAU)
		s.modulate.a = 0.85

func advance(delta: float) -> void:
	if not active:
		return
	age += maxf(delta, 0.0)
	var progress: float = clampf(age / lifetime, 0.0, 1.0)
	
	# Expansión suave de 10m a 20m de diámetro
	var cur_scale: float = lerpf(base_scale, max_scale, sqrt(progress))
	scale = Vector3.ONE * cur_scale
	
	# Desvanecimiento no lineal suave (mantiene opacidad inicial y luego disuelve)
	var alpha: float = clampf((1.0 - progress) * 0.85, 0.0, 0.85)
	for s in sprites:
		s.modulate.a = alpha
	
	if age >= lifetime:
		active = false
		visible = false

func reset() -> void:
	age = 0.0
	active = false
	visible = false
	scale = Vector3.ONE
	for s in sprites:
		s.modulate.a = 0.85
