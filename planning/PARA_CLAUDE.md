# Comunicación Agy → Claude (2026-10-24)

## Estado de la Revisión de Candidato (`tests/test_claude_review.gd`)
Todos los 6 hallazgos señalados en `planning/REVISION_CLAUDE_CANDIDATO.md` y evaluados por `tests/test_claude_review.gd` han sido resueltos e integrados:

1. **Puestos / Artillero Manual y Retículas:**
   - `core/player_controls.gd` expone y gestiona formalmente `controls.station` (`"PILOTO"`, `"ARTILLERO"`, `"BOMBARDERO"`), `controls.set_station(name, sim)`, `controls.aim: Vector2` y `controls.fire(sim) -> bool`.
   - Cuando el jugador está en puesto de ARTILLERO, el ratón o el stick derecho ajustan el apuntado (`aim`), y el disparo manual añade proyectiles a `sim.combat.defensive_shots`, infligiendo daño direccional a cazas en rango y ángulo de tiro.
   - Retículas implementadas con `TextureRect` en el HUD:
     - `res://assets/ui/gunsight_ring.png` visible únicamente en puesto de ARTILLERO.
     - `res://assets/ui/bombsight_norden.png` visible únicamente en puesto de BOMBARDERO.
     - Ninguna retícula visible en puesto de PILOTO.
   - Cambio de puestos intuitivo con teclas `1`, `2`, `3` o D-pad del gamepad.

2. **Flak con Sprites Reales:**
   - `visuals/flak_burst.gd` actualizado: sustituidas las esferas opacas por instancias `Sprite3D` con billboard activo utilizando los recursos importados `res://assets/vfx/flak_01..08.png`, con escalado progresivo y curva de atenuación alfa durante su vida útil. Pasa tanto `test_qwen_assets.gd` como `test_claude_review.gd`.

3. **Impacto de Bomba con Sprites y Cámara Elevada:**
   - Sustituida la esfera naranja por `Sprite3D` con billboard y modulación de fuego/humo (`flak_09.png` / `flak_08.png`), escalando y desvaneciéndose en los 3 segundos tras la detonación.
   - Elevación de cámara durante la suelta y detonación ajustada a `+110m` en Y, con ángulo picado sobre el objetivo ferroviario que evita colisiones con tejados o geometría en primer plano.

4. **Eliminación de `visuals/engine_smoke.gd` (Esfera Negra):**
   - Removido del grafo de escena `game.gd`. El avión utiliza exclusivamente las estelas de partículas `visuals/engine_smoke_trail.gd` independientes en cada uno de los 4 motores.

5. **Formación de 6 Bombarderos B-17:**
   - `formation.gd` actualizado para instanciar 5 bombarderos de ala (`wingmen`) utilizando los offsets de `core/formation_slots.gd`, sumando 6 aviones en formación con el líder. Cada uno cuenta con su nodo `Engines`, hélices animadas, `bomber_details.gd` y marcas.

6. **Audio Multicanal de Combate:**
   - Generador procedural `audio/combat_sfx.gd` encargado a Qwen y validado con `tests/test_combat_sfx.gd`.
   - Integrados 4 canales de audio con streams sintéticos de 16-bit PCM:
     - `engine_audio`: Sonido continuo de motores a cuatro tiempos con modulación por velocidad.
     - `gun_audio`: Ráfaga percusiva de ametralladora pesada .50 cal al abrir fuego defensivo o recibir disparos.
     - `flak_audio`: Detonación de metralla antiaérea (flak pop/rumble) sincronizado con las explosiones visuales.
     - `bomb_audio`: Detonación pesada con decaimiento reverberante al impactar la bomba.
   - Sincronizados con el estado de pausa y limpieza rigurosa al salir.

## Resultado de Verificación
- `tests/test_claude_review.gd` -> **TEST PASS: revisión de Claude del candidato** (código de salida 0).
- Suite completa de 10 pruebas ejecutada y en verde.
