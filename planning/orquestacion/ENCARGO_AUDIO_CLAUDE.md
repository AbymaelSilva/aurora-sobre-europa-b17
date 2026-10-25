# Encargo para Claude (terminal de audio) — Set de sonidos de «Aurora sobre Europa» (B-17)

## Meta (condición de terminado)
Obtener un SET COMPLETO de efectos de sonido para el juego: los 47 archivos WAV de la lista de abajo existen en
`/home/test-bench/Documents/B17-project/godot/B17/assets/audio/sfx/` y pasan la verificación automática.
Además están `assets/audio/SOURCES_AUDIO.md` (origen y licencia) e `planning/orquestacion/ENTREGA_AUDIO_CLAUDE.md` (informe).
No termines con un plan: termina con los archivos generados y verificados.

## Contexto (no lo cambies)
- Juego Godot 4.7.2 en `godot/B17`. Misión de un B-17G en formación de 6, en 1944: cazas Bf 109 y Fw 190, flak, pasada de bombardeo con mira Norden, regreso y fin de misión. Tres puestos: piloto, artillero (torreta con ametralladoras .50) y bombardero.
- Hoy el audio es procedural y mínimo: `godot/B17/audio/engine_tone.gd` y `audio/combat_sfx.gd`. Léelos como referencia.
- NO modifiques código de producción (`*.gd` fuera de `tools_audio/` y de las pruebas nuevas) ni la escena. La integración en el juego es un paso posterior que hará el supervisor. Tampoco toques `release/`.
- No hay modelo de audio en OpenArt, numpy, ffmpeg ni sox. Sí hay Python 3 con la biblioteca estándar y Godot en `tools/godot`.
- Ningún sonido descargado ni de terceros: todo sintetizado aquí, sin problemas de licencia.

## Método obligatorio
1. Escribe un sintetizador reproducible en `/home/test-bench/Documents/B17-project/tools_audio/synth_sfx.py` usando SOLO la biblioteca estándar (wave, struct, math, random con semilla fija por archivo). Bloques reutilizables:
   - osciladores (seno, sierra, cuadrada, pulso);
   - ruido blanco y rosa;
   - filtros biquad (paso bajo, paso alto, paso banda y resonante);
   - envolventes ADSR y exponenciales;
   - distorsión suave (tanh);
   - modulación AM y FM;
   - doppler, mediante variación de tono y volumen;
   - reverberación sencilla, con varias líneas de retardo con realimentación;
   - fundido cruzado para que los bucles no tengan clic.

   Ejecuta con `python3 -I tools_audio/synth_sfx.py`. Debe regenerar el set completo, de forma idéntica, en cada ejecución.
2. Formato: WAV PCM de 16 bits a 44 100 Hz. **Mono**, salvo los marcados con (E), que van en estéreo. Pico máximo de −1 dBFS, sin recortes. Silencio inicial de 10 ms como máximo en los sonidos de un disparo.
3. Bucles (marcados con BUCLE): duración indicada, sin clic en la unión (fundido cruzado de unos 150 ms o corte en paso por cero) y sin silencio al principio ni al final.
4. Niveles coherentes: motores y ambientes, RMS en torno a −20 dBFS; armas e impactos, en torno a −14 dBFS; interfaz, en torno a −22 dBFS.
5. Realismo: capas de ruido filtrado más tono, transitorios marcados, colas con reverberación corta de exterior a gran altitud y pequeñas variaciones aleatorias entre variantes. Evita que suene a «videojuego de 8 bits» salvo en los sonidos de interfaz, que pueden ser limpios.

## Lista de sonidos (47 archivos)

### A. B-17: motores y vuelo
| Archivo | Descripción | Duración |
|---|---|---|
| engine_b17_ext_loop.wav | 4 motores radiales Wright R-1820 Cyclone a crucero (~2300 rpm): zumbido grave pulsante, batido entre los 4 motores ligeramente desafinados y hélices. Vista exterior de persecución | BUCLE 8 s |
| engine_b17_int_loop.wav | Lo mismo oído desde dentro del fuselaje: más grave, filtrado y con vibración de la estructura. Puestos de artillero y bombardero | BUCLE 8 s |
| engine_b17_damaged_loop.wav | Un motor tocado: petardeos irregulares, fallos de encendido y tono inestable | BUCLE 6 s |
| engine_sputter_01.wav, engine_sputter_02.wav | Tos y petardeo de un motor al recibir daño | 1,0–1,5 s |
| engine_fire_loop.wav | Fuego o humo en el motor: rugido de llamas con viento | BUCLE 5 s |
| wind_altitude_loop.wav (E) | Viento a 4000 m pasando por el fuselaje y las rendijas | BUCLE 10 s |
| formation_drone_loop.wav (E) | Los otros 5 B-17 de la formación a distancia: zumbido lejano y amplio | BUCLE 10 s |

### B. Armas propias (torreta y ametralladoras .50 M2)
| Archivo | Descripción | Duración |
|---|---|---|
| gun_m2_shot_01.wav … gun_m2_shot_03.wav | Un disparo de .50 desde la torreta: golpe seco y potente con chasquido mecánico. Variantes para la cadencia de 0,12 s | 0,25–0,35 s |
| gun_m2_burst.wav | Ráfaga corta de ~8 disparos de la torreta doble | 1,0 s |
| gun_casings_01.wav | Casquillos metálicos cayendo sobre el suelo de la torreta | 0,8 s |

### C. Daños en el propio avión
| Archivo | Descripción | Duración |
|---|---|---|
| hit_hull_01.wav … hit_hull_03.wav | Impactos de bala contra el fuselaje de aluminio: chasquido metálico y perforación | 0,2–0,4 s |
| shrapnel_rattle_01.wav | Metralla de flak golpeando el fuselaje como granizo | 0,8 s |
| damage_alarm_bell.wav | Timbre de alarma de la tripulación, tipo campana eléctrica, 3 toques | 1,5 s |

### D. Cazas enemigos (Bf 109 y Fw 190)
| Archivo | Descripción | Duración |
|---|---|---|
| fighter_flyby_01.wav (E), fighter_flyby_02.wav (E) | Caza monomotor pasando cerca a gran velocidad: aproximación, doppler y alejamiento, panorámica de izquierda a derecha | 3,0–4,0 s |
| fighter_engine_loop.wav | Motor de caza en línea (DB 605 / BMW 801) más agudo y áspero que el B-17 | BUCLE 4 s |
| fighter_guns_distant.wav | Cañones de 20 mm y ametralladoras del caza a 300–600 m: tableteo rápido y amortiguado | 1,2 s |
| fighter_explosion.wav | Caza alcanzado que estalla en el aire: explosión media con cola | 2,5 s |
| fighter_falling_whine.wav | Caza derribado cayendo: aullido de motor que baja de tono y se aleja | 4,0 s |

### E. Antiaérea (flak)
| Archivo | Descripción | Duración |
|---|---|---|
| flak_near_01.wav … flak_near_03.wav | Proyectil de 88 mm que estalla cerca: estampido fuerte y seco con metralla y cola | 1,2–1,8 s |
| flak_far_01.wav, flak_far_02.wav | Estallido lejano: «pum» sordo y grave | 1,5 s |

### F. Bombardeo
| Archivo | Descripción | Duración |
|---|---|---|
| bomb_bay_doors_open.wav | Motor eléctrico y bisagras de las puertas de la bodega abriéndose, con más viento | 2,5 s |
| bomb_release.wav | Golpe mecánico del soporte al soltar la bomba | 0,5 s |
| bomb_impact_distant.wav | Explosión de la bomba sobre el nudo ferroviario, oída desde 3500 m: retumbo grave retardado | 3,0 s |
| bomb_secondary_explosions.wav | Explosiones secundarias en cadena en la estación (vagones y depósitos) | 4,0 s |

### G. Interfaz, HUD y radio
| Archivo | Descripción | Duración |
|---|---|---|
| ui_navigate.wav | Mover el foco en el menú: clic suave | 0,06 s |
| ui_accept.wav | Aceptar: clic con tono ascendente | 0,15 s |
| ui_back.wav | Volver o reanudar: tono descendente | 0,15 s |
| ui_pause.wav | Abrir la pausa: golpe apagado | 0,3 s |
| ui_profile_change.wav | Cambiar el perfil de control (◀ ▶): doble tic | 0,12 s |
| station_switch.wav | Cambiar de puesto: clic del interfono y un breve soplido | 0,25 s |
| cue_release_tick.wav | Cuenta atrás de «VENTANA DE SUELTA»: tic suave | 0,08 s |
| cue_release_now.wav | «SUELTA AHORA»: dos tonos claros y urgentes que no cansen | 0,4 s |
| cue_course_correction.wav | «CORRECCIÓN DE RUMBO»: tono de aviso medio | 0,3 s |
| radio_squelch_open.wav | Inicio de un mensaje de radio: chasquido y ruido de estática | 0,25 s |
| radio_squelch_close.wav | Fin del mensaje: «chsk» corto | 0,2 s |
| radio_static_loop.wav | Estática de fondo de la radio de 1944, de banda estrecha | BUCLE 4 s |

### H. Misión
| Archivo | Descripción | Duración |
|---|---|---|
| stinger_mission_complete.wav (E) | Fin de misión con éxito: acorde sostenido de metales sintetizados, sobrio y esperanzado | 4,0 s |
| stinger_mission_failed.wav (E) | Misión fallida o avión perdido: acorde menor grave que se apaga | 4,0 s |

(En total son 47 archivos.)

## Verificación obligatoria (debe pasar antes de terminar)
1. `tools_audio/check_sfx.py` (biblioteca estándar) recorre todos los archivos y comprueba:
   - que existen los 47 nombres exactos;
   - formato 16 bits a 44 100 Hz y número de canales según la tabla;
   - duración dentro del ±15 % de la indicada;
   - pico ≤ −1 dBFS y ninguna muestra recortada;
   - RMS dentro del ±6 dB del objetivo de su grupo;
   - en los BUCLES, salto entre la última y la primera muestra < 2 % de la escala completa;
   - que ningún archivo es silencio ni ruido blanco puro (variación de RMS por ventanas).

   Guarda la salida en `logs/audio/check_sfx.log` y el resumen en JSON en `logs/audio/check_sfx.json`.
2. Prueba de Godot `godot/B17/tests/test_audio_assets.gd`: carga cada WAV con `AudioStreamWAV.load_from_file` (o importándolo), comprueba que tiene datos, mix_rate 44100 y la duración, y termina con `TEST PASS`. Ejecútala con:
   `/home/test-bench/Documents/B17-project/tools/godot --headless --path /home/test-bench/Documents/B17-project/godot/B17 --script res://tests/test_audio_assets.gd`
   Ejecuta antes `tools/godot --headless --path godot/B17 --import` para que Godot cree los .import.
3. Hoja de escucha `planning/orquestacion/ENTREGA_AUDIO_CLAUDE.md`: por archivo, duración, pico, RMS, la técnica de síntesis usada y una autoevaluación honesta (qué suena convincente y qué es aproximado). Indica qué 5 sonidos mejorarían más con una grabación real.
4. `assets/audio/SOURCES_AUDIO.md`: todos los sonidos sintetizados por Claude con tools_audio/synth_sfx.py, sin material de terceros, licencia de uso propio.

## Reglas
- Escribe un registro de avance en `logs/orquestacion/claude_audio.log` (una línea con fecha por cada grupo A–H terminado). El supervisor lo muestra en su consola.
- Si algo falla, corrígelo tú y vuelve a ejecutar la verificación. No declares terminado con fallos.
- El disco está al 93 %: no guardes copias intermedias grandes; el set completo debería ocupar menos de 60 MB.
