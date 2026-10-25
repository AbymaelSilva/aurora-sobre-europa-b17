# Estado verificable de Unity

## Instalación
Unity Hub portátil: tools/unity-hub/UnityHub.AppImage. Editor 6000.3.27f1 instalado en tools/unity/6000.3.27f1/Editor/Unity. Archivo oficial descargado en streaming; checksum MD5 contrastado con los metadatos de Unity antes de ejecutar. Evidencia: tools/unity/6000.3.27f1/INSTALL_EVIDENCE.json y logs/unity-version.txt.

Proyecto definitivo: unity/B17. Núcleo de vuelo, bombas, daños, misión y patrones de cazas generado por Qwen. Avión procedural con alas perfiladas, fuselaje curvo, motores y hélices; escenario y audio procedural también generados por Qwen. Codex integró la escena, cámara, HUD y efectos, revisó y corrigió contratos de fábrica, geometría y lógica de bombardeo. Respuestas originales y diffs conservados en logs/ y snapshots/.

## Comprobaciones
Compilación C# estática con Roslyn y referencias reales del editor: superada sin diagnósticos. Evidencia: logs/unity-static/compiler.log y compiler.status.json. Esta comprobación no ejecuta la simulación, los shaders ni el juego.

El intento de inicialización en Unity terminó con código 198: No valid Unity Editor license found. Please activate your license. El intento posterior de abrir el editor gráfico terminó por la misma razón. Evidencia: logs/unity-initialize.log y logs/unity-editor-visible.log. Unity Hub se volvió a abrir a petición del usuario. No se introdujeron credenciales ni se aceptaron licencias.

El usuario debe iniciar sesión y activar su licencia desde Unity Hub. La pregunta de estado se dejó pendiente; no interpretar el paso del tiempo como activación. No intentar eludir la licencia ni afirmar que el juego Unity se ejecutó.

## Claude
Se asignó revisión de 21 fuentes en consola B17 — CLAUDE REVISION UNITY. El proceso terminó por timeout de 180 segundos y el archivo de respuesta está vacío: no hay conclusiones de esa revisión. El estado antiguo contenía el prompt completo dentro del error; no usarlo como informe. Las revisiones previas de planificación de Godot sí existen y se distinguen de esta auditoría Unity.

## Recursos
Se cerraron dos demos antiguas y doce consolas de tareas terminadas. Se solicitó cierre ordenado de Nautilus. Se preservaron la demo de combate más reciente, Unity, agentes, Ollama y acceso remoto. Uso de RAM observado bajó aproximadamente de 4.4 a 3.9 GiB; no atribuir toda diferencia a procesos ajenos. Detalle en logs/resource-cleanup.json.

## Próximos pasos
Confirmar licencia activa; ejecutar ProjectSetup.Initialize y CoreChecks dentro de Unity, resolver errores reales; comprobar escena renderizada y shaders; revisar rendimiento; continuar estaciones y combate interactivo; controles al final según instrucción. Proyecto final Windows y Ally X todavía no probado ni exportado. Sin gastos en OpenArt/Meshy; presupuesto pendiente. La meta completa permanece activa.
