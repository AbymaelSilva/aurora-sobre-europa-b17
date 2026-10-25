extends RefCounted

var shots: int = 0
var hits: int = 0
var kills: int = 0
var message: String = ""
var remaining: float = 0.0

static func snapshot(fighters: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for fighter in fighters:
		result.append({"alive": bool(fighter.get("alive", false)), "health": float(fighter.get("health", 0.0))})
	return result

func record_shot(before: Array[Dictionary], after: Array) -> void:
	# Se llama solo alrededor del disparo manual síncrono, nunca de un paso de IA.
	shots += 1
	var hit: bool = false
	var downed: int = 0
	for i in range(mini(before.size(), after.size())):
		if not before[i].alive: continue
		var health: float = float(after[i].get("health", 0.0))
		if health < float(before[i].health): hit = true
		if not bool(after[i].get("alive", false)) and health <= 0.0:
			downed += 1
	if hit: hits += 1
	if downed > 0:
		kills += downed
		message = "DERRIBO CONFIRMADO"
		remaining = 1.4
	elif hit:
		message = "IMPACTO"
		remaining = 0.65

func advance(delta: float, paused: bool) -> void:
	if paused: return
	remaining = maxf(0.0, remaining - maxf(delta, 0.0))
	if remaining <= 0.0: message = ""

func reset() -> void:
	shots = 0
	hits = 0
	kills = 0
	message = ""
	remaining = 0.0

func stats(total_kills: int) -> Dictionary:
	return {"manual_shots": shots, "manual_hits": hits, "manual_kills": kills,
		"total_kills": total_kills, "other_kills": maxi(0, total_kills - kills)}
