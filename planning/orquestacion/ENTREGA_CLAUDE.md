# Entrega — Claude: contrato técnico de revisión visual, arte y documentación

- Fecha: 2026-10-24T09:20-07:00 (aprox.; sin reloj del sistema en esta sesión).
- Puntos: 1.1.1.4, 1.1.2.3, 1.1.3.4 (revisión), 1.1.4.2, 1.1.5.4 (propuesta; decide el usuario).
- Fase: PLANIFICACIÓN. Esta entrega es documental. No se ejecutó Godot, ni pruebas, ni capturas nuevas, ni generaciones de arte; no se modificó ningún .gd/.tscn/.glb/shader. Las herramientas de esta sesión fueron Read/Write/Edit/Glob/Grep (sin shell).
- Nada de lo escrito aquí equivale a un punto verificado. Los valores «medidos» proceden de leer código y documentos; los que exigen render quedan como evidencia futura.

---

## 1. Estado constatado (lectura de archivos, 2026-10-24)

| # | Hecho | Fuente |
|---|---|---|
| E1 | El juego usa aviones **procedurales**: `aircraft.gd` instancia `visuals/body.gd`, `wings.gd`, `engines.gd`. Los `.glb` solo se cargan en una prueba. | `godot/B17/aircraft.gd:4-12`; Grep de `.glb` en `godot/B17` |
| E2 | Existen 4 GLB construidos por Claude con `tools_art/loft_aircraft.gd` (plan B sin Meshy): `b17g`, `bf109g`, `fw190a`, `p51d` + `__albedo.png`. Origen y proceso documentados. | `godot/B17/assets/SOURCES.md:14`; `planning/AVANCE_CLAUDE.md:58-64` |
| E3 | Convención de los GLB: x lateral (+derecha), y arriba, **morro hacia −Z**, origen en la mitad de la longitud del fuselaje. | `tools_art/loft_aircraft.gd:143`, `:277` |
| E4 | Rotores de los GLB: nodos `Rotor_N`; giran sobre su **Z local** (palas en el plano XY). El B-17 tiene `Rotor_0..3`, numerados por orden de detección de góndolas, **no** de izquierda a derecha. | `loft_aircraft.gd:242-246`, `:477-488`, `:502-521` |
| E5 | Material de los GLB: un atlas 2048² proyectado (lateral/planta), metálico 0.35, rugosidad 0.55, **`CULL_DISABLED`** (se ven las caras interiores). Las góndolas usan un gris liso sin textura. | `loft_aircraft.gd:251-259`, `:491-500` |
| E6 | Góndolas medidas en el GLB del B-17: x ≈ ±3,8 y ±7,7 m. El juego coloca motores/humo en x = ±4,4 y ±9,4. | `AVANCE_CLAUDE.md:61`; `visuals/engines.gd:8`; `game.gd:233-237` |
| E7 | Diámetro de hélice que deriva del loft: B-17 ≈ 2,88 m (r_góndola = 0,024·env; radio = r·1,9); cazas ≈ 0,32·envergadura (Bf 109 ≈ 3,17 m; Fw 190 ≈ 3,36 m; P-51D ≈ 3,61 m). Valores calculados a partir del código; **no medidos** en el GLB. | `loft_aircraft.gd:244`, `:246`, `:488` |
| E8 | La prueba actual de modelos solo comprueba envergadura (±3 %), número de rotores y que haya textura. **No** comprueba longitud, orientación, posición/eje de rotores ni número de palas. | `tests/test_aircraft_models_claude.gd:9-29` |
| E9 | Hay tres puestos de cámara más la cámara de bomba en un único `Camera3D`: persecución `(0,22,115)` mirando 20 m por delante; ARTILLERO en `(0,2.8,−1.8)` con yaw+aim y pitch limitado a [−20°, 85°]; BOMBARDERO en `(0,−0.8,−9.5)` con pitch −78°; bomba `+ (60,110,85)`. FOV 65°, near 0,5, far 18 000. | `game.gd:35-37`, `:256-272` |
| E10 | El avión no se alabea al girar: `rotation = (pitch, yaw, 0)`, también en los compañeros. | `game.gd:226`; `formation.gd:21` |
| E11 | `fire()` calcula la dirección como `(sin(yaw), …, −cos(yaw))`, mientras que el vuelo y la cámara usan el −Z de Godot girado, que es `(−sin(yaw), …, −cos(yaw))`. Con yaw ≠ 0 las balas del jugador salen **reflejadas en X** respecto a lo que ve la cámara. Además, `aim.y` permite bajar hasta −0,85 rad (−48,7°) y la cámara se para en −20°. | `core/player_controls.gd:35-37`, `:85`, `:133`; `core/flight.gd:19`; `game.gd:263-265` |
| E12 | Deducción estática que hay que confirmar: D/derecha → `turn_input = +1` → `yaw` aumenta → el morro gira hacia −X, es decir, **a la izquierda**. El rumbo del HUD también disminuye. | `player_controls.gd:116`; `core/flight.gd:16,19`; `game.gd:302` |
| E13 | Contratos de los que dependen el juego y las pruebas: hijo `Engines` en cada bombardero (`set_process` en pausa; la prueba cuenta bombarderos por `Engines`), 6 bombarderos, ≥3 compañeros visibles en persecución, separación cámara-bombardero > 25 m, retículas centradas. | `game.gd:228-231`; `tests/test_claude_review.gd:45-52`, `:76-81`, `:149-150`, `:162-181` |
| E14 | Las capturas disponibles están **desfasadas**: `logs/godot-final-preview.png` muestra «ESCUADRILLA AURORA», y el código actual dice «ESCUADRILLA AURORA (6 B-17)». Las capturas de las rondas 3 y 4 de `capture_mission_claude.gd` no están en `logs/`. En la vista previa, el B-17 del jugador mide unos 300 px de ancho (≈23 % de 1280), la textura es plana oliva y se aprecia una posible costura vertical del terreno en x ≈ 640. | `logs/godot-final-preview.png`; `ui/mission_overlay.gd:44` |
| E15 | Documentación de usuario: no existen instrucciones del paquete en `build/windows/` (solo `AuroraSobreEuropa.exe`). `README.md` dice que el «juego final previsto [es] en Unity», lo que está **obsoleto** (Unity cancelado). | `build/windows/`; `README.md:3`; `planning/ESTADO.md:8` |
| E16 | Mando: pausa con Start/ESC; reinicio **solo con R de teclado** (no hay botón de mando); en el mando, A/B sueltan la bomba en fase BOMBARDEO desde cualquier puesto distinto de ARTILLERO. | `game.gd:153-166`; `player_controls.gd:87-108` |
| E17 | Exportación: el preset excluye `tests/*`; el firmado está desactivado (es previsible el aviso de SmartScreen); se usa `export_console_wrapper=1`. | `godot/B17/export_presets.cfg:10,21,26` |
| E18 | Histórico: mi `AVANCE_CLAUDE.md:46` decía «primera misión jugable… verificada» (16/16 PASS). Bajo el tablero actual eso es **evidencia histórica, no aceptación**: es anterior a los GLB y no incluye Windows/Ally. | `planning/AVANCE_CLAUDE.md:45-56` |

---

## 2. Hallazgos previos a la ejecución (entradas para 1.1.3.4)

Severidad: **S1** bloquea la aceptación de fase; **S2** es un defecto visible persistente que debe corregirse o aplazar el usuario de forma explícita; **S3** es cosmético o una propuesta.

| ID | Hallazgo | Sev. | Punto afectado | Dueño de corrección propuesto | Confirmación necesaria |
|---|---|---|---|---|---|
| H-01 | Con el origen del GLB en el centro, el morro queda en z ≈ −L/2 (≈ −11,3 m si L = 22,66). La cámara BOMBARDERO en z = −9,5, y = −0,8 cae **dentro del fuselaje**, y con `CULL_DISABLED` se vería la pared interior. | S1 | 1.1.2.3 | Qwen (`game.gd`) | Captura C07 tras integrar el GLB |
| H-02 | Los offsets de motor y humo (±4,4/±9,4) no coinciden con las góndolas del GLB (±3,8/±7,7): el humo saldría 0,6–1,7 m fuera del motor. | S2 | 1.1.1.4 / 1.1.2.2 | Qwen | Medir `Rotor_*` y compararlo con los emisores |
| H-03 | Hélice del B-17 ≈ 2,88 m frente a ≈ 3,5 m de referencia (−18 %). | S2 | 1.1.1.4 | Qwen escala `Rotor_*` en la integración (recomendado); la alternativa es que Claude regenere el GLB con el loft local, sin créditos | Medir el diámetro |
| H-04 | `Rotor_N` no está ordenado por x: si se asocia a `damage.engines[N]`, el humo o la parada de hélice irían al motor equivocado. | S1 si se usa para daños | 1.1.1.4 / 1.1.2.2 | Qwen | Prueba de correspondencia (ver §3.1, O5) |
| H-05 | Disparos del artillero reflejados en X y límite inferior de pitch distinto entre `aim` y la cámara (E11). | S1 | 1.1.2.1 (Agy) y 1.1.2.3 | Qwen vía Agy | C05/C06 con trazadoras visibles |
| H-06 | Posible giro invertido con D/A y el stick (E12). | S1 si se confirma | Controles (Agy/Qwen) | Qwen vía Agy | Mantener D 3 s: el horizonte y el rumbo deben ir a la derecha |
| H-07 | Falta alabeo visual en los virajes (E10). | S3 | 1.1.3.4 | Qwen | Propuesta; decide el supervisor |
| H-08 | Posible costura vertical del terreno en el centro de la pantalla (E14). | S2 | 1.1.3.4 | Qwen (`world/farmland.gdshader` o UV) | Captura nueva C01; puede haberse corregido ya |
| H-09 | Bomba con bandas naranjas sobredimensionada en primer plano (`scale 1.5`, `game.gd:242`). | S3 | 1.1.3.4 | Qwen | C08 |
| H-10 | `README.md` obsoleto (Unity) y paquete sin instrucciones. | S2 | 1.1.4.2 | Claude | Revisión documental |
| H-11 | Aviso `ObjectDB instances leaked at exit` (histórico). | S2 | 1.1.3.3 (Agy) | Qwen vía Agy | Salida de consola del candidato |
| H-12 | No hay reinicio con el mando: en la Ally X no se puede reiniciar sin teclado. | S2 | 1.1.4.4 | Qwen | Prueba en el destino |

---

## 3. Contratos por punto

### 3.1 — 1.1.1.4 Escala, orientación y hélices

- **Dueño:** Claude (revisión). **Revisor:** Agy. **Depende de:** 1.1.1.1–1.1.1.3 integrados (Qwen).
- **Entradas:** candidato con los GLB integrados; manifiesto SHA256 de `godot/B17/**/*.gd`, `*.tscn` y `assets/aircraft/**`; salida de la prueba de modelos; capturas M01–M16 y C01–C03.
- **Salida:** `planning/orquestacion/REVISION_CLAUDE_1.1.1.4.md` con una tabla PASS/FAIL por criterio y modelo, y las rutas de evidencia.
- **Archivos que se leen (no edito):** `assets/aircraft/models/*.glb`, `aircraft.gd`, `formation.gd`, `visuals/engines.gd`, `visuals/fighter.gd`, `game.gd`, `tests/test_aircraft_models_claude.gd`.
- **Contratos públicos a conservar:** hijo `Engines` bajo cada bombardero con `set_process` (E13); 6 bombarderos; `$Aircraft` como raíz del jugador; `fighter_visuals[i]` con −Z hacia la velocidad (`game.gd:218`); índices `damage.engines[0..3]` = izquierda exterior → derecha exterior (`game.gd:233`).

**Criterios cuantificables.** Valores de referencia propuestos, que el supervisor o el usuario pueden ajustar:

| Modelo | Envergadura (m) | Longitud (m) | Hélices × palas | Ø hélice ref. (m) |
|---|---|---|---|---|
| B-17G | 31,62 | 22,66 | 4 × 3 | 3,53 |
| Bf 109G | 9,92 | 9,02 | 1 × 3 | 3,00 |
| Fw 190A | 10,51 | 8,95 | 1 × 3 | 3,30 |
| P-51D | 11,28 | 9,83 | 1 × 4 | 3,40 |

- **O1 Escala:** la envergadura medida **en escena**, con la transformación global aplicada, queda a ±3 % de la referencia; la longitud (AABB en Z sin `Rotor_*`), a ±5 %. Sin escalas no uniformes (|sx−sy|, |sy−sz| < 0,001).
- **O2 Orientación del modelo:** todos los `Rotor_*` tienen z < 0 y la deriva (`Fin`) tiene z > 0 y y máx > 0 en el espacio local del avión.
- **O3 Orientación en vuelo:** en 10 fotogramas muestreados de la demo, el ángulo entre el −Z global del modelo y la dirección de avance es ≤ 3° para el jugador y los compañeros, y ≤ 8° para los cazas vivos.
- **O4 Hélices, geometría:** número de rotores y palas según la tabla; Ø medido a ±10 % de la referencia; el eje de giro (Z local del rotor) forma ≤ 5° con el eje longitudinal; el centro del rotor está a ≤ 0,3 m del frente de su góndola o morro.
- **O5 Correspondencia de motores:** al ordenar los rotores por x ascendente se obtiene `engines[0..3]`. Los emisores de humo quedan a ≤ 0,5 m en x del rotor de su índice y entre el borde de ataque y el de salida en z. Una prueba que dañe un único motor mueve el humo y, si se implementa la parada, detiene solo ese rotor.
- **O6 Animación:** con la simulación activa, `rotation.z` de cada rotor cambia ≥ 10 rad/s; en pausa y en COMPLETADA/FALLIDA no cambia (Δ < 1e-4 en 30 fotogramas).
- **O7 Textura y material:** cada malla del fuselaje, las alas y la deriva tiene `albedo_texture`. En las capturas M, sin fondo gris del atlas sangrando en la silueta: ≤ 2 % de los píxeles del avión con el color `(0.55, 0.57, 0.55)` ± 0,03 del relleno del atlas (`loft_aircraft.gd:136`). La comprobación es visual sobre zonas marcadas y la confirma Agy.
- **O8 Formación:** con el GLB, la distancia mínima entre AABB de bombarderos es > 2 m (los offsets de `formation_slots.gd` dejan unos 6,4 m de holgura lateral con 31,6 m de envergadura). Se mantienen ≥ 3 compañeros visibles en persecución y separación > 25 m (prueba existente).
- **Prueba nueva propuesta:** ampliar la cobertura con O1, O2 y O4–O6 en una prueba **nueva** (la autoría la asigna el supervisor). La prueba existente `test_aircraft_models_claude.gd` no se debilita.

### 3.2 — 1.1.2.3 Tres cámaras revisadas

- **Dueño:** Claude. **Revisor:** Agy. **Depende de:** 1.1.1.1–1.1.1.2 integrados, H-01 y H-05 corregidos.
- **Entradas:** capturas C01–C12 a 1280×720 y 1920×1080 (resolución nativa de la pantalla de la Ally X); registro numérico de la cámara (posición, base, `station`, `aim`).
- **Salida:** `planning/orquestacion/REVISION_CLAUDE_1.1.2.3.md`.
- **Contratos a conservar:** un único `$Camera3D`; `controls.station ∈ {PILOTO, ARTILLERO, BOMBARDERO}`; retículas `gunsight_ring.png` y `bombsight_norden.png` centradas y visibles solo en su puesto; cámara de bomba > 120 m del impacto y > 80 m de altura (`test_claude_review.gd:151`).

**Criterios cuantificables:**

- **K1 Persecución:** el B-17 del jugador ocupa entre el **18 % y el 35 %** del ancho de pantalla en vuelo nivelado (actual ≈ 23 %, E14), su centro está en el tercio central y el horizonte es visible. Se mantienen ≥ 3 compañeros visibles y separación > 25 m.
- **K2 Artillero:** la posición está fuera de la malla propia, con una holgura ≥ 0,6 m sobre el techo del fuselaje en esa estación (near = 0,5). La geometría propia ocupa ≤ 35 % de la pantalla con `aim = (0,0)`. **Alineación:** la trazadora del jugador pasa a ≤ 2 % de la altura de pantalla del centro de la retícula con `aim` ∈ {(0,0), (±0,6, 0,3), (0, límite inferior)} y yaw del avión ∈ {0, ±0,8 rad}. Los límites de pitch de `aim` y de la cámara coinciden.
- **K3 Bombardero:** la cámara está fuera del fuselaje, o el avión propio queda oculto a esa cámara por capa o `cull_mask`; cualquiera de las dos implementaciones es válida. Ninguna geometría propia dentro del círculo de la mira Norden; el suelo ocupa ≥ 90 % de ese círculo en fase BOMBARDEO. La dirección de la vista tiene componente Y ≤ −0,7 (prueba existente).
- **K4 Transiciones:** al cambiar 1/2/3 o el D-pad no hay ningún fotograma con la cámara dentro de geometría ni con la retícula del puesto anterior visible (prueba existente más la captura del fotograma siguiente al cambio).
- **K5 Resolución:** a 1920×1080 se cumplen K1–K4 y la retícula y el HUD quedan centrados y legibles (texto ≥ 12 px efectivos).
- **K6 Giro:** con D mantenido 3 s en PILOTO, el rumbo del HUD aumenta y el avión gira a la derecha en pantalla (confirma o descarta H-06).

### 3.3 — 1.1.3.4 Hallazgos visuales corregidos (Claude revisa; Qwen corrige)

- **Revisor:** Codex Entrega. **Depende de:** capturas actuales del candidato.
- **Proceso por hallazgo:** se registra el ID H-NN en `REVISION_CLAUDE_1.1.3.4.md` con la captura **antes** (ruta, script, fotograma o tiempo de simulación, resolución, manifiesto SHA256), el resultado esperado medible y la severidad. Agy lo encola a Qwen como contrato pequeño. Qwen corrige sin modificar pruebas. Se toma la captura **después** con el mismo script, fotograma y resolución. Por último, Claude dictamina PASS o DEVUELTO con diferencias concretas.
- **Criterio de cierre del punto:** todos los S1 cerrados; todos los S2 cerrados o aplazados por escrito por el usuario; los S3 se listan como pendientes. Sin regresión en la suite de Agy (1.1.3.3) del mismo candidato. Si una integración posterior invalida una captura, el hallazgo se reabre.
- **Capturas no reproducibles:** si la aleatoriedad (`randf_range`, `player_controls.gd:50`) impide repetir el fotograma, se compara por fase y estado (fase, cazas vivos, `station`, `aim`) con una tolerancia de ±1 s de simulación, y se declara.

### 3.4 — 1.1.4.2 Paquete e instrucciones

- **Dueño:** Claude. **Revisor:** Codex Entrega. **Depende de:** 1.1.4.1 (exe e identificador del candidato).
- **Salidas:** un archivo `LEEME.md` en español (también como `.txt` para Windows), redactado por Claude en una ruta propia que asigne el supervisor (propuesta: `release/<id_candidato>/LEEME.md`). Codex Entrega lo copia al paquete y no lo edita. Además, una propuesta de actualización de `README.md` como texto para quien sea su dueño; no lo edito sin asignación.
- **Contenido obligatorio:**
  1. Nombre, versión o id del candidato y SHA256 del exe tomado del manifiesto de Codex.
  2. Requisitos: Windows x64 y GPU compatible con el renderizador del preset, que se constatará en la exportación.
  3. Aviso de SmartScreen por exe sin firmar.
  4. Arranque y cierre.
  5. Tabla de controles teclado/ratón/mando derivada **línea a línea** de `player_controls.gd` y `game.gd`.
  6. Pausa (ESC/Start) y reinicio (R; sin botón de mando mientras siga H-12).
  7. Fases de la misión y objetivo.
  8. Límites: qué se probó y dónde. Windows y Ally X aparecen como «no probado» salvo que exista evidencia de 1.1.4.3.
  9. Problemas conocidos (S2/S3 abiertos).
  10. Créditos y origen de recursos (`SOURCES.md`), incluido el pendiente de términos de OpenArt si se distribuye (`SOURCES.md:9`).
- **Criterios:** 0 discrepancias entre la tabla de controles y el código del candidato (lista de comprobación con referencia a cada línea). El hash coincide con el manifiesto. Agy recorre cada paso en Windows/Ally durante 1.1.4.3 y marca cada instrucción como ejecutada o fallida; solo entonces se considera validado en destino. Sin afirmaciones de rendimiento sin medición.

### 3.5 — 1.1.5.4 Opciones para la siguiente misión (propuesta; elige el usuario)

- **Revisor:** Agy. **Depende de:** primera misión estable (1.1.5.2).
- **Salida:** `planning/orquestacion/PROPUESTA_MISION2_CLAUDE.md` con 3 opciones. Para cada una: objetivo jugable, recursos reutilizados frente a nuevos (indicando si alguno exige **créditos de pago**, que necesitan autorización del usuario), archivos o sistemas afectados, riesgos, verificación y dependencia con lo pendiente en la Ally X. Sin fechas ni FPS prometidos.
- **Borrador de opciones (sin preferencia impuesta):**
  - **A. Escolta:** segunda misión con P-51D de escolta (reutiliza `p51d.glb`, ya construido) y un objetivo nuevo, como un aeródromo. Reutilización alta.
  - **B. Objetivo industrial con meteorología:** capa de nubes y flak más denso. Exige nuevos sistemas visuales y nuevo arte de terreno.
  - **C. Continuidad de tripulación:** daños y estado que persisten entre misiones y un informe ampliado. Sobre todo sistemas e interfaz, con poco arte nuevo.
- **Criterio de cierre:** el documento queda revisado por Agy y la decisión del usuario se registra por escrito. Sin esa decisión, el punto queda en espera y no se inicia nada.

---

## 4. Protocolo común de capturas (ejecución futura)

- **Ejecutor:** Agy (QA), o Claude si en la fase de ejecución dispone de shell. **Revisor visual:** Claude. Requiere render con GPU real (RTX 2060 SUPER); un render headless sin GPU no sirve.
- **Herramientas existentes:** `tests/capture_mission_claude.gd` (C) y `tools_art/inspect_glb.gd` (M; 4 vistas por modelo). Las ampliaciones que necesiten código nuevo se encargan vía Agy y Qwen.
- **Carpeta:** `logs/revision_claude/<UTC AAAAMMDDTHHMMSSZ>/` con `manifest.json` (SHA256 de las fuentes y los recursos, versión de Godot, comando, código de retorno, resolución) y las PNG numeradas.

| ID | Momento | Puntos |
|---|---|---|
| M01–M16 | 4 GLB × {frente, lado, arriba, 3/4} | 1.1.1.4 |
| C01 | Persecución, inicio (t ≈ 5 s) | 1.1.1.4, 1.1.2.3, H-08 |
| C02 | Persecución con cazas a < 1500 m | 1.1.1.3, 1.1.2.3 |
| C03 | Persecución con flak (≥ 3 ráfagas) y un motor dañado | 1.1.1.4 O5, 1.1.2.4 |
| C04–C06 | ARTILLERO: aim (0,0); (±0,6, 0,3); límite inferior, con trazadoras | 1.1.2.3 K2, H-05 |
| C07 | BOMBARDERO en fase BOMBARDEO | 1.1.2.3 K3, H-01 |
| C08–C09 | Bomba cayendo; impacto | H-09, 1.1.2.4 |
| C10–C12 | Regreso; final COMPLETADA/FALLIDA; pausa | 1.1.3.2 |
| C13 | Secuencia D mantenido 3 s (3 fotogramas) | K6, H-06 |
| R1 | Registro numérico de rotores (`rotation.z` en 30 fotogramas activos y 30 en pausa) | O6 |

Cada captura C se repite a 1280×720 y a 1920×1080. Las del dispositivo Ally X pertenecen a 1.1.4.3 y no se sustituyen por estas.

---

## 5. Criterios para los puntos donde soy revisor

| Punto | Para aprobar necesito |
|---|---|
| 1.1.1.3 | Bf 109 y Fw 190 aparecen ambos en la misión (≥ 1 de cada uno), O1–O4 y O7 cumplidos para ambos, captura C02 con un caza identificable a < 300 m. |
| 1.1.2.1 | H-05 cerrado; impactos del jugador solo dentro del cono que muestra la retícula; ataques enemigos con trazadoras visibles en C02. |
| 1.1.2.4 | VFX en los sprites `assets/vfx/flak_*` (sin esferas opacas), humo pegado al motor correcto (O5) y audio pausado en la pausa. Las capturas antes y después muestran el ajuste. |
| 1.1.3.2 | C10–C12 en las dos resoluciones; el reinicio restaura cámara, puesto, `aim`, rotores y humo; la pausa congela rotores (O6) y VFX. |
| 1.1.5.3 | Registro que separa: plan aceptado / código integrado / pruebas PASS / verificado en Linux / verificado en Windows / verificado en Ally X; los pendientes S2/S3 listados con su dueño. |

---

## 6. Conflictos de responsabilidad para el supervisor

1. `ENTREGA_QWEN.md` (1.1.1.1–1.1.1.3, 1.1.3.4) declara como archivos propios los `.glb`, cuyo autor es Claude (`SOURCES.md:14`). Para mantener un autor por archivo propongo que Qwen sea dueño de los `.gd` de integración (`aircraft.gd`, `formation.gd`, `visuals/fighter.gd`, secciones de `game.gd`) y que los `.glb` no se toquen. H-03 se corrige escalando `Rotor_*` en la integración. Si hiciera falta regenerar un GLB, lo haría Claude con el loft local, sin créditos y solo en la fase de ejecución.
2. H-05 y H-06 son de controles y combate (Agy/Qwen), aunque afectan a mi punto 1.1.2.3. Propongo que 1.1.2.3 dependa de su cierre.

## 7. Bloqueos y límites de verificación

- **B1 (dependencia):** 1.1.1.4 y 1.1.2.3 no pueden revisarse hasta que 1.1.1.1–1.1.1.3 estén integrados; los GLB hoy no están en el juego (E1).
- **B2 (evidencia):** no hay capturas vigentes del candidato actual (E14). Las primeras capturas de la ejecución tienen que regenerar el conjunto C antes de abrir hallazgos.
- **B3 (destino):** nada de este contrato valida Windows ni la Ally X. Las capturas a 1920×1080 en Linux no sustituyen a 1.1.4.3 (BLOQUEADO_DESTINO si no hay dispositivo).
- **B4 (herramientas de esta sesión):** sin shell no pude medir los GLB. E6 y E7 proceden de documentación y código y deben medirse en O1/O4.
- **B5 (decisión):** 1.1.5.4 requiere la elección del usuario. Los valores de referencia de §3.1 y el rango K1 son propuestas que el supervisor debe aprobar.

## 8. Siguiente hito solicitado

Que el supervisor revise este contrato junto a los de Agy, Qwen y Codex Entrega, resuelva los conflictos de §6, apruebe o ajuste las referencias de §3.1 y K1, y asigne la ruta del `LEEME`. No se inicia ninguna ejecución hasta que el usuario cambie la fase.
