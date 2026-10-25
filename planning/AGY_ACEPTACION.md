# Acta de Aceptación Técnica - Candidato a Release (Ronda 4)
## Proyecto B-17: "Aurora sobre Europa"

- **Fecha de Evaluación:** 2026-10-24
- **Agente Coordinador:** Agy (Antigravity)
- **Programador de Núcleo:** Qwen (`qwen2.5-coder:7b-instruct-q4_K_M` en Ollama local)
- **Motor:** Godot 4.7.2 (Headless en Linux / Runtime Godot 4)
- **Estado de Release:** `candidate_complete` (Candidato para revisión)

---

### 1. Lo Demostrado y Validado por Pruebas

1. **Misión Completa y Paridad Simulación / Escena:**
   - La escena completa (`game.tscn` / `game.gd`) avanza a 60 Hz frame a frame sincronizada de forma determinista con el núcleo (`core/simulation.gd`).
   - Misión completa de larga duración validada en `tests/test_scene_mission.gd`: 785.12s de vuelo, 60 ráfagas de flak visuales y balísticas, 5 fases superadas con éxito (Reunión, Rumbo, Pasada de bombardeo, Regreso, Zona segura).
   - Pausa (`sim.paused`) congela la física, hélices, audios y efectos. Reinicio (`sim.reset()`) limpia completamente la telemetría, daños, bombas y trazadoras.

2. **Formación de 6 Bombarderos y Escenografía de Tierra:**
   - Formación de 6 B-17 (`formation.gd` con `core/formation_slots.gd`): Líder más 5 aviones de ala, todos con nodos `Engines`, hélices rotatorias y detalles de torretas y marcas (`visuals/bomber_details.gd` y `visuals/markings.gd`).
   - `world/target_ground.gd`: Plano texturado de 1800m con material `farmland_a.png` y shader de nudo ferroviario.
   - `world/cloud_sprites.gd` y atmósfera.

3. **Combate Aéreo Real (Dogfight & Balística):**
   - Módulo `core/combat_manager.gd` gestiona oleadas de cazas interceptores enemigos en penetración y retorno.
   - IA enemiga (`core/fighter_ai.gd`): Estados de aproximación, ataque en picado, rotura evasiva y reposicionamiento táctico.
   - Fuego defensivo del B-17: Las torretas responden automáticamente a los cazas a menos de 700m, causando derribos confirmados (rotación descontrolada y caída con gravedad).
   - Daño modular e independiente a los 4 motores (`damage.engines[0..3]`), con estelas de partículas independientes de `visuals/engine_smoke_trail.gd` (eliminada la esfera negra previa).
   - Balística visual sincronizada con `visuals/tracer_pool.gd` mediante pool acotado (cero allocations en runtime).

4. **Puestos de Tripulación, Controles Jugables y Retículas Centradas:**
   - Puestos conmutables (`PILOTO`, `ARTILLERO`, `BOMBARDERO`) mediante teclas 1, 2, 3 o D-pad del mando.
   - Modo Artillero: Cámara en la torreta dorsal (a 3.33 m del avión, orientada con `aim`). Puntería manual con ratón o stick derecho analógico (`aim: Vector2`), disparo manual con botón izquierdo o gatillo (`fire(sim) -> bool`), y retícula `assets/ui/gunsight_ring.png` centrada exactamente en pantalla.
   - Modo Bombardero: Cámara en el morro acristalado mirando hacia abajo en picado (`-basis.z.y = -0.98`), mira Norden `assets/ui/bombsight_norden.png` centrada exactamente en pantalla, suelta con Espacio o botón B del mando.
   - Modo Piloto: Vista de persecución con separación > 51 m (superando el requisito de ≥25 m) y 3 bombarderos de ala visibles simultáneamente en pantalla. Control directo de cabeceo, alabeo y acelerador. Sin retícula para visión despejada.
   - Soporte ROG Ally X / Gamepad con zona muerta radial (`deadzone = 0.15`). Alternancia instantánea entre demostración automática y vuelo manual (TAB / botón View).

5. **Efectos Visuales de Flak e Impacto con Sprites Reales:**
   - `visuals/flak_burst.gd` utiliza billboards `Sprite3D` con la secuencia real `res://assets/vfx/flak_01..08.png`, escalado y desvanecimiento alfa.
   - Impacto de bomba en el nudo ferroviario con sprites billboard de fuego y humo (`flak_09.png` y `flak_08.png`) y cámara elevada a +110m Y sin colisión con tejados.

6. **Audio Multicanal Procedural:**
   - 4 streams de audio sintetizados proceduralmente a 22050Hz 16-bit PCM: motor a cuatro tiempos continuo (`engine_tone.gd`), ametralladora pesada .50 cal, detonación de flak y explosión de bomba (`combat_sfx.gd`). Pausa unificada y cero fugas en salida.

7. **Estabilidad Física y Rendimiento Multi-Tasa:**
   - Verificado en `tests/test_release_acceptance.gd`: Ejecución determinista idéntica a 30 Hz, 60 Hz y 120 Hz sin valores NaN ni acumulación de deriva.
   - Verificado en `tests/test_claude_review.gd`: TEST PASS formal superando los 6 hallazgos de revisión externa.
   - Cero advertencias de objetos filtrados en la suite de aceptación (`0 ObjectDB instances leaked at exit`).

---

### 2. Límites Reales y Verificaciones Pendientes en Destino

- **Hardware Local de Prueba:** Las pruebas se han ejecutado en el entorno Linux del banco de trabajo con Godot 4 headless.
- **Hardware ROG Ally X / Windows Destino:**
   - El mapeo de controles utiliza las constantes nativas de `JOY_BUTTON_*` y `JOY_AXIS_*` de Godot 4 con filtrado de zona muerta de 0.15. La calibración final de háptica o curvas ergonómicas específicas del chasis ROG Ally X requiere verificación visual directa en dicha consola física.
- **Modelos 3D de Aviones y Exportación Windows:**
   - En espera de la clave de usuario para Meshy image-to-3D y plantillas de exportación Windows gestionadas por Claude según la división de tareas acordada.
