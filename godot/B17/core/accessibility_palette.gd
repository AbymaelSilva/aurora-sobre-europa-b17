class_name AccessibilityPalette extends RefCounted

# Paletas alternativas para HUD/marcadores (ALTO 3.2). "positive"/"danger"/"warning"
# son los pares que más confunden daltonismo rojo-verde; se reemplazan por
# combinaciones azul/naranja/amarillo más distinguibles en esos modos.
const PALETTES: Dictionary = {
	"NINGUNO": {
		"positive": Color(0.3, 0.85, 0.4),
		"danger": Color(0.9, 0.2, 0.2),
		"warning": Color(0.9, 0.6, 0.2),
	},
	"PROTANOPIA": {
		"positive": Color(0.3, 0.6, 0.95),
		"danger": Color(0.95, 0.45, 0.1),
		"warning": Color(0.95, 0.85, 0.2),
	},
	"DEUTERANOPIA": {
		"positive": Color(0.3, 0.6, 0.95),
		"danger": Color(0.95, 0.45, 0.1),
		"warning": Color(0.95, 0.85, 0.2),
	},
	"TRITANOPIA": {
		"positive": Color(0.2, 0.95, 0.3),
		"danger": Color(0.9, 0.15, 0.5),
		"warning": Color(0.95, 0.5, 0.2),
	},
}

static func color_for(semantic: String, mode: String) -> Color:
	var palette: Dictionary = PALETTES.get(mode, PALETTES["NINGUNO"])
	return palette.get(semantic, PALETTES["NINGUNO"].get(semantic, Color.WHITE))
