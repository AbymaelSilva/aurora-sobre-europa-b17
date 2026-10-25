# Procedencia de conversaciones y partitura — revisión en-US, Europa 1945

## Guion y localización

28 líneas originales redactadas para esta misión ficticia, con `spoken_text` en inglés estadounidense y `text` para subtítulos en español. Los papeles son piloto, compañero, navegante, artillero, bombardero, mecánico y control; se usan dos voces base de catálogo. No se copiaron guiones ni bandas sonoras de películas y no se imitaron actores. El tratamiento de radio y el léxico evocan una localización de 1945; no son grabaciones históricas ni una recreación lingüística certificada de esa fecha.

Catálogo: `voice/dialogue_catalog.json`, con duraciones reales y hashes. Construcción: `tools_voice/build_scene_audio.py --voice-only`; originales sin filtro en `art/dialogue/raw/`, con voz y texto incorporados al hash de caché. Los modelos españoles probados al principio no son los usados por los WAV activos finales.

## Voces

Generación offline con Piper 2023.11.14-2, distribución oficial de https://github.com/rhasspy/piper/releases/tag/2023.11.14-2, aislada en `tools_voice/piper/`. Versiones, URLs y hashes en `tools_voice/downloads.json` y `downloads_en_US.json`. Licencias incluidas por el distribuidor en la carpeta de herramientas; no se necesita Piper en el ejecutable del juego.

- `en_US-joe-medium`: inglés de Estados Unidos, un hablante, 22050 Hz; [ficha del modelo](https://huggingface.co/rhasspy/piper-voices/blob/main/en/en_US/joe/medium/MODEL_CARD), dataset declarado CC0. Copia de ficha en `tools_voice/joe_MODEL_CARD.md`.
- `en_US-john-medium`: inglés de Estados Unidos, un hablante, 22050 Hz; [ficha del modelo](https://huggingface.co/rhasspy/piper-voices/blob/main/en/en_US/john/medium/MODEL_CARD), dataset declarado de dominio público de LibriVox, preparado por Bryce Beattie. Copia de ficha en `tools_voice/john_MODEL_CARD.md`.

Procesado: recorte conservador de silencio, remuestreo PCM a 44100 Hz, banda 220–3500 Hz, saturación suave, estática tenue y fundidos. Salida mono PCM16. Se conserva texto original de voz y traducción por separado. La síntesis puede tener limitaciones de pronunciación/interpretación; pendiente de valoración auditiva del usuario.

## Música

Siete piezas instrumentales originales creadas para esta misión mediante secuencias de notas nuevas: formación, aproximación, combate, pasada de bombardeo, regreso, misión cumplida y pérdida. No se usó melodía de ninguna película. Son instrumentos muestreados renderizados, no una orquesta humana grabada.

Renderizado offline con FluidSynth 2.4.8 y banco TimGM6mb: cuerdas, violonchelo, trompa, piano, oboe y percusión contenida. Paquetes Ubuntu descargados y extraídos en `tools_voice/runtime`, sin instalación global. TimGM6mb atribuido a Tim Brechbill (2004) y David Bolton (2010), licencia GPL-2 según su paquete Debian/Ubuntu. Copia íntegra de avisos en `art/dialogue/licenses/`; se conserva el banco original sin modificar en herramientas. Composición y renderizados propios registrados en `music/music_catalog.json`.

Partes de fase: bucles estéreo de 32 s con prerroll y unión cruzada de 0,5 s. Cierres: 16 s de éxito y 12 s de pérdida con fundido final. Salida PCM16 estéreo 44100 Hz. Mezcla adaptativa con transiciones de 2 s y descenso temporal de música/efectos durante diálogo. Menú de pausa permite silenciar música o voces conservando subtítulos; F6/F7 son atajos de teclado.

## Independencia del set M2

Esta herramienta no escribe `assets/audio/sfx/`. Los cinco WAV de la M2 validados por el usuario se cotejan con `logs/audio_redesign/m2_protected_hashes.json`. La reducción temporal del bus de efectos durante radio no modifica sus archivos ni su generador.
