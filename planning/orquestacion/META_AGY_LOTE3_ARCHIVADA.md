# DEVOLUCIÓN 2 DEL SUPERVISOR — LOTE 3, SOLO PRESENTACIÓN (2026-10-24T14:19:09-07:00)
YA VERIFICADO, no se repite: los 5 hallazgos anteriores, 17/17 PASS, navegación real con 0 fallos, cadencia del mando (7 disparos/s), stick del artillero en demo y configuración del jugador intacta.
Las capturas GPU logs/orquestacion/lote3b-supervisor-20261024T141710/capturas/menu_*.png muestran 3 defectos. Corrige con parches mínimos:
1. El marcador de navegación («◇ 30.0 km», ui/navigation_marker.gd) se dibuja ENCIMA del botón Reanudar, porque game.gd lo añade a $HUD después del menú (línea ~126 frente a ~59). En set_pause(true) llama a settings_menu.move_to_front() (o crea el menú después del marcador). Además, el panel del menú debe ser OPACO (por ejemplo un StyleBoxFlat con Color(0.08,0.09,0.11,0.96) en el PanelContainer).
2. mission_overlay.gd dibuja el texto «PAUSA» en el centro (línea ~134) y se transparenta detrás del menú. No lo dibujes: el menú ya tiene el título «PAUSA / CONFIGURACIÓN». Conserva el oscurecimiento si quieres. test_overlay_integrity exige la cadena "PAUSA" en el código: la sigue cumpliendo el título del menú solo si cambias la prueba, así que NO borres la línea; envuélvela en `if not data.get("menu_visible", false):` y pasa data["menu_visible"] desde game.gd.
3. Nombres legibles: añade a InputProfile `static func display_name(profile) -> String` con «Teclado y ratón», «Mando Xbox» y «ROG Ally X», y úsala en settings_menu (Controles: ◀ Mando Xbox ▶). Unifica los prompts de mando en español con flechas: piloto «Cruceta ↑», artillero «Cruceta →» y bombardero «Cruceta ↓». Si alguna prueba compara literalmente "D-Pad", ajústala.
Después ejecuta las pruebas del lote 3 y la regresión de la lista, actualiza ENTREGA_LOTE3_AGY.md y pon awaiting_review.

# DEVOLUCIÓN DEL SUPERVISOR — LOTE 3 (2026-10-24T14:10:51-07:00) — hacer SOLO esto, con parches mínimos
Ya verificado y que NO se repite: input_profile.gd, settings_menu.gd, la integración base y 17/17 pruebas en PASS. La navegación con flechas y cruceta mueve el foco de uno en uno (tools_review/menu_navigation_claude.gd).
Hallazgos del supervisor, por el camino REAL de entrada (Input.parse_input_event):
1. CON MANDO NO SE PUEDE ACTIVAR NADA EN EL MENÚ. En Godot 4.7, ui_accept = Enter/Kp Enter/Espacio y ui_cancel = Escape; no incluyen botones de mando. En game.gd _ready, añade con InputMap.action_add_event un InputEventJoypadButton JOY_BUTTON_A a "ui_accept" y JOY_BUTTON_B a "ui_cancel", solo si aún no están. En settings_menu.gd handle_input, añade la rama ui_cancel → resume_requested.emit(). Aceptación: con A sobre Reanudar se quita la pausa; B quita la pausa; A sobre Reiniciar misión reinicia. Pruébalo con Input.parse_input_event, no llamando a handle_input.
2. tests/test_input_profile_unit.gd deja user://b17_settings.cfg con perfil="DESCONOCIDO": es el archivo REAL del jugador, y el juego empaquetado usa la misma ruta. Al empezar, guarda el contenido si existe; al terminar, también en los FAIL, restáuralo o bórralo si no existía. Revisa test_settings_menu_unit.gd igual.
3. Fuego con mando sin recarga: en player_controls.gd poll_inputs, RB/X mantenidos llaman a fire() en CADA fotograma (60 disparos/s, 25 de daño cada uno). Añade var joy_fire_cooldown: float y dispara como máximo cada 0.12 s mientras el botón esté mantenido; resta delta cada fotograma. No cambies el disparo con clic ni con ESPACIO.
4. Artillero con mando en DEMO: poll_inputs sale con `if sim.autopilot: return` antes de leer el stick derecho, así que en demo el mando no apunta ni dispara (el ratón sí). Mueve ese return para que SOLO afecte a los mandos de vuelo: con autopiloto y station == "ARTILLERO", el stick derecho y RB/X deben funcionar con un perfil de mando.
5. mission_overlay.gd: «[1/2/3] MANUAL · PUESTO» sigue fijo. Con XBOX o ROG_ALLY_X debe decir «[Cruceta] MANUAL · PUESTO». Añade una acción "puestos" a InputProfile.prompt ("1/2/3" en TECLADO_RATON y "Cruceta" en los mandos), con un parche mínimo.
Después ejecuta todas las pruebas del lote 3 y las de regresión de la lista de reglas, escribe ENTREGA_LOTE3_AGY.md con los cambios y pon AGY_ESTADO.json en awaiting_review.

# NOTA DEL SUPERVISOR (2026-10-24T14:00:45-07:00) — leer antes de continuar el LOTE 3
1. core/input_profile.gd YA EXISTE y su estructura está revisada; no la regeneres. Corrige con un PARCHE tuyo solo estos textos de prompt():
   - "disparar" en XBOX y ROG_ALLY_X: "RB / X". RT es el acelerador; player_controls.gd dispara con JOY_BUTTON_RIGHT_SHOULDER o X.
   - "pausa" en XBOX: "Menú (≡)". En el mando Xbox Series ese botón se llama Menú. "autopiloto" en XBOX: "Vista (⧉)".
2. ui/settings_menu.gd: los 6 rechazos de Qwen se deben a un ERROR DE LA PRUEBA, no de Qwen. El candidato logs/agy-qwen/20261024T205845-1792875525039457367/3.candidate.gd SÍ emite profile_changed. En tests/test_settings_menu_unit.gd (y en test_input_profiles.gd si hace lo mismo), las lambdas `func(name): profile_received = name` asignan a variables LOCALES, y en GDScript las lambdas las capturan POR VALOR: la asignación nunca se ve fuera. Usa un contenedor, por ejemplo `var got := {}` y `func(n): got["profile"] = n`, o `var got := []` con append. Corrige las pruebas y vuelve a pasar ese candidato 3 por el puente (o reintenta con el mismo brief): no reescribas el brief.
3. test_input_profiles.gd escribe en user://b17_settings.cfg, el archivo real del jugador. Guarda su contenido al empezar (si existe) y restáuralo o bórralo al terminar, también en los caminos de FAIL.

# Encargo vigente Agy/Qwen — LOTE 3: configuración de controles (supervisor Claude, 2026-10-24T13:51:01-07:00)
Petición del usuario: «en las configuraciones, elegir jugar con teclado y ratón, con el mando de XBOX más nuevo o con los controles de ASUS ROG Ally X».
Lotes 1 y 2 CERRADOS y verificados; no repetir nada de ellos. El candidato release/local-20261024-b457f0384d78 NO se toca: se trabaja en godot/B17.

## Reglas (sin cambios)
- Pruebas SOLO con esta orden literal, ruta absoluta y sin cd delante:
  `/home/test-bench/Documents/B17-project/tools/godot --headless --path /home/test-bench/Documents/B17-project/godot/B17 --script res://tests/<archivo>.gd`
- Nada de python3 -c, sha256sum, ls ni otras órdenes. Archivos NUEVOS: Qwen, mediante el puente encargar_qwen.py, con una prueba que cubra su comportamiento. Cambios en archivos EXISTENTES: Agy, con parches mínimos usando su herramienta de edición, nunca reescribiendo el archivo entero.
- Tras cada paso deben seguir en PASS: test_overlay_integrity, test_local_control_directions, test_player_controls, test_neutral_station_inputs, test_local_bombing_usability, test_victory_defeat_pause_reset.

## Contrato
Perfiles: "TECLADO_RATON" (por defecto), "XBOX" (mando Xbox Series X|S) y "ROG_ALLY_X" (controles integrados de la Ally X, que el sistema expone como mando tipo Xbox).
- Teclado y ratón funcionan SIEMPRE, con cualquier perfil, para que nadie quede bloqueado.
- El mando solo actúa con XBOX o ROG_ALLY_X, para evitar derivas de stick con TECLADO_RATON.
- XBOX y ROG_ALLY_X comparten el mapeo de botones actual de player_controls.gd. No se mapean M1/M2 de la Ally (no llegan al juego por defecto). Cambian los textos en pantalla.

## Tareas, en este orden
A. (Agy) Prueba primero: tests/test_input_profiles.gd. Debe FALLAR antes de implementar y cubrir:
   1. el perfil por defecto es TECLADO_RATON;
   2. guardar y cargar el perfil en user://b17_settings.cfg (ConfigFile, sección "controles", clave "perfil"), sobrevive a una instancia nueva y un valor inválido vuelve a TECLADO_RATON;
   3. suggest_profile(nombres_de_mandos: Array) devuelve TECLADO_RATON sin mandos, ROG_ALLY_X si algún nombre contiene "ally" o "asus" (sin distinguir mayúsculas) y XBOX en otro caso;
   4. prompt(accion, perfil) devuelve texto no vacío para "soltar", "disparar", "pausa", "reiniciar", "autopiloto", "piloto", "artillero", "bombardero", "aceptar" y "volver"; los textos de TECLADO_RATON y XBOX difieren para "soltar" y "pausa"; ROG_ALLY_X nombra los botones como en la Ally X (A, B, X, Y, «Vista», «Menú»);
   5. con la escena game.tscn: con TECLADO_RATON, un InputEventJoypadButton A en BOMBARDERO, en manual y con la fase BOMBARDEO, NO suelta la bomba; con XBOX, SÍ; ESPACIO suelta con los dos perfiles;
   6. JOY_BUTTON_START abre la pausa con el menú visible; la navegación con eventos ui_down/ui_accept/ui_left/ui_right cambia de perfil y lo guarda; «Reanudar» quita la pausa; «Reiniciar misión» reinicia.
B. (Qwen, archivo nuevo) core/input_profile.gd: class_name InputProfile extends RefCounted, con constantes PROFILES, load_profile() -> String, save_profile(name) -> void, suggest_profile(names: Array) -> String y prompt(action: String, profile: String) -> String. Estático y sin nodos.
C. (Qwen, archivo nuevo) ui/settings_menu.gd: extends Control. Panel centrado con Buttons enfocables: «Reanudar», «Controles: <perfil>» (◀ ▶ y aceptar para cambiar), «Reiniciar misión». Señales resume_requested, restart_requested y profile_changed(name). Navegable con ratón, teclado (flechas y Enter) y mando (las acciones ui_* integradas). Muestra debajo una línea con los controles principales del perfil elegido, usando InputProfile.prompt.
D. (Agy, parches) Integración:
   - game.gd: crear el menú en $HUD; ESC, P y START alternan pausa y menú; conectar las señales (profile_changed → controls.profile y save_profile); pasar data["input_profile"] al overlay.
   - player_controls.gd: var profile:String; ignorar los eventos y ejes de mando si profile == "TECLADO_RATON".
   - mission_overlay.gd: sustituir SOLO las indicaciones de teclas fijas ([ESPACIO], [TAB / VIEW], la línea de controles de la intro y «R · VOLVER A VOLAR») por InputProfile.prompt según data["input_profile"]. Con mando, en la pantalla final, A también vuelve a volar.
   - Al primer arranque sin configuración guardada, usar suggest_profile con los nombres de Input.get_connected_joypads() / get_joy_name().
E. Escribe planning/orquestacion/ENTREGA_LOTE3_AGY.md (archivos, APIs y pruebas con su resultado) y pon AGY_ESTADO.json en awaiting_review.
El supervisor revisará los cambios, repetirá la regresión, capturará con GPU el menú y el HUD en los 3 perfiles y regenerará el paquete.

---
## Histórico (U01/U02, ya cerrado)
# Encargo prioritario Agy/Qwen — cerrar U01/U02 para V1LOCAL
Ejecución autorizada. No rehacer modelos/cazas/anclajes/H05/H06: ya pasaron revisión independiente. No capturas headless, no repro_controlsdenegado, no comandosls/genéricos ni permisosglobales. El principal solo supervisa. Trabaja hasta entregar ambas correcciones con pruebas y checkpoint.

## Estado comprobado
Codex: modelosactivos+formación+combate+controles+escenaPASS; manualfixtureClaudeenmendadoPASS724s IM PACTO hull57sinObjectDB; paqueteLinux fuente+motor+lanzador restaurado con importaciónfría y misiónPASSenhost. CLAUDE está revisandoGPUvisual/audio ahora. TodavíaNOACEPTADO. Árbol producción estable antesdeestos cambios, manifiestoreleaseanterior quedaráanticuadoalcorregir.

## Primero leer estas rutas conocidas con herramientasdearchivos, sinlistados
planning/orquestacion/REVISION_BOMBARDEO_MANUAL_CODEX.md; godot/B17/core/player_controls.gd; godot/B17/bomb_model.gd; godot/B17/core/simulation.gd; godot/B17/ui/mission_overlay.gd; game.gd; planning/orquestacion/ENMIENDA_TEST_MANUAL_CLAUDE.md.

## U01 — Ayuda visible y real de suelta de bomba, Qwenprincipal
El retículo actualmira266m adelante a1200m/85mps,pero la bomba avanza1329m. Soltarconcruzcentradafalla1062m; robotmanuallee fórmulasecreta. No aceptar con simpletexto fijo.
Meta mínima: usuario de puestoBOMBARDEROenmodoMANUAL recibe señal clara basada en balística REAL para poderpulsarSPACE y acertar. No automatizar suelta, no exigiraritméticaalusuario ni cambiar vuelo/campaña. Mantener mira sihayayudaclara distinta, sinfingirquecruzdecorativaesimpacto.
Declaro archivos nuevos Qwen permitidos: core/bombing_aid.gd (lógica pequeña) y ui/bombing_cue.gd (widgetpequeño) si facilitar evita reescribir300líneas. Agy integra conpatchespequeños en game.gd. Alternativa equivalente conoverlay existentepermitida, publicacontrato antes deescribir. Reutiliza gravedad yvelocidad/origenqueusa bomb_model; sincambioshiddena radio/blancoparaPASS.
Contrato de datos compartidos paraQA: un diccionario `bombing_aid` expuesto en overlay.data (o cue.data conruta explícitaentregada) que la UIREALrenderice. Campos mínimos `release_now:bool`, `eta_seconds:float`, `lateral_error_m:float`, `status:String`, `predicted_impact:Vector3`. Datos calculados desdeestadoactual, no fases/tiempo hardcoded. Si tuinterfaz difiere,documenta equivalenciaenCOORDINACIONAGYantesdepruebas.
UIvisible: indicación de aproximación/cuentaatrás oadelanto, correcciónderumbo si fueraeje, señal inequívocaSUELTA AHORA vinculada a release_now, yestadoBOMBAS FUERA si gastada. Soloactivarverdeconsoluciónválida; siobjetivoyaquedóatrásnofalsopositivo. No mostrar mensaje genérico imperativo ESPACIO SOLTAR todoeltramo como si cualquierinstantefueraacierto. V1LOCAL teclado/ratón: quitartexto AllyXintroqueahoranoaplica,conservar soporteexistente sin borrarcontroles.
QAantesdeaceptar: caso1200m/85mpsy variaciones razonablesvelocidad/altura: operador sintéticousaSOLAMENTEelmismodiccionarioexpuestoalHUD para decidir ypulsa tecla realSPACE; modelo real daIMPACTO. Fueraeje yobjetivopasado no debenindicarrelease_now. NOusar fórmulaocultaenrobot paraelPASS. La prueba independiente futura deCodex no se modifica por ti.

## U02 — Neutralizar entradas al cambiar puesto
Se reproducen6casos (D,S,SHIFT xARTILLERO/BOMBARDERO) con teclaya físicamentesoltada y2savance: quedan -1/+1inputs causando giro36deg, pitch9.87deg oaceleración16mps. Al abandonarPILOTO neutraliza comandosmanuales latentes, manténmodoautopiloto/manual elegidoyestadodelavión. AlvolverPILOTO pollea tecladovigente, nocarguetrashistórico. PuedeencargarseaQwen cambioacotado player_controls.gd, preservandoH05/H06. Pausa/resetcontractsinregresión. Prueba6casosconeventosInputreales;inputsquedan0sin teclasnuevas. Conservarcabeceo físico estabilizándoserazonablemente no confundirlo con inputaplicado.

## Ejecución y comunicación
Usarpuenteautorizado `python3 -u /home/test-bench/Documents/B17-project/encargar_qwen.py /home/test-bench/Documents/B17-project/planning/agy-qwen/tarea.json`. Tests `.../tools/godot --headless --path /home/test-bench/Documents/B17-project/godot/B17 --script res://tests/prueba.gd`. HerramientasdearchivosparaJSONylecturas, NOls yNO--verboseantesde--path ni reintentarcommandsdenegados. No modificarpruebas ajenas; conservarversionesprevias. Elpuentecontesta accepted_for_review, noautoaprobaciónfinal.
Escribe planning/orquestacion/ENTREGA_U01_U02_AGY.md conarchivos, APIs,hashes ytests; actualiza AGY_ESTADO.jsonreal yAGY_AVANCE deorquestacion, logs/agy.log. SiamboscasosQA pasan status awaiting_review, no repetir módulos esperando. Nuevoharnessreconoceeseestado ydeduplica evidencia.
PrimeroU02 máspequeño; luegoU01. Mantenercandidatorevisable ypruebaslocalespertinentes. No sincorreccionesentregadas y un meroplan. Cuandoestélisto,supervisorreactivarevisiónindependiente/visualydeliveryactualizado.


# Marco de alcance
# Prompt técnico activo — Orquestación de V1 LOCAL

## Autorización y prioridad
El usuario revisó el prompt y dijo «run». Luego redujo el alcance: PRIMERA VERSIÓN EN ESTA MÁQUINA LINUX/RTX2060SUPER; migración a AllyX posterior. FASE ACTIVA: EJECUCIÓN. Esta instrucción sustituye la congelación de planificación y los requisitos Windows/Ally de contratos históricos. No pedir otra confirmación de la ejecución rutinaria ya autorizada.

## Meta global y cierre
Completar y verificar una primera misión jugable de Aurora sobre Europa en Godot en este equipo: formación, cazas/antiaérea, daño, bombardeo, regreso a zona segura, victoria/derrota, pausa/reset, controles teclado/ratón y modo de demostración separado. Integrar los modelos texturizados existentes y resolver regresiones. Entregar un arranque local reproducible, instrucciones exactas y versión respaldada. No añadir despegue/aterrizaje ni campaña.

Fuera de V1: exportación/pruebas Windows, validación AllyX, optimización de energía/controles específicos de consola, siguiente misión y publicación. No borrar lo ya existente. Gamepad existente puede conservarse, pero no bloquea V1. No nuevas generaciones pagadas/compras ni instalaciones globales.

## Hilo principal — supervisor exclusivamente
No programa producción, no corrige juego ni absorbe tareas. Asigna dueños/metas, consulta estados, revisa evidencia, devuelve entregas y resuelve bloqueos. Mantiene tablero y publica avances aceptados en consola. No confunde proceso vivo con progreso, plan aceptado con implementación ni tests con aceptación visual.

## Metas por agente
- AGY: coordinador técnico y QA. Completar puntos1.1.2.1,1.1.2.2,1.1.3.1–3,1.1.4.3LOCAL y1.1.5.3. Encargar a Qwen código con contratos pequeños y firmas precisas; ejecutar pruebas/registrar códigos de retorno y diagnósticos; mantener checkpoint; integrar cambios aceptables. No autoaprobar entrega final.
- QWEN: programador principal. Completar1.1.1.1–3,1.1.2.4,correcciones1.1.3.4,1.1.4.4LOCAL y1.1.5.1LOCAL. Modelo real qwen2.5-coder:7b-instruct-q4_K_M. Una inferencia por vez vía encargar_qwen.py y godot-art.lock. No descargar modelos ni debilitar pruebas de revisión para aprobar.
- CLAUDE: cerrar revisión1.1.1.4 y1.1.2.3,registrar/revisar1.1.3.4 y redactar1.1.4.2LOCAL. Revisión estática, capturas GPU reales y hallazgos reproducibles. No modificar producción que pertenece a Agy/Qwen. No nuevas llamadas de arte pagadas. La propuesta misión2 queda diferida.
- CODEX ENTREGA LOCAL: comprobar integración, preparar arranque/entrega local1.1.4.1 y respaldo1.1.5.2, revisar dependencias asignadas. No exportar Windows ni condicionar cierre a hardware externo. Puede escribir prueba independiente tests/test_imported_aircraft_integration.gd; Agy/Qwen NO la modifican para ocultar defectos. No tocar producción; si hace falta, encargar a Qwen mediante Agy.

## Primer hito — modelos activos, no solo archivos existentes
1.1.1.1: aircraft.gd instancia b17g.glb ya importado; conserva Engines pausable y cuatro rotores sin geometría duplicada.
1.1.1.2: cinco compañeros usan el mismo modelo integrado conservando wingmen/left/right/slots y separación/cámaras.
1.1.1.3: fighter.gd usa Bf109/Fw190 existentes, conservando rotor:Node3D y contratos IA. Mostrar ambos en la misión.
1.1.1.4: revisar materiales, escala/orientación, animación y correspondencia de índices de daño con motores físicos.
GLB/texturas son entradas de solo lectura para Qwen. Ordenar/m apear motores por x física, no por sufijo Rotor_N. Derivar humo/escapes de nodos/transformadas. Declarar/asignar cualquier módulo auxiliar antes de escribirlo. Agy declara punto listo para revisar mediante planning/orquestacion/HITO1_LISTO_PARA_REVISION.md con hashes/archivos/pruebas y límites; no basta candidate_complete anterior.

## Riesgos que deben reproducirse y resolverse
Leer ENTREGA_CLAUDE.md H-01/H-04/H-05/H-06: cámara de bombardero dentro del modelo, índices motor/rotor cruzados, dirección de disparo divergente de cámara, posible giro invertido. Son hallazgos estáticos, no declarar corrección sin reproducción/prueba. Confirmar reinicio accesible por teclado y no exigir mando de consola en V1. Investigar warnings históricos ObjectDB en candidato actual.

## Método y evidencia
Un dueño por archivo. Agy/Qwen poseen producción; Claude posee documentos/revisión/arte; Codex Entrega posee test independiente/manifiesto/entrega. Coordinar nombres antes de editar. Hasta3correcciones Qwen por contrato, después reducir tarea o revisar diagnóstico, sin bucles vacíos. El lock de inferencia no bloquea ediciones.
Pruebas pertinentes del candidato exacto: modelos activos/recursos, formación, combate, controles, misión larga y escena, entradas manuales sintéticas, revisión cámaras y aceptación. Mantener30/60/120pasos físicos/s separados de FPS de render. Usar capturas reales en RTX y medir rendimiento local identificado; no extrapolar a AllyX ni inventar sesión humana. Ángulos de rotores requieren manejar envolvimiento2π. Conservar/manifiesto de hashes diferentes por artefacto.

## Avances en consola
Cada agente mantiene SU log en logs/orquestacion/{agy,qwen,claude,codex_entrega}.log conservando líneas previas:
fecha real o NO_VERIFICADA | agente | punto | RECIBIDO/EN_EJECUCION/ENTREGADO/BLOQUEADO | descripción | evidencia
El supervisor publica COMPLETADO_VERIFICADO solo tras revisión, en supervisor.log y TABLERO.md. Reportar cada punto terminado, archivo de evidencia y siguiente dependencia. No inventar hora, ejecución ni aprobación.

## Cierre local
Requiere: modelos activos aceptados; combate/cámaras/control coherentes; misión completa y fallos/reset probados; arranque en esta Linux con GPU real; instrucciones teclado/ratón; problemas conocidos y métricas locales; respaldo/manifiesto restaurable. El paquete fuente+motor/lanzador puede ser suficiente si es reproducible: no imponer exportación innecesaria. Etiquetar CANDIDATO_LOCAL hasta revisión final del supervisor. Windows/Ally quedan DIFERIDO_POST_V1, sin bloquear.
