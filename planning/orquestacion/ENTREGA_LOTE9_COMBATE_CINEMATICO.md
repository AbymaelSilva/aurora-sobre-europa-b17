# Entrega Lote 9 — Combate aéreo, Europa 1945

## Resultado y continuidad

Integración iniciada después de comprobar `logs/dialogue_music/TERMINADO_Y_JUEGO_ABIERTO.json` con `complete: true`; no se creó ni modificó esa señal. Se cerró únicamente el juego anterior PID 1577820. Preflight y respaldo previo: `logs/lote9/preflight.json`, `logs/lote9/backup/`. Se inspeccionaron procesos activos: los otros agentes interactivos estaban fuera del directorio del proyecto, sin hijos escritores de cámara/juego observados. No se cerraron agentes ni aplicaciones ajenas.

Baseline confirmado: 30 interceptores, 16 P-51D, 300 B-17 (jugador, cinco compañeros detallados y 294 instancias MultiMesh). Se conserva esta formación, cámara orbital/observación, 100 nubes, niebla, flak, voces en inglés estadounidense/subtítulos españoles, música y banco de efectos. No hay nuevos recursos de audio, generación de audio ni cambios en sus scripts/fuentes. No se publicaron ni modificaron releases.

## Valores finales

- `core/combat_config.gd`: 48 enemigos, 16 frontales, 16 laterales (8 por flanco), 16 de cola; grupos de cuatro; semilla 1945; alternancia reproducible 24 Bf109G/24 Fw190A. Simulación y pool visual comparten la constante; el otro `range(1, 30)` de game.gd corresponde a bombas, no a cazas.
- Grupos escalonados 1,4 s, ciclo continuo de 50 s; aproximación, ventana nominal de 1,7 s, cruce/separación y retorno. Máximo ocho atacantes efectivos, condicionado además por distancia de 650 m y sector frontal del caza. Ráfaga lógica cada 0,5 s con daño de 0,02: el número total de modelos no multiplica voces ni daño simultáneo.
- Óvalos continuos relativos al bombardero, sin reasignar posiciones a la cámara ni saltos al cambiar de fase. Actitud tangente a la velocidad y alabeo suavizado limitado a ±0,65 rad. Velocidades muestreadas en vuelo recto a 85 m/s: 72,07–242,09 m/s; el extremo superior corresponde al tramo rápido de retorno/picado, no a una afirmación de fidelidad aerodinámica completa.
- Mínimos de los pases por avión dentro del intervalo solicitado de 120–500 m según sus corredores. Muestreo continuo de dos ciclos: 134,16 m mínimo al jugador, 18,38 m entre interceptores y 68,11 m a los 300 bombarderos. Las pruebas usan 48 vivos y paso de 0,05 s, no esconden derribados para mejorar separaciones.
- Trazadoras: pool 48, vida 0,28 s, segmentos de 3 m, sección base 0,20 m ajustada por distancia para lectura aproximada de 1–3 px a 720p; una por ráfaga representada de cuatro disparos. Métricas `emitted`, `dropped`, `peak_active`; sin sonido por trazadora. Destellos: pool 24, 45 ms, sin luces dinámicas; ocultos durante pausa.
- Los GLB inspeccionados no traen sockets de arma identificados. `visuals/combat_mounts.gd` define puntos locales fuera del centro: coincide con montajes documentados en bomber_details para torretas y con hardpoints de morro/ala en los cazas. La torreta elegida depende del sector/altura del blanco; no se añadieron modelos completos ni cañones duplicados.
- Daño <45/60 activa humo localizado en motor, reutilizando engine_smoke_trail con 12 partículas por caza. Daño letal conserva velocidad previa y aplica descenso con aceleración de 3 m/s² y alabeo lento; sin explosión terrestre por derribo. `combat.damage_events` registra índice, causa, salud y efecto (defensa automática, M2 manual y humo). Los campos anteriores de daños y bajas se conservan.
- Escoltas: un elemento de cuatro entra por sector; el anterior vuelve a velocidad relativa limitada a 65 m/s, excursión máxima 340 m. Offsets individuales mantienen separación dentro del elemento. El fuego de P-51 es visual de cobertura, sin añadir daño inevitable o mutar la simulación desde presentación. La actitud sigue su desplazamiento; las otras escoltas mantienen cobertura o regresan. Los cinco wingmen siguen sus contratos originales.
- Pausa detiene avance, rotores, emisión y visibilidad de ráfagas; reinicio limpia trazadoras, destellos, daño visual, blancos y oleada sin recrear los modelos ni perder perfil de mando. Cambiar de puesto conserva la misma IA/oleada.

## Archivos y revisión

Modificados: core/combat_manager.gd, core/fighter_ai.gd, core/player_controls.gd, game.gd, visuals/fighter.gd, visuals/escort.gd y visuals/tracer_pool.gd. Ajustes explícitos de contrato en tests/test_combat_manager.gd, tests/test_imported_aircraft_integration.gd y tests/test_release_acceptance.gd: 30→48; la aceptación espera daño además de una baja antes de cortar, puesto que los grupos ya no disparan todos al aparecer.

Nuevos: core/combat_config.gd, visuals/combat_mounts.gd, tests/test_lote9.gd, tests/test_lote9_scene.gd, tests/verify_lote9_gpu.gd y tests/capture_lote9.gd. Rutas anteriores relativas a godot/B17. Cambios y hashes revisables en logs/lote9/changes.diff y changed_files.json.

## Validación real

28 pruebas existentes/de integración PASS y prueba lógica Lote 9 PASS: logs individuales y regression.json, lote9_test.log y simulation_metrics.json. Cubren modelos importados, formación, cámara orbital, observación, controles/perfiles, misión completa a 30/60/120 Hz, bombardeo manual sintético, daño/determinismo, oleada, pausa/reset, HUD, nubes, flak, M2/banco de sonidos y director de voces/subtítulos/música. La prueba de escena confirma asignación visual 1:1 de 48, conservación de IDs de modelos al reiniciar y continuidad al cambiar de puesto. El pool rechaza 52 de 100 solicitudes simultáneas y expira las 48 aceptadas.

Supervivencia sin invulnerabilidad: semillas 1945, 42 y 871, 180 s, automático y manual con entradas neutras: casco 80,7%, 48 bajas y avión vivo. La misión completa a 60 Hz termina aproximadamente en 775,23 s con casco 62,6%; el piloto manual sintético completa objetivo con suelta manual (log test_manual_mission_claude). Esto no es una valoración humana de dificultad ni una prueba de mando físico.

GPU final: NVIDIA GeForce RTX 2060 SUPER, viewport real (1280.0, 720.0), 60.006 s, 3599 frames, **59.98 FPS**, mediana **16.640 ms**, p95 **16.888 ms**. Resultado próximo al objetivo de 60 FPS bajo sincronización de pantalla; no se redujeron los 48 enemigos. Logs: gpu.log y gpu_metrics.json. Fixture invulnerable únicamente para mantener carga: 48 enemigos vivos y 48 visuales todo el minuto, 16 escoltas, 300 bombarderos (70 modelos detallados totales +294 MultiMesh), 100 nubes y flak 78–89 de un pool 128. Máximos: 12 trazadoras de 48, 9 voces AudioStreamPlayer, 2853 objetos renderizados, 4 escoltas en elemento activo, ocho atacantes efectivos. Música combat, 7 inicios de diálogo; audio de flak acotado. El fixture mide presentación/rendimiento, no supervivencia.

Capturas reales 1280×720: frontal.png, lateral.png, cola.png, escolta_combate.png, caza_danado.png, orbital.png y carga_combinada.png bajo logs/lote9. captures.json documenta perfil/distancia y cámara de prueba. Son imágenes del juego renderizado con posiciones de pases deterministas; el daño de la captura dedicada se establece explícitamente a 24/60 para mostrar humo. Las cámaras cercanas de esa fixture no existen como cinemática forzada en el juego. Se revisaron visualmente formación, modelos, humo, leyenda de cámara y subtítulos.

## Audio protegido

Los 42 WAV sustituidos coinciden con first_build_hashes.json: sfx42_audit.json. Los cinco M2 y todos los scripts/fuentes de immutable_baseline.json coinciden byte por byte: protected_audio_audit.json.

| WAV M2 | SHA-256 |
|---|---|
| gun_m2_burst.wav | `37fca5948804d35fb2f5eb2bb6a4aa7cd20603f3d797a7fd8e943d12b4616b7a` |
| gun_m2_shot_01.wav | `faba8b76b8af8dcc2b4775b7337e380fee961f007bceff4b44bd3d98a785fabb` |
| gun_m2_shot_03.wav | `c08ddbe8f27e2c1d288b2ff367f506f4e1bfcada1d97babaf22294d60b8decf8` |
| gun_m2_shot_02.wav | `3b3eca1f0dd31ad11e7b8a74b1dbd5a2a28f2b535f78a8dcbe4aa5f6d6174905` |
| gun_casings_01.wav | `8776cd14f06f52f8494d8b151557a63bca224551cddec5cc7bbfbd1fd2622f2f` |

## Límites y pendientes reales

No se probó Ally X ni mando físico, ni se afirma escucha o aprobación humana del balance. La geometría muestreada corresponde a corredores de vuelo recto; no constituye una certificación de todas las maniobras arbitrarias del jugador ni un modelo completo de aerodinámica/colisiones. La semilla altera alternancia y selección de motor dañado; los corredores y escalonado son deliberadamente reproducibles entre semillas.

Persisten avisos de recursos/ObjectDB retenidos al cerrar algunas pruebas históricas de escena/audio, también visibles en ciertos logs nuevos; las aserciones y códigos de salida son PASS, pero no se declara toda la infraestructura libre de fugas. Los ensayos largos necesitaron un timeout de 180 s de pared para terminar su limpieza; no se sustituyó esa limpieza por un éxito inventado.

El fuego visual de escoltas representa cobertura/supresión y no contabiliza bajas propias de P-51. Los hardpoints de los GLB son coordenadas documentadas de respaldo porque faltan sockets nombrados. La valoración artística final de intensidad, humo y legibilidad corresponde a la ventana normal que se deja abierta.

PID/log de esa ventana y cierre de las pruebas: logs/lote9/runtime.json. Marcador final: logs/lote9/LISTO.md, escrito solo tras concluir las comprobaciones y abrir una única instancia normal con cámara exterior.

Ventana final verificada: PID **1586501**, `logs/lote9/juego_normal.log`, cámara exterior, sin pruebas GPU activas; instancia única comprobada a las 2026-10-24T18:15:08.062986-07:00.
