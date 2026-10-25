# Relevo de orquestación a Claude

## Instrucción del usuario
Cuando a Codex le quede aproximadamente 20% de contexto, delegar a Claude las tareas y el avance. No hay un indicador numérico fiable disponible en esta sesión: preparar el relevo de antemano y verificar que Claude reciba el encargo. No afirmar transferencia activa si no hay respuesta o ejecución comprobada.

## Meta completa y prioridades vigentes
Crear un videojuego B-17 estéticamente detallado, con buena jugabilidad. Primera misión original durante la Segunda Guerra Mundial: formación, amenazas aéreas/antiaéreas, bombardeo, daños y regreso. Destino Windows y ROG Ally X. El usuario CANCELÓ Unity: GODOT es ahora el motor definitivo, sin requisito de licencia Unity. No seguir instalando ni desarrollando Unity. Mantener sus archivos solo como referencia. Controles y mando para el final.

Qwen2.5-Coder 7B Instruct Q4_K_M debe escribir la mayor parte del código. Codex orquesta/integra y tú revisas o asumes orquestación al recibir el relevo. Agy apoya QA y arte. Trabajar en consolas visibles, con registros, autonomía acotada y sin preguntar por decisiones rutinarias. No comprar ni gastar créditos de OpenArt/Meshy: presupuesto todavía no autorizado. No cerrar conexiones remotas o herramientas del usuario. Evitar acumular ventanas de demos antiguas.

## Rutas y herramientas verificadas
- Raíz: /home/test-bench/Documents/B17-project
- Proyecto definitivo creado: godot/B17 (copia del prototipo funcional, aún en mejora).
- Prototipo de referencia: prototype-modular; combat.tscn funciona con tres bombarderos, antiaérea, daños, bombardeo automático y regreso.
- Godot portátil: tools/godot, versión 4.7.2 estable; descarga oficial e integridad SHA512 verificadas.
- Qwen/Ollama: http://127.0.0.1:11435, modelo qwen2.5-coder:7b-instruct-q4_K_M. Modelo en disco externo de solo lectura: /run/media/test-bench/38340C17340BD6B2/SentinelX/LLM. No modificar ese proyecto ni sus servicios. Reutilizar Ollama si responde; no descargar otro modelo. keep_alive=0s libera GPU tras cada encargo.
- GPU: RTX 2060 SUPER 8 GB, driver 595.99.02; RAM total ~14 GiB; Linux i5-12490F.
- OpenArt conectado previamente. Meshy autenticado en una prueba del usuario con clave temporal no guardada; no asumir acceso persistente ni pedir contraseñas en chat.
- Unity Hub fue cerrado tras cancelar Unity; instalación y fuentes archivadas bajo tools/unity y unity/B17, no eliminadas.

## Estado actual y pruebas
Godot original superó pruebas de vuelo de diez minutos simulados; pausa/reset; bombas con acierto/fallo/munición única; recorrido completo y daño letal/no letal a 30/60/120 pasos por segundo. Evidencias en logs/ y planning/RESULTADO_INICIO.md, RESULTADO_BOMBARDEO.md.
La lógica C# que se preparó para Unity también se probó con bibliotecas matemáticas reales, fuera del editor: duración ~783–784 s, impacto, daño y regreso. Es referencia para ampliar duración del juego Godot. No confundirlo con una ejecución gráfica de Unity.
La auditoría completa de 21 archivos que se intentó enviar a Claude expiró a los 180 s sin respuesta. No hay conclusiones en REVISION_UNITY_CLAUDE.md. Las revisiones previas de planificación sí existen. Conviene encargar a Claude tareas más pequeñas y verificar la recepción.

## Trabajo nuevo ya escrito por Qwen
generate_godot_art.py generó cuatro archivos en godot/B17/visuals/: parts.gd, body.gd, wings.gd, engines.gd. Los cuatro pasaron análisis de scripts a la primera. Respuestas originales y diagnósticos en logs/godot-art/<fecha>/; consola godot-art.console.log.
- parts.gd: materiales PBR compartidos y creación de MeshInstance3D.
- body.gd: fuselaje y nariz curvos, cabina y torretas acristaladas, cola.
- wings.gd: alas trapezoidales con SurfaceTool y normales explícitas.
- engines.gd: cuatro motores y hélices animadas.
Todavía NO están integrados en aircraft.gd ni se ha revisado su renderizado. Aircraft.gd sigue siendo el avión de bloques copiado del prototipo.

## Siguiente trabajo concreto
1. Integrar aircraft.gd como ensamblador de los tres componentes visuales, sin clases duplicadas o stubs.
2. Corregir engines.gd: el rotor quedó hijo del spinner escalado. Debe ser Node3D hijo de engines en posición (x,0,-5); conservar spinner en (x,0,-4.5) con escala (1,1,1.4) y quitar la asignación posterior scale=Vector3.ONE*1.4. Hélices independientes, sin escalar su radio accidentalmente.
3. Añadir cielo y luz físicos, terreno procedural de campos y río, nubes y escenario ferroviario original. Recursos nativos, sin consumir créditos. Mejorar HUD con objetivos claros; no mostrar detalles de implementación como flujo de producto.
4. Integrar y ejecutar pruebas del proyecto Godot final, arrancar con GPU y guardar/inspeccionar capturas reales. Sintaxis o tests de lógica no prueban calidad gráfica, rendimiento ni mando.
5. Ampliar duración y flujo de la misión hacia 13–15 min usando contratos y valores de referencia C# si ayudan; trasladar correcciones de la bomba: resultado solo después de tocar suelo y actualización balística aunque la bomba ya haya sido gastada.
6. Cazas, torreta y puestos interactivos, audio, menús y acabado. Controles al final por orden del usuario; no reducir el objetivo a una demo automática terminada.
7. Exportar Windows, probar flujo completo y luego validar Ally X con el usuario. No declarar la meta completa con geometría provisional o solo tests automáticos.

## Evitar regresiones de orquestación
run_team.py e INICIAR_B17.sh aún apuntan a prototype-modular y contienen instrucciones antiguas sobre Unity en la función review(). Actualizarlos al proyecto Godot final y al nuevo alcance antes de presentarlos como arranque definitivo. No iniciar una generación si una tarea real sigue activa; comprobar proceso/handle, no solo un archivo de estado.

Cada encargo a Qwen: un archivo, contexto mínimo, firmas exactas de dependencias y diagnóstico literal. Máximo tres intentos antes de reducir tarea o corregir explícitamente; registrar autoría de cambios de Codex/Claude. Guardar snapshots antes de cambios amplios; git no está instalado en el entorno comprobado.
