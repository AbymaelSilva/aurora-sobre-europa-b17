# Directiva técnica — Conversaciones audibles, subtítulos y partitura adaptativa

## 1.1.1.0 Contexto, ejecución y conservación

- **1.1.1.1** Implementar en `/home/test-bench/Documents/B17-project/godot/B17`: conversación original de aviadores, audible en inglés estadounidense de época (1945) y subtitulada en español, más música instrumental según la escena del B-17G sobre Europa en invierno de 1945. Producir archivos locales, cerrar el juego antes de integrar, comprobar y abrir una única instancia para el usuario.
- **1.1.1.2** Conservar cámara orbital, nubes, niebla reducida y los cinco WAV M2 validados. Otro Codex reemplaza efectos en `assets/audio/sfx`; este trabajo solo escribe `assets/audio/voice`, `assets/audio/music` y sus propios scripts/datos. Coordinar importación mediante `logs/dialogue_music/import.lock`, sin sobrescribir generadores ni archivos del encargo de efectos.
- **1.1.1.3** Diálogos en español como localización de una tripulación ficticia estadounidense; no afirmar autenticidad histórica literal. Nada de copiar diálogo o música de películas/series, clonar actores ni reutilizar bandas sonoras. Guardar atribución de modelos, instrumental y técnicas.

## 1.1.2.0 Voces y guion

- **1.1.2.1** Catálogo JSON por línea: ID estable, personaje, texto exacto del subtítulo, modelo TTS, prioridad, WAV y duración real. Usar Piper local con dos modelos en_US (joe y john) y cadencias moderadas por papel; dos voces base, no cuatro actores distintos. No presentar TTS como grabación humana.
- **1.1.2.2** Generar conversación de formación (líder/compañero/artillero), aproximación (navegante/piloto), contacto con cazas (artillero/piloto), flak (artillero/piloto), motores/fuselaje dañados, preparación de bombardeo, suelta, impacto/fallo, regreso y desenlace. Frases breves de 2–7 s, claras y sin solapamiento. Afirmar impacto solo cuando la simulación lo confirma.
- **1.1.2.3** Voz radiofónica legible: banda aproximada 220–3500 Hz, saturación leve, estática muy tenue, pico menor de −1 dBFS y nivel cercano a −18 dBFS RMS. No aplicar filtros tan estrechos que se pierdan consonantes ni reverberación de sala.

## 1.1.3.0 Director de escenas de audio

- **1.1.3.1** Nuevo `audio/scene_audio_director.gd` con cola acotada, prioridad y exclusión de diálogo simultáneo. Detectar cambios de `sim.mission.phase`, primera aparición real de cazas, primer flak, umbrales de daño, suelta y resultado de bomba. No disparar una frase cada frame. Limpiar conversaciones de una fase superada; emergencias y desenlace tienen prioridad. Espacio de 0,4–0,8 s entre respuestas.
- **1.1.3.2** Cada línea mantiene subtítulo visible exactamente durante su reproducción. La cola no determina una duración fija arbitraria. Pausar detiene voces, música, colas y subtítulos; reanudar conserva posición; reiniciar limpia eventos y reproduce el inicio nuevamente. Sonido ausente no debe dejar una línea eternamente visible.
- **1.1.3.3** Integrar en `game.gd`, conservando `core/radio_director.gd` como interfaz histórica para pruebas, sin reproducir a la vez los mensajes mudos antiguos. No duplicar el squelch por cada fotograma.

## 1.1.4.0 Banda sonora original adaptativa

- **1.1.4.1** Componer siete cues instrumentales originales: formación, aproximación, combate, bombardeo, regreso, misión cumplida y pérdida. Paleta de cuerdas bajas, maderas, trompa discreta, piano y percusión contenida; sin electrónica arcade, melodía de premio ni voces cantadas sobre la radio.
- **1.1.4.2** Renderizar con instrumentos muestreados locales cuando estén disponibles, registrando banco/licencia. Mantener herramientas de composición fuera del juego. Archivos PCM16 estéreo a 44100 Hz. Bucles de 24–40 s para fases, cierres de 12–16 s. Uniones sin clic y fundidos entre estados de aproximadamente 2 s; no reiniciar pista cada frame.
- **1.1.4.3** Prioridad musical: desenlace > combate real activo > bombardeo > fase de vuelo. Combate no permanece para siempre por un caza alejado o muerto: comprobar distancia/estado de amenaza. No convertir cambio de puesto o cámara en cambio de música.
- **1.1.4.4** Buses separados de diálogo, partitura y efectos. Durante habla bajar música aproximadamente 7–9 dB y efectos 4–6 dB con ataque/recuperación suaves. Conservar el WAV M2 byte por byte; ajustar mezcla temporal no es regenerarlo. Exponer ajuste práctico independiente de música/diálogo, sin ocultar avisos importantes.

## 1.1.5.0 Subtítulos y pruebas

- **1.1.5.1** Subtítulos en `ui/mission_overlay.gd`: personaje e identificación clara, máximo dos líneas, tamaño mínimo 20 px a 1280×720 y panel oscuro; márgenes de 24 px. No encimar ayuda de cámara, mira, radio o información de bombardeo. Escalar con viewport a 1080p. El texto debe coincidir con lo hablado.
- **1.1.5.2** Verificar WAV no silenciosos, formato, picos y duraciones; hashes M2 intactos. Pruebas de eventos sin duplicados, cola, prioridad, pausa/reanudación, reinicio, subtítulos sincronizados y cambio de música. Pruebas de cámara y de audio existentes como regresión. No afirmar escucha humana o aprobación perceptiva a partir de pruebas headless.
- **1.1.5.3** Guardar `ENTREGA_DIALOGOS_MUSICA_CONTEXTUAL.md`, fuentes/licencias, guion, manifiesto y logs. Cerrar únicamente la instancia anterior de este juego antes de promover código/recursos y abrir una única ventana normal en cámara exterior. Identificar límites del TTS y estado real de los efectos/flak de otro encargo; no declarar terminado todo el proyecto.

## Corrección explícita del usuario

Voces en inglés estadounidense, léxico y tratamiento radiofónico de 1945. Subtítulos en español. El catálogo separa spoken_text (en-US) y text (es). Dos voces TTS de catálogo, sin imitar actores ni afirmar que proceden de grabaciones de 1945.
