# Hito: demostración automática de bombardeo

Prioridad del usuario: dejar controles y mando para el final. Se conserva el prototipo de vuelo anterior y se añade una escena separada mission.tscn; no se cambió su mapeo.

Qwen escribió bomb_model.gd, mission_state.gd y mission_scenery.gd. Los tres archivos pasaron el análisis de Godot en su primer intento. Prompts, respuestas y diagnósticos en logs/mission/<fecha>/. Codex escribió el adaptador de escena mission_main.gd, pruebas y captura. Copia previa en snapshots/before-mission-<fecha>/.

La demostración vuela automáticamente por tres puntos, calcula una suelta aproximada, deja caer una bomba con velocidad heredada y gravedad, comprueba impacto o fallo y regresa a una zona segura. Un segundo lanzamiento se rechaza. La cámara sigue la bomba durante la caída. Estación, vías, río y referencias son geometría simple.

Pruebas: acierto, fallo, munición única, reinicio de bomba, pausa, reinicio completo y fases aproximación/bombardeo/regreso/completada. Comprobación del recorrido a 30/60/120 pasos simulados por segundo; esto no mide FPS de renderizado. Estado de misión fallida al fallar el blanco. Renderizado comprobado en RTX 2060 SUPER; capturas de aproximación y bomba inspeccionadas.

Límites: es una demostración corta de lógica; no representa la misión final de quince minutos. No incluye enemigos, torreta, antiaérea, daños del avión, audio ni arte final. El indicador de impacto no representa destrucción física detallada de edificios. No se han consumido créditos de OpenArt/Meshy. Unity sigue siendo el destino final; guardar contratos y parámetros para trasladarlos.

Arranque normal: INICIAR_B17.sh detecta la misión validada, ejecuta sus pruebas y abre la demostración con consola visible. Una comprobación fallida deja diagnóstico y no presenta la misión como funcional.
