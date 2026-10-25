# Meta de implementación — Cuatro mejoras de jugabilidad BAJO

El usuario autoriza crear esta meta e implementar las propuestas de baja complejidad. Dificultad significa complejidad técnica de implementación, no dificultad al jugar. Proyecto `/home/test-bench/Documents/B17-project/godot/B17`. Estas mejoras usan datos y HUD existentes, sin nuevos modelos, voces, música ni cambios a dificultad/daño/cadencia.

## 1.1.1.0 Selección autorizada

- **1.1.1.1 · BAJO — Avisos direccionales de amenaza.** Mostrar el caza vivo cercano más relevante dentro de 1500 m con posición de reloj respecto al rumbo del B-17, altura relativa (alto/nivel/bajo) y distancia redondeada. Ejemplo: «CAZA · 3 EN PUNTO · ALTO · 450 m». Si no hay amenaza no inventar contacto. Referencia del avión del jugador, aunque la cámara observe otro avión. Refrescar con datos reales sin nuevos avisos hablados repetidos.
- **1.1.1.2 · BAJO — Confirmación visual de impactos y derribos manuales.** Cuando una acción real del jugador dañe a un caza, mostrar brevemente «IMPACTO» y, al confirmar su destrucción, «DERRIBO CONFIRMADO». Vincular a la pérdida de salud y transición vivo/muerto del blanco del disparo manual. No premiar disparos fallados ni atribuir al jugador los derribos automáticos. Indicador discreto fuera de mira/subtítulos; sin modificar los WAV M2, la física del disparo o su daño.
- **1.1.1.3 · BAJO — Objetivo inmediato claro.** Una instrucción breve cambia según fase/puesto y estado real: mantener formación, vigilar/cubrir sectores, seguir rumbo, alinear mira, esperar ventana/suelta, observar impacto o regresar. Durante autopiloto explicitar la acción útil disponible del jugador. No repetir instrucciones que ya se completaron ni indicar soltar bombas tras gastar la carga. Aprovechar la ayuda de bombardeo existente, sin crear más pasos ni teclas obligatorias.
- **1.1.1.4 · BAJO — Resumen de misión más útil.** Ampliar el informe final existente con resultado real del bombardeo, derribos manuales y totales por separado, tiempo, estado del avión y causa comprobable del desenlace. No inventar porcentaje de precisión, supervivientes o estadísticas que la simulación no mida. Distinguir fallo de objetivo y pérdida del avión. Conservar reinicio y mensajes de fin de misión.

## 1.1.2.0 Orden y archivos

- **1.1.2.1** Completar primero el Lote 9 de 48 cazas. Su ejecutor Codex modifica `game.gd`, `core/player_controls.gd` y combate; no editar esos archivos simultáneamente. Mientras tanto se pueden preparar helpers/pruebas independientes. Leer `logs/lote9/LISTO.md` y su entrega real antes de tomar el relevo. No matar el ejecutor ni considerar una advertencia de prueba como entrega terminada.
- **1.1.2.2** Archivos previstos: nuevo `core/gameplay_hints.gd` para funciones puras de aviso/objetivo; cambios acotados en `core/player_controls.gd` para registrar resultado del disparo manual; `core/debrief.gd` para datos finales; `game.gd` para transferir estado al HUD y temporizadores; `ui/mission_overlay.gd` para representación. Mantener interfaces existentes con parámetros opcionales cuando haga falta.
- **1.1.2.3** Mantener las 48 unidades y contratos finales del Lote 9, las 5 alas detalladas, cámara orbital, flak denso, nubes OpenArt, niebla reducida, voces en-US de contexto 1945 con subtítulos españoles y partitura adaptativa. Los cinco WAV M2 validados deben conservar los hashes de `logs/audio_redesign/m2_protected_hashes.json`. No regenerar sonido ni usar indicadores de estilo arcade estridente.

## 1.1.3.0 Presentación y comportamiento

- **1.1.3.1** A 1280×720, texto legible de 18–20 px como mínimo, margen seguro 24 px. Amenaza junto a información de vuelo y objetivo en zona superior libre; impacto discreto próximo a la mira pero sin taparla. No superponer subtítulos, ayuda de cámara, panel de bombardeo o menús. Escalar a 1080p con el HUD existente. Ajustar mediante capturas, no solo medidas en código.
- **1.1.3.2** Pausa congela el tiempo del indicador de impacto y el estado de misión. Reinicio limpia contadores manuales, indicadores temporales y aviso de la escena anterior. Cambio de puesto/cámara no altera disparos, simulación ni progreso. Los avisos no generan nuevos enemigos, daños ni sonidos.

## 1.1.4.0 Aceptación y cierre

- **1.1.4.1** Pruebas significativas: relojes 12/3/6/9 con distintos rumbos; ausencia de contacto para muertos/lejanos; alto/nivel/bajo; disparo manual acertado/fallado/derribo; separar autoría automática; objetivos coherentes con cada puesto, bomba gastada y autopiloto; causa del informe final; pausa/reinicio de contadores e indicadores.
- **1.1.4.2** Regresión de cámara, controles, audio/subtítulos y combate vigente; hashes M2 intactos. Capturas reales 720p y comprobación de legibilidad en 1080p. No declarar prueba de mando físico o de Ally X sin dispositivo.
- **1.1.4.3** Guardar respaldo de archivos tocados en `logs/jugabilidad_bajo/backup/`, logs y `planning/orquestacion/ENTREGA_JUGABILIDAD_BAJO.md`. Cerrar únicamente el juego anterior del proyecto al integrar y abrir UNA instancia final en cámara exterior tras pasar las comprobaciones. Marcar la meta completada solo al lograr las cuatro mejoras y el cierre pendiente de los 48 cazas.
