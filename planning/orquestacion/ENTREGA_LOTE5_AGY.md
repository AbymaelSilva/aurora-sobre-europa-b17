# Entrega Lote 5: Terreno Nuevo y Set de Audio en el Juego

**Fecha:** 2026-10-24T15:29:00-07:00  
**Autor:** Agy (coordinador técnico y QA) / Qwen (programador banco de sonidos)  
**Supervisor:** Claude  
**Estado:** awaiting_review  

---

## 1. Resumen de Cambios

### Tarea A: Terreno Nuevo y Escala de Shader 1200 m
- **`godot/B17/world/farmland.gdshader`**:
  - Modificada la escala de mosaico de `/2800.0` a `/1200.0` para corresponder con los 1200 m por mosaico convenidos.
- **`godot/B17/game.gd`**:
  - Textura `farmland_texture` actualizada a `res://assets/terrain/farmland_t1.png`.
  - Mecanismo de carga dual compatible (`load` si está importado, o `Image.load_from_file` + `ImageTexture` si aún no fue procesado por el importador de Godot).
  - Preservada la textura anterior `assets/terrain/farmland_a.png` intacta.
- **`godot/B17/tests/test_terrain_t1.gd`**:
  - Prueba automatizada que instancia `game.tscn`, valida que `$Ground.material_override` tiene el shader con `/1200.0` y no `/2800.0`, y que `farmland_texture` apunta a `farmland_t1.png`. Resultado: **PASS**.

### Tarea B: Banco de Sonidos (`godot/B17/audio/sfx_bank.gd`)
- Generado por Qwen a través del puente autorizado (`encargar_qwen.py`) en el intento 1/3.
- `class_name SfxBank extends RefCounted`.
- `const DIR := "res://assets/audio/sfx/"`.
- `get_stream(name: String) -> AudioStream`: carga `DIR + name + ".wav"`. Para streams que terminan en `_loop`, clona la muestra con `.duplicate()`, asigna `loop_mode = AudioStreamWAV.LOOP_FORWARD`, `loop_begin = 0` y calcula `loop_end` acorde al total de muestras reales (`round(get_length() * mix_rate)` / formato PCM).
- `random_variant(base: String, count: int, rng: RandomNumberGenerator = null) -> AudioStream`: selecciona una variante aleatoria formateada `%s_%02d` (ej. `flak_near_01..03`), admitiendo generador `rng` opcional.
- **`godot/B17/tests/test_sfx_bank.gd`**:
  - Valida que `engine_b17_ext_loop` tiene `LOOP_FORWARD` y `loop_end > 0`.
  - Valida que `bomb_release` no tiene bucle (`LOOP_DISABLED`).
  - Valida que `random_variant("flak_near", 3, rng)` devuelve uno de los 3 WAV válidos.
  - Valida bucles estéreo (`wind_altitude_loop`). Resultado: **PASS**.

### Tarea C: Integración de Audio en `game.gd`
- **1. Motores del B-17:**
  - `engine_audio` reproduce `engine_b17_ext_loop` en estación `PILOTO` y conmuta suavemente a `engine_b17_int_loop` en `ARTILLERO` o `BOMBARDERO`.
  - `engine_damaged_audio` se añade como reproductor secundario a -14 dB reproduciendo `engine_b17_damaged_loop` si cualquier motor cae por debajo del 50 % de salud.
  - El pitch de ambos se modula según la velocidad relativa crucero (`speed / 85.0`).
- **2. Disparos:**
  - `gun_audio` configurado con `max_polyphony = 4`.
  - Cada nuevo disparo defensivo reproduce una variante aleatoria `gun_m2_shot_01..03`.
- **3. Flak:**
  - En cada ráfaga de antiaérea, si el estallido se produce a menos de 150 m del avión reproduce `flak_near_01..03`, y si no `flak_far_01..02`.
- **4. Bombardeo:**
  - Reproduce `bomb_release` en el momento de soltar la bomba.
  - Reproduce `bomb_impact_distant` en el instante del impacto sobre el suelo.
  - Si el resultado es `IMPACTO`, reproduce `bomb_secondary_explosions` exactamente 1,0 s después.
- **5. Avisos del HUD:**
  - `cue_release_now` solo se reproduce en el flanco de subida de `bombing_aid.release_now` (una sola vez por pasada de aproximación).
  - `cue_course_correction` solo se reproduce al entrar en el estado `CORREGIR_RUMBO`.
- **6. Puestos y Menú UI:**
  - `station_switch` al conmutar entre puestos.
  - `ui_pause` al abrir la pausa.
  - `ui_back` al reanudar la misión.
  - `ui_profile_change` al cambiar el perfil de control.
- **7. Fin de Misión:**
  - `stinger_mission_complete` o `stinger_mission_failed` reproducido una sola vez al entrar en las fases terminales `COMPLETADA` o `FALLIDA`.
- **8. Radio:**
  - `radio_squelch_open` se activa cuando cambia el mensaje de radio a uno no vacío.
- **Pool de SFX y Pausa:**
  - Pool de 4 `AudioStreamPlayer` para one-shots dinámicos.
  - Pausados coherentemente durante la pausa del simulador (`stream_paused`).
  - Archivos existentes `audio/engine_tone.gd` y `audio/combat_sfx.gd` preservados como respaldo sin borrar.
- **`godot/B17/tests/test_audio_integration.gd`**:
  - Prueba automatizada que valida con la escena completa: motor con bucle, conmutación ext/int en BOMBARDERO, sonido de suelta de bomba, flanco único de `cue_release_now`, stinger único en COMPLETADA, y activación de motor dañado a < 50%. Resultado: **PASS**.

---

## 2. Resultados de las Pruebas

Orden literal ejecutada para cada prueba:
`/home/test-bench/Documents/B17-project/tools/godot --headless --path /home/test-bench/Documents/B17-project/godot/B17 --script res://tests/<archivo>.gd`

| # | Archivo de prueba | Resultado |
|---|---|---|
| 1 | `tests/test_terrain_t1.gd` | **PASS** |
| 2 | `tests/test_sfx_bank.gd` | **PASS** |
| 3 | `tests/test_audio_integration.gd` | **PASS** |
| 4 | `tests/test_local_control_directions.gd` | **PASS** |
| 5 | `tests/test_player_controls.gd` | **PASS** |
| 6 | `tests/test_manual_mission_claude.gd` | **PASS** |
| 7 | `tests/test_neutral_station_inputs.gd` | **PASS** |
| 8 | `tests/test_bombing_aid.gd` | **PASS** |
| 9 | `tests/test_local_bombing_usability.gd` | **PASS** |
| 10 | `tests/test_imported_aircraft_integration.gd` | **PASS** |
| 11 | `tests/test_formation_six.gd` | **PASS** |
| 12 | `tests/test_scene_mission.gd` | **PASS** |
| 13 | `tests/test_release_acceptance.gd` | **PASS** |
| 14 | `tests/test_overlay_integrity.gd` | **PASS** |
| 15 | `tests/test_victory_defeat_pause_reset.gd` | **PASS** |
| 16 | `tests/test_combat_and_engine_damage.gd` | **PASS** |
| 17 | `tests/test_input_profiles.gd` | **PASS** |
| 18 | `tests/test_settings_menu_unit.gd` | **PASS** |
| 19 | `tests/test_probar_mando.gd` | **PASS** |
| 20 | `tests/test_audio_assets.gd` | **PASS** |

**Total suite: 20/20 PASS.**

---

## 3. Estado de la Entrega

- Estado: **`awaiting_review`**
- Siguiente paso: Verificación independiente por el supervisor Claude con GPU para textura/shader de terreno y comprobación de niveles de audio en registros.
