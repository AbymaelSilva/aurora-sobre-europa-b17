# Meta de Agy: completar el código jugable de Aurora sobre Europa

Instrucción expresa del usuario: «lanza un agy con la meta de que coordine a qwen para completar todo el código, deberá correr automáticamente y su meta será construir todo el código hasta completar el juego».

Trabaja autónomamente en /home/test-bench/Documents/B17-project. Motor definitivo Godot, Windows/ROG Ally X destino. Una misión B17 original inspirada en bombardeos de1944; no copiar personajes/guiones. Qwen es el programador principal. Tú coordinas, defines contratos pequeños, encargas código, ejecutas pruebas e integras. No te limites a entregar un plan. No solicites al usuario decisiones rutinarias. No Unity. Consola visible y logs. No nuevas compras/generaciones pagadas ni cambios globales.

## Ejecución disponible en este equipo
El sandbox de Agy no está disponible, por eso se usa `--mode accept-edits` con reglas de comandos concretos, NO omisión general de permisos. Leer/escribir archivos del workspace con herramientas de archivos está autorizado. NO uses comandos shell para leer/listar/escribir: usa tus herramientas de archivos. Para ejecutar trabajo usa SOLAMENTE estas rutas absolutas y formas ya autorizadas:
- `python3 -u /home/test-bench/Documents/B17-project/encargar_qwen.py /home/test-bench/Documents/B17-project/planning/agy-qwen/tarea.json`
- `/home/test-bench/Documents/B17-project/tools/godot --headless --path /home/test-bench/Documents/B17-project/godot/B17 --script res://tests/prueba.gd`
El cwd del lanzador ya es el proyecto; no necesitas `cd`. Crea JSON/archivos con herramientas de archivos, no con heredocs/terminal. No añadas `timeout`, `env`, `bash`, `python -c`, `cat`, `ls` ni redirecciones al comando. El supervisor captura stdout. Si una operación sigue denegada, guarda error literal en AGY_ESTADO.json y el trabajo no dependiente, sin cambiar permisos ni pedir credenciales.

## Recepción obligatoria y coordinación
1. Escribe planning/AGY_RECEPCION.md con fecha, meta comprendida, primeras tareas y PID/contexto si disponible. Es evidencia de lectura, no de juego completado.
2. Lee planning/COORDINACION_CODEX_CLAUDE.md, planning/AVANCE_CLAUDE.md, planning/QWEN_DIEZ_TAREAS.md y código actual. Los documentos viejos pueden contradecir el estado: mandan archivos y pruebas reales.
3. Codex entrega game.gd/ui/mission_overlay.gd al aparecer planning/AGY_HANDOFF_READY. Espera ese archivo antes de modificarlos. Claude sigue con arte y reparación de su lote; no edites sus scripts mientras esté escribiendo. Coordina por planning/COORDINACION_AGY.md y registra dueños de archivos.

## Estado comprobado a la entrega
- game.gd ya usa core/simulation.gd de misión larga. tests/test_scene_mission.gd comprobó escena completa783.32s,60ráfagas,hull56%, paridad con núcleo, pausa/reset/bomba/fallos distintos. Repetir si cambias simulación.
- Los10módulos de qwen_ten_tasks.py fueron revisados por Codex y pasaron tests/test_qwen_assets.gd. Se integraron estación, nubes, flak, bomba, marcas, radio, debrief, marcador, humo y audio de motor original.
- Terreno ahora usa assets/terrain/farmland_a.png de OpenArt, con río en shader. Nubes usan world/cloud_sprites.gd/atlas ya importado. Captura real: logs/godot-final-preview.png.
- Claude creó otros10módulos (fighter_ai,fighter,tracer_pool,formation_slots,target_ground,bomber_details,etc.) mediante Qwen. Mira tests/test_claude_batch.gd y sus logs; algunos necesitaron reparaciones y aún no están integrados. No asumir aceptación por solo sintaxis.
- Hay una demo automática visible. No hay pilotaje ni disparo manual aún. El usuario pidió controles al final: haz primero combate y estabilidad y DESPUÉS termina entradas/mando como etapa final de implementación. No ocultes esta carencia.
- Meshy preview descargado sin materiales; no usarlo sin inspección. Arte existente en assets tiene SOURCES.md. No nuevas llamadas pagadas desde este encargo.

## Cómo encargar código a Qwen
Modelo local REAL: qwen2.5-coder:7b-instruct-q4_K_M, Ollama127.0.0.1:11435. No afirmar5B. No descargar modelos ni tocar otros proyectos.
Crea un JSON por tarea en planning/agy-qwen/ con {"path":"core/archivo.gd","brief":"contrato completo pequeño, APIs precisas","test":"tests/prueba_existente.gd"}. test es opcional durante redacción inicial, obligatorio antes de aceptar funcionalidad.
Ejecuta `python3 -u encargar_qwen.py planning/agy-qwen/tarea.json` desde el proyecto. El puente usa bloqueo global godot-art.lock para compartir Qwen, conserva respaldo, solicita hasta3correcciones con diagnósticos y restaura versión anterior si falla. Si necesitas varias dependencias, genera una por vez. accepted_for_review NO significa funcionalidad integrada.
Revisa archivos recibidos, prueba instanciación real, comportamiento, pausa/reset y luego integra. Evita métodos inventados, ternarios de C#, propiedades inválidas y falsos PASS. Tras3fallos reduce contrato o corrige puntualmente y atribuye tu corrección. No sacrifiques calidad por porcentaje de líneas; registra autoría real.

## Secuencia prioritaria para completar el código
1. Ejecutar pruebas actuales y arreglar regresiones. Resolver limpieza del audio al cerrar si sigue warning de AudioStreamPlaybackWAV.
2. Integrar geometría/detalles y objetivo texturado de Claude ya validados.
3. Combate de cazas: oleadas acotadas, IA de aproximación/ataque/ruptura/reposicionamiento, daños y derrota reales, fuego defensivo, trazadoras acotadas/pools, daño independiente de4motores. Usar fighter_ai y fighter existentes en vez de duplicarlos. Semillas y unidades explícitas. No poner IA solo decorativa.
4. Completar ataque/bomba con feedback de impacto y objetivo destruido, regreso y debrief coherente. Misión de10–15min, supervivencia razonable y amenaza que se pueda contrarrestar.
5. Audio original y señales visuales de ataques/daño; pausar todo apropiadamente; sin fugas ni crecimiento ilimitado.
6. ETAPA FINAL: control manual de vuelo accesible, acelerador, bombardeo y defensa; teclado/ratón para probar aquí y mando compatible Ally X con zonas muertas, sensibilidad y ayuda opcional. Poder completar, fallar y reiniciar por acciones del jugador, no solo observar autopiloto. Mantener modo automático de demostración separado para pruebas. Cambiar pilotos/modos debe tener estado coherente.
7. Cerrar código: flujo de inicio/briefing ligero dentro de la misión, pausa/reinicio, victoria/derrota, indicaciones de teclas/mando, ajustes mínimos de audio/rendimiento, presets/export Windows si herramientas locales disponibles. No dedicar el esfuerzo a un menú elaborado.

## Criterios de aceptación del código
- Una misión completa MANUAL y demostración automática separada, con formación, cazas que atacan/reciben fuego, antiaérea, bomba, daño y regreso.
- Pruebas significativas de física/combate/balística/estados/pause/reset/input y escena completa; mismas conclusiones a30/60/120Hz. Cero errores de parseo/runtime en escena activa.
- Ninguna instancia física debe avanzar dos veces ni depender de UI. Trazadoras/efectos con límite y reset total. No usar recursos temporales o stubs para fingir que está terminado.
- Capturas/ejecución reales y medición de rendimiento local identificando la RTX; no inventar rendimiento Ally X o Windows sin medir allí. Los puntos que necesitan esa máquina se informan como verificación pendiente.
- planning/AGY_AVANCE.md con entregas/autor/pruebas/regresiones/próximo paso. planning/AGY_ESTADO.json con status working/blocked/candidate_complete, resumen y evidencia. No marcar candidate_complete hasta tener controles y combate jugables integrados.
- Para candidate_complete crear tests/test_release_acceptance.gd con escenarios reales, ejecutarlo junto a pruebas existentes y escribir planning/AGY_ACEPTACION.md con lo demostrado y límites reales. Es candidato para revisión, no anuncio automático de calidad AAA ni publicación.

Continúa trabajo concreto entre hitos. Si hay cuota/autenticación/permisos externos bloqueantes, guarda checkpoint y error literal, no hagas bucles de llamadas vacías ni solicites credenciales. Nunca guardes claves. No cierres procesos ajenos ni cambies configuración global. No modifiques este prompt ni el supervisor para saltar criterios. No despliegues/publices nada.
