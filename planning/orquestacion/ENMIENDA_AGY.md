# Enmienda Técnica — AGY (QA y Coordinación Qwen)

En respuesta a la revisión documental emitida por el supervisor (`planning/orquestacion/REVISION_AGY_SUPERVISOR.md`), AGY formula las siguientes seis correcciones técnicas a su contrato original (`planning/orquestacion/ENTREGA_AGY.md`), el cual se preserva intacto como registro histórico:

### 1. Alcance de misión y naturaleza de pruebas de entrada (Puntos 3.3 y 3.4)
Se delimita formalmente el alcance de la misión: inicia en vuelo estabilizado y finaliza al alcanzar la zona segura designada tras el bombardeo; no comprende secuencias de despegue ni aterrizaje. Asimismo, se rectifica que la inyección programática de eventos de teclado mediante `Input.parse_input_event` constituye una prueba de entradas sintéticas para verificar la máquina de estados y la respuesta del bucle de control, no una demostración ni certificación de una sesión humana real.

### 2. Posiciones derivadas del modelo GLB integrado (Puntos 3.2 y 3.5)
Se descarta el uso de coordenadas fijas heredadas del fuselaje procedural (`[-9.4, -4.4, 4.4, 9.4]`). Las posiciones de anclaje de las estelas de humo, escapes y rotores se derivarán dinámicamente de la jerarquía de nodos y transformadas del modelo integrado `b17g.glb`, asegurando alineación geométrica verificable con la malla 3D final.

### 3. Matriz de ensayo de FPS y desacoplamiento de física (Puntos 3.6 y 4)
Los perfiles de energía, resoluciones y valores de FPS descritos se definen estrictamente como una matriz de ensayo propuesta para captura de datos empíricos, no como compromisos contractuales garantizados ni especificaciones comprobadas. Queda explícitamente descartada cualquier promesa de 60 FPS en ASUS ROG Ally X. Se separa conceptual y técnicamente la tasa física de simulación (`physics_ticks_per_second` a 30, 60 o 120 Hz) del framerate real de renderizado (FPS variables según carga de GPU/CPU).

### 4. Trazabilidad por manifiesto de candidato y hashes distintos (Puntos 3.7 y 4)
Se corrige la formulación sobre hashes. El ejecutable Windows, el paquete de recursos y el árbol de fuentes poseen estructuras binarias disímiles y por ende hashes SHA256 distintos; no se exige que sean iguales. La integridad y correspondencia se garantizarán mediante un manifiesto del candidato que registrará y vinculará los hashes específicos de cada componente probado.

### 5. Métricas observables de memoria sin hipótesis sobre GC (Punto 4)
Se suprimen las referencias genéricas a pausas por recolector de basura (GC), incompatibles con el modelo de memoria de Godot (basado en conteo de referencias para `RefCounted` y desasignación explícita para `Object`). La auditoría técnica se ceñirá a mediciones concretas y reproducibles de `Performance` (`ObjectDB` instances, memoria estática asignada y tiempos de frame), documentando con rigor los límites de la evidencia recabada.

### 6. Alcance de `godot-art.lock` y coordinación de archivos (Punto 2.2)
Se aclara que `godot-art.lock` es una guarda operativa destinada exclusivamente a serializar las invocaciones de inferencia local de Qwen para evitar inanición de recursos y colisiones concurrentes. No es un bloqueo automático ni excluyente sobre las ediciones de escenas o materiales a cargo de Claude. La titularidad y propiedad de archivos modificables se gobierna y coordina formalmente a través del `TABLERO.md`.

---
*Esta enmienda se somete a la consideración del Supervisor técnico para su revisión y eventual aprobación.*
