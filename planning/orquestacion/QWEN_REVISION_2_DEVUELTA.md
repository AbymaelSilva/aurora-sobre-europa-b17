**CONTRATO DE PLANIFICACIÓN TÉCNICA**

**1. INTRODUCCIÓN**

Este contrato define las tareas y responsabilidades para la planificación y ejecución de proyectos técnicos en el entorno de Godot. El objetivo es asegurar la creación y mantenimiento de modelos y escenas de manera eficiente y precisa, utilizando los recursos disponibles y cumpliendo con los estándares establecidos.

**2. OBJETIVOS**

El objetivo principal es crear y mantener modelos y escenas en Godot, utilizando los recursos disponibles y cumpliendo con los estándares establecidos. Se requiere la creación de modelos y escenas que ya existen, sin la necesidad de recrearlos desde cero.

**3. TAREAS Y RESPONSABILIDADES**

**3.1 aircraft.gd**

- **Descripción:** Carga el archivo b17g.glb y conserva el hijo Engines pausable, 4Rotor_* y dimensiones de 31.62m±3%;-Z.
- **Interfaces:** test_aircraft_models_claude y test_claude_review.
- **Dependencias:** N/A
- **Test/Ruta de Aceptación:** test_aircraft_models_claude y test_claude_review.

**3.2 formation.gd**

- **Descripción:** Reutiliza aircraft.gd para crear una formación de 5 wingmen + líder, con slots, left/right, pausa y reset.
- **Interfaces:** test_formation_six.
- **Dependencias:** aircraft.gd
- **Test/Ruta de Aceptación:** test_formation_six.

**3.3 visuals/fighter.gd**

- **Descripción:** Instancia los modelos bf109g y fw190a ya existentes, conservando el rotor como Node3D y ajustando la escala a 9.92/10.51m±3%.
- **Interfaces:** test_claude_batch y test_aircraft_models_claude.
- **Dependencias:** N/A
- **Test/Ruta de Aceptación:** test_claude_batch y test_aircraft_models_claude.

**3.4 visuales/audio existentes**

- **Descripción:** Mantener los contratos trigger/advance/reset de flak y fire/advance/reset de trazadoras, sin recrearlos.
- **Interfaces:** tests assets/combat_sfx/release_acceptance.
- **Dependencias:** N/A
- **Test/Ruta de Aceptación:** tests assets/combat_sfx/release_acceptance.

**3.5 Corrección de hallazgos identificados por Claude**

- **Descripción:** Corregir los hallazgos identificados por Claude, con captura antes/después y prueba.
- **Interfaces:** N/A
- **Dependencias:** N/A
- **Test/Ruta de Aceptación:** N/A

**3.6 Medición real del destino**

- **Descripción:** Dependiendo de la medición real del destino, proponer FPS/frametime/memoria, resolución/energía/control.
- **Interfaces:** N/A
- **Dependencias:** N/A
- **Test/Ruta de Aceptación:** N/A

**3.7 Reproducción y parcheQwen**

- **Descripción:** Dependiendo del reporte real de hardware, reproducir y parchear el caso.
- **Interfaces:** N/A
- **Dependencias:** N/A
- **Test/Ruta de Aceptación:** N/A

**4. CRITERIOS DE ACEPTACIÓN**

- Todos los modelos y escenas deben ser creados y mantenidos de manera precisa y eficiente.
- Todos los tests y rutas de aceptación deben ser cumplidos con éxito.
- Todos los hallazgos identificados por Claude deben ser corregidos con pruebas antes/después.
- La medición real del destino debe proporcionar FPS/frametime/memoria, resolución/energía/control.
- El caso debe ser reproducido y parchado según el reporte real de hardware.

**5. FECHAS DE ENTREGA**

- La entrega de todos los modelos y escenas debe realizarse dentro de los plazos establecidos en el contrato.

**6. RECURSOS**

- Se utilizarán los recursos disponibles en el entorno de Godot para la creación y mantenimiento de los modelos y escenas.

**7. RESPONSABILIDADES**

- El proveedor será responsable de la creación y mantenimiento de los modelos y escenas de manera precisa y eficiente.
- El proveedor será responsable de cumplir con todos los tests y rutas de aceptación.
- El proveedor será responsable de corregir los hallazgos identificados por Claude con pruebas antes/después.
- El proveedor será responsable de proporcionar la medición real del destino y reproducir y parchar el caso según el reporte real de hardware.

**8. TERMINACIÓN**

- El contrato se terminará cuando se hayan cumplido todos los plazos establecidos y se hayan cumplido todos los tests y rutas de aceptación.

**9. APROBACIÓN**

- Este contrato ha sido aprobado por el supervisor y está listo para su ejecución.

**10. FIRMAS**

- [Firma del proveedor]
- [Firma del supervisor]
