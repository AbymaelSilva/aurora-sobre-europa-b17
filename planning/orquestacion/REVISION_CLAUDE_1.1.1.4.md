# Revisión 1.1.1.4 — Modelos integrados (GLB) — Claude

- Hora real: 2026-10-24T11:12:39-07:00. Máquina: Linux, NVIDIA GeForce RTX 2060 SUPER, Vulkan Forward+, Godot 4.7.2-stable (`tools/godot`).
- Autorización: VENTANA_REVISION_ACTUAL.md (revisión incremental sin marker de Agy).
- Candidato revisado: árbol de producción `godot/B17` con manifiesto `logs/revision_claude/20261024T175932Z-integrado/manifest_antes.txt` (sha256 del manifiesto e9652124…; 135 archivos, excluidos tests/ y .godot). **Hashes idénticos antes, entre y después de todas las capturas** (`manifest_pre_final.txt`, `manifest_despues.txt`, `manifest_redaccion.txt`: diff vacío). Los 135 archivos coinciden byte a byte con `release/local-20261024-acd6e3ddfc40/MANIFEST_STAGING.json` (135/135, 0 diferencias).
- Hashes clave: game.gd 5d801e88…, aircraft.gd 2db34c5d…, visuals/fighter.gd dbb90e3c…, visuals/engine_anchors.gd 72b144e8…, core/player_controls.gd 382eac71… (los mismos que el PASS H05/H06 de Codex de 10:56:35).
- No se modificó producción. Solo se tocó mi herramienta `tests/capture_mission_claude.gd` (guardas + capturas de harness) y `tools_review/*_claude.gd`.

## Dictamen: **ACEPTADO** para V1 local (sin S1/S2 en modelos)

## Evidencia (capturas GPU reales, no headless)
- 1280×720 (ventana): `logs/revision_claude/20261024T175932Z-integrado/capturas_1280/` (19 PNG, rc=0, `capturas_1280.log`).
- 1920×1080 (pantalla completa, PNG verificados a 1920×1080): `.../capturas_1920/` (19 PNG, rc=0). La ventana de 1920×1080 sin `--fullscreen` la recorta el escritorio a 1853×1011; ese conjunto se conserva aparte como `capturas_1853x1011_ventana/` y no se usa para K5.
- Primera pasada de 1280 (17 PNG, mismo árbol) en `capturas_1280_r1/`. Repetí para añadir el caso de caza cercano.
- Las PNG `h_*` son de cámara o estado forzados por el harness (formación desde arriba, primer plano, humo forzado) y se identifican así. Las demás usan el encuadre real del juego.

| Criterio | Resultado | Evidencia |
|---|---|---|
| O1 escala/dimensiones | PASS. Escala global (1,0,1,0,1,0) en los 6 B-17 y en los cazas, uniforme. Con escala 1, las dimensiones son las del GLB medido (31,62 m). AABB de los cazas en escena 10,13 m (Bf 109, +2,2 % sobre 9,92 m con el disco de la hélice) y 10,65 m (Fw 190, +1,4 %) | log «medida … escala», «caza=… aabb» |
| O2 orientación de las piezas | PASS. Todos los Rotor_* tienen z<0 (−7,87/−8,07). El Fin está en la cola en todas las vistas (el origen del nodo Fin es 0; el criterio se verifica con la medida de malla del baseline y con las capturas) | 03_h_b17_cerca, 07/08 |
| O3 avance | PASS en las muestras tomadas: 0,00° en los 6 B-17 (inicio, cazas, humo) y en los cazas vivos (Bf 109 y Fw 190). Fueron 3 instantes, no 10. La orientación viene del código (`Basis.looking_at(vel)` en los cazas y del yaw/pitch en los B-17), así que no espero divergencia | log «ang_avance» |
| O4 rotores / sin duplicados | PASS. B-17: 4 rotores; cazas: 1 cada uno. No hay Body/Wings procedurales; la coincidencia «Nacelle» es un nodo del propio GLB (comprobado). `bomber_details.gd` sigue añadiendo ametralladoras, torreta de barbilla y escapes procedurales (detalle, no duplicado; ver H-15) | 03, 04 |
| O5 humo indexado | PASS. engines[i] ↔ Rotor_0, Rotor_2, Rotor_3, Rotor_1 (x ascendente). Emisor a dx=0,00 m del rotor de su índice, z −5,87/−6,07 (detrás del rotor). Posición derivada de los nodos (`EngineAnchors`). Con solo el motor 1 dañado (forzado en el harness), sale una única estela desde la góndola interior izquierda | 17_h_humo_motor1 (1280), 19_h_humo_motor1 (1920), log «medida humo» |
| O6 giro/congelado | PASS. En vuelo, los rotores avanzan; el código fija 31 rad/s en el B-17 y 40 en los cazas, y lo medido es Δ≠0. Con COMPLETADA y en pausa, Δ=0,0000 rad en 60 frames (B-17 y cazas) | log «giro_b17» activo/final/pausa |
| O7 textura | PASS (inspección). El B-17 es plateado con atlas, y los Bf 109 (morro amarillo, camuflaje) y Fw 190 (moteado gris) son reconocibles. No vi relleno gris del atlas en la silueta | 03, 07, 08 |
| O8 formación | PASS en 6 aviones (6 con Engines; 02_h_formacion_6). Separación mínima entre AABB 9,46 m (>2). Cámara a 117 m (>25). **Parcial:** en persecución se ven 2 compañeros completos y otros 2 cortados en las esquinas, detrás de los paneles del HUD (igual que en el baseline) → S3 de encuadre (H-16) | 01, 06, 02_h |

H-03 (Ø de la hélice del B-17 2,59 m, −27 %) sigue igual: S3 cosmético, no bloquea V1 local (por orden del supervisor).

## Fuera de alcance de este dictamen
Si cambian game.gd, aircraft.gd, fighter.gd, formation.gd, engine_anchors.gd o los GLB (por ejemplo, con U01/U02), esta aceptación sigue valiendo solo para los hashes de arriba. Para un cambio que no toque esos archivos basta repetir `capture_mission_claude.gd` (≈15 s por resolución).
