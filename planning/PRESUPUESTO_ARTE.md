# Presupuesto de arte — B-17

Decisión del usuario (2026-10-24, comunicada a Claude): **uso personal, calidad profesional, presupuesto = todo el saldo disponible, para todos los agentes.** Comprar créditos sigue requiriendo autorización expresa.

Reglas:
- Antes de cada lote se genera una pieza piloto; el lote solo sigue si la pieza piloto se puede usar.
- No se repiten variantes.
- Cada cargo real se apunta en el registro de abajo.
- El arte generado es concepto o textura de partida: se revisa siempre antes de entrar en el juego.

## OpenArt (Claude) — saldo verificado 1333 créditos (2026-10-24, plan Starter)

Ya gastado antes del reparto: 45 créditos (imagen `xwXsWLaDW2Qmk1awEoqA`). Está completada y descargada en `art/openart/concept-01-key-art.png`. Revisión: sirve como **arte de menú o título**. No sirve como referencia para modelar: el estabilizador horizontal está sobredimensionado y descolocado.

**Enfoque del usuario (2026-10-24): aviones y escenario. El menú, la tripulación, la interfaz y las cinemáticas quedan fuera del presupuesto.**

| Lote | Contenido | Modelo (coste unitario cotizado) | Previsto |
|---|---|---|---|
| AV1. Referencias para Meshy (B-17) | Vista 3/4 aislada con fondo gris; si la geometría es correcta: lateral, frontal y superior con image2image para que sean coherentes | GPT Image 2.5 Sunburst medium (40) / image2image (42) | ~170 |
| AV2. Cazas enemigos | Referencia aislada de un caza monomotor alemán tipo Bf 109 / Fw 190, sin esvástica | GPT Image 2.5 Sunburst medium (40) | ~120 |
| AV3. Acabado del avión | Máscaras de suciedad, manchas de escape y desgaste **sin repetición**, en escala de grises, más arte de nariz y marcas originales del escuadrón ficticio como calcas | Wan 2.7 pro (15), Nano Banana 2.1 (30) | ~120 |
| ES1. Terreno | Campos (A1 sirve), bosques y aldeas (A2), río, pueblo, variantes de estación del año | Wan 2.7 pro (15) | ~120 |
| ES2. Objetivo | Complejo ferroviario visto desde arriba (A3) y concepto en perspectiva para modelarlo | Wan 2.7 pro (15), GPT 2.5 (40) | ~80 |
| ES3. Cielo y nubes | Atlas de nubes, panorama de cielo equirectangular, capas de nubes vistas desde arriba | Wan 2.7 pro (15) | ~100 |
| ES4. Efectos | Secuencias de fotogramas (flipbooks) de ráfaga de flak, humo, fuego, explosión en tierra y trazadoras | Wan 2.7 pro (15) | ~120 |
| R. Reserva para corregir y segunda ola | Tras integrar en Godot | — | resto (~430) |

Lecciones aprendidas:
- Wan 2.7 tiende a generar **repeticiones internas**. A1 salió como cuadrícula 2×2 y A5 (olive drab) como una rejilla artificial con el mismo desconchón en cada panel: **rechazada**.
- La pintura y la chapa del avión van como shader procedural en Godot (paneles, remaches y ruido). De la IA solo se usan máscaras que no se repitan.

**Audio:** OpenArt **no tiene ningún modelo que genere solo audio** (comprobado en `openart_model_list` el 2026-10-24). Los modelos de vídeo traen el audio pegado a la imagen, y eso no sirve como efectos de sonido sueltos. El audio necesita otra herramienta o bibliotecas con licencia CC0. Sigue pendiente.

## Meshy (Codex) — saldo 1200 según el usuario; no lo he podido verificar desde Claude

Ya gastado: 5 créditos (preview `01a16d47…`; 1 malla, 0 materiales). Codex hace su propio reparto aquí, con la misma regla de pieza piloto. Propuesta de Claude:
- Refinar con textura el modelo que pase la revisión de proporciones.
- Recursos secundarios: vagones, locomotora, edificios de la estación, camiones, emplazamiento antiaéreo, caza enemigo genérico sin insignias reales.
- El B-17 principal solo se cambia si supera al procedural (hélices separadas, pivotes, escala).

## Registro de cargos

| Fecha | Agente | Herramienta | ID | Pieza | Créditos | Resultado |
|---|---|---|---|---|---|---|
| 2026-10-24 | Codex | OpenArt GPT Image 2.5 | xwXsWLaDW2Qmk1awEoqA | Arte de menú | 45 | Utilizable para el menú |
| 2026-10-24 | Codex | Meshy T2.5 preview | 01a16d47-2d05-705d-9946-e557b8071420 | B-17 preview | 5 | Pendiente de revisión |
| 2026-10-24 | Claude | OpenArt Wan 2.7 Image pro 4K | KsPeiAZ4Pd29Naldb13D | A1 piloto: terreno de campos | 15 (cotizado) | **Utilizable.** `art/openart/textures/A1-farmland-4k.png`. Enlaza en mosaico (costura 16/10 frente a 8,6/4,9 interior, medido con `seam_check.gd`). Defecto: la imagen es una cuadrícula 2×2 interna (~2K únicos); conviene un shader que rote o mezcle |
| 2026-10-24 | Claude | OpenArt Wan 2.7 Image pro 4K | vWUpOBpnmiUQKt6VUq9c | A2 terreno con bosques y aldeas | 15 (cotizado) | Limitada: repetición 2×2 y la costura se nota un poco (11,8/13 frente a 4,4/8,9) |
| 2026-10-24 | Claude | OpenArt Wan 2.7 Image pro 4K | a5p85jdlAqRmXX9UcaKl | A3 complejo ferroviario visto desde arriba (objetivo) | 15 (cotizado) | **Muy buena**, importada como `godot/B17/assets/terrain/rail_yard.png` |
| 2026-10-24 | Claude | OpenArt Wan 2.7 Image pro 4K | K6PAj1ik7g51hilghuhg | A4 aluminio con remaches | 15 (cotizado) | Rechazada como textura principal: rejilla repetida |
| 2026-10-24 | Claude | OpenArt Wan 2.7 Image pro 4K | vR2kjgcBYSYAPW4xdtnd | A5 olive drab desgastado | 15 (cotizado) | **Rechazada:** rejilla artificial con el mismo desconchón en cada panel (`art/openart/textures/A5-olive-drab-4k.png`, se conserva como prueba) |
| 2026-10-24 | Claude | OpenArt GPT Image 2.5 Sunburst medium 2K | 8OnyeQVFrNIWvFuH0LI4 | AV1 piloto: B-17G 3/4 aislado para Meshy | 40 (cotizado) | **Muy buena**, `art/openart/refs/AV1-b17g-34-ref.png`; se entrega a Codex para Meshy |
| 2026-10-24 | Claude | OpenArt Wan 2.7 Image pro 4K | WAo755enGw8YCXEozZyk | ES3 piloto: atlas de 16 nubes | 15 (cotizado) | **Muy buena**, con canal alfa → `godot/B17/assets/sky/cloud_atlas.png` |
| 2026-10-24 | Claude | OpenArt GPT Image 2.5 Sunburst medium 2K | jRXRL8nuyR5TIjWygnzQ | AV2 Bf 109G 3/4 aislado para Meshy | 40 (cotizado) | **Muy buena**, `art/openart/refs/AV2-bf109g-34-ref.png`, sin insignias; entregada a Codex (PARA_CODEX_MESHY.md) |
| 2026-10-24 | Claude | OpenArt Wan 2.7 Image pro 4K | 0nf0VCZbjROoDleamtXY | ES4 piloto: flipbook de flak | 15 (cotizado) | **Rechazada**: estilo de dibujos animados, líneas de cuadrícula y fotogramas casi idénticos. Lección: Wan no sirve para efectos; probar con GPT 2.5 sobre fondo blanco |
| 2026-10-24 | Claude | GPT Image 2.5 medium | fvdguY5hOW7pkvd4zo5S | ES4b 9 puffs de flak realistas sobre blanco | 40 | **Se usa** → `assets/vfx/flak_01..09.png` |
| 2026-10-24 | Claude | GPT Image 2.5 i2i medium | NzwUqIdcJDejaMO8pquR | AV1-side vista lateral del B-17 | 42 | **Se usa**: coherente con AV1; entrada de Meshy multi-imagen |
| 2026-10-24 | Claude | GPT Image 2.5 i2i medium | UxZSyFxhcbLhd1az1co0 | AV1-top planta del B-17 | 42 | **Se usa**: entrada de Meshy multi-imagen |
| 2026-10-24 | Claude | GPT Image 2.5 medium | opqMJzT6vNHfvJz42gOR | AV3 Fw 190A 3/4 | 40 | **Se usa**: entrada de Meshy |
| 2026-10-24 | Claude | GPT Image 2.5 medium | ArSQsVfvfq9S11wS5fNV | AV4 P-51D 3/4 (escolta) | 40 | Aceptable (rarezas menores en el ala): entrada de Meshy |
| 2026-10-24 | Claude | GPT Image 2.5 medium | x7PEQr2Ppf9QkcR0nxz4 | AV5 calcas: estrella, K, halcón, MISS ADA, registro de misiones, serie | 40 | **Se usa** → `assets/aircraft/decals/` |
| 2026-10-24 | Claude | GPT Image 2.5 medium | n2QhDZ0JgZOEFricWLWY | AV6 9 calcas de daño | 40 | **Se usa** → `assets/aircraft/damage/` |
| 2026-10-24 | Claude | GPT Image 2.5 medium | ffcrlG9IahAz5S16wXVG | AV7 mira de artillero y mira Norden | 40 | **Se usa** → `assets/ui/` |
| — | — | — | — | **Saldo OpenArt verificado 2026-10-24: 815 créditos** (gastados 518 de 1333) | | |
| 2026-10-24 | Claude | GPT Image 2.5 i2i medium ×6 | WDyNTMNqfHRzAXFJ391E, RmwDHO5MVJHvFbiyYSXb, oWspLfyu2c7IaQHfDwAg, F8JxxqO5LEZyaK9PBqYf, GVBFJvuBUWkAXlvAliBw, 63wgFnch6jyElPTFp2Tc | Vistas lateral y planta de Bf 109, Fw 190 y P-51 (plan B sin Meshy) | 6×42 = 252 | **Se usan**: fuente de geometría y textura de los modelos 3D. Saldo verificado después: **521** |
| 2026-10-24 | Claude | OpenArt Nano Banana Pro 4K (text2image) | aHyegxEcNsDxWGjSFyzp | T1 terreno superior (petición del usuario: «mayor capacidad»), vista cenital fotorrealista de campos de 1944 | 80 | **ACEPTADA como candidata (GPU, 1200 m/mosaico; versión enlazable *-tile.png).** Muy buena calidad, sin repetición interna (cuadrantes distintos, Δ≈40). NO enlaza en mosaico (costura 13/17 frente a 6/5 interior): requiere procesado para hacerla enlazable. Escala: cubre ≈1,2 km, no 2,8. `art/openart/textures/T1-nanobanana/T1-farmland-nbpro-4k.png`. Pendiente de integrar |
| — | — | — | — | **Saldo OpenArt verificado 2026-10-24 14:40: 441 créditos** | | |
| 2026-10-24 | Claude-Meshy | Meshy Retexture (latest=meshy-7, PBR, 4k, UV nuevas; imagen AV1 + texto → la API usa solo la imagen) | 01a16fdf-54c7-73f3-90a8-5722bd0715dc | Piloto B-17G, intento 1 | 10 | **Falla parcial**: fuselaje y góndolas muy buenos (paneles, remaches, metal); alas, estabilizadores y deriva oscuros y lisos; disco tipo emblema en el lomo. `art/meshy/textures/b17g/intento1/` |
| 2026-10-24 | Claude-Meshy | Meshy Retexture (igual, solo texto corregido) | 01a16fe3-7311-7144-bfdd-becd4b3efd4d | Piloto B-17G, reintento | 10 | **Falla**: alas oscuras otra vez, tono azulado y marcas inventadas en el morro y el fuselaje. Causa hallada: winding invertido en alas, estabilizadores y deriva de nuestros GLB (Meshy no pinta las caras traseras). Lote NO lanzado |
| — | — | — | — | **Saldo Meshy verificado 2026-10-24 14:55: 1175 créditos** (1195 antes del piloto) | | |
| 2026-10-24 | Claude-Meshy | Meshy Retexture (meshy-7, PBR, 4k, UV nuevas; entrada `b17g_winding_fix.glb`, imagen AV1 + texto reforzado, que la API ignora) | 01a16fef-168e-7698-8dac-89e49116d927 | Piloto B-17G, ronda 2 (3.er envío, autorizado por el supervisor) | 10 | **No pasa, pero es el mejor de los tres**: alas con paneles y remaches; deriva todavía oscura y lisa, extradós gris azulado y sin brillo, y un glifo inventado en el panel antirreflejo. Lote NO lanzado. `art/meshy/textures/b17g/intento3/` |
| — | — | — | — | **Saldo Meshy verificado 2026-10-24 15:05: 1165 créditos** | | |


## Lote 8 — Nubes realistas (Codex)

Solicitud piloto Nano Banana 2.1 text2image, 1 imagen, 4K, 1:1.
- History ID: `xSTm6sjSshPkw6omuAak`
- Resource ID: `maETMDBdoJ2FI3kmpFe5`
- Project ID: `OgiFUoWFMu1oOrtlChxF`
- Estado: **COMPLETADA**
- Coste confirmado: **78 créditos** (saldo restante: 363 créditos)
- Atlas generado: 4096×4096 px en cuadrícula 4×4 (16 celdas de 1024×1024 px)
- Conversión: `assets/sky/cloud_atlas_realistic_v2.png` (RGBA8 con mipmaps y filtrado lineal, comprobado contra fondo celeste y gris oscuro en `art/openart/clouds_lote8/preview_*.png`)
