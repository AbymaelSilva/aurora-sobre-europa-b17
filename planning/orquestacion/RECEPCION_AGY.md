# Recepción — AGY (Coordinador técnico de Qwen y Responsable QA)

- **Fecha:** 2026-10-24T09:02:00-07:00
- **Fase vigente:** PLANIFICACIÓN («no codifiques, estamos planeando»). Lectura estática de archivos, escenas, tests y metadatos sin ejecución de comandos ni alteración de código o escenas.
- **Meta inmediata:** Elaboración del contrato técnico de QA y protocolo de coordinación de Qwen para los puntos bajo titularidad directa: 1.1.2.1, 1.1.2.2, 1.1.3.1, 1.1.3.2, 1.1.3.3, 1.1.4.3, 1.1.5.3, y definición de criterios de revisión para los puntos asignados a otros agentes.
- **Rol y responsabilidades asumidas:**
  1. Coordinación técnica de Qwen: definición de micro-contratos de GDScript, gestión de turnos de inferencia única (`qwen2.5-coder:7b-instruct-q4_K_M`), control del lock `godot-art.lock`, validación estricta de interfaces preexistentes sin permitir alteración de tests para enmascarar fallos.
  2. Responsable de QA: diseño y ejecución (en fases futuras) de la batería de pruebas automatizadas y manuales, recolección de diagnósticos literales, control de regresiones y reporte reproducible de evidencias.
  3. No decidir unilateralmente la aceptación final de la misión ni de los puntos; elevar evidencias a los revisores y supervisor según el tablero.
- **Puntos asignados bajo titularidad directa:**
  - `1.1.2.1`: Ataques y defensa verificados (Revisor: Claude, Dep: 1.1.1.3)
  - `1.1.2.2`: Daño independiente 4 motores (Revisor: Codex Entrega, Dep: 1.1.1.1)
  - `1.1.3.1`: Misión manual completa (Revisor: Codex Entrega, Dep: Fases 1 y 2)
  - `1.1.3.2`: Victoria, derrota, pausa, reset (Revisor: Claude, Dep: Fase 2)
  - `1.1.3.3`: Regresión tras integración (Revisor: Codex Entrega, Dep: Fases 1 y 2)
  - `1.1.4.3`: Prueba Windows/AllyX (Revisor: Codex Entrega, Dep: Paquete + hardware disponible)
  - `1.1.5.3`: Registro de cierre y pendientes (Revisor: Claude, Dep: Evidencias finales)
- **Puntos bajo revisión técnica asignada a AGY:**
  - `1.1.1.2`: Cinco compañeros texturizados (Dueño: Qwen)
  - `1.1.1.4`: Escala, orientación, hélices (Dueño: Claude)
  - `1.1.2.3`: Tres cámaras revisadas (Dueño: Claude)
  - `1.1.4.1`: Exportación Windows actualizada (Dueño: Codex Entrega)
  - `1.1.4.4`: Ajustes rendimiento/mando/UI (Dueño: Qwen)
  - `1.1.5.2`: Versión estable y respaldo (Dueño: Codex Entrega)
  - `1.1.5.4`: Opciones siguiente misión (Dueño: Claude; decide usuario)
- **Fuentes iniciales leídas e inspeccionadas:**
  - Orquestación y contratos: `planning/orquestacion/TABLERO.md`, `PROMPT_ORQUESTADOR.md`, `ENCARGO_QWEN.md`, `ENTREGA_QWEN.md`, `RECEPCION_CLAUDE.md`, `RECEPCION_CODEX_ENTREGA.md`, `ENTREGA_CODEX_ENTREGA.md`.
  - Proyecto Godot: `godot/B17/project.godot`, `godot/B17/game.gd`, `godot/B17/core/simulation.gd`, `godot/B17/core/damage.gd`, `godot/B17/core/combat_manager.gd`, `godot/B17/core/player_controls.gd`, `godot/B17/aircraft.gd`, `godot/B17/formation.gd`, `godot/B17/visuals/fighter.gd`.
  - Suites de test existentes: `godot/B17/tests/test_aircraft_models_claude.gd`, `godot/B17/tests/test_formation_six.gd`, `godot/B17/tests/test_claude_batch.gd`, `godot/B17/tests/test_claude_review.gd`, `godot/B17/tests/test_manual_mission_claude.gd`, `godot/B17/tests/test_release_acceptance.gd`, `godot/B17/tests/test_long_mission.gd`, `godot/B17/tests/test_scene_mission.gd`, `godot/B17/tests/test_qwen_assets.gd`.
  - Registros históricos: `logs/agy-coordinador/candidate-verification.json` (constatando advertencia de fuga de 4 objetos en `test_claude_review.gd`).
- **Salida comprometida:** `planning/orquestacion/ENTREGA_AGY.md` con el contrato técnico exhaustivo y trazabilidad estricta en `logs/orquestacion/agy.log`.
- **Restricciones respetadas:** No alterar archivos de otros agentes ni el tablero central. No ejecutar comandos ni procesos de motor en esta fase.
