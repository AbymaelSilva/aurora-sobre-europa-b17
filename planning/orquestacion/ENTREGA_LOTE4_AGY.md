# Entrega LOTE 4 — Cierre de Controles (Agy / Qwen)
**Fecha:** 2026-10-24T14:48:50-07:00  
**Estado:** Entregado para revisión independiente (`awaiting_review`)  
**Responsable técnico:** AGY (coordinación, integración y QA)  
**Programador:** QWEN (vía puente autorizado `encargar_qwen.py`)

---

## 1. Resumen de Tareas Ejecutadas

### Tarea A — Confirmación de R en Misión Activa
- **`godot/B17/game.gd`**:
  - Se añade variable de control `var restart_confirm_timer: float = 0.0`.
  - En `_unhandled_input`:
    - En pantallas finales (`sim.mission.phase in ["COMPLETADA", "FALLIDA"]`), la tecla `KEY_R` reinicia de inmediato (`restart_confirm_timer = 0.0; restart_mission()`).
    - En misión activa, la primera pulsación de `KEY_R` activa una ventana de 2 segundos: `restart_confirm_timer = 2.0; update_presentation(0.0)`.
    - Si se pulsa `KEY_R` de nuevo mientras `restart_confirm_timer > 0.0`, se cancela el temporizador y se ejecuta `restart_mission()`.
    - La opción «Reiniciar misión» del menú de configuración (`settings_menu.restart_requested`) sigue llamando directamente a `restart_mission()`, manteniéndose inmediata.
  - En `update_presentation`:
    - Decrementa `restart_confirm_timer` según `delta` si `delta > 0.0`.
    - En caso de fase `COMPLETADA` o `FALLIDA`, fuerza `restart_confirm_timer = 0.0`.
    - Expone `"restart_confirm": restart_confirm_timer > 0.0` en el diccionario de datos entregado al overlay.
  - En `reset_presentation`: asegura `restart_confirm_timer = 0.0`.
- **`godot/B17/ui/mission_overlay.gd`**:
  - Al recibir `data["restart_confirm"] == true`, dibuja en la parte superior central (sin interferir con el panel de misión ni el indicador de puesto/autopiloto):
    - Panel de aviso `Rect2(width / 2 - 180, 24, 360, 32)` con borde dorado.
    - Cadena exacta: `«Pulsa R otra vez para reiniciar»` en fuente tamaño 13 color dorado.
- **`godot/B17/tests/test_victory_defeat_pause_reset.gd`**:
  - Se amplía la prueba con la sección 2b:
    1. Verifica que durante la misión en marcha (`FORMACION`), una sola pulsación de R NO reinicia el reloj ni el avión, y activa `data["restart_confirm"] = true`.
    2. Verifica que una segunda pulsación de R dentro de 2 s SÍ reinicia la misión y limpia `restart_confirm`.
    3. Verifica que si pasa el tiempo (2.1 s), la confirmación expira, y una nueva pulsación de R vuelve a actuar como primera pulsación (no reinicia sin segunda confirmación).
    4. Conserva las comprobaciones de reinicio inmediato con una sola R en pantallas de derrota (`DERRIBO`, `FALLO`) y victoria (`COMPLETADA`).

### Tarea B — Herramienta de Diagnóstico de Mando (`tools/probar_mando.gd`)
- **Generación**:
  - Generado mediante el puente autorizado Qwen (`qwen2.5-coder:7b-instruct-q4_K_M`) en el intento 1/3.
  - Archivo: `godot/B17/tools/probar_mando.gd` (extends `SceneTree`).
  - Hash SHA-256: `72d7a21af4c9b4e6a9f4c3d53063ae3cd90f006981b91f3a0970188fb5f0f717`.
  - Registro de inferencia: `logs/agy-qwen/20261024T214643-1792878403595991457`.
- **Características implementadas**:
  - **Interfaz en ventana**:
    - Control a pantalla completa con fondo oscuro y `Label` con fuente grande (20 pt).
    - Muestra lista de mandos conectados (ID, nombre `Input.get_joy_name`, GUID `Input.get_joy_guid`).
    - Muestra perfil sugerido mediante `InputProfile.suggest_profile` y nombre amigable `InputProfile.display_name`.
    - Muestra ejes analógicos con 2 decimales (`LX`, `LY`, `RX`, `RY`, `LT`, `RT`).
    - Muestra botones pulsados con su nombre físico y su acción en el juego según `player_controls.gd`:
      - `A → Soltar bomba / Aceptar`
      - `RB → Disparar`
      - `Cruceta ↓ → Puesto Bombardero`
      - `Cruceta ↑ → Puesto Piloto`
      - `Cruceta → → Puesto Artillero`
      - `Vista → Autopiloto ON/OFF`
      - `Menú → Pausa / Menú`
  - **Condiciones de salida**:
    - Se cierra pulsando `ESC` o manteniendo `Vista + Menú` durante 2 s.
  - **Estado sin mando**:
    - Si no hay ningún mando conectado, muestra: `«No se detecta ningún mando: conéctalo por USB o Bluetooth»`.
  - **Funciones estáticas puras**:
    - `get_button_name(button_index: int) -> String`
    - `get_button_action(button_index: int) -> String`
    - `get_axis_name(axis_index: int) -> String`
    - `describe(state: Dictionary) -> String`
    - `poll_state(hold_time: float) -> Dictionary`
  - **Modo headless amigable**:
    - Si se ejecuta directamente en headless (`DisplayServer.get_name() == "headless"`), imprime el diagnóstico actual y sale con código 0 sin bloquear el hilo.
- **Prueba headless**:
  - Archivo: `godot/B17/tests/test_probar_mando.gd`.
  - Verifica sin ventana: nombres de botones, acciones de juego, nombres de ejes, formateo de ejes a 2 decimales, mensaje «no se detecta», y simulaciones de estados con mandos Xbox y ROG Ally X.

---

## 2. Verificación de Pruebas (9/9 PASS)

Ejecutadas con la orden literal requerida:
`/home/test-bench/Documents/B17-project/tools/godot --headless --path /home/test-bench/Documents/B17-project/godot/B17 --script res://tests/<archivo>.gd`

| # | Prueba | Resultado | Observaciones |
|---|---|---|---|
| 1 | `test_input_profiles.gd` | **PASS** (código 0) | Carga, guardado, fallback, perfiles, suelta y navegación |
| 2 | `test_settings_menu_unit.gd` | **PASS** (código 0) | Inicialización, señales, ciclo y foco de menú |
| 3 | `test_victory_defeat_pause_reset.gd` | **PASS** (código 0) | Pausa (P/Esc), confirmación R en vuelo, 1-R en debriefing |
| 4 | `test_overlay_integrity.gd` | **PASS** (código 0) | Integridad textual y diccionario runtime |
| 5 | `test_local_control_directions.gd` | **PASS** (código 0) | Direcciones A/D, flechas, 60 casos de artillero H05/H06 |
| 6 | `test_player_controls.gd` | **PASS** (código 0) | Mapeo analógico, zonas muertas, puestos y disparo |
| 7 | `test_neutral_station_inputs.gd` | **PASS** (código 0) | 6 casos de neutralización al cambiar de puesto |
| 8 | `test_local_bombing_usability.gd` | **PASS** (código 0) | 9 casos balísticos reales de ayuda de bombardeo |
| 9 | `test_probar_mando.gd` | **PASS** (código 0) | Diagnóstico de mando, nombres, acciones, ejes y perfiles |

---

## 3. Estado de la Entrega

- Estado reportado: `awaiting_review`.
- No hay comandos prohibidos ni scripts ad-hoc ejecutados.
- Todo listo para la revisión del supervisor Claude y empaquetado final.
