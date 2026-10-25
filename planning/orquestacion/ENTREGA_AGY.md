# Contrato Técnico — AGY (Coordinador Técnico de Qwen y Responsable QA)

## 1. Alcance, estado constatado y rol de AGY
El presente documento constituye la entrega de planificación técnica de **AGY** como Coordinador Técnico de Qwen y Responsable de Aseguramiento de Calidad (QA). En cumplimiento de la consigna de fase vigente (**«no codifiques, estamos planeando»**), no se ha ejecutado el motor Godot, no se han invocado comandos ni modelos locales, no se han modificado scripts `.gd`, escenas `.tscn` ni shaders, y no se ha exportado ningún binario.

### Estado constatado del proyecto (inspección estática)
1. **Modelos 3D y escenas:** Existen los modelos GLB texturizados en `res://assets/aircraft/models/` (`b17g.glb`, `bf109g.glb`, `fw190a.glb`, `p51d.glb`). No obstante, en la escena activa `game.tscn`, el script `aircraft.gd` todavía instancia partes procedurales (`body.gd`, `wings.gd`, `engines.gd`), y `visuals/fighter.gd` sigue construyendo un caza procedural con primitivas en lugar de utilizar los GLB importados.
2. **Formación y contratos de nodos:** `formation.gd` instancia 5 aviones wingmen gestionados mediante `core/formation_slots.gd`. La escena principal `game.gd` y los tests asumen la existencia de un nodo hijo `Engines` (`$Aircraft.get_node("Engines").set_process(not frozen)` y en cada wingman), el cual debe preservarse obligatoriamente para no romper la pausa y el control de vuelo.
3. **Puestos y cámaras:** `player_controls.gd` soporta las estaciones `PILOTO`, `ARTILLERO` y `BOMBARDERO`, control de retículas (`gunsight_ring.png` y `bombsight_norden.png`), y disparo manual defensivo / suelta de bombas.
4. **Advertencia de memoria identificada en logs previos:** En `logs/agy-coordinador/candidate-verification.json` consta que la ejecución de `tests/test_claude_review.gd` arrojó:
   `WARNING: 4 ObjectDB instances were leaked at exit (run with --verbose for details).`
   Esta fuga no puede ser ignorada ni enmascarada; debe rastrearse en el candidato integrado y resolverse explícitamente en el ciclo de QA.
5. **Hardware físico destino (Windows / ROG Ally X):** No existe evidencia verificada en hardware físico ASUS ROG Ally X; las pruebas pasadas corrieron en Linux. Queda establecido que ningún resultado en Linux certifica la experiencia en Ally X.

---

## 2. Protocolo de Coordinación Técnica de Qwen

AGY actúa como cortafuegos técnico y coordinador directo de **Qwen** (programador principal):

### 2.1. Gestión de encargos y cola de trabajo
- **Modelo verificado:** `qwen2.5-coder:7b-instruct-q4_K_M` en inferencia local única.
- **Cola secuencial estricta:** Solo una inferencia de Qwen a la vez. No se paralelizan peticiones ni se satura la memoria del sistema.
- **Micro-contratos de tarea:** Cada encargo a Qwen se formulará como una especificación acotada (máximo un módulo o sub-sistema por turno), definiendo:
  - Archivos de entrada y archivos propietarios modificables.
  - Contratos de firma exactos (nombres de funciones, tipos estáticos de argumentos y retornos).
  - Nodos requeridos en el árbol de escena (ej. `Engines`, `Rotor_*`, `fighter_visuals`).
  - Restricción prohibitiva de alterar archivos de prueba para "aprobar" el código.

### 2.2. Control de concurrencia y bloqueo de arte (`godot-art.lock`)
- Antes de que Qwen toque scripts que vinculen escenas 3D o recursos importados (`b17g.glb`, materiales, texturas), AGY comprobará el estado de `godot-art.lock`.
- Si Claude está evaluando o modificando metadatos visuales/materiales, el lock permanece activo y la tarea de Qwen queda encolada hasta la liberación formal.

### 2.3. Protocolo de prueba, devolución de fallos y aceptación
1. **Inspección previa (Static Linting):** AGY comprueba estáticamente que la entrega de Qwen contenga GDScript válido para Godot 4.7.2, sin referencias a APIs inexistentes ni tipos rotos.
2. **Ejecución de suite (en fase de ejecución):** AGY ejecuta los tests unitarios y de integración correspondientes.
3. **Criterio de devolución (FAIL):** Si un test falla o se genera un error de consola:
   - AGY redacta un reporte de fallo con:
     1) Comando exacto ejecutado.
     2) Salida literal del log (`stdout` / `stderr`), destacando la línea de ruptura.
     3) Contrato de interfaz o aserción incumplida.
     4) Archivo y línea específica a corregir.
   - Qwen no recibe el visto bueno hasta que el reporte de fallo esté resuelto limpiamente.
4. **Criterio de aceptación técnica:** Se otorga únicamente cuando la suite completa aplicable devuelve código de salida `0`, con salida reproducible y sin violaciones de contrato.

---

## 3. Contratos Técnicos de los Puntos Bajo Titularidad Directa de AGY

### 3.1. Punto 1.1.2.1 — Ataques y defensa verificados
- **Dueño:** AGY | **Revisor:** Claude | **Dependencia:** 1.1.1.3 (Cazas Bf109/Fw190 integrados).
- **Meta futura:** Verificar que las oleadas de cazas interceptores (Bf109 / Fw190) realizan aproximación, ataque, quiebre y reposicionamiento con trayectorias físicamente coherentes, que el fuego defensivo del B17 inflige daño efectivo derribando enemigos, y que el combate produce bajas registradas en debriefing.
- **Entradas:** Escena de combate con cazas integrados, `core/combat_manager.gd`, `core/fighter_ai.gd`, `visuals/tracer_pool.gd`, `visuals/fighter.gd`.
- **Archivos propietarios / de verificación:**
  - `godot/B17/tests/test_claude_batch.gd` (bloque `test_fighter_ai` y `test_tracers`).
  - `godot/B17/tests/test_release_acceptance.gd` (paso 4: combate de cazas y defensas).
  - `godot/B17/tests/test_claude_review.gd` (sección 4: avistamiento de cazas en frustum de cámara a menos de 1500m).
- **Contratos públicos a conservar:**
  - `fighter_ai.gd`: campos `position: Vector3`, `velocity: Vector3`, `state: String`, `side: float`; métodos `setup()`, `step(delta, bomber_pos)`, `is_attacking() -> bool`.
  - Estados obligatorios alcanzados por la IA: `APPROACH`, `ATTACK`, `BREAK`, `REPOSITION`.
  - `combat_manager.gd`: `active_wave`, `total_kills`, `enemy_shots`, `defensive_shots`, `step(...)`.
- **Riesgos concretos:** Cazas atascados en NaN/Inf al cruzar la formación; disparos sin origen/destino válidos; cazas invisibles o que no entran en el cono de visión de la cámara de persecución/artillero.
- **Criterios de aceptación verificables:**
  - Cazas completan los 4 estados sin NaN ni saltos anómalos.
  - Al menos 1 baja de caza enemigo acreditada por fuego defensivo durante la aproximación.
  - Trazadoras visibles y trazables en `tracer_pool` tanto para fuego ofensivo como defensivo.
  - Código de retorno `0` en la verificación reproducible.

---

### 3.2. Punto 1.1.2.2 — Daño independiente en 4 motores
- **Dueño:** AGY | **Revisor:** Codex Entrega | **Dependencia:** 1.1.1.1 (B17 texturizado jugador).
- **Meta futura:** Validar que los 4 motores del B17 registran salud individual (0-100%), que el daño aplicado a un índice no degrada los motores sanos no impactados, que el empuje global responde a la degradación acumulada (`thrust_factor()`), y que cada motor humea de forma independiente según su propia salud.
- **Entradas:** `core/damage.gd`, `visuals/engine_smoke_trail.gd`, modelo de avión con nodos de rotor/escapes vinculados.
- **Archivos propietarios / de verificación:**
  - `godot/B17/core/damage.gd`
  - `godot/B17/visuals/engine_smoke_trail.gd`
  - `godot/B17/tests/test_long_mission.gd` (verificación de daños por flak y derribo terminal).
  - `godot/B17/tests/test_release_acceptance.gd` (daños modulares y reducción de velocidad).
- **Contratos públicos a conservar:**
  - `damage.gd`: `hull: float`, `engines: PackedFloat32Array` (tamaño 4), `engine: float` (propiedad computada con la media de los 4), `apply_damage(amount: float, engine_index: int = -1)`, `thrust_factor() -> float`, `destroyed() -> bool`.
  - `engine_smoke_trail.gd`: `from_engine_health(health: float)`. Con salud 100% no emite partículas; con salud < 40% emite humo denso proporcional.
  - Reset íntegro: `sim.damage.reset()` restaura `hull = 100.0` y `engines = [100.0, 100.0, 100.0, 100.0]`.
- **Riesgos concretos:** Daño generalizado que afecte a todos los motores por igual; índices fuera de rango (índice < 0 o > 3); pérdida de sincronía entre el valor de salud y las partículas visuales de humo.
- **Criterios de aceptación verificables:**
  - Afectación de motor 0, 1, 2 o 3 de manera aislada sin alterar los restantes.
  - Reducción medible del empuje (`thrust_factor() = 0.6 + 0.4 * engine / 100.0`).
  - Las 4 estelas de humo responden visualmente a los índices respectivos en sus posiciones alares (`[-9.4, -4.4, 4.4, 9.4]`).

---

### 3.3. Punto 1.1.3.1 — Misión manual completa
- **Dueño:** AGY | **Revisor:** Codex Entrega | **Dependencia:** Fases 1 y 2.
- **Meta futura:** Demostrar que un jugador humano puede completar íntegramente la misión (despegue/formación, aproximación bajo ataque, cambio a estación de bombardero, apuntado y suelta manual de bomba con impacto en el blanco, y retorno a base) sin recurrir al piloto automático y sin atajos que fuercen variables de estado.
- **Entradas:** `godot/B17/game.tscn`, `core/player_controls.gd`, eventos reales de `Input.parse_input_event`.
- **Archivos propietarios / de verificación:**
  - `godot/B17/tests/test_manual_mission_claude.gd`
- **Contratos públicos a conservar:**
  - Control por teclado: `KEY_TAB` conmuta piloto automático; `KEY_1`, `KEY_2`, `KEY_3` conmutan `PILOTO`, `ARTILLERO`, `BOMBARDERO`.
  - Controles de vuelo: `W`/`S` (cabeceo), `A`/`D` (guiñada/alabeo), `KEY_SPACE` / `KEY_B` (suelta de bomba balística).
  - `sim.autopilot == false` durante todo el recorrido manual.
- **Riesgos concretos:** Inestabilidad de la física en giros manuales continuados; colisión o imposibilidad de alcanzar el objetivo dentro de la ventana cinemática; fallo de desprendimiento de la bomba en la estación `BOMBARDERO`.
- **Criterios de aceptación verificables:**
  - Misión alcanza estado final `COMPLETADA`.
  - Comprobación explícita de `turned == true` (giros provocados por eventos de teclado reales).
  - Comprobación de `released == true` y `sim.bomb.result == "IMPACTO"` mediante cálculo balístico físico.
  - Integridad estructural final con `sim.damage.hull > 0` y tiempo de misión reportado en el debriefing.

---

### 3.4. Punto 1.1.3.2 — Victoria, derrota, pausa, reset
- **Dueño:** AGY | **Revisor:** Claude | **Dependencia:** Fase 2.
- **Meta futura:** Verificar los estados terminales de la máquina de estados de la misión y el flujo de control: victoria al aterrizar/retornar tras bombardeo exitoso, derrota por derribo (casco a 0) o fallo en el bombardeo (bomba fuera de objetivo), pausa total del mundo y motores, y reset limpio sin fugas ni estados residuales.
- **Entradas:** `core/mission.gd`, `core/simulation.gd`, `game.gd`, `ui/mission_overlay.gd`.
- **Archivos propietarios / de verificación:**
  - `godot/B17/tests/test_scene_mission.gd`
  - `godot/B17/tests/test_long_mission.gd`
- **Contratos públicos a conservar:**
  - Transición completa por las 5 fases de misión: `FORMACION` → `APROXIMACION` → `BOMBARDEO` → `REGRESO` → `COMPLETADA`.
  - Pausa: `sim.paused = true` detiene el avance del reloj de simulación, la posición del avión y apaga el procesamiento de los motores (`$Aircraft/Engines.is_processing() == false`).
  - Reset: `scene.restart_mission()` restablece tiempo a 0, casco a 100, motores a 100, oculta visuales de bombas/impactos y limpia trazadoras.
  - Derrota explícita: overlay muestra `"DERRIBO"` al agotarse el casco, o `"FALLO"` si la bomba no da en el blanco.
- **Riesgos concretos:** Congelación residual de nodos tras reset; audio que continúa reproduciéndose en pausa; partículas de explosión que no se reinicializan.
- **Criterios de aceptación verificables:**
  - Demostración de las dos condiciones de derrota (`DERRIBO` y `FALLO`) con mensajes correctos en HUD.
  - Inmovilidad rigurosa de coordenadas y reloj durante pausa (0.0 avance en 120 frames).
  - Reinicio perfecto validado por `test_scene_mission.gd` con código de salida `0`.

---

### 3.5. Punto 1.1.3.3 — Regresión tras integración
- **Dueño:** AGY | **Revisor:** Codex Entrega | **Dependencia:** Fases 1 y 2 integradas.
- **Meta futura:** Ejecución integral de la suite completa de tests automatizados sobre el candidato integrado con modelos GLB reales, garantizando que la incorporación de mallas, texturas y hélices no alteró la lógica matemática del núcleo ni introdujo regresiones de rendimiento o fugas de memoria.
- **Entradas:** Candidato congelado por el supervisor con todos los cambios de Qwen y Claude.
- **Batería de tests exigida:**
  1. `godot/B17/tests/test_aircraft_models_claude.gd` (escala, orientación morro -Z, 4 rotores en B17, 1 en cazas, texturas).
  2. `godot/B17/tests/test_formation_six.gd` (6 bombarderos, nodo `Engines` en los 5 wingmen).
  3. `godot/B17/tests/test_claude_batch.gd` (ranuras de formación, IA de cazas, trazadoras, materiales y nodos).
  4. `godot/B17/tests/test_claude_review.gd` (ausencia de esferas negras, audio cuádruple, visibilidad de cazas y retículas).
  5. `godot/B17/tests/test_long_mission.gd` (determinismo a 30Hz, 60Hz y 120Hz).
  6. `godot/B17/tests/test_scene_mission.gd` (sincronía exacta entre escena y simulación matemática).
  7. `godot/B17/tests/test_qwen_assets.gd` (contratos funcionales de los 10 módulos).
  8. `godot/B17/tests/test_manual_mission_claude.gd` (completitud manual).
  9. `godot/B17/tests/test_release_acceptance.gd` (suite de aceptación final).
- **Riesgos concretos:** Fuga de memoria (`ObjectDB instances leaked`) detectada previamente en `test_claude_review.gd`; caída de framerate al instanciar múltiples mallas GLB pesadas.
- **Criterios de aceptación verificables:**
  - Código de salida `0` en el 100% de la batería.
  - Cero advertencias críticas de fugas de nodos u objetos ObjectDB al salir.
  - Trazabilidad y volcado de salida íntegra en el log de QA.

---

### 3.6. Punto 1.1.4.3 — Prueba Windows y ROG Ally X física
- **Dueño:** AGY | **Revisor:** Codex Entrega | **Dependencia:** Paquete Windows exportado (1.1.4.1) + instrucciones (1.1.4.2) + hardware físico disponible.
- **Meta futura:** Realizar la validación funcional, ergonómica y de rendimiento del paquete ejecutable `AuroraSobreEuropa.exe` en un PC Windows nativo y en el dispositivo portátil ASUS ROG Ally X físico.
- **Entradas:** Artefacto `build/windows/AuroraSobreEuropa.exe`, PCK embebido o paquete de entrega, hoja de instrucciones de control de Claude.
- **Comprobaciones manuales en hardware físico (Protocolo de Ensayo):**
  1. **Arranque y ventana:** Inicialización en Windows x86_64 sin dependencias ausentes; arranque a pantalla completa y en ventana 1280×720 / 1080p nativa en ROG Ally X.
  2. **Controles de mando (ASUS ROG Ally X):**
     - Stick izquierdo: cabeceo y alabeo del B17 con filtro de zona muerta `0.15` (comprobando ausencia de *stick drift* en reposo).
     - Gatillos analógicos (LT / RT): aceleración y frenado / modulación de potencia de motores.
     - D-Pad: conmutación de puestos (Arriba = PILOTO, Derecha = ARTILLERO, Abajo = BOMBARDERO).
     - Botón Start: pausa y reanudación limpia de la simulación.
     - Botón Back / View: alternancia manual / piloto automático.
     - Stick derecho: puntería de la torreta en puesto ARTILLERO.
     - Gatillo RB / Botón A/B: disparo de ametralladoras y suelta balística de la bomba.
  3. **Rendimiento térmico y framerate:**
     - Perfil de energía 15W (Performance) y 25W (Turbo) en Armoury Crate.
     - Tasa de cuadros estable: mínimo 60 FPS continuos en 720p/1080p Forward+ con MSAA 2x.
  4. **Audio y visualización:**
     - Sonido estéreo limpio sin chasquidos por *buffer underrun*.
     - Legibilidad de textos y HUD en pantalla de 7 pulgadas a 1080p.
- **Riesgos concretos y tratamiento de dependencias:**
  - Si la máquina Windows o la ROG Ally X física no están disponibles en el momento de la prueba, este punto queda formalmente categorizado como **`BLOQUEADO_DESTINO`**.
  - **REGLA DE ORO:** Bajo ningún concepto se sustituirá la prueba física por un emulador Wine/Proton, ni por mocks en Linux, ni se declarará "PASS" en Windows/Ally sin haberlo corrido físicamente en dichos entornos.
- **Criterios de aceptación verificables:**
  - Acta de prueba manual firmada por el tester detallando: versión de Windows, driver gráfico, perfil de energía, FPS medios/mínimos y verificación de cada control físico.

---

### 3.7. Punto 1.1.5.3 — Registro de cierre y pendientes
- **Dueño:** AGY | **Revisor:** Claude | **Dependencia:** Cierre de evidencias de fases 1 a 5.
- **Meta futura:** Consolidar el informe técnico final de verificación, reuniendo los identificadores SHA256 de los artefactos probados, la matriz de resultados de cada test, la lista exhaustiva de bugs corregidos y los ítems pendientes o limitaciones conocidas para futuras versiones.
- **Entradas:** Logs de ejecución de AGY, Qwen, Claude y Codex Entrega; manifiesto de entrega; actas de prueba de destino.
- **Archivos propietarios / de salida:**
  - `planning/orquestacion/REGISTRO_CIERRE_FASE1.md` (o documento de auditoría acordado con el supervisor).
- **Contratos públicos a conservar:** Estructura de trazabilidad ISO y referencias cruzadas con los 20 puntos del `TABLERO.md`.
- **Riesgos concretos:** Dejar riesgos abiertos sin documentar; discrepancias entre los hashes del paquete y las fuentes probadas.
- **Criterios de aceptación verificables:**
  - Validación cruzada y aprobación por parte de Claude y el Supervisor.
  - Documentación explícita de cualquier limitación remanente (ej. pruebas de hardware que queden diferidas por falta de dispositivo).

---

## 4. Criterios de Revisión Asignados a AGY (Puntos de Otros Agentes)

Como revisor técnico asignado en el `TABLERO.md`, AGY aplicará los siguientes criterios estrictos antes de aprobar las entregas ajenas:

| Punto | Entregable | Dueño | Criterio de Aprobación de AGY |
|---|---|---|---|
| **1.1.1.2** | Cinco compañeros texturizados | Qwen | Verificar que `formation.gd` instancia 5 bombarderos usando los modelos reales texturizados; que cada wingman expone el nodo `Engines`; que `formation.follow()` no genera saltos; y que `test_formation_six.gd` pasa al 100%. |
| **1.1.1.4** | Escala, orientación, hélices | Claude | Verificar que las envergaduras coincidan con la tolerancia (<3% error) en `test_aircraft_models_claude.gd`; que el morro apunte estrictamente a -Z; que los nodos de hélice se llamen `Rotor_*` y giren en `_process`. |
| **1.1.2.3** | Tres cámaras revisadas | Claude | Comprobar que la cámara de Piloto (persecución) mantiene despeje >25m; que la de Artillero se ubica a <12m del centro con rotación libre y retícula centrada; y que la de Bombardero tiene inclinación hacia abajo (-78°) con retícula Norden centrada (`test_claude_review.gd`). |
| **1.1.4.1** | Exportación Windows actualizada | Codex Entrega | Comprobar que el ejecutable `AuroraSobreEuropa.exe` y su PCK embebido coincidan con el SHA256 del candidato que pasó QA; que incluya todos los recursos de arte; y que no empaquete archivos de prueba espurios que inflen el binario. |
| **1.1.4.4** | Ajustes rendimiento/mando/UI | Qwen | Verificar que las curvas analógicas mantengan zona muerta `0.15`; que la tasa de refresco sea estable a 60 y 120 FPS; y que no se produzcan allocations masivas por frame que disparen el Garbage Collector o pausas en el hilo de render. |
| **1.1.5.2** | Versión estable y respaldo | Codex Entrega | Comprobar la reproducibilidad del respaldo: restauración en directorio limpio, verificación de integridad SHA256 de todas las fuentes y comprobación de que el proyecto abre sin rutas absolutas rotas. |
| **1.1.5.4** | Opciones siguiente misión | Claude | Verificar que las propuestas técnicas para la siguiente misión respeten la arquitectura del motor y no requieran dependencias externas no autorizadas; el dictamen final corresponderá al usuario. |

---

## 5. Matriz de Dependencias y Bloqueos Identificados

1. **Bloqueo de código y pruebas:** En esta fase de planificación, la ejecución de tests automatizados y la modificación de scripts de juego está congelada. Los contratos aquí descritos se aplicarán en la fase de ejecución cuando el usuario ordene el cambio de fase.
2. **Dependencia de modelos texturizados (Fase 1):** Los puntos de combate (1.1.2.1) y daño de motores (1.1.2.2) dependen de que Qwen y Claude cierren la integración de mallas texturizadas y verificación visual sin alterar las jerarquías de nodos requeridas por el núcleo.
3. **Bloqueo potencial de Hardware Destino (`BLOQUEADO_DESTINO`):** El punto 1.1.4.3 quedará supeditado a la disponibilidad física del equipo Windows y la consola ROG Ally X. No se declarará cerrado en base a simulaciones.
4. **Resolución de fuga histórica de memoria:** Se establece como requisito previo a la aceptación de release la investigación y erradicación del warning de 4 instancias ObjectDB filtradas detectado en `test_claude_review.gd`.

---

## 6. Conclusión y Siguiente Hito Solicitado
AGY deja completado su contrato técnico y protocolo de coordinación con total trazabilidad. Se solicita al Supervisor del hilo principal la revisión de este contrato junto con los de Qwen, Claude y Codex Entrega para proceder a la consolidación del plan global de ejecución.
