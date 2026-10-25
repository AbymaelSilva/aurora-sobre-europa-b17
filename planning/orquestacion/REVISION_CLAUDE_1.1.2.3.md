# Revisión 1.1.2.3 — Cámaras, retículas y encuadre (integrado) — Claude

- Hora real: 2026-10-24T11:12:39-07:00. Mismo candidato y manifiesto estable que REVISION_CLAUDE_1.1.1.4.md (`logs/revision_claude/20261024T175932Z-integrado/manifest_antes.txt`, = staging `local-20261024-acd6e3ddfc40`).
- Capturas GPU RTX 2060 SUPER a 1280×720 y 1920×1080 en pantalla completa. Entradas y puestos se cambian por código (`set_station`, `aim`). No es una sesión humana.

## Dictamen: **ACEPTADO** en encuadre, oclusión y cambio de puesto. Sin S1/S2 de cámara. Una observación S3 nueva (H-14).
La utilidad de la cruz Norden como ayuda de suelta NO forma parte de este dictamen: es U01 (Codex), sigue abierta y depende del encargo a Agy/Qwen.

| Criterio | Resultado | Evidencia |
|---|---|---|
| K1 encuadre de persecución | PASS. B-17 ≈330/1280 px = 25,8 % (1920: ≈496/1920 = 25,8 %), centrado y con el horizonte visible | capturas_1280/01_inicio, 06_cazas, 15_regreso; capturas_1920/01_inicio |
| K2 artillero | PASS. Cámara a 2,8 m sobre el origen, 1,85 m sobre el techo del GLB (0,95). Retícula centrada. Se ve el techo propio solo en el borde inferior (pitch mín. −20°). Alineación disparo/cámara: PASS de Codex con desviación de 0,000° sobre el mismo player_controls.gd/game.gd (hash idéntico) | 04_puesto_artillero, 05_h_artillero_apunta_caza, 10_h_artillero_caza_cercano |
| K3 Norden | PASS (H-01 cerrado). El avión propio se oculta en BOMBARDERO (`aircraft_visible=false`). La cámara está en (0, −0,80, −11,5), delante del morro (−11,33). dir.y = −0,978 (≤ −0,7). El suelo ocupa el 100 % del círculo y no hay geometría propia | 11_puesto_bombardero (1280), 13_puesto_bombardero (1920), log «medida norden» |
| K4 cambio de puesto | PASS. En el frame siguiente a BOMBARDERO→PILOTO y a ARTILLERO→PILOTO no queda retícula y la cámara no está dentro de geometría | 12_piloto_tras_bombardero, 09_persecucion_caza_cercano |
| K5 1920×1080 | PASS. K1–K4 se mantienen y el HUD es legible a pantalla completa | capturas_1920/* |
| K6 dirección D/A | PASS de Codex (D +54°, a la derecha, 112 m) sobre los mismos hashes. No lo repetí | REVISION_LOCAL_CONTROL_DIRECTIONS.md |
| K7 ObjectDB | **FAIL, clasificado S3** (solo al salir, sin crecimiento). Ver H-11 en REVISION_CLAUDE_1.1.3.4.md | logs objectdb_* |

## Hallazgo nuevo H-14 (S3): el punto central de la mira del artillero tapa el caza apuntado
- Pasos: misión demo determinista, t=55,2 s, el Fw 190 más cercano a 445 m. Puesto ARTILLERO con aim sobre el caza (proyecta a (960,540)). Capturé con y sin la retícula en el mismo frame.
- Resultado: el punto negro (≈24 px a 1080p, ≈16 px a 720p) tapa entero el caza (≈15–19 px de envergadura). Sin la retícula, el caza se ve.
- Evidencia: `logs/revision_claude/20261024T175932Z-integrado/oclusion_reticula/comparacion_con_sin.png`, `artillero_con_reticula.png`, `artillero_sin_reticula.png`; `zoom_artillero_caza_cercano_1920.png`; herramienta `tools_review/gunner_occlusion_claude.gd`.
- Contexto medido (`tools_review/fighter_visibility_claude.gd`, misión completa): la distancia mínima caza–jugador es 268 m. Hay cazas vivos en 5530 frames, pero solo 792 con un caza en pantalla en persecución y 63 (≈1 s) con uno a menos de 600 m. Casi siempre los cazas se ven como puntos de 10–35 px.
- Por qué es S3 y no S2: `fire()` acierta con un cono de ≈23° (dot > 0,92). El caza solo desaparece cuando ya está muy dentro del cono, así que no impide disparar ni derribar. Afecta a la legibilidad.
- Propuesta (Agy/Qwen, opcional para V1 local): vaciar el punto central de `assets/ui/gunsight_ring.png` (anillo o punto ≤4 px). Es una edición del recurso existente; no hace falta compra ni arte nuevo.

## Observaciones S3 de cámara
- H-16: en persecución, los compañeros traseros quedan cortados por las esquinas y los paneles del HUD (01/06). Igual que en el baseline.
- El mástil de radio procedural (`bomber_details.gd` RadioMast) aparece como una barra vertical bajo la retícula del artillero al mirar al frente (04). Es cosmético.
- La línea de controles Ally X del HUD de inicio (H-13) sigue presente. Su retirada ya está incluida en ENCARGO_U01_U02_AGY.md.

## Revalidación necesaria tras U01/U02
U01/U02 tocarán player_controls.gd, game.gd y/o mission_overlay.gd. Cuando cambien sus hashes, este dictamen no cubre el nuevo árbol. Habrá que repetir `capture_mission_claude.gd` a 1280 y 1920 (≈15 s cada una) más K2/K4 y revisar la ayuda de suelta nueva en la vista Norden.
