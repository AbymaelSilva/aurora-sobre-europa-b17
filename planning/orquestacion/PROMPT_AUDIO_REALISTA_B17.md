# Encargo Codex — Audio contextual de B-17; M2 validada e intocable

## 1.1.1.0 Objetivo y contexto

- **1.1.1.1** Trabaja en `/home/test-bench/Documents/B17-project`, motor definitivo Godot, proyecto `godot/B17`. El usuario ordena mejorar, generar/adaptar e integrar el set de sonidos según el contexto del juego, EXCEPTO la ametralladora Browning M2 .50 ya validada. Entrega archivos y comprobaciones; no te detengas en otro plan.
- **1.1.1.2** Contexto: B-17G, Europa en invierno de 1944, formación masiva aliada, escoltas P-51, Bf 109/Fw 190, flak de 88 mm, daños, bombardeo en salva sobre nudo ferroviario y regreso. Tres puestos, ahora con cámara exterior orbital. Confirma comportamiento y cantidades actuales en código sin restaurar valores de informes antiguos.
- **1.1.1.3** El usuario rechazó los efectos sintéticos anteriores: parecían saltos de Mario Bros. Añadir ruido sobre un seno descendente no eliminaba el timbre arcade. Prioriza grabaciones del fenómeno correcto con licencia compatible; no declares sonido auténtico por cambiar el nombre de una síntesis genérica.
- **1.1.1.4** Otro Codex integra cámara y controles. NO edites `game.gd`, `camera/`, `core/player_controls.gd`, UI, escenas, gráficos, nubes, flak visual, balística, `release/` ni snapshots. No cierres agentes ni el juego del usuario. No abras otra ventana de juego ni reproduzcas audio automáticamente encima de ella.

## 1.1.2.0 M2 protegida byte por byte

- **1.1.2.1** NO modificar `gun_m2_shot_01.wav`, `gun_m2_shot_02.wav`, `gun_m2_shot_03.wav`, `gun_m2_burst.wav` ni `gun_casings_01.wav`. Son cinco archivos protegidos; quedan **42 archivos autorizados para reemplazo** en el catálogo de 47. Hashes iniciales: `logs/audio_redesign/m2_protected_hashes.json`.
- **1.1.2.2** No cambies muestreo, tono, volumen, normalización, duración ni contenido de esos cinco WAV. No regeneres el grupo B. No ejecutes el sintetizador completo sobre el banco activo. No modifiques `build_recorded_m2.py`, `assets/audio/source_m2/` ni atribución CC0 de ikbenraar.
- **1.1.2.3** Conserva el AudioStreamRandomizer de M2 sin variación de tono y la función antigua `combat_sfx.gd` que ahora carga el WAV vigente. No restaures su generador sintético. Comprueba hashes tras cada promoción y al terminar; cualquier cambio accidental debe restaurarse de inmediato y documentarse.

## 1.1.3.0 Auditoría, candidatos y contrato

- **1.1.3.1** Lee `assets/audio/SOURCES_AUDIO.md`, `planning/orquestacion/ENTREGA_AUDIO_REALISTA_B17.md`, `tools_audio/synth_sfx.py`, `synth_realista.py`, `check_sfx.py`, `audio/sfx_bank.gd` y los consumidores de `game.gd` en modo lectura. Los documentos que dicen que todos los sonidos son sintéticos describen el set anterior; la M2 actual procede de grabación.
- **1.1.3.2** Conserva nombres exactos, duraciones y canales del checker y `tests/test_audio_assets.gd`. WAV PCM16 a 44100 Hz, pico ≤−1 dBFS, sin recorte ni desplazamiento continuo relevante. RMS inicial de motores/ambientes alrededor de −20, impactos/armas −14 e interfaz −22 dBFS. No destruyas transitorios para igualar niveles.
- **1.1.3.3** Candidatos: `art/audio/redesign_v4/candidates/`. Originales y licencias: `art/audio/redesign_v4/sources/`. Respaldo de los 42 WAV vigentes: `logs/audio_redesign/backup/`. Manifiesto por archivo con fuente, autor, URL, licencia, hash original/final, recorte, filtros, nivel, duración y si es grabación, derivado o síntesis.
- **1.1.3.4** Verifica herramientas antes de asumirlas. Hay Python estándar y Godot; GStreamer se usó para decodificar MP3 a PCM. No asumas ffmpeg/numpy/Pillow instalados ni instales modelos pesados. No compres créditos. OpenArt no tiene aquí capacidad confirmada para generar WAV independientes.

## 1.1.4.0 Especificación de los 42 efectos permitidos

- **1.1.4.1** `engine_b17_ext_loop.wav`, `engine_b17_int_loop.wav`, `engine_b17_damaged_loop.wav`, `engine_sputter_01/02.wav`: textura de motores radiales de pistón, escape irregular, paso de hélice y estructura. Exterior áspero, interior filtrado y vibrante sin convertirse en seno grave. El dañado se suma al sano: evita duplicar cuatro motores enteros. No uses jets o coches como sustituto principal sin declarar su inadecuación.
- **1.1.4.2** `engine_fire_loop.wav`, `wind_altitude_loop.wav`, `formation_drone_loop.wav`: fuego arrastrado por viento, rachas de fuselaje y campo lejano difuso de otros aviones. Evita silbidos puros y ruido blanco estático. Bucles sin clics, huecos ni oleadas excesivamente periódicas; evalúa fatiga durante una misión.
- **1.1.4.3** `hit_hull_01/02/03.wav`, `shrapnel_rattle_01.wav`, `damage_alarm_bell.wav`: chapa de aluminio perforada, granizo de fragmentos y timbre electromecánico. Impactos secos e inarmónicos, sin campanas musicales. Reserva timbre sostenido para la alarma de tripulación.
- **1.1.4.4** `fighter_flyby_01/02.wav`, `fighter_engine_loop.wav`, `fighter_falling_whine.wav`: aeronaves de pistón con aproximación, estela y alejamiento; variantes distinguibles. Sin láser, caricatura ni turbina moderna. No dupliques Doppler/panorámica ya incorporados al WAV con procesado posterior.
- **1.1.4.5** `fighter_guns_distant.wav`, `fighter_explosion.wav`: cañoneo amortiguado distante y rotura aérea con combustible/metal. NO modifiques ni mezcles el set propio M2. Una caída no implica siempre una explosión gigantesca de película.
- **1.1.4.6** `flak_near_01/02/03.wav`, `flak_far_01/02.wav`: frente de presión seco cerca, retumbo amortiguado lejos con información en medios graves. Sin reverberación de catedral, subgrave como única información ni metralla contra el avión en cada bocanada sin daño. Variantes aptas para repetición frecuente sin fatiga.
- **1.1.4.7** `bomb_bay_doors_open.wav`, `bomb_release.wav`: motores/engranajes, pestillos, bisagras y entrada de viento; desprendimiento mecánico, nunca pitido de premio. Evita acumulación desagradable durante la salva, preservando el contrato de eventos.
- **1.1.4.8** `bomb_impact_distant.wav`, `bomb_secondary_explosions.wav`: detonaciones terrestres oídas desde la altura de misión, amortiguadas y de tamaños distintos. No insertes varios segundos de silencio para simular propagación; depende de distancia en ejecución y este encargo no cambia la balística.
- **1.1.4.9** `ui_navigate.wav`, `ui_accept.wav`, `ui_back.wav`, `ui_pause.wav`, `ui_profile_change.wav`, `station_switch.wav`: pulsadores, interruptores, relés e interfono breves y sobrios. Diferencia por ritmo y peso, sin arpegios ni blips senoidales expuestos. Son accesibilidad de juego, no una reproducción histórica documentada de instrumentos.
- **1.1.4.10** `cue_release_tick.wav`, `cue_release_now.wav`, `cue_course_correction.wav`: patrones mecánicos/interfono cortos y distinguibles, audibles sobre motores sin resultar chillones. Nada parecido a moneda, salto ni láser arcade.
- **1.1.4.11** `radio_squelch_open.wav`, `radio_squelch_close.wav`, `radio_static_loop.wav`: radio de banda limitada, chasquidos, irregularidad y saturación suave; ruido discreto que no canse. No afirmes que existen mensajes hablados si solo entregas estática.
- **1.1.4.12** `stinger_mission_complete.wav`, `stinger_mission_failed.wav`: cierres de 4 s sobrios, alivio al regresar y pérdida al fracasar. Transición ambiental o instrumentos acústicos con licencia si existen. Sin fanfarria arcade ni metales con sierras demasiado evidentes.

## 1.1.5.0 Fuentes y producción

- **1.1.5.1** Prioriza grabación propia, CC0 o licencia que permita adaptación e inclusión en el juego. Lee la página INDIVIDUAL. No uses previews de bancos comerciales de pago sin licencia. Si requiere atribución, consérvala. No extraigas audio de películas, series u otros videojuegos.
- **1.1.5.2** Guarda originales y licencia verificable. Una preescucha pública CC0 puede servir de fuente, pero declara compresión y perspectiva. Evita voces, música, watermark y ruido ajeno. No transformes una fuente genérica en «grabación histórica B-17» por el nombre del archivo.
- **1.1.5.3** Conserva transitorios y monta colas mediante fundidos. En bucles comprueba continuidad de textura/envolvente durante diez repeticiones, además de la unión entre muestras. Las variantes deben diferir por contenido cuando sea posible, no solo pitch.
- **1.1.5.4** Si no encuentras fuente pertinente, el fóley/síntesis por capas es una aproximación explícita. Excitación aperiódica para mecánica; no seno descendente como cuerpo universal de explosiones ni resonador afinado como chapa. El generador anterior es referencia temporal, no calidad aceptada.
- **1.1.5.5** Piloto inicial: motor exterior/interior, flak cercano y cambio de puesto. Verifica contexto y formato antes de extender la técnica al resto. Si no puedes escuchar, declara esa limitación; no inventes escucha propia, autoevaluación ni aceptación del usuario.

## 1.1.6.0 Integración y comprobaciones

- **1.1.6.1** Mantén la API de SfxBank sin editar juego. Integra solo los 42 candidatos validados sobre `assets/audio/sfx/` por nombre. No borres `.import` a ciegas ni modifiques caches para ocultar archivos incorrectos.
- **1.1.6.2** Crea `tools_audio/build_contextual_set.py` o proceso reproducible equivalente basado en fuentes LOCALES. Debe usar lista explícita de 42 destinos y guardas de hashes para los cinco protegidos. Una regeneración jamás escribe los protegidos. No rompas scripts de M2 ni reescribas informes históricos como si describieran estas fuentes nuevas.
- **1.1.6.3** Ejecuta `python3 -I tools_audio/check_sfx.py`, importación local Godot y `tests/test_audio_assets.gd`, secuencialmente cuando no haya otro importador. Conserva logs/códigos de salida. No relajes límites para aprobar tus recursos.
- **1.1.6.4** Comprueba formato, canales, duración, niveles, ausencia de silencio/clics/clipping y hashes M2 intactos. Enumera qué archivos cambiaron de verdad: no declares 42 sustituidos si algunos son idénticos a los anteriores.
- **1.1.6.5** Deja comparación A/B de pilotos con nivel comparable en `art/audio/redesign_v4/review/`, sin alterar ni incluir la M2. NO reproduzcas esos audios automáticamente sobre el juego. Los PASS verifican compatibilidad; la aprobación perceptiva sigue siendo del usuario.
- **1.1.6.6** Actualiza `assets/audio/SOURCES_AUDIO.md` con procedencia actual y conserva historial identificado. Entrega `planning/orquestacion/ENTREGA_AUDIO_CONTEXTUAL_SIN_TOCAR_M2.md`: 42 resultados, cinco hashes protegidos, fuentes/licencias, técnicas, límites, pruebas y A/B. Documenta cualquier familia bloqueada y continúa lo independiente.
- **1.1.6.7** Al acabar crea `logs/audio_redesign/LISTO_PARA_RECARGAR.md` con estado real y comandos. El supervisor recargará el juego. No abras otra ventana ni cierres la validación de cámara del usuario.

## 1.1.7.0 Condición de cierre

- **1.1.7.1** Los 42 efectos permitidos se generaron/adaptaron y promovieron con procedencia documentada y compatibilidad verificada. Los cinco recursos M2 son idénticos byte a byte. Distingue integración, limitaciones perceptivas y pendientes. No declares realismo aprobado por métricas ni escucha humana inexistente.
