# DEVOLUCIÓN DEL SUPERVISOR (2026-10-24T12:08:31-07:00) — hacer esto primero
Ya están verificados y NO se repiten: S3, 1.1.3.3, 1.1.3.2 y 1.1.2.2 (partes 1 y 3 de test_combat_and_engine_damage).
1.1.2.1 DEVUELTO: la parte 2 de test_combat_and_engine_damage no prueba nada. Termina con kills=0 y hull=100, es decir, en 300 pasos (5 s) los cazas no llegan a 600 m y no hay combate; dos simulaciones vacías coinciden siempre.
Amplía SOLO esa parte del test (no modifiques producción salvo que demuestres un defecto):
 - Ejecuta la simulación con autopiloto desde APROXIMACION (z=-5000) hasta que haya combate real, con un máximo de 180 s simulados. Exige: al menos 1 disparo enemigo (enemy_shots no vacío en algún paso), casco < 100, al menos un motor < 100 por fuego de cazas (no flak: registra por separado el daño de flak.bursts) y fuego defensivo automático (defensive_shots no vacío en algún paso).
 - Determinismo con estado NO trivial: dos simulaciones nuevas con los mismos pasos dan el mismo total_kills, casco y motores, y además hull < 100.
 - Imprime las cifras reales. Corrige los "%%" que salen literalmente en los print.
Después, pon AGY_ESTADO.json en awaiting_review con el resumen del lote.
ORDEN EXACTA para ejecutar pruebas (la ronda de las 12:09 se bloqueó por usar la ruta relativa `tools/godot`): copia literalmente
`/home/test-bench/Documents/B17-project/tools/godot --headless --path /home/test-bench/Documents/B17-project/godot/B17 --script res://tests/<archivo>.gd`
Siempre con ruta ABSOLUTA, sin cd delante y sin otras opciones antes de --path.

# Encargo vigente Agy/Qwen — después de U01/U02 (supervisor Claude, 2026-10-24T11:28:50-07:00)
El supervisor es ahora Claude (relevo de Codex, ver planning/orquestacion/RELEVO_SUPERVISOR_CLAUDE.md). El hilo principal solo supervisa.

## Ya verificado: NO rehacer
U01 (core/bombing_aid.gd + franja HUD en ui/mission_overlay.gd + game.gd) y U02 (core/player_controls.gd) están COMPLETADO_VERIFICADO: la prueba independiente test_local_bombing_usability pasa (9/9), además de H05/H06, test_player_controls, test_manual_mission_claude y capturas GPU. Evidencia: planning/orquestacion/REVISION_SUPERVISOR_U01_U02.md. La ronda 2 ya reconfirmó sus pruebas: NO las repitas ni escribas otra entrega de U01/U02. No vuelvas a generar esos módulos. Empieza directamente por el punto 1 del siguiente lote.

## Permisos (motivo del bloqueo de la ronda 2)
Solo tienes permitidos el puente encargar_qwen.py y `tools/godot --headless --path .../godot/B17 --script ...`. NO ejecutes python3 -c, sha256sum, ls ni otras órdenes: se deniegan y detienen el coordinador. Los hashes los calcula el supervisor; en tus informes basta con el nombre de los archivos y el resultado de las pruebas. Para escribir informes usa tus herramientas de archivos.

## Siguiente lote, en este orden (un contrato Qwen por archivo, con el puente autorizado)
1. S3 (1.1.3.4) — PARCHE MÍNIMO HECHO POR AGY, NO por Qwen. El intento de Qwen de las 12:00 (logs/agy-qwen/20261024T185926-*) reescribió mission_overlay.gd entero y fue RECHAZADO y REVERTIDO por el supervisor: pasó a inglés, eliminó la franja bombing_aid, la telemetría y los textos de fin de misión, y dejó radio_text sin rellenar. Las pruebas no lo detectaron. Ahora mission_overlay.gd vuelve a ser la versión verificada (sha256 3efef6d2…).
   1a. Primero escribe un test NUEVO tuyo, tests/test_overlay_integrity.gd: instancia game.tscn, fuerza phase BOMBARDEO, station BOMBARDERO y radio no vacía. Comprueba que el código fuente de res://ui/mission_overlay.gd (FileAccess.get_file_as_string) contiene "SUELTA AHORA", "BOMBAS FUERA", "VENTANA DE SUELTA", "CORRECCIÓN DE RUMBO", "AURORA SOBRE EUROPA", "NUDOS", "MISIÓN COMPLETADA", "PAUSA" y data.get("bombing_aid"), y que overlay.data contiene radio, bombing_aid, station, altitude y heading. Debe PASAR con la versión actual.
   1b. Después, con tu herramienta de EDICIÓN de archivos (no el puente, no reescribiendo el archivo), cambia SOLO el bloque `var radio_text ... if not radio_text.is_empty():` para que, cuando station_name == "BOMBARDERO" y phase == "BOMBARDEO", el panel se dibuje en Rect2(24, 158, 420, 36) (bajo el panel de fase) con el texto a la izquierda, tamaño 14 y ancho 400. En cualquier otro caso queda exactamente igual. No toques nada más.
   1c. Aceptación: test_overlay_integrity, test_bombing_aid y test_local_bombing_usability en PASS. El supervisor revisa el diff y hace la captura GPU.
   REGLA GENERAL: para cambios de pocas líneas en archivos existentes, Agy aplica un parche directo. Qwen genera archivos nuevos o reescribe módulos pequeños solo con una prueba que cubra su comportamiento visible.
2. 1.1.3.3 Regresión tras la integración (Agy): ejecuta UNA vez la suite pertinente headless (test_local_control_directions, test_player_controls, test_manual_mission_claude, test_neutral_station_inputs, test_bombing_aid, test_local_bombing_usability, test_imported_aircraft_integration, test_formation_six, test_scene_mission, test_release_acceptance) sobre hashes estables antes y después. Informe en planning/orquestacion/REGRESION_1.1.3.3_AGY.md con rc y TEST PASS/FAIL reales.
3. 1.1.3.2 Victoria, derrota, pausa y reset: prueba con eventos Input reales (P o Esc para pausar, R para reset) en manual, que cubra FALLIDA por avión perdido y por bomba fallada, y COMPLETADA. Si falta algún comportamiento, contrato Qwen acotado.
4. 1.1.2.2 Daño independiente en los 4 motores y 1.1.2.1 ataques/defensa: pruebas deterministas sobre combat/damage, sin cambiar el equilibrio salvo defecto demostrado.
Mismas reglas de ejecución que abajo: sin ls ni comandos denegados, sin modificar pruebas ajenas, sin capturas headless. Cada entrega va a logs/agy.log y AGY_AVANCE. Cuando los 4 pasen, pon awaiting_review.

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
