# Arranque real del equipo

## Comprobado
- Acceso al escritorio mediante ejecución fuera del sandbox, sin omitir permisos.
- Consolas xfce4-terminal iniciadas y procesos comprobados. Bajo Wayland, xwininfo no enumera las ventanas nativas; no se presenta esa herramienta como prueba visual.
- GPU: NVIDIA RTX 2060 SUPER, 8192 MiB VRAM, controlador 595.99.02.
- Godot portátil 4.7.2-stable descargado del repositorio oficial godotengine/godot-builds y SHA512 contrastado con SHA512-SUMS publicado. Binario ejecutado: 4.7.2.stable.official.ed1daf0bf.
- Qwen respondió realmente a solicitudes en 11435 con el modelo qwen2.5-coder:7b-instruct-q4_K_M.
- Claude completó revisión: logs/claude-review.txt. Sus recomendaciones son análisis, no ejecución de pruebas.
- Agy completó encargo documental sin herramientas: planning/AGY_20261024T083236Z.txt. Su inventario refleja contexto anterior, no el estado actual; sus propuestas de QA/arte son útiles. No interpretar sus pendientes antiguos como fallos actuales.

## Prototipo
Ruta: prototype-modular. Cuatro scripts del juego generados por Qwen: modelo de vuelo, avión de bloques, HUD y controlador de escena.
El encargo inicial de dos archivos falló tres veces. Se dividió en archivos pequeños. El modelo de vuelo pasó a la primera. Qwen necesitó guía adicional para la sintaxis de arrays del avión. Tras tres fallos repetidos en el controlador, Codex corrigió enumeración de mandos, operador condicional y reinicio omitido. Codex corrigió también el texto de estado del HUD. No atribuir esas correcciones a Qwen.
La escena de integración, el lanzador y las pruebas son de Codex. Respuestas originales y diagnósticos en logs/.

## Pruebas ejecutadas
- Compilación/carga de scripts y arranque headless de 120 cuadros.
- 36000 pasos de vuelo, equivalentes a 10 minutos de simulación: posición finita, velocidad dentro de límites y altura mínima.
- Reinicio exacto, vuelo nivelado y ascenso.
- Integración: pausa congela vuelo; reinicio durante pausa; 20 secuencias de alternar/reiniciar; HUD y reanudación. Pruebas de lógica mediante eventos directos, no botones físicos.
- Arranque con renderizado OpenGL en RTX; captura logs/prototype-preview.png inspeccionada por Codex.

## Límites
Prototipo muy básico con geometría simple, sin misión, enemigos, arte final ni audio. Mando físico, Ally X, Windows, exportación y rendimiento objetivo pendientes. No se han usado créditos de OpenArt/Meshy.
Git no está instalado: las respuestas y diagnósticos sirven como respaldo provisional; control de versiones pendiente.
Godot es una prueba desechable; Unity sigue siendo destino final. No ampliar ambos motores a campañas paralelas.

## Autonomía acotada
El lanzador abre consolas separadas, conserva registros, no duplica un trabajador activo y acota solicitudes e intentos. Agy se limita a análisis sin herramientas porque su host no admite el sandbox de terminal del modo auto; no se desactivan permisos para darle comandos. Claude tiene un máximo de 90 segundos por consulta. Qwen recibe hasta tres intentos por archivo; los fallos persistentes quedan registrados para revisión. No se garantiza resolver cualquier fallo automáticamente.
