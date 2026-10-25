extends RefCounted

var offsets: Array[Vector3] = []

func _init() -> void:
	_generate_300_slots()

func _generate_300_slots() -> void:
	offsets.clear()
	# 1. Escuadrilla líder inmediata (Aurora Uno + 5 compañeros en Combat Box cerrada)
	# Se preservan exactamente las coordenadas relativas históricas para estabilidad visual y de cámara
	offsets.append(Vector3(0, 0, 0))          # 0: Líder de la formación
	offsets.append(Vector3(-38, -10, 32))      # 1: Elemento 2 (Babor bajo)
	offsets.append(Vector3(38, -10, 32))       # 2: Elemento 3 (Estribor bajo)
	offsets.append(Vector3(-70, -18, 64))      # 3: Elemento 4 (Babor exterior)
	offsets.append(Vector3(70, -18, 64))       # 4: Elemento 5 (Estribor exterior)
	offsets.append(Vector3(0, 14, 64))         # 5: Elemento 6 (Líder alto)

	# 2. Doctrina histórica de Combat Wings de la 8ª Fuerza Aérea (300 aeronaves en total):
	# Dividida en 3 grandes escalones:
	# - Lead Wing (Centro): slots 6 a 99 (94 bombarderos adicionales en cajas escalonadas)
	# - High Wing (Estribor, +X, cota alta +Y): slots 100 a 199 (100 bombarderos)
	# - Low Wing (Babor, -X, cota baja -Y): slots 200 a 299 (100 bombarderos)
	# Separación lateral: 35 a 60 m. Escalonamiento vertical: 15 a 30 m.

	# Lead Wing: escalones de combate trailing (índices 6 a 99)
	for i in range(6, 100):
		var local_idx := i - 6
		var group_idx := int(local_idx / 18)
		var box_idx := int((local_idx % 18) / 6)
		var sub_idx := local_idx % 6
		
		var box_center_x := 0.0
		var box_center_y := 0.0
		var box_center_z := 110.0 + float(group_idx) * 260.0
		
		if box_idx == 1:
			box_center_x = 180.0
			box_center_y = 25.0
			box_center_z += 60.0
		elif box_idx == 2:
			box_center_x = -180.0
			box_center_y = -25.0
			box_center_z += 120.0
			
		var side_sign := -1.0 if (sub_idx % 2 == 0) else 1.0
		var echelon_layer := int(sub_idx / 2) + 1
		var slot_x := box_center_x + side_sign * (38.0 + float(echelon_layer) * 10.0)
		var slot_y := box_center_y - float(echelon_layer) * 18.0
		var slot_z := box_center_z + float(echelon_layer) * 42.0
		offsets.append(Vector3(slot_x, slot_y, slot_z))

	# High Wing: Estribor (+X), escalonamiento hacia arriba (+Y, +15 a +30 m entre capas)
	for i in range(100, 200):
		var local_idx := i - 100
		var group_idx := int(local_idx / 20)
		var sub_idx := local_idx % 20
		var row := int(sub_idx / 4)
		var col := sub_idx % 4
		
		var wing_base_x := 680.0 + float(group_idx) * 70.0
		var wing_base_y := 160.0 + float(group_idx) * 20.0
		var wing_base_z := 150.0 + float(group_idx) * 280.0
		
		var slot_x := wing_base_x + (float(col) - 1.5) * 48.0   # Separación lateral 48 m (35-60 m)
		var slot_y := wing_base_y + float(row) * 20.0           # Escalonamiento vertical 20 m (15-30 m)
		var slot_z := wing_base_z + float(row) * 55.0
		offsets.append(Vector3(slot_x, slot_y, slot_z))

	# Low Wing: Babor (-X), escalonamiento hacia abajo (-Y, -15 a -30 m entre capas)
	for i in range(200, 300):
		var local_idx := i - 200
		var group_idx := int(local_idx / 20)
		var sub_idx := local_idx % 20
		var row := int(sub_idx / 4)
		var col := sub_idx % 4
		
		var wing_base_x := -680.0 - float(group_idx) * 70.0
		var wing_base_y := -160.0 - float(group_idx) * 20.0
		var wing_base_z := 180.0 + float(group_idx) * 280.0
		
		var slot_x := wing_base_x + (float(col) - 1.5) * 48.0   # Separación lateral 48 m (35-60 m)
		var slot_y := wing_base_y - float(row) * 20.0           # Escalonamiento vertical 20 m (15-30 m)
		var slot_z := wing_base_z + float(row) * 55.0
		offsets.append(Vector3(slot_x, slot_y, slot_z))

func slot_count() -> int:
	return offsets.size()

func local_offset(index: int) -> Vector3:
	return offsets[clampi(index, 0, offsets.size() - 1)]

func world_position(leader_pos: Vector3, leader_yaw: float, index: int) -> Vector3:
	return leader_pos + local_offset(index).rotated(Vector3.UP, leader_yaw)
