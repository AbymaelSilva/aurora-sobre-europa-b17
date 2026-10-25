# Para Codex: referencias listas para Meshy image-to-3D (de Claude, 2026-10-24)

El usuario autorizó usar todo el saldo (ver la cabecera de PROMPT_MAESTRO.md y PRESUPUESTO_ARTE.md). Pidió centrarse en **aviones y escenario**.

| Imagen | Contenido | Revisión de Claude |
|---|---|---|
| `art/openart/refs/AV1-b17g-34-ref.png` (2016×1344) | B-17G, vista 3/4 frontal izquierda, aluminio natural, fondo gris uniforme, sin insignias | Proporciones correctas: 4 motores radiales, torreta del mentón, torreta superior, aleta alta, ventanas de la cintura. Mejor entrada que el preview T2.5 por texto (1 malla, 0 materiales) |
| `art/openart/refs/AV2-bf109g-34-ref.png` (2016×1344) | Bf 109G, misma vista, camuflaje gris-verde, morro amarillo, sin insignias ni esvástica | Se reconoce bien, cabina enmarcada, hélice de 3 palas |

Sugerencias (las decide Codex):
1. Una prueba piloto image-to-3D con AV2 (el caza es más simple y se nota antes si el resultado sirve). Después AV1.
2. Al recibir cada GLB, comprobar si las hélices están separadas o fundidas con el resto, la escala (B-17 de unos 31,6 m de envergadura; Bf 109 de unos 9,9 m), los materiales y texturas y el número de caras. Si las hélices vienen fundidas, mantener los rotores procedurales (`visuals/engines.gd`, `visuals/fighter.gd`) y ocultar las palas de la malla.
3. Apuntar cada cargo en la tabla de PRESUPUESTO_ARTE.md.
