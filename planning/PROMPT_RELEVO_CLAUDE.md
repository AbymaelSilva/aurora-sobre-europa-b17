# Prompt de relevo: Claude como orquestador de Aurora

Asume la orquestación del proyecto existente. No vuelvas a empezar ni sustituyas la meta por una demo más pequeña. Trabaja en español, con autonomía para decisiones rutinarias, pruebas reales y consolas visibles. Antes de modificar algo, contrasta este documento con los archivos y procesos actuales.

## Instrucciones del usuario que siguen vigentes

- Meta: un videojuego estéticamente detallado, con buena jugabilidad.
- Shooter aéreo original de B-17 durante la Segunda Guerra Mundial. Primera misión: formación aliada, amenazas aéreas y antiaéreas, bombardeo, daños y regreso a zona segura. Escala prevista: unos 15 minutos; después se añadirán misiones.
- Motor definitivo: **Godot Engine**. Unity fue cancelado explícitamente. No lo abras, reinstales ni desarrolles más; conserva sus fuentes solo como referencia.
- Plataforma: Windows, objetivo ASUS ROG Ally X. Desarrollo en Linux, i5-12490F, ~14 GiB RAM, RTX 2060 SUPER 8 GB.
- Dejar los controles y la validación del mando para el final. Esto no elimina el requisito de entregar un juego jugable.
- Qwen2.5-Coder 7B Instruct Q4_K_M debe escribir la mayor parte del código. Tú orquestas, revisas e integras. Agy puede preparar pruebas; Codex queda como colaborador al retomar.
- Reparto artístico solicitado: **Claude–OpenArt** para imágenes; **Codex–Meshy** para modelos 3D. Son roles de trabajo, no prueba de que ambos CLI tengan conectores disponibles.
- El usuario pidió este relevo cuando a Codex le quede aproximadamente 20% de contexto. No hay un porcentaje verificable disponible: el registro preparado no significa por sí solo que hayas recibido la orquestación.

## Primera acción y recibo verificable

1. Lee este documento y `planning/ESTADO.md`; comprueba la existencia del proyecto, los módulos y los resultados indicados abajo.
2. Crea `planning/CLAUDE_RECEPCION.md` con la fecha, el objetivo completo, Godot como motor definitivo, lo que comprobaste, la tarea que vas a ejecutar primero y hasta tres bloqueos reales. No atribuyas como ejecutadas las pruebas que solo leíste.
3. Continúa con trabajo concreto. Actualiza `planning/AVANCE_CLAUDE.md` después de cada hito con archivos cambiados, autor, pruebas ejecutadas, resultados y siguiente tarea.
4. Si necesitas un acceso o una aprobación, explica el bloqueo concreto y avanza con las tareas independientes. No solicites contraseñas en el chat.

## Rutas y herramientas

La raíz de trabajo es el directorio desde el que se inicia esta sesión: `/home/test-bench/Documents/B17-project`.

| Elemento | Ruta o dato |
|---|---|
| Proyecto Godot definitivo | `godot/B17` |
| Motor verificado | `tools/godot`, Godot 4.7.2 estable |
| Prototipo de referencia | `prototype-modular`, no sobrescribirlo |
| Peticiones y respuestas de agentes | `logs/` |
| Copias anteriores | `snapshots/` |
| Fuente de instrucciones vigentes | `planning/PROMPT_MAESTRO.md`, encabezado prioritario |
| Relevo histórico | `planning/HANDOFF_CLAUDE.md`; contiene pendientes ya superados: usar este documento y verificar disco |

Qwen funciona mediante Ollama en `http://127.0.0.1:11435`, modelo exacto `qwen2.5-coder:7b-instruct-q4_K_M`. Se verificó inferencia real. Sus archivos están en un volumen de solo lectura de otro proyecto: `/run/media/test-bench/38340C17340BD6B2/SentinelX/LLM`. No modificar ese proyecto. Consultar el servicio existente antes de iniciar otra instancia; no descargar modelos por defecto. En solicitudes usar `keep_alive: "0s"` para liberar GPU antes de renderizar o medir.

Cada encargo a Qwen debe ser de un archivo, con firmas exactas de las dependencias, alcance y criterios de aceptación. Proporciona los errores literales. Después de tres intentos fallidos, reduce el encargo o corrige explícitamente registrando autoría; no finjas que Qwen hizo una corrección tuya. Los generadores `generate_godot_art.py` y `assign_godot_team.py` contienen ejemplos funcionales. No los ejecutes a ciegas: pueden conservar archivos que solo compilan sin validar su lógica.

## Estado comprobado al preparar el relevo

### Presentación Godot ya integrada

- `godot/B17/aircraft.gd` ensambla `visuals/parts.gd`, `body.gd`, `wings.gd` y `engines.gd`. Qwen escribió los cuatro componentes; Codex integró y corrigió la jerarquía de rotores.
- Hay fuselaje curvo, cabina y torretas acristaladas, alas perfiladas, cuatro motores y hélices animadas. Es geometría procedural original; no equivale a un recurso final AAA.
- `game.gd` integra cielo y luz física (`world/atmosphere.gd`), terreno de campos y río (`world/farmland.gdshader`) e interfaz (`ui/mission_overlay.gd`).
- Se ejecutó con Vulkan Forward+ en la RTX y se inspeccionó `logs/godot-final-preview.png`. La captura demuestra ese estado visual concreto, no jugabilidad completa ni rendimiento en Ally X.
- `test_visuals.gd` pasó: 32 mallas, dimensiones aproximadas `(31.6, 7.0, 23.289)`, materiales presentes y cuatro hélices animadas.
- El flujo gráfico todavía usa la misión corta heredada: el núcleo largo nuevo no está integrado en `game.gd`.

### Núcleo de misión larga generado, pendiente de pruebas e integración

Qwen escribió `core/flight.gd`, `core/damage.gd`, `core/mission.gd`, `core/simulation.gd`.

- Convenciones: metros, segundos, radianes; Godot avanza hacia `-Z`.
- Vuelo nuevo: posición inicial `(0,1200,0)`, velocidad inicial 85 m/s, límites 55–110 m/s.
- Ruta: z=-6000, -14000, -22000; objetivo `(0,0,-30000)`; salida `(28000,1200,-15000)`.
- Fases: FORMACION, APROXIMACION, BOMBARDEO, REGRESO, COMPLETADA, FALLIDA.
- Cuatro motores con daños independientes. Las ráfagas antiaéreas usan el temporizador existente configurado a 2.8 s.
- Codex corrigió un `:` ausente en una propiedad de daño, tipos inexistentes en el simulador y una asignación de delta. La sintaxis del simulador pasó después.
- **Defecto conocido por corregir:** `core/simulation.gd.reset()` todavía omite `damage.reset()` y `mission.reset()`. No presentar reinicio completo como probado.
- Ejecutar pruebas reales del recorrido largo a 30/60/120 pasos/s antes de integrarlo. La duración ~783–784 s se midió en la referencia C#; todavía no en estos módulos Godot.
- El modelo de bomba existente debe seguir en EN_VUELO hasta tocar el suelo. Continuar su integración después de gastar la bomba; no detenerla por `spent=true`.

### Resultados de otros agentes

- Claude entregó `planning/REVISION_GODOT_CLAUDE.md`. Es análisis estático de tres archivos. Verificar cada hallazgo: su afirmación de un `_ready()` omitido en `mission_main.gd` no corresponde al archivo real, que no tiene ese método; el texto heredado del HUD se reinicia cada tick, así que no se demostró crecimiento ilimitado. Sí es pertinente mostrar el motivo del fallo, ajustar el plano cercano de cámara y detener/frenar hélices con pausa o daño.
- Agy generó `godot/B17/tests/test_damage_agy.gd`; se revisó y ejecutó. Pasó daño negativo, aislamiento de motor, destrucción y reinicio. Evidencia de salida en la conversación y código guardado. Una entrega anterior quedó cortada y fue rechazada; no usar `logs/agy-godot/response-truncated-original.txt` como prueba válida.
- Las revisiones Unity antiguas vacías no prueban que Claude esté desconectado; la revisión breve Godot sí respondió.

## Arte externo solicitado por el usuario

### Claude–OpenArt

Claude escribió `planning/OPENART_CLAUDE_PROMPT.txt`. Codex envió **una imagen** a OpenArt: GPT Image 2.5 Sunburst, 2K, 16:9, calidad media. Cotización: 45 créditos. ID `xwXsWLaDW2Qmk1awEoqA`, proyecto `OgiFUoWFMu1oOrtlChxF`. El último estado observado en la respuesta de creación fue PENDING; no asumir que sigue pendiente ni que ya terminó. Metadatos: `art/openart/first-concept-generation.json`. La tarjeta de OpenArt se actualiza por sí sola; no crear duplicados por falta de descarga local. El conector de Codex no se transfiere automáticamente a tu CLI. No inventes acceso ni gastes créditos intentando reconstruirlo.

### Codex–Meshy

Existe `art/meshy/b17-preview-01/b17-preview.glb`, descargado y con cabecera GLB válida. La tarea `01a16d47-2d05-705d-9946-e557b8071420` terminó SUCCEEDED. Solicitud y respuesta están junto al archivo. Es un preview Meshy T2.5 de 25 mil caras objetivo, cotizado a 5 créditos.

Inspección del contenedor: **1 nodo, 1 malla, 0 materiales, 0 texturas; 469868 bytes**. No afirmar que tenga hélices separadas o texturas. Falta importarlo, verlo desde varias vistas, medirlo y comprobar proporciones/topología antes de sustituir el avión procedural. La clave se introdujo de forma oculta y no se guardó; no asumir acceso API persistente ni pedirla en chat.

El usuario autorizó estos encargos de arte. No comprar créditos ni generar variantes repetidas sin necesidad y control del presupuesto. Para más trabajos, comprobar alcance y coste antes de enviar, evitar duplicar una tarea existente y registrar los cargos reales cuando se conozcan.

## Orden de trabajo recomendado

1. Corregir y probar el reinicio y el recorrido de `core/simulation.gd`; ejecutar éxito, fallo, bomba, pausa y reinicio con distintas tasas.
2. Integrar el núcleo largo en la escena final, sin reescribir los módulos validados ni conservar la misión corta como supuesto producto terminado.
3. Importar e inspeccionar el GLB de Meshy; decidir con evidencia si mejora al avión actual. Conservar las hélices animadas y la geometría válida mientras se resuelven los problemas del modelo.
4. Mejorar estación ferroviaria, nubes, iluminación, efectos y audio. Usar el arte de OpenArt cuando haya un archivo final disponible, sin confundir una pantalla bonita con gráficos de juego terminados.
5. Añadir cazas, torreta y puestos de piloto/artillero/bombardero con automatización de puestos inactivos; después controles y mando, menús y ajustes de calidad.
6. Medir rendimiento con el modelo Qwen descargado de GPU. Ejecutar una misión completa, probar victoria/derrota/reinicio y capturar imágenes reales. Exportar Windows y validar en Ally X cuando se disponga del dispositivo.

No declarar cumplida la meta con una demo automática, solo sintaxis, solo tests del núcleo o una imagen conceptual. No reducir el alcance para poder afirmar éxito.

## Arranque y pruebas ya disponibles

Desde la raíz, comprobar los comandos antes de ejecutarlos:

```bash
tools/godot --headless --path godot/B17 --script res://test_visuals.gd
tools/godot --headless --path godot/B17 --script res://tests/test_damage_agy.gd
tools/godot --path godot/B17
```

El último abre una ventana gráfica real. Las restricciones de escritorio/red del sandbox de Codex fallaron inicialmente; desde la terminal externa se pudo ejecutar. No omitir controles de permisos para resolverlo.

`run_team.py` e `INICIAR_B17.sh` todavía contienen rutas de `prototype-modular` e instrucciones históricas de Unity. Actualizarlos al proyecto definitivo antes de presentarlos como lanzadores finales. Los scripts de creación pueden regenerar o gastar créditos: no ejecutarlos para inspeccionar estado.

## Reglas de continuidad

- Una sola herramienta/agente modifica un archivo a la vez.
- Mantén registros y snapshots; git no estaba instalado en la última comprobación.
- Comprueba procesos o handles antes de reiniciar una tarea. Un timeout de observación no prueba que el trabajo haya terminado.
- No cerrar aplicaciones del usuario o acceso remoto. Cerrar solo demos nuestras redundantes y consolas de tareas terminadas si hace falta liberar recursos.
- No introducir credenciales en archivos ni logs, no eludir licencias, no publicar ni enviar mensajes externos sin autorización.
- Documenta lo que sigue incompleto con precisión y conserva la meta completa.
