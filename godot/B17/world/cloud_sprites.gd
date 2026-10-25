# world/cloud_sprites.gd
# Distribución de nubes realistas 2.5D en dos capas (Lote 8) con fallback automático
extends Node3D

@export var count: int = 100
@export var seed_value: int = 1944
@export var area_x_min: float = -14000.0
@export var area_x_max: float = 14000.0
@export var area_z_min: float = -38000.0
@export var area_z_max: float = 8000.0

# Dos capas de altitud (1.1.6.7):
# Capa baja: 1800 - 2600 m
# Capa alta: 4000 - 4800 m
const LAYER1_Y_MIN: float = 1800.0
const LAYER1_Y_MAX: float = 2600.0
const LAYER2_Y_MIN: float = 4000.0
const LAYER2_Y_MAX: float = 4800.0

var sprites: Array[Sprite3D] = []
var used_texture_path: String = ""

func _ready() -> void:
	if sprites.is_empty():
		_spawn_clouds()

func _spawn_clouds() -> void:
	for s in sprites:
		if is_instance_valid(s):
			s.queue_free()
	sprites.clear()
	
	# Comprobar recurso OpenArt Realistic V2 o fallback al existente (1.1.6.7)
	var new_path: String = "res://assets/sky/cloud_atlas_realistic_v2.png"
	var fallback_path: String = "res://assets/sky/cloud_atlas.png"
	var tex: Texture2D = null
	
	if ResourceLoader.exists(new_path):
		tex = load(new_path) as Texture2D
		used_texture_path = new_path
	
	if tex == null and ResourceLoader.exists(fallback_path):
		tex = load(fallback_path) as Texture2D
		used_texture_path = fallback_path
	
	if tex == null:
		return
	
	var tex_size: Vector2 = tex.get_size()
	var cell: Vector2 = tex_size / 4.0
	var is_4k: bool = tex_size.x >= 3800.0
	
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	
	var target_count: int = clampi(count, 80, 160)
	
	for i in range(target_count):
		var s := Sprite3D.new()
		s.texture = tex
		s.region_enabled = true
		
		# Región 4x4 (16 celdas)
		var c: int = rng.randi_range(0, 15)
		var col: int = c % 4
		var row: int = c / 4
		# Inset de 8 px para evitar contaminación entre celdas vecinas
		var inset: float = 8.0 if is_4k else 4.0
		var r_pos := Vector2(float(col) * cell.x + inset, float(row) * cell.y + inset)
		var r_size := Vector2(cell.x - inset * 2.0, cell.y - inset * 2.0)
		s.region_rect = Rect2(r_pos, r_size)
		
		s.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
		s.shaded = false
		s.transparent = true
		s.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		
		# Tamaño físico final 250 - 800 m (1.1.6.7)
		if is_4k:
			# ~1024px celda: 0.25 - 0.78 m/px -> 250 - 800 m
			s.pixel_size = rng.randf_range(0.25, 0.78)
		else:
			# ~512px celda: 0.50 - 1.40 m/px -> 250 - 700 m
			s.pixel_size = rng.randf_range(0.50, 1.40)
		
		s.modulate = Color(1.0, 1.0, 1.0, rng.randf_range(0.70, 0.90))
		
		# Distribución en dos capas (60% capa baja 1800-2600m, 40% capa alta 4000-4800m)
		var y_pos: float = 0.0
		if rng.randf() < 0.60:
			y_pos = rng.randf_range(LAYER1_Y_MIN, LAYER1_Y_MAX)
		else:
			y_pos = rng.randf_range(LAYER2_Y_MIN, LAYER2_Y_MAX)
		
		var x_pos: float = rng.randf_range(area_x_min, area_x_max)
		# Conservar corredor despejado en X central [-250, 250] a la altura de vuelo para visibilidad de la formación
		if absf(x_pos) < 250.0 and y_pos > 2000.0 and y_pos < 2600.0:
			x_pos = (350.0 if x_pos >= 0.0 else -350.0) + rng.randf_range(0.0, 300.0)
		
		var z_pos: float = rng.randf_range(area_z_min, area_z_max)
		s.position = Vector3(x_pos, y_pos, z_pos)
		
		add_child(s)
		sprites.append(s)

func cloud_count() -> int:
	if sprites.is_empty():
		_spawn_clouds()
	return sprites.size()
