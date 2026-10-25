# tests/test_cloud_sprites.gd
extends SceneTree

func _init() -> void:
	print("--- TEST CLOUD SPRITES ---")
	var cs = load("res://world/cloud_sprites.gd").new()
	root.add_child(cs)
	print("  Cloud count: %d" % cs.cloud_count())
	print("  Used texture: %s" % cs.used_texture_path)
	assert(cs.cloud_count() >= 80 and cs.cloud_count() <= 160, "Recuento de nubes debe estar entre 80 y 160")
	assert(cs.used_texture_path != "", "Debe haber cargado una textura válida")
	cs.queue_free()
	print("ALL CLOUD SPRITES TESTS PASSED!")
	quit(0)
