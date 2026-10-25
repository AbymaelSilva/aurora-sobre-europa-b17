# visuals/flak_field.gd
# Campo denso de flak visual para el Lote 8 (60-100 simultáneos, pool 128, distribución 3D, audio acotado)
extends Node3D

const FlakBurstScene = preload("res://visuals/flak_burst.gd")

const POOL_SIZE: int = 128
const BURSTS_PER_SEC_MIN: float = 8.0
const BURSTS_PER_SEC_MAX: float = 10.0
const LIFETIME_MIN: float = 8.0
const LIFETIME_MAX: float = 12.0
const SEED_DEFAULT: int = 1944
const AUDIO_COOLDOWN_MIN: float = 0.20
const AUDIO_COOLDOWN_MAX: float = 0.35

var pool: Array[Node3D] = []
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var emit_timer: float = 0.0
var current_interval: float = 0.11
var audio_cooldown: float = 0.0
var burst_counter: int = 0

# Reproducción de audio con pool de 4 voces
var audio_players: Array[AudioStreamPlayer] = []
var audio_voice_index: int = 0
var audio_play_count: int = 0

func _init() -> void:
	rng.seed = SEED_DEFAULT
	_init_pool()
	_init_audio()
	_pick_next_interval()

func _ready() -> void:
	if pool.is_empty():
		_init_pool()
	if audio_players.is_empty():
		_init_audio()

func _init_pool() -> void:
	for i in range(POOL_SIZE):
		var burst := FlakBurstScene.new()
		burst.name = "FlakBurst_%03d" % i
		add_child(burst)
		pool.append(burst)

func _init_audio() -> void:
	for i in range(4):
		var asp := AudioStreamPlayer.new()
		asp.name = "FlakAudioVoice_%d" % (i + 1)
		asp.volume_db = -6.0
		add_child(asp)
		audio_players.append(asp)

func _pick_next_interval() -> void:
	# Intervalo aleatorio entre 0.08 y 0.16 s (media ~0.11s -> ~9 bocanadas/s)
	current_interval = rng.randf_range(0.08, 0.16)

func reset() -> void:
	emit_timer = 0.0
	audio_cooldown = 0.0
	burst_counter = 0
	audio_play_count = 0
	audio_voice_index = 0
	rng.seed = SEED_DEFAULT
	_pick_next_interval()
	for burst in pool:
		burst.reset()
	for asp in audio_players:
		if is_instance_valid(asp) and asp.playing:
			asp.stop()

func active_burst_count() -> int:
	var c: int = 0
	for burst in pool:
		if burst.active:
			c += 1
	return c

func step(delta: float, in_zone: bool, center_pos: Vector3, heading_yaw: float, cam: Camera3D, frozen: bool) -> void:
	if frozen:
		for asp in audio_players:
			if is_instance_valid(asp):
				asp.stream_paused = true
		return
	
	for asp in audio_players:
		if is_instance_valid(asp):
			asp.stream_paused = false
	
	# Envejecimiento de bocanadas activas
	for burst in pool:
		burst.advance(delta)
	
	if audio_cooldown > 0.0:
		audio_cooldown = maxf(0.0, audio_cooldown - delta)
	
	if not in_zone:
		# Fuera de zona, no emitir nuevas pero dejar que las activas se desvanezcan
		return
	
	emit_timer += maxf(delta, 0.0)
	
	# Emitir bocanadas recuperando frames lentos con tope de 5 por frame
	var emitted_this_frame: int = 0
	while emit_timer >= current_interval and emitted_this_frame < 5:
		emit_timer -= current_interval
		_emit_burst(center_pos, heading_yaw, cam)
		_pick_next_interval()
		emitted_this_frame += 1

func _emit_burst(center_pos: Vector3, heading_yaw: float, cam: Camera3D) -> void:
	# Buscar una ranura inactiva en el pool
	var target_burst = null
	for burst in pool:
		if not burst.active:
			target_burst = burst
			break
	if target_burst == null:
		# Si el pool está lleno al tope (128), reutilizar la más vieja
		var oldest_burst = pool[0]
		var max_age: float = -1.0
		for burst in pool:
			if burst.age > max_age:
				max_age = burst.age
				oldest_burst = burst
		target_burst = oldest_burst
	
	# Distribución espacial según especificación 1.1.4.3:
	# 25% cercano: 100-400 m
	# 45% medio: 400-1500 m
	# 30% lejano: 1500-3500 m
	# Altura relativa: -250 a +350 m
	var roll: float = rng.randf()
	var dist: float = 0.0
	if roll < 0.25:
		dist = rng.randf_range(100.0, 400.0)
	elif roll < 0.70:
		dist = rng.randf_range(400.0, 1500.0)
	else:
		dist = rng.randf_range(1500.0, 3500.0)
	
	# Concentración principal sobre la ruta para que el frente se vea tupido;
	# conservar un 30% alrededor de la formación al mirar hacia atrás.
	var angle: float = rng.randf_range(0.0, TAU)
	if rng.randf() < 0.70:
		angle = -PI / 2.0 + rng.randf_range(-0.55, 0.55)
	var rel_x: float = cos(angle) * dist
	var rel_z: float = sin(angle) * dist
	var rel_y: float = clampf(rng.randf_range(-0.20, 0.24) * dist, -250.0, 350.0)
	
	# Orientar según el rumbo de la formación
	var offset: Vector3 = Vector3(rel_x, rel_y, rel_z).rotated(Vector3.UP, heading_yaw)
	var world_pos: Vector3 = center_pos + offset
	
	# Zona de exclusión/baja probabilidad alrededor del punto de mira (1.1.4.4):
	# Si la bocanada es cercana (< 400m) y está en la línea directa de visión de la cámara (< 8° del centro),
	# desplazar lateralmente para no cegar la navegación.
	if cam != null and is_instance_valid(cam):
		var cam_to_burst: Vector3 = world_pos - cam.global_position
		var cam_dist: float = cam_to_burst.length()
		if cam_dist < 400.0 and cam_dist > 1.0:
			var cam_fwd: Vector3 = -cam.global_transform.basis.z.normalized()
			var dot: float = cam_fwd.dot(cam_to_burst.normalized())
			if dot > 0.985: # ~10 grados en radio de 90px
				# Desplazar a un lado
				world_pos += cam.global_transform.basis.x * (120.0 if rng.randf() > 0.5 else -120.0)
	
	var burst_lifetime: float = rng.randf_range(LIFETIME_MIN, LIFETIME_MAX)
	target_burst.trigger(world_pos, burst_lifetime, burst_counter)
	burst_counter += 1
	
	# Audio acotado por distancia (1.1.4.7):
	_try_play_flak_sound(world_pos, center_pos)

func _try_play_flak_sound(burst_pos: Vector3, player_pos: Vector3) -> void:
	var dist: float = player_pos.distance_to(burst_pos)
	if dist > 850.0:
		# Bocanadas lejanas no reproducen audio para evitar saturación
		return
	
	if audio_cooldown > 0.0:
		return
	
	# Disparar audio en la voz rotatoria del pool
	if audio_players.is_empty():
		return
	
	var asp: AudioStreamPlayer = audio_players[audio_voice_index]
	audio_voice_index = (audio_voice_index + 1) % audio_players.size()
	
	var SfxBank = preload("res://audio/sfx_bank.gd")
	if dist <= 350.0:
		asp.stream = SfxBank.random_variant("flak_near", 3)
		asp.volume_db = lerpf(-4.0, -8.0, dist / 350.0)
	else:
		asp.stream = SfxBank.random_variant("flak_far", 2)
		asp.volume_db = lerpf(-8.0, -16.0, (dist - 350.0) / 500.0)
	
	asp.pitch_scale = 1.0
	if asp.is_inside_tree():
		asp.play()
	audio_play_count += 1
	audio_cooldown = rng.randf_range(AUDIO_COOLDOWN_MIN, AUDIO_COOLDOWN_MAX)

func _exit_tree() -> void:
	for player in audio_players:
		if is_instance_valid(player):
			player.stop()
			player.stream = null
