# Revisión independiente incremental — H05/H06

- Hora real: 2026-10-24T10:56:35.023286-07:00.
- Alcance: esta Linux, prueba semántica headless de direcciones; no revisión visual ni aceptación del hito completo.
- Prueba exclusiva de Codex Entrega: `tests/test_local_control_directions.gd`, sin cambios desde su baseline negativa.
- Ejecución: UNA repetición incremental autorizada tras cambios de producción. Los hashes se observaron estables antes de iniciar y coinciden antes/después de ejecutar. No se repitió la suite completa ni se empaquetó.

## Resultado
**PASS, código0**, sin errores de parseo/runtime ni advertencias ObjectDB en esta ejecución.

H06: ocho casos de teclado sintético(D/A/RIGHT/LEFT, yaw inicial0y0.8). D/RIGHT ahora desplazan112.10m hacia la derecha y aumentan rumbo54° en3s; A/LEFT muestran−112.10m y−54°. El movimiento, orientación del morro y brújula son coherentes con el lado solicitado.

H05:60combinaciones de yaw/aim/pitch incluyendo límites. Desviación máxima entre dirección del disparo manual y eje−Z de la cámara:0.000°, frente al criterio≤1.5°. La prueba lee la trazadora defensiva que `fire()` añadió, no reconstruye su resultado con una fórmula esperada compartida.

Los eventos de entrada son sintéticos. No representan una sesión humana ni demuestran por sí solos que el artillero puede ver todos los enemigos o que el plano de mira esté libre de geometría propia.

## Evidencia y candidato observado
- `logs/orquestacion/local-control-directions-review-20261024T105635.log`
- `.json` contiguo con hashes antes/después, código de retorno, validez de revisión y presencia/ausencia de advertencias.
- `core/player_controls.gd`: `382eac7150ccacaca01625cf2da66fee86459e26689da7ca297c25be470d3d1e`.
- `game.gd`: `5d801e8833d56550bbb391d598e0e201f035a6c8026e7551b7c80fd110907e00`.
- `core/flight.gd`: `f39deb3fe239d73bd7ab5fad7ffd1db3c20b5679a700ad2439f3a5f0247a7494`.

## Límite y siguiente dependencia
Este dictamen acredita H05/H06 únicamente sobre esos archivos/hash y la prueba descrita. No cierra hito1, revisión de cámaras, misión completa ni candidato local. Un cambio posterior en las rutas críticas requiere revisar qué evidencia sigue siendo aplicable.

Solicito al supervisor `HITO1_LISTO_PARA_REVISION.md` con manifiesto estable y ventana sin escritura para la revisión final de modelos/cámaras. La entrega/respaldo LOCAL seguirá al cierre de esas dependencias; no hace falta exportador ni plantilla si fuente+motor+lanzador reproducibles bastan aquí.
