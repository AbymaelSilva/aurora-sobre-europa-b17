# Meta de Implementación — Cuatro Mejoras de Jugabilidad MEDIO
# Aurora sobre Europa — B-17 Flying Fortress (Godot 4.7.2)

> [!IMPORTANT]
> **ORDEN DE EJECUCIÓN AUTÓNOMA DIRECTA:**
> ```bash
> agy --dangerously-skip-permissions --mode auto -p "$(cat planning/orquestacion/PROMPT_MEJORAS_MEDIO.md)"
> ```

Fecha: 2026-10-24  
Proyecto: `/home/test-bench/Documents/B17-project/godot/B17`  
Motor: Godot 4.7.2.stable.official.ed1daf0bf (`tools/godot`)  
Estado inicial de regresión: 29/29 tests PASS (Lote 9)  

Tu objetivo es implementar las cuatro mejoras de complejidad MEDIO y verificarlas con la suite de tests existente. Ejecuta de forma autónoma. No inventes logs ni falsifiques PASS.

---

## 1.1.1.0 Autoridad y Restricciones

- **1.1.1.1** Las cuatro mejoras deben coexistir con todo lo ya verificado: 48 cazas, 16 P-51D, 300 B-17 en MultiMesh, cámara orbital, flak calibrado, voces en inglés con subtítulos españoles, partitura adaptativa y banco de 47 efectos. No alteres ninguno de esos sistemas.
- **1.1.1.2** Los cinco WAV de la Browning M2 son inmutables. Sus hashes están en `logs/audio_redesign/m2_protected_hashes.json`. No los regeneres, muevas ni normalices.
- **1.1.1.3** No toques `tests/` salvo para añadir los nuevos tests de esta entrega. No modifiques tests existentes excepto para agregar un `assert` o parámetro opcional que los haga compatibles.
- **1.1.1.4** Respalda en `logs/mejoras_medio/backup/` todos los archivos que modifiques antes de editarlos. Registra cambios en `logs/mejoras_medio/changes.diff`.

---

## 1.1.2.0 Mejora 1 — Gestión de Emergencias de Motores y Extintores

### Descripción
Cuando un motor individual baje de 45/100 (humo) o de 20/100 (fuego), el jugador en puesto PILOTO puede activar contramedidas que afectan la física de vuelo.

### Implementación

**`core/damage.gd`** — Añadir estado por motor y campo de extintor:
```gdscript
var engine_feathered: PackedByteArray = PackedByteArray([0, 0, 0, 0])
var engine_extinguisher_used: PackedByteArray = PackedByteArray([0, 0, 0, 0])

func feather_engine(idx: int) -> void:
    # Detiene la hélice: elimina resistencia pero ese motor ya no genera empuje
    if idx >= 0 and idx < 4 and not engine_feathered[idx]:
        engine_feathered[idx] = 1

func use_extinguisher(idx: int) -> void:
    # Actúa si motor en fuego (<20); detiene degradación posterior; no repara
    if idx >= 0 and idx < 4 and not engine_extinguisher_used[idx] and engines[idx] < 25.0:
        engine_extinguisher_used[idx] = 1
        engines[idx] = clampf(engines[idx] + 8.0, 0.0, 25.0)

func thrust_factor() -> float:
    var total := 0.0
    for i in 4:
        var contrib := engines[i] / 100.0
        if engine_feathered[i]:
            contrib = 0.0  # Motor embandado: sin empuje, sin resistencia añadida
        total += contrib
    return 0.6 + 0.4 * (total / 4.0)
```

**`core/simulation.gd`** — Parar degradación de motor si extintor usado:
- En `apply_damage` / flak: si `damage.engine_extinguisher_used[idx]` es true, el motor no sigue degradándose por flak (sí por impacto directo de caza).

**`core/player_controls.gd`** — Añadir keybinds en teclado y mando:
- Teclado: `F1`–`F4` = embanderar motor 1–4. `Ctrl+F1`–`Ctrl+F4` = disparar extintor motor 1–4.
- Mando (solo perfil ROG_ALLY_X / XBOX): `LT+Cruceta+A` cicla motor seleccionado; `LT+Cruceta+X` embandера; `LT+Y` extintor sobre motor seleccionado. Documenta en overlay si se añade UI.
- Solo disponible en puesto PILOTO. Ignorar en ARTILLERO y BOMBARDERO.

**`ui/mission_overlay.gd`** — Indicador de estado de motores:
- Cuatro iconos pequeños (M1–M4) en zona inferior del HUD. Color: verde >45, naranja 20–45, rojo <20, gris si embandado.
- Al activar extintor: flash breve «EXTINTOR M[n]» en HUD.

**`core/flight.gd`** — Compesación de timón asimétrica:
- Si un motor de babor (M1/M2) tiene distinta potencia que estribor (M3/M4), añadir un `turn_bias` proporcional al desequilibrio que el jugador debe contrarrestar con el timón para mantener rumbo recto. Rango máximo ±0.12 rad/s.

### Archivos a crear o modificar
- `core/damage.gd` (modificar)
- `core/simulation.gd` (modificar)
- `core/player_controls.gd` (modificar)
- `core/flight.gd` (modificar)
- `ui/mission_overlay.gd` (modificar)
- `tests/test_engine_emergencies.gd` (nuevo)

---

## 1.1.3.0 Mejora 2 — Tránsito entre Múltiples Puestos de Ametralladoras

### Descripción
Ampliar el puesto ARTILLERO para ciclar entre tres estaciones históricas del B-17G: torreta dorsal superior (actual), torreta de cola (*tail*) y torreta de bola ventral (*ball turret*). Cada una cubre un arco de fuego distinto.

### Implementación

**`core/player_controls.gd`** — Nueva variable y lógica de ciclo:
```gdscript
var gunner_station: String = "DORSAL"  # "DORSAL" | "COLA" | "VENTRAL"

func cycle_gunner_station() -> void:
    match gunner_station:
        "DORSAL": gunner_station = "COLA"
        "COLA":   gunner_station = "VENTRAL"
        "VENTRAL": gunner_station = "DORSAL"
```
- Teclado: `Q` en puesto ARTILLERO cicla la estación.
- Mando: `LB+Cruceta Abajo` (no colisiona con zoom de cámara porque zoom exige estar en cámara exterior).
- En reinicio: `gunner_station` vuelve a "DORSAL".

**`core/player_controls.gd`** — Ajustar límites de apuntado según estación:
- DORSAL: yaw libre 360°, pitch [-20°, +85°].
- COLA: yaw ±35° respecto a la cola (180° del rumbo), pitch [-10°, +25°].
- VENTRAL: yaw libre 360°, pitch [-90°, -10°] (apunta hacia abajo).

**`visuals/combat_mounts.gd`** — Origen del tracador por estación:
- DORSAL: offset `Vector3(-0.18, 2.2, -3.6)` (actual).
- COLA: offset `Vector3(0.0, 0.6, 11.8)`.
- VENTRAL: offset `Vector3(0.0, -2.0, -0.95)`.

**`ui/mission_overlay.gd`** — Indicador de estación activa:
- Pequeña etiqueta junto al aviso de amenaza: `[TORRETA: DORSAL / COLA / VENTRAL]`.
- Actualiza al ciclar sin requerir menú extra.

**`game.gd`** — Cámara de artillero según estación:
- DORSAL: `Vector3(0.0, 2.8, -1.8)` (actual).
- COLA: `Vector3(0.0, 0.8, 12.0)`.
- VENTRAL: `Vector3(0.0, -1.8, -1.0)`.

### Archivos a crear o modificar
- `core/player_controls.gd` (modificar)
- `visuals/combat_mounts.gd` (modificar)
- `ui/mission_overlay.gd` (modificar)
- `game.gd` (modificar)
- `tests/test_gunner_stations.gd` (nuevo)

---

## 1.1.4.0 Mejora 3 — Escoltas P-51D con Combate Activo y Solicitud por Radio

### Descripción
Los P-51D ya tienen lógica de combate visual en `visuals/escort.gd`. Esta mejora añade daño real al fuego de escolta y una orden táctica de radio del jugador.

### Implementación

**`visuals/escort.gd`** — Daño real al disparar:
- Cuando el P-51 efectúa fuego (`fire_cooldown <= 0` y `nearest < 600.0` y dot > 0.85), llamar `target["health"] = maxf(0.0, target["health"] - 0.015)` y registrar en `combat.damage_events` con causa `"escort"`.
- El daño es bajo (0.015 por ráfaga, cada 0.5 s) para que el jugador y la IA compartan protagonismo sin que las escoltas eliminen todos los cazas solas.

**`core/player_controls.gd`** — Comando de cobertura por radio:
```gdscript
var escort_cover_requested: bool = false
var escort_cover_timer: float = 0.0
const ESCORT_COVER_DURATION: float = 20.0

func request_escort_cover() -> void:
    escort_cover_requested = true
    escort_cover_timer = ESCORT_COVER_DURATION
```
- Teclado: `E` en puesto PILOTO o ARTILLERO.
- Mando: `LT+RB` (en perfil no TECLADO_RATON).
- Cooldown: 45 s entre solicitudes (evita spam).

**`visuals/escort.gd`** — Modo de cobertura cercana:
- Si `controls.escort_cover_requested` es true, los 4 Mustangs más cercanos al jugador (elementos 0 y 1 de babor y estribor) fuerzan `engaging = true` ignorando el ciclo de 8 s y priorizan cazas dentro de 800 m del jugador.
- Al expirar el timer, vuelven al ciclo normal.

**`ui/mission_overlay.gd`** — Feedback de radio:
- Al solicitar cobertura: flash «P-51 · COBERTURA SOLICITADA» 2 s.
- Durante cobertura activa: pequeño indicador «ESCOLTA ACTIVA» con timer descendente.
- Durante cooldown: mensaje al intentar solicitar de nuevo «RADIO · ESPERA [Xs]».

**`game.gd`** — Pasar `controls` al método `update_combat` de `escort.gd`:
- Actualizar la firma: `escort.update_combat(delta, ..., controls)`.

### Archivos a crear o modificar
- `visuals/escort.gd` (modificar)
- `core/player_controls.gd` (modificar)
- `ui/mission_overlay.gd` (modificar)
- `game.gd` (modificar)
- `tests/test_escort_combat.gd` (nuevo)

---

## 1.1.5.0 Mejora 4 — Metralla de Flak con Daño a Instrumentos

### Descripción
Las detonaciones de flak a menos de 80 m del B-17 pueden causar averías secundarias en instrumentos y visor Norden, añadiendo tensión sobre el objetivo.

### Implementación

**`flak_model.gd`** — Exponer proximidad al llamador:
```gdscript
var last_burst_proximity: float = 999.0  # en metros; actualizar en step()
```
- En `step()`, cuando hay detonación, asignar `last_burst_proximity = rng.randf_range(15.0, 120.0)` (distancia simulada al casco).

**`core/damage.gd`** — Nuevos campos de instrumentos:
```gdscript
var altimeter_error: float = 0.0      # Metros de error en lectura de altímetro
var compass_drift: float = 0.0        # Radianes de deriva de brújula
var norden_disabled: bool = false     # Visor Norden dañado: suelta manual
var instrument_damage_timer: float = 0.0

func apply_instrument_damage(proximity: float) -> void:
    if proximity > 80.0: return
    var severity := 1.0 - (proximity / 80.0)
    if randf() < severity * 0.45:
        altimeter_error = randf_range(-40.0, 40.0) * severity
        compass_drift = randf_range(-0.08, 0.08) * severity
    if randf() < severity * 0.20 and proximity < 30.0:
        norden_disabled = true
    instrument_damage_timer = randf_range(8.0, 25.0) * severity

func step_instruments(delta: float) -> void:
    if instrument_damage_timer > 0.0:
        instrument_damage_timer -= delta
        if instrument_damage_timer <= 0.0:
            altimeter_error = 0.0
            compass_drift = 0.0
            norden_disabled = false
```

**`core/simulation.gd`** — Llamar apply_instrument_damage en burst:
- Después de `damage.apply_damage(flak_damage, ...)`: `damage.apply_instrument_damage(flak.last_burst_proximity)`.
- En `step()`: `damage.step_instruments(delta)`.

**`ui/mission_overlay.gd`** — Mostrar avisos de instrumentos:
- Si `altimeter_error != 0.0`: mostrar altímetro con el valor distorsionado (altitud real + error) en color naranja.
- Si `compass_drift != 0.0`: rumbo distorsionado.
- Si `norden_disabled`: superponer «NORDEN AVERIADO · SUELTA MANUAL» parpadeante en rojo; la suelta automática del autopiloto queda inhibida temporalmente.

**`core/bombing_aid.gd`** / **`core/simulation.gd`** — Inhibir suelta automática si Norden dañado:
- `if mission.phase == "BOMBARDEO" and autopilot and not bomb.spent and not damage.norden_disabled:` antes de la suelta automática.

**`ui/mission_overlay.gd`** — Efectos visuales de impacto cercano:
- Flash blanco de pantalla (<0.15 s) en burst < 30 m.
- Vibración del HUD (offset aleatorio ±4 px durante 0.4 s) en burst < 50 m.

### Archivos a crear o modificar
- `flak_model.gd` (modificar)
- `core/damage.gd` (modificar)
- `core/simulation.gd` (modificar)
- `core/bombing_aid.gd` (modificar)
- `ui/mission_overlay.gd` (modificar)
- `tests/test_flak_instruments.gd` (nuevo)

---

## 1.1.6.0 Verificación, Pruebas y Cierre

### Suite de tests obligatorios

Ejecutar cada test con:
```bash
tools/godot --headless --path godot/B17 --script res://tests/<archivo>.gd
```

**Tests nuevos a crear:**
- `tests/test_engine_emergencies.gd`: Verificar feathering reduce thrust_factor, extintor detiene degradación, turn_bias proporcional al desequilibrio, keybinds F1–F4, límites de engines tras extintor.
- `tests/test_gunner_stations.gd`: Verificar ciclo DORSAL→COLA→VENTRAL→DORSAL, límites de pitch por estación, origen del tracador correcto, reset a DORSAL.
- `tests/test_escort_combat.gd`: Verificar damage_events con causa "escort", cooldown de 45 s, duración ESCORT_COVER_DURATION, fuego activo en modo cobertura, no duplicar eventos.
- `tests/test_flak_instruments.gd`: Verificar apply_instrument_damage sin efecto a >80 m, altimeter_error/compass_drift en rango, norden_disabled solo <30 m, step_instruments limpia estado, inhibición suelta automática.

**Regresión completa (29 tests existentes + 4 nuevos = 33 PASS esperados).**

### Capturas GPU (opcional si el proceso de juego del Lote 9 sigue abierto)
- Verificar visualmente el indicador de motores, etiqueta de torreta y flash de instrumentos a 1280×720.

### Entrega
- Crear `planning/orquestacion/ENTREGA_MEJORAS_MEDIO.md` con todos los cambios, hashes M2 verificados y resultado de la regresión.
- Actualizar `planning/orquestacion/TABLERO.md` con la nueva fila sin borrar historial.
- Marcar como COMPLETADO_VERIFICADO solo si los 33 tests pasan y los hashes M2 coinciden.
