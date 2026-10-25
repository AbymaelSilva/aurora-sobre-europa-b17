# Dictamen del supervisor — cierre de contratos de planificación

## Resultado
Se aceptan los cuatro contratos documentales con las enmiendas y decisiones siguientes. Esto cierra la preparación del plan, NO los20puntos de implementación ni el juego. La fase sigue siendo PLANIFICACIÓN: sin código, pruebas nuevas, arte, instalaciones, exportaciones ni publicación.

## Entregas revisadas
- Codex Entrega: ENTREGA_CODEX_ENTREGA.md. Aceptado. El build previo es anterior a los modelos; no acredita integración nueva ni ejecución Windows/Ally.
- Agy: ENTREGA_AGY.md + ENMIENDA_AGY.md. Aceptados juntos. La enmienda sustituye las formulaciones originales sobre alcance, anclajes, rendimiento, hashes, memoria y bloqueo de inferencia.
- Qwen: ENTREGA_QWEN.md + ENMIENDA_QWEN.md/json. Aceptados juntos. Las revisiones1y2 fueron devueltas; su afirmación de aprobación autoatribuida es inválida. Solo este dictamen acredita aceptación del plan.
- Claude: ENTREGA_CLAUDE.md. Aceptado como contrato de revisión, con las aclaraciones siguientes. Sus hallazgos son hipótesis/observaciones estáticas a reproducir, no nuevos tests ejecutados.
- Revisión cruzada: REVISION_CODEX_PLANES.md. Los6hallazgos se resuelven documentalmente mediante enmienda Agy y enmienda Qwen; ningún cambio del juego está autorizado por este cierre.

## Decisiones vinculantes de coordinación
1. Qwen es dueño futuro de aircraft.gd, formation.gd, visuals/fighter.gd y módulos de integración que se asignen por escrito. Los GLB/texturas existentes son entradas de solo lectura para Qwen; Claude conserva la titularidad del arte. Un nuevo archivo auxiliar debe declararse y asignarse antes de escribirlo.
2. El contrato Engines se mantiene sin geometría duplicada. Los índices de salud se mapean por posición física de los motores; no por sufijo Rotor_N. Humo/escapes derivan de nodos/transformadas del GLB. Las coordenadas estáticas del recurso constatadas por Codex son evidencia, no nuevas constantes de producción.
3. Alcance: misión que empieza en vuelo y termina en zona segura. Sin despegue/aterrizaje añadidos. Pruebas con entradas sintéticas no se anuncian como prueba de un jugador humano.
4. FPS/render y frecuencia física son verificaciones distintas. No se aprueba un compromiso60/120FPS ni perfiles de energía como especificación del dispositivo. Agy preparará matriz de ensayo con opciones disponibles y métricas; el objetivo final se decide con datos.
5. Un manifiesto vincula fuente/recursos congelados, motor, preset, pruebas y hashes de cada artefacto. Hashes de objetos distintos no deben ser iguales. En copia/restauración sí se compara cada archivo con su original.
6. La advertencia histórica de ObjectDB se investiga en el candidato futuro; no se declara resuelta por documentos previos. El bloqueo godot-art.lock serializa inferencias, no protege automáticamente archivos de otros agentes.
7. Se adoptan como objetivos de revisión local: conservación de Engines/rotor,6bombarderos, cámaras/retículas coherentes, ausencia de geometría propia que tape la mira y regresión de pausa/reset. Los umbrales nuevos de encuadre/textura/diámetro de Claude son propuestas de verificación; deben concretarse antes del encargo que las implemente. Las dimensiones históricas propuestas requieren su fuente si se convierten en requisito de fidelidad histórica.
8. Para medir animación de rotores se utilizarán incrementos angulares con tratamiento del envolvimiento de2π, no diferencia ingenua entre ángulos almacenados. No se implementa ninguna prueba ahora.
9. H-01/H-04/H-05/H-06 de Claude se priorizan para reproducción en el primer hito ejecutable; no se consideran corregidos. H-05/H-06 dependen de Agy/Qwen y condicionan revisión de cámaras. El supervisor puede diferir cosmética con razón; solo escala al usuario cambios materiales de alcance, presupuesto o preferencias.
10. Ruta futura de instrucciones: release/<id_candidato>/LEEME.md y LEEME.txt, Claude redacta y Codex Entrega empaqueta. No se crea paquete ahora. README obsoleto queda como hallazgo para ejecución documental posterior.
11. Windows/AllyX física: BLOQUEADO_DESTINO cuando falte acceso. La siguiente misión requiere elección del usuario. No confundir esos pendientes con tareas cerradas.
12. El supervisor conserva el hilo principal exclusivamente para supervisar. Las tareas de integración/corrección se delegan. Cada evento aceptado se imprime por logs/orquestacion/supervisor.log en la consola de seguimiento.

## Tiempos y evidencia
Las horas de algunos agentes no tienen reloj verificado. Claude reportó una hora aproximada futura respecto a la observada; no se usa para el orden de aceptación. La hora de recepción/aceptación registrada por el supervisor con reloj local es la referencia. En adelante, un agente sin reloj informa hora no verificada y no inventa marcas temporales.

## Siguiente hito definido, no activado
Integración texturizada del B17 del jugador, con preservación de Engines, mapeo de motores y cámaras. Dueño Qwen; Agy coordina y prueba; Claude revisa visual; Codex Entrega revisa contrato y trazabilidad; hilo principal supervisa. Las condiciones de comienzo siguen la fase que indique el usuario.
