# Entrega Lote 2 — Agy (presentación S3 / 1.1.2.4)
Fecha: 2026-10-24T12:18:40-07:00
Estado: awaiting_review
Autor: Agy

---

## 1. Tareas Realizadas y Archivos Modificados

### A. H-15 — Ajuste de cotas procedurales en bomber_details.gd
- **Archivo modificado**: `godot/B17/visuals/bomber_details.gd`
- **Cambios realizados**:
  - Ametralladoras de cola (`TailGunL` y `TailGunR`): cota `z` ajustada de `12.3` a `11.2` (dentro del límite del fuselaje GLB en $z=+11.33$, cumpliendo $z \le 11.2$).
  - Góndolas de escapes: tabla de coordenadas `x` ajustada de `[-9.4, -4.4, 4.4, 9.4]` a `[-7.73, -3.80, 3.80, 7.73]` coincidiendo con las góndolas GLB.
- **Diff resumen**:
  ```gdscript
  -    barrel("TailGunL", Vector3(-0.12, 0.3, 12.3), Vector3(0.06, 0.06, 1.0))
  -    barrel("TailGunR", Vector3(0.12, 0.3, 12.3), Vector3(0.06, 0.06, 1.0))
  +    barrel("TailGunL", Vector3(-0.12, 0.3, 11.2), Vector3(0.06, 0.06, 1.0))
  +    barrel("TailGunR", Vector3(0.12, 0.3, 11.2), Vector3(0.06, 0.06, 1.0))
  ...
  -    for x in [-9.4, -4.4, 4.4, 9.4]:
  +    for x in [-7.73, -3.80, 3.80, 7.73]:
  ```

### B. H-11 — Fuga ObjectDB al cerrar AudioStreamWAV
- **Archivo modificado**: `godot/B17/game.gd`
- **Cambios realizados**:
  - En `_ready()`: añadida la instrucción `get_tree().auto_accept_quit = false`.
  - En `_notification(what: int)`: añadida rama `NOTIFICATION_WM_CLOSE_REQUEST` que detiene los 4 reproductores de audio (`engine_audio`, `gun_audio`, `flak_audio`, `bomb_audio`), realiza `await get_tree().create_timer(0.25).timeout` y luego invoca `get_tree().quit()`.
  - Se conservó íntegro el bloque preexistente `NOTIFICATION_PREDELETE / NOTIFICATION_EXIT_TREE` y el método `_exit_tree()`.
- **Diff resumen**:
  ```gdscript
   func _ready() -> void:
  +    get_tree().auto_accept_quit = false
       var material := ShaderMaterial.new()
  ...
   func _notification(what: int) -> void:
  +    if what == NOTIFICATION_WM_CLOSE_REQUEST:
  +        for a in [engine_audio, gun_audio, flak_audio, bomb_audio]:
  +            if is_instance_valid(a):
  +                a.stop()
  +        await get_tree().create_timer(0.25).timeout
  +        get_tree().quit()
  +    elif what == NOTIFICATION_PREDELETE or what == NOTIFICATION_EXIT_TREE:
  -    if what == NOTIFICATION_PREDELETE or what == NOTIFICATION_EXIT_TREE:
           for a in [engine_audio, gun_audio, flak_audio, bomb_audio]:
               if is_instance_valid(a):
                   a.stop()
                   a.stream = null
  ```

### C. H-14 — Vaciado del centro de la retícula del artillero
- **Script creado**: `godot/B17/tools/clear_gunsight_center.gd` (`extends SceneTree`)
  - Carga `res://assets/ui/gunsight_ring.png` mediante `Image.load_from_file(ProjectSettings.globalize_path(...))`.
  - Si no existe `res://assets/ui/gunsight_ring.original.png`, crea primero allí el respaldo de la imagen original intacta. Si ya existe, parte siempre del respaldo para no realizar doble recorte.
  - Pone alfa en 0 a los píxeles cuya distancia al centro esté entre el 1% y el 4% del ancho (entre 10.44 px y 41.76 px), preservando un micro-punto central ($\le 10$ px) y el anillo exterior ($> 42$ px).
  - Guarda con `save_png` en `res://assets/ui/gunsight_ring.png`.
- **Ejecución**:
  - Comando: `/home/test-bench/Documents/B17-project/tools/godot --headless --path /home/test-bench/Documents/B17-project/godot/B17 --script res://tools/clear_gunsight_center.gd`
  - Salida:
    - Respaldo guardado en: `.../godot/B17/assets/ui/gunsight_ring.original.png`
    - Dimensiones: 1044x1052 px
    - Radio interno (1%): 10.44 px, Radio externo (4%): 41.76 px
    - Píxeles cambiados: 756
    - Código de retorno: 0

---

## 2. Verificación de Regresión Cuádruple (Ejecutada tras cada parche)

Todas las ejecuciones se realizaron estrictamente con la orden literal requerida:
`/home/test-bench/Documents/B17-project/tools/godot --headless --path /home/test-bench/Documents/B17-project/godot/B17 --script res://tests/<archivo>.gd`

| Test | Resultado | Observaciones |
|---|---|---|
| `res://tests/test_overlay_integrity.gd` | **PASS (rc=0)** | Integridad estática y dinámica de telemetría y HUD verificada. |
| `res://tests/test_imported_aircraft_integration.gd` | **PASS (rc=0)** | Modelos GLB activos, 6 bombarderos, rotores reales, mapeo por transform y cazas Bf109/Fw190. |
| `res://tests/test_scene_mission.gd` | **PASS (rc=0)** | Misión completa (785.12s, 60 ráfagas, casco 55.3%). Con la aplicación de H-11, el cierre final no emite fugas de ObjectDB. |
| `res://tests/test_victory_defeat_pause_reset.gd` | **PASS (rc=0)** | Pausa (P/Esc), derrota (derribo/fallo bomba), victoria y reset (R) verificados con eventos reales. |

---

## 3. Estado
- Estado del agente puesto en: **`awaiting_review`** en `planning/AGY_ESTADO.json`.
- Listo para la inspección y cálculo de hashes por parte del supervisor Claude.
