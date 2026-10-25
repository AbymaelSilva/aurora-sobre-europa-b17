**Revisión de game.gd, combat_main.gd y visuals/engines.gd (análisis estático, sin ejecución)**

**1. `combat_main.gd` / `_ready()`: falta `super._ready()`**
- **Caso:** `game._ready()` llama a `super._ready()`, que entra en `combat_main._ready()`, pero esta función no encadena hacia `mission_main._ready()`. En Godot 4 el padre no se invoca solo. Toda la inicialización de `mission_main` (HUD, vuelo, misión) se omite.
- **Solución:** añadir `super._ready()` como primera línea de `combat_main._ready()`.

**2. `game.gd` / `_physics_process`: la formación se posiciona dos veces**
- **Caso:** `combat_main` llama a `$Formation.follow(pos, yaw, pitch)` y después `game.gd` sobrescribe `left` y `right` usando solo el yaw. Al cabecear, los escoltas no siguen el pitch. Además, el offset `z=-35` los coloca 35 m *delante* del líder, porque la cámara usa `+60` como detrás.
- **Solución:** eliminar las dos líneas de `game.gd` y ajustar los offsets (`z` positivo) dentro de `Formation.follow`.

**3. `combat_main.gd` / `_physics_process`: HUD oculto pero se sigue construyendo, y `failure_reason` se pierde**
- **Caso:** `game.gd` oculta `$HUD.label`, pero `combat_main` sigue concatenando con `+=` en cada tick de física. Si `mission_main` no reinicia el texto, la cadena crece sin límite. Además, el overlay no recibe `failure_reason`: al derribar el avión, el jugador ve "FALLIDA" sin el motivo.
- **Solución:** añadir `"failure": failure_reason` al diccionario de `set_state` y omitir el `+=` cuando `$HUD.label.visible` sea falso.

**4. `game.gd` / `_ready`: precisión de profundidad y suelo gigante**
- **Caso:** con `far=18000` y el `near` por defecto (0.05), la relación near/far es de 360 000:1. Las vías y la estación, coplanares con el suelo, parpadearán (z-fighting) a media distancia. Además, el `PlaneMesh` de 100 km tiene 2 triángulos: si `farmland.gdshader` usa UV o `VERTEX`, el tileado queda estirado o con jitter.
- **Solución:** fijar `$Camera3D.near = 0.5`, elevar las vías unos centímetros y usar `world_position.xz` en el shader en lugar de UV.

**5. `visuals/engines.gd` / `_process`: las hélices ignoran pausa, daño y destrucción**
- **Caso:** con `paused=true`, con la misión en FALLIDA o con el motor por debajo de 85 % (humo visible), las cuatro hélices siguen girando a 31 rad/s en el mismo sentido. Esto contradice el humo y la velocidad reducida.
- **Solución:** crear `var spin_factor := 1.0` en `engines.gd` y asignarlo desde `combat_main` como `0.0 if paused or destroyed else damage.thrust_factor()`. Multiplicar `delta * 31 * spin_factor`.

**Nota menor:** el bucle `range(4, …)` sobre `$Scenery` depende del orden de los hijos. Si se reordena la escena, se ocultará la estación.

**Controles (verificación pendiente, no ejecutada)**
- [ ] Un `print` en `mission_main._ready()` aparece una vez tras corregir el punto 1.
- [ ] Cabecear ±20°: los escoltas mantienen la altura relativa y quedan detrás del líder.
- [ ] Derribo por flak: el overlay muestra el motivo; el monitor de memoria se mantiene estable durante 10 min.
- [ ] Cámara a 2–5 km de la estación: sin parpadeo en las vías.
- [ ] Pausa y motor por debajo de 85 %: las hélices se detienen o frenan.
- [ ] Esta revisión no valida jugabilidad completa; la captura RTX y los tests de geometría tampoco la validan.
