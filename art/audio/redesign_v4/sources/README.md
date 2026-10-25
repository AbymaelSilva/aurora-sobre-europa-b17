# Fuentes locales del set contextual v4 — 2026-10-24

Se guardaron preescuchas públicas HQ MP3 y se convirtieron con GStreamer a PCM16,
44100 Hz estéreo. Son originales de trabajo comprimidos; no son los WAV/AIFF/FLAC
maestros anunciados en las páginas. Cada `*.json` registra URL de descarga, hashes del
MP3 y PCM, página individual, licencia y comando exacto de conversión. Los
`*-page.html` son la evidencia local de la licencia que declaraba el autor.

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

Atribución que debe acompañar al juego: audio derivado de la grabación de DC-3 de
**YleArkisto**, Freesound 256049, **CC BY 4.0**. Cambios: selección de fragmentos,
filtrado, mezcla, montaje de bucles, fundidos, ganancia y conversión de formato.
No implica apoyo de YleArkisto al juego. La licencia permite adaptación y distribución
comercial con atribución; conservar autor, enlace y aviso de cambios.
Los demás autores se acreditan aunque sus fuentes sean CC0.

Perspectivas y límites:
- `radial`: DC-3 en rodaje/despegue/alejamiento, grabación Nagra de 1978 desde tierra.
  Aproximación de pistón radial; no grabación de B-17G, cabina ni Bf109/Fw190.
- `tnt`: demolición terrestre con micrófono de videocámara; se excluye el preámbulo
  y se usa el ataque principal desde aproximadamente 2.16 s. No es flak88mm.
- `sheet`: acero golpeado con una herramienta. `metal`: impacto metálico.
  Se amortiguan y montan como fóley; no prueban perforación de aluminio.
- `switch`: pulsación metálica grabada en habitación. Accesibilidad y mecanismos
  aproximados; no documentación de paneles aeronáuticos originales.
- `fire`: fuego de campamento; `wind`: viento real de Atacama, estéreo MS decodificado
  por el autor. Montaje de fuego bajo viento, no incendio aeronáutico medido.
- `alarm`: timbre escolar grabado en sala; se selecciona el primer toque.

Se leyeron también fuentes rechazadas: `prop` (333203) está descrita como
caricaturesca y `blast` (592000) es un petardo de garaje procesado: sus páginas y
metadatos se conservan para auditoría, pero NO se descargaron ni se usan en el banco.
P-40 161119 se rechazó por licencia no comercial. No se usaron efectos procedentes
de películas, juegos, bancos comerciales ni previews de pago.

El servidor de Creative Commons devolvió HTTP403 al intentar guardar sus páginas
con urllib. Las licencias canónicas se consultaron en navegador; la prueba local de
asignación a cada sonido es su página individual guardada, con hash. No se presenta
un archivo local de texto legal inexistente.

`fighter_guns_distant` y `radio_static_loop` son síntesis aperiódica nueva, sin muestras
externas. Los dos squelch mezclan síntesis e interruptor grabado. No contienen voces.
La síntesis no usa el generador antiguo, senos descendentes ni resonadores de chapa.
Ninguna ruta de este proceso accede al audio M2 como fuente.

No se ha realizado escucha humana. Los cortes se eligieron por metadatos y análisis
de envolvente. Confirmar manualmente ausencia de voces/ruidos ajenos residuales,
credibilidad de las aproximaciones y fatiga. No hay aprobación perceptiva implícita.
