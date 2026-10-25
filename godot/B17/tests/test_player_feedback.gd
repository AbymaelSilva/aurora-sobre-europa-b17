extends SceneTree

const Feedback = preload("res://core/player_feedback.gd")

func check(ok: bool, message: String) -> bool:
	if not ok:
		push_error("TEST FAIL: " + message)
		quit(1)
	return ok

func _initialize() -> void:
	var feedback = Feedback.new()
	var fighters: Array = [{"alive": true, "health": 60.0}, {"alive": true, "health": 60.0}]
	var before: Array[Dictionary] = Feedback.snapshot(fighters)
	fighters[0].health = 35.0
	feedback.record_shot(before, fighters)
	if not check(feedback.shots == 1 and feedback.hits == 1 and feedback.kills == 0 and feedback.message == "IMPACTO", "Impacto manual no confirmado"): return
	feedback.advance(1.0, true)
	if not check(feedback.remaining == 0.65, "Pausa consume confirmación"): return
	feedback.advance(1.0, false)
	if not check(feedback.message.is_empty(), "Confirmación no termina"): return
	# Un derribo de IA fuera de record_shot no cuenta como manual.
	fighters[1].health = -1.0
	fighters[1].alive = false
	if not check(feedback.kills == 0, "Derribo automático atribuido al jugador"): return
	before = Feedback.snapshot(fighters)
	feedback.record_shot(before, fighters)
	if not check(feedback.shots == 2 and feedback.hits == 1 and feedback.message.is_empty(), "Disparo fallado genera confirmación"): return
	before = Feedback.snapshot(fighters)
	fighters[0].health = -5.0
	fighters[0].alive = false
	feedback.record_shot(before, fighters)
	if not check(feedback.kills == 1 and feedback.message == "DERRIBO CONFIRMADO", "Derribo real no confirmado"): return
	var stats: Dictionary = feedback.stats(2)
	if not check(stats.manual_kills == 1 and stats.other_kills == 1 and stats.manual_hits == 2, "Resumen mezcla autores de derribos"): return
	feedback.reset()
	if not check(feedback.kills == 0 and feedback.shots == 0 and feedback.message.is_empty(), "Reinicio no limpia contadores"): return
	print("TEST PASS: impacto, fallo, derribo, autoría manual, pausa y reinicio")
	quit(0)
