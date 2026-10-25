# Directiva Técnica — Lote 7: Gran Formación de 30 B-17 (Armada x5) y Clima de Invierno Europeo

> [!IMPORTANT]
> **ORDEN DE EJECUCIÓN AUTÓNOMA DIRECTA:**
> ```bash
> agy --dangerously-skip-permissions --mode auto -p "$(cat planning/orquestacion/PROMPT_FORMACION_30_Y_CLIMA_INVIERNO_LOTE7.md)"
> ```

> [!NOTE]
> **Estándar Permanente para Documentos MD:**
> Conforme a la regla del supervisor, este documento incluye la instrucción literal de ejecución autónoma `agy --dangerously-skip-permissions --mode auto -p ...` para permitir su resolución desatendida.

---

## 1. Alcance y Objetivos

El objetivo de esta directiva técnica es elevar la inmersión histórica y escala de «Aurora sobre Europa»:
1. **Gran Formación de B-17 (Multiplicar x5 la escuadrilla):**
   - Pasar de 6 bombarderos (1 líder + 5 compañeros) a **30 bombarderos B-17 Flying Fortress** (1 líder + 29 compañeros).
   - Estructuración táctica histórica basada en la doctrina de *Combat Box* de la 8ª Fuerza Aérea (Escuadrón Líder, Escuadrón Alto / High Squadron y Escuadrón Bajo / Low Squadron escalonados en altitud y azimut para defensa mutua).
2. **Clima de Invierno Europeo (European Winter 1944):**
   - Terreno con manto de nieve y escarcha en campos de cultivo y río helado.
   - Iluminación solar fría de ángulo bajo (sol de invierno a baja elevación).
   - Cielo invernal con bruma gélida, niebla atmosférica pálida y reflejo de albedo de nieve.

---

## 2. Componentes de Código Afectados y Parámetros

### A. Formación Táctica de 30 Bombarderos (x5)

#### 1. `godot/B17/core/formation_slots.gd`
- **Componente:** Definición geométrica de posiciones relativas de la formación.
- **Modificación:**
  - Ampliar el array `offsets: Array[Vector3]` de 6 a 30 posiciones:
    - **Slot 0:** `Vector3(0, 0, 0)` (Líder del Grupo / Aurora Uno).
    - **Slots 1 a 9 (Escuadrón Líder central):** Dispersión en cuña y escalón con separación segura (offsets entre -90 m y +90 m en X, -20 m y +20 m en Y, +30 m a +120 m en Z).
    - **Slots 10 a 19 (High Squadron - Escuadrón Alto):** Escalonado hacia estribor y cota superior (`X: +110 a +220 m`, `Y: +70 a +160 m`, `Z: +50 a +180 m`).
    - **Slots 20 a 29 (Low Squadron - Escuadrón Bajo):** Escalonado hacia babor y cota inferior (`X: -110 a -220 m`, `Y: -70 a -160 m`, `Z: +50 a +180 m`).
  - Cada ranura garantiza una separación mínima entre cajas delimitadoras (AABB) superior a 15 m para evitar colisiones visuales o solapamientos.

#### 2. `godot/B17/formation.gd`
- **Componente:** Nodo 3D responsable de instanciar y sincronizar los compañeros de vuelo.
- **Modificación:**
  - En `_ready()`: Cambiar el bucle de instanciación de 5 a 29 compañeros (`for i in range(29):`), cada uno equipado con `aircraft.gd`, `bomber_details.gd` y `markings.gd`.
  - Mantener referencias heredadas `left = wingmen[0]` y `right = wingmen[1]`.
  - En `follow(leader_position, yaw, pitch)`: Iterar sobre los 29 wingmen actualizando `world_position` con la ranura `i + 1` y rotación homogénea.

#### 3. `godot/B17/game.gd`
- **Componente:** Escena principal del juego y lógica de presentación.
- **Modificación:**
  - Asegurar que la cámara de persecución mantenga la visibilidad de la gran armada sin obstrucciones.
  - El audio ambiente de motores de formación (`formation_drone_loop`) mantiene volumen equilibrado (-10 dB) para enriquecer el rugido coral de los 120 motores Wright Cyclone sin saturación.

---

### B. Clima de Invierno Europeo

#### 1. Shader de Terreno (`godot/B17/world/farmland.gdshader`)
- **Componente:** Renderizado de la superficie terrestre en mosaico.
- **Modificación:**
  - Incorporar modulación de nieve y escarcha sobre la textura base `farmland_texture`:
    - Detección de parcelas y campos nevados mediante ruido procedural de baja frecuencia.
    - Mezcla de color de nieve europea (`vec3(0.92, 0.94, 0.97)`) sobre los tonos terrosos y verdes apagados de invierno.
    - El río se transforma en río invernal congelado (`mix` hacia tonos hielo `vec3(0.68, 0.78, 0.84)` con rugosidad reflectante `ROUGHNESS = 0.25`).

#### 2. Atmósfera y Entorno (`godot/B17/world/atmosphere.gd`)
- **Componente:** `WorldEnvironment`, cielo procedural y niebla volumétrica.
- **Modificación:**
  - **Cielo invernal nuboso/frío:**
    - `sky_top_color = Color(0.28, 0.38, 0.48)` (azul gélido invernal atenuado).
    - `sky_horizon_color = Color(0.70, 0.76, 0.82)` (horizonte brumoso pálido).
    - `ground_bottom_color = Color(0.72, 0.75, 0.78)` (reflejo de la luz ambiente sobre la nieve).
    - `ground_horizon_color = Color(0.70, 0.76, 0.82)`.
  - **Niebla atmosférica:**
    - `fog_enabled = true`
    - `fog_light_color = Color(0.74, 0.80, 0.86)` (bruma helada).
    - `fog_density = 0.00010` (mayor sensación de lejanía invernal sin ocultar los compañeros).
  - **Ajustes tonales:**
    - `tonemap_exposure = 1.05`
    - `adjustment_saturation = 0.88` (ligera desaturación característica del invierno europeo de 1944).

#### 3. Luz Solar en `godot/B17/game.gd`
- **Componente:** Nodo `$Sun` (DirectionalLight3D).
- **Modificación:**
  - Ángulo solar bajo de invierno: `rotation_degrees = Vector3(-18.0, -30.0, 0.0)` (sol bajo que proyecta sombras alargadas sobre la formación y el terreno).
  - Color de luz fría: `light_color = Color(0.94, 0.96, 1.0)`.
  - Energía ajustada a `1.25` con rebote ambiental compensado por la nieve.

---

### C. Actualización de Pruebas y Contratos

1. **`tests/test_formation_six.gd`**:
   - Actualizar nombre conceptual y aserciones: validar que `form.wingmen.size() >= 29` (total 30 con líder) y que todos posean nodo `Engines` y rotores activos.
2. **`tests/test_imported_aircraft_integration.gd`**:
   - Actualizar la comprobación de bombarderos totales para aceptar la formación ampliada de 30 bombarderos.
3. **`tests/test_claude_review.gd`**:
   - La prueba ya exige `bombers >= 6`, por lo que 30 bombarderos superarán la aserción directamente.

---

## 3. Criterios de Aceptación y Verificación

1. **Determinismo y Rendimiento:**
   - La simulación debe mantener 60 FPS estables en la NVIDIA GeForce RTX 2060 SUPER con los 30 B-17 (120 rotores animados) y los 4 P-51D de escolta.
2. **Suite de Pruebas:**
   - Todas las pruebas de la suite (25/25) deben arrojar resultado **PASS**.
3. **Validación GPU:**
   - Ejecutar captura visual GPU con `capture_mission_claude.gd` y verificar la estética de nieve, la iluminación baja de invierno y la escala masiva de la armada.
4. **Registro:**
   - Registrar la entrega en `supervisor.log`, actualizar `TABLERO.md`, `AGY_AVANCE.md` y `AGY_ESTADO.json`.
