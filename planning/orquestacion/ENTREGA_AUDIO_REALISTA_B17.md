# Entrega de audio revisado — 2026-10-24

Se regeneraron e integraron los 47 WAV con `tools_audio/synth_realista.py`, reutilizando el sintetizador de Claude y conservando nombres, duraciones y canales. Ocho señales de UI/ayuda usan mecanismos amortiguados; los dos stingers usan cierres ambientales sin acordes. Se añadió textura irregular a motores, cuerpo a armas/explosiones y amortiguación a impactos. Todo es síntesis local sin material de terceros.

Respaldo: `logs/audio/backup-realista-20261024T171430/`. Los hashes previos están en `hashes.json`; los actuales, junto con las métricas por archivo, en `logs/audio/check_sfx.json`. Técnicas: `logs/audio/synth_manifest.json`.

Verificación realizada:
- `python3 -I tools_audio/check_sfx.py`: 47/47 PASS, 12.44 MB.
- Importación Godot: salida 0.
- `test_audio_assets.gd`: TEST PASS, 47 WAV cargados.
- `test_audio_integration.gd`: TEST PASS. Al cerrar la prueba se informan 22 ObjectDB y 5 recursos retenidos; la prueba funcional pasa pero ese cierre no está limpio.
- Juego iniciado en ventana 1280x720; PID en `logs/audio/juego_realista.pid`, salida en `logs/audio/juego_realista.log`.

La integración utiliza las rutas ya activas de SfxBank y no cambia código de juego. No se ha realizado escucha humana, comparación A/B ni prueba física en Ally X. Queda la validación perceptiva del usuario; las métricas no certifican realismo histórico. La siguiente regeneración debe usar `synth_realista.py`; `synth_sfx.py` genera el set anterior.

## Corrección v3 de disparos tras escucha del usuario

El usuario rechazó el timbre de los disparos por parecer saltos de Mario Bros. La revisión v2 conservaba el seno descendente y resonadores del generador original: añadir ruido no resolvía ese componente. Se sustituyeron los tres disparos y la ráfaga M2 por excitaciones aperiódicas de ruido filtrado y cerrojos secos, sin senos, barridos ni resonadores. Regeneración: `python3 -I tools_audio/synth_realista.py B`. Respaldo v2: `logs/audio/backup-disparos-v2/`. Verificador 47/47 PASS; importación salida 0. La aceptación del timbre sigue pendiente del usuario; no se declara escucha propia ni realismo aprobado.

## M2 grabada y eliminación del audio duplicado

Los cuatro efectos M2 se sustituyeron por material CC0 de ikbenraar (Freesound 339976), identificado por el autor como M2 .50. Es una grabación de campo en MP3 de preescucha, no una toma AN/M2 aérea. El script `build_recorded_m2.py` adapta ataques/colas sin osciladores. `synth_realista.py` aplica ahora ese script tras regenerar B. Se registró la procedencia en SOURCES_AUDIO.md. El reproductor usa AudioStreamRandomizer con tono fijo y 4 voces, sin reasignar stream en cada disparo. La función antigua create_gun_stream carga el nuevo WAV.

Se cerraron las instancias 1549080 (benchmark anterior) y 1555146 (juego anterior) tras la queja de audio empalmado. Se abrió una instancia nueva. Las versiones anteriores se conservan como respaldo fuera del banco activo. Checker 47/47 PASS; carga de 47 WAV PASS; integración PASS con avisos de recursos retenidos al cerrar la prueba; compatibilidad combat_sfx salida 0. Pendiente de aceptación auditiva del usuario.
