# Recepción de la orquestación — Claude

**Fecha:** 2026-10-24, 03:07 (hora local)
**Objetivo fijado por el usuario:** "continuar el trabajo de Codex hasta terminar la primera misión del juego".
**Motor definitivo:** Godot 4.7.2 (`tools/godot`). Unity cancelado; sus archivos se conservan solo como referencia.

## Lo que comprobé yo mismo (ejecutado, no solo leído)
- **8/8 pruebas existentes pasan:** `test_visuals`, `test_scene_mission` (misión completa en la escena real: 783,32 s, 60 ráfagas, casco al 56 %), `test_long_mission` (30/60/120 pasos/s), las 4 de Agy y `test_qwen_assets`.
- **`core/simulation.gd.reset()` ya reinicia `damage` y `mission`.** El defecto que señalaba el relevo está corregido.
- `game.gd` ya integra el núcleo largo, el flak, la bomba, el impacto, la radio, la sesión de resultados (debrief), el sonido del motor y el marcador de navegación.
- Qwen: Ollama en 127.0.0.1:11435, 4,75 GB de VRAM, entero en la GPU, contexto de 4096 (`/api/ps`, 03:06).
- Lote de 10 encargos de Claude a Qwen: 6 superan las pruebas de comportamiento escritas por Claude y 3 están en segunda ronda (ver AVANCE_CLAUDE.md).

## Definición de "primera misión terminada" (criterios observables)
1. **Jugable:** el jugador puede alternar entre piloto, artillero y bombardero. Los puestos que no ocupa siguen funcionando con automatismos. Teclado y ratón, y mando.
2. **Amenazas:** cazas que hacen pasadas de ataque, causan daño, se pueden derribar con la torreta y dejan trazadoras visibles; flak en la zona del objetivo.
3. **Bombardeo:** con la mira, el jugador decide la suelta; si no ocupa el puesto, lo hace el automatismo. Acierto o fallo según el impacto real.
4. **Formación** de 6 bombarderos con los detalles del B-17.
5. **Escenario:** terreno con textura, el objetivo ferroviario reconocible, el río, nubes, cielo y luz.
6. **Audio:** motores, ametralladoras, flak, explosiones y radio.
7. **Flujo:** menú y sesión informativa (briefing) → misión → sesión de resultados (debrief) → reintentar o salir. Pausa.
8. **Pruebas:** misión completa sin intervención, victoria y derrota, y reinicio a 30/60/120 Hz; capturas reales revisadas.
9. **Exportación a Windows** que arranca. La validación en la Ally X queda para cuando el usuario tenga el dispositivo.

## Primera tarea
Integrar el escenario y los detalles ya validados del lote Qwen en `game.gd` y comprobarlo con una captura con GPU. Después, los cazas, las trazadoras y la torreta (punto 2).

## Bloqueos reales
1. **[ACTUALIZADO 03:49]** Codex pasó el relevo a **Agy** (`AGY_HANDOFF_READY`), que es el dueño de `game.gd` y `ui/mission_overlay.gd` (ver COORDINACION_AGY.md). **Retiro mi reserva sobre esos archivos.** Claude pasa a verificar de forma independiente (pruebas, capturas reales, flujo de la misión) y a dejar los hallazgos en `planning/PARA_AGY.md`. También sigo con el arte de los aviones (OpenArt/Meshy).
2. **No se puede probar en la Ally X** sin el dispositivo.
3. **Meshy** depende de Codex (clave no persistente). Las referencias están en PARA_CODEX_MESHY.md.
