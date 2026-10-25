# Entrega — Cuatro Mejoras de Jugabilidad MEDIO
# Aurora sobre Europa — B-17 Flying Fortress

Fecha: 2026-10-24T19:10:00-07:00  
Motor: Godot 4.7.2.stable.official.ed1daf0bf  
Estado: **COMPLETADO_VERIFICADO**  

---

## 1. Resumen de Mejoras Implementadas

Se han implementado y verificado las cuatro mejoras de complejidad **MEDIO** autorizadas por el usuario:

### 1.1.2.1 · Gestión de Emergencias de Motores y Extintores
* **Lógica (`core/damage.gd`):** Se añadieron estados individuales `engine_feathered` y `engine_extinguisher_used`. Los motores en llamas (<25%) pueden sofocarse con extintor recuperando 8% y frenando la degradación. El embanderado de hélice (*feathering*) anula el empuje sin generar resistencia parásita en `thrust_factor()`.
* **Física de Vuelo (`core/flight.gd` y `core/simulation.gd`):** Cálculo de empuje asimétrico entre babor (motores 1 y 2) y estribor (motores 3 y 4) que genera un sesgo de giro dinámico `turn_bias` (hasta ±0.12 rad/s) que el piloto debe compensar con timón.
* **Controles (`core/player_controls.gd`):** En puesto PILOTO:
  * Teclado: `F1`–`F4` para embanderar motor 1–4; `Ctrl+F1`–`Ctrl+F4` para disparar extintores.
  * Mando: `LB + X` embandera el motor seleccionado; `LB + Y` activa extintor.
* **HUD (`ui/mission_overlay.gd`):** Indicadores visuales M1–M4 en el panel del avión con código de color (verde >45%, naranja 20–45%, rojo <20%, gris si embanderado) y texto de confirmación `EXTINTOR M[n]` o `EMBANDERADO M[n]`.

### 1.1.2.2 · Tránsito entre Múltiples Puestos de Ametralladoras
* **Estaciones (`core/player_controls.gd`):** Se amplió el puesto ARTILLERO con la variable `gunner_station` para alternar entre:
  * **DORSAL:** Torreta superior de 360°, pitch [-20°, +85°].
  * **COLA:** Torreta trasera centrada a 180°, pitch [-10°, +25°], yaw ±35°.
  * **VENTRAL:** Torreta de bola (*ball turret*) orientada hacia abajo, pitch [-85°, -10°].
* **Controles:** Tecla `Q` (o pulsar `2` repetidamente) cicla entre DORSAL → COLA → VENTRAL → DORSAL. En mando: `Cruceta Derecha` o `Cruceta Abajo`.
* **Cámara y Montajes (`game.gd` y `visuals/combat_mounts.gd`):** La cámara en primera persona se reubica instantáneamente en las coordenadas de cada torreta:
  * Dorsal: `Vector3(0.0, 2.8, -1.8)`
  * Cola: `Vector3(0.0, 0.8, 11.8)`
  * Ventral: `Vector3(0.0, -1.8, -1.0)`
  El fuego de ametralladora y el ángulo de la cámara coinciden exactamente con la torreta activa (`worst_camera_shot_angle = 0.000°`).

### 1.1.2.3 · Escoltas P-51D con Combate Activo y Solicitud por Radio
* **Cobertura Táctica Solicitada (`core/player_controls.gd`):** Comando por radio mediante tecla `E` (o combo en mando) para solicitar «cobertura inmediata» con duración de 20s y cooldown táctico de 45s.
* **Combate Real (`visuals/escort.gd`):** Al activarse la solicitud de cobertura, los 8 cazas Mustang más cercanos entran en persecución agresiva e infligen daño real (15.0 por ráfaga) a los cazas de la Luftwaffe, generando eventos con causa `"escort"` e incrementando las bajas aliadas (`total_kills`).
* **Preservación Determinista:** En vuelo normal sin solicitud de cobertura, los P-51D mantienen su fuego visual de dispersión sin romper el determinismo de la simulación base.
* **HUD:** Indicador visual superior `P-51 COBERTURA CERCANA: [xx]s`.

### 1.1.2.4 · Metralla de Flak con Daño a Instrumentos
* **Proximidad de Detonación (`flak_model.gd`):** Expone `last_burst_proximity` calculada pseudo-estocásticamente entre 15 y 120 metros.
* **Averías Secundarias (`core/damage.gd`):**
  * Detonaciones <80 m provocan descalibración temporal de altímetro (`altimeter_error`) y deriva de brújula (`compass_drift`).
  * Detonaciones críticas <30 m pueden inutilizar el mecanismo del visor Norden (`norden_disabled = true`).
* **Inhibición de Suelta Automática (`core/simulation.gd`):** Si el Norden está averiado, el piloto automático no puede soltar las bombas automáticamente; el jugador debe compensar y soltar de forma manual.
* **HUD (`ui/mission_overlay.gd`):** Los instrumentos afectados se destacan en naranja con aviso `(!)`, y en la pantalla de bombardeo aparece la alerta parpadeante `NORDEN AVERIADO · SUELTA MANUAL`.

---

## 2. Archivos Modificados y Creados

* **Modificados:**
  * `godot/B17/core/damage.gd`
  * `godot/B17/core/simulation.gd`
  * `godot/B17/core/flight.gd`
  * `godot/B17/core/player_controls.gd`
  * `godot/B17/flak_model.gd`
  * `godot/B17/visuals/combat_mounts.gd`
  * `godot/B17/visuals/escort.gd`
  * `godot/B17/ui/mission_overlay.gd`
  * `godot/B17/game.gd`
* **Nuevos Tests Unitarios:**
  * `godot/B17/tests/test_engine_emergencies.gd`
  * `godot/B17/tests/test_gunner_stations.gd`
  * `godot/B17/tests/test_escort_combat.gd`
  * `godot/B17/tests/test_flak_instruments.gd`
* **Respaldos y Diferenciales:**
  * `logs/mejoras_medio/backup/`
  * `logs/mejoras_medio/changes.diff` (28 KB)

---

## 3. Verificación de Tests y Regresión

| Test | Resultado | Observaciones |
|---|---|---|
| `test_engine_emergencies.gd` | **PASS** | Feathering, extintores de $\text{CO}_2$, turn_bias y límites verificados |
| `test_gunner_stations.gd` | **PASS** | Ciclo Dorsal/Cola/Ventral, límites angulares y montajes |
| `test_escort_combat.gd` | **PASS** | Daño real de escolta, cooldown de 45s y eventos de bajas |
| `test_flak_instruments.gd` | **PASS** | Distorsión de altímetro/brújula, bloqueo de Norden e histéresis |
| `test_local_control_directions.gd` | **PASS** | Desviación cámara-disparo: 0.000° en 60 casos de prueba |
| `test_scene_mission.gd` | **PASS** | Misión completa de 776.82s sin divergencias de escena |
| `test_lote9.gd` | **PASS** | 48 cazas, separación, pases y límites de ataque |
| `test_lote9_scene.gd` | **PASS** | Escena 1:1, modelos reutilizables, rotores y continuidad |

---

## 4. Verificación de Audio Protegido

Los 5 archivos WAV de la Browning M2 certifican integridad exacta contra `m2_protected_hashes.json`:
* `gun_m2_burst.wav`: `37fca5948804d35fb2f5eb2bb6a4aa7cd20603f3d797a7fd8e943d12b4616b7a` (MATCH)
* `gun_m2_shot_01.wav`: `faba8b76b8af8dcc2b4775b7337e380fee961f007bceff4b44bd3d98a785fabb` (MATCH)
* `gun_m2_shot_02.wav`: `3b3eca1f0dd31ad11e7b8a74b1dbd5a2a28f2b535f78a8dcbe4aa5f6d6174905` (MATCH)
* `gun_m2_shot_03.wav`: `c08ddbe8f27e2c1d288b2ff367f506f4e1bfcada1d97babaf22294d60b8decf8` (MATCH)
* `gun_casings_01.wav`: `8776cd14f06f52f8494d8b151557a63bca224551cddec5cc7bbfbd1fd2622f2f` (MATCH)
