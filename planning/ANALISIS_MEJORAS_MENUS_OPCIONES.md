# Análisis y propuesta de mejoras — Menús y Opciones (Aurora sobre Europa / B-17)

Autor: Claude (análisis de código, sin ejecutar el juego). Alcance: `godot/B17`, enfocado en menús, pausa y opciones. No implica cambios de arte ni de misión.

## 1. Estado actual (evidencia de código)

1.1 No existe menú principal. `project.godot` arranca directo en `res://game.tscn` (`run/main_scene`); no hay `main_menu.tscn` ni pantalla de título, logo o "Pulsa para empezar".

1.2 El único menú del juego es la superposición de pausa, generada 100% por código en `ui/settings_menu.gd` (no es una `.tscn`), instanciada desde `game.gd:103-107` y mostrada al pausar (`set_pause`).

1.3 Ese menú de pausa mezcla en una sola pantalla sin categorías: Reanudar, perfil de control (cíclico), Reiniciar misión, Música (on/off), Voces (on/off). No hay separación entre "ajustes" y "acciones de partida".

1.4 Audio: solo interruptores binarios para música y voces (`music_enabled`, `voice_enabled` en `settings_menu.gd:17-18`); no hay control deslizante de volumen general, de efectos ni de motor/disparos, aunque el motor de audio sí mezcla por buses con `volume_db` fijos en `game.gd` (líneas 165-196).

1.5 Controles: 3 perfiles fijos (`TECLADO_RATON`, `XBOX`, `ROG_ALLY_X` en `core/input_profile.gd`) que solo se pueden ciclar con flechas; no hay remapeo individual de botones/teclas. Existen variables de sensibilidad (`pitch_sensitivity`, `turn_sensitivity`, `throttle_sensitivity` en `core/player_controls.gd:4-6`) pero están fijas en código a `1.0` y no se exponen en ningún menú.

1.6 Gráficos/rendimiento: cero opciones. `project.godot` fija resolución 1280x720, MSAA 3D y `forward_plus` sin exponer nada al jugador (ni pantalla completa, ni V-Sync, ni calidad).

1.7 Accesibilidad: no existe ninguna opción (sin modo daltonismo, sin tamaño de texto/subtítulos, sin opacidad de fondo de subtítulos, sin reducción de vibración/cámara). Los subtítulos están siempre activos y codificados (`tests/test_scene_audio.gd:20`: `spoken_language == "en-US"`, `subtitle_language == "es"`), sin selector de idioma.

1.8 Persistencia: `InputProfile` guarda solo el perfil de control en `user://b17_settings.cfg` (`core/input_profile.gd:5-23`). El resto de ajustes (música, voces, sensibilidad) no persiste entre sesiones: se reinician en cada partida.

1.9 Navegación por mando: el foco entre botones de pausa está cableado a mano con `has_focus()` en cadena (`settings_menu.gd:137-193`), frágil ante agregar/quitar opciones y sin indicación visual de "siguiente/anterior" más allá del foco del botón.

1.10 No hay confirmación para "Reiniciar misión" (acción destructiva de progreso de la partida en curso) ni pantalla de créditos/salir.

## 2. Estándares de la industria investigados

- **Game Accessibility Guidelines** (gameaccessibilityguidelines.com) y el resumen de IGDA-GASIG: los cuatro puntos más demandados por jugadores son remapeo de controles, tamaño de texto, modos de daltonismo y presentación de subtítulos (fuente/contraste/tamaño configurables). [gameaccessibilityguidelines.com/basic](https://gameaccessibilityguidelines.com/basic/) · [IGDA GASIG](https://igda-gasig.org/?p=3404)
- **Xbox Accessibility Guidelines (XAG)**: todos los caminos hacia accesibilidad deben ser accesibles desde el arranque; se recomienda ofrecer configurarla como primera pantalla; subtítulos y narración activados por defecto; reducir distracciones visuales por defecto. [devdocs.xbox.com/gaming/accessibility](https://devdocs.xbox.com/gaming/accessibility/xbox-accessibility-guidelines/112)
- **Investigación UX de settings (PlayStation / tesis Drexel 2023)**: el menú de opciones dejó de ser un contenedor simple de video/audio y ahora es un "directorio" que puede alterar la jugabilidad; su usabilidad debe diseñarse como una pantalla propia, no como un añadido del menú de pausa.
- **Taxonomía común de categorías** usada en la mayoría de juegos comerciales: Video/Gráficos, Audio, Controles, Jugabilidad, Accesibilidad, Idioma — cada una en su propia pestaña o sub-menú, no todo mezclado.

## 3. Propuesta de mejoras (numeración jerárquica)

### 1. Menú principal (nuevo, no existe hoy)
- 1.1 Crear `main_menu.tscn` como `run/main_scene`, con `game.tscn`/`mission.tscn` cargados solo al elegir "Jugar".
  - 1.1.1 Botón **Jugar** → inicia nueva misión.
  - 1.1.2 Botón **Continuar** → visible solo si existe partida/progreso guardado (ver 4.2).
  - 1.1.3 Botón **Opciones** → abre el menú de opciones (sección 2), accesible también desde pausa.
  - 1.1.4 Botón **Créditos** → pantalla con equipo/herramientas usadas.
  - 1.1.5 Botón **Salir** → con confirmación si hay partida en curso.
- 1.2 Pantalla de título con logo/nombre "Aurora sobre Europa" y versión/build visible (útil para QA de Agy).
- 1.3 Foco inicial automático en "Jugar" al entrar, navegable con teclado, mando y Steam Deck/ROG Ally sin mouse.

### 2. Menú de Opciones (rediseño en categorías, reemplaza el bloque plano actual)
- 2.1 **Audio**
  - 2.1.1 Deslizador de volumen general (bus Master), no solo on/off.
  - 2.1.2 Deslizador independiente: Música, Efectos (motor/disparos/bombas), Voces.
  - 2.1.3 Mantener los toggles actuales de Música/Voces como atajo rápido dentro de esta categoría, no como únicas opciones.
- 2.2 **Video / Gráficos**
  - 2.2.1 Selector de resolución (lista de resoluciones soportadas) y modo Ventana/Pantalla completa/Sin bordes.
  - 2.2.2 V-Sync on/off.
  - 2.2.3 Nivel de calidad (MSAA/sombras) con preset Bajo/Medio/Alto, pensando en el perfil ROG Ally X (batería) vs PC de escritorio.
- 2.3 **Controles**
  - 2.3.1 Mantener el selector de perfil (Teclado/Xbox/ROG Ally X) pero como una opción más dentro de esta categoría, no como todo el menú.
  - 2.3.2 Pantalla de remapeo individual por acción (piloto, disparar, soltar bomba, pausa, autopiloto) con detección de conflictos.
  - 2.3.3 Exponer `pitch_sensitivity`, `turn_sensitivity`, `throttle_sensitivity` (ya existen en `core/player_controls.gd`) como deslizadores 0.5x–2.0x.
  - 2.3.4 Opción de invertir eje de cabeceo (pitch invert), estándar en simuladores de vuelo.
- 2.4 **Jugabilidad**
  - 2.4.1 Dificultad (si aplica: precisión de flak/cazas, daño recibido) — hoy fija en `core/combat_config.gd`.
  - 2.4.2 Ayudas de vuelo on/off (ej. horizonte artificial asistido, auto-nivelado).
  - 2.4.3 Confirmaciones de acciones destructivas (ver 3.3).
- 2.5 **Accesibilidad**
  - 2.5.1 Modo daltonismo (protanopía/deuteranopía/tritanopía) para marcadores de navegación y HUD (`ui/navigation_marker.gd` ya usa color dorado fijo, candidato a revisar).
  - 2.5.2 Tamaño de texto/subtítulos y opacidad de fondo del subtítulo.
  - 2.5.3 Reducción de vibración del mando y de movimiento de cámara (motion sickness).
- 2.6 **Idioma**
  - 2.6.1 Selector de idioma de voz y de subtítulos, independientes entre sí (hoy fijos a `en-US` voz / `es` subtítulo en `tests/test_scene_audio.gd`).
  - 2.6.2 Selector de idioma de interfaz (textos de botones/menús).

### 3. Menú de Pausa (mejoras sobre el actual `settings_menu.gd`)
- 3.1 Separar "acciones de partida" (Reanudar, Reiniciar misión, Volver al menú principal, Salir) de "ajustes" (Audio/Video/Controles resumidos o un botón "Opciones completas" que abra el menú de la sección 2).
- 3.2 Mostrar el mismo panel de Opciones (sección 2) también desde pausa, para no duplicar lógica ni tener dos UIs distintas con las mismas variables.
- 3.3 Añadir diálogo de confirmación ("¿Seguro que quieres reiniciar la misión? Perderás el progreso actual") antes de ejecutar `restart_requested`.
- 3.4 Sustituir el cableado manual de foco (`has_focus()` en cadena) por un `FocusGroup`/orden de `focus_neighbor_*` declarado una vez, para que añadir/quitar botones no rompa la navegación.

### 4. Persistencia y guardado
- 4.1 Extender `InputProfile`/`ConfigFile` (o un `SettingsManager` nuevo) para guardar en `user://b17_settings.cfg` **todas** las opciones nuevas (volúmenes, resolución, sensibilidad, accesibilidad, idioma), no solo el perfil de control.
- 4.2 Si se añade "Continuar" en el menú principal (1.1.2), definir qué se guarda como progreso (misión actual, daño del avión) y en qué archivo (`user://` separado del de ajustes).

### 5. Navegación y UX general
- 5.1 Mismo esquema visual para menú principal, opciones y pausa (misma tipografía, mismo estilo de `PanelContainer`/`StyleBoxFlat`) para que no se vean como tres interfaces distintas.
- 5.2 Indicar en cada pantalla de opciones el atajo para volver atrás (`ui_cancel`/Esc/B) de forma visible, no solo funcional.
- 5.3 Mostrar en pantalla, junto a Controles, la lista de teclas/botones vigentes del perfil activo (ya existe parcialmente en `hint_label` de `settings_menu.gd`); extenderlo también al menú principal/opciones para quien nunca llegó a pausar.

## 4. Tabla resumen — USUARIO | OPCIONES | MENÚ

| USUARIO (a quién beneficia) | OPCIONES (qué se ofrece) | MENÚ (dónde vive) |
|---|---|---|
| Jugador nuevo que abre el juego | Jugar / Continuar / Opciones / Créditos / Salir (1.1) | Menú principal |
| Jugador en PC de escritorio | Resolución, pantalla completa, V-Sync, calidad gráfica (2.2) | Opciones → Video/Gráficos |
| Jugador en ROG Ally X / mando | Perfil de control, remapeo individual, sensibilidad, invertir pitch (2.3) | Opciones → Controles |
| Jugador con baja audición o entorno ruidoso | Volumen general + música/efectos/voces independientes (2.1) | Opciones → Audio |
| Jugador con daltonismo | Modo daltonismo para HUD/marcadores (2.5.1) | Opciones → Accesibilidad |
| Jugador con baja visión o pantalla pequeña (modo portátil) | Tamaño y opacidad de subtítulos/texto (2.5.2) | Opciones → Accesibilidad |
| Jugador sensible a mareo por movimiento | Reducción de vibración/cámara (2.5.3) | Opciones → Accesibilidad |
| Jugador hispanohablante o angloparlante | Idioma de voz, subtítulo e interfaz por separado (2.6) | Opciones → Idioma |
| Jugador que busca un reto distinto | Nivel de dificultad, ayudas de vuelo (2.4) | Opciones → Jugabilidad |
| Jugador a mitad de misión que pausa | Reanudar, Reiniciar misión (con confirmación), Volver al menú, acceso rápido a Opciones (3.1–3.3) | Menú de pausa |
| Cualquier jugador que quiere retomar | Continuar desde progreso guardado (4.2) | Menú principal |
| QA / Agy | Versión/build visible en pantalla de título (1.2) | Menú principal |

## 5. Siguiente paso sugerido

No se tocó código en este análisis. Si se aprueba, el orden de implementación de menor a mayor riesgo sería: 4.1 (extender persistencia) → 2.1/2.3.3 (sliders de audio y sensibilidad, reutilizan variables ya existentes) → 2.2 (video) → 1 (menú principal) → 2.5/2.6 (accesibilidad/idioma) → 3.3/3.4 (confirmación y foco robusto).

### Fuentes consultadas
- [Game Accessibility Guidelines — Basic](https://gameaccessibilityguidelines.com/basic/)
- [IGDA Game Accessibility SIG](https://igda-gasig.org/?p=3404)
- [Xbox Accessibility Guidelines](https://devdocs.xbox.com/gaming/accessibility/xbox-accessibility-guidelines/112)
- [20 reasons your pause menu is sabotaging your game](https://www.wayline.io/blog/20-reasons-your-pause-menu-is-sabotaging-your-game)
- [UI/UX en juegos: menús, HUDs y sistemas de feedback](https://respawn.outlookindia.com/gaming/gaming-guides/ui-and-ux-in-games-building-menus-huds-and-feedback-systems)
