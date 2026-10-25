# Contrato técnico — Codex Entrega

## Alcance y estado constatado
Entrega documental para 1.1.4.1 y 1.1.5.2. No se ejecutaron motor, pruebas, exportaciones ni instalaciones; no se modificó código ni el build. Esta entrega requiere revisión del supervisor.

Inventario leído el 24 de octubre de 2026:
- `godot/B17/export_presets.cfg`: preset `Windows Desktop`, x86_64, PCK embebido, recursos completos, exclusión `tests/*`, exportación a `../../build/windows/AuroraSobreEuropa.exe`, firma desactivada.
- `godot/B17/project.godot`: escena `game.tscn`, ventana1280×720 y renderizador Forward+.
- `tools/godot-version.txt`: motor4.7.2-stable con SHA512 documentado. Existen plantillas locales Windows debug/release x86_64 de4.7.2.stable; no se verificó su hash ni se ejecutaron.
- Build existente: `build/windows/AuroraSobreEuropa.exe`,154744480bytes, fecha04:36:03 -07:00. SHA256 leído ahora: `ed1278025a3601753139387d4c31fa37fd58306609d207537283d73cfe5a8f28`.
- El GLB B17 es posterior:05:29:13 -07:00. `aircraft.gd` todavía instancia `body.gd`, `wings.gd` y `engines.gd` procedurales. El ejecutable existente no acredita la futura integración de los modelos texturizados.
- `logs/agy-coordinador/candidate-verification.json` registra PASS anteriores, pero la revisión de Claude incluye advertencia de4objetos filtrados. No basta esa evidencia para afirmar cierre sin advertencias.
- `planning/AVANCE_CLAUDE.md` registra exportación y ejecución del paquete mediante Godot Linux; declara pendientes Windows/AllyX. Es evidencia histórica atribuida a Claude, no ejecución realizada por este agente.

## 1.1.4.1 — Exportación Windows actualizada

**Meta futura:** entregar un paquete Windows identificable que corresponda exactamente al candidato aprobado después de integrar modelos y corregir regresiones.

**Entradas:** candidato congelado por el supervisor; aceptación QA de fase3; pruebas/capturas del mismo conjunto de archivos; preset y plantillas compatibles; procedencia de recursos; instrucciones de Claude(1.1.4.2).

**Archivos bajo responsabilidad futura:** `godot/B17/export_presets.cfg`, `build/windows/`, registro de exportación y manifiesto de release en una carpeta exclusiva de entrega. Cambios de código necesarios se encargan a Qwen; no se modifica una prueba para conseguir aceptación.

**Contrato que conservar:** Windows Desktop x86_64; escena principal `game.tscn`; dependencias y texturas importadas completas; entradas de teclado/mando de la versión aprobada; versión exacta del motor/plantilla. No sustituir preset ni renderer para ocultar fallos sin revisión.

**Pasos previstos:**
1. Recibir identificador del candidato, manifiesto SHA256 de sus fuentes/recursos y cierre de fase3. Mientras no exista, punto bloqueado por dependencia.
2. Revisar recursos empaquetados: `tests/*` excluye la carpeta de pruebas, pero hay scripts `test_*.gd` y `capture_*.gd` en la raíz del proyecto que requieren inventario; no asumir que esa exclusión los cubre.
3. Preservar el build actual como candidato anterior; exportar primero a carpeta nueva identificada. Guardar comando exacto, salida, código de retorno y versiones. Este documento no ejecuta el comando.
4. Inventariar todos los archivos necesarios, tamaños y SHA256. Si aparece wrapper de consola u otro archivo dependiente, incluirlo o justificar su ausencia tras comprobación; no suponer que el EXE siempre basta.
5. Verificar carga del paquete y coherencia con el candidato. Un arranque mediante Linux solo valida lo demostrado allí.
6. Entregar a Agy para prueba real Windows y AllyX(1.1.4.3), con instrucciones preparadas por Claude.

**Aceptación:** exportación de release sin errores; manifiesto ligado al mismo candidato que pasó QA; modelos/texturas efectivamente presentes; paquete íntegro tras copia; registro reproducible. El estado “paquete preparado” puede aceptarse antes de disponer del dispositivo; “validado Windows/AllyX” requiere pruebas en esos destinos y pertenece a1.1.4.3. Una regresión reabre1.1.4.1.

## 1.1.5.2 — Versión estable y respaldo

**Meta futura:** conservar una versión recuperable y trazable después de aceptar las correcciones de destino, con diferencia explícita entre candidato Linux y estable validada en destino.

**Entradas/dependencias:** hallazgos de1.1.4.3, correcciones Qwen1.1.4.4/1.1.5.1 aprobadas, paquete actualizado, aceptación QA y registro1.1.5.3. Si falta hardware, conservar candidato etiquetado; no cerrar “estable AllyX”.

**Salidas previstas:** carpeta inmutable por versión con proyecto fuente, recursos referenciados, presets, versión y procedencia del motor/plantilla, artefacto Windows, instrucciones, manifiesto SHA256, lista de pruebas y pendientes. Respaldo en ubicación identificada y registro de restauración. Excluir credenciales, cachés regenerables y procesos/logs ajenos; no borrar snapshots existentes.

**Pasos previstos:** congelar candidato aceptado; crear manifiesto; copiar a respaldo independiente del árbol editable; comparar hashes; restaurar a carpeta temporal limpia; verificar integridad y, en ejecución autorizada, apertura/misión desde esa restauración. Registrar ubicación y fecha sin sobrescribir versiones previas.

**Aceptación:** todos los archivos coinciden con el manifiesto; la restauración no depende de rutas absolutas de arte del equipo original; las pruebas del respaldo corresponden a esa versión; existe plan de reversión y acta del supervisor. Una copia en el mismo disco protege contra cambios accidentales, no acredita protección frente a fallo del disco. Una segunda ubicación/dispositivo sigue pendiente si no está disponible.

## Criterios de revisión asignados

| Punto | Evidencia necesaria para aprobar |
|---|---|
|1.1.1.1|Modelo B17 cargado en escena activa; escala/orientación/materiales correctos; cuatro rotores y contrato `Engines` conservados; pausa/reset y cámaras sin regresión.|
|1.1.2.2|Daño dirigido a cada motor sin alterar otros índices; relación daño/empuje/humo comprobada; reset restaura los cuatro; pruebas del candidato integrado.|
|1.1.3.1|Misión completa con entradas manuales del jugador que atraviesa todas las fases; resultado/tiempo/daños registrados; sin escribir directamente estados para fingir juego manual.|
|1.1.3.3|Suite pertinente del candidato exacto con códigos de retorno y diagnósticos completos; incluir recursos, escena y cambios nuevos; investigar advertencias en vez de omitirlas del criterio.|
|1.1.3.4|Hallazgo identificado por Claude, captura anterior y posterior reproducible, corrección atribuida a Qwen y no regresión.|
|1.1.4.2|Instrucciones coinciden con controles reales y paquete; requisitos conocidos, arranque/cierre/pausa/reinicio, límites Windows/Ally y versión visibles.|
|1.1.4.3|Prueba en Windows/Ally física: versiones SO/driver, modo energético, resolución/preset, mando, audio, misión y métricas locales registradas; sin extrapolar RTX→Ally.|
|1.1.5.1|Cada hallazgo de destino ligado a una corrección y repetición de la prueba en el destino afectado; cierre por revisor, no por autor únicamente.|

## Bloqueos y siguiente hito
- Integración de modelos y QA posterior pendientes: impiden actualizar el paquete como candidato definitivo.
- Hardware Windows/Ally no acreditado: bloquea validación en destino y cierre estable, no la preparación documental.
- Advertencia histórica de objetos requiere dictamen QA. El plan no certifica ausencia de fugas.
- No se constató respaldo completo recuperable ni segunda ubicación; se verificará al ejecutar1.1.5.2.

**Siguiente hito solicitado al supervisor:** revisar este contrato junto a los de Agy/Qwen/Claude; aclarar y asignar el identificador de candidato de entrada. No activar exportación ni respaldo por el mero cierre de esta planificación.
