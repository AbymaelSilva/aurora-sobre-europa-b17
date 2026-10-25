# Cámara orbital integrada

Se cerró el juego anterior y el ejecutor Agy Lote 8 para evitar escrituras simultáneas; Codex completó la integración del controlador de cámara en game.gd y entrada de mando/ratón. Se registraron los cinco compañeros y dieciséis escoltas: 22 objetivos contando el propio avión. La flota MultiMesh no se recorre individualmente. Se preservaron nubes, niebla reducida y M2.

Mando: Y cambia exterior/puesto; stick derecho orbita; R3 centra; LB+cruceta arriba/abajo zoom; LB+izquierda/derecha cambia avión. Cruceta sin LB conserva cambio de puestos. Teclado: V alterna; botón derecho+ratón orbita; rueda zoom; C centra; [ y ] cambian avión. Observar otro avión activa autopiloto. Exterior manual tiene prioridad sobre cámara automática de bomba. Cambiar de puesto devuelve cámara del puesto. Pausa/foco perdido limpian arrastre y reinicio limpia cámara. Se ocultan miras en exterior.

Pruebas: test_orbit_camera, test_orbit_integration, test_local_control_directions y test_audio_integration pasaron. Prueba GPU de integración pasó y dejó captura logs/lote8/camera_companion.png, revisada visualmente. Las pruebas headless de integración conservan advertencias de recursos retenidos al salir; la ejecución GPU de la prueba terminó sin esos avisos. No se probó un mando físico ni Ally X.

Juego iniciado con --camera-exterior; PID y log en logs/lote8/. El flak ampliado continúa pendiente y no se declara terminado el Lote 8 completo.

Se lanzó por petición del usuario un Codex independiente en terminal visible para reemplazar 42 efectos; los 5 archivos M2 están protegidos con hashes y no puede editar cámara/juego ni abrir otra ventana. Prompt actualizado: planning/orquestacion/PROMPT_AUDIO_REALISTA_B17.md; log: logs/audio_redesign/codex.log.
