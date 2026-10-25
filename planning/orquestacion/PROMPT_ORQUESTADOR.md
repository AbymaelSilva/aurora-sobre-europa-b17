# Prompt técnico activo — Orquestación de V1 LOCAL

> [!IMPORTANT]
> **Invocación del agente / supervisor Agy:**
> ```bash
> agy --dangerously-skip-permissions --mode auto -p "$(cat mis_tareas_prompt.txt)"
> ```
> **Regla de Ejecución Autónoma Obligatoria:** Todos los documentos MD técnicos y directivas (presentes y subsecuentes) deben incluir en su encabezado la orden de ejecución:
> `agy --dangerously-skip-permissions --mode auto -p "$(cat <ruta_al_archivo>.md)"`

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
