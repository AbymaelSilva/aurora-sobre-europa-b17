# Revisión de infraestructura de supervisión

Autor: agente `supervision_runtime`. Alcance exclusivo: `agy_coordinador.py`, `encargar_qwen.py` y prueba offline de infraestructura. No se modificaron producción Godot, recursos, pruebas del juego, prompts activos ni permisos. No hubo llamadas a LLM ni ejecución real de Godot. No se detuvieron/reiniciaron procesos.

## Respaldo
`snapshots/orchestration-runtime-20261024T104904/` conserva ambos scripts originales.

## Cambios preparados

### Supervisor Agy
- Lee explícitamente el checkpoint `planning/orquestacion/AGY_AVANCE.md` y solicita continuar desde el primer pendiente, sin repetir entregas idénticas. No reemplaza el prompt que ya corrigió el supervisor principal.
- Distingue código modificado y nueva evidencia QA; excluye logs de charla/recibos y deduplica entregas Qwen por archivo/hash. Repetir idéntico archivo aceptado no acredita progreso nuevo.
- Soporta estado explícito `awaiting_review`/`waiting_review`: detiene la ronda como espera de revisión, sin declarar bloqueo ni juego completo. Dos rondas realmente estancadas producen `needs_supervisor_attention` para que el principal corrija la secuencia, sin seguir gastando llamadas.
- Heartbeat cada30s durante la ejecución del agente; preserva id de conversación, PID, archivo de meta y último tool en el estado. Heartbeat significa proceso observado, no progreso aceptado.
- Publica eventos operativos en `logs/orquestacion/runtime.log`: inicio/final de ronda, bloqueo, espera de revisión y necesidad de supervisor. Son eventos de infraestructura, no cierres de puntos del juego.
- La verificación de candidato añade tests independientes de integración GLB, dirección de controles y misión manual sintética. Rechaza warnings `ObjectDB instances were leaked`, timeouts, fuentes cambiadas durante la verificación y acta de aceptación anterior a la ronda. Conserva PASS/FAIL reales; no modifica pruebas.
- Cierra descriptores de lock y stdout al terminar, evitando recursos abiertos detectados en la validación offline.

### Puente Qwen
- Registra inicio, entrega para revisión, devolución tras tres intentos y bloqueo en el log `qwen.log` que YA sigue la consola central. Nunca escribe COMPLETADO_VERIFICADO.
- Carpetas de petición únicas incluso en el mismo segundo; elimina riesgo de mezclar respuestas/originales/resultados entre invocaciones.
- Conserva/restaura versión previa ante fallo. Un fallo de red queda registrado como bloqueo con resultado propio, sin guardar el original como si fuera un candidato del modelo.
- Lock se libera explícitamente al salir también por excepción. Se mantiene la única inferencia compartida.

## Validación realizada
Comando: `python3 -W error::ResourceWarning tests/test_orchestration_runtime.py`.
Resultado: **9 tests offline PASS**, sin ResourceWarning. Evidencia: `logs/orquestacion/runtime-offline-tests.log`.

Escenarios: rechazo funcional con proceso0 restaura original y nunca publica entrega; éxito solo entrega para revisión; invocaciones del mismo segundo separadas; fallo de red sin candidato ficticio; evidencia QA frente a charla/duplicados; espera de revisión vs estancamiento; rechazo de leaks con PASS aparente; fuentes cambiadas/acta caducada; agente ficticio con estado/metadatos correctos; lock impide segunda instancia. Los escenarios comparten9métodos de unittest. API y motor están sustituidos por stubs; el único subproceso real es un Python temporal que emite eventos ficticios.

Sintaxis: `python3 -m py_compile agy_coordinador.py encargar_qwen.py tests/test_orchestration_runtime.py` PASS.

## Aplicación y coordinación
- **El supervisor Agy que ya está vivo continúa con su código cargado anterior.** Los cambios de `agy_coordinador.py` se aplican al PRÓXIMO ARRANQUE del supervisor, no automáticamente en su próxima ronda. No reiniciar un encargo de Qwen en curso para aplicarlos; esperar checkpoint/fin seguro y decidir desde el hilo principal.
- El puente se ejecuta como proceso nuevo por encargo: sus cambios se aplican en la siguiente invocación de `encargar_qwen.py`; un proceso de puente ya lanzado conserva la versión cargada.
- La consola ya sigue `qwen.log`, por lo que verá las entregas del puente. Para ver también eventos de infraestructura, añadir `logs/orquestacion/runtime.log` al monitor cuando se reconfigure; no se tocó la consola activa.
- El cierre sigue siendo del supervisor principal con evidencia visual/funcional y entrega local; la infraestructura no declara el producto terminado.
