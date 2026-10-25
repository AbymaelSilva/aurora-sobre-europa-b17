# Prompt técnico — Dashboard de operaciones B17 (autor del código: Qwen; supervisor: Claude)

## 1. Análisis del requerimiento
### 1.1 Lo que pide el usuario
- 1.1.1 Una pantalla que muestre de forma continua las operaciones en curso y lo ya completado por todos los agentes.
  - 1.1.1.1 Debe mantenerse viva: se refresca sola, sin intervención.
  - 1.1.1.2 El código lo escribe Qwen.
  - 1.1.1.3 Se ve en una ventana propia del escritorio.
### 1.2 Restricciones reales
- 1.2.1 Qwen (qwen2.5-coder 7B, en Ollama :11435) responde peticiones; no puede ejecutar un proceso permanente. Qwen escribe el programa y el programa es el que se mantiene vivo.
- 1.2.2 El puente `encargar_qwen.py` solo acepta archivos `.gd` dentro de `godot/B17`, con `--check-only` y una prueba que imprima `TEST PASS`. Por eso el dashboard es GDScript (Godot 4.7.2) y se ejecuta como `SceneTree` en ventana.
- 1.2.3 Qwen rinde con archivos pequeños (menos de 120 líneas) y contratos explícitos. Si regenera un archivo existente puede romperlo, así que se hacen 3 archivos NUEVOS.
- 1.2.4 Solo lectura: el dashboard NO escribe en ningún archivo del proyecto ni lanza procesos.
### 1.3 Fuentes de datos (rutas absolutas bajo ROOT = /home/test-bench/Documents/B17-project)
- 1.3.1 `logs/orquestacion/supervisor.log`: líneas `[ISO] [SUPERVISOR] [ETIQUETA] ESTADO | detalle | evidencia=ruta`. Los estados que empiezan por `COMPLETADO` o `ENTREGADO_ACEPTADO` cuentan como completados; `DEVUELTO`, `BLOQUEO` o `RECHAZADO`, como incidencias.
- 1.3.2 `planning/orquestacion/TABLERO.md`: filas `| 1.1.x.x | entregable | dueño | revisor | dependencia | contrato | ejecución |`.
- 1.3.3 `logs/agy-coordinador/status.json`: `status`, `round`, `reason`, `last_tool`, `last_activity_utc`.
- 1.3.4 `logs/orquestacion/qwen.log`: líneas `[ISO] [QWEN_BRIDGE] [ruta] [ESTADO] evidencia=…`.
- 1.3.5 `logs/orquestacion/claude_audio.log` y `logs/orquestacion/claude_meshy.log`: líneas `ISO texto`.
- 1.3.6 Contadores: `godot/B17/assets/audio/sfx/*.wav` (meta 47) y `art/meshy/candidatos/*.glb` (meta 4).
- 1.3.7 Paquetes: `release/*/CANDIDATE_STATUS.json`, campos `candidate_id` y `status`. Se muestra el más reciente por fecha de modificación.

## 2. Arquitectura (3 archivos nuevos de Qwen y 1 prueba del supervisor)
### 2.1 `godot/B17/tools/dashboard/dashboard_data.gd`: lógica pura, sin nodos ni archivos
- 2.1.1 `extends RefCounted`, con `class_name DashboardData`. Todas las funciones son `static` y reciben texto, no rutas.
- 2.1.2 `static func parse_supervisor(text: String) -> Array[Dictionary]`
  - 2.1.2.1 Una entrada por línea válida: `{time, tag, status, detail}`. `time` = los 19 primeros caracteres tras `[`; `detail` = el texto entre el primer y el segundo `|`, recortado a 110 caracteres.
  - 2.1.2.2 Ignora las líneas que no tengan `[SUPERVISOR]`.
- 2.1.3 `static func classify(status: String) -> String` devuelve `"ok"`, `"warn"` o `"info"`, según 1.3.1.
- 2.1.4 `static func parse_board(text: String) -> Dictionary` devuelve `{total, done, rows: Array[Dictionary]}`.
  - 2.1.4.1 Fila válida: empieza por `| 1.` y tiene 7 celdas o más.
  - 2.1.4.2 `done` cuenta las filas cuya última celda contiene `COMPLETADO` o `PASS`.
  - 2.1.4.3 `rows[i] = {id, item, owner, state}`; `state` es la última celda recortada a 60 caracteres.
- 2.1.5 `static func parse_bridge(text: String, limit: int) -> Array[Dictionary]`: las últimas `limit` líneas de qwen.log como `{time, path, status}`.
- 2.1.6 `static func tail_lines(text: String, n: int) -> PackedStringArray`: las últimas n líneas no vacías.
- 2.1.7 `static func progress_bar(done: int, total: int, width: int) -> String`, por ejemplo `"████████░░░░ 8/12"`. Con `total` = 0 devuelve `"—"`.
### 2.2 `godot/B17/tools/dashboard/dashboard_view.gd`: dibujo
- 2.2.1 `extends Control`, a pantalla completa. Propiedad `var model: Dictionary` y `func set_model(m: Dictionary)` que guarda el modelo y llama a `queue_redraw()`.
- 2.2.2 `_draw()` con `draw_rect` y `draw_string`. Fondo `Color(0.07,0.08,0.10)`, título dorado `Color(0.95,0.78,0.35)`, completados en verde `Color(0.35,0.85,0.45)`, incidencias en rojo `Color(0.95,0.40,0.35)` y lo demás en gris claro.
- 2.2.3 Distribución en 1280×720:
  - 2.2.3.1 Cabecera: «B17 · CENTRO DE OPERACIONES», la hora de la última actualización y la barra global del tablero (`progress_bar`).
  - 2.2.3.2 Columna izquierda «AGENTES»: una tarjeta por agente (Agy, Qwen, Claude audio, Claude Meshy y Supervisor) con su estado y su última actividad. Agy, de status.json; Qwen, de su última línea del puente; audio, «WAV n/47» más su última línea; Meshy, «candidatos n/4» más su última línea.
  - 2.2.3.3 Columna central «COMPLETADO»: los 12 últimos eventos del supervisor con clase `ok`, del más nuevo al más antiguo, con hora y etiqueta.
  - 2.2.3.4 Columna derecha «TABLERO V1»: las filas del tablero con un punto de color (verde si están hechas, ámbar si no) y su estado.
  - 2.2.3.5 Pie de página: «INCIDENCIAS», con los 3 últimos eventos `warn`, y el último paquete (`candidate_id` y `status`).
- 2.2.4 Fuente: `ThemeDB.fallback_font`. Tamaños 22 (título), 15 (secciones) y 13 (filas). Los textos largos se recortan; nada se sale de su columna.
### 2.3 `godot/B17/tools/dashboard/dashboard_main.gd`: proceso vivo
- 2.3.1 `extends SceneTree`. En `_initialize()` crea `dashboard_view` dentro de `root`, pone el título de ventana «B17 — DASHBOARD DE OPERACIONES» con `DisplayServer.window_set_title` y llama a `refresh()`.
- 2.3.2 Refresco cada 3 s con un `Timer` (one_shot=false, añadido a root) cuyo `timeout` llama a `refresh()`.
- 2.3.3 `refresh()` lee los archivos de 1.3 con `FileAccess.get_file_as_string(ROOT + ruta)`. Si falta un archivo usa `""`, nunca un error. Lista directorios con `DirAccess.get_files_at`. Construye el diccionario `model` con DashboardData y llama a `view.set_model(model)`.
- 2.3.3.1 Contrato del modelo (el mismo que `sample_model()` de tests/test_dashboard_view.gd):
  - `updated`: «HH:MM:SS»;
  - `board`: el resultado de parse_board;
  - `agents`: Array de `{name, state, detail, time}` para Agy, Qwen, Claude audio, Claude Meshy y Supervisor;
  - `completed`: los 12 últimos eventos `ok`, del más nuevo al más antiguo;
  - `warnings`: los 3 últimos `warn`;
  - `release`: `{candidate_id, status}`.
- 2.3.4 `const ROOT := "/home/test-bench/Documents/B17-project/"`.
- 2.3.5 Sale con ESC o al cerrar la ventana (con `quit()`).
- 2.3.6 Consumo mínimo: sin `_process` de dibujo continuo; solo redibuja al refrescar.

## 3. Pruebas y aceptación
- 3.1 `godot/B17/tests/test_dashboard_data.gd`, escrita por el supervisor ANTES que el código: textos de ejemplo con el formato real de 1.3. Comprueba 2.1.2–2.1.7, incluidos casos vacíos y líneas mal formadas. Debe imprimir `TEST PASS`.
- 3.2 Puente, un archivo por encargo y en este orden: `dashboard_data.gd` (prueba 3.1), `dashboard_view.gd` (prueba `tests/test_dashboard_view.gd`: instancia, `set_model` con un modelo de ejemplo y sin errores) y `dashboard_main.gd` (solo `--check-only` más la prueba de vista).
- 3.3 Verificación del supervisor con GPU:
  - 3.3.1 La ventana se abre y muestra datos reales.
  - 3.3.2 Los cambios en los logs aparecen en 3 s o menos.
  - 3.3.3 Nada se superpone.
  - 3.3.4 Uso de CPU por debajo del 5 %.
- 3.4 Lanzador `tools_review/dashboard.sh`: abre la ventana con `tools/godot --path godot/B17 --resolution 1280x720 --script res://tools/dashboard/dashboard_main.gd`. El supervisor lo deja abierto en el escritorio.

## 4. Reglas para Qwen (van en cada encargo)
- 4.1 Solo GDScript de Godot 4.7, sin C# ni JavaScript; tipos explícitos; nada de clases ni dependencias inventadas.
- 4.2 Implementa EXACTAMENTE el contrato de su archivo, con los nombres y firmas literales de la sección 2.
- 4.3 Sin escritura de archivos ni procesos externos.
