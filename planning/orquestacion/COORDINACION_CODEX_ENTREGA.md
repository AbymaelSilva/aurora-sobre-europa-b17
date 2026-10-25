# Coordinación de revisión independiente — Codex Entrega LOCAL

Recibido scope Linux/RTX2060SUPER. No exportaré Windows ni exigiré Ally. No edito producción/arte/pruebas existentes. Soy dueño únicamente del nuevo tests/test_imported_aircraft_integration.gd y evidencia propia.

## Inspección previa y expectativas del test
- Verificar la escena activa game.tscn, no solo existencia de recursos GLB. Jugador y5wingmen deben tener exactamente una instancia real b17g.glb; su geometría corresponde al recurso importado y no convive con Body/Wings/Engines procedurales duplicados. Se permiten los detalles adicionales de bomber_details.gd.
- Engines debe conservar el control efectivo de animación/pausa sobre4rotores reales. La diferencia angular se compara envuelta a2π.
- Salud0..3 conserva orden físico izquierda→derecha; anclajes de humo se derivan de transformaciones de nodos reales. El test dirigirá daño individual, revisará posición localx del trail respecto al rotor ordenado y verificará que el anclaje siga una variación de transform del modelo, sin fijar las coordenadas originales.
- Cazas activos en fighter_visuals deben incluir instancias reales de BF109 yFW190 con un rotor real cada uno y referencia rotor compatible; sin geometría procedural duplicada. No se exige un API nuevo para elegir variante mientras ambas aparezcan realmente en escena.

## Hallazgo que requiere coordinación antes de integrar
Los GLB b17g/bf109g/fw190a tienen7hijos de malla por rotor (buje+3palas+3puntas), constatado leyendo su JSON. tests/test_claude_batch.gd esperaba4hijos en el rotor PROCEDURAL. Esa aserción antigua no corresponde al modelo nuevo. No inventar nodos vacíos, wrappers decorativos ni geometría doble para hacerla pasar. Pedir al dueño Claude una actualización semántica explícita de esa prueba si la referencia rotor pasa a ser el rotor GLB real; la prueba independiente comparará contra los nodos reales del recurso, no fijará4. Codex Entrega no modificará el test ajeno.

## Estado
Preparando prueba independiente antes de integración. El código activo todavía es procedural a09:19. Un FAIL inicial es esperado y sirve de control contra falsos positivos; no es una regresión atribuida a Qwen antes de recibir su entrega.

## Entrega de prueba independiente y baseline
- Nueva prueba exclusiva: tests/test_imported_aircraft_integration.gd. Sintaxis comprobada y ejecución baseline realizada.
- Resultado baseline: salida1,11comprobaciones incumplidas por no existir instancias GLB en jugador/compañeros/cazas. Los controles positivos del inspector con las escenas fuente importadas NO fallaron. Es el resultado esperado antes de integración; evita un falsoPASS por solo existencia de archivos.
- Evidencia: logs/orquestacion/imported-aircraft-baseline.log y baseline-model-integration.json. El manifiesto es observacional, NO congela candidato ni autoriza exportación.
- Incluye visibilidad de cazas en la primera oleada por avance real de simulación; no solo slots ocultos. Comparación de recursos de malla contra GLB fuente y ausencia de geometría adicional no asignada; permite bomber_details.gd. Pausa y reanudación de24rotores con ángulos envueltos. Mapeo de humo por daño individual/posición local, giro del avión y perturbación de transform del modelo.
- PROMPT_EJECUCION.md leído; alcanceLOCAL confirmado. Esperando HITO1_LISTO_PARA_REVISION.md antes de dictaminar integración. No se editaron producción ni pruebas ajenas ni se exportó.
- Limpieza de la prueba independiente: detiene/desreferencia los4players, libera escena y espera6ciclos físicos/proceso, igual que la suite existente. La última baseline termina con11fallos de integración esperados y sin advertencia ObjectDB. Una versión intermedia del test que no drenaba audio sí reprodujo2instancias retenidas al cierre; no se ha cambiado producción ni se usa ese resultado intermedio para declarar fuga resuelta en el juego.

## Revisión estática de entrega parcial09:31
Leí el aircraft.gd importado y el baseline de Claude. El test independiente conserva validez sin modificaciones. Los25fallos que ejecutó Agy son20comprobaciones de humo/mapeo y5de cazas; no hay fallos de pausa en esa salida. Hito todavía NOaceptado. Nueva checklist en CHECKLIST_REVISION_LOCAL_CODEX.md y plan/manifiesto de entrega en PLAN_ENTREGA_LOCAL_CODEX.md. Espero HITO1y ventana de archivos estables; no repetiré suite sobre entregas en escritura. No se exportó ni empaquetó nada.

## H05/H06 — prueba semántica independiente disponible (10:45:54 -07:00)
Se creó `tests/test_local_control_directions.gd`, sin modificar pruebas de Claude ni producción. Baseline ejecutada una vez sobre hashes estables de flight/player_controls/game, registrados antes/después en `logs/orquestacion/local-control-directions-baseline.json`.

Resultados reproducidos: salida1;80comprobaciones incumplidas(24de giro+56de alineación de fuego). D/RIGHT durante3s producen desplazamiento de112.10m hacia la izquierda y cambio de rumbo−54°, tanto en yaw inicial0como0.8. A/LEFT invierten igualmente el sentido. En60casos de yaw/aim/límites de pitch, desviación máxima disparo/cámara160.428° frente al criterio≤1.5°. Las pruebas usan teclado sintético y vectores reales, no equivalen a sesión humana. El log conserva además advertencia de2instancias ObjectDB al cierre; no declarada resuelta.

Agy puede usar la nueva prueba como contrato para corregir H05/H06 después de finalizar modelos/humo. No tocarla para forzar aprobación; si sospecha falso positivo, reportar evidencia al dueño. Baseline `logs/orquestacion/local-control-directions-baseline.log`.

## Solicitud de siguiente artefacto al supervisor
Necesito `HITO1_LISTO_PARA_REVISION.md` con hashes/archivos y ventana de noescritura para dictamen de modelos. A10:44 seguía faltando y el estado de Agy conservaba bloqueo de09:35. Tras reiniciarlo, confirmar recepción del primer pendiente(humo/cazas) y no repetir aircraft.gd ya aceptado. Quedo esperando esa dependencia y revisaré el candidato estable; no exportaré ni declararé release por la preparación.

## Revisión incremental autorizada10:56:35
UNAejecución de test_local_control_directions.gd tras cambios estables: PASS/código0. D/RIGHT ahora+112.10m y+54°; A/LEFT negativos.60casos de disparo/cámara con peorángulo0.000°(límite1.5°). Hashes antes/después iguales. Sin warningObjectDB en ESAejecución. Informe REVISION_LOCAL_CONTROL_DIRECTIONS.md y logs/…review-20261024T105635.{log,json}. No se cambió test ni producción. No se cierra hito por este PASS. Sigue faltando marcador para revisión final y posterior entrega/restauración LOCAL.

## QAfinal en curso11:00 — observación semántica del test manual de Claude
Modelos activos y las11primeras pruebas de la suite local pasaron sobre fuentes estables. test_claude_review pasó pero conservó warning4ObjectDB. La prueba manual está ejecutándose; inspeccioné su controlador sintético y aún contiene `hold(KEY_D, err>2°)` y `hold(KEY_A, err<−2°)` con comentario que asume D→yawpositivo. Tras H06corregido, D→yawnegativo(giroderecha) y A→yawpositivo. Si el testmanual falla en regreso, hay evidencia concreta de un controlador de prueba con signo anterior, no demostración automática de que el producto no se pueda pilotar. Claude debe revisar/actualizar SUprueba semánticamente y volver a demostrar misión; Codex no la modificará ni cerrará fase3hasta tener ese resultado. No se pide revertir H06correcto para satisfacer el testviejo.

## Resultado QAfinal y candidato local en preparación11:00–11:04
Ejecuté UNA suite de14pruebas pertinentes sobre hashes estables de TODOel proyecto(sin caché):13PASSy1FAILmanual. Modelos activos independientePASS; escena785.12s/hull55.3/60ráfagasPASS; controlesPASS; aceptaciónPASS. Manual llegóREGRESO,IMPACTO,sueltamanualtrue,1500s por controlador sintético de signo antiguo; el supervisor ya asigna enmienda semántica a Claude. MantengoFAILhasta repetición validada. test_claude_review advierte4ObjectDB y manual2ObjectDB; no ocultados. Informe logs/orquestacion/final-local-qa/report.json.

Se preparó staging versionado `release/local-20261024-acd6e3ddfc40/`, identificado por digest de producción. Fuente+motor portátil+lanzador, sin `.godot`;238archivos con hashes. Estado explícito `CANDIDATO_LOCAL_EN_REVISION_NO_ACEPTADO`. No exportador ni templates. La restauración con importación fría se está verificando en snapshots/restoration-local-20261024-acd6e3ddfc40/source. El testmanual del staging todavía es el anterior; se actualizará solo después de revisión/pasada por Claude, con manifiesto nuevo y evidencia.

**Para Claude/supervisor:** id de candidato propuesto `local-20261024-acd6e3ddfc40`; instrucciones en release/<id>/LEEME.md y .txt. Necesito dictamen visual integrado y nuevoPASSmanual sobre producción sin cambios para cerrar/restaurar artefacto final. No se etiqueta aceptado por la copia ni por13PASS.

## Bloqueantes de usabilidad manual11:06
Entregado REVISION_BOMBARDEO_MANUAL_CODEX.md con datos reales de escena/bomba: cruzNorden266.398m, bomba1329.505m, suelta al centrarobjetivoFALLOpor1061.824m; suelta balísticacontrolpositivoIMPACTOa1.283m. Objetivo óptimo fuera delviewport1280×720 y sincueexpuesto alusuario. Además cambioPILOTO→BOMBARDERO/ARTILLERO deja inputslatentes: D→−36°en2s,S→+9.87°,SHIFT→+16m/s ya sinteclaspulsadas. Fuentesestables y herramienta sinwarningsenúltimaejecución. Solicito contrato mínimo deayudasuelta+neutralizacióndeinputs aAgy/Qwen antes deaceptarjugabilidad; no exige rediseño/aterrizaje/autosuelta.

## Aclaración cold-import al supervisor
El verificador deimport NOexige TESTPASS: usa retorno0 y ausencia deSCRIPTERROR/ERROR. El primerintento realmente registró4ERRORdeTCP `_sock == -1`/ERR_CANT_CREATE al intentar elservidorlocaldeleditor dentrodelsandbox; logpreservado cold-import.sandbox-attempt.log. Se repitió importaciónfría con socketslocalesdisponibles ylognuevoen cold-import.log, retorno0/sinerrores. No fuefallodeGLB ni fuentes. Se siguenahora tests derecursos/escenarestaurados sobreestecache regenerado.

## Restauración y manualverificados11:08
Testmanualenmendado deClaude repetido una vez:PASS/código0 conproducciónestable. Staging ycopiaderestauración recibenese testsolo despuésdevalidarlo. Importfrío hostrc0/sinerrores, testmodelosrestauradosPASS, escenarestauradaPASS;fuentes delmanifiestointactas. Informe evidence/restoration/report.json verified=true. No se impuso TESTPASSalimportador; errororiginal erandeTCPlocaldel sandbox yquedópreservado. Todo sigue NOACEPTADOporU01/U02+visual+documentación. Informe consolidado INFORME_QA_LOCAL_CODEX.md. Si Agy corrigeproducción, generarnuevocandidatooidentidadrevisadayQAafectada,no reciclar evidenciadelcódigoanterior.

## Contrato temprano de prueba independiente U01/U02 (11:11)
Nueva prueba propietaria: `tests/test_local_bombing_usability.gd`. No modificar porAgy/Qwen. Consumirá `scene.overlay.data["bombing_aid"]` o `data` del widget real cuyo script sea `res://ui/bombing_cue.gd`(equivalencia a declarar). Campos release_now:bool,eta_seconds/lateral_error_m:númerosfinitos,status:String,predicted_impact:Vector3finito. El proveedor deHUD debe estar en escena/visible en la estación activa; la representación visual efectiva la revisaClaude conGPU.

El operador de prueba no calculará una fórmula de suelta: empezará4km antes del objetivo enmanual/BOMBARDERO, avanza vuelo y pulsaráSpace medianteInputEventKey SOLOcuando eldatoHUD release_now sea true. El modelo real debeIMPACTARen9casos(alturas1000/1200/1400m×velocidades70/85/100mps). El caso1200/85 es obligatorio. Datosse invalidarán sifuentes cambian enmitad. Casosfueraeje900m yobjetivo500myaatrás no permitenfalsepositive de release_now. Se comprobaráque la señal cambie a gastada despuésdeSpace; no se exige un texto/cámara históricos ni un diseño de UI concreto.

U02:seis casos D/S/SHIFT soltados físicamente antesde cambiar aARTILLERO/BOMBARDERO. Entradas quedan0inmediatamente ytras2s, sin36°/16mps de deriva; volverPILOTO debeleer teclaactual(p.ej.A) y luego0al soltarla. Los testsH05/H06existentes se conservarán. No significa ponerautopiloto automáticamente ni congelar física.

PrepararébaselineFAILesperada antesdeentrega, no repetiré duranteescritura. Releaseanterior sigue NOACEPTADOy no cubrirá fuentescorregidas; nuevo manif/freeze trasQA pertinente.

## Entrega real del test independiente U01/U02 (11:15)
Archivo `tests/test_local_bombing_usability.gd`, propietarioCodex, sintaxis válida. BaselineUNAvez, hashesestables: retorno1,30checksfallidosesperados(ayudaHUDaúninexistente+6latentes);9operadoresintentados,0impactosporfaltarproveedor. Sinwarnings/parseerrors enbaseline. Se comprueba disposiciónmanual/hardcodednoautoDrop conSpaceinjection; la ventana ydecisióndesuelta dependenexclusivamente `release_now` delHUD,no fórmulaoculta. Dos negativos(offaxis900,pasado500), campostipados/valoresfinitos/proveedorUIvisible, estadogastadainmediatamente,6transiciones yrelecturaactualalvolverPILOTO.

Se respeta dictamenparcial delsupervisor: modelosaceptados;H11S3conlimitaciónevidenciada,no nuevo bloqueo automático porwarningsconocidos. La nueva prueba no normalizawarnings ni altera otras; evidenciaíntegra. Espero ENTREGA_U01_U02_AGY para repetir solopruebaspertinentes yactualizarcandidato fuente+motor/restauración, noversión Windows.

## Observación sobre la prueba propia antes de ajustar
La comprobación de retorno aPILOTO del borrador exige raw `turn_input>0.5` al mantenerA. Eso coincide con producción actual pero fijaría innecesariamente un signo interno. Se reemplazará por `abs(turn_input)>0.5` MÁS verificación física de que el morro gira a la izquierda en el marco anterior del avión. Conserva/refuerza el comportamiento exigido sin imponer representación interna ni esconder los30fallosbaseline. Se preserva versión inicial de prueba/hashes en logs; no se repetirá baseline por este ajuste de fixture.
