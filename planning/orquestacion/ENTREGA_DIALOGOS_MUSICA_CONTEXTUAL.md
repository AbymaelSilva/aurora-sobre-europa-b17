# Entrega integrada — conversaciones, música y flak, Europa 1945

## Resultado actual

- 28 líneas originales, audibles en inglés estadounidense mediante dos voces Piper en_US (joe/john), con subtítulos españoles sincronizados al archivo real. No son actores ni grabaciones de 1945; fraseología original y procesado de radio orientados al contexto.
- 7 piezas instrumentales originales según formación, aproximación, combate cercano, bombardeo, regreso y desenlace. Renderizadas con instrumentos muestreados FluidSynth/TimGM6mb. No se copiaron bandas sonoras de películas.
- Cola de diálogos acotada, prioridades, no repetición por frame, pausa/reanudación, reinicio y eliminación de conversaciones pendientes al cambiar de fase. Fallar el objetivo no anuncia falsamente destrucción del avión.
- Música con transiciones de 2 s; reducción suave durante voz de hasta 8 dB en música y 5 dB en efectos. Menú de pausa permite silenciar música y voces manteniendo subtítulos; F6/F7 como atajos.
- Los 42 efectos nuevos del Codex de audio ya están promovidos y validados; cinco archivos M2 intactos según hashes originales. Flak basado en grabaciones de demolición TNT adaptadas: aproximación sonora declarada, no grabación histórica de 88 mm en vuelo.
- DenseFlakField conectado: pool 128, tres sprites por bocanada, ~8–10 emisiones/s, vidas 8–12 s; concentración frontal del 70% y resto alrededor de formación. Audio limitado a cuatro voces y eventos por proximidad, con variantes cerca/lejos reales. No multiplica el daño lógico. Pausa y reset limpian estados.
- Cámara orbital/observación de compañeros y escoltas conservada; cien nubes en dos capas, atlas OpenArt nuevo y niebla 0.000025. HUD localizado en Europa 1945.

## Archivos y fuentes

Nuevo director `audio/scene_audio_director.gd`; integración en `game.gd`; subtítulos en `ui/mission_overlay.gd`; controles de audio en `ui/settings_menu.gd`. Guion: `assets/audio/voice/dialogue_catalog.json`. Partitura: `assets/audio/music/music_catalog.json`. Construcción y validación: `tools_voice/build_scene_audio.py` y `check_scene_audio.py`. Fuente/licencias: `assets/audio/SOURCES_DIALOGUE_MUSIC.md`, `art/dialogue/licenses/` y fichas de modelos. Herramientas descargadas y extraídas dentro del proyecto, sin instalación global ni pagos.

Partitura y TTS son recursos renderizados offline; no se ejecuta inferencia durante el juego. Los WAV de diálogo españoles iniciales se reemplazaron por los en_US en las mismas rutas, no se reproducen simultáneamente. Los originales de trabajo fuera del banco activo se conservan para trazabilidad.

## Verificaciones reales

35 archivos de voces/música con PCM16/44100, niveles y duraciones correctos; bucles musicales con unión comprobada; 5 M2 idénticos. Regresión de 16 pruebas PASS: voces, música, subtítulos, cámara, flak, nubes, perfiles, menú, audio, pausa/reinicio y dirección de tiro. Tras corrección de idioma, test_scene_audio y validador de activos vuelven a PASS con voces en_US. Pruebas headless de integración aún emiten avisos de recursos retenidos al cerrar; no se declara cierre limpio de toda la infraestructura histórica.

GPU de escritorio: NVIDIA GeForce RTX 2060 SUPER, ventana real (1280.0, 720.0), 60.02 s, 3592 frames, FPS medio 59.85, mediana 16.641 ms, p95 16.892 ms. Flak activo 78–89, 100 nubes. Fixture invulnerable de carga estable y física fija 1/60 por frame: mide presentación/rendimiento, no supervivencia/dificultad.

Revisión visual adicional de 5.02 s en viewport real (1920.0, 1080.0), FPS medio 55.83; es una comprobación breve de resolución/legibilidad, no una medición de un minuto a 1080p. Capturas en `logs/dialogue_music/`. Subtítulos y ayuda de cámara revisados visualmente, sin solaparse.

## Límites y siguiente encargo

No se realizó escucha humana por parte del agente ni prueba de mando físico o Ally X. La valoración de voces, música, mezcla y flak corresponde al usuario. Las fuentes aproximadas de algunos efectos están descritas en la entrega del Codex de audio.

El Lote 9, más interceptores/combate cinematográfico, queda separado y solo arranca tras la señal explícita de cierre de este trabajo. Prompt: `planning/orquestacion/PROMPT_COMBATE_CINEMATICO_1945_LOTE9.md`. No se da por implementado aquí el incremento de 30 a 48 cazas.
