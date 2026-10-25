# Coordinación de Desarrollo - Agy

- **Coordinador Principal:** Agy
- **Programador Principal:** Qwen (vía `encargar_qwen.py`)
- **Estado de Handoff:** Recibido de Codex (`planning/AGY_HANDOFF_READY`).
- **Archivos bajo responsabilidad de Agy:**
  - `godot/B17/game.gd` (Escena principal de juego y orquestación visual/física)
  - `godot/B17/ui/mission_overlay.gd` (HUD, telemetría y mensajes de cabina)
  - Integración de los 10 módulos de Claude (`target_ground`, `formation_slots`, `fighter`, `fighter_ai`, `tracer_pool`, `bomber_details`, etc.)
  - Combate aéreo completo: intercepción de cazas, balística, daños a motores, torretas defensivas.
  - Bombardeo sobre objetivo ferroviario con impacto y debrief.
  - Controles de jugador (teclado/ratón y ROG Ally X / gamepad) con alternancia limpia y demo automática preservada.
  - Tests de aceptación y estabilidad a 30/60/120Hz.

## Registro de Dueños de Archivos
- `core/simulation.gd`: Lógica de simulación determinista (Agy / Qwen)
- `core/fighter_ai.gd`: IA de cazas interceptores (Claude / Qwen -> Agy / Qwen)
- `visuals/fighter.gd`: Malla y animación del caza (Claude / Qwen -> Agy)
- `visuals/tracer_pool.gd`: Pool acotado de trazadoras de combate (Claude / Qwen -> Agy)
- `visuals/bomber_details.gd`: Geometría y detalles del B-17 (Claude / Qwen -> Agy)
- `world/target_ground.gd`: Objetivo de tierra texturado (Claude / Qwen -> Agy)
- `core/player_controls.gd`: Controles del jugador y gestión de input (Agy / Qwen)
- `tests/*`: Pruebas automatizadas continuas (Agy)
