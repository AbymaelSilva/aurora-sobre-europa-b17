# Revisión de contratos — Codex Entrega

**Fase:** planificación. Inspección documental/estática únicamente; no se ejecutaron Godot, pruebas ni exportaciones, ni se modificaron entregas ajenas o código. Los hallazgos proponen enmiendas; el supervisor decide su aceptación.

## Dictamen

Los documentos ofrecen una base útil, pero necesitan corregir la propiedad del código de integración, los anclajes de motores y el alcance de la misión antes de aprobar los contratos afectados. El rendimiento y la trazabilidad del paquete requieren formulaciones precisas para evitar compromisos no acordados o criterios imposibles.

| ID | Hallazgo confirmado | Evidencia | Clasificación |
|---|---|---|---|
|CE-R1|Qwen1.1.1.1 enumera solo el GLB; omite el adaptador editable `aircraft.gd`.|ENTREGA_QWEN.md:4–8; aircraft.gd crea Body/Wings/Engines procedurales.|Bloqueante del contrato1.1.1.1.|
|CE-R2|AGY fija coordenadas antiguas para humo de motores.|ENTREGA_AGY.md:88; metadatos GLB actuales difieren.|Bloqueante de integración/aceptación1.1.2.2.|
|CE-R3|Se introduce despegue/aterrizaje fuera del cierre actual de misión.|ENTREGA_AGY.md:94,113; core/flight.gd y core/mission.gd.|Bloqueante de alcance1.1.3.1/1.1.3.2.|
|CE-R4|Se prescribe mínimo60FPS y perfiles15W/25W con etiquetas como requisitos ya acordados.|ENTREGA_AGY.md:168–169; TABLERO.md no fija umbral ni perfiles.|Bloqueante del criterio de rendimiento si se mantiene obligatorio; medición puede planificarse.|
|CE-R5|La revisión de rendimiento exige60/120FPS y necesita separar ese objetivo de la simulación30/60/120Hz.|ENTREGA_AGY.md:140,205.|Aclaración técnica obligatoria antes de aceptar1.1.4.4.|
|CE-R6|El criterio SHA256 del EXE/PCK se puede interpretar como igualdad con el hash de las fuentes.|ENTREGA_AGY.md:204 y riesgo de183–190.|Aclaración obligatoria del contrato de trazabilidad1.1.4.1/1.1.5.3.|

## CE-R1 — Código propietario y GLB como entrada

**Confirmación:** el borrador de Qwen contiene `archivos: assets/aircraft/models/b17g.glb`; actualmente `godot/B17/aircraft.gd` es quien construye las piezas procedurales. La integración prevista debe cambiar ese adaptador, no regenerar el recurso por defecto. Tener GLB válido no demuestra que la escena activa lo use.

**Enmienda propuesta para1.1.1.1:**
> Entradas de solo lectura: `res://assets/aircraft/models/b17g.glb` y sus materiales/texturas importados. Código editable propietario: `godot/B17/aircraft.gd`; si se necesita un módulo de animación importada, nombrarlo y asignarlo expresamente en el contrato antes de escribirlo. Mantener un nodo `Engines` con el comportamiento usado por `game.gd`, enlazado a los cuatro `Rotor_*` reales. No modificar/regenerar el GLB salvo hallazgo documentado y reasignación al dueño del recurso. Aceptación: la escena activa y cada compañero usan el modelo importado, mantienen escala/materiales y congelan/reanudan sus rotores al pausar/reiniciar, además de las pruebas de recurso y cámaras pertinentes.

**Cierre:** Qwen entrega contrato enmendado con entrada/código/salida separados; Agy y Codex Entrega comprueban conservación de `Engines` y ausencia de doble geometría.

## CE-R2 — Posición e índice de motores

**Confirmación:** la lista `[-9.4,-4.4,4.4,9.4]` procede del avión procedural. Leyendo únicamente el bloque JSON del GLB existente se obtienen estas traslaciones locales de sus rotores:

| Nodo | x | y | z |
|---|---:|---:|---:|
|Rotor_0|-7.7293|-0.6367|-7.8716|
|Rotor_1|7.7293|-0.6367|-7.8716|
|Rotor_2|-3.8008|-0.6367|-8.0734|
|Rotor_3|3.8008|-0.6367|-8.0734|

La mera asociación del índice de salud con el sufijo del nodo cambiaría el orden anterior de izquierda a derecha. Las coordenadas son evidencia del recurso actual, no constantes nuevas que deban incrustarse en producción.

**Enmienda propuesta:**
> Definir un mapeo estable entre `damage.engines[0..3]` y los cuatro motores físicos. Conservar el orden de izquierda a derecha usado por los anclajes actuales, salvo cambio semántico aprobado y documentado. Obtener anclajes de humo/escape desde los nodos y transformaciones del modelo integrado, con offset local de escape explícito si hace falta; no reutilizar coordenadas procedurales ni asumir que `Rotor_i` corresponde al índice de salud `i`. Validar individualmente los cuatro índices con daño dirigido, humo en el motor correspondiente, transformaciones correctas tras giro y reset completo.

**Cierre:** el contrato incluye el mapeo y una comprobación por motor. El test no debe limitarse a comprobar que existen cuatro partículas.

## CE-R3 — Inicio y final de la misión

**Confirmación:** `core/flight.gd` inicia en `(0,1200,0)`, velocidad85m/s. `core/mission.gd` declara `exit_point=(28000,1200,-15000)` y pasa de `REGRESO` a `COMPLETADA` al estar a menos de500m de ese punto. No hay fases de despegue o aterrizaje en la máquina de estados inspeccionada.

**Enmiendas propuestas:**
- 1.1.3.1: «Completar manualmente la misión desde su inicio en vuelo y reunión de formación, atravesando aproximación, pasada con suelta e impacto y regreso hasta alcanzar la zona segura definida por `exit_point`; sin forzar estados para conseguir el resultado».
- 1.1.3.2: «Victoria al alcanzar la zona segura después del bombardeo exitoso; derrota por derribo o fallo de objetivo, más pausa y reinicio verificables».
- Despegue/aterrizaje quedan como posible ampliación futura, no requisito implícito de esta misión.

**Cierre:** Agy elimina esas ampliaciones de los dos criterios sin cambiar código ni estados para acomodar un requisito no acordado.

## CE-R4 y CE-R5 — Medición y objetivo de rendimiento

**Confirmación y matiz:** Agy exige «mínimo60FPS continuos» y «tasa de refresco estable a60y120FPS». También enumera correctamente pruebas de simulación30/60/120Hz. No afirma literalmente que FPS y Hz sean iguales; el problema verificable es que el contrato no separa su alcance y añade objetivos de render sin decisión. Pasar simulación headless a distintas tasas no acredita esos FPS en AllyX.

**Enmienda propuesta:**
> Probar por separado: (a) corrección de la simulación con pasos de30/60/120por segundo; (b) rendimiento de render medido en el destino real. Registrar resolución, renderer, MSAA, configuración, energía disponible, alimentación/batería, SO/driver, escena/duración, FPS y distribución de frametimes. Los perfiles15W/25W son casos propuestos sujetos a disponibilidad y acuerdo, no condiciones obligatorias ni etiquetas certificadas por este documento. El objetivo mínimo de FPS y los presupuestos de frametime/memoria se presentan al supervisor como propuesta pendiente de aprobación; no se promete60o120FPS antes de medir y acordar. Mientras falte hardware, registrar `BLOQUEADO_DESTINO`.

**Cierre:** el plan puede aprobar un protocolo de medición con objetivos pendientes explícitos; la aceptación final de rendimiento requiere objetivo acordado y resultados de destino. No convertir el pendiente en un PASS ni forzar calidad gráfica para alcanzar una cifra no acordada.

## CE-R6 — Hashes y vínculo del artefacto

**Confirmación y matiz:** «EXE y su PCK embebido coincidan con el SHA256 del candidato que pasóQA» puede significar correctamente un artefacto ya identificado, pero es ambiguo si “candidato” se refiere al árbol fuente. Son objetos distintos y no procede exigir igualdad entre sus hashes. Con PCK embebido no debe inventarse un archivo PCK externo.

**Enmienda propuesta:**
> Crear un manifiesto con identificador de candidato y hashes por archivo de las fuentes/recursos congelados, versiones del motor/plantilla/preset, comando y registro de exportación, más SHA256 del EXE y de cada archivo distribuido que exista. Vincular las pruebas a ese identificador y a los hashes de los artefactos efectivamente probados. Al copiar o restaurar un artefacto, sí se exige igualdad de su hash con el original registrado; no se exige que fuentes, EXE y contenido empaquetado tengan el mismo hash entre sí. Si se verifica el contenido del PCK embebido, registrar método e inventario por separado.

**Cierre:** Agy y Codex Entrega usan la misma definición de candidato/manifiesto. Este punto es de trazabilidad, no prueba por sí solo que el ejecutable funciona en Windows.

## Recomendación al supervisor

Devolver los puntos afectados con estas enmiendas documentales y conservar el resto en revisión. No rechazar la totalidad de los planes ni activar programación para resolver observaciones de planificación. La aprobación posterior corresponde al supervisor y no está implícita en esta revisión.
