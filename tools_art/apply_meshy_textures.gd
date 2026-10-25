extends SceneTree
# Aplica las texturas PBR de un Retexture de Meshy a NUESTRO GLB sin tocar geometría, escala, transforms ni nodos Rotor_*.
# Uso (sin tocar el proyecto del juego):
#   tools/godot --headless --path /tmp/meshy_proj --script tools_art/apply_meshy_textures.gd -- \
#       <nuestro.glb> <meshy.glb> <carpeta_mapas> <salida.glb>
# <carpeta_mapas> debe contener base_color.png, normal.png, roughness.png, metallic.png (y ao.png opcional).
#
# Método (Meshy genera UV nuevas, enable_original_uv=false):
#   1. Se juntan todos los triángulos de Meshy en espacio de mundo, con sus UV. Si la caja de Meshy no coincide con la nuestra
#      (Meshy puede recentrar o escalar), se alinea por caja (escala uniforme + traslación).
#   2. Para cada triángulo NUESTRO se busca el triángulo de Meshy más cercano a su centroide con normal compatible
#      (|cos| > 0,5, para no confundir el extradós con el intradós en los bordes finos).
#   3. Las UV de nuestros 3 vértices se calculan con las baricéntricas respecto a ESE triángulo de Meshy (las tres de la misma
#      isla de UV: ningún triángulo nuestro cruza una costura). Si Meshy conservó los vértices, la coincidencia es exacta.
#   4. Se regeneran tangentes (mapa normal) y se pone un StandardMaterial3D PBR único. Se exporta con GLTFDocument.
# Autor: Claude (herramienta de arte; no es código del juego).

const CELL := 0.35

var m_pos := PackedVector3Array()   # 3 por triángulo de Meshy (mundo, ya alineado)
var m_uv := PackedVector2Array()
var m_nrm := PackedVector3Array()   # 1 por triángulo
var grid := {}                      # Vector3i -> PackedInt32Array de triángulos

func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() < 4:
		printerr("uso: <nuestro.glb> <meshy.glb> <carpeta_mapas> <salida.glb>")
		quit(2)
		return
	quit(run(a[0], a[1], a[2], a[3]))

func _load_scene(path: String) -> Node3D:
	var doc := GLTFDocument.new()
	var st := GLTFState.new()
	if doc.append_from_file(path, st) != OK:
		return null
	return doc.generate_scene(st) as Node3D

func _world_aabb(scene: Node3D) -> AABB:
	var box := AABB()
	var first := true
	for n in scene.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		var b: AABB = _global_xf(mi) * mi.get_aabb()
		box = b if first else box.merge(b)
		first = false
	return box

# Transform de mundo sin estar en el árbol.
func _global_xf(n: Node) -> Transform3D:
	var xf := Transform3D.IDENTITY
	var cur := n
	while cur != null:
		if cur is Node3D:
			xf = (cur as Node3D).transform * xf
		cur = cur.get_parent()
	return xf

func _tris(mesh: Mesh, s: int) -> Dictionary:
	var arr := mesh.surface_get_arrays(s)
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var nrm = arr[Mesh.ARRAY_NORMAL]
	var uv = arr[Mesh.ARRAY_TEX_UV]
	var idx = arr[Mesh.ARRAY_INDEX]
	if idx == null:
		idx = PackedInt32Array(range(v.size()))
	return {"v": v, "n": nrm, "uv": uv, "i": idx}

func _key(p: Vector3) -> Vector3i:
	return Vector3i(floori(p.x / CELL), floori(p.y / CELL), floori(p.z / CELL))

func _collect_meshy(meshy: Node3D, ours_box: AABB) -> void:
	var raw_box := _world_aabb(meshy)
	# Alineación por caja: escala uniforme (media de los 3 ejes) + traslación de centros.
	var sc := (ours_box.size.x / raw_box.size.x + ours_box.size.y / raw_box.size.y + ours_box.size.z / raw_box.size.z) / 3.0
	var per_axis := Vector3(ours_box.size.x / raw_box.size.x, ours_box.size.y / raw_box.size.y, ours_box.size.z / raw_box.size.z)
	print("  caja Meshy=%s  nuestra=%s  escala por eje=%s" % [raw_box.size, ours_box.size, per_axis])
	var align := Transform3D.IDENTITY
	if absf(sc - 1.0) > 0.002 or raw_box.get_center().distance_to(ours_box.get_center()) > 0.01:
		align = Transform3D(Basis.from_scale(Vector3.ONE * sc), ours_box.get_center() - raw_box.get_center() * sc)
		print("  AVISO: Meshy movió/escaló el modelo; se alinea con escala %.5f" % sc)
	for n in meshy.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		var xf := align * _global_xf(mi)
		for s in mi.mesh.get_surface_count():
			var t := _tris(mi.mesh, s)
			if t["uv"] == null:
				continue
			var v: PackedVector3Array = t["v"]
			var uv: PackedVector2Array = t["uv"]
			var idx: PackedInt32Array = t["i"]
			for k in range(0, idx.size(), 3):
				var p0 := xf * v[idx[k]]; var p1 := xf * v[idx[k + 1]]; var p2 := xf * v[idx[k + 2]]
				var fn := (p1 - p0).cross(p2 - p0)
				if fn.length_squared() < 1e-14:
					continue
				var ti := m_nrm.size()
				m_pos.append(p0); m_pos.append(p1); m_pos.append(p2)
				m_uv.append(uv[idx[k]]); m_uv.append(uv[idx[k + 1]]); m_uv.append(uv[idx[k + 2]])
				m_nrm.append(fn.normalized())
				# El triángulo se registra en todas las celdas que toca su caja (así la búsqueda local no lo pierde).
				var lo := _key(Vector3(minf(p0.x, minf(p1.x, p2.x)), minf(p0.y, minf(p1.y, p2.y)), minf(p0.z, minf(p1.z, p2.z))))
				var hi := _key(Vector3(maxf(p0.x, maxf(p1.x, p2.x)), maxf(p0.y, maxf(p1.y, p2.y)), maxf(p0.z, maxf(p1.z, p2.z))))
				for x in range(lo.x, hi.x + 1):
					for y in range(lo.y, hi.y + 1):
						for z in range(lo.z, hi.z + 1):
							var kk := Vector3i(x, y, z)
							if not grid.has(kk):
								grid[kk] = PackedInt32Array()
							grid[kk].append(ti)

func _closest_on_tri(p: Vector3, a: Vector3, b: Vector3, c: Vector3) -> Vector3:
	var bc := Geometry3D.get_triangle_barycentric_coords(p, a, b, c)
	if bc.x >= 0.0 and bc.y >= 0.0 and bc.z >= 0.0:
		return a * bc.x + b * bc.y + c * bc.z
	var q1 := Geometry3D.get_closest_point_to_segment(p, a, b)
	var q2 := Geometry3D.get_closest_point_to_segment(p, b, c)
	var q3 := Geometry3D.get_closest_point_to_segment(p, c, a)
	var best := q1
	if p.distance_squared_to(q2) < p.distance_squared_to(best): best = q2
	if p.distance_squared_to(q3) < p.distance_squared_to(best): best = q3
	return best

# Devuelve [índice_triángulo, distancia] del triángulo de Meshy más cercano con normal compatible.
func _find(p: Vector3, n: Vector3) -> Array:
	var k := _key(p)
	var best := -1
	var best_d := INF
	var best_any := -1
	var best_any_d := INF
	for r in [1, 2, 4]:
		var seen := {}
		for x in range(k.x - r, k.x + r + 1):
			for y in range(k.y - r, k.y + r + 1):
				for z in range(k.z - r, k.z + r + 1):
					var kk := Vector3i(x, y, z)
					if not grid.has(kk):
						continue
					for ti in grid[kk]:
						if seen.has(ti):
							continue
						seen[ti] = true
						var q := _closest_on_tri(p, m_pos[ti * 3], m_pos[ti * 3 + 1], m_pos[ti * 3 + 2])
						var d := p.distance_to(q)
						if d < best_any_d:
							best_any_d = d; best_any = ti
						if absf(n.dot(m_nrm[ti])) > 0.5 and d < best_d:
							best_d = d; best = ti
		if best >= 0:
			return [best, best_d]
	return [best_any, best_any_d]

func _uv_from(ti: int, p: Vector3) -> Vector2:
	var a := m_pos[ti * 3]; var b := m_pos[ti * 3 + 1]; var c := m_pos[ti * 3 + 2]
	var bc := Geometry3D.get_triangle_barycentric_coords(p, a, b, c)
	return m_uv[ti * 3] * bc.x + m_uv[ti * 3 + 1] * bc.y + m_uv[ti * 3 + 2] * bc.z

func _tex(dir: String, name: String) -> ImageTexture:
	var path := dir.path_join(name)
	if not FileAccess.file_exists(path):
		return null
	var img := Image.load_from_file(path)
	if img == null:
		return null
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)

func _material(dir: String) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.resource_name = "meshy_pbr"
	m.albedo_texture = _tex(dir, "base_color.png")
	var nt := _tex(dir, "normal.png")
	if nt:
		m.normal_enabled = true
		m.normal_texture = nt
	var rt := _tex(dir, "roughness.png")
	if rt:
		m.roughness = 1.0
		m.roughness_texture = rt
		m.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
	var mt := _tex(dir, "metallic.png")
	if mt:
		m.metallic = 1.0
		m.metallic_texture = mt
		m.metallic_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
	var at := _tex(dir, "ao.png")
	if at:
		m.ao_enabled = true
		m.ao_texture = at
		m.ao_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
	# Igual que el material original: algunas superficies (alas, deriva) se ven por ambas caras.
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	print("  material: albedo=%s normal=%s rough=%s metal=%s ao=%s" % [m.albedo_texture != null, nt != null, rt != null, mt != null, at != null])
	return m

func run(ours_path: String, meshy_path: String, maps_dir: String, out_path: String) -> int:
	var ours := _load_scene(ours_path)
	var meshy := _load_scene(meshy_path)
	if ours == null or meshy == null:
		printerr("no se pudo cargar ", ours_path if ours == null else meshy_path)
		return 1
	var box_before := _world_aabb(ours)
	var rotors_before := _rotor_names(ours)
	_collect_meshy(meshy, box_before)
	print("  triángulos Meshy=%d celdas=%d" % [m_nrm.size(), grid.size()])
	var mat := _material(maps_dir)
	var total := 0
	var exact := 0
	var far := 0
	var max_d := 0.0
	for n in ours.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		var xf := _global_xf(mi)
		var new_mesh := ArrayMesh.new()
		for s in mi.mesh.get_surface_count():
			var t := _tris(mi.mesh, s)
			var v: PackedVector3Array = t["v"]
			var nrm = t["n"]
			var idx: PackedInt32Array = t["i"]
			var st := SurfaceTool.new()
			st.begin(Mesh.PRIMITIVE_TRIANGLES)
			for k in range(0, idx.size(), 3):
				var w := [xf * v[idx[k]], xf * v[idx[k + 1]], xf * v[idx[k + 2]]]
				var fn: Vector3 = (w[1] - w[0]).cross(w[2] - w[0])
				fn = fn.normalized() if fn.length_squared() > 1e-14 else Vector3.UP
				var cen: Vector3 = (w[0] + w[1] + w[2]) / 3.0
				var hit := _find(cen, fn)
				var ti: int = hit[0]
				total += 1
				# Coincidencia exacta: los 3 vértices están en el triángulo de Meshy (< 1 mm).
				var dv := 0.0
				for j in 3:
					dv = maxf(dv, (w[j] as Vector3).distance_to(_closest_on_tri(w[j], m_pos[ti * 3], m_pos[ti * 3 + 1], m_pos[ti * 3 + 2])))
				if dv < 0.001: exact += 1
				if hit[1] > 0.05: far += 1
				max_d = maxf(max_d, hit[1])
				for j in 3:
					if nrm != null:
						st.set_normal(nrm[idx[k + j]])
					st.set_uv(_uv_from(ti, w[j]))
					st.add_vertex(v[idx[k + j]])
			if nrm == null:
				st.generate_normals()
			st.generate_tangents()
			st.set_material(mat)
			st.commit(new_mesh)
			new_mesh.surface_set_name(new_mesh.get_surface_count() - 1, mi.mesh.surface_get_name(s))
		new_mesh.resource_name = mi.mesh.resource_name
		mi.mesh = new_mesh
		mi.material_override = null
	print("  transferencia: %d triángulos, exactos=%d (%.1f%%), a >5 cm=%d, distancia máx=%.4f m" % [total, exact, 100.0 * exact / maxf(total, 1), far, max_d])
	_own(ours, ours)
	var doc := GLTFDocument.new()
	var st2 := GLTFState.new()
	var err := doc.append_from_scene(ours, st2)
	if err == OK:
		DirAccess.make_dir_recursive_absolute(out_path.get_base_dir())
		err = doc.write_to_filesystem(st2, out_path)
	if err != OK:
		printerr("fallo al exportar: ", err)
		return 1
	# Comprobación inmediata releyendo el archivo escrito.
	var back := _load_scene(out_path)
	var box_after := _world_aabb(back)
	var rotors_after := _rotor_names(back)
	var diff := (box_after.size - box_before.size).abs()
	var rel := maxf(diff.x / box_before.size.x, maxf(diff.y / box_before.size.y, diff.z / box_before.size.z))
	print("  AABB antes=%s después=%s dif.rel.máx=%.5f%%" % [box_before, box_after, rel * 100.0])
	print("  Rotor antes=%s después=%s" % [rotors_before, rotors_after])
	var ok := rel < 0.01 and rotors_before == rotors_after
	print("APPLY %s %s" % ["OK" if ok else "FALLO", out_path])
	return 0 if ok else 1

func _rotor_names(scene: Node) -> Array:
	var names := []
	for n in scene.find_children("Rotor_*", "", true, false):
		names.append("%s@%s" % [n.name, (n as Node3D).position.snapped(Vector3.ONE * 0.001)])
	names.sort()
	return names

func _own(node: Node, owner_node: Node) -> void:
	for c in node.get_children():
		c.owner = owner_node
		_own(c, owner_node)
