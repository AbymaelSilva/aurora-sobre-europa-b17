extends Node

const VOICE_DIR := "res://assets/audio/voice/"
const MUSIC_DIR := "res://assets/audio/music/"
const VOICE_BUS := "B17Dialogue"
const MUSIC_BUS := "B17Music"
const EFFECTS_BUS := "B17Effects"

var voice_player: AudioStreamPlayer
var music_players: Array[AudioStreamPlayer] = []
var catalog: Dictionary = {}
var music_catalog: Dictionary = {}
var pending: Array[Dictionary] = []
var used: Dictionary = {}
var subtitle: String = ""
var current_id: String = ""
var current_music: String = ""
var last_phase: String = ""
var music_enabled: bool = true
var voice_enabled: bool = true
var active_music: int = 0
var gap: float = 0.0
var sequence: int = 0
var duck: float = 0.0
var mix: float = 1.0
var fallback_remaining: float = 0.0
var phase_clock: float = 0.0
var voice_start_count: int = 0

func _ready() -> void:
	for name in [VOICE_BUS, MUSIC_BUS, EFFECTS_BUS]:
		if AudioServer.get_bus_index(name) < 0:
			AudioServer.add_bus()
			var idx: int = AudioServer.bus_count - 1
			AudioServer.set_bus_name(idx, name)
			AudioServer.set_bus_send(idx, "Master")
	catalog = JSON.parse_string(FileAccess.get_file_as_string(VOICE_DIR + "dialogue_catalog.json"))
	music_catalog = JSON.parse_string(FileAccess.get_file_as_string(MUSIC_DIR + "music_catalog.json"))
	voice_player = AudioStreamPlayer.new()
	voice_player.bus = VOICE_BUS
	add_child(voice_player)
	voice_player.finished.connect(_voice_finished)
	for i in range(2):
		var player := AudioStreamPlayer.new()
		player.bus = MUSIC_BUS
		player.volume_db = -80.0
		add_child(player)
		music_players.append(player)
	reset()

func reset() -> void:
	if is_instance_valid(voice_player): voice_player.stop()
	for player in music_players: player.stop()
	pending.clear()
	used.clear()
	subtitle = ""
	current_id = ""
	current_music = ""
	last_phase = ""
	gap = 0.0
	sequence = 0
	duck = 0.0
	mix = 1.0
	phase_clock = 0.0
	fallback_remaining = 0.0
	voice_start_count = 0
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(EFFECTS_BUS), 0.0)

func enqueue(ids: Array) -> void:
	for value in ids:
		var id: String = str(value)
		if used.has(id) or not catalog.has(id): continue
		used[id] = true
		sequence += 1
		pending.append({"id": id, "priority": int(catalog[id].get("priority", 1)), "order": sequence})
	pending.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if a.priority == b.priority: return a.order < b.order
		return a.priority > b.priority)
	if pending.size() > 8: pending.resize(8)

func _phase_changed(phase: String, sim) -> void:
	pending.clear()
	phase_clock = 0.0
	if phase in ["FALLIDA", "COMPLETADA"]:
		voice_player.stop()
		_voice_finished()
		gap = 0.12
	match phase:
		"FORMACION": enqueue(["formation_lead", "formation_reply", "formation_gunner"])
		"APROXIMACION": enqueue(["approach_nav", "approach_pilot"])
		"BOMBARDEO": enqueue(["bombing_nav", "bombing_pilot", "bombing_ready"])
		"REGRESO": enqueue(["impact_bombardier", "return_pilot", "return_nav", "return_gunner"])
		"COMPLETADA": enqueue(["complete_control", "complete_pilot"])
		"FALLIDA":
			if sim.damage.destroyed(): enqueue(["failed_pilot", "failed_reply"])
			else: enqueue(["miss_bombardier", "failed_objective"])

func _voice_finished() -> void:
	subtitle = ""
	current_id = ""
	fallback_remaining = 0.0
	gap = 0.55

func _start_voice() -> void:
	if pending.is_empty(): return
	var entry: Dictionary = pending.pop_front()
	current_id = entry.id
	var line: Dictionary = catalog[current_id]
	subtitle = "%s: %s" % [line.speaker, line.text]
	var path: String = VOICE_DIR + str(line.file)
	if ResourceLoader.exists(path):
		voice_player.stream = load(path) as AudioStream
		voice_player.play()
		voice_start_count += 1
	else:
		push_warning("Falta voz: " + path)
		fallback_remaining = maxf(float(line.get("duration", 4.0)), 2.0)

func _music_for(sim, threat: bool) -> String:
	match sim.mission.phase:
		"FALLIDA": return "failed"
		"COMPLETADA": return "complete"
	if threat: return "combat"
	match sim.mission.phase:
		"APROXIMACION": return "approach"
		"BOMBARDEO": return "bombing"
		"REGRESO": return "return"
	return "formation"

func _set_music(key: String) -> void:
	if key == current_music or not music_catalog.has(key): return
	current_music = key
	active_music = 1 - active_music
	var player: AudioStreamPlayer = music_players[active_music]
	var entry: Dictionary = music_catalog[key]
	var stream := load(MUSIC_DIR + str(entry.file)) as AudioStreamWAV
	if stream == null: return
	stream = stream.duplicate() as AudioStreamWAV
	if bool(entry.loop):
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = int(round(stream.get_length() * stream.mix_rate))
	player.stream = stream
	player.volume_db = -80.0
	player.play()
	mix = 0.0

func update_scene(delta: float, sim) -> void:
	var paused: bool = sim.paused
	voice_player.stream_paused = paused
	for player in music_players: player.stream_paused = paused
	if paused: return
	var dt: float = maxf(delta, 0.0)
	phase_clock += dt
	var phase: String = sim.mission.phase
	if phase != last_phase:
		last_phase = phase
		_phase_changed(phase, sim)
	var threat: bool = false
	for fighter in sim.combat.fighters:
		if fighter.get("alive", false) and fighter.ai.position.distance_to(sim.flight.position) < 1500.0:
			threat = true
			break
	if phase not in ["COMPLETADA", "FALLIDA"]:
		if threat: enqueue(["contact_gunner", "contact_pilot"])
		if sim.flak.bursts > 0 and phase in ["APROXIMACION", "BOMBARDEO"]:
			enqueue(["flak_gunner", "flak_pilot"])
		for health in sim.damage.engines:
			if health < 50.0: enqueue(["damage_engine", "damage_engine_ack"])
		if sim.damage.hull < 65.0: enqueue(["damage_hull", "damage_hull_ack"])
		if sim.bomb.spent and phase == "BOMBARDEO": enqueue(["release_bombardier", "release_pilot"])
	# Una urgencia interrumpe una frase rutinaria; ninguna voz se solapa.
	if not pending.is_empty() and not current_id.is_empty():
		if int(pending[0].priority) >= 3 and int(catalog[current_id].priority) < 3:
			voice_player.stop()
			_voice_finished()
			gap = 0.12
	if fallback_remaining > 0.0:
		fallback_remaining = maxf(0.0, fallback_remaining - dt)
		if fallback_remaining == 0.0: _voice_finished()
	gap = maxf(0.0, gap - dt)
	if current_id.is_empty() and not voice_player.playing and gap <= 0.0: _start_voice()
	_set_music(_music_for(sim, threat))
	var speaking: bool = voice_player.playing and voice_enabled
	duck = move_toward(duck, 1.0 if speaking else 0.0, dt * (6.0 if speaking else 1.5))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(EFFECTS_BUS), -5.0 * duck)
	voice_player.volume_db = 0.0 if voice_enabled else -80.0
	mix = minf(1.0, mix + dt / 2.0)
	for i in range(2):
		var gain: float = mix if i == active_music else 1.0 - mix
		music_players[i].volume_db = (-7.0 - 8.0 * duck + linear_to_db(maxf(gain, 0.0001))) if music_enabled else -80.0
		if i != active_music and mix >= 1.0: music_players[i].stop()

func _exit_tree() -> void:
	if is_instance_valid(voice_player): voice_player.stop()
	for player in music_players:
		if is_instance_valid(player): player.stop()
	var index: int = AudioServer.get_bus_index(EFFECTS_BUS)
	if index >= 0: AudioServer.set_bus_volume_db(index, 0.0)
