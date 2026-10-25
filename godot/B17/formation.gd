extends Node3D

var wingmen: Array[Node3D] = []
var left: Node3D
var right: Node3D
var slots = preload("res://core/formation_slots.gd").new()

# Flota de fondo optimizada mediante MultiMeshInstance3D
var fleet_multimesh: MultiMeshInstance3D
var fleet_count: int = 294

func _ready() -> void:
	# 1. Escuadrilla líder inmediata (5 bombarderos completos con detalles, marcas y hélices animadas)
	for i in range(5):
		var aircraft = preload("res://aircraft.gd").new()
		aircraft.name = "Wingman_%d" % (i + 1)
		aircraft.add_child(preload("res://visuals/bomber_details.gd").new())
		aircraft.add_child(preload("res://visuals/markings.gd").new())
		add_child(aircraft)
		wingmen.append(aircraft)
	left = wingmen[0]
	right = wingmen[1]

	# 2. Gran armada aliada (294 bombarderos de fondo en MultiMeshInstance3D para 60 FPS sostenidos)
	_setup_background_fleet()

func _setup_background_fleet() -> void:
	var b17_scene = load("res://assets/aircraft/models/b17g.glb") as PackedScene
	if b17_scene == null:
		return
	var inst: Node3D = b17_scene.instantiate()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var mat: Material = null
	for child in inst.find_children("*", "MeshInstance3D", true, false):
		var mi := child as MeshInstance3D
		if mi.mesh != null and not mi.name.begins_with("Blade") and not mi.name.begins_with("Spinner") and not mi.name.begins_with("Rotor"):
			var cur_mat: Material = mi.get_active_material(0)
			if cur_mat != null and mat == null:
				mat = cur_mat
			st.append_from(mi.mesh, 0, mi.transform)
	inst.free()

	var combined_mesh: ArrayMesh = st.commit()
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.instance_count = fleet_count
	mm.mesh = combined_mesh

	# Pre-configurar las posiciones relativas locales de los 294 bombarderos
	for i in range(fleet_count):
		var local_pos: Vector3 = slots.local_offset(i + 6)
		mm.set_instance_transform(i, Transform3D(Basis.IDENTITY, local_pos))

	fleet_multimesh = MultiMeshInstance3D.new()
	fleet_multimesh.name = "FleetArmada300"
	fleet_multimesh.multimesh = mm
	if mat != null:
		fleet_multimesh.material_override = mat
	add_child(fleet_multimesh)

func follow(leader_position: Vector3, yaw: float, pitch: float) -> void:
	# 1. Posicionar los 5 compañeros cercanos de Aurora Uno
	for i in range(wingmen.size()):
		wingmen[i].position = slots.world_position(leader_position, yaw, i + 1)
		wingmen[i].rotation = Vector3(pitch, yaw, 0.0)

	# 2. Posicionar la gran armada en bloque con transformación jerárquica a coste CPU cero
	if fleet_multimesh != null:
		fleet_multimesh.global_position = leader_position
		fleet_multimesh.rotation = Vector3(pitch, yaw, 0.0)

func get_total_aircraft() -> int:
	return 1 + wingmen.size() + fleet_count
