# Revisión directa de Claude — 2026-10-24

Autor: sesión interactiva de Claude Code (no una instancia hija). No se implementó nada, no se instaló nada, no se arrancaron servicios ni se gastaron créditos.

Documentos leídos: PARA_CLAUDE.md, PROMPT_MAESTRO.md, DECISIONES.md, ESTADO.md, AGY_ENCARGO.md, ENCARGO_QWEN_001.md, consultar_agy.py, CONSULTA_CLAUDE.txt.

Relación con la otra revisión: `REVISION_CLAUDE_20261024_012244.txt` es una revisión completa y válida (generada con `consultar_claude.sh` desde la terminal de Claude, con red). Responde a CONSULTA_CLAUDE.txt, que es **anterior** a la decisión "Godot prototipo / Unity final" y a Agy. Este documento no la repite: la actualiza con evidencia nueva y se centra en lo que pide PARA_CLAUDE.md. Para la arquitectura modular, el checklist de arte, las métricas de la Ally X y el audio, sigue valiendo esa revisión.

---

## 1. Evidencia nueva (comprobada desde fuera del sandbox de Codex, solo lectura)

| Dato | Resultado | Cómo se obtuvo |
|---|---|---|
| GPU | **NVIDIA GeForce RTX 2060 SUPER, 8192 MiB, driver 595.99.02** → la declaración del usuario queda confirmada | `nvidia-smi`, `lspci` |
| RAM | 14 GiB total, ~12 GiB disponibles en reposo | `free -h` |
| Disco raíz `/` | **58 GB, 15 GB libres (73 %)** | `df -h` |
| Disco del modelo (nvme0n1p3) | Montado, 465 GB, 116 GB libres | `df -h` |
| Godot / Unity | **No se encontró ninguno** en PATH, `~`, `/opt` (búsqueda de profundidad 4) | `command -v`, `find` |
| Ollama | Cliente 0.40.8 en `~/.local/bin/ollama`; **no hay servidor activo** | `ollama --version` |
| Puertos 11434 / 11435 | Nada escuchando | `ss -ltn` |
| Lanzador `servir_qwen.sh` | `OLLAMA_HOST=127.0.0.1:11435`, `OLLAMA_CONTEXT_LENGTH=4096`, 1 modelo, 1 petición paralela | lectura del archivo (no se ejecutó) |
| Codex → red | Desde el sandbox de Codex, las llamadas de red fallan (`EAI_AGAIN`, `socket: operation not permitted`). Eso explica los intentos vacíos de Claude y de Agy. No es un fallo de Claude ni de Agy. | archivos `REVISION_CLAUDE_*_011518.txt`, `AGY_*.stderr.txt` |

Esto cierra parcialmente B2 de la revisión anterior (la GPU queda confirmada) y abre dos problemas nuevos: **disco** y **contexto**.

---

## 2. Bloqueos (impiden avanzar; ordenados)

1. **Qwen no tiene servidor en marcha y la inferencia sigue sin probarse.**
   - **Cómo se cierra:** el usuario ejecuta `servir_qwen.sh` desde su terminal (fuera del sandbox de Codex) y lanza una petición fija.
   - **Qué se registra:** tokens/s, VRAM usada (`nvidia-smi`) y si el modelo cabe entero en la GPU (`ollama ps`).
   - **Nota sobre el sandbox:** si Codex tampoco puede conectar a 127.0.0.1 desde el suyo, la integración Codex↔Qwen tiene el mismo problema que tuvo con Claude. Hay que comprobarlo pronto, porque condiciona todo el reparto.
2. **Contexto de 4096 tokens.**
   - El modelo declara 32768, pero el lanzador fija 4096.
   - Con 4096, cada encargo (prompt, documentación de la API, archivo existente y respuesta) tiene que caber en unas ~3000 palabras.
   - **Opción A:** mantener 4096 y diseñar encargos diminutos.
   - **Opción B:** subirlo (por ejemplo a 8192) y medir la VRAM.

   No se debe modificar `servir_qwen.sh` porque pertenece a SentinelX. Si se quiere otro valor, conviene hacer una copia dentro de B17-project con la misma configuración, solo con el contexto cambiado.
3. **Espacio en disco para Unity.**
   - En `/` quedan 15 GB.
   - Unity Hub, el editor, el módulo de compilación para Windows y la carpeta `Library` de un proyecto suelen ocupar del orden de decenas de GB. **Esta cifra hay que verificarla en la documentación vigente antes de instalar.**
   - Hay 116 GB libres en el NVMe del modelo. Instalar ahí el editor y los proyectos es probablemente la salida, pero es una partición con etiqueta tipo NTFS: hay que comprobar el sistema de archivos (`lsblk -f`), porque permisos y enlaces simbólicos en NTFS pueden romper el editor o el proyecto.
   - **Bloquea la instalación de Unity, no el prototipo de Godot**, que ocupa poco.
4. **Ningún motor instalado.** Es esperado, pero significa que `ENCARGO_QWEN_001` no se puede validar todavía. El requisito previo de "versión exacta fijada" está bien planteado.
5. **Agy no puede ejecutarse desde el sandbox de Codex.** Por la misma causa que Claude: `listen tcp 127.0.0.1:0` está prohibido. Hay que lanzarlo con `consultar_agy.py` desde la terminal del usuario, igual que `consultar_claude.sh`. Su "autonomía validada" sigue sin demostrar.

---

## 3. Revisión del alcance y del plan Godot → Unity

### Lo que está bien
- El prototipo de Godot está acotado: formas simples, sin arte, sin combate y sin misión.
- Se reconoce explícitamente que el código no se transfiere y que hay que reimplementar.
- Está prohibido mantener dos implementaciones completas a la vez.

### Crítica principal: qué valida realmente el prototipo de Godot
La "sensación de vuelo" depende de tres cosas:
1. el modelo de vuelo (las fórmulas y los parámetros);
2. el sistema de entrada (zonas muertas, curvas, el muestreo del mando);
3. la integración con la física del motor (paso fijo, interpolación, cámara).

Solo la parte 1 se transfiere a Unity como especificación. Las partes 2 y 3 hay que volver a ajustarlas en Unity, y es justo lo que más influye en la sensación con un mando. Por eso el prototipo en Godot da menos información de lo que parece sobre el juego final.

### Coste real de prototipar en dos motores (estimación cualitativa, no medida)

| Coste | Godot (prototipo) | Unity (final) | ¿Se paga dos veces? |
|---|---|---|---|
| Instalar, fijar versión y exportar a Windows | Bajo | Medio-alto (disco, Hub, módulos) | Sí |
| Harness de pruebas headless | GUT o scripts `--headless` (verificar) | Unity Test Framework en batchmode (verificar en Linux) | Sí |
| Calibrar a Qwen en el lenguaje y la API | GDScript 4 (riesgo de mezclar con la API de Godot 3) | C# y la API de Unity (riesgo de APIs obsoletas, sistema de entrada antiguo frente al nuevo) | Sí, y es el coste más caro |
| Ajustar el mando y la cámara | Sí | Sí | Sí |
| Especificación y parámetros del modelo de vuelo | Se crean | Se reutilizan | No |
| Prueba en la Ally X | Recomendable | Obligatoria | Parcial |

### Recomendación (propuesta, decide el usuario)

- **Opción A (recomendada): saltarse Godot e ir directo a Unity**, con un prototipo de vuelo igual de acotado en Unity, siempre que el bloqueo 3 (disco) se resuelva sin problemas.
  - El prototipo y el juego final comparten el sistema de entrada, la física, la cámara y el harness.
  - Qwen se calibra una sola vez y en el lenguaje en el que va a trabajar.
  - El prototipo se puede tirar igual: se usa un proyecto aparte (`B17-proto-unity`), no la base del juego.
- **Opción B: mantener Godot**, pero con presupuesto cerrado. Por ejemplo, un máximo de N encargos a Qwen o X horas de trabajo humano, que se fija antes de empezar. Además:
  - la salida obligatoria es un documento de parámetros y criterios (`FLIGHT_SPEC.md`), no código;
  - es razonable si Unity va a tardar en estar instalable, porque Godot permite avanzar mientras tanto.
- **En ambos casos:**
  - el modelo de vuelo se escribe como lógica pura, sin nodos ni componentes del motor, con tests de valores;
  - así la especificación (las fórmulas y la tabla de casos de prueba) es lo que se transfiere, y Qwen la reimplementa en C# con los **mismos casos de prueba**.

### Incoherencias en los documentos (Codex debería unificarlas)
- `DECISIONES.md` todavía dice "Godot 4 preferencia provisional… comparar antes de cerrar motor". `PROMPT_MAESTRO.md` ya fija "Godot prototipo / Unity final". Hay que poner un solo estado.
- `ESTADO.md` dice "No hubo conversación con Claude todavía" y "Identificador exacto del modelo pendiente". Las dos cosas están ya superadas (hay dos revisiones de Claude y el modelo está identificado).
- `DECISIONES.md` §Claude dice "No hay acuerdo conjunto todavía". Ahora hay revisiones de Claude, pero **sigue sin haber acuerdo**: Codex aún no ha respondido a ellas. No hay que registrarlo como consenso.
- `PROMPT_MAESTRO.md` habla de "comparar distintas tasas de actualización". Hay que concretar qué se compara: los FPS de render (por ejemplo 30/60/sin límite) con el paso de física fijo, y comprobar que la trayectoria y la respuesta no cambian.

---

## 4. Contratos pequeños para Qwen

### Revisión de `ENCARGO_QWEN_001` (FlightCommand)

Es un buen primer encargo: pequeño, puro y verificable. Hay que corregir lo siguiente:

1. **Falta el archivo de pruebas.** El encargo dice "comprobar límites", pero no define quién escribe la prueba ni cómo se ejecuta. Propuesta: Codex escribe y **congela** `res://tests/test_flight_command.gd` antes de enviarle el encargo a Qwen, y la prueba se ejecuta con `godot --headless --script` (sintaxis exacta según la versión fijada). Qwen no puede modificar la prueba.
2. **Ambigüedad en `class_name` y `extends Resource`.** Hay que exigir las dos cosas de forma explícita, porque si no Qwen puede entregar un `RefCounted` o un `Node`.
3. **Ambigüedad en `@export`.** Hay que decidir si las propiedades deben verse en el inspector. Propuesta: sin `@export` en este encargo, para no añadir alcance.
4. **"Explicación breve" en la respuesta.** Con un contexto de 4096 tokens, hay que pedir "máximo 5 líneas".
5. **Falta un caso.** "Valores internos" debería incluir -0,0 y valores en el límite exacto (1,0 y -1,0 sin cambio).
6. **Hay que pasarle la documentación mínima,** no la documentación entera: `clampf`, `is_nan`, `is_inf` y la sintaxis de propiedades tipadas, extraídas de la versión fijada.

### Plantilla de contrato que conviene usar en todos los encargos (adaptada a 4096 tokens)

```
ID / motor+versión / autor: Qwen / revisor
Objetivo (1 frase)
Archivos permitidos (≤2) — archivos de solo lectura proporcionados (≤1)
Contrato tipado (firmas exactas)
Casos límite (lista)
Prueba congelada: ruta + comando
Respuesta: solo código + ≤5 líneas de supuestos
Presupuesto: ≤2 rondas de corrección; si falla → dividir
```

Regla práctica: si el prompt completo (con el código de contexto) supera unas ~2500 palabras, el encargo es demasiado grande para 4096 tokens.

### Primeros encargos propuestos, en orden (válidos para cualquier motor; los nombres cambian)

| ID | Encargo | Tipo | Depende de |
|---|---|---|---|
| Q-001 | `FlightCommand` y `sanitize()` (ya redactado, con las correcciones anteriores) | Puro | Motor fijado |
| Q-002 | `shape_axis(raw, deadzone, expo) -> float` (zona muerta y curva; casos en la revisión anterior, §5) | Puro | Q-001 |
| Q-003 | `FlightState` (posición, velocidad, actitud) y un integrador `step(state, cmd, params, dt) -> state` con un modelo de vuelo simplificado de 3 grados de libertad. Prueba: 10 minutos simulados sin NaN e igual resultado con dt dividido en dos pasos | Puro | Q-001 |
| Q-004 | Adaptador: nodo o componente que lee la entrada → `FlightCommand` → `step` en el paso fijo → transformación | Motor | Q-002, Q-003 |
| Q-005 | Cámara de persecución con suavizado | Motor | Q-004 |
| Q-006 | Puntos de ruta y detección de paso por ellos, más pausa y reinicio | Motor | Q-004 |

Q-001 a Q-003 son la "prueba de calibración" de Qwen. Se registran las rondas por encargo y si el código usó APIs inexistentes. **Si Q-001–Q-003 fallan de forma sistemática con 4096 tokens, el reparto "Qwen como autor principal" se revisa antes de Q-004.** No se hace cambiando de autor en silencio.

---

## 5. Riesgos actualizados (los nuevos o los que cambian)

1. **El sandbox de Codex bloquea la red local.** Si Codex no puede hablar con Qwen en 127.0.0.1:11435, el orquestador no puede orquestar al codificador. Es el riesgo operativo número 1 y se resuelve antes que el motor. Alternativas:
   - el usuario lanza un script puente desde su terminal;
   - se ajusta la configuración de red del sandbox de Codex, si el usuario lo autoriza explícitamente (PARA_CLAUDE.md pide no cambiar configuración global, así que solo lo decide el usuario).
2. **VRAM compartida.**
   - El 7B Q4_K_M ocupa, a ojo, unos 5 GB con 4096 de contexto (**hay que medirlo**).
   - Con el editor de Unity y la vista de juego abiertos, 8 GiB pueden no bastar y Ollama pasaría capas a la CPU, con lo que bajan mucho los tokens/s.
   - Mitigación, ya prevista en el prompt maestro: no ejecutar a la vez la inferencia y las pruebas gráficas exigentes. Hay que medir en el primer hito el caso "editor abierto + Qwen generando".
3. **El modelo vive en el disco de SentinelX.**
   - B17 depende del montaje de ese disco y de que la configuración de SentinelX no cambie.
   - El lanzador no se debe compartir: es mejor un `servir_qwen_b17.sh` propio en B17-project, que apunte al mismo `OLLAMA_MODELS`.
4. **Coste de coordinar cuatro agentes** (Codex, Qwen, Claude, Agy) con un usuario como puente manual entre sandbox y terminal.
   - Propuesta: un único archivo de cola, `planning/COLA.md`, con columnas ID / para / estado / archivo de respuesta.
   - Cada agente solo escribe su propio archivo de respuesta. Así no se pisan, y se respeta la regla "un autor por archivo".
5. **Doble calibración Godot→Unity** (ver §3). Es el mayor riesgo de alcance que se puede evitar.

---

## 6. Siguientes pasos para Codex (en orden; ninguno requiere gastar créditos)

1. Unificar DECISIONES.md y ESTADO.md con la evidencia de §1, y marcar las dos revisiones de Claude como "recibidas, pendientes de respuesta de Codex".
2. Pedir al usuario que lance Qwen desde su terminal y medir lo de §2.1. Comprobar después si Codex puede llegar a 127.0.0.1:11435 desde su sandbox.
3. Pedir al usuario la decisión de §3 (opción A: prototipo directo en Unity / opción B: Godot con presupuesto cerrado). Mientras tanto, preparar Q-001 a Q-003 en una versión neutra respecto al motor.
4. Si se elige Unity: verificar el sistema de archivos del NVMe y las necesidades de disco **antes** de instalar.
5. Relanzar Agy desde la terminal del usuario. Su A01 se puede alimentar con la tabla de §1.
6. Responder en un archivo (`planning/RESPUESTA_CODEX_A_CLAUDE.md`) qué puntos de esta revisión y de la anterior acepta, rechaza o deja pendientes. Hasta que ese archivo exista, no hay acuerdo.
