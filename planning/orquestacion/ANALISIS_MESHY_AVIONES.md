# Análisis: capacidades de Meshy frente a lo que mejoraría los aviones (supervisor Claude, 2026-10-24)

## Estado actual de los aviones (medido en el proyecto)
- 4 modelos: `godot/B17/assets/aircraft/models/{b17g,bf109g,fw190a,p51d}.glb`, de unos 4,3 MB cada uno. Los construyó Claude con `tools_art/loft_aircraft.gd` a partir de vistas ortográficas de OpenArt.
- **Geometría validada por el juego**:
  - escala real (`tests/test_aircraft_models_claude.gd`);
  - hélices en nodos `Rotor_*` que el juego hace girar;
  - anclajes de motor para el humo (`visuals/engine_anchors.gd`);
  - formación de 6 y pruebas de integración en PASS.

  **No debe romperse.**
- Material: un único `StandardMaterial3D` con **solo albedo**, un atlas de 2048² **proyectado** desde la vista lateral y la de planta. Defectos:
  - color estirado en las superficies oblicuas (panza, intradós, góndolas);
  - sin mapa normal: ni líneas de paneles ni remaches con relieve;
  - sin mapas de rugosidad y metal: el B-17 de aluminio natural se ve plano, sin reflejos;
  - sin oclusión ambiental;
  - sin desgaste coherente (manchas de escape, aceite, rozaduras en los bordes de ataque).
- Las calcas (estrella, nose art, registro de misiones) y el daño son PNG aparte (`assets/aircraft/decals`, `damage`). Se mantienen.

## Qué haría mejores a los aviones (por impacto visual en el juego)
1. **Juego PBR completo**: color base + normal + rugosidad + metal (+ AO). Es lo que más se nota con la luz del sol de Godot Forward+.
2. **Desplegado UV limpio**, sin proyección: color uniforme en los laterales y la panza.
3. **Acabados correctos por avión**:
   - B-17G: aluminio natural sin pintar, paneles de distinto tono, antideslumbrante oliva delante de la cabina y desgaste en los bordes de ataque;
   - Bf 109G: RLM 74/75/76 con moteado y capó amarillo;
   - Fw 190A: grises RLM 74/75/76 moteados;
   - P-51D: aluminio natural.
4. **Desgaste narrativo**: escapes en el extradós detrás de cada motor, aceite en las góndolas y suciedad de manipulación cerca de las puertas.
5. Mantener la geometría y la jerarquía del juego (escala, `Rotor_*`, pivotes, anclajes). El presupuesto de rendimiento ya está medido: 60 FPS con margen.

## Capacidades de Meshy y cómo encajan
(Verificar contra la documentación vigente, docs.meshy.ai: la API cambia.)
| Capacidad | Para qué sirve aquí | Encaje |
|---|---|---|
| **Retexture / Text-to-Texture** sobre un modelo subido, con prompt de texto y/o **imagen de estilo**; genera texturas PBR | Texturizar NUESTROS GLB conservando su geometría. Las imágenes de estilo son las vistas de OpenArt (`art/openart/refs/AV1-*`, `AV2-*`, …) | **ALTO: es la vía principal** |
| Image-to-3D / Multi-image-to-3D con textura PBR | Modelo nuevo desde las vistas. Mejor superficie, pero geometría propia: escala, hélices separadas y pivotes no garantizados | MEDIO: solo como plan B o referencia |
| Text-to-3D (vista previa + refine) | Ya se probó (5 créditos, vista previa del B-17); geometría sin control | BAJO |
| Remesh (cuadriláteros/triángulos, número de polígonos objetivo) | Bajar polígonos de un modelo de Meshy si se usara el plan B | Solo plan B |
| Rigging / animación | Humanoides: no aplica a aviones | NO |
| Exportación GLB/FBX/OBJ/USDZ, mapas PBR por separado | GLB para Godot, más los PNG de cada mapa | Sí |

Riesgos de Retexture y su mitigación:
- **Puede rehacer el UV o fusionar nodos y perder `Rotor_*`.** Solución: no usar el GLB de Meshy tal cual. Usar sus **mapas** y, si cambian las UV, transferirlos con un script de Godot o reconstruir el GLB: geometría y nodos nuestros, UV y materiales de Meshy. Verificar con las pruebas del juego.
- **Puede inventar marcas o insignias.** Pedir superficies limpias; las insignias van en nuestras calcas. **Nunca esvásticas**: los cazas sin insignias nacionales o con cruces de balkenkreuz como mucho.
- **Repeticiones o costuras.** Revisar en Godot con GPU, no solo en las miniaturas.

## Recomendación
Retexture del B-17 como **pieza piloto** → revisar en Godot → lote de Bf 109, Fw 190 y P-51. Opcional: un segundo acabado del B-17 (desgaste fuerte) para los compañeros de formación, para variar. Coste: cotizar en la API antes de cada envío y apuntarlo en `planning/PRESUPUESTO_ARTE.md`.
