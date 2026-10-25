extends SceneTree
# Construye un avión 3D texturizado a partir de dos vistas ortográficas (lateral con morro a la izquierda y planta con morro arriba).
# Uso: godot --headless --script loft_aircraft.gd -- <lateral.png> <planta.png> <largo_m> <envergadura_m> <palas> <salida.glb> [motores_en_ala:0|1]
# Autor: Claude. Plan B sin Meshy: la geometría sale de las siluetas y la textura de las propias vistas.

const WORK := 1024          # resolución de trabajo de las máscaras
const STATIONS := 96        # secciones del fuselaje
const RING := 24            # vértices por sección

var side_img: Image
var top_img: Image
var side_mask: PackedByteArray
var top_mask: PackedByteArray
var sw := 0; var sh := 0; var tw := 0; var th := 0
var length_m := 20.0
var span_m := 30.0
var atlas: Image
var side_rect := Rect2i()   # bbox en la imagen lateral de trabajo
var top_rect := Rect2i()
var side_uv := Rect2()      # posición en el atlas (0..1)
var top_uv := Rect2()

func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	length_m = float(a[2]); span_m = float(a[3])
	var blades := int(a[4])
	var wing_engines := a.size() > 6 and a[6] == "1"
	side_img = _load(a[0]); top_img = _load(a[1])
	sw = side_img.get_width(); sh = side_img.get_height(); tw = top_img.get_width(); th = top_img.get_height()
	side_mask = _mask(side_img); top_mask = _mask(top_img)
	side_rect = _bbox(side_mask, sw, sh); top_rect = _bbox(top_mask, tw, th)
	_build_atlas()
	var model := _build(blades, wing_engines)
	_own(model, model)  # GLTFDocument solo exporta nodos cuyo owner es la raíz
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	var err := doc.append_from_scene(model, state)
	if err == OK:
		err = doc.write_to_filesystem(state, a[5])
	print("LOFT %s → %s (error %d)" % [a[0].get_file(), a[5], err])
	model.free()
	quit(0 if err == OK else 1)

func _own(node: Node, owner_node: Node) -> void:
	for c in node.get_children():
		c.owner = owner_node
		_own(c, owner_node)

# ---------- imagen ----------
func _load(path: String) -> Image:
	var img := Image.load_from_file(path)
	img.convert(Image.FORMAT_RGB8)
	var s := float(WORK) / maxi(img.get_width(), img.get_height())
	img.resize(int(img.get_width() * s), int(img.get_height() * s), Image.INTERPOLATE_LANCZOS)
	return img

func _mask(img: Image) -> PackedByteArray:
	# Fondo = gris conectado al borde, avanzando solo entre vecinos casi iguales y cercanos al color de fondo.
	# Así el aluminio del avión (tono parecido al fondo) no se pierde: queda encerrado por su contorno.
	var w := img.get_width(); var h := img.get_height()
	var bg := (img.get_pixel(2, 2) + img.get_pixel(w - 3, 2) + img.get_pixel(2, h - 3) + img.get_pixel(w - 3, h - 3)) / 4.0
	var is_bg := PackedByteArray(); is_bg.resize(w * h)
	var stack := PackedInt32Array()
	for x in w: stack.append(x); stack.append((h - 1) * w + x)
	for y in h: stack.append(y * w); stack.append(y * w + w - 1)
	while stack.size() > 0:
		var i := stack[stack.size() - 1]
		stack.resize(stack.size() - 1)
		if is_bg[i] == 1: continue
		var x := i % w; var y := i / w
		var c := img.get_pixel(x, y)
		if absf(c.r - bg.r) + absf(c.g - bg.g) + absf(c.b - bg.b) > 0.12: continue
		is_bg[i] = 1
		for nb in [Vector2i(x - 1, y), Vector2i(x + 1, y), Vector2i(x, y - 1), Vector2i(x, y + 1)]:
			if nb.x >= 0 and nb.y >= 0 and nb.x < w and nb.y < h:
				var j: int = nb.y * w + nb.x
				if is_bg[j] == 0:
					var d: Color = img.get_pixel(nb.x, nb.y)
					if absf(d.r - c.r) + absf(d.g - c.g) + absf(d.b - c.b) < 0.05:
						stack.append(j)
	var m := PackedByteArray(); m.resize(w * h)
	for i in w * h: m[i] = 1 - is_bg[i]
	return m

func _bbox(m: PackedByteArray, w: int, h: int) -> Rect2i:
	var x0 := w; var y0 := h; var x1 := 0; var y1 := 0
	for y in h:
		for x in w:
			if m[y * w + x] == 1:
				x0 = mini(x0, x); x1 = maxi(x1, x); y0 = mini(y0, y); y1 = maxi(y1, y)
	return Rect2i(x0, y0, x1 - x0 + 1, y1 - y0 + 1)

func _run(m: PackedByteArray, w: int, h: int, fixed: int, at: int, vertical: bool) -> Vector2i:
	# Tramo contiguo de máscara que contiene 'at' en la fila/columna 'fixed'. (-1,-1) si no hay.
	var idx := func(i: int) -> int: return (i * w + fixed) if vertical else (fixed * w + i)
	var n := h if vertical else w
	if at < 0 or at >= n or m[idx.call(at)] == 0:
		return Vector2i(-1, -1)
	var lo := at; var hi := at
	while lo > 0 and m[idx.call(lo - 1)] == 1: lo -= 1
	while hi < n - 1 and m[idx.call(hi + 1)] == 1: hi += 1
	return Vector2i(lo, hi)

# ---------- atlas de textura ----------
func _bleed(img: Image, m: PackedByteArray, w: int, rect: Rect2i, passes: int) -> Image:
	# Extiende el color del avión hacia el fondo (dilatación de color) para que el muestreo junto a la silueta no tome gris de fondo.
	var out := img.get_region(rect)
	var rw := rect.size.x; var rh := rect.size.y
	var filled := PackedByteArray(); filled.resize(rw * rh)
	for y in rh:
		for x in rw:
			filled[y * rw + x] = m[(y + rect.position.y) * w + x + rect.position.x]
	for _p in passes:
		var nf := filled.duplicate()
		for y in rh:
			for x in rw:
				if filled[y * rw + x] == 1: continue
				var acc := Color(0, 0, 0); var n := 0
				for d in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]:
					var q: Vector2i = Vector2i(x, y) + d
					if q.x >= 0 and q.y >= 0 and q.x < rw and q.y < rh and filled[q.y * rw + q.x] == 1:
						acc += out.get_pixel(q.x, q.y); n += 1
				if n > 0:
					out.set_pixel(x, y, acc / n); nf[y * rw + x] = 1
		filled = nf
	return out

func _build_atlas() -> void:
	var s := _bleed(side_img, side_mask, sw, side_rect, 10)
	var t := _bleed(top_img, top_mask, tw, top_rect, 10)
	var size := 2048
	s.resize(size, maxi(8, int(size * float(s.get_height()) / s.get_width())), Image.INTERPOLATE_LANCZOS)
	var t_h := mini(size - s.get_height(), int(size * float(t.get_height()) / t.get_width()))
	t.resize(int(t_h * float(t.get_width()) / t.get_height()) if t_h < int(size * float(t.get_height()) / t.get_width()) else size, t_h, Image.INTERPOLATE_LANCZOS)
	atlas = Image.create(size, size, true, Image.FORMAT_RGB8)
	atlas.fill(Color(0.55, 0.57, 0.55))
	atlas.blit_rect(s, Rect2i(Vector2i.ZERO, s.get_size()), Vector2i.ZERO)
	atlas.blit_rect(t, Rect2i(Vector2i.ZERO, t.get_size()), Vector2i(0, s.get_height()))
	side_uv = Rect2(0, 0, 1, float(s.get_height()) / size)
	top_uv = Rect2(0, float(s.get_height()) / size, float(t.get_width()) / size, float(t.get_height()) / size)
	atlas.generate_mipmaps()

# Coordenadas del modelo: x lateral (+derecha), y arriba, z longitudinal con el morro en -z (convención Godot).
func _uv_side(p: Vector3) -> Vector2:
	var u := (p.z / length_m) + 0.5
	var v := 0.5 - p.y / (length_m * float(side_rect.size.y) / side_rect.size.x)
	return side_uv.position + Vector2(u, v) * side_uv.size

func _uv_top(p: Vector3) -> Vector2:
	var u := 0.5 + p.x / span_m
	var v := (p.z / length_m) + 0.5
	return top_uv.position + Vector2(u, v) * top_uv.size

# ---------- medidas ----------
func _side_x(s: float) -> int: return side_rect.position.x + int(s * (side_rect.size.x - 1))
func _top_y(s: float) -> int: return top_rect.position.y + int(s * (top_rect.size.y - 1))
func _m_per_px_side() -> float: return length_m / side_rect.size.x
func _m_per_px_top_long() -> float: return length_m / top_rect.size.y
func _m_per_px_top_span() -> float: return span_m / top_rect.size.x

func _interp_gaps(arr: PackedFloat32Array, bad: PackedByteArray) -> void:
	var n := arr.size()
	var i := 0
	while i < n:
		if bad[i] == 1:
			var a := i - 1
			var b := i
			while b < n and bad[b] == 1: b += 1
			var va := arr[a] if a >= 0 else (arr[b] if b < n else 0.0)
			var vb := arr[b] if b < n else va
			for k in range(i, b):
				var t := float(k - a) / float(b - a) if b < n and a >= 0 else 0.0
				arr[k] = lerpf(va, vb, t)
			i = b
		else:
			i += 1

func _median(values: Array) -> float:
	if values.is_empty(): return 0.0
	var v := values.duplicate(); v.sort()
	return v[v.size() / 2]

func _build(blades: int, wing_engines: bool) -> Node3D:
	var root := Node3D.new(); root.name = "Aircraft"
	var cx := int(top_rect.get_center().x)
	# Eje vertical del fuselaje en la lateral: mediana del centro de los tramos en la zona trasera (sin ala ni motores).
	var centers := []
	for k in range(30):
		var x := _side_x(0.6 + 0.2 * k / 29.0)
		var r := _run(side_mask, sw, sh, x, int(side_rect.get_center().y), true)
		if r.x >= 0: centers.append((r.x + r.y) / 2.0)
	var axis_y = _median(centers) if not centers.is_empty() else side_rect.get_center().y
	# Perfiles a lo largo del fuselaje.
	var half_w := PackedFloat32Array(); var top_z := PackedFloat32Array(); var bot_z := PackedFloat32Array()
	var bad_w := PackedByteArray(); var bad_h := PackedByteArray()
	for i in STATIONS:
		var s := float(i) / (STATIONS - 1)
		var rt := _run(top_mask, tw, th, _top_y(s), cx, false)
		half_w.append(maxf(0.0, (rt.y - rt.x) * 0.5) * _m_per_px_top_span() if rt.x >= 0 else 0.0)
		var rs := _run(side_mask, sw, sh, _side_x(s), int(axis_y), true)
		var mp := _m_per_px_side()
		top_z.append((axis_y - rs.x) * mp if rs.x >= 0 else 0.0)
		bot_z.append((rs.y - axis_y) * mp if rs.x >= 0 else 0.0)
	# Ancho típico del fuselaje (zona trasera) para detectar las filas de ala/estabilizador y de deriva/motores.
	var tail_w := []
	var tail_h := []
	for i in range(int(STATIONS * 0.6), int(STATIONS * 0.8)):
		tail_w.append(half_w[i]); tail_h.append(top_z[i] + bot_z[i])
	var ref_w := _median(tail_w)
	var max_body_w := 0.0
	for i in STATIONS:
		bad_w.append(1 if half_w[i] > ref_w * 1.9 else 0)
		bad_h.append(0)
	_interp_gaps(half_w, bad_w)
	for i in STATIONS: max_body_w = maxf(max_body_w, half_w[i])
	# En la lateral, donde la silueta es mucho más alta que el doble de la anchura local, hay ala/motor/deriva: suavizar.
	var fin_top := PackedFloat32Array(); fin_top.resize(STATIONS)
	for i in STATIONS:
		var hgt := top_z[i] + bot_z[i]
		if hgt > half_w[i] * 2.0 * 1.9 and half_w[i] > 0.0:
			bad_h[i] = 1
		fin_top[i] = top_z[i]
	var top_s := top_z.duplicate(); var bot_s := bot_z.duplicate()
	_interp_gaps(top_s, bad_h); _interp_gaps(bot_s, bad_h)
	# --- fuselaje ---
	var body := _loft_body(half_w, top_s, bot_s)
	root.add_child(body)
	# --- alas y estabilizador desde la planta ---
	print("  fuselaje: semiancho_max=%.2f m ref_cola=%.2f m eje_y=%.0f px" % [max_body_w, ref_w, axis_y])
	var lifts := _planforms(cx, max_body_w)
	var wing_y := -0.45 * (bot_s[int(STATIONS * 0.4)])
	for surf in lifts:
		var y_root: float = wing_y if surf["kind"] == "ala" else 0.15 * top_s[int(STATIONS * 0.9)]
		for side in [-1.0, 1.0]:
			root.add_child(_wing(surf, side, y_root, max_body_w))
	# --- deriva desde la lateral (zona trasera donde la silueta sube por encima del fuselaje) ---
	root.add_child(_fin(fin_top, top_s))
	# --- motores y hélices ---
	if wing_engines:
		for nac in _nacelles(cx, lifts): print("  góndola x=%.2f r=%.2f z0=%.2f z1=%.2f" % [nac["x"], nac["r"], nac["z0"], nac["z1"]])
		var i := 0
		for nac in _nacelles(cx, lifts):
			root.add_child(_nacelle(nac, wing_y))
			root.add_child(_rotor("Rotor_%d" % i, Vector3(nac["x"], wing_y, nac["z0"] - 0.15), nac["r"] * 1.9, blades)); i += 1
	else:
		root.add_child(_rotor("Rotor_0", Vector3(0, 0.0, -length_m * 0.5 - 0.05), span_m * 0.16, blades))
	return root

var _mat_cache: StandardMaterial3D

func _material() -> StandardMaterial3D:
	if _mat_cache: return _mat_cache
	var m := StandardMaterial3D.new()
	m.albedo_texture = ImageTexture.create_from_image(atlas)
	m.metallic = 0.35
	m.roughness = 0.55
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	_mat_cache = m
	return m

func _emit(st: SurfaceTool, tri: Array, normals: Array, force := "") -> void:
	# UV por triángulo según su normal: arriba/abajo → planta; costados → lateral. Las superficies sustentadoras fuerzan la planta.
	var fn: Vector3 = (tri[1] - tri[0]).cross(tri[2] - tri[0]).normalized()
	var use_top := absf(fn.y) > absf(fn.x)
	if force == "top": use_top = true
	elif force == "side": use_top = false
	for k in 3:
		st.set_normal(normals[k])
		st.set_uv(_uv_top(tri[k]) if use_top else _uv_side(tri[k]))
		st.add_vertex(tri[k])

func _loft_body(half_w: PackedFloat32Array, top_s: PackedFloat32Array, bot_s: PackedFloat32Array) -> MeshInstance3D:
	var rings := []
	var ring_n := []
	for i in STATIONS:
		var s := float(i) / (STATIONS - 1)
		var z := (s - 0.5) * length_m
		var hw := maxf(half_w[i], 0.02)
		var hh := maxf((top_s[i] + bot_s[i]) * 0.5, 0.02)
		var cy := (top_s[i] - bot_s[i]) * 0.5
		var ring := []
		var nrm := []
		for j in RING:
			var a := TAU * j / RING
			var ca := cos(a); var sa := sin(a)
			# Superelipse (exponente 2,4): algo más "cuadrada" que una elipse, como un fuselaje real.
			var ex := signf(ca) * pow(absf(ca), 2.0 / 2.4)
			var ey := signf(sa) * pow(absf(sa), 2.0 / 2.4)
			ring.append(Vector3(ex * hw, cy + ey * hh, z))
			nrm.append(Vector3(ca / hw, sa / hh, 0).normalized())
		rings.append(ring); ring_n.append(nrm)
	var st := SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in STATIONS - 1:
		for j in RING:
			var j2 := (j + 1) % RING
			var a: Vector3 = rings[i][j]; var b: Vector3 = rings[i][j2]; var c: Vector3 = rings[i + 1][j2]; var d: Vector3 = rings[i + 1][j]
			var na: Vector3 = ring_n[i][j]; var nb: Vector3 = ring_n[i][j2]; var nc: Vector3 = ring_n[i + 1][j2]; var nd: Vector3 = ring_n[i + 1][j]
			_emit(st, [a, c, b], [na, nc, nb])
			_emit(st, [a, d, c], [na, nd, nc])
	var mi := MeshInstance3D.new(); mi.name = "Fuselage"
	mi.mesh = st.commit(); mi.material_override = _material()
	return mi

func _fit_line(xs: Array, ys: Array, reject_forward := false) -> Vector2:
	# Recta y = a + b·x por mínimos cuadrados con dos pasadas de rechazo de atípicos (góndolas, puntas).
	var keep := range(xs.size())
	var ab := Vector2.ZERO
	for _pass in 6:
		var n := float(keep.size())
		if n < 2: break
		var sx := 0.0; var sy := 0.0; var sxx := 0.0; var sxy := 0.0
		for k in keep:
			sx += xs[k]; sy += ys[k]; sxx += xs[k] * xs[k]; sxy += xs[k] * ys[k]
		var den := n * sxx - sx * sx
		var b := (n * sxy - sx * sy) / den if absf(den) > 1e-6 else 0.0
		ab = Vector2((sy - b * sx) / n, b)
		var res := []
		for k in keep: res.append(ys[k] - (ab.x + ab.y * xs[k]))
		var absr := []
		for r in res: absr.append(absf(r))
		var lim: float = _median(absr) * 2.0 + 0.15
		var nk := []
		for idx in keep.size():
			# Borde de ataque: las góndolas quedan POR DELANTE (z menor) → se rechaza solo ese lado.
			var ok: bool = (res[idx] >= -lim) if reject_forward else (absf(res[idx]) <= lim * 1.5)
			if ok: nk.append(keep[idx])
		keep = nk
	return ab

func _planforms(cx: int, body_w: float) -> Array:
	# Bandas de filas (morro→cola) donde la silueta en planta es mucho más ancha que el fuselaje.
	var rows_wide := []
	for y in range(top_rect.position.y, top_rect.end.y):
		var x0 := -1; var x1 := -1
		for x in range(top_rect.position.x, top_rect.end.x):
			if top_mask[y * tw + x] == 1:
				if x0 < 0: x0 = x
				x1 = x
		rows_wide.append((x1 - x0) * _m_per_px_top_span() if x0 >= 0 else 0.0)
	var bands := []
	var inside := false; var start := 0
	for i in rows_wide.size():
		var wide: bool = rows_wide[i] > body_w * 2.0 * 2.2
		if wide and not inside: inside = true; start = i
		if (not wide or i == rows_wide.size() - 1) and inside:
			inside = false
			if i - start > 3: bands.append(Vector2i(start + top_rect.position.y, i + top_rect.position.y))
	var out := []
	var widest := 0.0
	for band in bands:
		var w := 0.0
		for y in range(band.x, band.y): w = maxf(w, rows_wide[y - top_rect.position.y])
		widest = maxf(widest, w)
	for band in bands:
		var w := 0.0
		for y in range(band.x, band.y): w = maxf(w, rows_wide[y - top_rect.position.y])
		if w < widest * 0.15: continue
		var kind := "ala" if w >= widest * 0.8 else "estabilizador"
		# Para cada columna fuera del fuselaje (lado izquierdo): borde de ataque y de salida dentro de la banda.
		var xs := []; var le := []; var te := []
		var tip_x := cx
		var body_px := int(body_w / _m_per_px_top_span())
		for x in range(top_rect.position.x, cx - body_px):
			var y0 := -1; var y1 := -1
			for y in range(band.x - 6, band.y + 6):
				if y >= 0 and y < th and top_mask[y * tw + x] == 1:
					if y0 < 0: y0 = y
					y1 = y
			if y0 >= 0:
				xs.append(float(cx - x) * _m_per_px_top_span())
				le.append((y0 - top_rect.position.y) * _m_per_px_top_long() - length_m * 0.5)
				te.append((y1 - top_rect.position.y) * _m_per_px_top_long() - length_m * 0.5)
				tip_x = mini(tip_x, x)
		if xs.size() < 4: continue
		var semi_here: float = float(cx - tip_x) * _m_per_px_top_span()
		var xo := []; var leo := []
		for k in xs.size():
			if xs[k] > semi_here * 0.62 and xs[k] < semi_here * 0.95:
				xo.append(xs[k]); leo.append(le[k])
		var le_fit: Vector2 = _fit_line(xo, leo, true) if xo.size() >= 4 else _fit_line(xs, le, true)
		print("  banda %s filas %d-%d (bbox %d-%d) ancho_max=%.1f m  le=%s te=%s semi=%.1f" % [kind, band.x, band.y, top_rect.position.y, top_rect.end.y, w, le_fit, _fit_line(xs, te), float(cx - tip_x) * _m_per_px_top_span()])
		out.append({"kind": kind, "le": le_fit, "te": _fit_line(xs, te), "semi": float(cx - tip_x) * _m_per_px_top_span(), "xs": xs, "le_raw": le})
	return out

func _airfoil(chord: float, thick: float) -> Array:
	# Perfil simétrico de 12 puntos (z relativo al borde de ataque, y espesor).
	var pts := []
	for k in 13:
		var t := float(k) / 12.0
		var yt := 5.0 * thick * (0.2969 * sqrt(t) - 0.126 * t - 0.3516 * t * t + 0.2843 * t * t * t - 0.1036 * t * t * t * t)
		pts.append(Vector2(t * chord, yt * chord))
	return pts

func _wing(surf: Dictionary, side: float, y_root: float, body_w: float) -> MeshInstance3D:
	var semi: float = surf["semi"]
	var le: Vector2 = surf["le"]; var te: Vector2 = surf["te"]
	var dihedral := deg_to_rad(4.0 if surf["kind"] == "ala" else 1.0)
	var n := 24
	var sections := []
	for k in n + 1:
		var e := lerpf(body_w * 0.6, semi, float(k) / n)
		var z0 := le.x + le.y * e
		var z1 := te.x + te.y * e
		if k == n:  # punta redondeada: acorta la cuerda
			var mid := (z0 + z1) * 0.5; z0 = lerpf(z0, mid, 0.35); z1 = lerpf(z1, mid, 0.35)
		var chord := maxf(z1 - z0, 0.05)
		var thick := lerpf(0.16, 0.09, float(k) / n) if surf["kind"] == "ala" else 0.09
		var prof := _airfoil(chord, thick)
		var ring := []
		for p in prof: ring.append(Vector3(side * e, y_root + e * tan(dihedral) + p.y, z0 + p.x))
		for idx in range(prof.size() - 2, 0, -1):
			var p: Vector2 = prof[idx]
			ring.append(Vector3(side * e, y_root + e * tan(dihedral) - p.y, z0 + p.x))
		sections.append(ring)
	var st := SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var m: int = sections[0].size()
	for k in n:
		for j in m:
			var j2 := (j + 1) % m
			var a: Vector3 = sections[k][j]; var b: Vector3 = sections[k][j2]; var c: Vector3 = sections[k + 1][j2]; var d: Vector3 = sections[k + 1][j]
			# Normal de cara orientada hacia fuera de la línea media del perfil (evita brillos alternos en el borde de salida).
			var cen: Vector3 = (a + b + c + d) / 4.0
			var mid := Vector3(cen.x, y_root + absf(cen.x) * tan(dihedral), cen.z)
			var fn: Vector3 = (b - a).cross(c - a).normalized()
			if fn.dot(cen - mid) < 0.0:
				fn = -fn
				_emit(st, [a, c, b], [fn, fn, fn], "top")
				_emit(st, [a, d, c], [fn, fn, fn], "top")
			else:
				_emit(st, [a, b, c], [fn, fn, fn], "top")
				_emit(st, [a, c, d], [fn, fn, fn], "top")
	var mi := MeshInstance3D.new(); mi.name = ("Wing" if surf["kind"] == "ala" else "Tailplane") + ("L" if side < 0 else "R")
	mi.mesh = st.commit(); mi.material_override = _material()
	return mi

func _fin(fin_top: PackedFloat32Array, body_top: PackedFloat32Array) -> MeshInstance3D:
	# Columnas traseras donde la silueta lateral sobresale > 25 % por encima del fuselaje suavizado.
	var outline := []
	for i in range(int(STATIONS * 0.55), STATIONS):
		if fin_top[i] > body_top[i] * 1.25 + 0.1:
			var z := (float(i) / (STATIONS - 1) - 0.5) * length_m
			outline.append(Vector3(0, fin_top[i], z))
			outline.append(Vector3(0, body_top[i] * 0.85, z))
	var st := SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var half_t := length_m * 0.008
	for k in range(0, outline.size() - 2, 2):
		var a: Vector3 = outline[k]; var b: Vector3 = outline[k + 1]; var c: Vector3 = outline[k + 3]; var d: Vector3 = outline[k + 2]
		for sgn in [-1.0, 1.0]:
			var o := Vector3(sgn * half_t, 0, 0)
			var nn := Vector3(sgn, 0, 0)
			_emit(st, [a + o, b + o, c + o], [nn, nn, nn], "side")
			_emit(st, [a + o, c + o, d + o], [nn, nn, nn], "side")
		var cap := Vector3(0, 1, 0)
		_emit(st, [a + Vector3(-half_t, 0, 0), a + Vector3(half_t, 0, 0), d + Vector3(half_t, 0, 0)], [cap, cap, cap], "side")
		_emit(st, [a + Vector3(-half_t, 0, 0), d + Vector3(half_t, 0, 0), d + Vector3(-half_t, 0, 0)], [cap, cap, cap], "side")
	var mi := MeshInstance3D.new(); mi.name = "Fin"
	mi.mesh = st.commit(); mi.material_override = _material()
	return mi

func _nacelles(cx: int, lifts: Array, per_side: int = 2) -> Array:
	# Góndolas: máximos locales de cuánto se adelanta el borde de ataque real respecto a la recta del tramo exterior.
	var out := []
	for surf in lifts:
		if surf["kind"] != "ala": continue
		var xs: Array = surf["xs"]; var raw: Array = surf["le_raw"]; var le: Vector2 = surf["le"]
		var fwd := []
		for k in xs.size(): fwd.append((le.x + le.y * xs[k]) - raw[k])
		var sm := []
		for k in xs.size():
			var acc := 0.0; var n := 0
			for q in range(maxi(0, k - 3), mini(xs.size(), k + 4)): acc += fwd[q]; n += 1
			sm.append(acc / n)
		var peaks := []
		for k in range(1, xs.size() - 1):
			if sm[k] >= sm[k - 1] and sm[k] >= sm[k + 1] and sm[k] > 0.4:
				peaks.append({"e": xs[k], "v": sm[k], "z0": raw[k]})
		peaks.sort_custom(func(a, b): return a["v"] > b["v"])
		var chosen := []
		for pk in peaks:
			var far := true
			for c in chosen:
				if absf(c["e"] - pk["e"]) < span_m * 0.08: far = false
			if far: chosen.append(pk)
			if chosen.size() == per_side: break
		var te: Vector2 = surf["te"]
		for c in chosen:
			for sgn in [-1.0, 1.0]:
				out.append({"x": sgn * c["e"], "r": span_m * 0.024, "z0": c["z0"], "z1": te.x + te.y * c["e"]})
	return out

func _nacelle(nac: Dictionary, wing_y: float) -> MeshInstance3D:
	var cyl := CylinderMesh.new()
	cyl.top_radius = nac["r"] * 0.85; cyl.bottom_radius = nac["r"]; cyl.height = nac["z1"] - nac["z0"]; cyl.radial_segments = 20
	var mi := MeshInstance3D.new(); mi.name = "Nacelle"
	mi.mesh = cyl
	mi.rotation.x = -PI / 2
	mi.position = Vector3(nac["x"], wing_y, (nac["z0"] + nac["z1"]) * 0.5)
	var m := StandardMaterial3D.new(); m.albedo_color = Color(0.62, 0.63, 0.62); m.metallic = 0.6; m.roughness = 0.4
	mi.material_override = m
	return mi

func _rotor(label: String, pos: Vector3, radius: float, blades: int) -> Node3D:
	var rotor := Node3D.new(); rotor.name = label; rotor.position = pos
	var dark := StandardMaterial3D.new(); dark.albedo_color = Color(0.06, 0.06, 0.06); dark.roughness = 0.6
	var tip := StandardMaterial3D.new(); tip.albedo_color = Color(0.85, 0.7, 0.1)
	var spin := SphereMesh.new(); spin.radius = radius * 0.16; spin.height = radius * 0.45
	var sp := MeshInstance3D.new(); sp.name = "Spinner"; sp.mesh = spin; sp.material_override = dark; sp.rotation.x = PI / 2
	rotor.add_child(sp)
	for b in blades:
		var ang := TAU * b / blades
		var blade := MeshInstance3D.new(); blade.name = "Blade"
		var box := BoxMesh.new(); box.size = Vector3(radius * 0.13, radius, radius * 0.03)
		blade.mesh = box; blade.material_override = dark
		blade.position = (Vector3.UP * radius * 0.5).rotated(Vector3.FORWARD, ang)
		blade.rotation.z = -ang
		rotor.add_child(blade)
		var t := MeshInstance3D.new(); t.name = "Tip"
		var tb := BoxMesh.new(); tb.size = Vector3(radius * 0.135, radius * 0.08, radius * 0.035)
		t.mesh = tb; t.material_override = tip
		t.position = (Vector3.UP * radius * 0.96).rotated(Vector3.FORWARD, ang); t.rotation.z = -ang
		rotor.add_child(t)
	return rotor
