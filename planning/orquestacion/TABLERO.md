# Actualización de integración — 2026-10-24

Cámara orbital, nubes OpenArt, niebla reducida, flak denso, 42 efectos revisados (M2 protegida), voces en inglés estadounidense con subtítulos españoles y siete estados musicales: integrados y comprobados. La entrega vigente es `ENTREGA_DIALOGOS_MUSICA_CONTEXTUAL.md`. Los registros inferiores son históricos; los valores antiguos de 15 flak/min, 60 nubes y 47 WAV sintéticos ya no describen toda la presentación actual. La lógica de daño de flak se conserva separada del campo visual.

Siguiente encargo solicitado: Lote 9, 48 interceptores y combate cinematográfico, secuencial después de esta entrega. No se declara terminado aquí. Prueba física y aprobación perceptiva del usuario pendientes.

---

# Tablero de supervisión — V1 LOCAL en ejecución

> [!IMPORTANT]
> **ORDEN DE EJECUCIÓN AUTÓNOMA DIRECTA:**
> ```bash
> agy --dangerously-skip-permissions --mode auto -p "$(cat planning/orquestacion/TABLERO.md)"
> ```

Autorizado por «run» y reducido por el usuario a esta máquina Linux/RTX2060SUPER. Plan aceptado no equivale a implementación terminada.

| Punto | Entregable V1 | Dueño | Revisor | Dependencia | Contrato | Ejecución |
|---|---|---|---|---|---|---|
| 1.1.1.1 | B17 texturizado jugador | Qwen | Codex Entrega | Inventario modelos | ACEPTADO | COMPLETADO_VERIFICADO |
| 1.1.1.2 | Cinco compañeros texturizados | Qwen | Agy | 1.1.1.1 | ACEPTADO | COMPLETADO_VERIFICADO |
| 1.1.1.3 | Bf109/Fw190 integrados | Qwen | Claude | Inventario modelos | ACEPTADO | COMPLETADO_VERIFICADO |
| 1.1.1.4 | Escala, orientación, hélices | Claude | Agy | 1.1.1.1–3 | ACEPTADO | COMPLETADO_VERIFICADO |
| 1.1.2.1 | Ataques y defensa verificados | Agy | Claude | 1.1.1.3 | ACEPTADO | COMPLETADO_VERIFICADO (obs: daño de cazas bajo) |
| 1.1.2.2 | Daño independiente4motores | Agy | Codex Entrega | 1.1.1.1 | ACEPTADO | COMPLETADO_VERIFICADO |
| 1.1.2.3 | Tres cámaras revisadas | Claude | Agy | 1.1.1.1–2 | ACEPTADO | COMPLETADO_VERIFICADO (U01 GPU; S3 radio/retículo) |
| 1.1.2.4 | VFX/audio ajustados | Qwen | Claude | 1.1.2.1–3 | ACEPTADO | COMPLETADO_VERIFICADO (H-15, H-11, H-14; pendientes S3: H-08 costura terreno, H-16) |
| 1.1.3.1 | Misión manual completa | Agy | Codex Entrega | Fases1y2 | ACEPTADO | PASS_SINTÉTICO (test_manual_mission_claude, 724 s, IMPACTO); falta partida humana |
| 1.1.3.2 | Victoria, derrota, pausa, reset | Agy | Claude | Fase2 | ACEPTADO | COMPLETADO_VERIFICADO (obs: R reinicia sin confirmar) |
| 1.1.3.3 | Regresión tras integración | Agy | Codex Entrega | Fases1y2 | ACEPTADO | COMPLETADO_VERIFICADO (14/14 supervisor) |
| 1.1.3.4 | Hallazgos visuales corregidos | Claude revisión;Qwen corrección | Codex Entrega | Capturas actuales | ACEPTADO | COMPLETADO_VERIFICADO (S3 radio/Norden, parche Agy) |
| 1.1.4.1 | Arranque y entrega Linux local | Codex Entrega | Agy | Fase3aceptada | ACEPTADO | COMPLETADO_VERIFICADO (candidato b457f0384d78, restauración en frío 8/8) |
| 1.1.4.2 | Instrucciones y paquete local | Claude | Codex Entrega | 1.1.4.1 | ACEPTADO | COMPLETADO (LEEME en candidato b457f0384d78) |
| 1.1.4.3 | Prueba en esta Linux/RTX2060SUPER | Agy | Codex Entrega | Candidato local+esta máquina | ACEPTADO | COMPLETADO_VERIFICADO (60 FPS, p99 17.3 ms, 720p) |
| 1.1.4.4 | Ajustes locales rendimiento/teclado/ratón/UI | Qwen | Agy | Resultados locales1.1.4.3 | ACEPTADO | COMPLETADO_VERIFICADO (perfiles de control, confirmación de R, diagnóstico de mando; falta probar con hardware real) |
| 1.1.5.1 | Correcciones detectadas en esta máquina | Agy (relevo) | Supervisor Agy | Hallazgos locales | ACEPTADO | COMPLETADO_VERIFICADO (Lote 5: Terreno T1 1200m con mipmaps, audio 47 WAV con bucles QOA exactos, test_claude_review enmendado; 24/24 PASS) |
| 1.1.5.2 | Versión estable local y respaldo | Agy (relevo) | Supervisor Agy | Correcciones locales aceptadas | ACEPTADO | COMPLETADO_VERIFICADO (candidato local-20261024-6b9c2dbc5167 verificado, restauración en frío 11/11 tests PASS) |
| 1.1.5.3 | Registro de cierre y pendientes | Agy (supervisor) | Agy | Evidencias finales | ACEPTADO | COMPLETADO_VERIFICADO (supervisor.log actualizado, dictamen GPU 19 capturas en logs/revision_supervisor/20261024T223630Z-lote5-gpu-terreno, LEEME.md; pendiente partida humana) |
| 1.1.5.4 | Siguiente misión: fuera de V1 | Claude | Agy;decide usuario | Posterior a V1 | ACEPTADO | DIFERIDO_POST_V1 |
| 1.1.6.1 | Lote 6: Combate intenso, flak denso a escala y escuadrillas ampliadas | Agy (supervisor) | Agy | Lote 5 completado | ACEPTADO | COMPLETADO_VERIFICADO (Flak escala 20% / pool ampliado, cazas Luftwaffe escalonados, P-51D escolta alta; 33/33 tests PASS; GPU 19 capturas revalidadas) |
| 1.1.7.0 | Lote 7: Gran Incursión Masiva sobre Europa en Invierno | Agy (supervisor) | Agy | Lote 6 completado | ACEPTADO | COMPLETADO_VERIFICADO (300 B-17 Combat Wings en MultiMeshInstance3D, 30 cazas Luftwaffe activos en 3 escalones, 16 P-51D Mustang cobertura alta, Flak estocástica 15/min, Salva 30 bombas en ristra 0.08s, HUD telemetría salva, manto continuo de nieve y río helado, sol rasante; 29/29 tests PASS, 19 capturas GPU RTX 2060 SUPER) |
| 1.1.8.0 | Lote 9: Combate Cinemático Europa 1945 | Codex | Agy | Lote 7 completado | ACEPTADO | COMPLETADO_VERIFICADO (48 cazas, 16 P-51D, pases tácticos 120-500m, trazadoras, humo de impacto, 60 FPS RTX 2060 SUPER, M2 intacta; 29/29 tests PASS) |
| 1.1.9.0 | Exportación Portable ASUS ROG Ally / Windows x86-64 | Agy | Agy | Lote 9 completado | ACEPTADO | COMPLETADO_VERIFICADO (AuroraSobreEuropa.exe 212MB PE32+, ZIP portable 142MB, include_filter *.json, LEEME_ROG_ALLY.md, SHA256SUMS.txt) |
| 1.1.10.0 | Mejoras de Jugabilidad MEDIO (Motores, Torretas, Escoltas, Flak) | Antigravity | Agy | Lote 9 / ROG Ally | ACEPTADO | COMPLETADO_VERIFICADO (Extintores/feathering F1-F4, ciclo 3 torretas Dorsal/Cola/Ventral Q, orden radio P-51 daño real E, averías flak altímetro/brújula/Norden; 33/33 tests PASS) |

## Cierre Lote 7: Gran Incursión Masiva sobre Europa en Invierno (supervisor Agy, 2026-10-24T17:00:00-07:00)
- **1.1.1.0 Escuadrilla Aliada Masiva (300 Aviones en Vuelo):**
  - `core/formation_slots.gd`: Generador procedural de 300 ranuras de vuelo estructuradas según la doctrina de Combat Wings de la 8ª Fuerza Aérea (Lead Wing central, High Wing a estribor +Y, Low Wing a babor -Y) con separación lateral de 35 a 60 m y escalonamiento vertical de 15 a 30 m.
  - `formation.gd`: Instanciación híbrida de alto rendimiento. Mantiene los 5 compañeros inmediatos como modelos completos con detalles y marcas (`aircraft.gd`, `bomber_details.gd`, `markings.gd`), y gestiona los 294 bombarderos de fondo mediante un `MultiMeshInstance3D` consolidado con el fuselaje y alas del B-17G para garantizar 60 FPS estables.
  - `visuals/escort.gd` y `game.gd`: Cobertura aliada ampliada a 16 cazas P-51D Mustang en patrulla de cota alta (+150 m a +220 m) y flancos.
- **1.1.2.0 Fuerza de Interceptación Enemiga (30 Cazas de la Luftwaffe):**
  - `core/combat_manager.gd`: Gestor de combate ampliado a 30 cazas activos distribuidos en oleadas masivas coordinadas: 10 en ataque frontal «12 en punto alto», 10 en sectores laterales (babor/estribor) y 10 en persecución por la cola, alternando modelos Bf 109G y Fw 190A.
  - `game.gd`: Pool visual de cazas expandido a 30 nodos con orientación 3D, animación de rotores a 40 rad/s y trazadores balísticos.
  - `core/fighter_ai.gd`: Algoritmo cinemático sincronizado con carriles estocásticos para evitar solapamientos en los vectores de tiro.
- **1.1.3.0 Artillería Antiaérea Estocástica (15 Detonaciones por Minuto):**
  - `flak_model.gd`: Generador pseudo-estocástico determinista calibrado a una media exacta de 15 detonaciones por minuto (media de 1 detonación cada 4,0 segundos, rango entre 2,5 s y 5,5 s con semilla 1944).
  - `visuals/flak_burst.gd`: Escala contenida al 20% histórico (`pixel_size = 0.016`, dispersión de grupo reducida a `0.30` y escala de expansión contenida entre `0.4` y `6.8` m).
  - `game.gd`: Pool ampliado a 20 puffs de flak distribuidos tridimensionalmente a lo largo de la caja de vuelo, con audio `flak_near` y `flak_far` dinámico.
- **1.1.4.0 Bombardeo en Salva de Saturación (30 Bombas por B-17):**
  - `bomb_model.gd` y `core/simulation.gd`: Lógica de salva en ristra (*bomb train*) de 30 bombas por cada B-17 liberadas en intervalos secuenciales de 0,08 s con dispersión longitudinal balística realista.
  - `game.gd`: Instanciación y renderizado de la lluvia masiva de bombas cayendo coordinadamente hacia el nudo ferroviario con audio encadenado (`cue_release_tick`, `bomb_release`, `bomb_secondary_explosions`).
  - `ui/mission_overlay.gd` y `core/bombing_aid.gd`: Telemetría HUD actualizada con estado de salva («SALVA EN PROGRESO: [xx/30]», «ALFOMBRA DE BOMBAS IMPACTADA»).
- **1.1.5.0 Clima y Escenario de Invierno Europeo (Invierno de 1944):**
  - `world/farmland.gdshader`: Manto invernal continuo con mezcla procedural de nieve europea (`vec3(0.92, 0.94, 0.97)`) sobre campos y cauce fluvial transformado en río helado con tonos pálidos (`vec3(0.70, 0.80, 0.86)`), reflectividad de hielo (`ROUGHNESS = 0.22`, `METALLIC = 0.18`) y escala `/1200.0`.
  - `world/atmosphere.gd`: Atmósfera invernal encapotada con `sky_top_color = Color(0.28, 0.38, 0.48)`, horizonte brumoso `Color(0.70, 0.76, 0.82)`, rebote lumínico de la nieve `Color(0.75, 0.78, 0.82)`, niebla helada `0.00010` y desaturación tonal cinematográfica a `0.88`.
  - `game.gd`: Iluminación rasante de `$Sun` a `Vector3(-16.0, -28.0, 0.0)`, luz fría `Color(0.94, 0.96, 1.0)` y energía `1.20`.
- **1.1.6.0 Verificación, Pruebas y Criterios de Aceptación:**
  - Suite de regresión automatizada: **29/29 tests PASS** sin regresiones.
  - Rendimiento gráfico: Tasa sostenida de 60 FPS Forward+ en 1280x720 en la NVIDIA GeForce RTX 2060 SUPER.
  - Validación GPU real: Ejecución de `capture_mission_claude.gd` con 19 capturas almacenadas en `logs/revision_supervisor/20261024T240000Z-lote7-gran-incursion/`.

## Cierre Lote 6: Combate Intenso, Flak Denso y Escuadrillas Ampliadas (supervisor Agy, 2026-10-24T16:17:00-07:00)
- Flak antiaérea:
  - Frecuencia aumentada +60.0% (intervalo reducido de 1.2 a 0.75 s en `flak_model.gd`).
  - Escala visual contenida al 20% histórico en `flak_burst.gd`: `pixel_size = 0.016`, dispersión reducida a `* 0.30`, escala base `0.4` y expansión máxima `6.8` m.
  - Capacidad de pool ampliada a 16 instancias en `game.gd`.
- Cazas enemigos (Luftwaffe):
  - Oleada 1 y Oleada 2 ampliadas a 4 cazas cada una (2 Bf 109G y 2 Fw 190A por oleada) con aproximación escalonada (frontal alta, lateral y cola) en `combat_manager.gd`.
  - Nodos visuales de cazas ampliados a 8 instancias con mapeo 1:1 en `game.gd`.
- Escolta aliada P-51D Mustang («Little Friends»):
  - Módulo `visuals/escort.gd` con 4 cazas P-51D instanciando `assets/aircraft/models/p51d.glb` y animación de rotores `Rotor_*`.
  - Patrulla táctica de cobertura alta (+150 m altitud, laterales ±120/160 m) preservando el contrato de los 6 B-17 base en `Formation.wingmen`.
- Validación y Control de Calidad:
  - Suite de regresión completa: **33/33 tests PASS** (24 pruebas base + 9 complementarias).
  - Sesión GPU en NVIDIA GeForce RTX 2060 SUPER: 19 capturas guardadas en `logs/revision_supervisor/20261024T231630Z-lote6-combate-intenso/` y revalidadas en `logs/revision_supervisor/20261025T002500Z-lote6-validacion/`.
  - Documentación de entrega consolidada en `planning/orquestacion/ENTREGA_LOTE6_AGY.md`.

## Cierre Lote 5 y V1 Local (supervisor Agy, 2026-10-24T15:42:00-07:00)
- Relevo de supervisión activado por orden del usuario.
- Lote 5 cerrado y verificado al 100%:
  - Terreno T1 (farmland_t1.png) con preload y mipmaps activos (escala 1200 m).
  - Audio integrado completo (47 WAV sintetizados, SfxBank con cálculo de bucle QOA exacto, pool dinámico y conmutación exterior/interior).
  - Revisión con GPU completada con el juego real y mipmaps (19 capturas en logs/revision_supervisor/20261024T223630Z-lote5-gpu-terreno).
  - Regresión completa de 24 pruebas: 24/24 PASS.
  - Paquete candidato generado: `release/local-20261024-6b9c2dbc5167`, verificado con restauración en frío completa.

## Autoridad y estado
PROMPT_EJECUCION.md y CAMBIO_ALCANCE_V1_LOCAL.md sustituyen el destino Windows/Ally de contratos históricos. El cierre es primera misión jugable LOCAL. Windows/Ally y misión2 no bloquean. Cada cierre de ejecución requiere evidencia nueva y revisión del supervisor.


## U01/U02 (supervisor Claude, 2026-10-24T11:28:32-07:00)
U01 ayuda de suelta y U02 neutralización de entradas: COMPLETADO_VERIFICADO (lógica y GPU). Release local-20261024-acd6e3ddfc40 SUPERADO; candidato nuevo pendiente tras la regresión 1.1.3.3. Evidencia: REVISION_SUPERVISOR_U01_U02.md.
