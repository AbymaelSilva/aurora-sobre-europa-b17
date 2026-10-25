# Recepción de Mando - Proyecto B-17 "Aurora sobre Europa"

- **Fecha**: 2026-10-24
- **Agente Coordinador**: Agy (Antigravity)
- **Programador Principal**: Qwen (vía encargar_qwen.py / qwen2.5-coder:7b-instruct-q4_K_M en Ollama)
- **Motor / Plataforma Objetivo**: Godot 4 (Linux testbench / Windows & ROG Ally X destino final)
- **PID / Contexto**: Supervisor de sesión agy-cli, workspace `/home/test-bench/Documents/B17-project`.

## Meta Comprendida
Construir y completar de forma autónoma todo el código jugable de la misión "Aurora sobre Europa":
1. Coordinar a Qwen mediante contratos rigurosos y pruebas unitarias/integración en Godot headless.
2. Integrar combate aéreo activo: oleadas de cazas interceptores con IA (aproximación, ataque, ruptura, reposicionamiento), balística y pools de trazadoras, fuego defensivo de torretas, daño modular a 4 motores y subsistemas.
3. Integrar detalles de bombardero y objetivos terrestres texturados creados en lotes previos.
4. Bombardeo de precisión con feedback visual/impacto, retorno seguro y debrief coherente.
5. Control manual accesible (teclado/ratón + mando ROG Ally X con zonas muertas y sensibilidad) manteniendo demo/autopiloto separado para pruebas.
6. Estabilidad, cero fugas de memoria/instancias duplicadas, verificación rigurosa a 30/60/120 Hz.
7. Respetar estrictamente los bloqueos de archivos y no editar `game.gd` ni `mission_overlay.gd` hasta que aparezca `planning/AGY_HANDOFF_READY`.

## Primeras Tareas Inmediatas
1. Leer documentación de coordinación previa (`COORDINACION_CODEX_CLAUDE.md`, `AVANCE_CLAUDE.md`, `QWEN_DIEZ_TAREAS.md`).
2. Comprobar existencia de `planning/AGY_HANDOFF_READY` y estado de archivos en `godot/B17/`.
3. Ejecutar pruebas existentes en Godot headless (`tests/test_qwen_assets.gd`, `tests/test_scene_mission.gd`, `tests/test_claude_batch.gd`) para verificar línea base y regresiones.
4. Inicializar `planning/AGY_AVANCE.md`, `planning/AGY_ESTADO.json` y `planning/COORDINACION_AGY.md`.
