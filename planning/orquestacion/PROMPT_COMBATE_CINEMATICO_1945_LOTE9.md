# Lote 9 — Más interceptores y combate aéreo cinematográfico, Europa 1945

## 1.1.1.0 Orden secuencial y contexto

- **1.1.1.1** El usuario ordena ejecutar este encargo DESPUÉS de terminar la integración actual de conversaciones, subtítulos, música y flak. No empieces cambios hasta que exista `logs/dialogue_music/TERMINADO_Y_JUEGO_ABIERTO.json` y su campo `complete` sea true. El lanzador espera esa señal; no la fabriques.
- **1.1.1.2** Proyecto `/home/test-bench/Documents/B17-project/godot/B17`. Más cazas enemigos y combate visual intenso con coordinación, pasadas cercanas, trazadoras, evasiones y daños, evocando cine bélico sin copiar escenas, diálogo ni música de películas. Mantén carácter de bombarderos B-17G, escoltas P-51 y Bf109/Fw190, Europa en 1945.
- **1.1.1.3** Conserva cámara orbital/observación de compañeros, cien nubes, niebla reducida, flak denso, voces en inglés estadounidense con subtítulos españoles, partitura adaptativa y cuarenta y dos efectos recién sustituidos. Los cinco WAV M2 validados son intocables byte por byte: `logs/audio_redesign/m2_protected_hashes.json`. No regeneres audio ni alteres sus scripts/fuentes.

## 1.1.2.0 Fuerza de interceptación y código

- **1.1.2.1** Inspecciona estado real en `core/combat_manager.gd`, `core/fighter_ai.gd`, `game.gd`, `visuals/fighter.gd`, `visuals/escort.gd` y `visuals/tracer_pool.gd`. Baseline documentado: 30 interceptores, 16 escoltas y 300 bombarderos (cinco compañeros detallados y fondo MultiMesh). Confirma antes de cambiar.
- **1.1.2.2** Eleva fuerza enemiga a **48 cazas** con una constante/configuración compartida entre simulación y pool visual, evitando un 30 fijo en game.gd. Reparte 16 frontales, 16 laterales (8 por flanco) y 16 de cola; alterna Bf109 y Fw190 de manera reproducible con semilla. No instancies o destruyas modelos durante cada pase.
- **1.1.2.3** Coordina grupos de 4: aproximación, ventana de disparo de 1–2 s, cruce y separación, retorno al siguiente pase. Escalona grupos entre 0,8 y 2 s; evita que todos viren o disparen al mismo tiempo. Mantén distancias de seguridad entre trayectorias y avión del jugador. No teletransportes cazas a la cámara.
- **1.1.2.4** Diseña pasadas observables de 120–500 m según geometría real de vuelo; aproxima por delante y flancos, con velocidad relativa legible y sin atravesar fuselajes. Las evasiones de alabeo/viraje deben seguir la velocidad del modelo; evitar giros instantáneos o acrobacias tipo misil.
- **1.1.2.5** El aumento de aviones no debe multiplicar linealmente el daño inevitable. Limita a 8–12 atacantes con ventana de tiro efectiva simultánea y distribuye el resto en aproximación/separación. Conserva una misión jugable en manual y autopiloto; prueba supervivencia con varias semillas sin inventar validación de dificultad del usuario.

## 1.1.3.0 Lectura visual del combate

- **1.1.3.1** En `visuals/tracer_pool.gd` y emisores existentes, muestra trazadoras por ráfagas con proporción moderada de 1 cada 3–5 disparos representados. Duración aproximada 0,15–0,4 s, ancho de pantalla orientativo 1–3 px a 1280×720; sin rayos continuos ni lluvia de líneas atravesando todos los planos. Pool con límite explícito y métricas; no aumentar audio por cada trazadora.
- **1.1.3.2** Da coherencia a fuego aliado/enemigo: origen en montajes existentes, dirección hacia objetivos que realmente puede alcanzar su sector, destello breve visible 30–60 ms y apagado durante pausa. No dispares desde el centro de un modelo si existen puntos de arma.
- **1.1.3.3** Conecta daños a humo y caída: humo de motor/combustible localizado, pérdida gradual de sustentación, descenso que conserva impulso, uno o pocos estallidos cuando corresponde. No explotar cada caza como una bomba terrestre. Reutiliza recursos validados y registra qué daño lógico origina cada efecto.
- **1.1.3.4** Las escoltas deben entrar visualmente en el enfrentamiento por sectores de cobertura sin abandonar la formación todas a la vez. Mantén cinco wingmen base y sus contratos. No conviertas los 294 bombarderos de fondo en nodos completos ni rehagas modelos.
- **1.1.3.5** Conserva corredores para observar acción con la nueva cámara: no tapes permanentemente el B-17 ni la información de mira. Ayuda de cámara y subtítulos deben permanecer legibles con humo y trazadoras. La cámara no toma el control del usuario para imponer una cinemática.

## 1.1.4.0 Audio, diálogos y continuidad

- **1.1.4.1** No añadas reproducciones del disparo antiguo ni multipliques sonidos por los 48 cazas: usa límites de voces y priorización por distancia. La M2 propia conserva exactamente sus recursos y reproducción validados. Los flak recientes proceden de grabación adaptada; no vuelvas a los tonos de salto.
- **1.1.4.2** `audio/scene_audio_director.gd` ya dispara avisos de cazas y música de combate según amenaza. Usa su estado real; no dupliques locuciones por caza ni cambies idioma a español. Voces estadounidenses en inglés con fraseología radiofónica de 1945, subtítulos españoles sincronizados. No imites actores ni afirmes que las voces TTS son grabaciones históricas.
- **1.1.4.3** Pausa detiene movimiento, ráfagas y colas; reiniciar limpia pools/oleadas/objetivos, mantiene menús y no pierde perfiles de mando. Cambiar de puesto no debe reiniciar oleada ni duplicar blancos.

## 1.1.5.0 Validación, cierre y ventana de prueba

- **1.1.5.1** Antes de editar, guarda respaldo de los archivos afectados bajo `logs/lote9/backup/`, y comprueba que no haya otro escritor de cámara/juego activo. Cierra la instancia anterior de ESTE proyecto al empezar la integración. No mates otros programas ni sesiones de Codex/Claude ajenas al encargo.
- **1.1.5.2** Pruebas de 48 enemigos, asignación 1:1 visual/simulación, límites de atacantes efectivos, fin de oleada, reset/pausa, trayectorias no solapadas y pool de trazadoras acotado. Pruebas existentes de cámara, escenas, audio/subtítulos/música, controles y misión; actualiza expectativas antiguas solo donde el contrato cambie de manera expresa.
- **1.1.5.3** Capturas reales 1280×720 de pase frontal/lateral/cola, escolta en combate, caza dañado y observación orbital. Mide 60 s con carga combinada: 48 enemigos, formación, escoltas, flak activo, nubes, voces y música. Registra FPS medio, mediana/p95 de frame, número de instancias/trazadoras/voces y GPU. Objetivo 60 FPS a 720p; si falla, optimiza overdraw/pools/LOD antes de reducir las 48 unidades pedidas. No declares Ally X probado sin hardware.
- **1.1.5.4** Entrega `planning/orquestacion/ENTREGA_LOTE9_COMBATE_CINEMATICO.md` con archivos, valores finales, evidencias, logs, hashes M2 y pendientes reales. No publiques ni modifiques releases anteriores. Cierra todas las pruebas GPU y abre UNA instancia normal del juego con cámara exterior para validación. Registra PID/log y deja `logs/lote9/LISTO.md` solo cuando implementación y comprobaciones hayan concluido.
