# Estado del proyecto


## Actualización documental — 2026-10-24

Esta sesión solo revisa documentos: no comprueba procesos actuales, no instala, no arranca servicios ni realiza inferencia o gasto de créditos.

**Prevalece:** Godot definitivo, Unity cancelado y controles aplazados, según la instrucción vigente de PROMPT_MAESTRO.md. Los registros de ejecución se atribuyen a sus informes; no se presentan como observaciones en vivo.

### Evidencia de REVISION_CLAUDE_DIRECTA.md §1

- GPU confirmada por Claude fuera del sandbox: NVIDIA GeForce RTX 2060 SUPER, 8192 MiB, driver 595.99.02 (nvidia-smi/lspci).
- RAM: 14 GiB total, ~12 GiB disponibles en reposo (free -h).
- Raíz /: 58 GB, 15 GB libres, 73 % ocupado; disco del modelo nvme0n1p3 montado: 465 GB, 116 GB libres (df -h). Son valores de aquella inspección; sistema de archivos pendiente de confirmar, no deducible de la etiqueta.
- En aquella búsqueda no se encontró Godot/Unity en PATH, ~ ni /opt hasta profundidad 4; no prueba ausencia universal y está superada por los registros posteriores.
- Ollama cliente 0.40.8 en ~/.local/bin/ollama, sin servidor activo; ss -ltn no mostraba escuchas en 11434/11435 en ese momento. La inferencia posterior está documentada en RESULTADO_INICIO.md: no relanzar por un pendiente histórico.
- Lanzador SentinelX leído: 127.0.0.1:11435, contexto 4096, un modelo y una petición paralela. No confundir los 32768 declarados por el modelo con contexto efectivo medido; no modificar ese lanzador.
- Errores históricos EAI_AGAIN/socket: operation not permitted desde Codex explican los intentos fallidos de Claude/Agy; no demuestran fallo de los agentes externos.

### Revisiones y pendientes efectivos

Ambas revisiones de Claude recibidas y respondidas en RESPUESTA_CODEX_A_CLAUDE.md; no hay consenso conjunto confirmado. El modelo está identificado: qwen2.5-coder:7b-instruct-q4_K_M (7.6B, Q4_K_M).
RESULTADO_INICIO.md registra inferencia, Godot 4.7.2, pruebas de lógica y respuesta documental de Agy; no valida autonomía de Agy con herramientas. ESTADO_UNITY.md registra instalación posterior y bloqueo de ejecución por licencia, hoy fuera del plan activo.
Pendientes: tokens/s, contexto efectivo, VRAM/residencia GPU y convivencia editor/LLM con mediciones trazables; acceso desde este sandbox sin generalizar los errores antiguos; Windows/exportación/Ally X y mando físico (controles aplazados). No se cierra B2 completo solo por confirmar GPU.
Criterio de distintas tasas: variar FPS de render (30/60/sin límite cuando sea viable), conservar paso fijo de física, entradas y semilla reproducibles, y definir tolerancias de trayectoria/respuesta. No afirmar que esta comparación ya se ejecutó.

## Estado registrado anteriormente (conservado; no comprobación en vivo)

Unity cancelado por el usuario. Godot es el motor definitivo. Unity Hub cerrado, archivos preservados. Qwen está sin tarea de inferencia activa; Ollama disponible sin modelos cargados. Claude mantiene sesiones abiertas, pero la auditoría Unity encargada terminó por timeout; Agy terminó su informe. Codex continúa la transición al proyecto Godot final.
Historial SUPERADO por cancelación de Unity: ver ESTADO_UNITY.md. Editor instalado y C# estático sin errores; ejecución Unity bloqueada por licencia aún no activada. Controles siguen aplazados. No confundir el prototipo Godot que funciona con una ejecución del juego final en Unity.
Avance posterior: controles aplazados por instrucción del usuario. Demostración automática de ruta/bombardeo/regreso añadida y abierta en consola B17 — QWEN MISION. Ver RESULTADO_BOMBARDEO.md; no confundir con la misión final ni el juego Unity.
Primer prototipo abierto y ejecutándose en GPU desde consola B17 — VUELO. Godot 4.7.2 portátil verificado. Qwen produjo cuatro scripts; Codex hizo correcciones puntuales e integración. Claude y Agy respondieron. Pruebas de vuelo de diez minutos simulados y pausa/reinicio/reanudación superadas. Ver RESULTADO_INICIO.md y logs/flight.console.log. Mando físico, Windows y Ally X pendientes. Sin gasto de créditos de arte.

## Solicitudes históricas — vigencia resuelta en la actualización anterior

- B-17: primera misión de aproximadamente 15 minutos; ampliar después.
- Desarrollo en PC ASUS con RTX 2060 SUPER; destino ROG Ally X.
- Codex orquesta; Qwen es el codificador principal. [SUPERADO: «Identificador exacto del modelo pendiente»; identificado arriba.]
- Claude debe revisar el plan junto con Codex y documentar conclusiones.
- OpenArt y Meshy para arte. Capacidad de generación de audio pendiente de verificar.
- [SUPERADO por instrucciones y ejecución posteriores: «No comenzar implementación del juego todavía». En esta sesión solo se autoriza edición documental.]

## Comprobaciones históricas — pendientes superados indicados

- Claude CLI y Ollama están instalados.
- No se pudo abrir una terminal gráfica: Gtk cannot open display :0.
- [SUPERADO: «No hubo conversación con Claude todavía». Existen ambas revisiones de planificación y esta respuesta de Codex.]
- Se intentó consulta no interactiva con Claude: aparecieron errores 'Failed to create stream fd: Operation not permitted' y no se recibió respuesta durante la comprobación. No atribuirle conclusiones.
- Consulta completa guardada en CONSULTA_CLAUDE.txt; consultar_claude.sh permite ejecutarla desde la terminal del usuario y guardar su respuesta.
- Inspección del entorno: Linux, Intel Core i5-12490F, 14 GiB RAM total informados por free. No se localizaron ejecutables godot/godot4/unity/UnrealEditor en PATH. No demuestra ausencia de instalaciones fuera de PATH. GPU RTX 2060 SUPER declarada por usuario, entonces pendiente de validar [SUPERADO por evidencia de Claude §1].
- La consulta a Ollama fue bloqueada por el entorno: socket operation not permitted. Modelo instalado no verificado en aquel intento [SUPERADO por identificación e inferencia documentadas].
- No hay integración Meshy expuesta a esta sesión ni MESHY_API_KEY en el entorno.
- Se preparó meshy_connect.py para validar autenticación consultando saldo; no crea recursos, no guarda claves.

## Organización propuesta para Qwen

Codex define interfaces y tareas pequeñas. Qwen implementa la mayor parte del código del juego. Claude revisa arquitectura y riesgos. Codex integra y valida. No modificar simultáneamente los mismos archivos.

Cada encargo debe registrar: objetivo, contexto mínimo, archivos permitidos, interfaces, restricciones, criterios de aceptación, resultado y revisión. Si Qwen falla repetidamente, reducir la tarea antes de trasladar su implementación a otro modelo. No fijar un porcentaje de participación hasta medir resultados reales.

## Agy

- Antigravity CLI encontrado en /home/test-bench/.local/bin/agy. Ayuda local confirma modo auto, sandbox, modo no interactivo y tiempo límite.
- Añadido al prompt maestro con tareas A01 inventario, A02 preparación de QA y A03 recepción de arte. Qwen conserva programación principal.
- Contrato: AGY_ENCARGO.md. Lanzador reproducible: consultar_agy.py; captura salida, errores y estado, con límite de tiempo.
- Primer intento no llegó a iniciar: 'Failed to start: listen tcp 127.0.0.1:0: socket: operation not permitted'. [SUPERADO en cuanto a entregables: existe informe documental según RESULTADO_INICIO.md; autonomía con herramientas sigue sin validar.] No se intentó omitir permisos.
