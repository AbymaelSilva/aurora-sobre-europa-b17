extends SceneTree

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var target_res := "res://assets/ui/gunsight_ring.png"
	var backup_res := "res://assets/ui/gunsight_ring.original.png"

	var target_global := ProjectSettings.globalize_path(target_res)
	var backup_global := ProjectSettings.globalize_path(backup_res)

	var img: Image = null
	if FileAccess.file_exists(backup_res):
		img = Image.load_from_file(backup_global)
		print("Respaldo existente encontrado en: %s" % backup_global)
	else:
		img = Image.load_from_file(target_global)
		if img == null:
			printerr("Error al cargar la imagen: %s" % target_global)
			quit(1)
			return
		var err := img.save_png(backup_global)
		if err != OK:
			printerr("Error al guardar respaldo: %s" % backup_global)
			quit(1)
			return
		print("Respaldo guardado en: %s" % backup_global)

	if img == null:
		printerr("No se pudo cargar la imagen.")
		quit(1)
		return

	var w := img.get_width()
	var h := img.get_height()
	var center := Vector2(float(w) * 0.5, float(h) * 0.5)

	var r_min: float = float(w) * 0.01
	var r_max: float = float(w) * 0.04

	var changed: int = 0

	for y in range(h):
		for x in range(w):
			var pos := Vector2(float(x) + 0.5, float(y) + 0.5)
			var dist := pos.distance_to(center)
			if dist >= r_min and dist <= r_max:
				var col := img.get_pixel(x, y)
				if col.a > 0.0:
					col.a = 0.0
					img.set_pixel(x, y, col)
					changed += 1

	var save_err := img.save_png(target_global)
	if save_err != OK:
		printerr("Error al guardar la imagen procesada: %s" % target_global)
		quit(1)
		return

	print("H-14 gunsight_ring procesado con exito.")
	print("Dimensiones: %dx%d px" % [w, h])
	print("Radio interno (1%%): %.2f px, Radio externo (4%%): %.2f px" % [r_min, r_max])
	print("Pixeles cambiados: %d" % changed)
	quit(0)
