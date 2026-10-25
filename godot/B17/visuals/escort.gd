extends Node3D
# Caza de escolta aliado P-51D Mustang («Little Friends») para cobertura alta de la escuadrilla B-17.

var previous_position := Vector3.ZERO
var has_position := false
var slot := 0
var combat_clock := 0.0
var combat_offset := Vector3.ZERO
var fire_cooldown := 0.0
var engaging := false
var rotor: Node3D
var model: Node3D
var base_offset: Vector3 = Vector3.ZERO
var patrol_phase: float = 0.0

func _ready() -> void:
	var path := "res://assets/aircraft/models/p51d.glb"
	var scene: PackedScene = load(path) as PackedScene
	if scene != null:
		model = scene.instantiate() as Node3D
		add_child(model)
		
		var rotors: Array = model.find_children("Rotor_*", "Node3D", true, false)
		if not rotors.is_empty():
			rotor = rotors[0] as Node3D

func setup_slot(slot_idx: int) -> void:
	slot = slot_idx
	# Cazas P-51D en formación de escolta táctica y patrulla de cobertura alta (+150m Y a +220m Y)
	# Distribuida en flanco babor (-X), flanco estribor (+X) y caja central de bombardeo
	match slot_idx:
		0:
			base_offset = Vector3(-140.0, 150.0, -80.0)
			patrol_phase = 0.0
		1:
			base_offset = Vector3(-220.0, 165.0, -20.0)
			patrol_phase = 0.4
		2:
			base_offset = Vector3(140.0, 150.0, -80.0)
			patrol_phase = 1.6
		3:
			base_offset = Vector3(220.0, 165.0, -20.0)
			patrol_phase = 2.0
		4:
			base_offset = Vector3(-350.0, 180.0, 40.0)
			patrol_phase = 0.8
		5:
			base_offset = Vector3(350.0, 180.0, 40.0)
			patrol_phase = 2.4
		6:
			base_offset = Vector3(-450.0, 195.0, 120.0)
			patrol_phase = 1.2
		7:
			base_offset = Vector3(450.0, 195.0, 120.0)
			patrol_phase = 2.8
		8:
			base_offset = Vector3(0.0, 210.0, -140.0)
			patrol_phase = 0.2
		9:
			base_offset = Vector3(0.0, 220.0, 60.0)
			patrol_phase = 1.8
		10:
			base_offset = Vector3(-580.0, 175.0, -50.0)
			patrol_phase = 0.6
		11:
			base_offset = Vector3(580.0, 175.0, -50.0)
			patrol_phase = 2.2
		12:
			base_offset = Vector3(-280.0, 160.0, -180.0)
			patrol_phase = 1.0
		13:
			base_offset = Vector3(280.0, 160.0, -180.0)
			patrol_phase = 2.6
		14:
			base_offset = Vector3(-180.0, 190.0, 200.0)
			patrol_phase = 1.4
		15:
			base_offset = Vector3(180.0, 190.0, 200.0)
			patrol_phase = 3.0
		_:
			var sign_x := -1.0 if (slot_idx % 2 == 0) else 1.0
			base_offset = Vector3(sign_x * (150.0 + float(slot_idx) * 35.0), 150.0 + float(slot_idx % 4) * 20.0, -100.0 + float(slot_idx) * 25.0)
			patrol_phase = float(slot_idx) * 0.5

func _process(delta: float) -> void:
	if rotor != null:
		rotor.rotate_z(delta * 40.0)

func reset() -> void:
	patrol_phase = float(slot) * 0.2
	combat_clock = 0.0
	has_position = false
	combat_offset = Vector3.ZERO
	fire_cooldown = 0.0
	engaging = false

func update_patrol(delta: float, bomber_pos: Vector3, bomber_yaw: float, bomber_pitch: float, frozen: bool) -> void:
	set_process(not frozen)
	if not frozen:
		patrol_phase += delta * 0.35
	
	# Movimiento sutil de barrido / patrulla táctica de cobertura alta
	var weave_x := sin(patrol_phase * 1.4) * 14.0
	var weave_y := cos(patrol_phase * 1.1) * 6.0
	var weave_z := sin(patrol_phase * 0.7) * 18.0
	var current_offset := base_offset + Vector3(weave_x, weave_y, weave_z)
	
	var rotated_offset := current_offset.rotated(Vector3.UP, bomber_yaw)
	if is_inside_tree():
		global_position = bomber_pos + rotated_offset
	else:
		position = bomber_pos + rotated_offset
	
	var roll_angle := -cos(patrol_phase * 1.4) * 0.10
	rotation = Vector3(bomber_pitch, bomber_yaw, roll_angle)

func update_combat(delta: float, bomber_pos: Vector3, yaw: float, pitch: float, frozen: bool, combat, tracers, controls = null) -> void:
	var previous_basis := basis.orthonormalized()
	update_patrol(delta, bomber_pos, yaw, pitch, frozen)
	if not frozen:
		combat_clock += delta
		fire_cooldown -= delta
	
	var cur_pos: Vector3 = global_position if is_inside_tree() else position
	var cover_boost: bool = controls != null and bool(controls.get("escort_cover_requested"))
	# Si se solicitó cobertura cercana, los primeros 8 escoltas entran de inmediato
	if cover_boost and slot < 8:
		engaging = not combat.wave_complete
	else:
		engaging = not combat.wave_complete and int(combat_clock / 8.0) % 4 == int(slot / 4)
		
	var desired := Vector3.ZERO
	var target = null
	var nearest := 850.0
	if engaging:
		for fighter in combat.fighters:
			var local: Vector3 = (fighter["ai"].position - bomber_pos).rotated(Vector3.UP, -yaw)
			if not fighter["alive"] or local.x * base_offset.x < 0.0: continue
			var dist: float = cur_pos.distance_to(fighter["ai"].position)
			if dist < nearest:
				nearest = dist
				target = fighter
		if target != null:
			var local: Vector3 = (target["ai"].position - bomber_pos).rotated(Vector3.UP, -yaw)
			var element_lane := float(slot % 4)
			var cover_offset := Vector3((element_lane - 1.5) * 36.0, 55.0 + float(slot % 2) * 24.0, 160.0 + float(int(slot % 4 / 2)) * 54.0)
			desired = (local + cover_offset - base_offset).limit_length(340.0)
	if not frozen:
		combat_offset = combat_offset.move_toward(desired, delta * 65.0)
	cur_pos += combat_offset.rotated(Vector3.UP, yaw)
	if is_inside_tree():
		global_position = cur_pos
	else:
		position = cur_pos
	if has_position and not frozen and delta > 0.0:
		var motion := cur_pos - previous_position
		if motion.length_squared() > 0.001:
			basis = previous_basis.slerp(Basis.looking_at(motion.normalized(), Vector3.UP), minf(delta * 1.5, 1.0))
	if frozen: basis = previous_basis
	previous_position = cur_pos
	has_position = true
	if target != null and not frozen and cover_boost:
		var direction: Vector3 = target["ai"].position - cur_pos
		if nearest < 600.0 and fire_cooldown <= 0.0 and (-basis.z).dot(direction.normalized()) > 0.85:
			fire_cooldown = 0.5
			var origin: Vector3 = cur_pos + basis * Vector3(2.1, 0.1, -2.6)
			if tracers != null:
				tracers.fire(origin, direction.normalized() * 850.0)
				tracers.flash(origin)
			# Daño real de fuego de cobertura P-51D durante la orden de apoyo
			target["health"] = maxf(0.0, float(target["health"]) - 15.0)
			if target["health"] <= 0.0 and target["alive"]:
				target["alive"] = false
				combat.total_kills += 1
				combat.damage_events.append({"fighter": combat.fighters.find(target), "cause": "escort", "effect": "engine_smoke_lift_loss"})
				target["fall_vel"] = target["ai"].velocity
			else:
				combat.damage_events.append({"fighter": combat.fighters.find(target), "cause": "escort", "effect": "suppression"})
	elif target != null and not frozen:
		var direction: Vector3 = target["ai"].position - cur_pos
		if nearest < 600.0 and fire_cooldown <= 0.0 and (-basis.z).dot(direction.normalized()) > 0.85:
			fire_cooldown = 0.5
			var origin: Vector3 = cur_pos + basis * Vector3(2.1, 0.1, -2.6)
			if tracers != null:
				tracers.fire(origin, direction.normalized() * 850.0)
				tracers.flash(origin)
