# Verificación del supervisor (Claude) — U01/U02 (2026-10-24T11:27:44-07:00)
Hashes estables antes y después de todas las ejecuciones (logs/orquestacion/u01-u02-supervisor/h_before).
| Prueba | Dueño | Resultado |
|---|---|---|
| test_local_bombing_usability (independiente) | Codex | PASS rc0, 0 warnings: 9 casos guiados por HUD aciertan; sin falso positivo fuera de eje ni con el objetivo superado; 6 transiciones neutralizan y vuelven a leer el teclado |
| test_local_control_directions (H05/H06) | Codex | PASS rc0 |
| test_player_controls | — | PASS rc0 |
| test_manual_mission_claude | Claude | PASS rc0 |
| test_neutral_station_inputs / test_bombing_aid | Agy | PASS rc0 |
Revisión de código: bombing_aid.gd replica la física de bomb_model (mismo origen y velocidad, g=9.81, sin resistencia); la ventana de 55 m cae dentro del radio de impacto de 120 m. El signo de desvío lateral coincide con el texto de giro en mission_overlay. Se quitó el texto sobre Ally X.
Pendiente: dictamen visual con GPU de la nueva franja HUD (1.1.2.3 REVALIDAR_UI_U01); nuevo candidato y manifiesto (el release local-20261024-acd6e3ddfc40 queda superado); ENTREGA_U01_U02_AGY.md de Agy.

## Dictamen visual GPU (2026-10-24T11:28:32-07:00) — 1280×720, RTX 2060 SUPER
Capturas: logs/revision_claude/20261024T182757Z-u01-hud/ (18 PNG, misión COMPLETADA 785 s).
- 13_puesto_bombardero: franja «VENTANA DE SUELTA EN T-89.4s · Guía balística · ALINEADO», legible, no tapa el retículo. ACEPTADO.
- 15_bomba_cayendo: «BOMBAS FUERA · OBSERVANDO IMPACTO». ACEPTADO.
- 01_inicio: la intro ya no menciona Ally X; los controles aparecen como teclado/ratón. ACEPTADO.
- S3 (no bloquea): el panel de radio («Bombardero: preparados para la suelta.») se superpone a la parte inferior del círculo y la escala vertical del Norden. Se propone subir el panel de radio en la vista BOMBARDERO o moverlo arriba.
- No verificado en imagen: el estado verde «SUELTA AHORA», porque el harness de capturas suelta en autopiloto. Lo cubre la prueba lógica independiente (9/9).
Resultado: 1.1.2.3 revalidado tras U01, con una observación S3.
