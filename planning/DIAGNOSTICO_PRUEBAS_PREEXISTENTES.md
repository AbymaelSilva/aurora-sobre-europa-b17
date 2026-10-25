# Diagnóstico de pruebas no verdes — ajenas a las mejoras de menús/opciones

Al implementar BAJO+MEDIO+ALTO de `PRIORIZACION_COMPLEJIDAD_MENUS_OPCIONES.md`, el barrido completo de `godot/B17/tests/` (56 archivos) deja 50 PASS, 4 FAIL y 2 sin aserción/timeout por diseño. Este documento dictamina cada uno con causa raíz y evidencia, para no dejarlo como una afirmación suelta.

**Método de verificación:** `git stash` revierte todo el trabajo de esta tanda al commit base (`ef377c3`, antes de tocar un solo archivo de menús/opciones), se corre la prueba sola, se compara contra el resultado con los cambios aplicados, y se hace `git stash pop`. Si el resultado es idéntico en ambos casos, la causa es ajena a este trabajo.

## FAIL — ajenos, confirmados por `git stash`

1. **`test_claude_batch`** — falla en `check(ai.side == 1.0, "caza: lado 0 → +1")` (línea 69). La prueba llama `ai.setup(pos, 0.0)` (pasa `attack_side=0.0` explícito) y espera que `core/fighter_ai.gd` trate `0.0` como un valor centinela que debe convertirse en `+1.0`. El `setup()` actual simplemente asigna `side = attack_side` sin ese caso especial — y en el juego real `combat_manager.gd` nunca pasa `0.0` (siempre `-1.0` o `1.0`). Es un desajuste entre una prueba vieja y el contrato actual de `fighter_ai.gd`, no un bug de combate real. No se tocó `core/fighter_ai.gd` en este trabajo.
2. **`test_local_bombing_usability`** — reporta que varias combinaciones de altitud/velocidad no ofrecen una ventana de suelta manual alcanzable con la ayuda de bombardeo actual (`core/bombing_aid.gd`). Es un problema de balance de la ayuda de puntería, no de menús/opciones; no se tocó `core/bombing_aid.gd`.
3. **`test_qwen_assets`** — falla en `fail("flak does not expire")`, sobre el ciclo de vida visual de `visuals/flak_burst.gd`. No se tocó ese archivo.
4. **`test_manual_mission_claude`** — simula una partida completa jugada "a mano" (eventos de teclado sintéticos en tiempo real simulado) hasta `COMPLETADA`; cuelga más allá de 120 s tanto con los cambios como sin ellos. No es un bug introducido aquí; es una prueba de recorrido completo ya lenta/bloqueada antes de este trabajo.

## Sin aserción o timeout — por diseño o por naturaleza externa, no son regresiones

5. **`test_audio_leak`** — su código (24 líneas) no tiene ninguna sentencia `print`/`check`/`fail`: corre 60 pasos de física, libera los reproductores de audio y sale con código 0. Su único criterio de éxito es "no se cuelga ni truena"; cumplido (confirmado con el log completo, exit=0, sin líneas de ERROR).
6. **`test_claude_review`** — cuelga más allá de 90 s tanto en el commit base como con los cambios aplicados (confirmado con `git stash`). Por el nombre y su falta de relación con `game.gd`/`ui/`, depende de un servicio externo (probablemente una llamada a un modelo) no disponible en este entorno, no de las mejoras de menús.

## Lo que sí se verificó con una corrida real (no solo getters/setters)

`tests/verify_mejoras_jugabilidad.gd` (no forma parte de la suite de regresión; se ejecuta a pedido) simula una misión real completa hasta la fase de bombardeo, con la misma semilla de aleatoriedad (`seed(1945)`) para aislar la variable bajo prueba:

```
OK remapeo: tecla original (3) ya no activa Bombardero tras remapear
OK remapeo: tecla nueva (9) activa Bombardero en la partida real
FACIL   -> hull=94.89 flak_damage=0.770 max_attackers=6 bursts=4 fase=APROXIMACION
DIFICIL -> hull=92.75 flak_damage=1.485 max_attackers=10 bursts=4 fase=APROXIMACION
OK dificultad: DIFICIL deja mas daño real de casco que FACIL con la misma secuencia de flak
```

- **Remapeo:** se envía un evento de teclado real a `scene._unhandled_input()` (el mismo camino que usa el juego corriendo). La tecla original deja de cambiar de puesto tras remapear; la tecla nueva sí lo hace.
- **Dificultad:** con la *misma* secuencia de ráfagas de flak (4 ráfagas en ambos casos, mismo seed), DIFICIL deja más daño real de casco que FACIL (94.89% → 92.75%), no solo un multiplicador aislado sin efecto medible.
