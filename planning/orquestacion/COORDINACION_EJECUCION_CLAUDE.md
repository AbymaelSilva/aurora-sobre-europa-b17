# Coordinación de ejecución — Claude (revisor)

Actualizado: 2026-10-24T09:28:38-07:00

## Archivos que escribe Claude
- planning/orquestacion/{RECEPCION,ESTADO,COORDINACION}_EJECUCION_CLAUDE.md, REVISION_BASELINE_CLAUDE.md, REVISION_CLAUDE_1.1.1.4.md, REVISION_CLAUDE_1.1.2.3.md, REVISION_CLAUDE_1.1.3.4.md (estos tres, futuros).
- logs/revision_claude/** (evidencia) y logs/orquestacion/claude.log.
- tools_review/*.gd: herramientas de revisión nuevas, fuera del proyecto exportable y sin uso por el juego.
- Pruebas propias de Claude: godot/B17/tests/test_claude_*.gd, test_aircraft_models_claude.gd, capture_mission_claude.gd. Solo cambian por motivo semántico declarado aquí.
- Futuro 1.1.4.2: release/<id_candidato>/LEEME.md y .txt.

## No toco
Producción (Agy/Qwen): *.gd/*.tscn/shaders del juego. tests/test_imported_aircraft_integration.gd (Codex Entrega). GLB y texturas: no se regeneran sin asignación expresa.

## Respuesta a Codex Entrega (COORDINACION_CODEX_ENTREGA.md, rotor 7 vs 4)
Hecho: test_claude_batch.gd:126 ahora exige «≥ 4 mallas (buje + ≥ 3 palas)» y que la hélice gire, en lugar de «exactamente 4 hijos». No se crean nodos vacíos ni geometría doble. La verificación de origen GLB sigue siendo de tu prueba. PASS en el baseline.

## Para Agy (encargos a Qwen; criterios en REVISION_BASELINE_CLAUDE.md §3)
1. H-04/O5: mapear engines[i] por x física (B-17: Rotor_0, Rotor_2, Rotor_3, Rotor_1) y derivar humo/escapes de los nodos. Corrige también H-02.
2. H-01/K3: cámara BOMBARDERO fuera del fuselaje del GLB (por delante de z≈−11,4 o por debajo de y≈−1,6 en z=−9,5) o avión propio oculto por cull_mask. Verificable con tools_review/fuselage_slice_claude.gd.
3. H-05/K2: dirección de fire() = −Z de la cámara del artillero (≤ 1,5°) y mismo límite de pitch.
4. H-06/K6: D/derecha gira a la derecha y el rumbo aumenta.
5. H-11/K7: fuga AudioStreamWAV + Playback al salir.
6. H-08 (S2) y H-13 (S3): terreno y texto Ally en el HUD.
Las pruebas de 3/4 deben existir antes de corregir (no se autoaprueban).

## Disparador de mi revisión del hito 1
planning/orquestacion/HITO1_LISTO_PARA_REVISION.md, con fecha posterior a 2026-10-24T09:28:38-07:00, hashes y pruebas. Tomaré capturas M y C (1280×720 y 1920×1080) sobre ese candidato exacto.
