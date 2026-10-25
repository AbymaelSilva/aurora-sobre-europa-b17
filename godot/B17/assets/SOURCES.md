# Origen de los recursos (assets)

| Archivo | Origen | ID OpenArt | Proceso |
|---|---|---|---|
| terrain/farmland_a.png | OpenArt Wan 2.7 Image pro, generado por Claude 2026-10-24 | KsPeiAZ4Pd29Naldb13D | Copia directa 4096²; enlaza en mosaico (seam_check) |
| terrain/rail_yard.png | OpenArt Wan 2.7 Image pro, generado por Claude 2026-10-24 | a5p85jdlAqRmXX9UcaKl | Copia directa 4096²; no se repite, se usa como calca del objetivo |
| sky/cloud_atlas_realistic_v2.png | OpenArt Nano Banana 2.1, Lote 8 (2026-10-24) | xSTm6sjSshPkw6omuAak / maETMDBdoJ2FI3kmpFe5 | Atlas 4096² (16 celdas 1024²), alfa procesado, mipmaps y filtrado lineal. 78 créditos confirmados |
| sky/cloud_atlas.png | OpenArt Wan 2.7 Image pro, generado por Claude 2026-10-24 | WAo755enGw8YCXEozZyk | Reducido a 2048², alfa por luminancia y color sin premultiplicar (recurso previo / fallback) |

Uso personal. Términos de OpenArt para el plan Starter: pendiente de revisar si alguna vez se distribuye.
| aircraft/decals/*.png (6) | OpenArt GPT Image 2.5 Sunburst, Claude 2026-10-24 | x7PEQr2Ppf9QkcR0nxz4 | Recortadas con `tools_art/cut_sheet.gd` (modo flood: el blanco interior sigue opaco). Estrella USAAF de 1944 (símbolo histórico); "K", el halcón, MISS ADA y el número de serie son originales/ficticios |
| aircraft/damage/damage_01..09.png | OpenArt GPT Image 2.5 Sunburst, Claude 2026-10-24 | n2QhDZ0JgZOEFricWLWY | Recortadas (modo flood) |
| ui/gunsight_ring.png, ui/bombsight_norden.png | OpenArt GPT Image 2.5 Sunburst, Claude 2026-10-24 | ffcrlG9IahAz5S16wXVG | Recortadas (modo ink: alfa = trazo) |
| vfx/flak_01..09.png | OpenArt GPT Image 2.5 Sunburst, Claude 2026-10-24 | fvdguY5hOW7pkvd4zo5S | Recortadas (modo ink: alfa = densidad del humo) |
| aircraft/models/{b17g,bf109g,fw190a,p51d}.glb (+ __albedo.png) | **Construidos por Claude** con `tools_art/loft_aircraft.gd` a partir de vistas ortográficas de OpenArt (GPT Image 2.5 i2i): B-17 AV1-side/top (NzwUqIdcJDejaMO8pquR, UxZSyFxhcbLhd1az1co0); Bf 109 (WDyNTMNqfHRzAXFJ391E, RmwDHO5MVJHvFbiyYSXb); Fw 190 (oWspLfyu2c7IaQHfDwAg, F8JxxqO5LEZyaK9PBqYf); P-51 (GVBFJvuBUWkAXlvAliBw, 63wgFnch6jyElPTFp2Tc) | Silueta → fuselaje por secciones superelípticas, alas y estabilizador por ajuste de bordes y perfil NACA, deriva, góndolas (B-17); textura proyectada desde las propias vistas con un atlas 2048² y color extendido; hélices como nodos `Rotor_*`. Escala real verificada (`tests/test_aircraft_models_claude.gd`). Plan B sin Meshy |
| (candidato, no integrado) art/meshy/candidatos/b17g.glb | Meshy Retexture, Claude-Meshy 2026-10-24, tarea 01a16fdf-54c7-73f3-90a8-5722bd0715dc | — | **Candidato, no integrado; piloto NO aprobado** (alas oscuras). Nuestra geometría y nodos + UV/mapas PBR de Meshy transferidos con `tools_art/apply_meshy_textures.gd`. Ver `planning/orquestacion/ENTREGA_MESHY_TEXTURAS.md` |
| terrain/farmland_t1.png | OpenArt Nano Banana Pro 4K, generado por Claude 2026-10-24 | aHyegxEcNsDxWGjSFyzp | Vista cenital fotorrealista; hecha enlazable en mosaico con `tools_art/make_tileable.py` (franja 8 %, costura 5,0/5,1 = interior). Escala prevista: 1200 m por mosaico |
| audio/sfx/*.wav (47) | Sintetizados por Claude (terminal de audio) con `tools_audio/synth_sfx.py`, 2026-10-24 | — | Solo biblioteca estándar de Python, sin material de terceros. Verificados con check_sfx.py y test_audio_assets.gd |


## Nubes OpenArt v2 — 2026-10-24

`sky/cloud_atlas_realistic_v2.png`: Nano Banana 2.1 en OpenArt, ID `xSTm6sjSshPkw6omuAak`, 4096×4096, 16 variantes. Original y metadatos en `art/openart/clouds_lote8/`; transparencia, descontaminación de bordes y fundidos de celda mediante `res://tools_art/build_cloud_atlas.gd`. Material generado, no fotografía histórica. Cotización 78 créditos; cargo final no comunicado por la respuesta. Se conserva el atlas anterior como fallback.
