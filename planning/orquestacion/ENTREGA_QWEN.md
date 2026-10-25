# Contrato técnico Qwen — borrador para revisión
Respuesta estructurada del modelo local; no acredita ejecución ni aprobación.

## 1.1.1.1
- **archivos:** assets/aircraft/models/b17g.glb
- **interfaz_conservar:** Engines, 4Rotor_*
- **dependencia:** GLB importado
- **aceptacion:** escala 31.62m±3%, morro-Z, tests/test_aircraft_models_claude.gd y test_claude_review.gd

## 1.1.1.2
- **archivos:** formation.gd
- **interfaz_conservar:** wingmen, left, right, slots
- **dependencia:** 1.1.1.1
- **aceptacion:** 5 compañeros + líder, pausa/reset, test_formation_six.gd

## 1.1.1.3
- **archivos:** visuals/fighter.gd
- **interfaz_conservar:** rotor:Node3D, contratos IA
- **dependencia:** modelos importados
- **aceptacion:** 1 rotor por caza, escala 9.92/10.51m±3%, tests/test_claude_batch.gd y test_aircraft_models_claude.gd

## 1.1.2.4
- **archivos:** visuals/flak_burst.gd, visuals/tracer_pool.gd, audio/combat_sfx.gd
- **interfaz_conservar:** trigger/advance/reset, fire/advance/reset
- **dependencia:** revisión cámaras y combate
- **aceptacion:** efectos limitados, pausa/reset, tests/test_qwen_assets.gd, test_combat_sfx.gd, test_release_acceptance.gd

## 1.1.3.4
- **archivos:** Según hallazgosClaude
- **interfaz_conservar:** interfaces afectadas
- **dependencia:** reporteClaude
- **aceptacion:** captura antes/después mismo escenario y regresión pertinente, cierre por revisor

## 1.1.4.4
- **archivos:** core/player_controls.gd, ui/mission_overlay.gd, project.godot
- **interfaz_conservar:** mapeos/zonamuerta, legibilidad y modo manual/demo
- **dependencia:** medición Windows/Ally real
- **aceptacion:** registrar FPS, frametime, memoria, resolución, preset, modo energía y repetir caso en destino; no afirmar Ally probado

## 1.1.5.1
- **archivos:** Según reporte destino
- **interfaz_conservar:** controles y misión
- **dependencia:** hallazgos reales 1.1.4.3
- **aceptacion:** reproducción previa, parche atribuido Qwen, prueba regresión y repetición en dispositivo afectado. Sin N/A; deja bloqueo por hardware explícito
