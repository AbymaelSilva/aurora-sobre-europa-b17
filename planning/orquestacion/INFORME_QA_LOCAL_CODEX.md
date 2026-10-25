# Informe QA y restauración — Codex Entrega LOCAL

## Revisión ejecutada sobre producción estable
Suite pertinente de14pruebas, sin cambios de fuentes durante la ejecución(antes/después completos en logs/orquestacion/final-local-qa/). Trece pasaron; testmanual deClaude fallóporconvención de giro anterior y llegóREGRESO/IMPACTO/sueltamanualtrue a1500s. No se ocultó eseFAIL.

Tras enmienda semántica revisada por supervisor y Claude(conservar entradas reales, invertir selector conforme H06 y reforzar IMPACTO/hull>0), repetí SOLOtestmanual: PASS/código0 sobre hashes estables. Log `manual-after-semantic-amendment.log/json`. Las13pruebas restantes no se repitieron sin cambios de producción. La suite cubre modelos activos, recursos, formación, VFX/audio, combate, controles, misión larga, escena, dirección de control, revisiónClaude y aceptación.

Advertencias conservadas: test_claude_review originaldio4ObjectDB; testmanualantiguodio2ObjectDB. La repetición manualenmendada no advierte fugas. Las pruebas independientes de modelos/controles y escena restaurada no mostraron errores ni warnings. No extrapolar esto a ausencia absoluta de fuga en todo flujo de salida; Claude debe dictaminar el warning de SUprueba de revisión.

## Candidato y respaldo/restauración efectivos
ID propuesto: `local-20261024-acd6e3ddfc40`.
- Staging: `release/<id>/source/`:238archivos(manifiesto por archivo), proyecto completo+motor portátil+lanzador, sin caché `.godot`.
- Prueba manualenmendada copiada a staging y restauración solo trasvalidación; MANIFEST_STAGING actualizado, evidencia delFAILanterior preservada.
- Copia restaurada: `snapshots/restoration-<id>/source/`.
- Hashes de copia coinciden con manifiesto antes de importar.
- Importación fría real de GLB/texturas y apertura del editor portátil realizadas sobre la restauración. Primer intento en sandbox registró errores reales de sockets locales deleditor; se preservó el log y repitió con sockets disponibles tras borrar SOLOelcache de la copia restaurada. No se exigía TESTPASSalimportador; se exigía rc0/sinerrores.
- En el entorno restaurado/reimportado: testindependiente de modelosPASS y misión de escena completaPASS, rc0ambos. No se asumió que copiar fuentes sin caché equivaliera a arrancar.
- Los hashes fuente del respaldo permanecieron iguales después de reimportar/testear. Informe `release/<id>/evidence/restoration/report.json`, verified=true, hora11:08:25-07:00.

El respaldo es local en el mismo disco, no protección acreditada frente a fallo del disco. El motor original se copió y hasheó; no hizo falta exportador ni plantilla Linux. El lanzador restaurado `--check` pasó; un chequeo de rutas no equivale al arranque GPU, que debe cubrir la revisión visual de Claude.

## Bloqueo de aceptación restante
El artefacto está etiquetado **CANDIDATO_LOCAL_EN_REVISION_NO_ACEPTADO**. No es juego final ni “estable” porque se descubrieron problemas de usabilidad U01/U02(REVISION_BOMBARDEO_MANUAL_CODEX.md): mira de suelta sin solución visible válida y entradaslatentes al cambiar puesto. Requieren decisión/corrección Agy/Qwen y una nueva revisión de lo afectado. Si cambia producción, este id y hashes sirven como rollback anterior; no cubren el código nuevo.

También falta dictamen visual integrado de Claude y LEEME del candidato correcto. El supervisor puede adoptar el id o fijarotro al cerrar. No se publica ni exporta nada.
