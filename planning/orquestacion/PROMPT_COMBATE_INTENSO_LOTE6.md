# Directiva Técnica — Lote 6: Combate Intenso, Flak Histórico Denso y Escuadrillas Ampliadas

> [!IMPORTANT]
> **ORDEN DE EJECUCIÓN AUTÓNOMA DIRECTA:**
> ```bash
> agy --dangerously-skip-permissions --mode auto -p "$(cat planning/orquestacion/PROMPT_COMBATE_INTENSO_LOTE6.md)"
> ```

> [!NOTE]
> **Estándar Permanente para Documentos MD:**
> Por directiva expresa del usuario, este documento y **todos los subsecuentes generados** para especificaciones, lotes, encargos o pruebas técnicas DEBEN incorporar en su encabezado la instrucción literal de ejecución autónoma:
> `agy --dangerously-skip-permissions --mode auto -p "$(cat <ruta_al_archivo>.md)"`

## 1. Contexto y Objetivos
El usuario ha solicitado calibrar el combate para mayor fidelidad histórica e intensidad:
1. **Flak +60% frecuencia**: Fuego antiaéreo significativamente más continuo y tupido.
2. **Flak al 20% de escala visual**: Explosiones compactas y contenidas (humo negro concentrado de 10-15 m reales en vez de nubes desproporcionadas de cientos de metros).
3. **Más aviones enemigos**: Aumentar las oleadas de interceptores alemanes (Bf 109G y Fw 190A) de 2 a 4 por oleada (8 cazas en combate).
4. **Más aviones aliados**: Incorporar cazas de escolta aliados P-51D Mustang (`aircraft/models/p51d.glb`) acompañando la formación sin alterar el contrato de los 6 B-17 de la escuadrilla base.

---

## 2. Parámetros Técnicos Exactos

### A. Antiaérea (Flak)
- **`godot/B17/flak_model.gd`**:
  - `interval`: Reducir de `1.2` a `0.75` s (frecuencia aumenta de 0.833 a 1.333 ráfagas/s, incremento exacto del +60.0%).
- **`godot/B17/visuals/flak_burst.gd`**:
  - `pixel_size`: Reducir de `0.08` a `0.016` (20% del tamaño del sprite base).
  - Offset de dispersión de sprites: De `* 1.5` a `* 0.30` para mantener el grupo de partículas apretado.
  - Escala en `trigger()`: De `Vector3.ONE * 2.0` a `Vector3.ONE * 0.4`.
  - Expansión en `advance()`: De `2.0 + age * 8.0` a `0.4 + age * 1.6` (máximo de 6.8 m en vez de 34 m).
- **`godot/B17/game.gd`**:
  - Ampliar `flak_pool` de 8 a 16 instancias para soportar el mayor caudal de detonaciones simultáneas sin reciclar prematuramente los puffs que se desvanecen.

### B. Cazas Enemigos (Luftwaffe)
- **`godot/B17/core/combat_manager.gd`**:
  - Ampliar `spawn_wave(1)` y `spawn_wave(2)` a 4 cazas cada una (2 Bf 109G y 2 Fw 190A por oleada) con posiciones de entrada escalonadas (frontal alta, lateral y cola).
- **`godot/B17/game.gd`**:
  - Ampliar el bucle de creación de `fighter_visuals` de 4 a 8 nodos para mapear 1:1 los datos de simulación.

### C. Aviones Aliados (Escolta P-51D «Little Friends»)
- **`godot/B17/visuals/escort.gd`** (o integración directa en `game.gd`):
  - Instanciar 2 o 4 P-51D usando el modelo ya existente `res://assets/aircraft/models/p51d.glb` y `p51d__albedo.png`.
  - Posicionarlos en patrulla de cobertura alta (ej. +150 m sobre la escuadrilla de B-17, laterales ±120 m).
  - Preserva intacto `Formation.wingmen` (5 compañeros) para no romper las pruebas `test_formation_six.gd` ni `test_imported_aircraft_integration.gd`.

---

## 3. Protocolo de Ejecución y Validación
1. Realizar parches limpios y precisos en los archivos correspondientes.
2. Ejecutar la suite de regresión completa de 24 pruebas:
   `/home/test-bench/Documents/B17-project/tools/godot --headless --path /home/test-bench/Documents/B17-project/godot/B17 --script res://tests/<test>.gd`
3. Ejecutar captura GPU para verificar la escala visual de las explosiones de flak y la formación ampliada:
   `/home/test-bench/Documents/B17-project/tools/godot --path godot/B17 --resolution 1280x720 --script res://tests/capture_mission_claude.gd -- /home/test-bench/Documents/B17-project/logs/revision_supervisor/<nueva_carpeta>`
4. Actualizar `supervisor.log`, `TABLERO.md`, `AGY_AVANCE.md` y `AGY_ESTADO.json`.
