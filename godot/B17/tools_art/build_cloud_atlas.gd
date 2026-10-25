extends SceneTree

func _initialize() -> void:
	var source := Image.load_from_file(ProjectSettings.globalize_path("res://../../art/openart/clouds_lote8/cloud_atlas_4k_original.png"))
	if source == null or source.get_size() != Vector2i(4096, 4096):
		push_error("Atlas OpenArt ausente o dimensiones incorrectas")
		quit(1)
		return
	source.convert(Image.FORMAT_RGBA8)
	var pixels := source.get_data()
	var transparent: int = 0
	for y in range(4096):
		for x in range(4096):
			var idx: int = (y * 4096 + x) * 4
			var r: float = pixels[idx] / 255.0
			var g: float = pixels[idx + 1] / 255.0
			var b: float = pixels[idx + 2] / 255.0
			var value: float = maxf(r, maxf(g, b))
			# Fondo negro: mantener sombras densas y descontaminar filamentos suaves.
			var alpha: float = smoothstep(0.008, 0.65, value)
			var edge: int = mini(mini(x % 1024, 1023 - x % 1024), mini(y % 1024, 1023 - y % 1024))
			alpha *= smoothstep(0.0, 8.0, float(edge))
			if alpha < 0.004:
				pixels[idx] = 230
				pixels[idx + 1] = 235
				pixels[idx + 2] = 242
				pixels[idx + 3] = 0
				transparent += 1
			else:
				pixels[idx] = int(clampf(r / alpha, 0.0, 1.0) * 255)
				pixels[idx + 1] = int(clampf(g / alpha, 0.0, 1.0) * 255)
				pixels[idx + 2] = int(clampf(b / alpha, 0.0, 1.0) * 255)
				pixels[idx + 3] = int(alpha * 255)
	var output := Image.create_from_data(4096, 4096, false, Image.FORMAT_RGBA8, pixels)
	var err := output.save_png("res://assets/sky/cloud_atlas_realistic_v2.png")
	if err != OK:
		quit(1)
		return
	var small := output.duplicate() as Image
	small.resize(1024, 1024, Image.INTERPOLATE_LANCZOS)
	for kind in ["blue", "dark"]:
		var backdrop := Image.create(1024, 1024, false, Image.FORMAT_RGBA8)
		backdrop.fill(Color(0.32, 0.46, 0.62) if kind == "blue" else Color(0.12, 0.14, 0.17))
		backdrop.blend_rect(small, Rect2i(0, 0, 1024, 1024), Vector2i.ZERO)
		backdrop.save_png("res://../../art/openart/clouds_lote8/preview_%s.png" % kind)
	print("CLOUD ATLAS PASS: RGBA8 4096x4096, transparent pixels=", transparent)
	quit(0)
