# Decisiones y evidencia


## Vigencia y resolución documental — 2026-10-24

La instrucción vigente al inicio de PROMPT_MAESTRO.md cancela Unity y fija **Godot como motor definitivo**, con controles aplazados. Sustituye tanto la comparación provisional como el plan intermedio Godot prototipo / Unity final. No se reabre esa decisión con una recomendación de Claude. Se conservan abajo las decisiones anteriores como historial superado.

RESULTADO_INICIO.md documenta inferencia de qwen2.5-coder:7b-instruct-q4_K_M en 11435, ejecución de Godot 4.7.2 y pruebas del prototipo. Son registros posteriores, no comprobaciones repetidas en esta sesión. Sus referencias a Unity como destino también quedan superadas por la instrucción vigente. ESTADO_UNITY.md documenta instalación posterior del editor y bloqueo por licencia: no prueba ejecución del juego y no justifica reactivar Unity.

## Evidencia recibida de Claude — fotografía de su inspección

Fuente: REVISION_CLAUDE_DIRECTA.md §1, inspección externa al sandbox y de solo lectura. Se atribuye a Claude; esta actualización no ejecuta esos comandos ni certifica que los valores dinámicos sigan iguales.

| Dato | Evidencia y alcance |
|---|---|
| GPU | RTX 2060 SUPER, 8192 MiB, driver 595.99.02, mediante nvidia-smi/lspci: declaración del usuario confirmada; B2 parcialmente cerrado. |
| RAM | 14 GiB totales, aproximadamente 12 GiB disponibles en reposo, mediante free -h; no demuestra convivencia editor/LLM. |
| Raíz / | 58 GB totales, 15 GB libres, 73 % ocupado, mediante df -h; capacidad histórica, revisar antes de futuras instalaciones. |
| Disco del modelo | nvme0n1p3 montado, 465 GB totales y 116 GB libres; sistema de archivos no confirmado por la etiqueta. |
| Motores | No encontrados en PATH, ~ ni /opt hasta profundidad 4; búsqueda limitada, superada por registros posteriores de Godot y Unity. |
| Ollama | Cliente 0.40.8 en ~/.local/bin/ollama; sin servidor activo en aquella inspección. |
| Puertos | 11434 y 11435 sin escuchas según ss -ltn en aquella inspección; posteriormente hay inferencia documentada. |
| Lanzador SentinelX | servir_qwen.sh: OLLAMA_HOST=127.0.0.1:11435, OLLAMA_CONTEXT_LENGTH=4096, un modelo y una petición paralela; leído, no ejecutado por Claude. Contexto declarado del modelo: 32768; no equivale al contexto efectivo. |
| Red de Codex | EAI_AGAIN y socket: operation not permitted en registros previos explican intentos fallidos de Claude/Agy desde el sandbox; no prueban fallo de esos servicios externos ni imposibilidad permanente de todo puente. |

## Criterios vigentes derivados de la revisión

- Mantener el lanzador de SentinelX intacto. Un lanzador propio de B17, si hace falta, requiere un encargo separado; no se crea en esta revisión.
- Conservar 4096 como configuración observada, no como capacidad validada para cualquier tarea. Presupuestar tokens de entrada y salida, con margen y medición; rechazar equivalencias fijas de palabras a tokens. Cambiar a 8192 requiere evidencia de memoria y rendimiento, no una descarga de modelo.
- Separar lógica y adaptadores; contratos pequeños, pruebas de aceptación congeladas y autoría explícita. Las correcciones históricas de Codex se conservan como tales, sin atribuirlas a Qwen.
- Para comparar tasas de actualización: variar FPS de render (30/60/sin límite cuando sea viable), mantener paso de física fijo, entradas reproducibles y semilla; comparar trayectoria y respuesta con tolerancias explícitas. Una prueba con dt frente a dos medios pasos evalúa convergencia del integrador y no exige igualdad exacta general.
- Windows, mando físico y Ally X siguen sin validación documentada en RESULTADO_INICIO.md. Los controles permanecen aplazados por el usuario; las pruebas de lógica no sustituyen esas validaciones.
- Unity y su capacidad de disco dejan de ser bloqueos del plan vigente. No instalar, activar ni abrir Unity como consecuencia de esta revisión.

## Recepción y respuesta a Claude

REVISION_CLAUDE_20261024_012244.txt y REVISION_CLAUDE_DIRECTA.md recibidas y leídas; respuesta de Codex registrada en RESPUESTA_CODEX_A_CLAUDE.md. No hay consenso conjunto: Claude no ha respondido a los desacuerdos. Se aceptan principios de modularidad, pruebas y mediciones; las propuestas de motor y los criterios técnicos se resuelven por separado.

## Historial superado o condicionado (se conserva)

Los párrafos de selección de motor, inferencia no comprobada y ausencia de respuesta de Claude que siguen describen etapas previas. No prevalecen sobre las secciones vigentes anteriores. El reparto, arte e hitos siguen siendo referencias donde no contradigan instrucciones posteriores; el orden de controles queda aplazado.

## Motor elegido por Codex para el prototipo — SUPERADO

Preferencia provisional inicial: Godot 4 estable, edición estándar, GDScript tipado. No es una decisión definitiva. Ante la pregunta del usuario sobre Unity, comparar una tarea pequeña equivalente en C# y GDScript antes de cerrar el motor. Versión exacta pendiente de comprobar y fijar antes de instalar; no actualizar durante un hito.

Razones: editor disponible para Linux, exportación Windows x86_64, escenas/scripts de texto revisables y módulos pequeños. Es una decisión de ingeniería para este alcance, no una conclusión de Claude ni una prueba de rendimiento. La capacidad real de Qwen con GDScript debe comprobarse antes de producir sistemas completos.

Unity/C# es candidato principal junto con Godot, no debe descartarse por el hardware declarado. Puede convenir por el ecosistema de recursos y trabajo con C#; verificar integración real y capacidades de Qwen, sin dar por demostrada su superioridad en ese lenguaje. Unreal no es la primera opción para este prototipo: implica más complejidad y presión de memoria; Epic recomienda 32 GB RAM. No se afirma que sea imposible ejecutarlo en este equipo.

Fuentes consultadas:

- https://docs.godotengine.org/en/stable/about/system_requirements.html
- https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_windows.html
- https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_basics.html
- https://docs.unity3d.com/6000.0/Documentation/Manual/system-requirements.html
- https://dev.epicgames.com/documentation/unreal-engine/hardware-and-software-specifications-for-unreal-engine

## Qwen encontrado — hallazgo histórico; inferencia pendiente SUPERADA

Modelo: qwen2.5-coder:7b-instruct-q4_K_M.
Informe local: arquitectura qwen2, 7.6B parámetros, cuantización Q4_K_M, contexto declarado 32768.
Directorio: /run/media/test-bench/38340C17340BD6B2/SentinelX/LLM
Se leyó el manifiesto y se verificó existencia y tamaño de sus seis blobs. No se verificaron hashes completos ni inferencia.
Hay un lanzador existente servir_qwen.sh en ese directorio configurado para 127.0.0.1:11435 y contexto 4096; no se ejecutó ni modificó.
El puerto estándar 11434 no pudo consultarse: socket operation not permitted. Eso no demuestra que el servicio esté apagado.
El nombre '5B' comunicado anteriormente no coincide con el modelo encontrado. No hace falta descargar otro modelo para comprobar este.

## Reparto de trabajo

Qwen redacta la mayor parte del código del juego y sus correcciones. Codex define contratos, proporciona contexto, integra y comprueba. Claude revisa alcance, arquitectura y cambios sensibles cuando sea accesible. Registrar por tarea autor, revisor y correcciones para medir participación real.
No ejecutar inferencia de Qwen y pruebas gráficas exigentes simultáneamente antes de medir memoria y VRAM.

## Hitos

1. Entorno: inferencia local de prueba, versión del motor fijada, proyecto vacío ejecutable y exportación Windows de prueba. No asumir que la exportación funciona porque funciona el editor.
2. Vuelo: avión de formas simples, mando, cámara, aceleración/viraje limitados y pausa. Aceptación: recorrer puntos de ruta sin valores inválidos ni controles bloqueados; comprobar distintas tasas de actualización.
3. Puestos: piloto/torreta/mira. Aceptación: cambiar repetidamente sin duplicar entradas o cámaras; automatización mantiene el avión cuando el jugador deja el pilotaje.
4. Bombardeo: una bomba y un blanco de prueba. Aceptación: impacto, fallo y agotamiento de munición reconocidos correctamente; reinicio restaura estado.
5. Combate y daño: un caza, torreta y daños básicos. Aceptación: aciertos afectan solo al objetivo correcto; cada daño tiene un efecto visible y reproducible.
6. Misión: secuencia completa con victoria/fracaso y reinicio. Solo después integrar arte y ampliar formación/efectos.
7. Ally X: ejecutar exportación, comprobar controles y legibilidad, registrar tiempos de CPU/GPU por fotograma, memoria y tirones en escenas comparables. Resolución y calidad se ajustan con evidencia; sin promesas de FPS.

## Arte

No gastar créditos hasta validar el prototipo y establecer presupuesto por recurso. OpenArt proporciona conceptos/referencias; Meshy genera una base que requiere revisión. No asumir que vistas generadas coinciden geométricamente ni que un B-17 generado es históricamente correcto. Revisar silueta, hélices independientes, pivotes, escala, UV, materiales, colisiones y niveles de detalle. Registrar origen y licencia. Audio: herramienta real aún por verificar.

## Claude — intentos históricos; ausencia de respuesta SUPERADA

Consulta y reintento enviados desde CLI. El reintento en modo seguro terminó por tiempo límite (código 124) tras 35 segundos, sin respuesta ni diagnóstico en sus archivos. No hay acuerdo conjunto todavía.
