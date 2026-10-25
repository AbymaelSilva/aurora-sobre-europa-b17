# BORRADOR — LÉEME local (Linux, teclado y ratón)

> Borrador de Claude, 2026-10-24T11:12-07:00. Derivado línea a línea de `core/player_controls.gd` (382eac71…), `game.gd` (5d801e88…), `jugar_b17.py` e `INICIAR_B17.sh` del candidato `local-20261024-acd6e3ddfc40`. Se copiará a `release/<id>/LEEME.md/.txt` cuando Codex fije el id final.
> **Pendiente:** U01 (ayuda de suelta) y U02 (entradas al cambiar de puesto) van a cambiar el apartado del bombardero y quizá el HUD. Hay que revisar las secciones marcadas ⚠ contra el árbol corregido antes de publicar.

# Aurora sobre Europa — B-17 (versión local)

Probado únicamente en este equipo: Linux con NVIDIA GeForce RTX 2060 SUPER y Godot 4.7.2 incluido en la carpeta. Windows y mando/ROG Ally X: **no probados, posteriores a esta versión**.

## Arrancar
1. Abre una terminal en la carpeta del juego.
2. Ejecuta `./INICIAR_B17.sh`.
   - Se abre una consola (xfce4-terminal) y la ventana del juego (1280×720).
   - La consola guarda un registro en `logs/game-<fecha>.console.log`.
   - Solo puede haber una partida abierta a la vez con este lanzador.
3. Para comprobar que están el motor y el proyecto sin abrir el juego: `./INICIAR_B17.sh --check`.

## La misión
Eres AURORA UNO, el B-17 que encabeza una escuadrilla de seis. Fases: reunión de la escuadrilla → rumbo al objetivo (cazas Bf 109 y Fw 190, fuego antiaéreo) → pasada de bombardeo sobre el nudo ferroviario → regreso a casa → MISIÓN COMPLETADA o FALLIDA.

La partida **empieza en DEMO AUTOPILOTO**: el avión vuela solo hasta el objetivo y suelta la bomba. Pulsa **TAB** para tomar el control manual.

## Controles (teclado y ratón)
| Tecla / ratón | Acción |
|---|---|
| TAB | Alternar entre demo con piloto automático y control manual |
| 1 | Puesto PILOTO (cámara de persecución) |
| 2 | Puesto ARTILLERO (torreta superior, retícula circular) |
| 3 | Puesto BOMBARDERO (mira Norden, vista hacia el suelo) |
| ESC | Pausa / continuar |
| R | Reiniciar la misión (también al terminar: «R · VOLVER A VOLAR») |

**Piloto** (solo en manual y en el puesto 1):
| Tecla | Acción |
|---|---|
| W / ↑ | Morro abajo |
| S / ↓ | Morro arriba |
| A / ← | Girar a la izquierda |
| D / → | Girar a la derecha |
| Mayús | Más potencia |
| Ctrl | Menos potencia |

**Artillero** (puesto 2; funciona también en demo):
- Mover el ratón: apuntar la torreta (de −20° a +85° en vertical).
- Clic izquierdo, ESPACIO o B: disparar.
- El ratón no queda capturado por la ventana. Si el cursor llega al borde, vuelve a centrarlo.

⚠ **Bombardero** (puesto 3; solo en manual y durante PASADA DE BOMBARDEO):
- Clic izquierdo, ESPACIO o B: soltar la bomba (una por misión).
- ⚠ Ahora mismo la cruz de la mira NO marca el punto de impacto. Esta sección se reescribirá con la ayuda de suelta que entregue U01.

## Cosas conocidas de esta versión
- Al cerrar, la consola puede mostrar un aviso de Godot «ObjectDB instances leaked» (sonido del motor). No afecta a la partida.
- El texto de mando/ROG Ally X del inicio no aplica a esta versión (⚠ se retirará con U01).
