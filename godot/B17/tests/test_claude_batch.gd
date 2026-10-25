extends SceneTree
# Pruebas de comportamiento del lote Claude→Qwen (autor de las pruebas: Claude). Cada bloque es independiente.

var failures: PackedStringArray = []

func check(cond: bool, label: String) -> void:
	if not cond:
		failures.append(label)
		print("FAIL ", label)

func finite(v: Vector3) -> bool:
	return is_finite(v.x) and is_finite(v.y) and is_finite(v.z)

func load_ok(path: String) -> Script:
	var script := load(path) as Script
	if script == null or not script.can_instantiate():
		check(false, path + " no carga o no compila")
		return null
	return script

func needs(obj: Object, names: Array, label: String) -> bool:
	for n in names:
		if not (n in obj):
			check(false, label + ": falta el miembro '" + n + "' del contrato")
			return false
	return true

func spawn(path: String) -> Node:
	var script := load_ok(path)
	if script == null:
		return null
	var node: Node = script.new()
	root.add_child(node)
	if not node.is_node_ready():
		check(false, path + " no ejecutó _ready()")
	return node

func _initialize() -> void:
	run()

func run() -> void:
	# En _initialize la raíz aún no está en el árbol: _ready() de los nodos añadidos se aplaza.
	await process_frame
	test_formation()
	test_fighter_ai()
	test_tracers()
	test_ground_material()
	test_scene_nodes()
	print("TEST FAIL: %d" % failures.size() if failures.size() else "TEST PASS: lote Claude→Qwen")
	quit(1 if failures.size() else 0)

func test_formation() -> void:
	var sc := load_ok("res://core/formation_slots.gd")
	if sc == null: return
	var s = sc.new()
	check(s.slot_count() == 300, "formación: 300 puestos")
	check(s.world_position(Vector3(10, 1200, 5), 0.0, 0) == Vector3(10, 1200, 5), "formación: líder en su posición")
	check(s.local_offset(1).z > 0.0, "formación: puesto 1 detrás (+Z)")
	check(s.local_offset(999) == s.local_offset(299) and s.local_offset(-3) == s.local_offset(0), "formación: índice recortado")
	var rotated: Vector3 = s.world_position(Vector3.ZERO, PI / 2.0, 1)
	check(absf(rotated.length() - s.local_offset(1).length()) < 0.001, "formación: la rotación conserva la distancia")

func test_fighter_ai() -> void:
	var sc := load_ok("res://core/fighter_ai.gd")
	if sc == null: return
	var ai = sc.new()
	if not needs(ai, ["position", "velocity", "state", "side"], "caza IA"): return
	ai.setup(Vector3(3000, 1500, -6000), 0.0)
	check(ai.side == 1.0, "caza: lado 0 → +1")
	var seen := {}
	var bomber := Vector3(0, 1200, 0)
	for i in 20 * 60 * 3:
		bomber += Vector3(0, 0, -85.0 / 60.0)
		ai.step(1.0 / 60.0, bomber)
		seen[ai.state] = true
		if not finite(ai.position) or not finite(ai.velocity):
			check(false, "caza: NaN/Inf en paso %d" % i)
			return
	for s in ["APPROACH", "ATTACK", "BREAK", "REPOSITION"]:
		check(seen.has(s), "caza: alcanza " + s)
	ai.step(10.0, bomber)
	check(finite(ai.position), "caza: delta enorme recortado")

func test_tracers() -> void:
	var pool = spawn("res://visuals/tracer_pool.gd")
	if pool == null or not needs(pool, ["meshes", "capacity"], "trazadoras"): return
	check(pool.active_count() == 0, "trazadoras: empiezan inactivas")
	check(pool.fire(Vector3.ZERO, Vector3(0, 0, -800)), "trazadoras: dispara")
	check(pool.fire(Vector3.ZERO, Vector3(0, 800, 0)), "trazadoras: dispara en vertical sin error de base")
	check(pool.active_count() == 2, "trazadoras: 2 activas")
	pool.advance(0.5)
	check(pool.meshes[0].position.z < -399.0, "trazadoras: avanzan")
	pool.advance(2.0)
	check(pool.active_count() == 0, "trazadoras: caducan")
	for i in pool.capacity + 5:
		pool.fire(Vector3.ZERO, Vector3.FORWARD)
	check(pool.active_count() == pool.capacity, "trazadoras: no excede capacidad")
	pool.reset()
	check(pool.active_count() == 0, "trazadoras: reset")
	pool.queue_free()

func test_ground_material() -> void:
	var g := load_ok("res://world/ground_material.gd")
	if g == null: return
	var farm: StandardMaterial3D = g.farmland(2000.0)
	check(farm.albedo_texture != null, "terreno: textura de campos")
	check(farm.uv1_world_triplanar, "terreno: triplanar mundial")
	check(g.rail_yard().albedo_texture != null, "terreno: textura del objetivo")

func test_scene_nodes() -> void:
	var clouds = spawn("res://world/cloud_sprites.gd")
	if clouds and needs(clouds, ["sprites"], "nubes"):
		check(clouds.cloud_count() == 100, "nubes: 100 sprites en dos capas")
		var inside := true
		for s in clouds.sprites:
			inside = inside and ((s.position.y >= 1800.0 and s.position.y <= 2600.0) or (s.position.y >= 4000.0 and s.position.y <= 4800.0))
		check(inside, "nubes: dentro de las dos franjas de altura")
	var river = spawn("res://world/river.gd")
	if river and needs(river, ["river", "points"], "río"):
		check(river.river != null and river.river.mesh.get_faces().size() == (river.points.size() - 1) * 6, "río: 2 triángulos por tramo")
	var target = spawn("res://world/target_ground.gd")
	if target and needs(target, ["ground"], "objetivo"):
		check(target.ground != null and target.ground.position.y > 0.0, "objetivo: plano elevado sobre el suelo")
	var fighter = spawn("res://visuals/fighter.gd")
	if fighter and needs(fighter, ["rotor"], "caza"):
		# Semántica, no recuento procedural: el rotor del GLB tiene buje + 3 palas + 3 puntas (7 mallas).
		check(fighter.rotor != null and fighter.rotor.find_children("*", "MeshInstance3D", true, false).size() >= 4, "caza: rotor con buje y al menos 3 palas")
		var r0: float = fighter.rotor.rotation.z
		fighter._process(0.1)
		check(fighter.rotor.rotation.z != r0, "caza: la hélice gira")
	var details = spawn("res://visuals/bomber_details.gd")
	if details:
		check(details.get_child_count() == 16, "detalles: 1 torreta + 10 cañones + 1 mástil + 4 escapes")
	var smoke = spawn("res://visuals/engine_smoke_trail.gd")
	if smoke and needs(smoke, ["particles", "intensity"], "humo"):
		smoke.from_engine_health(100.0)
		check(not smoke.particles.emitting, "humo: motor sano no humea")
		smoke.from_engine_health(10.0)
		check(smoke.particles.emitting and smoke.intensity > 0.8, "humo: motor dañado humea")
