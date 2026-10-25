# Procedencia vigente — audio contextual v4 (2026-10-24)

Se sustituyeron **42 WAV** por el set contextual de `tools_audio/build_contextual_set.py`:
38 derivados de grabación, dos híbridos de grabación/síntesis y dos de síntesis nueva.
Los cinco recursos M2 protegidos son idénticos a los hashes iniciales, incluidos los
casquillos. Los cuatro disparos M2 siguen procediendo de ikbenraar, CC0; los casquillos
protegidos conservan su síntesis anterior. No se tocó esa fuente, atribución ni script.

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

Crédito requerido: **YleArkisto — DC-3, Freesound 256049, CC BY 4.0**.
Fragmentos adaptados mediante filtrado, mezcla, bucles, fundidos, ganancia y conversión.
Conservar estos enlaces, atribución y aviso de cambios al distribuir el juego.
Las siete fuentes restantes son CC0 y se acreditan en la tabla.
Se usaron preescuchas HQ MP3, no los masters sin compresión. El DC-3 es una
aproximación de pistón radial; no se presenta como B-17 ni caza histórico grabado.
La demolición TNT es terrestre; chapa de acero, timbre escolar y fuego de campamento
son aproximaciones declaradas. No hay mensajes hablados ni música nueva.

Fuentes originales de trabajo, páginas individuales de licencia y comandos de
conversión: `art/audio/redesign_v4/sources/`. Manifiesto por archivo (autor, URL,
licencia, hashes, cortes, filtros, nivel, duración y limitaciones):
`art/audio/redesign_v4/manifest_full.json`. Informe:
`planning/orquestacion/ENTREGA_AUDIO_CONTEXTUAL_SIN_TOCAR_M2.md`.
A/B sin M2: `art/audio/redesign_v4/review/`. Compatibilidad verificada;
aprobación perceptiva y fatiga pendientes de escucha del usuario.

Regeneración vigente (solo fuentes locales; nunca genera grupo B):

```sh
python3 -I tools_audio/build_contextual_set.py --pilot
python3 -I tools_audio/build_contextual_set.py
python3 -I tools_audio/build_contextual_set.py --promote
python3 -I tools_audio/review_contextual_set.py
```

Los scripts antiguos citados abajo son historia y **no deben ejecutarse sobre el banco
activo**: pueden regenerar archivos protegidos. No se han modificado esos scripts.

---

# Historial v1–v3 conservado (anterior a contextual v4)

El contenido siguiente documenta estados anteriores y sus comandos; sus afirmaciones
sobre el set completo sintético no describen el banco vigente.

# Origen de los recursos de audio

## Estado vigente: disparos M2 grabados

Los cuatro WAV `gun_m2_shot_01/02/03.wav` y `gun_m2_burst.wav` proceden ahora de **ikbenraar**, [Telskuf_IRAQ_Gun.aif](https://freesound.org/people/ikbenraar/sounds/339976/), publicado como **CC0 1.0**. Se descargó la preescucha pública HQ MP3, no el AIFF original. El autor identifica una Browning M2 .50; no documenta una AN/M2 de aviación. Conversión mediante GStreamer a PCM mono 44100 Hz/16 bits, selección de tres ataques, montaje de cola, paso alto, fundidos y ajuste de nivel mediante `tools_audio/build_recorded_m2.py`. Fuente, URL, hash y licencia: `assets/audio/source_m2/source.json`.

Los otros 43 WAV siguen siendo síntesis local. Para regenerar el set vigente usar `python3 -I tools_audio/synth_realista.py`; aplica al final los disparos grabados. Los apartados siguientes conservan el historial y ya no describen la procedencia de los cuatro disparos actuales.

## Historial del set original

Todos los archivos de `assets/audio/sfx/` (47 WAV, PCM de 16 bits a 44 100 Hz) los ha **sintetizado Claude**
(terminal de audio, 2026-10-24) con `tools_audio/synth_sfx.py`, un script que solo usa la biblioteca estándar
de Python 3 (wave, struct, math, random con semilla fija por archivo).

- **Sin material de terceros:** no se ha descargado, grabado ni muestreado ningún sonido, ni se ha usado
  ningún banco de efectos o de instrumentos. Cada muestra sale de osciladores, ruido pseudoaleatorio con
  semilla fija, filtros, envolventes y reverberación programados en ese script.
- **Reproducible:** `python3 -I tools_audio/synth_sfx.py` regenera el set idéntico byte a byte.
  Los sha256 de cada archivo están en `logs/audio/check_sfx.json`.
- **Licencia:** de uso propio del proyecto «Aurora sobre Europa». Como no hay derechos de terceros, se
  puede usar, modificar y distribuir con el juego sin restricciones.

| Archivos | Origen | Proceso |
|---|---|---|
| sfx/*.wav (47) | Síntesis procedural de Claude, `tools_audio/synth_sfx.py` | La técnica de cada archivo está en `planning/orquestacion/ENTREGA_AUDIO_CLAUDE.md` y la verificación en `tools_audio/check_sfx.py` |

## Revisión sonora v2 — Codex, 2026-10-24

Los 47 WAV actuales se regeneran con `python3 -I tools_audio/synth_realista.py`, que reutiliza el sintetizador original de Claude. Todo el material continúa siendo síntesis procedural local, sin muestras de terceros ni servicios de pago. La revisión sustituye ocho señales electrónicas por mecanismos de relé/panel, los dos cierres musicales por ambientes y añade textura irregular, cuerpo o amortiguación según familia. No se presenta como grabación histórica.

El comando original `synth_sfx.py` restaura la versión anterior; para conservar esta revisión utiliza `synth_realista.py`. Copia previa y hashes: `logs/audio/backup-realista-20261024T171430/`. Las técnicas actuales figuran en `logs/audio/synth_manifest.json`; el informe antiguo de Claude describe la versión anterior. La aceptación perceptiva queda pendiente de escucha del usuario.


## Diálogo y partitura posteriores

Se añadieron 28 voces en_US con subtítulos españoles y siete piezas instrumentales originales, en directorios separados de sfx. Su procedencia y licencias están en SOURCES_DIALOGUE_MUSIC.md. Esto sustituye cualquier nota anterior de «no hay voces» como descripción del estado vigente del juego. Los cinco WAV M2 permanecen protegidos.
