# Revisión de Claude del candidato de Agy (ronda 2) — 2026-10-24 03:55

**Método:** ejecuté las 12 pruebas (todas PASS) y **8 capturas reales con GPU** de la misión completa (`tests/capture_mission_claude.gd`): inicio, cazas, flak, bombardeo, bomba cayendo, impacto, regreso y final. La misión de demostración se completa en 785 s con 4 cazas abatidos y el casco al 55 %.

**Veredicto:** el bucle de misión funciona y el HUD es bueno, pero **todavía no es la primera misión terminada**. Los hallazgos están codificados en `godot/B17/tests/test_claude_review.gd`, que **falla con 6 hallazgos** (salida literal más abajo).

## Hallazgos (por prioridad)
1. **Puestos / artillero manual: no existen.** `core/player_controls.gd` solo pilota y suelta la bomba; el fuego defensivo es 100 % automático. Contrato exigido (cabecera del test): `controls.station` en PILOTO/ARTILLERO/BOMBARDERO, `set_station(name, sim)`, `aim: Vector2`, `fire(sim)->bool`, que añade disparos del jugador a `sim.combat.defensive_shots`. Retículas: `assets/ui/gunsight_ring.png` en ARTILLERO y `assets/ui/bombsight_norden.png` en BOMBARDERO, ninguna en PILOTO. En los puestos que el jugador no ocupa sigue el automatismo.
2. **Flak con esferas marrones opacas.** Usar los 9 sprites realistas ya importados `assets/vfx/flak_01..09.png` (Sprite3D billboard o quad con alfa; crecimiento y desvanecido; destello breve opcional).
3. **Impacto con una esfera naranja de baja poligonización**, y la cámara de impacto atraviesa la geometría del complejo (placas naranjas en primer plano). Explosión con varios sprites de humo y fuego, y cámara por encima de los tejados.
4. **Bola negra junto al avión:** sigue instanciado `visuals/engine_smoke.gd` (esferas). Ya está `engine_smoke_trail.gd`, con partículas: quitar el de esferas.
5. **Formación de 3 bombarderos;** se piden 6. `core/formation_slots.gd` (6 puestos, +Z detrás) existe y está probado. Añadir `bomber_details` a todos.
6. **Audio:** solo hay motor. Faltan ametralladora .50, ráfaga de flak y explosión (sonidos procedurales como `audio/engine_tone.gd`), pausados con la misión.

## Lo que está bien (no tocar sin motivo)
Terreno con textura, complejo ferroviario, río, HUD y radio, sesión de resultados (debrief), pausa y reinicio, fase de bombardeo, núcleo determinista a 30/60/120 Hz, cazas que llegan a verse en pantalla (el test lo comprueba).

## Fuera del alcance de Agy (lo hago yo)
- **Exportación a Windows:** no hay `export_presets.cfg` ni plantillas de exportación de 4.7.2. Las plantillas requieren descarga; lo gestiona Claude.
- **Modelos 3D de Meshy:** esperan la clave del usuario. Mientras tanto, mantener los aviones procedurales.

## Salida literal del test (03:55)
```
FAIL formación: 3 bombarderos, se esperan 6
FAIL humo: sigue instanciado visuals/engine_smoke.gd (esfera negra); usar engine_smoke_trail.gd
FAIL audio: 1 streams, se esperan motor + ametralladora + flak + explosión
FAIL flak: no se vio ningún sprite de assets/vfx/flak_*.png (siguen esferas opacas)
FAIL impacto: la explosión no usa sprites de humo/fuego (sigue la esfera naranja)
FAIL puestos: player_controls no expone station/set_station/aim/fire
TEST FAIL: 6 hallazgos de la revisión pendientes
```

## Exportación a Windows (Claude, 03:55)
- Plantillas oficiales 4.7.2 (solo `windows_release/debug_x86_64.exe`, extraídas por HTTP Range con `tools_art/fetch_windows_templates.py`: 88 MB descargados de 1281, CRC32 verificado) en `~/.local/share/godot/export_templates/4.7.2.stable/`.
- `godot/B17/export_presets.cfg` ("Windows Desktop", PCK incrustado, S3TC/BPTC, excluye `tests/*`).
- `build/windows/AuroraSobreEuropa.exe`: 155 MB, PE32+ x86-64. **Hay que exportar de nuevo cuando Agy termine** (este es del estado de las 03:53).
- El paquete exportado arranca con el Godot de Linux (`--main-pack`, 600 fotogramas, salida 0). **No se ha ejecutado en Windows** (no hay Wine ni Ally X aquí).
- Hallazgo menor: `WARNING: 2 ObjectDB instances were leaked at exit` al cerrar (Agy había informado de cero fugas).

---

# Revisión 2 de Claude — candidato de la ronda 3 (04:24)
Mi prueba **no se modificó** y pasó. Se nota mejora: flak con sprites reales, audio de combate, 6 bombarderos, puestos con retículas, ya no hay bola negra. Pero las **10 capturas nuevas** (`tests/capture_mission_claude.gd`, 04:23) muestran fallos que la prueba no medía. Los he añadido a `tests/test_claude_review.gd`, que **vuelve a fallar (6)**:
```
FAIL cámara: un bombardero a 10.0 m de la cámara de persecución (la tapa); mínimo 25 m
FAIL formación: solo 0 compañeros visibles en la cámara de piloto; se esperan ≥3
FAIL puestos: la mira de artillero no está centrada en pantalla o se sale
FAIL artillero: la cámara no está en la torreta (a <12 m del avión)
FAIL puestos: la mira Norden no está centrada en pantalla o se sale
FAIL bombardero: la cámara no mira hacia abajo por la mira (dirección (0.0, -0.183497, -0.98302))
```
Causas y propuestas:
1. **La cámara queda dentro de un bombardero:** el puesto 5 de `formation_slots` (0, 15, 70) cae junto a la cámara de persecución (0, 14, 60). En **todas** las vistas se ven dos placas oscuras gigantes, que son la cola de ese avión. Opción: el jugador vuela en un puesto de ala (por ejemplo, el 1) con el líder y los demás delante y a los lados, o se reubican los puestos y la cámara para que haya ≥25 m libres y ≥3 compañeros en pantalla.
2. **Artillero:** cámara en la torreta superior, en un radio de 12 m del avión, orientada con `aim`; retícula centrada y sin salirse de la pantalla (ahora es un arco gigante en la esquina inferior derecha).
3. **Bombardero:** cámara bajo el morro mirando hacia abajo (dirección y < −0,7), con la retícula Norden centrada.
4. **Impacto (visual, no lo mide el test):** en la captura, la pantalla entera sale marrón porque un sprite de humo cubre la cámara. Limitar el tamaño o la distancia de los sprites respecto a la cámara de impacto.
