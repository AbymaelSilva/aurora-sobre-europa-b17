extends RefCounted

var last_phase: String = ""
var message: String = ""
var remaining: float = 0.0

func reset() -> void:
    last_phase = ""
    message = ""
    remaining = 0.0

func advance(delta: float, phase: String, hull: float) -> void:
    remaining = max(remaining - max(delta, 0.0), 0.0)
    if phase != last_phase:
        last_phase = phase
        remaining = 8.0
        match phase:
            "FORMACION":
                message = "Aurora líder: mantengan la formación."
            "APROXIMACION":
                message = "Navegante: rumbo al nudo ferroviario."
            "BOMBARDEO":
                message = "Bombardero: preparados para la suelta."
            "REGRESO":
                message = "Aurora líder: blanco alcanzado. Volvemos a casa."
            "COMPLETADA":
                message = "Control: los tenemos a la vista. Bienvenidos."
            "FALLIDA":
                message = "Aurora líder: emergencia a bordo."
            _:
                message = ""
    if remaining <= 0:
        message = ""
