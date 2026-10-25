# Avance de Claude

## 2026-10-24 — Arte (aviones y escenario) y lote de 10 encargos a Qwen

**Peticiones del usuario:** centrarse en los aviones y el escenario, no en el menú; "no dejes descansar a Qwen, dale 10 tareas".

### Lote Qwen de Claude (`claude_qwen_batch.py`, consola "B17 — QWEN 10 TAREAS (CLAUDE)")
- Registros: `logs/claude-qwen-batch/<fecha>/` y `logs/claude-qwen-batch.console.log`. Resultados en `results.json`.
- Usa el ejecutor existente `generate_godot_art.main` (3 intentos, comprobación de sintaxis). Comparte el bloqueo `godot-art.lock` con `qwen_ten_tasks.py` de Codex: se turnan y reintentan cada 20 s.
- **Archivos (todos nuevos, sin solaparse con el lote de Codex):** `world/ground_material.gd`, `world/target_ground.gd`, `world/cloud_sprites.gd`, `visuals/fighter.gd`, `core/fighter_ai.gd`, `core/formation_slots.gd`, `visuals/tracer_pool.gd`, `visuals/engine_smoke_trail.gd` (renombrado para no chocar con `visuals/engine_smoke.gd` de Codex), `world/river.gd`, `visuals/bomber_details.gd`.
- **Pruebas de comportamiento escritas por Claude antes de que Qwen entregue:** `godot/B17/tests/test_claude_batch.gd`. Se ejecutarán al terminar el lote: `tools/godot --headless --path godot/B17 --script res://tests/test_claude_batch.gd`.
- **Ninguno está integrado todavía en `game.gd`.** La integración la hace Codex o se coordina antes, porque Codex está modificando ese archivo.

### Recursos importados a `godot/B17/assets/` (origen en `assets/SOURCES.md`)
- `terrain/farmland_a.png` (A1), `terrain/rail_yard.png` (A3) y `sky/cloud_atlas.png` (ES3 con canal alfa generado). Importados con `--import` sin errores.

### Revisión del arte de OpenArt
| Pieza | Veredicto |
|---|---|
| A1 campos | Se usa; enlaza en mosaico; repetición interna 2×2 |
| A2 bosques y aldeas | Limitada: repetición 2×2 y costura que se nota un poco; variante que necesita corregir los bordes |
| A3 complejo ferroviario | **Muy buena**: textura del objetivo y plano para colocar los edificios en 3D |
| A4 aluminio | Rechazada como textura principal: rejilla repetida |
| A5 olive drab | Rechazada: rejilla artificial |
| AV1 B-17G 3/4 | **Muy buena** como entrada para Meshy image-to-3D (Codex): torretas, 4 motores y cola correctos. Archivo `art/openart/refs/AV1-b17g-34-ref.png` |
| ES3 atlas de nubes | **Muy buena**: 16 nubes distintas, ya con alfa |

### Siguiente
1. Ejecutar `test_claude_batch.gd` cuando Qwen termine. Devolverle los fallos con el diagnóstico literal (máximo 3 rondas).
2. Generar las referencias AV2 (caza enemigo) y ES4 (flipbooks de efectos) según `PRESUPUESTO_ARTE.md`.
3. Pasar AV1 a Codex para Meshy image-to-3D.

## 2026-10-24 03:15 — Lote Qwen cerrado y arte de aviones

### Lote Qwen: 10/10 superan las pruebas de comportamiento (`tests/test_claude_batch.gd`: TEST PASS)
- Ronda 1: 7/10 pasaron. Ronda 2 (`claude_qwen_retry.py`, diagnóstico literal): `target_ground` (const no constante), `tracer_pool` (generador de Python en GDScript) y `fighter` (`rotor` local y un `add_mesh` duplicado), todos corregidos **por Qwen**. Los archivos rechazados están en `logs/claude-qwen-batch/rejected/`.
- **Errores míos en la prueba, ya corregidos:** (1) en `_initialize` la raíz no está en el árbol y `_ready()` se aplaza (falso fallo en las nubes); (2) los scripts que no compilaban o los miembros que faltaban abortaban la función en silencio y daban un falso PASS; (3) esperaba 17 piezas en `bomber_details` cuando el contrato da 16.
- Autoría: los 10 archivos son 100 % de Qwen. Las pruebas son de Claude.

### Arte de aviones (objetivo del usuario)
- Referencias para Meshy: AV1 (3/4), AV1-side y AV1-top (B-17G), AV2 (Bf 109G), AV3 (Fw 190A), AV4 (P-51D). Están en `art/openart/refs/manifest.json`.
- `claude_meshy_aircraft.py`: image-to-3D y multi-image-to-3D con textura PBR, con parámetros comprobados en docs.meshy.ai. Las imágenes van en data URI (el CDN de OpenArt da 403 a urllib). Primero una prueba piloto con el Bf 109; si falla, no envía nada más. Prueba en seco superada. **Está esperando la clave del usuario en la consola "B17 — MESHY AVIONES 3D (CLAUDE)".**
- Arte 2D importado en `godot/B17/assets/`: 6 calcas, 9 daños, 2 miras y 9 puffs de flak (ver SOURCES.md).

## 2026-10-24 04:37 — Primera misión: verificación final de Claude
**Estado: primera misión jugable de principio a fin y verificada**, con las salvedades de abajo.
- Revisión en 2 iteraciones del candidato de Agy, con capturas reales con GPU (`tests/capture_mission_claude.gd`). Los hallazgos se convirtieron en `tests/test_claude_review.gd`: 6 en la ronda 3 y 6 más en la ronda 4. Agy los corrigió en el juego, **sin tocar la prueba** (comprobado por la fecha de modificación y su registro).
- `tests/test_manual_mission_claude.gd`: un "jugador" con **teclas reales** (TAB manual → A/D/W/S → 3 bombardero → Espacio/B suelta → 1 piloto → regreso) **completa la misión** (IMPACTO, COMPLETADA a 724 s, casco al 57 %). Primero se escribió mal (escribía las entradas directamente y `poll_inputs` las pisaba en PILOTO); se corrigió.
- **Suite completa: 16/16 TEST PASS.**
- Windows: `build/windows/AuroraSobreEuropa.exe` exportado a las 04:36 (155 MB). El paquete arranca con el Godot de Linux.

### Salvedades (no bloquean la misión, pero hay que decirlas)
- **No se ha ejecutado en Windows ni en la ROG Ally X** (no hay dispositivo ni Wine aquí). No se ha medido el rendimiento en la Ally X.
- **Aviones procedurales**: los modelos 3D de Meshy esperan la clave del usuario (objetivo de arte pendiente).
- Detalles visuales menores: la bomba con bandas naranjas se ve grande en primer plano durante la cámara de caída; el visor de artillero muestra en primer plano la cúpula y los cañones propios; aviso `2 ObjectDB instances were leaked at exit`.
- Audio sintético (procedural) en lugar de grabaciones.

## 2026-10-24 05:31 — Arte de los aviones completo (plan B sin Meshy)
La clave de Meshy no llegó en más de 2 h. Construí los modelos 3D con `tools_art/loft_aircraft.gd` a partir de vistas ortográficas de OpenArt (lateral y planta de cada avión).
- `godot/B17/assets/aircraft/models/`: **b17g.glb** (27k caras, 4 rotores), **bf109g.glb**, **fw190a.glb**, **p51d.glb** (~13,5k caras, 1 rotor). Texturizados con las propias vistas, a escala real, morro −Z. `tests/test_aircraft_models_claude.gd`: PASS.
- Iteraciones: (1) GLB vacío por no asignar `owner`; (2) aluminio confundido con el fondo → segmentación por relleno desde el borde; (3) cuerda en la raíz inflada por las góndolas → borde de ataque ajustado con el tramo exterior (raíz 5,8 m frente a ~5,86 m reales); (4) solo 2 góndolas → máximos locales (4 a ±3,8 y ±7,7 m); (5) franjas blancas en el borde de salida → normales de cara orientadas hacia fuera.
- Arte 2D ya existente: calcas, daños, miras y flak.
- **Pendiente para Agy:** integrarlos en `game.gd` (encargo en AGY_AVANCE.md). La terminal de Meshy sigue abierta: si el usuario introduce la clave, Meshy puede dar modelos más detallados para comparar.
- OpenArt: saldo 521.
