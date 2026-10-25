extends SceneTree
# Recorta una hoja de calcas sobre fondo blanco en piezas RGBA independientes.
# Uso: godot --headless --script cut_sheet.gd -- <hoja.png> <carpeta_salida> <prefijo> <modo>
#   modo "flood": transparente solo el blanco conectado con el borde (conserva el blanco interior: estrellas, recuadros).
#   modo "ink":   alfa = oscuridad (miras de línea negra, humo oscuro); color sin premultiplicar.
# Autor: Claude (herramienta de preparación de arte, no código del juego).

const WHITE_TOL := 0.10
const SCALE := 4

func _init() -> void:
	var a := OS.get_cmdline_user_args()
	var img := Image.load_from_file(a[0])
	img.convert(Image.FORMAT_RGBA8)
	var out_dir: String = a[1]
	var prefix: String = a[2]
	var mode: String = a[3]
	DirAccess.make_dir_recursive_absolute(out_dir)
	var w := img.get_width()
	var h := img.get_height()
	var bg := PackedByteArray()
	bg.resize(w * h)
	if mode == "flood":
		_flood_background(img, bg, w, h)
	else:
		_ink_alpha(img, bg, w, h)
	var boxes := _components(bg, w, h)
	var n := 0
	for box in boxes:
		if box.size.x < 24 or box.size.y < 24:
			continue
		n += 1
		var piece := img.get_region(box.grow(6).intersection(Rect2i(0, 0, w, h)))
		piece.save_png("%s/%s_%02d.png" % [out_dir, prefix, n])
	print("%s: %d piezas en %s" % [prefix, n, out_dir])
	quit()

func _is_white(c: Color) -> bool:
	return c.r > 1.0 - WHITE_TOL and c.g > 1.0 - WHITE_TOL and c.b > 1.0 - WHITE_TOL

func _flood_background(img: Image, bg: PackedByteArray, w: int, h: int) -> void:
	var stack := PackedInt32Array()
	for x in w:
		stack.append(x); stack.append((h - 1) * w + x)
	for y in h:
		stack.append(y * w); stack.append(y * w + w - 1)
	while stack.size() > 0:
		var i := stack[stack.size() - 1]
		stack.resize(stack.size() - 1)
		if bg[i] == 1:
			continue
		var x := i % w
		var y := i / w
		if not _is_white(img.get_pixel(x, y)):
			continue
		bg[i] = 1
		if x > 0: stack.append(i - 1)
		if x < w - 1: stack.append(i + 1)
		if y > 0: stack.append(i - w)
		if y < h - 1: stack.append(i + w)
	for y in h:
		for x in w:
			if bg[y * w + x] == 1:
				img.set_pixel(x, y, Color(1, 1, 1, 0))
			else:
				# Borde suave: los píxeles casi blancos junto al fondo se atenúan.
				var c := img.get_pixel(x, y)
				var near_bg := (x > 0 and bg[y * w + x - 1] == 1) or (x < w - 1 and bg[y * w + x + 1] == 1)
				if near_bg:
					c.a = clampf((1.0 - minf(c.r, minf(c.g, c.b))) * 4.0, 0.25, 1.0)
					img.set_pixel(x, y, c)

func _ink_alpha(img: Image, bg: PackedByteArray, w: int, h: int) -> void:
	for y in h:
		for x in w:
			var c := img.get_pixel(x, y)
			var alpha := smoothstep(0.04, 0.6, 1.0 - c.get_luminance())
			if alpha <= 0.01:
				bg[y * w + x] = 1
				img.set_pixel(x, y, Color(0, 0, 0, 0))
			else:
				var k := 1.0 - alpha
				var u := Color(clampf((c.r - k) / alpha, 0, 1), clampf((c.g - k) / alpha, 0, 1), clampf((c.b - k) / alpha, 0, 1), alpha)
				img.set_pixel(x, y, u)

func _components(bg: PackedByteArray, w: int, h: int) -> Array[Rect2i]:
	# Componentes conexas sobre una rejilla reducida (SCALE) para unir trazos finos de la misma pieza.
	var gw := w / SCALE + 1
	var gh := h / SCALE + 1
	var grid := PackedByteArray()
	grid.resize(gw * gh)
	for y in h:
		for x in w:
			if bg[y * w + x] == 0:
				grid[(y / SCALE) * gw + x / SCALE] = 1
	# Dilatación de 3 celdas para que las piezas con huecos (miras, marcas de misión) queden juntas.
	var dil := grid.duplicate()
	for gy in gh:
		for gx in gw:
			if grid[gy * gw + gx] == 1:
				for dy in range(-3, 4):
					for dx in range(-3, 4):
						var nx := gx + dx
						var ny := gy + dy
						if nx >= 0 and ny >= 0 and nx < gw and ny < gh:
							dil[ny * gw + nx] = 1
	var seen := PackedByteArray()
	seen.resize(gw * gh)
	var boxes: Array[Rect2i] = []
	for start in gw * gh:
		if dil[start] == 0 or seen[start] == 1:
			continue
		var minx := gw; var miny := gh; var maxx := 0; var maxy := 0
		var stack := PackedInt32Array([start])
		seen[start] = 1
		while stack.size() > 0:
			var i := stack[stack.size() - 1]
			stack.resize(stack.size() - 1)
			var x := i % gw
			var y := i / gw
			minx = mini(minx, x); maxx = maxi(maxx, x); miny = mini(miny, y); maxy = maxi(maxy, y)
			for j in [i - 1, i + 1, i - gw, i + gw]:
				if j >= 0 and j < gw * gh and dil[j] == 1 and seen[j] == 0 and absi(j % gw - x) <= 1:
					seen[j] = 1
					stack.append(j)
		boxes.append(Rect2i(minx * SCALE, miny * SCALE, (maxx - minx + 1) * SCALE, (maxy - miny + 1) * SCALE))
	return boxes
