# Revisión 1.1.3.4 — Estado de hallazgos (integrado) — Claude

- Hora real: 2026-10-24T11:12:39-07:00. Candidato: manifiesto estable `logs/revision_claude/20261024T175932Z-integrado/manifest_antes.txt` (= staging `local-20261024-acd6e3ddfc40`). Hashes sin cambios antes y después.
- No se modificó producción.

## Dictamen: **sin S1/S2 abiertos atribuibles a modelos, cámaras ni ObjectDB.** Lo que bloquea V1 local son U01/U02 (Codex), que ya tienen encargo a Agy/Qwen.

| ID | Baseline | Integrado (este árbol) | Sev. V1 local | Evidencia |
|---|---|---|---|---|
| H-01 Norden dentro del fuselaje | S1 | **CERRADO.** Avión propio oculto, cámara delante del morro, suelo al 100 % | — | 11/13_puesto_bombardero |
| H-02 humo desalineado | S2 | **CERRADO.** dx=0,00 m, derivado de los nodos | — | log «medida humo», 17/19_h_humo_motor1 |
| H-03 Ø hélice B-17 | S3 | Sin cambios (2,59 m) | S3, no bloquea | glb_medidas.json (baseline) |
| H-04 orden de los motores | S1 | **CERRADO.** Orden por x: R0,R2,R3,R1 | — | log «motor=i rotor=…» |
| H-05 disparo del artillero | S1 | **CERRADO** (PASS de Codex, 0,000°, mismos hashes) | — | REVISION_LOCAL_CONTROL_DIRECTIONS.md |
| H-06 D gira a la izquierda | S1 | **CERRADO** (PASS de Codex, mismos hashes) | — | ídem |
| H-08 corte del terreno | S2 | **PRESENTE** (línea vertical fina en el centro y triángulos en las vistas cenitales). **Reclasificado a S3**: no tapa información ni impide jugar; es una costura del shader | S3 | capturas_1280/02_h_formacion_6, capturas_1920/13_puesto_bombardero |
| H-11 ObjectDB al salir | S2 | **REPRODUCIDO en salida real, sin crecimiento.** Reclasificado a S3. Detalle abajo | S3 | logs objectdb_* |
| H-12 reinicio solo con R | diferido | Sin cambios | DIFERIDO_POST_V1 | — |
| H-13 texto Ally X en HUD | S3 | Presente. Su retirada está en ENCARGO_U01_U02_AGY | S3 | 01_inicio |
| H-14 (nuevo) el punto de la mira tapa el caza | — | Ver REVISION_CLAUDE_1.1.2.3.md | S3 | oclusion_reticula/comparacion_con_sin.png |
| H-15 (nuevo) detalles procedurales con cotas antiguas | — | `visuals/bomber_details.gd` coloca los escapes en x=±4,4/±9,4 (góndolas GLB en ±3,80/±7,73) y las ametralladoras de cola en z=12,3 (la cola del GLB acaba en +11,33). En las capturas apenas se distinguen | S3 | 03_h_b17_cerca |
| H-16 (nuevo) compañeros cortados en persecución | — | 2 completos y 2 cortados detrás de los paneles | S3 | 01, 06 |
| U01 / U02 (Codex) | — | Coincido visualmente con U01: con la cruz Norden a −78° (13_puesto_bombardero) el suelo bajo la cruz está ≈266 m por delante y no hay ninguna señal de suelta. No lo vuelvo a medir | Bloqueante según Codex/supervisor | REVISION_BOMBARDEO_MANUAL_CODEX.md |

## H-11 — investigación del warning ObjectDB
**Qué se fuga:** 1 AudioStreamWAV y su AudioStreamPlaybackWAV. El id fugado (9223372094098639164) es el del stream de `engine_audio` (tono de motor en bucle, que siempre suena). Las ids impresas como int64 negativo son el mismo uint64 (`objectdb_headless_*.log`).

**Repro en el cierre real del juego (no harness):** `tools/godot --path godot/B17 --resolution 1280x720 --verbose --quit-after 600`, con ventana, GPU y audio real: **3/3 con la fuga** (`objectdb_main_ventana_quitafter600_{1,2,3}.log`). Headless con `--quit-after 600`: también (`objectdb_main_headless_quitafter600.log`).

**Harness frente a real:**
- La escena como escena actual con `quit()` inmediato tras 600 frames, con ventana: 4/6 con la fuga. Depende de la temporización.
- Con mi script de capturas, que libera la escena y espera un frame, no apareció en las 3 ejecuciones GPU de hoy, pero sí en mi script headless que libera y sale enseguida (`objectdb_headless_liberar.log`). Una prueba que no avise no demuestra que esté resuelto.

**¿Crece durante el juego?** No. Con 6 misiones demo completas y 5 reinicios con `restart_mission()`, los contadores no cambian: objetos=2778, recursos=203, nodos=718, huérfanos=0 en los 6 ciclos (`objectdb_crecimiento_6ciclos.log`). Es una fuga solo de cierre: no hay pérdida de memoria en partida, por eso la dejo en S3.

**Causa:** `game.gd` hace `stop()` + `stream=null` en `_exit_tree`/PREDELETE. AudioServer retira el playback de su lista de forma asíncrona, en el hilo de mezcla. Si el proceso termina antes, el playback (que referencia el stream) sigue en la lista y se informa como fuga.

**Corrección concreta propuesta a Agy (game.gd, ≈10 líneas, opcional para V1 local):**
```gdscript
func _ready() -> void:
    get_tree().auto_accept_quit = false
    # ... resto igual

func _notification(what: int) -> void:
    if what == NOTIFICATION_WM_CLOSE_REQUEST:
        for a in [engine_audio, gun_audio, flak_audio, bomb_audio]:
            if is_instance_valid(a):
                a.stop()
        await get_tree().create_timer(0.25).timeout
        get_tree().quit()
    # mantener aquí el bloque PREDELETE/EXIT_TREE existente
```
Comprobado en el harness equivalente (`tools_review/objectdb_fix_probe_claude.gd`, con ventana): `inmediato` tiene la fuga en 4/6 y `parar` (stop + 0,25 s + quit) en 0/6 (`objectdb_sonda_ventana_*_{1..6}.log`). Límite: `--quit-after` no pasa por WM_CLOSE_REQUEST, así que para comprobarlo hay que cerrar la ventana de verdad o enviar la notificación. No lo declaro resuelto hasta verlo en el árbol corregido.

## Pasos para reproducir cualquiera de estas medidas
- Capturas: `tools/godot --path godot/B17 --resolution 1280x720 --script res://tests/capture_mission_claude.gd -- /ruta/absoluta` (y `--fullscreen --resolution 1920x1080`). Sin carpeta absoluta o en headless sale con código 1.
- Visibilidad de los cazas: `tools/godot --path godot/B17 --headless --script res://../../tools_review/fighter_visibility_claude.gd`.
- Oclusión de la mira: `tools/godot --path godot/B17 --fullscreen --resolution 1920x1080 --script res://../../tools_review/gunner_occlusion_claude.gd -- /ruta/absoluta`.
- ObjectDB: `tools_review/objectdb_exit_claude.gd -- en_arbol|liberar|crecimiento` y `tools_review/objectdb_fix_probe_claude.gd -- inmediato|parar`.
