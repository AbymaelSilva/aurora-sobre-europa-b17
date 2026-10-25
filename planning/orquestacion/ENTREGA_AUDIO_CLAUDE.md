# Entrega de audio · Claude (terminal de audio)

Generado el 2026-10-24 14:52 con `python3 -I tools_audio/make_report.py`.

## Resumen

- **47 de 47** WAV en `godot/B17/assets/audio/sfx/`, 12.4 MB en total. Verificación `tools_audio/check_sfx.py`: **PASS** (`logs/audio/check_sfx.log`, `logs/audio/check_sfx.json`).
- Prueba de Godot `tests/test_audio_assets.gd`: **TEST PASS** (`logs/audio/test_audio_assets.log`). Carga los 47 con `AudioStreamWAV.load_from_file` y comprueba los datos, 44 100 Hz, 16 bits, los canales, la duración y que los bucles salgan con `LOOP_FORWARD`.
- Todo se sintetiza con `tools_audio/synth_sfx.py`, que solo usa la biblioteca estándar y tarda unos 14 s en un pool de 8 procesos. Cada archivo usa una semilla fija (crc32 del nombre). He comprobado que dos ejecuciones, una en paralelo y otra con `--serial`, dan los 47 archivos idénticos byte a byte (sha256).
- Los bucles llevan un bloque RIFF `smpl` con el bucle completo. Godot lo detecta solo al importar o cargar (`loop_mode = LOOP_FORWARD`), así que la integración no necesita configurar los puntos de bucle.
- Niveles: motores, ambientes, pasadas y stingers a −20 dBFS RMS; armas e impactos a −14 (algunos apuntados a −16/−17 dentro de la tolerancia: casquillos, campana, flak lejano, bomba lejana, cañones lejanos); interfaz y radio a −22. El pico máximo es −1,1 dBFS: un limitador suave lo garantiza.
- No he modificado código de producción, escenas ni `release/`. La `--import` obligatoria de Godot creó los `.import` de los WAV y algunos `.uid` que faltaban en scripts de otros (metadatos que Godot genera solo).

**Aviso honesto:** no puedo escuchar los archivos. La autoevaluación se basa en el diseño de cada síntesis y en medidas objetivas (niveles por bandas de octava, factor de cresta, variación de RMS por ventanas). Antes de dar el set por definitivo, una persona debe escucharlo.

## Bloques del sintetizador

Osciladores (seno, sierra y pulso o cuadrada con polyBLEP), FM por fase y AM; ruido blanco, rosa (Kellet), marrón y chasquidos; biquads RBJ (paso bajo, paso alto, paso banda y pico resonante), SVF TPT con frecuencia variable y banco de resonadores modales; envolventes ADSR, exponencial y por tramos; tanh y limitador suave; doppler físico (trayectoria recta con el tiempo de emisión resuelto exactamente, más una fuente que se aleja y un remuestreo variable genérico); reverberación tipo Freeverb (6 peines realimentados y amortiguados, 3 pasa-todo, mono y estéreo); bucles con fundido cruzado de potencia constante de 150 ms y rotación a la unión más suave; motor de pistones genérico (radial de 9 cilindros, V12 y doble estrella de 14).

## Hoja de escucha

Columnas: duración (s), pico (dBFS), RMS (dBFS) / objetivo, inicio (ms) o salto en la unión (fracción de la escala completa).

### A. B-17: motores y vuelo

| Archivo | Dur. | Pico | RMS / obj. | Inicio / unión | Técnica | Convincente | Aproximado |
|---|---|---|---|---|---|---|---|
| `engine_b17_ext_loop.wav` BUCLE | 8.00 | -11.6 | -20.0 / -20 | unión 0.0000 | 4 motores radiales de 9 cilindros (tren de pulsos de escape a 172,5 Hz con amplitud por cilindro, deriva lenta de rpm), hélice tripala (64,7 Hz), ruido rosa modulado por la combustión; 4 motores desafinados ±0,5 % para el batido; tanh, reverberación corta | Batido lento entre los 4 motores y pulso de escape a 172 Hz con hélice a 65 Hz: el «zumbido pulsante» está bien planteado. | Sin turbo ni el rugido irregular real de un radial; puede sonar algo limpio y uniforme. |
| `engine_b17_int_loop.wav` BUCLE | 8.00 | -14.1 | -20.0 / -20 | unión 0.0000 | Mismos 4 motores con paso bajo a 340 Hz, resonancias del fuselaje (108 y 232 Hz), retumbo marrón y vibración de chapas modulada en AM al paso de pala; sala muy pequeña | Más oscuro (−5 a −8 dB en 0,5–1 kHz frente al exterior) con resonancia de fuselaje; la vibración de las chapas añade cuerpo. | La estructura real tiene muchos más modos y traqueteos; la resonancia es genérica. |
| `engine_b17_damaged_loop.wav` BUCLE | 6.00 | -5.9 | -20.0 / -20 | unión 0.0000 | Motor con fallos de encendido aleatorios (probabilidad variable), rpm inestable ±4 %, oleadas de AM, petardeos (chasquido + golpe grave) y los otros 3 motores de fondo | Los fallos de encendido y los petardeos aleatorios se distinguen bien del motor sano. | La forma del petardeo es genérica; un motor real tocado tiene golpeteos mecánicos que no están. |
| `engine_sputter_01.wav` | 1.25 | -7.2 | -20.0 / -20 | 0.23 ms | Motor que pierde rpm (rampa exponencial), fallos crecientes y serie de petardeos dobles irregulares | Caída de rpm con toses irregulares: se lee como «motor tocado». | Las toses pueden sonar parecidas entre sí. |
| `engine_sputter_02.wav` | 1.40 | -5.8 | -20.0 / -20 | 0.09 ms | Igual que la 01 con otra semilla y otra caída de rpm | Variante distinta (otra semilla y otra caída de rpm). | Igual que la 01. |
| `engine_fire_loop.wav` BUCLE | 5.00 | -13.4 | -20.0 / -20 | unión 0.0000 | Rugido de llamas: ruido marrón y rosa filtrado con parpadeo (control aleatorio a 9 Hz), chasquidos filtrados y viento con rachas; tanh | Rugido grave con parpadeo y chasquidos: funciona como capa de fondo. | Fuego sintético: le falta la textura «rasgada» de una llama real con viento a 300 km/h. |
| `wind_altitude_loop.wav` (E) BUCLE | 10.00 | -4.4 | -20.0 / -20 | unión 0.0001 | Ruido rosa compartido + propio por canal, paso banda ancho con rachas lentas, silbido resonante estrecho (SVF Q=14) que deriva en frecuencia y golpeteo grave | Rachas lentas y un silbido de rendija que deriva; estéreo decorrelado y amplio. | El silbido es una sola resonancia; el real tiene varias. |
| `formation_drone_loop.wav` (E) BUCLE | 10.00 | -8.7 | -20.0 / -20 | unión 0.0001 | 5 aviones × 2 motores radiales, paso bajo por distancia, desvanecimientos lentos independientes, panorámica repartida y reverberación ancha estéreo | Zumbido lejano y ancho con desvanecimientos independientes por avión. | Muy dependiente del filtro de distancia; puede quedar algo turbio. |

### B. Armas propias

| Archivo | Dur. | Pico | RMS / obj. | Inicio / unión | Técnica | Convincente | Aproximado |
|---|---|---|---|---|---|---|---|
| `gun_m2_shot_01.wav` | 0.30 | -1.4 | -14.0 / -14 | 0.07 ms | Estampido (ruido paso bajo, caída 10 ms) + cuerpo rosa + golpe grave en barrido + chasquidos del cerrojo (paso banda) + modos de chapa (banco de resonadores); tanh; reverberación corta de exterior | Ataque inmediato (<0,1 ms), golpe grave y chasquido del cerrojo: sirve a cadencia de 0,12 s. | Un .50 real tiene un estampido mucho más complejo; aquí es ruido + seno. |
| `gun_m2_shot_02.wav` | 0.30 | -2.4 | -14.0 / -14 | 0.07 ms | Estampido (ruido paso bajo, caída 10 ms) + cuerpo rosa + golpe grave en barrido + chasquidos del cerrojo (paso banda) + modos de chapa (banco de resonadores); tanh; reverberación corta de exterior | Variante con timbre ±7 %. | Igual que la 01. |
| `gun_m2_shot_03.wav` | 0.30 | -2.6 | -14.0 / -14 | 0.07 ms | Estampido (ruido paso bajo, caída 10 ms) + cuerpo rosa + golpe grave en barrido + chasquidos del cerrojo (paso banda) + modos de chapa (banco de resonadores); tanh; reverberación corta de exterior | Variante con timbre ±7 %. | Igual que la 01. |
| `gun_m2_burst.wav` | 1.00 | -4.3 | -14.0 / -14 | 0.14 ms | 8 disparos alternando las dos armas cada ~0,112 s, cada uno con semilla y timbre propios, y reverberación común | 8 disparos alternando dos armas con micro-variaciones de tiempo: evita el efecto «ametralladora de 8 bits». | Cadencia de 0,112 s (según la tabla); la cadencia real de dos M2 juntas sería mayor. |
| `gun_casings_01.wav` | 0.80 | -1.7 | -17.2 / -14 | 0.07 ms | 12 casquillos: clic que excita 4 modos inarmónicos (2,6–3,6 kHz) con 2–4 rebotes cada vez más cortos y flojos; golpe sordo del suelo | Modos inarmónicos y rebotes cada vez más cortos: los tintineos metálicos son de lo más creíble del set. | Suelo de torreta genérico. |

### C. Daños en el propio avión

| Archivo | Dur. | Pico | RMS / obj. | Inicio / unión | Técnica | Convincente | Aproximado |
|---|---|---|---|---|---|---|---|
| `hit_hull_01.wav` | 0.30 | -1.9 | -14.1 / -14 | 0.07 ms | Chasquido de alta frecuencia + desgarro en paso banda + golpe grave + panel de aluminio (7 modos inarmónicos, 0,04–0,22 s); variantes por semilla | Chasquido + desgarro + modos de panel de aluminio: lectura clara de «impacto metálico». | La perforación real es más «seca»; puede sonar algo a campana. |
| `hit_hull_02.wav` | 0.30 | -3.0 | -14.0 / -14 | 0.05 ms | Chasquido de alta frecuencia + desgarro en paso banda + golpe grave + panel de aluminio (7 modos inarmónicos, 0,04–0,22 s); variantes por semilla | Variante. | Igual que la 01. |
| `hit_hull_03.wav` | 0.30 | -4.0 | -14.0 / -14 | 0.05 ms | Chasquido de alta frecuencia + desgarro en paso banda + golpe grave + panel de aluminio (7 modos inarmónicos, 0,04–0,22 s); variantes por semilla | Variante. | Igual que la 01. |
| `shrapnel_rattle_01.wav` | 0.80 | -4.2 | -14.0 / -14 | 0.05 ms | 55 golpecitos metálicos con densidad decreciente, algunos más fuertes, sobre un lecho de ruido y una resonancia común de chapa a 520 Hz | Densidad decreciente de golpecitos con algunos fuertes: efecto «granizo». | La distribución es estadística; no hay trozos grandes. |
| `damage_alarm_bell.wav` | 1.50 | -3.2 | -16.0 / -14 | 0.05 ms | Campana eléctrica: martillo a 22 golpes/s excitando 6 modos de campana (1180 Hz × 1; 2,31; 2,97…), 3 toques de 0,36 s | Martillo a 22 Hz sobre 6 modos de campana: timbre eléctrico reconocible. | Campana idealizada; la real tiene el zumbido del electroimán. |

### D. Cazas enemigos

| Archivo | Dur. | Pico | RMS / obj. | Inicio / unión | Técnica | Convincente | Aproximado |
|---|---|---|---|---|---|---|---|
| `fighter_flyby_01.wav` (E) | 3.50 | -1.5 | -20.1 / -20 | 0.95 ms | Bf 109 (V12, 12 cilindros, 2700 rpm) + estela aerodinámica; trayectoria recta a 125 m/s y 28 m con doppler exacto (tiempo de emisión), ganancia 1/r, absorción del aire (paso bajo con la distancia) y panorámica izquierda→derecha | Doppler físico (tiempo de emisión exacto), 1/r, absorción del aire y panorámica: la curva de tono y volumen es correcta. | La fuente (V12 sintético) es la parte débil; el «rasgado» real de un 109 en pasada es mucho más rico. |
| `fighter_flyby_02.wav` (E) | 3.50 | -1.2 | -20.2 / -20 | 1.00 ms | Fw 190 (BMW 801, 14 cilindros, 2400 rpm, más áspero) a 150 m/s y 20 m; misma técnica | Fw 190 con 14 cilindros, más rápido y más cerca: se distingue de la 01. | Igual que la 01. |
| `fighter_engine_loop.wav` BUCLE | 4.00 | -8.7 | -20.0 / -20 | unión 0.0000 | V12 a 2700 rpm: pulsos de escape más cortos y saturados (tanh), hélice, silbido del compresor y ruido de combustión | Más agudo y saturado que el B-17, con deriva de rpm y oleadas. | Silbido del compresor simplificado (un seno). |
| `fighter_guns_distant.wav` | 1.20 | -3.7 | -17.0 / -14 | 4.40 ms | 2 cañones MG 151/20 (11,7 disparos/s) + 2 MG 131 (15/s): estallidos de ruido paso bajo + golpe grave, filtro de distancia y reverberación difusa | Dos cadencias superpuestas (20 mm y 13 mm), amortiguadas y difusas. | Sin el «crac» supersónico de los proyectiles que pasan cerca. |
| `fighter_explosion.wav` | 2.50 | -1.7 | -14.0 / -14 | 0.02 ms | Onda N + bola de fuego (rosa paso bajo) + retumbo marrón + subgrave en barrido + restos (chasquidos) + soplido de combustible; tanh; reverberación | Onda N, bola de fuego, subgrave y restos: lectura clara de explosión media en el aire. | Explosión «de manual»; falta la desintegración del avión (metal, hélice). |
| `fighter_falling_whine.wav` | 4.00 | -1.5 | -20.1 / -20 | 0.09 ms | V12 a sobrerrégimen + tono de punta de pala + aullido de viento resonante; fuente que se aleja a 190 m/s con doppler exacto, ganancia 1/r y paso bajo por distancia | Aullido que baja de tono por doppler real y se apaga con la distancia. | El aullido es de tono algo puro; puede sonar «de película». |

### E. Flak

| Archivo | Dur. | Pico | RMS / obj. | Inicio / unión | Técnica | Convincente | Aproximado |
|---|---|---|---|---|---|---|---|
| `flak_near_01.wav` | 1.50 | -1.1 | -14.1 / -14 | 0.02 ms | Explosión con onda N fuerte, bola de fuego y subgrave + 10–22 impactos de metralla en el fuselaje + cola reverberante de 1,1 s; tamaño variable por semilla | Estampido seco con metralla inmediata y cola: de los sonidos más eficaces del set. | La cola es reverberación genérica, no el eco real del cielo abierto. |
| `flak_near_02.wav` | 1.50 | -1.3 | -14.0 / -14 | 0.02 ms | Explosión con onda N fuerte, bola de fuego y subgrave + 10–22 impactos de metralla en el fuselaje + cola reverberante de 1,1 s; tamaño variable por semilla | Variante de tamaño y metralla. | Igual que la 01. |
| `flak_near_03.wav` | 1.50 | -1.1 | -14.1 / -14 | 0.02 ms | Explosión con onda N fuerte, bola de fuego y subgrave + 10–22 impactos de metralla en el fuselaje + cola reverberante de 1,1 s; tamaño variable por semilla | Variante de tamaño y metralla. | Igual que la 01. |
| `flak_far_01.wav` | 1.50 | -4.6 | -16.0 / -14 | 1.00 ms | Explosión sin onda de choque, paso bajo a 320 Hz (absorción), ataque de 6 ms y reverberación difusa larga | «Pum» sordo (todo por debajo de ~300 Hz), fácil de repetir sin cansar. | Se apoya mucho en el subgrave: en altavoces pequeños se oirá poco. |
| `flak_far_02.wav` | 1.50 | -5.2 | -16.0 / -14 | 0.98 ms | Explosión sin onda de choque, paso bajo a 320 Hz (absorción), ataque de 6 ms y reverberación difusa larga | Variante. | Igual que la 01. |

### F. Bombardeo

| Archivo | Dur. | Pico | RMS / obj. | Inicio / unión | Técnica | Convincente | Aproximado |
|---|---|---|---|---|---|---|---|
| `bomb_bay_doors_open.wav` | 2.50 | -1.7 | -20.0 / -20 | 0.07 ms | Motor eléctrico (sierra 115 Hz + engranajes 920 Hz) que arranca y se para, chirridos de bisagra en FM, golpes de cerrojo y tope, y viento cada vez más fuerte y brillante (SVF) | Arranque y parada del motor, chirridos de bisagra y viento que crece: la narrativa se entiende. | El motor eléctrico es una sierra filtrada; el real tiene más ruido de engranajes. |
| `bomb_release.wav` | 0.50 | -1.8 | -14.2 / -14 | 0.05 ms | Chasquido del soporte (paso banda), golpe grave, muelle (seno con caída de tono) y modos metálicos del gancho | Golpe mecánico seco con muelle: corto y legible. | Genérico. |
| `bomb_impact_distant.wav` | 3.00 | -3.4 | -16.0 / -14 | 1.29 ms | 4 explosiones paso bajo (ecos del terreno a 0,18/0,42/0,85 s) + retumbo marrón rodante, todo por debajo de 220 Hz y reverberación larga | Retumbo grave que rueda con ecos del terreno: transmite distancia. | Igual que el flak lejano: depende del subgrave. |
| `bomb_secondary_explosions.wav` | 4.00 | -3.5 | -14.0 / -14 | 0.16 ms | Cadena aleatoria de explosiones de distinto tamaño y espaciado, chasquidos de munición, filtro de distancia (1,4 kHz) y reverberación larga | Cadena irregular de tamaños y espaciados distintos. | Las explosiones individuales se parecen entre sí. |

### G. Interfaz, HUD y radio

| Archivo | Dur. | Pico | RMS / obj. | Inicio / unión | Técnica | Convincente | Aproximado |
|---|---|---|---|---|---|---|---|
| `ui_navigate.wav` | 0.06 | -6.9 | -22.0 / -22 | 0.11 ms | Blip senoidal de 1,9 kHz (9 ms) + clic de ruido | Limpio y corto. | — |
| `ui_accept.wav` | 0.15 | -11.2 | -22.0 / -22 | 0.14 ms | Clic + dos blips ascendentes (660 → 990 Hz) | Ascendente, claro. | — |
| `ui_back.wav` | 0.15 | -11.7 | -22.0 / -22 | 0.16 ms | Dos blips descendentes (880 → 560 Hz) | Descendente, simétrico a aceptar. | — |
| `ui_pause.wav` | 0.30 | -8.5 | -22.0 / -22 | 0.20 ms | Golpe senoidal 170→85 Hz + soplo grave + tono 330 Hz apagado | Golpe apagado y grave. | — |
| `ui_profile_change.wav` | 0.12 | -5.7 | -22.0 / -22 | 0.11 ms | Dos tics (1,5 y 1,8 kHz) separados 55 ms | Doble tic claro. | — |
| `station_switch.wav` | 0.25 | -1.4 | -22.0 / -22 | 0.09 ms | Clic doble del conmutador del interfono + soplido de ruido en la banda de la radio | Clic de interfono + soplido de radio: encaja con la época. | — |
| `cue_release_tick.wav` | 0.08 | -7.7 | -22.0 / -22 | 0.11 ms | Tic senoidal de 1250 Hz con armónicos, 12 ms | Tic suave para repetir en cuenta atrás. | — |
| `cue_release_now.wav` | 0.40 | -15.3 | -22.0 / -22 | 0.70 ms | Dos tonos (La5 880 Hz y Re6 1175 Hz) con 2.º y 3.er armónico suaves, ADSR con ataque de 6 ms | Dos tonos (La5–Re6) claros y redondos, sin agresividad. | — |
| `cue_course_correction.wav` | 0.30 | -13.5 | -22.0 / -22 | 0.93 ms | Tono de 660 Hz (seno + cuadrada filtrada) con AM a 16 Hz | Tono medio con trémolo leve, distinto de «suelta ahora». | — |
| `radio_squelch_open.wav` | 0.25 | -8.0 | -22.0 / -22 | 0.11 ms | Clic + ráfaga de estática (blanco + chasquidos) en banda de 350–2800 Hz, tanh | Clic + estática de banda estrecha. | — |
| `radio_squelch_close.wav` | 0.20 | -6.4 | -22.0 / -22 | 0.07 ms | Estática que corta + «chsk» en paso banda de 3,8 kHz + clic final | «Chsk» corto. | — |
| `radio_static_loop.wav` BUCLE | 4.00 | -5.2 | -22.0 / -22 | unión 0.0000 | Ruido con desvanecimiento lento (QSB), chasquidos, heterodino débil que deriva, zumbido de red a 120 Hz en AM, banda de 350–2800 Hz y tanh | Estática de banda estrecha con desvanecimiento, chasquidos y heterodino. | La radio real de 1944 tiene más zumbido y distorsión de válvulas. |

### H. Misión

| Archivo | Dur. | Pico | RMS / obj. | Inicio / unión | Técnica | Convincente | Aproximado |
|---|---|---|---|---|---|---|---|
| `stinger_mission_complete.wav` (E) | 4.00 | -7.2 | -20.0 / -20 | 1.97 ms | Metales sintetizados (2 sierras polyBLEP por voz, filtro SVF con envolvente, vibrato retardado): Si♭/Fa → Fa mayor (cadencia plagal), panorámica por voz y reverberación de sala | Cadencia plagal IV→I (Si♭/Fa → Fa), sobria y esperanzada. | Metales de sintetizador analógico: no parecen una sección de metales real. |
| `stinger_mission_failed.wav` (E) | 4.00 | -6.0 | -20.0 / -20 | 3.11 ms | Re menor grave con la voz superior que baja (La → Sol → Fa), el tono cae 35 cents y el filtro se cierra mientras se apaga | Re menor grave que se apaga con caída de 35 cents y filtro que se cierra. | Igual que el de éxito. |

## Los 5 sonidos que más mejorarían con una grabación real

1. **engine_b17_ext_loop.wav / engine_b17_int_loop.wav**: Es lo que más se oye en toda la misión. Un radial real tiene un rugido irregular y rico que la síntesis por pulsos solo imita; una grabación de un B-17 superviviente (p. ej., en exhibiciones de vuelo) lo mejoraría más que cualquier otro cambio.
2. **fighter_flyby_01.wav / fighter_flyby_02.wav**: La física del doppler es correcta, pero la fuente sintética no tiene la aspereza de un DB 605 o un BMW 801 reales.
3. **gun_m2_shot_01..03.wav**: El jugador lo dispara cientos de veces: un estampido real de M2 (con el mecanismo) daría mucho más peso.
4. **flak_near_01..03.wav**: Una explosión real tiene una textura y una cola imposibles de imitar con ruido filtrado.
5. **stinger_mission_complete.wav / stinger_mission_failed.wav**: Una sección de metales real (o al menos un instrumento muestreado) sonaría claramente más cuidada que las sierras filtradas.

## Cómo regenerar y verificar

```bash
cd /home/test-bench/Documents/B17-project
python3 -I tools_audio/synth_sfx.py          # o con grupos: python3 -I tools_audio/synth_sfx.py A D
python3 -I tools_audio/check_sfx.py
tools/godot --headless --path godot/B17 --import
tools/godot --headless --path godot/B17 --script res://tests/test_audio_assets.gd
python3 -I tools_audio/make_report.py
```

## Notas para la integración (paso del supervisor)

- Disparos: usar `gun_m2_shot_01..03` al azar, con un `pitch_scale` aleatorio de ±3 %, en un `AudioStreamPlayer` con `max_polyphony` ≥ 4. `gun_m2_burst` sirve para ráfagas preconstruidas o en la distancia.
- `engine_b17_ext_loop` y `engine_b17_int_loop` tienen la misma duración: se puede hacer un fundido cruzado entre ellos al cambiar de vista. `engine_b17_damaged_loop` está pensado como capa sobre el motor sano.
- Los stingers y las pasadas son estéreo. Las pasadas ya llevan su panorámica, así que deben ir en un `AudioStreamPlayer` sin espacialización, no en un `AudioStreamPlayer3D`.
