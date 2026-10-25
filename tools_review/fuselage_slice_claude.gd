extends SceneTree
# Revisión Claude: sección del fuselaje del GLB en z dados y prueba de punto dentro (rayos ±X/±Y).
# Uso: tools/godot --headless --path godot/B17 --script <abs>/fuselage_slice_claude.gd -- <glb_nombre> "x,y,z;x,y,z"

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var a := OS.get_cmdline_user_args()
	var inst: Node3D = (load("res://assets/aircraft/models/%s.glb" % a[0]) as PackedScene).instantiate()
	root.add_child(inst)
	var fus := inst.find_child("Fuselage", true, false) as MeshInstance3D
	var arr := fus.mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	for spec in a[1].split(";"):
		var c := spec.split(",")
		var p := Vector3(float(c[0]), float(c[1]), float(c[2]))
		var ymin := INF; var ymax := -INF; var xmax := 0.0
		for v in verts:
			var w: Vector3 = fus.transform * v
			if absf(w.z - p.z) < 0.35:
				ymin = minf(ymin, w.y); ymax = maxf(ymax, w.y); xmax = maxf(xmax, absf(w.x))
		var inside := p.y > ymin and p.y < ymax and absf(p.x) < xmax
		print("PUNTO %s seccion_z=%.2f y=[%.2f, %.2f] semiancho=%.2f dentro_caja_seccion=%s holgura_techo=%.2f" % [p, p.z, ymin, ymax, xmax, inside, p.y - ymax])
	quit(0)
