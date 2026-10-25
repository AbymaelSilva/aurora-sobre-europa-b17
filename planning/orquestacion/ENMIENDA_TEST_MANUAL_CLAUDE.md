# Enmienda de la prueba manual — `tests/test_manual_mission_claude.gd`

- Autor: Claude (autor de la prueba). Hora real: 2026-10-24T11:03-07:00. Ejecución local en esta Linux, Godot 4.7.2 headless.
- Alcance: SOLO la prueba manual de Claude. No se tocaron producción, pruebas de Codex ni el script de capturas.
- Es un **jugador sintético** (eventos de teclado generados por la prueba), no un jugador humano. Esto no es una aprobación del producto.

## Diagnóstico (matemática confirmada leyendo el código)
- `core/player_controls.gd:116`: `turn = A − D` (A → +1, D → −1).
- `core/flight.gd:16`: `yaw += turn · 18°/s`.
- Hacia delante en Godot = `−Basis.from_euler((pitch, yaw, 0)).z` = `(−sin yaw, ·, −cos yaw)`. Un yaw positivo gira −Z hacia −X (izquierda); por eso **D baja el yaw = derecha** y **A sube el yaw = izquierda**. Es correcto en Godot y coincide con la revisión H06 (D/RIGHT −> +112 m a la derecha).
- La prueba calcula `desired_yaw = atan2(−offset.x, −offset.z)` (inversa correcta de ese vector) y `err = desired_yaw − yaw`. Con `err > 0` hace falta **subir** el yaw, o sea pulsar **A**. El original mantenía **D** (supuesto previo a H06: "turn +1 sube el yaw con D"), así que giraba en sentido contrario. Llegaba a la pasada (IMPACTO, suelta manual) pero en REGRESO se alejaba del objetivo de navegación y se quedaba sin tiempo a los 1500 s.
- Conclusión: el fallo venía de la prueba, no del producto. No se cambió la física ni la dirección del producto.

## Cambios (antes → después)
1. Selector de teclas: `hold(KEY_D, err > 2°)` / `hold(KEY_A, err < −2°)` → `hold(KEY_A, err > 2°)` / `hold(KEY_D, err < −2°)`, con un comentario que explica la convención.
2. Criterio de PASS explícito: añadí `bomb.result == "IMPACTO"` y `damage.hull > 0` a los que ya había (COMPLETADA, suelta manual, giro por teclado en PILOTO, autopiloto desactivado). Así se endurece la prueba y no se relaja ningún criterio.
3. Limpieza antes de `quit` (`finish()`): suelta las teclas que siguen pulsadas mediante `Input.parse_input_event`, detiene los cuatro `AudioStreamPlayer` y pone `stream = null`, quita la referencia a `sim`/`controls`, hace `remove_child` + `free()` de la escena y espera 6 ciclos de proceso y física (el mismo patrón que `test_local_control_directions.gd` de Codex). Antes las 2 instancias de ObjectDB que se escapaban venían de salir con la escena todavía viva. No se ocultó ni se filtró ninguna advertencia: simplemente ya no aparece.
4. Comentario de cabecera: deja claro que es una prueba sintética.

Sin cambios: TAB real a través de `_unhandled_input`, las teclas de vuelo por `Input.parse_input_event`, el cambio de puesto (3 → BOMBARDERO, 1 → PILOTO), la suelta con SPACE/B, `dt` = 1/60, el límite de 60·1500 frames y el bucle `_physics_process` de la escena. La prueba no escribe posiciones, fases ni entradas de sim.
Diff completo: `logs/revision_claude/manual-fixture/enmienda.diff`. Original: `logs/revision_claude/manual-fixture/original.gd`.

## Ejecución (ronda 1 de 3 como máximo; no hizo falta otra)
Comando: `tools/godot --headless --path godot/B17 --script res://tests/test_manual_mission_claude.gd`. **Código de retorno 0**, 4.35 s.
Log literal (`logs/revision_claude/manual-fixture/run1-20261024T110308.log`):
```
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

giros_por_teclado=true fase=COMPLETADA bomba=IMPACTO suelta_manual=true t=724s casco=57 estacion=PILOTO
TEST PASS: misión completada por un jugador sintético en modo manual con suelta manual
```
Antes de la enmienda (final-local-qa): `fase=REGRESO bomba=IMPACTO suelta_manual=true t=1500s casco=57`, código 1, con 2 ObjectDB escapados.
Después: COMPLETADA en 724 s de misión, casco 57, sin advertencias.

## Hashes (SHA-256; producción idéntica antes y después de ejecutar)
- f03768e4a5d2bcddcbefbfa97e1ad37088fdd849a39bbbe043bdac729fcbf321  godot/B17/tests/test_manual_mission_claude.gd
- 382eac7150ccacaca01625cf2da66fee86459e26689da7ca297c25be470d3d1e  godot/B17/core/player_controls.gd
- f39deb3fe239d73bd7ab5fad7ffd1db3c20b5679a700ad2439f3a5f0247a7494  godot/B17/core/flight.gd
- 5d801e8833d56550bbb391d598e0e201f035a6c8026e7551b7c80fd110907e00  godot/B17/game.gd
- original.gd: 803a9236f110846bbc6bb085e8f2caeca4d49edd246ffe8947428d9f2eeeb3b7
- enmienda.diff: 2380616fac5d0ee3ddabd9fcaa729b270ff2944e9924873d4f46a2066d59e9db
- log run1: f5e5eee43e32d1893e8bf6a10eaadb04682cf40caa02ec08ecd16fb0acad0f8e

Los hashes de producción coinciden con los de la revisión H05/H06 (`REVISION_LOCAL_CONTROL_DIRECTIONS.md`).

## Límites
Solo demuestra que un controlador sintético sencillo (rumbo y altitud con un umbral de ±2°) puede completar la misión en manual usando los controles corregidos. No sustituye una sesión humana, ni la revisión visual o de cámaras, ni el cierre del hito. Si cambian las rutas críticas, hay que volver a ejecutarla.
