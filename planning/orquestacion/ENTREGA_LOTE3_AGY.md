# Entrega LOTE 3 — Devolución 2 del Supervisor (Agy / Qwen)
**Fecha:** 2026-10-24T14:24:00-07:00  
**Estado:** Entregado para revisión independiente (`awaiting_review`)  
**Responsable técnico:** AGY (coordinación, integración y QA)

---

## 1. Correcciones de Presentación Aplicadas según Devolución 2 (Lote 3)

### Defecto 1 — Marcador de navegación sobre botón Reanudar & Panel Opaco
- **`godot/B17/game.gd` (`set_pause`)**:
  - Se añade llamada a `settings_menu.move_to_front()` al pausar (`if paused: settings_menu.move_to_front()`), asegurando que el menú quede por encima del marcador de navegación (`ui/navigation_marker.gd`) y de cualquier otro nodo en el árbol `$HUD`.
- **`godot/B17/ui/settings_menu.gd` (`_ready`)**:
  - Se configuró el `PanelContainer` del menú con un `StyleBoxFlat` opaco:
    - Color de fondo: `Color(0.08, 0.09, 0.11, 0.96)`.
    - Radio de esquinas: `6` px (`set_corner_radius_all(6)`).
    - Margen interior: `16` px (`set_content_margin_all(16)`).
    - Impide que el contenido 3D y elementos HUD de fondo interfieran visualmente con los botones del menú.

### Defecto 2 — Texto «PAUSA» centrado detrás del menú
- **`godot/B17/ui/mission_overlay.gd` (`_draw`)**:
  - Se preservó la línea con la cadena `"PAUSA"` exigida por `test_overlay_integrity.gd`, pero envuelta en la condición:
    ```gdscript
    if not data.get("menu_visible", false):
        draw_string(font, Vector2(width / 2 - 200, height / 2), "PAUSA", HORIZONTAL_ALIGNMENT_CENTER, 400, 36, white)
    ```
  - Se conserva el oscurecimiento general de fondo `draw_rect(Rect2(0, 0, width, height), Color(0, 0, 0, 0.3))`.
- **`godot/B17/game.gd` (`update_presentation`)**:
  - Se envía `"menu_visible": settings_menu.visible if settings_menu != null else false` dentro del diccionario de estado para `overlay.set_state(...)`.

### Defecto 3 — Nombres legibles en perfiles & Prompts de cruceta con flechas
- **`godot/B17/core/input_profile.gd`**:
  - Añadido método estático:
    ```gdscript
    static func display_name(profile) -> String:
        match str(profile):
            "TECLADO_RATON": return "Teclado y ratón"
            "XBOX": return "Mando Xbox"
            "ROG_ALLY_X": return "ROG Ally X"
            _: return str(profile)
    ```
  - Prompts de cambio de puesto en mando unificados al español con flechas:
    - `"piloto"`: `"Cruceta ↑"` (en `XBOX` y `ROG_ALLY_X`).
    - `"artillero"`: `"Cruceta →"` (en `XBOX` y `ROG_ALLY_X`).
    - `"bombardero"`: `"Cruceta ↓"` (en `XBOX` y `ROG_ALLY_X`).
- **`godot/B17/ui/settings_menu.gd` (`_update_ui`)**:
  - Se actualiza el texto del botón de perfil usando `InputProfile.display_name`:
    `profile_button.text = "Controles: ◀ %s ▶" % InputProfile.display_name(current_profile)`
    (Ejemplo visible: `Controles: ◀ Mando Xbox ▶`, `Controles: ◀ Teclado y ratón ▶`, `Controles: ◀ ROG Ally X ▶`).

---

## 2. Histórico de Correcciones Previas (Devolución 1, Lote 3)

### Hallazgo 1 — Activación con mando en menú
- `game.gd`: Mapeo de `JOY_BUTTON_A` a `"ui_accept"` y `JOY_BUTTON_B` a `"ui_cancel"` en `InputMap`.
- `settings_menu.gd`: `ui_cancel` emite `resume_requested`.
- Verificado por `Input.parse_input_event` (A en Reanudar despausa, B despausa, A en Reiniciar reinicia).

### Hallazgo 2 — Preservación de `user://b17_settings.cfg` en tests
- `test_input_profile_unit.gd`, `test_settings_menu_unit.gd` y `test_input_profiles.gd` preservan y restauran el archivo del usuario en caso de éxito o fallo.

### Hallazgo 3 — Cadencia de fuego con mando (`joy_fire_cooldown`)
- `player_controls.gd`: cooldown de 0.12 s decreciente con delta para `RB / X` mantenidos (~8 disparos/s). Disparo por clic y barra espaciadora intactos.

### Hallazgo 4 — Artillero con mando en modo DEMO
- `player_controls.gd`: Stick derecho y disparo funcionales con autopiloto cuando `station == "ARTILLERO"`.

### Hallazgo 5 — Prompt dinámico de puestos en overlay
- `input_profile.gd`: Acción `"puestos"` devuelve `"1/2/3"` en teclado y `"Cruceta"` en mandos.
- `mission_overlay.gd`: Indicación de puesto manual `[%s] MANUAL · PUESTO: %s`.

---

## 3. Resultados de las Pruebas

Ejecutadas mediante la orden obligatoria:
`/home/test-bench/Documents/B17-project/tools/godot --headless --path /home/test-bench/Documents/B17-project/godot/B17 --script res://tests/<archivo>.gd`

### A. Pruebas de Lote 3
1. **`test_input_profiles.gd`**: **PASS**
2. **`test_input_profile_unit.gd`**: **PASS** (incluye verificación de `display_name` y flechas `Cruceta ↑/→/↓`)
3. **`test_settings_menu_unit.gd`**: **PASS** (incluye verificación de etiqueta legible en botón de controles)

### B. Pruebas de Regresión Exigidas
1. **`test_overlay_integrity.gd`**: **PASS** (cadena "PAUSA" preservada y visible cuando menú cerrado)
2. **`test_local_control_directions.gd`**: **PASS**
3. **`test_player_controls.gd`**: **PASS**
4. **`test_neutral_station_inputs.gd`**: **PASS**
5. **`test_local_bombing_usability.gd`**: **PASS**
6. **`test_victory_defeat_pause_reset.gd`**: **PASS**

---

## 4. Estado Final
Estado: **`awaiting_review`** para revisión del supervisor Claude y captura GPU.
