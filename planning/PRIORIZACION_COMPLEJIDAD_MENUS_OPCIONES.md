# Priorización por complejidad — Menús y Opciones

Reordena las mejoras de `ANALISIS_MEJORAS_MENUS_OPCIONES.md` por dificultad técnica/riesgo, para decidir qué abordar primero. Numeración: Complejidad.Área.Cambio.Detalle (ej. `1.1.1.1`).

## Estado de implementación (2026-10-24)

**BAJO y MEDIO: implementados completos.** **ALTO: implementado salvo 3.3.1.** Código en `core/settings_manager.gd`, `core/input_actions.gd`, `core/accessibility_palette.gd`, `core/save_game.gd`, `core/i18n.gd`, `ui/main_menu.gd`, `ui/options_menu.gd`, `ui/settings_menu.gd` (reescrito), más ajustes puntuales en `game.gd`, `core/player_controls.gd`, `core/damage.gd`, `core/simulation.gd`, `core/combat_manager.gd` y `ui/mission_overlay.gd`. Pruebas automatizadas nuevas en `tests/test_main_menu_smoke.gd`, `tests/test_options_integration.gd`, `tests/test_save_game.gd`, `tests/test_input_actions.gd`; toda la suite existente sigue en verde (las fallas preexistentes `test_claude_batch`, `test_local_bombing_usability`, `test_qwen_assets`, `test_manual_mission_claude` se confirmaron ajenas a este trabajo, vía `git stash`).

Único pendiente real: **3.3.1 (voz en más de un idioma)** no se hizo — no es código, requiere locución grabada que no existe en el proyecto. El selector de idioma de interfaz (3.3.2) sí funciona, pero solo traduce el menú principal y el panel de Opciones (lo que se escribió en esta tanda); el HUD de misión y los subtítulos de las voces existentes quedan fuera de ese alcance. Nivel SUPERIOR no se tocó, como estaba previsto.

## 1. BAJO — reutiliza código/variables ya existentes, sin pantallas nuevas

- 1.1 Audio
  - 1.1.1 Sliders de volumen (reemplazan los toggles binarios)
    - 1.1.1.1 Conectar sliders a los buses Master/Música/Efectos/Voz ya mezclados en `game.gd`
    - 1.1.1.2 Guardar el valor en el `ConfigFile` de ajustes
- 1.2 Controles
  - 1.2.1 Exponer la sensibilidad de vuelo
    - 1.2.1.1 Añadir 3 sliders (cabeceo/giro/aceleración) en la categoría Controles
    - 1.2.1.2 Conectarlos a `pitch_sensitivity`/`turn_sensitivity`/`throttle_sensitivity`, ya declaradas en `core/player_controls.gd:4-6`
- 1.3 Jugabilidad
  - 1.3.1 Confirmación antes de "Reiniciar misión"
    - 1.3.1.1 Diálogo "¿Seguro? Perderás el progreso actual" antes de emitir `restart_requested`
- 1.4 Menú de pausa
  - 1.4.1 Separar visualmente acciones de partida (Reanudar/Reiniciar/Salir) de ajustes (Audio/Controles)
    - 1.4.1.1 Dos bloques dentro del mismo panel, sin nueva pantalla
- 1.5 Navegación
  - 1.5.1 Indicador visible de "volver" (Esc / botón B) en cada pantalla
  - 1.5.2 Reutilizar el `hint_label` de controles fuera de la pausa, donde haga falta
- 1.6 Jugabilidad — mecánicas ya implementadas que conviene reflejar en Opciones/menú (sin tocar su lógica ni su balance)
  - 1.6.1 Gestión de motores (puesto Piloto, tecla `1`): indicadores `[M1][M2][M3][M4]` con color dinámico; `F1`–`F4` embandera hélices, `Ctrl+F1`–`Ctrl+F4` dispara extintores
    - 1.6.1.1 Incluir este atajo en el `hint_label` de pausa y, al construirse, en el menú principal (reutiliza 1.5.2; es solo texto, la mecánica ya existe)
  - 1.6.2 Ciclo de 3 torretas (puesto Artillero, tecla `2`): `Q` (o `2` repetida) alterna Dorsal (360°) / Cola (180°) / Bola ventral; el HUD ya muestra `ARTILLERO [DORSAL/COLA/VENTRAL]`
    - 1.6.2.1 Mencionar el ciclo de torretas en la categoría Controles de Opciones (2.6) como recordatorio de texto; no requiere remapeo nuevo (eso sigue en 3.1.1, ALTO)
  - 1.6.3 Solicitud de cobertura de escoltas P-51D (tecla `E`): aviso «P-51 COBERTURA CERCANA [20s]» y los cazas de escolta abaten interceptores con fuego real
    - 1.6.3.1 Mecánica autosuficiente vía HUD; no necesita entrada en Opciones, solo documentarse en el manual de controles del jugador
  - 1.6.4 Flak: las explosiones cercanas agitan y descalibran momentáneamente el altímetro y la brújula del panel de navegación
    - 1.6.4.1 Vincular con 2.5.2 (MEDIO): la opción "reducir vibración de cámara" debe atenuar también este jitter de instrumentos, no solo el shake de cámara

**Por qué es bajo:** no crea escenas nuevas, no toca sistemas de guardado ni arte; son conexiones de UI a variables/buses que ya existen en el código.

## 2. MEDIO — requiere pantallas o estructura nueva, con APIs estándar de Godot

- 2.1 Menú principal (no existe hoy)
  - 2.1.1 Crear `main_menu.tscn` con Jugar / Opciones / Créditos / Salir
    - 2.1.1.1 Enrutar "Jugar" hacia `game.tscn` (hoy es la escena de arranque directa)
    - 2.1.1.2 Pantalla de título con logo y versión/build visible
  - 2.1.2 Navegación completa por teclado y mando
    - 2.1.2.1 Foco inicial automático en "Jugar"
    - 2.1.2.2 Reemplazar el cableado manual de foco (`has_focus()` en cadena) por `focus_neighbor_*` declarado
- 2.2 Video / Gráficos (hoy no existe ninguna opción)
  - 2.2.1 Resolución y modo de pantalla vía `DisplayServer`
    - 2.2.1.1 Selector de resolución
    - 2.2.1.2 Ventana / Pantalla completa / Sin bordes
  - 2.2.2 V-Sync y calidad
    - 2.2.2.1 Interruptor V-Sync
    - 2.2.2.2 Preset Bajo/Medio/Alto (MSAA/sombras), pensando en PC de escritorio vs ROG Ally X
- 2.3 Controles
  - 2.3.1 Invertir eje de cabeceo (pitch invert)
- 2.4 Jugabilidad
  - 2.4.1 Dificultad simple: exponer como variables los multiplicadores ya usados en `core/combat_config.gd`
  - 2.4.2 Ayudas de vuelo on/off (ej. auto-nivelado)
- 2.5 Accesibilidad (parcial)
  - 2.5.1 Tamaño y opacidad de fondo de subtítulos
  - 2.5.2 Reducción de vibración del mando, de movimiento de cámara y del jitter de altímetro/brújula por flak (ver 1.6.4)
- 2.6 Estructura del menú de Opciones
  - 2.6.1 Reorganizar el bloque plano actual (`settings_menu.gd`) en pestañas/categorías
  - 2.6.2 Reutilizar el mismo panel de Opciones desde pausa y desde el menú principal (evitar dos UIs con la misma lógica)
- 2.7 Persistencia
  - 2.7.1 Extender el `ConfigFile` de ajustes para guardar todas las opciones nuevas de esta sección (hoy solo guarda el perfil de control)

**Por qué es medio:** usa APIs directas de Godot (`DisplayServer`, `AudioServer`, `focus_neighbor`), pero exige escenas/paneles nuevos, refactor de la pausa actual y pruebas en más de una plataforma (PC/ROG Ally).

## 3. ALTO — sistemas nuevos, research o dependencias de producción (arte/audio/traducción)

- 3.1 Controles
  - 3.1.1 Remapeo individual de botones/teclas
    - 3.1.1.1 UI de captura de input por acción (piloto, disparar, soltar bomba, pausa, autopiloto)
    - 3.1.1.2 Detección de conflictos entre acciones y entre los 3 perfiles existentes
- 3.2 Accesibilidad
  - 3.2.1 Modos de daltonismo (protanopía/deuteranopía/tritanopía)
    - 3.2.1.1 Paleta o shader alternativo para HUD y marcadores de navegación (hoy color dorado fijo en `ui/navigation_marker.gd`)
    - 3.2.1.2 Revisión de arte para que el cambio de paleta no rompa la legibilidad en combate
- 3.3 Idioma
  - 3.3.1 Selector de idioma de voz y subtítulos
    - 3.3.1.1 Requiere locución grabada en más de un idioma (hoy fijo a voz en-US / subtítulo es)
  - 3.3.2 Selector de idioma de interfaz
    - 3.3.2.1 Sistema de traducción (`TranslationServer`) sobre todos los textos hoy escritos directamente en el código
- 3.4 Progreso de partida
  - 3.4.1 Botón "Continuar" con guardado real (depende de 2.1.1)
    - 3.4.1.1 Diseñar qué se guarda (misión, daño del avión, posición) y el formato/versión del archivo
    - 3.4.1.2 Riesgo de romper la simulación si se carga a mitad de misión; necesita pruebas de Agy antes de liberar

**Por qué es alto:** cada ítem depende de un sistema que no existe (captura de input dinámica, pipeline de shaders/arte, locución en otro idioma, guardado de progreso), con riesgo de romper otras partes ya probadas (combate, audio, navegación).

## 4. SUPERIOR — excede el alcance de "menús y opciones"; requiere decisión de negocio/producción, no solo ingeniería

- 4.1 Progreso / campaña
  - 4.1.1 Campaña con múltiples misiones y progreso persistente entre partidas (más allá de "Continuar" una misión suelta, ver 3.4.1)
    - 4.1.1.1 Exige rediseñar el alcance del juego (hoy es una sola misión repetible), no solo su menú: estructura de carrera de piloto, múltiples mapas/objetivos, slots de guardado
- 4.2 Certificación de plataforma
  - 4.2.1 Checklist formal de certificación (Xbox TCR / PlayStation TRC) sobre accesibilidad y opciones
    - 4.2.1.1 Auditoría externa de cumplimiento; solo aplica si el juego se publica en una tienda de consola, no para el uso personal actual
- 4.3 Multijugador / red
  - 4.3.1 Opciones de red (cooperativo, sincronizar ajustes entre jugadores)
    - 4.3.1.1 No existe capa de networking en el proyecto; sería una base de código nueva, no una extensión del menú de Opciones
- 4.4 Localización profesional completa
  - 4.4.1 Doblaje y subtítulos en 5+ idiomas con control de calidad por idioma
    - 4.4.1.1 Requiere presupuesto de producción externo (actores de voz, estudio de grabación, traducción certificada); el selector de idioma (3.3) ya cubre el lado de código, esto es el lado de contenido

**Por qué es superior:** ya no es "más difícil de programar" como en ALTO — son decisiones que cambian el alcance del proyecto (de una misión a una campaña), dependen de terceros (certificadoras, estudios de doblaje) o de infraestructura que el proyecto no tiene (red). No se recomienda abordar nada de esta sección sin una decisión explícita del usuario sobre presupuesto y alcance.

## 5. Resumen para decidir

| Nivel | Nº de cambios | Depende de código nuevo | Depende de algo fuera del código (arte/audio/traducción/negocio) |
|---|---|---|---|
| BAJO | 6 | No | No |
| MEDIO | 11 | Sí (escenas/paneles) | No |
| ALTO | 7 | Sí (sistemas nuevos) | Sí (arte, locución, traducción) |
| SUPERIOR | 4 | Sí (si se decide hacer) | Sí (presupuesto, certificación, alcance del proyecto) |

Orden sugerido si se quiere ver avance rápido sin arriesgar nada: **BAJO completo → MEDIO (2.1 y 2.7 primero, por ser la base de todo lo demás) → ALTO solo si el presupuesto de arte/audio lo permite → SUPERIOR solo si decides cambiar el alcance del proyecto** (ver `planning/PRESUPUESTO_ARTE.md`).
