# Revisión baseline (pre-integración) — Claude

- Hora real de redacción: 2026-10-24T09:28:15-07:00. Máquina: esta Linux, NVIDIA GeForce RTX 2060 SUPER (driver 595.99.02), Godot 4.7.2-stable (tools/godot).
- Candidato: árbol actual SIN integrar GLB (aircraft.gd/fighter.gd procedurales). Manifiesto: `logs/revision_claude/20261024T162458Z-baseline/manifest_sha256.txt` (game.gd 6eb407b9…, aircraft.gd 7a7a5fe1…, b17g.glb 1bd4454b…).
- Esto NO revisa el hito 1. `HITO1_LISTO_PARA_REVISION.md` no existe. Las capturas son de referencia "antes" del juego procedural; no acreditan modelos integrados.
- Entradas sintéticas (Input.parse_input_event / llamadas directas); no es sesión humana.

## 1. Medición de los GLB (recurso, solo lectura) — `logs/revision_claude/20261024T162458Z-baseline/glb_medidas.json`

| Modelo | Envergadura | Longitud (sin rotores) | Morro z | Rotores (x, z) | Ø hélice | Mallas/rotor |
|---|---|---|---|---|---|---|
| b17g | 31,62 | 22,66 | −11,33 | R0(−7,73,−7,87) R1(+7,73,−7,87) R2(−3,80,−8,07) R3(+3,80,−8,07) | 2,59 | 7 (buje+3 palas+3 puntas) |
| bf109g | 9,92 | 9,02 | −4,51 | R0(0,−4,56) | 2,86 | 7 |
| fw190a | 10,50 | 8,95 | −4,47 | R0(0,−4,53) | 3,03 | 7 |
| p51d | 11,28 | 9,83 | −4,91 | R0(0,−4,97) | 3,61 | 9 |

Rotores: escala 1, sin rotación, eje Z local paralelo al longitudinal (0,0°). Material texturizado: atlas `*__albedo.png`, metálico 0,35, rugosidad 0,55, **cull=DISABLED**. Sin textura: góndolas gris (0,62), palas negras, puntas amarillas.

**Orden físico B-17 (izq.→der.) = Rotor_0, Rotor_2, Rotor_3, Rotor_1 → engines[0..3].** Queda confirmado en el recurso que el sufijo no es el orden (H-04).

## 2. Hallazgos reproducidos en el baseline

| ID | Resultado | Evidencia | Sev. V1 local | Dueño de la corrección |
|---|---|---|---|---|
| H-01 | **REPRODUCIDO en recurso.** El punto de la cámara BOMBARDERO (0,−0,8,−9,5) queda dentro de la sección del fuselaje del GLB (y∈[−1,51,0,95], semiancho 1,36). Con cull DISABLED se verá el interior. El baseline procedural no lo sufre (06_puesto_bombardero.png correcto). | `logs/revision_claude/20261024T162458Z-baseline/fuselaje_secciones.txt` | S1 tras integrar | Qwen vía Agy |
| H-02 | **CONFIRMADO en recurso.** Humo/motores en ±4,4/±9,4; góndolas GLB en ±3,80/±7,73: error de 0,60 y 1,67 m. | glb_medidas.json; game.gd `eng_offsets` | S2 | Qwen |
| H-03 | **MEDIDO.** El Ø de la hélice del B-17 es 2,59 m, frente a la referencia de 3,53 m (−27 %). Cazas dentro de ±10 % (Bf −5 %, Fw −8 %, P-51 +6 %). Se reclasifica como **S3** para V1 local (cosmético, no bloquea). Si se corrige, debe ser escalando de forma uniforme ≤1,36 los nodos Rotor_* del B-17 en la integración; a esa escala no hay solape entre rotores (3,93 m > 2×1,76 m). | glb_medidas.json | S3 | Qwen (opcional) |
| H-04 | **CONFIRMADO en recurso** (ver §1). Si se mapea por sufijo, el daño cae en el motor equivocado. | glb_medidas.json | S1 si se usa sufijo | Qwen |
| H-05 | **REPRODUCIDO.** Ángulo entre el disparo y el −Z de la cámara del artillero: 0° solo con yaw=0 y aim=0; 91,7° con yaw ±0,8 y aim=0; peor caso 140,6°. Con aim.y=−0,85 la cámara se limita a −20° y la bala sale a −48,7° (28,7°). | `logs/revision_claude/20261024T162458Z-baseline/repro_controles.log` | S1 | Qwen vía Agy (player_controls.gd) |
| H-06 | **REPRODUCIDO.** Con D mantenido 3 s: yaw +0,94 rad, rumbo 000→306°, avance lateral −0,81 (izquierda). D gira a la izquierda. | `logs/revision_claude/20261024T162458Z-baseline/repro_controles.log` | S1 | Qwen vía Agy (flight/controls) |
| H-08 | **PRESENTE.** Corte vertical del terreno en x≈640 y artefactos triangulares en el centro (C01, C03). | `logs/revision_claude/20261024T162458Z-baseline/zoom_H08_c01.png`, capturas_1280/03_cazas.png | S2 | Qwen (farmland.gdshader/UV) |
| H-11 | **REPRODUCIDO.** Escena principal headless, 600 frames: «2 ObjectDB instances leaked» (AudioStreamWAV + AudioStreamPlaybackWAV). También aparece al salir de capture_mission_claude.gd. | `logs/revision_claude/20261024T162458Z-baseline/objectdb_main_verbose.log`, capturas_1280.log | S2 | Qwen vía Agy |
| H-12 | Reinicio solo con R de teclado. En V1 local el teclado basta. | game.gd `_unhandled_input` | DIFERIDO_POST_V1 | — |
| H-13 (nuevo) | El HUD de inicio muestra «ROG Ally X: Stick Izq Vuelo…». La V1 local no debe prometer controles de Ally. | capturas_1280/01_inicio.png | S3 | Qwen (ui) |
| — | C02 «cazas» (t=53 s, 2 vivos): no hay ningún caza identificable en el encuadre de persecución. Se revisará con los GLB (criterio 1.1.1.3). | 03_cazas.png | observación | — |

Baseline de encuadre K1: B-17 del jugador ≈ 360 px / 1280 = 28 % (dentro de 18–35 %). Los compañeros traseros quedan cortados por las esquinas inferiores y el HUD.

## 3. Umbrales locales FIJADOS (sustituyen a las propuestas de ENTREGA_CLAUDE §3; Windows/Ally fuera)

Los valores se apoyan en las medidas de §1. Pueden convertirse en pruebas. La autoría de las pruebas la decide Agy/supervisor; la prueba independiente de Codex no se toca.

**1.1.1.4 Modelos**
- O1: envergadura en escena (transformación global) a ±3 % del GLB medido (31,62 / 9,92 / 10,50); longitud a ±5 %; escala uniforme (|sx−sy|,|sy−sz| < 0,001).
- O2: todos los Rotor_* con z < 0 y Fin con z > 0 en el espacio del avión.
- O3: ángulo entre el −Z global del modelo y la dirección de avance ≤ 3° (jugador y compañeros) y ≤ 8° (cazas vivos), en 10 muestras de la demo.
- O4: B-17 con 4 rotores y cazas con 1 cada uno, de 7 mallas (buje + 3 + 3). Eje ≤ 5°. Sin geometría procedural duplicada (Body/Wings/Nacelle procedurales ausentes). Ø de los cazas a ±10 %; Ø del B-17 informativo (H-03, S3).
- O5: engines[i] ↔ rotor i-ésimo por x ascendente (B-17: R0,R2,R3,R1). Emisor de humo a ≤ 0,5 m en x del rotor de su índice y con z entre el rotor (−8,1) y el borde de salida del ala. Si se daña un único motor, solo humea ese índice. Las posiciones deben derivarse de los nodos, no de constantes.
- O6: con la simulación activa, cada rotor avanza ≥ 10 rad/s (Δ envuelto en 2π). En pausa y en COMPLETADA/FALLIDA, Δ envuelto < 1e-4 rad en 30 frames.
- O7: las superficies de Fuselage/Wing*/Tailplane*/Fin tienen albedo_texture. Revisión visual en capturas M: sin relleno gris del atlas visible en la silueta (≤ 2 % de los píxeles del avión, inspección marcada).
- O8: 6 bombarderos (Engines en cada uno), ≥ 3 compañeros visibles en persecución, separación cámara > 25 m y distancia mínima entre AABB de bombarderos > 2 m.

**1.1.2.3 Cámaras** (1280×720 y 1920×1080 en este monitor)
- K1: el B-17 del jugador ocupa 18–35 % del ancho, con su centro en el tercio central y el horizonte visible.
- K2: cámara de artillero ≥ 0,6 m sobre el techo del GLB (baseline 1,57 m ⇒ se espera PASS). **Alineación angular entre disparo y −Z de la cámara ≤ 1,5°** para yaw ∈ {0, ±0,8} y aim ∈ {(0,0), (±0,6,0,3), (0, mín), (0, máx)}. El límite de pitch de aim es igual al de la cámara.
- K3: la cámara BOMBARDERO está fuera de la sección del fuselaje del GLB (`tools_review/fuselage_slice_claude.gd`), o el avión propio queda oculto mediante capas/cull_mask. Sin geometría propia dentro del círculo de la Norden y suelo ≥ 90 % del círculo en fase BOMBARDEO. dir.y ≤ −0,7.
- K4: al cambiar 1/2/3 no hay cámara dentro de geometría ni queda la retícula del puesto anterior (prueba existente + captura del frame siguiente).
- K5: a 1920×1080 se cumple K1–K4 y el HUD es legible.
- K6: con D mantenido 3 s, el rumbo del HUD aumenta y el desplazamiento lateral es a la derecha (A, simétrico).
- K7 (H-11): 0 «ObjectDB instances leaked» en la escena principal (headless --verbose, 600 frames) y en el script de capturas.

## 4. Herramientas de revisión (Claude, fuera del juego, no exportadas)
- `tools_review/measure_glb_claude.gd`: medidas de los GLB.
- `tools_review/fuselage_slice_claude.gd`: punto respecto a la sección del fuselaje.
- `tools_review/repro_controls_claude.gd`: H-05/H-06 sintéticos.
- Capturas GPU con la herramienta existente `godot/B17/tests/capture_mission_claude.gd` (rc=0, 10 PNG, 6 s, Vulkan Forward+ RTX 2060 SUPER).

## 5. Pruebas propias en el baseline
- test_claude_batch PASS · test_claude_review PASS · test_aircraft_models_claude PASS (logs en `logs/revision_claude/20261024T162458Z-baseline/`).
- Cambio en una prueba propia: `test_claude_batch.gd:126`, a petición de Codex (COORDINACION_CODEX_ENTREGA.md). Antes exigía exactamente 4 hijos (procedural); ahora exige «≥ 4 mallas (buje + ≥ 3 palas)» y sigue comprobando que la hélice gira. Es válido para el rotor GLB real (7) y no debilita la verificación de origen GLB, que pertenece a la prueba de Codex.

## 6. 1.1.4.2 LOCAL — preparación
Depende de 1.1.4.1 (Codex): id del candidato y lanzador. Existe `INICIAR_B17.sh` en la raíz (se revisará). La tabla de controles se derivará línea a línea del candidato que se acepte, porque H-06/H-05 cambiarán los controles. LEEME irá en release/<id>/LEEME.md y .txt, solo teclado/ratón y esta Linux. Windows/Ally aparecerán como «no probado, posterior a V1».
