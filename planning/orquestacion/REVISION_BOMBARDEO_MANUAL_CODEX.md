# Revisión de usabilidad — bombardeo manual y cambio de puesto

**Hora/evidencia:** 2026-10-24T11:06:06-07:00, fuentes estables antes/después. Diagnóstico ejecutado sobre la escena actual en modo headless con viewport1280×720. No es una sesión humana ni revisión de pixels GPU. No se modificó producción. Herramienta propia: `tools_review/review_manual_bombing_codex.gd`.

## Dictamen para V1 LOCAL
Dos problemas medibles afectan el uso manual aunque la misión del controlador sintético pueda completar el recorrido. Se recomienda resolverlos antes del cierre “jugable para el usuario”; no basta el PASS del robot manual.

### U-01 — La cruz Norden no indica la suelta balística y falta una ayuda visible equivalente

Caso real reproducido: vuelo horizontal a1200m,85m/s, cámara BOMBARDERO en(0,1199.2,−11.5), dirección(0,−0.978148,−0.207912), inclinación−78°.

| Medida | Resultado |
|---|---:|
|Punto del suelo bajo el centro de la mira|266.398m delante del avión|
|Tiempo analítico de caída desde el avión|15.641s|
|Avance horizontal previsto de la bomba|1329.505m|
|Diferencia cruz/impacto previsto|1063.107m|
|Radio de acierto usado por el modelo real|120m|

No se concluye solo a partir de una fórmula: se colocó el avión de forma que el objetivo ferroviario real quedara en el centro de la cámara, se soltó la bomba mediante `sim.release_bomb()` y se hizo avanzar `bomb_model.gd` hasta impacto. Resultado **FALLO**, distancia horizontal al objetivo **1061.824m**, caída15.633s. Es una suelta aproximadamente12.5s demasiado tarde para ese caso.

Control positivo: al soltar en la solución balística, el mismo modelo real da **IMPACTO**, error1.283m. En ese instante, el objetivo se proyecta a(640,−46.089) en viewport1280×720, fuera de la imagen superior. Por tanto “centrar la estación en la cruz y soltar” no ofrece una solución intuitiva válida en el caso por defecto.

La interfaz inspeccionada solo recibe distancia, fase y estado de bomba; `mission_overlay.gd` muestra “PREPARADOS PARA LA SUELTA” de forma general durante BOMBARDEO. No hay señal de momento de suelta vinculada al impacto previsto, cuenta de aproximación o marcador balístico observable equivalente. El test manual de Claude obtiene la predicción mediante cálculo interno que el usuario no recibe: ese PASS demuestra alcanzabilidad técnica, no que el usuario tenga la información necesaria.

**Corrección mínima recomendada, sin rediseñar avión/campaña:** proporcionar una ayuda de bombardeo visible y coherente con el modelo existente: marcador de impacto previsto o una señal inequívoca de suelta/adelanto y alineación que permita acertar sin conocer el cálculo oculto. No se exige mover la cámara a un ángulo histórico ni automatizar la suelta. Si se mantiene la cruz geométrica, la UI/instrucciones deben distinguirla de la ayuda de suelta; no presentar como solución una marca decorativa.

**Aceptación propuesta:** el caso1200m/85m/s permite al operador sintético utilizar la misma señal/dato expuesto en HUD, pulsar la tecla manual y obtener IMPACTO sin leer su propia fórmula balística oculta. Verificar también variaciones razonables de velocidad/altura y que la señal no dé “soltar” si está fuera de eje. Conservar intervención manual y prueba posterior de usuario/capturas; no sustituirla con un cambio de texto fijo.

### U-02 — Entradas de vuelo quedan latentes al salir del puesto PILOTO

Se pulsó una tecla en PILOTO durante un paso, se soltó físicamente mediante un nuevo `InputEventKey`, se cambió a BOMBARDERO o ARTILLERO y se avanzó2s sin mantener ninguna tecla. En los dos puestos se conserva el último valor de input porque `set_station()` solo cambia `station` y `poll_inputs()` no neutraliza los campos de vuelo fuera de PILOTO.

| Última tecla ya soltada | Campo que permanece | Efecto adicional en2s |
|---|---|---:|
|D|turn_input=−1|yaw−0.6283rad(−36°)|
|S|pitch_input=+1|pitch+0.1722rad(+9.87°)|
|SHIFT|throttle_input=+1|velocidad+16m/s|

Son6casos reproducidos(3entradas×2puestos), con los mismos valores persistentes tras2s. La deriva del avión dificulta apuntar/suprimir cazas incluso después de soltar la tecla.

**Corrección mínima recomendada:** al abandonar PILOTO, neutralizar los comandos de vuelo manual que ya no están bajo control del puesto activo. Conservar heading/estado físico razonable y no cambiar arbitrariamente el modo manual/autopiloto elegido por el usuario. Al volver a PILOTO, leer el teclado actual, sin recuperar valores históricos.

**Aceptación propuesta:** repetir estos6casos. Los inputslatentes son0al cambiar puesto y siguen0sin teclas nuevas; el avión no continúa girando/acelerando por una tecla ya soltada. Una leve estabilización del cabeceo físico existente se distingue de seguir aplicando un comando sostenido. Pausa/reset y demo/manual conservan sus contratos.

## Evidencias y límites
- Datos completos: `logs/orquestacion/manual-bombing-usability.log`.
- Hashes antes/después y estabilidad: `.json` contiguo.
- La primera versión de la herramienta reutilizó el objeto de entrada y produjo una advertencia de test; se corrigió en la herramienta del revisor creando un nuevo evento. Ese intento quedó preservado en `.initial-tool-warning.log`. La ejecución final limpia reproduce los mismos problemas; no se atribuye esa advertencia inicial al juego.
- No hay nuevo test de aceptación formal que imponga una solución de UI específica: primero el supervisor fija el contrato mínimo y Agy/Qwen implementan; el revisor medirá el resultado de forma independiente.
- El staging `local-20261024-acd6e3ddfc40` sigue NOACEPTADO. Si se corrige producción, necesita id/manifiesto y QA afectados actualizados; no conservar la etiqueta como si la evidencia antigua cubriera los cambios.
