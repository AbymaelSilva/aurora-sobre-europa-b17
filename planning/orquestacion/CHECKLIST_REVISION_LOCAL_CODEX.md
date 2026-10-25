# Revisión independiente pendiente — V1 LOCAL

## Estado confirmado por inspección, sin nueva ejecución
2026-10-24 09:31, hora local consultada. `aircraft.gd` ya instancia el recurso B17 mediante una propiedad `model` y un `EnginesNode` que gira los rotores reales. Es una entrega parcial, no el cierre del hito. El resultado de Qwen `logs/agy-qwen/20261024T163018/result.json` dice `accepted_for_review` y solo acredita su test específico.

La salida independiente que ejecutó Agy tras esa entrega contiene25fallos:16comparaciones de posiciónx de humo(4índices×4casos),4seguimientos de transformada del modelo y5requisitos de cazas. **No contiene fallos de pausa/animación de rotores**, aunque esa parte sigue pendiente de regresión final en el candidato completo. No atribuir los25fallos a pausa ni llamarlos25defectos distintos.

El cambio de Claude en `test_claude_batch.gd` ahora cuenta `MeshInstance3D` descendientes del rotor(≥4) y mantiene comprobación de giro. La justificación semántica está en COORDINACION_EJECUCION_CLAUDE.md. Nuestra prueba conserva una comprobación más específica: la referencia rotor debe ser el nodo real de la única instancia GLB activa. No necesita cambios por esa enmienda.

## Validez estática de la prueba independiente
- Busca instancias reales por `scene_file_path` y compara inventario de recursos de malla con el GLB original; el nuevo `aircraft.gd` mantiene esa condición.
- El controlador `EnginesNode` nuevo conserva el nombre y procesamiento que la prueba verifica; no se exige el nombre de su clase ni un archivo auxiliar específico.
- No fija7hijos de rotor ni depende del sufijo para ordenar salud. Ordena porx en coordenadas del avión.
- Usa anclajes reales y transformadas, no coordenadas históricas ±9.4/±4.4 ni nuevas constantes±7.73/±3.80.
- Observa giro real mediante frames, pausa y diferencia angular envuelta; no exige velocidad exacta o fase inicial de rotor.
- Permite geometría adicional declarada de `bomber_details.gd`; impide mallas procedurales duplicadas fuera del recurso. Decals y Label3D no se confunden con mallas duplicadas.
- Las pruebas de daño dirigido y perturbación de la transformada del modelo se limitan a la escena de test y se restablecen; no modifican los GLB ni producción.
- Verifica ambos cazas instanciados y su visibilidad/posición al avanzar hasta la primera oleada real; no acepta recursos sin uso en slots ocultos.
- **No observé un defecto de la prueba que justifique tocarla ahora.** Si una implementación legítima cambia el contrato y provoca un falso positivo, se presentará evidencia al supervisor antes de editarla. El test permanece sin cambios.

## Puerta de entrada al dictamen final
- [ ] Existe `HITO1_LISTO_PARA_REVISION.md`, emitido por Agy sobre el candidato actual.
- [ ] Enumera archivos cambiados, modelo B17/cazas, pruebas, hashes, límites y solicitudes visuales de Claude.
- [ ] Agy/Qwen han terminado de escribir esos archivos y coordinado una ventana estable de revisión.
- [ ] Los hashes de producción/arte/pruebas se fijan antes de ejecutar y se comprueban después. Un cambio durante revisión invalida el dictamen sobre el conjunto anterior.

## Comprobación de hito1
- [ ] Una única instancia texturizada B17 en jugador y cada uno de5compañeros; seis bombarderos en total.
- [ ] Cuatro rotores reales por bombardero, sin geometría procedural duplicada; `Engines` controla pausa y reanudación.
- [ ] Índices de daño0..3 corresponden de izquierda a derecha a los motores físicos. Humo acompaña al motor dañado tras cabeceo/guiñada y cambios del modelo.
- [ ] BF109yFW190 importados usados en combate; cada caza tiene referencia al rotor correcto, sin doble geometría.
- [ ] Nueva prueba independiente pasa sin errores de parseo/runtime. Guardar salida completa y código de retorno; investigar advertencias, no ocultarlas.
- [ ] Pruebas pertinentes existentes de recursos, formación y escena pasan en el mismo candidato. Las actualizaciones semánticas de tests están atribuidas y justificadas.
- [ ] Claude acepta las capturas del candidato exacto y registra cámaras/miras, superficies/materiales y visibilidad. No sustituir esta revisión visual por un PASS headless.

## Cierre LOCAL posterior, aún no disponible
- [ ] H-01/H-05/H-06: cámara de bombardero, dirección de fuego y giro/rumbo corregidos y revisados mediante reproducciones concretas de Claude.
- [ ] Misión manual sintética completa, combate, bombardeo, regreso, derrota, pausa y reinicio en candidato final. Documentar que entradas sintéticas no son una sesión humana.
- [ ] Arranque con GPU RTX2060SUPER en esta Linux y métricas locales identificadas; no exigir Windows/Ally ni prometer FPS externos.
- [ ] Instrucciones teclado/ratón redactadas por Claude para el lanzador/candidato reales.
- [ ] Manifiesto y respaldo local restaurables; etiqueta `CANDIDATO_LOCAL` hasta aceptación del supervisor.

## Cadencia
Esperar al marcador; no reejecutar suites cada vez que cambia un archivo parcial. Esta preparación no aprueba el hito ni dispara exportaciones. Un solo ciclo de revisión del conjunto estable, seguido de diagnósticos específicos si falla.
