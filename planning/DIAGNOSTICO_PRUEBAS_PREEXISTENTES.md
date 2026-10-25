# Diagnóstico de pruebas no verdes — ajenas a las mejoras de menús/opciones

Al implementar BAJO+MEDIO+ALTO de `PRIORIZACION_COMPLEJIDAD_MENUS_OPCIONES.md`, el barrido completo de `godot/B17/tests/` (56 archivos) dejó inicialmente 50 PASS, 4 FAIL y 2 sin aserción/timeout. Tras investigar causa raíz de cada uno: **2 de las 4 fallas se corrigieron** (arreglos aislados y verificados, sin tocar combate/vuelo real); **2 comparten una causa raíz de diseño ya identificada con precisión**, no un bug trivial; los 2 restantes se confirmaron como no-regresiones por diseño o por dependencia externa.

**Método de verificación:** `git stash` revierte todo el trabajo de esta tanda al commit base (`ef377c3`, antes de tocar un solo archivo de menús/opciones), se corre la prueba sola, se compara contra el resultado con los cambios aplicados, y se hace `git stash pop`. Si el resultado es idéntico en ambos casos, la causa es ajena a este trabajo.

## Corregidas (ya no fallan)

1. **`test_claude_batch`** — FIJO. Fallaba en `check(ai.side == 1.0, "caza: lado 0 → +1")`: la prueba llama `ai.setup(pos, 0.0)` esperando que `core/fighter_ai.gd` trate `0.0` como centinela de `+1.0`; el `setup()` no tenía ese caso. Se agregó `side = attack_side if attack_side != 0.0 else 1.0` en `core/fighter_ai.gd`. El juego real (`combat_manager.gd`) nunca pasa `0.0` (siempre `-1.0`/`1.0`), así que no cambia nada del combate real — verificado con `test_combat_manager`, `test_escort_combat` y `test_formation_six` en verde tras el cambio.
2. **`test_qwen_assets`** — FIJO. Fallaba en `fail("flak does not expire")`: la prueba disparaba una bocanada de flak sin duración explícita (usa el valor por defecto de 10 s en `visuals/flak_burst.gd`, que coincide con el rango real de producción de 8-12 s en `visuals/flak_field.gd`) y solo avanzaba 4 s — nunca iba a expirar. Se corrigió la prueba para avanzar 12.5 s (más allá del máximo real), sin tocar el código del juego.

## Causa raíz compartida, identificada con precisión — requiere una decisión de diseño, no un parche

3. **`test_local_bombing_usability`** y 4. **`test_manual_mission_claude`** fallan por la misma razón de diseño, confirmada con trazas reales:

   - Al cambiar al puesto **Bombardero**, `core/player_controls.gd` bloquea toda entrada de vuelo (`else: apply_flight_input(sim, 0.0, 0.0, 0.0)` cuando `station != "PILOTO"`) — es intencional: el bombardero no pilota a la vez.
   - Fuera de autopiloto, **nada corrige el rumbo** durante la pasada de bombardeo una vez el jugador/piloto sintético entra a Bombardero: cualquier deriva lateral que ya existiera (por ejemplo `turn_bias` por daño asimétrico de motor de un impacto de flak previo) queda congelada el resto de la pasada.
   - Con trazas reales (`alt=1000 speed=85`), la distancia mínima alcanzada al blanco fue de 115 m — nunca entra en la ventana de 55 m que exige `core/bombing_aid.gd`, incluso con deriva lateral modesta (coherente con que velocidades más altas, con el mismo paso de física, recorren la ventana geométrica en menos fotogramas y no "aciertan a pasar" tan cerca del blanco al volar perfectamente recto).
   - `test_manual_mission_claude` (recorrido completo de 1500 s simulados, **no es un cuelgue**: termina en ~3-4 min de reloj real, confirmado con un timeout de 580 s) falla por la misma razón: nunca entra en los 40 m de distancia prevista de impacto que exige su propio umbral de suelta manual.
   - En el modo normal del juego (piloto automático activo, el modo por defecto) esto no ocurre: `core/simulation.gd` corrige rumbo hacia el objetivo de navegación de forma continua, incluso durante `BOMBARDEO`, y la suelta automática sí funciona (visible en las capturas de `capture_mission_claude.gd` y en las de esta tanda).
   - **Conclusión:** no es un bug de una línea; es que la suelta manual sin piloto automático es marginal/imposible en ciertas combinaciones de velocidad una vez que el puesto Bombardero bloquea la corrección de rumbo. Corregirlo bien implica una decisión de diseño (¿ensanchar la ventana de 55 m/40 m?, ¿permitir pequeñas correcciones de rumbo desde Bombardero?, ¿es intencional que la suelta 100% manual sea difícil?) que no me corresponde tomar unilateralmente tocando el modelo de vuelo o el bombardeo real. No se modificó `core/bombing_aid.gd`, `core/player_controls.gd` (más allá de lo ya descrito para las mejoras) ni `core/flight.gd`.

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
