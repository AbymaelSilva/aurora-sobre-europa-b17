# Continuación del encargo Meshy (autorizada por el supervisor Claude, 2026-10-24)

Lee primero `planning/orquestacion/ENCARGO_MESHY_CLAUDE.md` (reglas, verificación y entregables, que siguen vigentes) y tu propia entrega `planning/orquestacion/ENTREGA_MESHY_TEXTURAS.md`.

## Autorización
Tu diagnóstico es correcto: el winding invertido de alas, estabilizadores y deriva es un defecto NUESTRO de entrada. Con la entrada corregida, el supervisor autoriza dentro del presupuesto aprobado por el usuario:
- 1. **Tercer piloto del B-17** con `art/meshy/input/b17g_winding_fix.glb`, la imagen de estilo `art/openart/refs/AV1-b17g-34-ref.png` y las mismas opciones, a **4K** (cuesta lo mismo que 2K: 10 créditos). Refuerza el prompt de texto contra las marcas inventadas: «… plain unmarked surfaces: absolutely no insignia, no roundels, no emblems, no letters, no numbers, no nose art, no stripes …».
- 2. Verificación del piloto como en el encargo original: AABB, `Rotor_*`, capturas con GPU antes y después, y criterios PASS.
- 3. **Si el piloto pasa**: genera con `tools_art/fix_winding_for_meshy.gd` las entradas corregidas de bf109g, fw190a y p51d, comprueba en cada una el AABB y los `Rotor_*` antes de enviarla y lanza el **lote a 4K** con AV2, AV3 y AV4 como estilo y los prompts del encargo original, reforzados contra marcas.
- 4. Sin más reintentos que los del encargo original. Si el tercer piloto falla, documenta y para.

## Al terminar
- Actualiza `ENTREGA_MESHY_TEXTURAS.md` (sección nueva «Ronda 2»), `PRESUPUESTO_ARTE.md` (cada cargo) y `logs/orquestacion/claude_meshy.log`.
- Los candidatos quedan en `art/meshy/candidatos/`. NO toques producción: la integración y la corrección del winding en los GLB del juego las decide el supervisor.
