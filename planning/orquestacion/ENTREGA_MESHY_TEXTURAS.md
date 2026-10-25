# Entrega: texturas PBR de Meshy para los aviones (Claude-Meshy, 2026-10-24)

## Resultado: BLOQUEADO tras el piloto (no se lanzó el lote)
- El piloto del B-17G **no pasa** en ninguno de sus dos intentos (el máximo permitido).
- Se encontró la **causa**, que es nuestra y no de Meshy: las alas, los estabilizadores y parte de la deriva de nuestros GLB tienen el **winding invertido**. En glTF esas caras miran hacia dentro, Meshy las trata como caras traseras y las deja oscuras y sin detalle.
- Los **tres cazas tienen el mismo defecto**, así que lanzar el lote habría gastado 30 créditos en el mismo fallo.
- **Queda preparada sin coste** la corrección: `tools_art/fix_winding_for_meshy.gd` y la entrada ya corregida `art/meshy/input/b17g_winding_fix.glb` (AABB idéntico y 4/4 `Rotor_*`).
- **Decisión pendiente del supervisor o del usuario:** autorizar un tercer envío del B-17 con esa entrada (10 créditos). Si pasa, el lote completo cuesta 30 créditos más.

Gasto: **20 créditos**. Saldo verificado: 1195 → **1175**.

## API y opciones (confirmado en docs.meshy.ai el 2026-10-24)
- `POST https://api.meshy.ai/openapi/v1/retexture` devuelve `{"result": id}`. Estado: `GET /openapi/v1/retexture/:id`, con `PENDING`, `IN_PROGRESS`, `SUCCEEDED`, `FAILED` o `CANCELED`.
- Modelo con `model_url` como data URI (`data:application/octet-stream;base64,…`, ≤ 100 MB), en GLB, glTF, OBJ, FBX o STL.
- Estilo: `text_style_prompt` (≤ 800 caracteres) **o** `image_style_url` (data URI, ≤ 20 MB). **Si se envían los dos, la API usa solo la imagen**: comprobado, porque la tarea 1 devolvió `text_style_prompt: ""`. También existe `multiview_image_urls` (1–4 vistas, solo meshy-7, no combinable con las otras dos entradas).
- `enable_original_uv` (por defecto false), `enable_pbr` (metal, rugosidad y normal; emisión solo con meshy-6), `texture_resolution` (`2k`, `4k` u `8k`), `ai_model` (`latest` = meshy-7) y `target_formats`. `remove_lighting` no tiene efecto con meshy-7.
- **Coste** (página de precios): Retexture cuesta 10 créditos a 2K/4K y 15 a 8K. Confirmado con `consumed_credits: 10` en las dos tareas. Las tareas fallidas se reembolsan.
- Opciones usadas: `ai_model: latest`, `enable_pbr: true`, `texture_resolution: 4k`, `enable_original_uv: false`, `target_formats: ["glb"]`.

### Por qué no se usaron las UV originales
Nuestras UV son una **proyección solapada**: los dos costados comparten texels, y el extradós y el intradós también. Con `enable_original_uv`, Meshy no podría pintar distinto cada cara y el estiramiento oblicuo seguiría. Además, ningún script del juego usa hoy las calcas por UV (`grep` de decal/decals en `godot/B17` sin resultados). Las calcas futuras deberían ir con nodos `Decal`, que no dependen de las UV.

## Tareas
| # | ID | Estilo | Créditos | Resultado |
|---|---|---|---|---|
| 1 | 01a16fdf-54c7-73f3-90a8-5722bd0715dc | Imagen `AV1-b17g-34-ref.png` (el texto se ignoró) | 10 | Falla parcial |
| 2 | 01a16fe3-7311-7144-bfdd-becd4b3efd4d | Solo texto corregido (`intento2/prompt.txt`) | 10 | Falla |

## Mapas obtenidos (por intento, en `art/meshy/textures/b17g/intento{1,2}/`)
- `base_color.png` 4096², `normal.png` 4096² (RGB, OpenGL), `metallic.png` 2048² y `roughness.png` 2048² (escala de grises).
- Sin AO (Meshy no la genera) y sin emisión (meshy-7).
- `meshy_model.glb` (original de Meshy, 17–20 MB), `thumbnail.png`, `task.json` (sin URLs firmadas) y `prompt.txt`.
- Total: 102 MB.

## Método de integración (`tools_art/apply_meshy_textures.gd`)
- **Datos de partida:** Meshy devuelve **una sola malla** de 26 842 triángulos, normalizada a 2 unidades (escala 15,81) y con UV nuevas. Los vértices se conservan.
- **Alineación:** el script alinea la malla de Meshy con la nuestra por la caja (escala uniforme y traslación).
- **Transferencia de UV:** para cada triángulo nuestro, en mundo, busca el triángulo de Meshy más cercano con normal compatible. Con una rejilla espacial, si |cos| > 0,5, para no mezclar el extradós con el intradós. Asigna nuestras UV con las baricéntricas respecto a ese triángulo: así ningún triángulo cruza una costura de UV.
  - Resultado: **98,0 % de triángulos con coincidencia exacta** (< 1 mm) y distancia máxima de 8,6 cm.
- **Geometría y nodos:** se conservan nuestras posiciones, normales, nombres y transforms, y los nodos `Rotor_*`. Se regeneran las tangentes para el mapa normal.
- **Material:** un `StandardMaterial3D` con albedo, normal, rugosidad y metal (`cull_disabled`, como el original). La AO se aplicaría si existiera `ao.png`.
- **Exportación:** con `GLTFDocument`, y se comprueba releyendo el archivo escrito.
- Herramientas auxiliares:
  - `tools_art/review_meshy_candidate.gd`: compara AABB y `Rotor_*` y hace capturas con GPU con la misma cámara;
  - `tools_art/fix_winding_for_meshy.gd`: corrección del winding para el próximo envío.

## Tabla AABB / Rotor (releyendo los GLB del disco)
| Avión | AABB actual (m) | AABB candidato | Dif. rel. | Rotor_* | Mismos nombres y posiciones |
|---|---|---|---|---|---|
| B-17G intento 1 (`art/meshy/candidatos/b17g.glb`) | 31,62 × 6,556 × 22,66 | 31,62 × 6,556 × 22,66 | 0,0000 % | 4 / 4 | Sí |
| B-17G intento 2 (regenerable con el script; no se guarda) | ídem | ídem | 0,0000 % | 4 / 4 | Sí |
| B-17G entrada corregida (`art/meshy/input/b17g_winding_fix.glb`) | ídem | ídem | 0,0000 % | 4 / 4 | Sí |
| Bf 109G, Fw 190A, P-51D | — | no generado | — | — | — |

## Capturas (GPU RTX 2060 SUPER, Vulkan Forward+, 1280×720, misma cámara)
Carpeta: `logs/meshy/2026-10-24-piloto/`.
- **Actual:** `b17g_actual_{tres_cuartos,lateral,planta,panza,detalle}.png`.
- **Intento 1:** `b17g_i1_candidato_*.png`.
- **Intento 2:** `b17g_r2_candidato_*.png`.
- **GLB de Meshy sin tocar:** `meshy_raw/*.png`. Confirma que las alas oscuras ya vienen de Meshy, no de la transferencia.
- **Mapas:** `b17g_base_color_1k.png` (atlas reducido) y `b17g_normal_crop.png`.

## Valoración honesta
**B-17G, intento 1 (imagen de estilo).**
- *Fuselaje y góndolas:* claramente mejores que el actual. Paneles y remaches visibles con el mapa normal, ventanillas y morro acristalado pintados, reflejo de aluminio creíble, sin estiramientos en la panza ni en los costados y sin costuras evidentes.
- *Superficies sustentadoras:* alas, estabilizadores y deriva salen gris azulado oscuro, lisos y sin paneles.
- *Marcas:* un disco tipo emblema en el lomo (la torreta dorsal mal interpretada) y unos galones en la panza.
- **No pasa.** Es el candidato guardado, como referencia y no para producción.

**B-17G, intento 2 (solo texto).**
- Peor: las alas siguen oscuras, el aluminio toma un tono azulado y aparecen **marcas inventadas** (mancha naranja y una «G» en el morro, parches tipo insignia en el fuselaje trasero).
- **No pasa.**

**Bf 109G, Fw 190A, P-51D.** No se generaron, porque el piloto no pasó y tienen el mismo defecto de winding.

## Lo que NO salió bien
1. **Winding invertido** de nuestros modelos. Afecta a las alas, los estabilizadores y 2 de cada 3 triángulos de la deriva, en los 4 aviones. Se debió medir antes de enviar.
   - En Godot no se ve porque el material usa `CULL_DISABLED`, pero cualquier herramienta externa lo nota.
   - Conviene corregirlo también en el origen (`tools_art/loft_aircraft.gd`, funciones `_wing` y `_fin`), cosa que decide el supervisor.
2. Con imagen y texto juntos, el texto no se usa. El encargo pedía ambos y solo se pudo usar uno por tarea.
3. El texto solo, sin imagen, dio un acabado menos fiel y con marcas inventadas pese a los «no insignia / no text» explícitos.
4. **Tamaño:** el candidato con 4K incrustado pesa 39 MB, frente a los 4,3 MB del actual. Para producción convendría bajar los mapas de metal y rugosidad a un ORM y comprimir con VRAM al importar.

## Siguiente paso recomendado (requiere autorización: 10 créditos más)
1. Reenviar el B-17 con `art/meshy/input/b17g_winding_fix.glb` como modelo y `image_style_url = AV1-b17g-34-ref.png`, con las mismas opciones. La imagen dio el mejor acabado.
2. Pasarle `apply_meshy_textures.gd` sobre la entrada corregida y repetir `review_meshy_candidate.gd`.
3. Si pasa: generar las entradas corregidas de los cazas con `fix_winding_for_meshy.gd` y lanzar el lote a 2K (3 × 10 créditos), con las referencias AV2, AV3 y AV4.

---

# Ronda 2 (autorizada por el supervisor, 2026-10-24): tercer piloto del B-17G

## Resultado: el piloto NO PASA y me paro (el lote no se lanzó)
- Es **el mejor de los tres envíos**. La corrección del winding funcionó: las alas y los estabilizadores ya tienen paneles, remaches, alerones y flaps.
- Aun así, no cumple dos criterios del encargo:
  - **Marca inventada:** un glifo con aro (parecido a una «e» atravesada) en el panel antirreflejo, delante de la cabina.
  - **Deriva oscura y lisa**, sin paneles, como en la ronda 1.
- Además, el extradós de las alas sale **gris azulado mate**, sin brillo metálico y claramente distinto del fuselaje.
- Como la autorización no permite más reintentos, **no se generaron las entradas de los cazas ni se lanzó el lote**.

Gasto de la ronda: **10 créditos**. Saldo verificado: 1175 → **1165**. Total del encargo: 30 créditos.

## Comprobación de la entrada antes del envío
Herramienta: `/tmp/meshy_tools/precheck.gd`, auxiliar y fuera del repositorio.

| GLB | AABB (m) | Rotor_* | Triángulos con el winding invertido |
|---|---|---|---|
| `godot/B17/assets/aircraft/models/b17g.glb` (producción) | 31,62 × 6,556 × 22,66 | 4 | 4622 / 27 354 |
| `art/meshy/input/b17g_winding_fix.glb` (enviado) | idéntico (dif. 0,0000 %) | 4, mismos nombres y posiciones | **0** / 27 354 |

## Tarea
| ID | Entrada | Estilo | Opciones | Créditos |
|---|---|---|---|---|
| 01a16fef-168e-7698-8dac-89e49116d927 | `b17g_winding_fix.glb` | Imagen `AV1-b17g-34-ref.png` y el texto reforzado de `intento3/prompt.txt` | `ai_model` latest (meshy-7), `enable_pbr`, `texture_resolution` 4k, `enable_original_uv` false, glb | 10 (`consumed_credits`; la página de precios confirma 10 a 2K/4K) |

**El texto reforzado contra marcas no tuvo efecto.** Con una imagen de estilo, la API descarta el texto: la tarea devolvió otra vez `text_style_prompt: ""`, como en la ronda 1. Esto ya estaba documentado arriba. Se envió igualmente, como pedía la autorización, pero no puede influir mientras haya imagen.

## Mapas (`art/meshy/textures/b17g/intento3/`)
- `base_color.png` y `normal.png` a 4096²; `metallic.png` y `roughness.png` a 2048². Sin AO.
- También: `meshy_model.glb` (23,6 MB), `thumbnail.png`, `task.json` (sin URLs firmadas), `prompt.txt` y `apply.log`.
- `art/meshy/textures` ocupa ahora 166 MB en total.

## Integración y verificación
- Mismo método que en la ronda 1 (`tools_art/apply_meshy_textures.gd`), aplicado sobre **nuestro `b17g.glb` de producción**. Así el candidato tiene exactamente la geometría del juego y el winding sigue como está: su corrección la decide el supervisor.
- Transferencia: 27 354 triángulos, **98,1 % exactos**, 512 a más de 5 cm y distancia máxima de 8,6 cm.
- `review_meshy_candidate.gd` (GPU RTX 2060 SUPER, Vulkan Forward+, 1280×720): AABB **0,0000 %**, Rotor_* **4/4, mismos nombres y posiciones → PASS** en la parte geométrica.
- **Candidato:** `art/meshy/candidatos/b17g.glb` (48 MB).
  - **Sustituye** al del intento 1, que era peor. Se puede regenerar con el script y `intento1/` si hiciera falta.
- **Capturas:** `logs/meshy/2026-10-24-ronda2/`.
  - Del actual: `b17g_i3_actual_{tres_cuartos,lateral,planta,panza,detalle}.png`.
  - Del candidato: `b17g_i3_candidato_*.png`.
  - Ampliación de las marcas dudosas: `b17g_i3_zoom_marcas.png`.

## Criterios PASS
| Criterio | Resultado |
|---|---|
| Sin estiramientos en la panza ni en los laterales | **Sí** |
| Paneles y remaches visibles con el mapa normal | **Sí** en el fuselaje, las góndolas, las alas y los estabilizadores (nuevo respecto a la ronda 1). **No** en la deriva, que sale oscura y lisa |
| Reflejo metálico creíble | **Sí** en el fuselaje y las góndolas. **No** en el extradós de las alas ni en los estabilizadores (gris azulado mate). El intradós sí está bien |
| Sin texto ni insignias inventadas | **No.** Hay un glifo con aro en el panel antirreflejo |
| Sin costuras evidentes | **Sí** dentro de cada pieza. Se nota el salto de tono entre las alas y el fuselaje |

### Elementos dudosos que NO cuento como fallo
- Un círculo en el extradós, junto a la góndola exterior: parece una tapa de depósito, no una escarapela.
- Parches grises y un rectángulo oscuro en el fuselaje trasero: parecen la ventana del artillero lateral y parches de reparación.
- Un óvalo rojo en una pala de la hélice: parece la calca del fabricante.
- Una «V» clara en la torreta superior: puede ser el marco del acristalamiento.

## Valoración honesta
- Frente al modelo actual, el candidato de la ronda 2 es **muy superior** en el fuselaje, las góndolas y ahora también en las alas.
- Los defectos que quedan son **localizados**:
  - un glifo en el panel antirreflejo;
  - la deriva lisa;
  - el tono del extradós.
- El glifo y el tono se podrían arreglar **sin créditos**, retocando `base_color.png`:
  - tapar el glifo con el olive drab de alrededor;
  - igualar el extradós al aluminio del fuselaje.
- La deriva lisa necesitaría otro envío, o pintarle a mano las líneas de panel en el normal.
- No apliqué ningún retoque: con los criterios del encargo, el piloto no pasa, y aceptar «con retoque» es decisión del supervisor.

## Lo que NO salió bien (ronda 2)
1. **El refuerzo contra marcas no se pudo aplicar:** con `image_style_url`, Meshy ignora `text_style_prompt`. Las marcas vienen de la interpretación que Meshy hace de la imagen o del modelo, no del texto.
2. **La deriva sigue oscura** aunque su winding ya es correcto (0 caras invertidas). La causa ya no es el winding.
   - Hipótesis sin verificar: es una placa fina de dos caras casi coplanarias.
3. **Tamaño:** el candidato pesa 48 MB, frente a los 4,3 MB del actual. Valen las mismas recomendaciones de la ronda 1: ORM y compresión VRAM.
4. Durante la comprobación previa se colgó un proceso de Godot por usar rutas relativas con `--path`. No tuvo coste. Se repitió con rutas absolutas.

## Opciones para el supervisor (ninguna lanzada)
- **A, sin créditos:** retocar `base_color.png` (glifo y tono del extradós), volver a aplicarlo con el script, revisar y, si convence, autorizar el lote.
  - El lote: 3 × 10 créditos, con las entradas de los cazas corregidas con `fix_winding_for_meshy.gd`.
  - Hay que contar con que los cazas pueden sacar marcas parecidas y necesitar el mismo retoque.
- **B:** dar el B-17 por cerrado tal cual, como candidato con defectos conocidos, y no gastar más.
- **C, 10 créditos y nueva autorización:** reenviar con una imagen de estilo retocada, sin la torreta ni la zona que inspiran el glifo. No garantiza nada sobre la deriva.
