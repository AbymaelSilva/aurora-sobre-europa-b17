# Preparación de entrega y respaldo — V1 LOCAL Linux/RTX2060SUPER

## Meta y alcance
Arranque reproducible en esta máquina, instrucciones correctas y respaldo recuperable del candidato aceptado. No exportación Windows, consola, ajustes de energía Ally, generación de arte ni publicación. No se crea un paquete mientras dependan QA/capturas pendientes.

## Identidad y manifiesto del candidato
1. El supervisor fija id de candidato local al cerrar integración/QA. El baseline actual es observacional; no es release ni se sustituye por un hash aislado.
2. Inventariar y hashear individualmente fuentes/escenas/shaders/configuración/UIDs/recursos del proyecto Godot, incluidos GLB y texturas realmente usados. Registrar versión y hash del motor portátil, preset y lanzador, fecha real, entorno de prueba y procedencia de recursos.
3. Vincular cada prueba/log/captura aceptados a ese id y sus hashes. Comprobar estabilidad de archivos antes/después de QA y del empaquetado. Diferentes fuentes, archivo de motor y eventual paquete tienen hashes diferentes.
4. Conservar lista de archivos y exclusiones. No incluir credenciales, configuraciones personales de agentes, Unity cancelado, cachés regenerables ni registros ajenos.

## Entrega mínima preferida
Puede bastar el proyecto aceptado, motor portátil local verificado y lanzador ya existente `INICIAR_B17.sh`/`jugar_b17.py`, con `release/<id>/LEEME.md`y`.txt` de Claude y manifiesto. No imponer exportación Linux si no mejora el uso o aislamiento. Si el lanzador precisa corrección, la implementación pertenece a Qwen mediante Agy; Codex Entrega no cambia producción.

## Respaldo y restauración
- Guardar una copia identificada del proyecto fuente completo y recursos usados fuera del árbol editable, sin sobrescribir versiones anteriores.
- Conservar `.gd.uid` y archivos fuente/importaciones necesarios; excluir el directorio de caché `.godot` solo con reimportación documentada. Un proyecto restaurado sin caché puede necesitar importación mediante el editor portátil antes de su primer arranque.
- Verificar hashes del respaldo contra manifiesto. Restaurar en carpeta limpia y comprobar carga/importación y misión usando ese árbol, no recursos residuales del original.
- Guardar logs de restauración y límites. Copia en el mismo disco protege cambios accidentales, no fallo del disco; una segunda ubicación solo se declara cuando exista y sea verificada.

## Dependencias y entrega al supervisor
Pendientes: HITO1estable, regresiones posteriores, capturas de Claude, controles locales revisados e instrucciones del candidato. Al cerrarse, proponer el id, inventario y mecanismo de arranque concretos; ejecutar copia/validación sin tocar código. Si cambian fuentes tras congelación, reabrir manifiesto y pruebas afectadas. La etiqueta estable solo la concede el supervisor al revisar esa evidencia.
