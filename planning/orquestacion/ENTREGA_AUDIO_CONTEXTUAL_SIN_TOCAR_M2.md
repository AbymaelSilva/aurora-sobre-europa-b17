# Entrega contextual sin tocar M2 — 2026-10-24

**42/42 WAV autorizados adaptados/generados, validados y promovidos; 42 difieren del
respaldo inicial. 5/5 WAV protegidos conservan exactamente sus bytes.** El banco tiene
47 WAV. Se mantuvieron API y consumidores: no se editó código de juego, cámara,
controles, UI, escenas, gráficos, balística, release ni snapshots. No se abrió ventana
de juego, no se cerraron procesos y no se reprodujo audio. Solo importación y prueba
headless con controlador Dummy. No hubo cambios accidentales de M2 que restaurar.

## Contexto comprobado en código actual (lectura)

- `formation.gd`: cinco compañeros detallados y 294 de fondo; con el jugador, 300 B-17.
  `core/formation_slots.gd`: 300 posiciones. No se recuperaron cantidades de informes.
- `game.gd` y `combat_manager.gd`: 30 interceptores Bf109G/Fw190A por oleada, dos
  oleadas según fase; 16 escoltas P-51 en presentación, cuatro estelas de motor,
  20 elementos en el pool de flak y 30 bombas visuales.
- `bomb_model.gd`: 30 bombas, intervalo80ms. `bomb_release` suena al cambiar spent;
  las siguientes sueltas usan `cue_release_tick`, no 30 reproducciones del release.
  Impactos nuevos disparan secundarios; se preservó el contrato existente.
- Motor exterior en PILOTO, interior en otros puestos. El dañado se suma al sano
  si algún motor baja de50 de salud: se diseñó una capa de avería intermitente.
- Flak: tres variantes cercanas y dos lejanas en catálogo. Con los offsets actuales,
  las distancias de las bocanadas son inferiores a150m y entra siempre la rama cercana.
  No se alteró esa lógica ni se añadieron golpes de metralla a cada explosión.
- M2: AudioStreamRandomizer de tres disparos, random_pitch1.0,
  random_volume_offset_db0, cuatro voces. La función antigua create_gun_stream sigue
  cargando el WAV grabado vigente. SfxBank no se modificó. Los efectos sin consumidor
  actual siguen disponibles en catálogo; sustituir WAV no crea nuevos eventos.
- Se observó la cámara orbital existente en lectura. No se interfirió con su trabajo.

## Producción, procedencia y límites

38 derivados de grabación, dos híbridos (squelch), dos síntesis nuevas (cañoneo distante
y estática). Fuentes locales y evidencia de licencia:

| ID local | Autor | Página individual | Licencia |
|---|---|---|---|
| alarm | sbyandiji | [217486](https://freesound.org/people/sbyandiji/sounds/217486/) | [CC0 1.0](http://creativecommons.org/publicdomain/zero/1.0/) |
| fire | StevenMyat_ | [676385](https://freesound.org/people/StevenMyat_/sounds/676385/) | [CC0 1.0](http://creativecommons.org/publicdomain/zero/1.0/) |
| metal | Johnnyfarmer | [209772](https://freesound.org/people/Johnnyfarmer/sounds/209772/) | [CC0 1.0](http://creativecommons.org/publicdomain/zero/1.0/) |
| radial | YleArkisto | [256049](https://freesound.org/people/YleArkisto/sounds/256049/) | [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/) |
| sheet | Stereo Surgeon | [262516](https://freesound.org/people/Stereo%20Surgeon/sounds/262516/) | [CC0 1.0](http://creativecommons.org/publicdomain/zero/1.0/) |
| switch | DustyWind | [697807](https://freesound.org/people/DustyWind/sounds/697807/) | [CC0 1.0](http://creativecommons.org/publicdomain/zero/1.0/) |
| tnt | sidohzen | [165808](https://freesound.org/people/sidohzen/sounds/165808/) | [CC0 1.0](http://creativecommons.org/publicdomain/zero/1.0/) |
| wind | felix.blume | [146914](https://freesound.org/people/felix.blume/sounds/146914/) | [CC0 1.0](http://creativecommons.org/publicdomain/zero/1.0/) |

**Crédito requerido**: YleArkisto, grabación de DC-3, Freesound256049, CC BY4.0.
Cambios: cortes, filtros, mezclas, bucles, fundidos, ganancia y conversión de formato.
Los otros autores se acreditan también. El detalle y páginas individuales están en
`art/audio/redesign_v4/sources/README.md`. Se guardan MP3 HQ de preescucha pública,
PCM decodificado y hashes; no se afirma disponer de los masters originales.

DC-3 es una grabación de pistón radial desde tierra, usada como aproximación para
B-17/cazas. No acredita un Wright R-1820, Bf109/Fw190 ni cabina. No se superpone otro
Doppler/pan a la toma de paso. Las dos variantes de flyby son ventanas distintas de
la misma pasada, no dos aviones grabados. La formación mezcla ventanas distintas y
filtradas, no pretende documentar300 aviones grabados. La avería está troceada y
filtrada, sin duplicar un conjunto sano completo. El fuego mezcla campamento y viento.

Flak y bombas proceden de demolición terrestre, sin seno descendente ni subgrave como
único contenido. El preámbulo se excluye; las variantes cercanas comparten grabación,
con distintos canales/filtros, sin colas añadidas de catedral ni shrapnel automático.
Lejanos conservan medios hasta850–1100Hz; no añaden segundos de propagación al WAV.
Chapa/fragmentos usan acero y metal grabados, amortiguados y montados, sin resonadores
afinados. La alarma procede de un timbre escolar en sala. Los pestillos/compuertas son
fóley adaptado; no se afirma haber grabado mecanismos originales B-17.

Interfaz y ayudas usan interruptor metálico por ritmo/peso, sin arpegios. Los squelch
mezclan interruptor y ruido de banda limitada. Radio estática y cañoneo distante usan
excitación aperiódica nueva y filtros, sin reutilizar M2. Los cierres de4s son ambiente
de aire/alejamiento con conmutador, sin fanfarria ni instrumentos sintetizados de sierra.

No hay familias bloqueadas para integración. **La obtención de grabaciones específicas
B-17/cazas, flak88mm, mecanismos originales y cañón aéreo queda pendiente**; se
entregaron aproximaciones explícitas y síntesis donde no se encontró fuente apropiada.
Se descartaron P-40 con licencia no comercial, hélice caricaturesca y material de
procedencia cinematográfica. No se compraron créditos ni instalaron modelos.

## Resultados por archivo

Todos PCM16/44100Hz, mismos nombres, canales y contrato de duración. s/ch = segundos /
canales. RMS/pico en dBFS. Lista completa de hashes previos/finales, fuente original,
autor/URL/licencia, cortes, filtros y ganancias en `art/audio/redesign_v4/manifest_full.json`.

| Archivo cambiado | s / ch | RMS / pico | Procedencia |
|---|---|---|---|
| `engine_b17_ext_loop.wav` | 8.00 / 1 | -20.00 / -7.36 | derivado: radial |
| `engine_b17_int_loop.wav` | 8.00 / 1 | -20.00 / -7.85 | derivado: radial |
| `engine_b17_damaged_loop.wav` | 6.00 / 1 | -20.71 / -1.20 | derivado: metal, radial |
| `engine_sputter_01.wav` | 1.25 / 1 | -20.00 / -4.82 | derivado: metal, radial |
| `engine_sputter_02.wav` | 1.25 / 1 | -20.00 / -6.79 | derivado: metal, radial |
| `engine_fire_loop.wav` | 5.00 / 1 | -20.00 / -5.58 | derivado: fire, wind |
| `wind_altitude_loop.wav` | 10.00 / 2 | -20.00 / -3.04 | derivado: wind |
| `formation_drone_loop.wav` | 10.00 / 2 | -20.00 / -3.00 | derivado: radial |
| `hit_hull_01.wav` | 0.30 / 1 | -16.51 / -1.20 | derivado: metal, sheet |
| `hit_hull_02.wav` | 0.30 / 1 | -16.87 / -1.20 | derivado: metal |
| `hit_hull_03.wav` | 0.30 / 1 | -14.54 / -1.20 | derivado: metal, sheet |
| `shrapnel_rattle_01.wav` | 0.80 / 1 | -18.70 / -1.20 | derivado: metal, sheet |
| `damage_alarm_bell.wav` | 1.50 / 1 | -15.15 / -1.20 | derivado: alarm |
| `fighter_flyby_01.wav` | 3.50 / 2 | -20.00 / -7.29 | derivado: radial |
| `fighter_flyby_02.wav` | 3.50 / 2 | -20.00 / -4.38 | derivado: radial |
| `fighter_engine_loop.wav` | 4.00 / 1 | -20.00 / -9.01 | derivado: radial |
| `fighter_falling_whine.wav` | 4.00 / 1 | -20.00 / -3.60 | derivado: radial |
| `fighter_guns_distant.wav` | 1.20 / 1 | -19.98 / -1.20 | síntesis: local |
| `fighter_explosion.wav` | 2.50 / 1 | -17.43 / -1.20 | derivado: fire, tnt |
| `flak_near_01.wav` | 1.50 / 1 | -15.55 / -1.20 | derivado: tnt |
| `flak_near_02.wav` | 1.50 / 1 | -14.00 / -1.52 | derivado: tnt |
| `flak_near_03.wav` | 1.50 / 1 | -15.65 / -1.20 | derivado: tnt |
| `flak_far_01.wav` | 1.50 / 1 | -14.32 / -1.20 | derivado: tnt |
| `flak_far_02.wav` | 1.50 / 1 | -14.00 / -1.81 | derivado: tnt |
| `bomb_bay_doors_open.wav` | 2.50 / 1 | -24.41 / -1.20 | derivado: metal, switch, wind |
| `bomb_release.wav` | 0.50 / 1 | -15.25 / -1.20 | derivado: metal, sheet, switch |
| `bomb_impact_distant.wav` | 3.00 / 1 | -16.91 / -1.20 | derivado: tnt |
| `bomb_secondary_explosions.wav` | 4.00 / 1 | -15.08 / -1.20 | derivado: tnt |
| `ui_navigate.wav` | 0.06 / 1 | -22.00 / -2.03 | derivado: switch |
| `ui_accept.wav` | 0.15 / 1 | -22.23 / -1.20 | derivado: switch |
| `ui_back.wav` | 0.15 / 1 | -22.00 / -3.89 | derivado: switch |
| `ui_pause.wav` | 0.30 / 1 | -22.00 / -2.56 | derivado: switch |
| `ui_profile_change.wav` | 0.12 / 1 | -22.00 / -1.82 | derivado: switch |
| `station_switch.wav` | 0.25 / 1 | -24.40 / -1.20 | derivado: switch |
| `cue_release_tick.wav` | 0.08 / 1 | -22.39 / -1.20 | derivado: switch |
| `cue_release_now.wav` | 0.40 / 1 | -24.85 / -1.20 | derivado: switch |
| `cue_course_correction.wav` | 0.30 / 1 | -25.26 / -1.20 | derivado: switch |
| `radio_squelch_open.wav` | 0.25 / 1 | -22.00 / -8.66 | híbrido: switch |
| `radio_squelch_close.wav` | 0.20 / 1 | -22.00 / -11.77 | híbrido: switch |
| `radio_static_loop.wav` | 4.00 / 1 | -22.00 / -9.53 | síntesis: local |
| `stinger_mission_complete.wav` | 4.00 / 2 | -20.00 / -2.12 | derivado: radial, switch, wind |
| `stinger_mission_failed.wav` | 4.00 / 2 | -20.33 / -1.20 | derivado: radial, switch, wind |

## Protección M2

Hashes iniciales iguales a finales (`logs/audio_redesign/m2_final_hashes.json`):

| Archivo protegido | SHA256 |
|---|---|
| `gun_m2_burst.wav` | `37fca5948804d35fb2f5eb2bb6a4aa7cd20603f3d797a7fd8e943d12b4616b7a` |
| `gun_m2_shot_01.wav` | `faba8b76b8af8dcc2b4775b7337e380fee961f007bceff4b44bd3d98a785fabb` |
| `gun_m2_shot_03.wav` | `c08ddbe8f27e2c1d288b2ff367f506f4e1bfcada1d97babaf22294d60b8decf8` |
| `gun_m2_shot_02.wav` | `3b3eca1f0dd31ad11e7b8a74b1dbd5a2a28f2b535f78a8dcbe4aa5f6d6174905` |
| `gun_casings_01.wav` | `8776cd14f06f52f8494d8b151557a63bca224551cddec5cc7bbfbd1fd2622f2f` |

El respaldo `logs/audio_redesign/backup/` contiene solo42 WAV permitidos. El generador
nuevo tiene lista explícita de42, valida todos los candidatos antes de copiar y
comprueba los cinco hashes tras cada copia. `promotion.json` registra42 verificaciones
por promoción y los42 nombres que cambiaron. `immutable_baseline.json` comprueba
SfxBank, combat_sfx, script y fuentes M2; no se alteraron. No se ejecutó el grupo B ni
el sintetizador completo antiguo. La prueba negativa corrompe solo un hash esperado
en memoria y comprueba que la guarda rechaza trabajar; cero escrituras activas.

## Pruebas y A/B

- `python3 -I tools_audio/check_sfx.py`: salida0, 47/47 PASS, sin relajar límites.
- Godot4.7.2 local, importación headless/editor/import/quit con audio Dummy: salida0.
- `tests/test_audio_assets.gd` headless/Dummy: salida0, TEST PASS47 WAV.
- Logs exactos y comandos: `logs/audio_redesign/{check_sfx,godot_import,test_audio_assets}.log`
  y `validation_exit_codes.json`. No había otro importador al iniciar.
- `candidate_checks_full.json`:42 candidatos, DC inferior a0.001 de escala completa,
  sin clipping, inicio dentro de10ms, bucles con smpl, límites originales de duración,
  canal y nivel. Pico máximo nuevo −1.20dBFS. Las ganancias conservan transitorios:
  no se usó limitador para forzar RMS; algunos impactos/UI quedan bajo objetivo,
  dentro de su tolerancia original. Las comprobaciones no certifican ausencia de
  cualquier clic perceptible ni realismo por sí solas.
- Los ocho bucles se analizaron como diez periodos: nueve uniones idénticas por
  construcción, continuidad de muestra y RMS de50ms en unión frente al interior,
  sin huecos de envolvente en unión. No se simula una escucha de diez vueltas.
- Generación repetida desde fuentes locales:42 hashes idénticos, en `reproducibility.json`.
- Pilotos primero: exterior/interior, flak cercano y station_switch, con formato
  validado antes de extender al banco. `manifest_pilot.json` y `pilot_build.log`.
- `art/audio/redesign_v4/review/`: A anterior y B nuevo, mismo RMS alcanzable y margen
  de pico sin limitador; AB con600ms de separación y ambos motores en10 vueltas
  lineales. `levels.json` indica ganancias y hashes. No incluye M2 ni se reprodujo.

**Sin escucha humana propia ni aceptación del usuario.** Pendiente comparar pilotos,
confirmar ausencia de ruido ajeno/voces residuales de fuentes de campo, valorar
credibilidad, fatiga de misión y mezcla desde cámara exterior. No se prueban nuevos
eventos en juego ni se declara autenticidad por las métricas. El supervisor recargará
la instancia; no se lanzó otra ni se cerró la validación de cámara.

## Comandos vigentes

Desde la raíz:

```sh
python3 -I tools_audio/build_contextual_set.py --pilot
python3 -I tools_audio/build_contextual_set.py
python3 -I tools_audio/build_contextual_set.py --promote
python3 -I tools_audio/review_contextual_set.py
python3 -I tools_audio/check_sfx.py
tools/godot --headless --audio-driver Dummy --path godot/B17 --editor --import --quit
tools/godot --headless --audio-driver Dummy --path godot/B17 --script res://tests/test_audio_assets.gd
```

Ejecutar importación solo cuando no exista otro importador. No ejecutar synth_sfx.py
ni synth_realista.py sobre el banco activo: son procesos históricos que escriben M2.
