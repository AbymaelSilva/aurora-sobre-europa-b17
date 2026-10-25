# Directiva Técnica — Lote 7: Gran Incursión Masiva sobre Europa en Invierno

> [!IMPORTANT]
> **ORDEN DE EJECUCIÓN AUTÓNOMA DIRECTA:**
> ```bash
> agy --dangerously-skip-permissions --mode auto -p "$(cat planning/orquestacion/PROMPT_GRAN_INCURSION_INVIERNO_LOTE7.md)"
> ```

> [!NOTE]
> **Estándar Permanente para Documentos MD:**
> Conforme a la directiva del proyecto, este documento incluye la instrucción literal de ejecución autónoma `agy --dangerously-skip-permissions --mode auto -p ...` para su ejecución desatendida.

---

### 1.1.1.0 Escuadrilla Aliada Masiva (300 Aviones en Vuelo)

- **1.1.1.1** `core/formation_slots.gd`: Implementar un generador procedural de ranuras de vuelo escalonadas que defina las coordenadas 3D para 300 aeronaves. El despliegue debe organizarse según la doctrina histórica de *Combat Wings* de la 8ª Fuerza Aérea, dividida en 3 grandes escalones (Lead Wing, High Wing a estribor y Low Wing a babor) con separación lateral de 35 a 60 m y escalonamiento vertical de 15 a 30 m para evitar turbulencias y colisiones visuales.
- **1.1.1.2** `formation.gd`: Instanciar la flota aliada de 300 aviones optimizando el rendimiento mediante jerarquía de nodos o `MultiMeshInstance3D` para las unidades de fondo, reservando modelos completos con `aircraft.gd`, `bomber_details.gd` y `markings.gd` para las unidades visibles cercanas al jugador.
- **1.1.1.3** `game.gd` y `visuals/escort.gd`: Distribuir la fuerza aérea aliada en una combinación de bombarderos pesados B-17G Flying Fortress y cazas de escolta P-51D Mustang (`aircraft/models/p51d.glb`) en patrulla de flancos y cota alta (+150 m) cubriendo la caja de bombardeo.

---

### 1.1.2.0 Fuerza de Interceptación Enemiga (30 Cazas de la Luftwaffe)

- **1.1.2.1** `core/combat_manager.gd`: Ampliar el gestor de combate para manejar 30 cazas enemigos activos. Distribuirlos en oleadas masivas coordinadas de ataque frontal («12 en punto alto»), ataques por sectores laterales y persecución por la cola, alternando los modelos Bf 109G y Fw 190A.
- **1.1.2.2** `game.gd`: Expandir el pool de visuales `fighter_visuals` de 4 a 30 nodos con orientación independiente, animación de rotores a 40 rad/s y trazadores defensivos correspondientes.
- **1.1.2.3** `core/fighter_ai.gd`: Sincronizar las trayectorias de pase de ataque y dispersión para que 30 cazas operen con determinismo sin solaparse en sus vectores de tiro.

---

### 1.1.3.0 Artillería Antiaérea Estocástica (15 Detonaciones por Minuto)

- **1.1.3.1** `flak_model.gd`: Modificar el modelo de disparo antiaéreo para generar un promedio exacto de **15 explosiones por minuto** (media de 1 detonación cada 4,0 segundos). Implementar un intervalo aleatorio pseudo-estocástico entre 2,5 s y 5,5 s utilizando `RandomNumberGenerator` con semilla determinista, emulando la dispersión irregular de las baterías de 88 mm alemanas.
- **1.1.3.2** `visuals/flak_burst.gd`: Reducir la escala visual de cada explosión al 20% del valor original (`pixel_size = 0.016`, dispersión de grupo reducida a `0.30` y escala de expansión contenida entre `0.4` y `6.8` m), generando bocanadas de humo negro compactas y densas de 10 a 15 metros reales.
- **1.1.3.3** `game.gd`: Gestionar un pool ampliado de 20 puffs de flak distribuidos tridimensionalmente a lo largo de la caja de vuelo de la formación, reproduciendo audio `flak_near` o `flak_far` según la cercanía al jugador.

---

### 1.1.4.0 Bombardeo en Salva de Saturación (30 Bombas por B-17)

- **1.1.4.1** `bomb_model.gd` y `core/simulation.gd`: Sustituir la lógica de proyectil único por una salva en ristra (*bomb train*) de **30 bombas por cada B-17**. Al activarse la orden de suelta (`SPACE` o automático), liberar las 30 bombas en intervalos secuenciales de 0,08 s con dispersión balística longitudinal realista.
- **1.1.4.2** `game.gd`: Instanciar y renderizar la lluvia masiva de bombas cayendo coordinadamente desde la formación hacia el nudo ferroviario objetivo, sincronizando el audio de desprendimiento mecánico múltiple y detonaciones encadenadas en tierra.
- **1.1.4.3** `ui/mission_overlay.gd` y `core/bombing_aid.gd`: Actualizar la telemetría de bombardeo en el HUD para reflejar el estado de la salva («SALVA EN PROGRESO: [xx/30]», «ALFOMBRA DE BOMBAS IMPACTADA»).

---

### 1.1.5.0 Clima y Escenario de Invierno Europeo (Invierno de 1944)

- **1.1.5.1** `world/farmland.gdshader`: Modificar el shader de terreno para aplicar un manto invernal continuo:
  - Mezcla procedural de nieve europea (`vec3(0.92, 0.94, 0.97)`) sobre campos de cultivo y arboledas desnudas.
  - Transformación del cauce fluvial en río helado con tonos azulados pálidos (`vec3(0.70, 0.80, 0.86)`) y alta reflectividad de hielo (`ROUGHNESS = 0.22`, `METALLIC = 0.18`).
- **1.1.5.2** `world/atmosphere.gd`: Configurar la atmósfera invernal:
  - `sky_top_color = Color(0.28, 0.38, 0.48)` (azul invernal encapotado).
  - `sky_horizon_color = Color(0.70, 0.76, 0.82)` (horizonte brumoso y pálido).
  - `ground_bottom_color = Color(0.75, 0.78, 0.82)` (rebote lumínico de la nieve).
  - Niebla helada `fog_light_color = Color(0.75, 0.80, 0.86)` con densidad calibrada a `0.00010`.
  - Desaturación de ajuste tonal a `0.88` para una estética cinematográfica invernal.
- **1.1.5.3** `game.gd`: Ajustar la iluminación de `$Sun` a un ángulo rasante invernal (`rotation_degrees = Vector3(-16.0, -28.0, 0.0)`), luz fría `Color(0.94, 0.96, 1.0)` y energía balanceada a `1.20`.

---

### 1.1.6.0 Verificación, Pruebas y Criterios de Aceptación

- **1.1.6.1** Pruebas Automatizadas: Actualizar las aserciones de `tests/test_formation_six.gd`, `tests/test_imported_aircraft_integration.gd` y suites de combate para verificar la compatibilidad de la gran armada sin romper la regresión base.
- **1.1.6.2** Rendimiento Gráfico: Verificar en la NVIDIA GeForce RTX 2060 SUPER una tasa sostenida de 60 FPS en 1280x720 Forward+ renderizando la flota masiva y las 30 bombas simultáneas.
- **1.1.6.3** Validación Visual GPU: Ejecutar `capture_mission_claude.gd` y almacenar capturas de la armada de 300 aviones, el flak estocástico, la alfombra de bombas y el manto de nieve en `logs/revision_supervisor/`.
- **1.1.6.4** Registro y Bitácoras: Asentar el estado en `supervisor.log`, `TABLERO.md`, `AGY_AVANCE.md` y `AGY_ESTADO.json`.
