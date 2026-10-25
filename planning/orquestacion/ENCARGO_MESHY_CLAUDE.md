# Encargo para Claude (terminal Meshy): set de texturas PBR para los aviones

## Meta (condición de terminado)
Obtener un **SET DE TEXTURAS PBR** (color base, normal, rugosidad y metal; AO si Meshy la da) para los 4 aviones del juego: B-17G, Bf 109G, Fw 190A y P-51D. Generado con Meshy sobre NUESTROS modelos y aplicado a copias de esos modelos que **conserven la geometría, la escala y los nodos `Rotor_*`**, y verificado en Godot.
Entregables:
- `art/meshy/textures/<avion>/` con los mapas PNG y el GLB de Meshy original;
- `art/meshy/candidatos/<avion>.glb`: nuestra geometría con los materiales nuevos;
- `planning/orquestacion/ENTREGA_MESHY_TEXTURAS.md`.
No termines con un plan: termina con los mapas descargados y verificados, o con un bloqueo concreto documentado (por ejemplo, saldo insuficiente).

## Lee primero
`planning/orquestacion/ANALISIS_MESHY_AVIONES.md` (análisis del supervisor), `planning/PRESUPUESTO_ARTE.md` (reglas y registro de gastos) y `godot/B17/assets/SOURCES.md`.

## Clave y presupuesto
- La clave está SOLO en la variable de entorno `MESHY_API_KEY` de esta sesión. **Nunca la imprimas, la escribas en archivos ni la pongas en los registros.** Úsala como `-H "Authorization: Bearer $MESHY_API_KEY"`.
- El usuario autorizó usar todo el saldo de Meshy para arte, con estas reglas:
  - PRIMERO consulta el saldo (`GET https://api.meshy.ai/openapi/v1/balance`, gratis);
  - cotiza o confirma el coste de cada tarea en la documentación antes de enviarla;
  - **pieza piloto (B-17) antes del lote**;
  - sin variantes repetidas;
  - apunta cada cargo real en la tabla «Registro de cargos» de `planning/PRESUPUESTO_ARTE.md` (fecha, agente «Claude-Meshy», herramienta, ID de tarea, pieza, créditos, resultado).
- Comprar créditos NO está autorizado. Si no hay saldo, para y documenta el bloqueo.

## Método
1. **Documentación**: lee la documentación vigente de la API (https://docs.meshy.ai) para Retexture / Text-to-Texture: endpoint, cómo subir un modelo (URL o data URI), campos `text_style_prompt` / `image_style_url`, `enable_pbr`, `enable_original_uv` si existe, resolución de textura, estados, descargas y coste en créditos. Anota en la entrega lo que confirmaste.
2. **Piloto B-17G**:
   - Modelo: `godot/B17/assets/aircraft/models/b17g.glb`.
   - Imagen de estilo: `art/openart/refs/AV1-b17g-34-ref.png` (súbela como data URI si la API lo permite).
   - Usa **las UV originales** si la API tiene esa opción, para no romper la proyección de calcas.
   - Prompt de estilo, en inglés: «Boeing B-17G Flying Fortress, 1944 USAAF, unpainted natural aluminium skin with subtly varying panel tones, crisp recessed panel lines and flush rivets, olive drab anti-glare panel in front of the cockpit, clear plexiglass nose and turrets, black de-icer boots on wing and tail leading edges, light weathering: exhaust soot streaks over the wings behind each engine nacelle, oil stains on nacelles, scuffed walkway areas, no insignia, no text, no numbers, no nose art, physically based materials, metallic aluminium with low roughness, realistic WWII bomber».
   - Descarga TODOS los mapas y el GLB resultante a `art/meshy/textures/b17g/`.
3. **Integración en una copia** (nunca en `godot/B17/assets/...` de producción). Escribe `tools_art/apply_meshy_textures.gd` (SceneTree) que:
   - cargue NUESTRO `b17g.glb`;
   - si las UV se conservan: sustituya el material por un `StandardMaterial3D` con albedo, normal, rugosidad, metal y AO de Meshy;
   - si Meshy cambió las UV: tome la malla de Meshy solo como fuente de UV o textura y transfiera el color por proyección o búsqueda del punto más cercano a nuestras UV; documenta el método;
   - conserve los nodos `Rotor_*`, transforms, escala y nombres;
   - guarde `art/meshy/candidatos/b17g.glb` (con `GLTFDocument`).
4. **Verificación del piloto** (obligatoria antes del lote):
   - Comparar nuestro GLB con el candidato: AABB (diferencia < 1 %), el mismo número de nodos `Rotor_*` y los mismos nombres.
   - Copiar el candidato a un proyecto temporal de prueba (`/tmp`, nunca `godot/B17`) o cargarlo desde un script de revisión, y hacer capturas con GPU a 1280×720 del candidato y del actual, misma cámara: vista 3/4 cercana, lateral y planta. Orden: `tools/godot --path <proyecto> --resolution 1280x720 --script <tu_script> -- <dir>`, sin headless. Guárdalas en `logs/meshy/<fecha>-piloto/`.
   - Criterios PASS:
     - superficie sin estiramientos en la panza ni en los laterales;
     - paneles y remaches visibles con el mapa normal;
     - reflejo metálico creíble;
     - sin texto ni insignias inventadas;
     - sin costuras evidentes.

   Si falla, como mucho UN reintento con el prompt corregido. Después, documenta y para.
5. **Lote** (solo si el piloto pasa), con el mismo método:
   - **Bf 109G** (`bf109g.glb`, estilo `AV2-bf109g-34-ref.png`): «Messerschmitt Bf 109G-6, 1944 Luftwaffe day fighter, RLM 74/75 grey camouflage upper surfaces with soft mottling on fuselage sides, RLM 76 light blue undersides, yellow engine cowling underside and rudder band, exhaust soot behind the engine stacks, light paint chipping, NO swastika, NO national insignia, NO text or numbers, physically based materials».
   - **Fw 190A** (`fw190a.glb`, `AV3-fw190a-34-ref.png`): «Focke-Wulf Fw 190A-8, 1944, RLM 74/75/76 grey camouflage with mottled fuselage sides, BMW 801 radial cowling, exhaust staining along the fuselage sides, light wear, NO swastika, NO national insignia, NO text or numbers, physically based materials».
   - **P-51D** (`p51d.glb`, `AV4-p51d-34-ref.png`): «North American P-51D Mustang, 1944 USAAF escort fighter, polished natural aluminium, olive drab anti-glare panel on the nose top, light exhaust staining, no insignia, no text, no numbers, physically based materials, low roughness metal».

   Cada uno: candidato en `art/meshy/candidatos/`, misma verificación y capturas.
6. **Entrega** en `planning/orquestacion/ENTREGA_MESHY_TEXTURAS.md`, con:
   - qué API y opciones usaste;
   - ID de cada tarea y créditos;
   - qué mapas obtuviste y su resolución;
   - método de integración;
   - tabla AABB/Rotor;
   - rutas de las capturas antes/después;
   - valoración honesta por avión;
   - lo que NO salió bien.

   Añade el origen a `godot/B17/assets/SOURCES.md` SOLO como «candidato, no integrado». La integración en producción y el reemplazo de los GLB del juego los decide y hace el supervisor tras revisar.

## Reglas
- No modifiques producción: ni `godot/B17/**/*.gd` ni `godot/B17/assets/**`, salvo la nota de SOURCES.md. Tampoco `release/`.
- Registro de avance en `logs/orquestacion/claude_meshy.log`: una línea con fecha por cada hito (saldo, piloto enviado, piloto descargado, piloto verificado, cada avión del lote, entrega).
- El disco está al 93 %: no guardes descargas duplicadas; el set debería ocupar menos de 400 MB.
- Ante cualquier error de la API, lee el mensaje, corrige los parámetros y como mucho reintenta una vez. No gastes créditos a ciegas.
