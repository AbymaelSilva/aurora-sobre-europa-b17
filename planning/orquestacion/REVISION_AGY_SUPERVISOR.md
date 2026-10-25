# Revisión del supervisor — contrato Agy
Estado: DEVUELTO para enmienda documental; no ejecutar código.

El contrato cubre los puntos y reconoce evidencia histórica correctamente. Debe corregirse antes de aceptarlo:
1. No ampliar misión con despegue/aterrizaje: comienza en vuelo y completa al alcanzar zona segura. La prueba manual con entradas no demuestra por sí sola una sesión humana.
2. Derivar posiciones de humo/rotores de los nodos del GLB integrado. Los offsets del avión procedural no acreditan alineación con el nuevo modelo.
3. Tratar FPS/perfiles/resoluciones como matriz de ensayo PROPUESTA, no compromisos aprobados ni especificaciones comprobadas. Separar tasa física30/60/120Hz de FPS reales de render. No prometer60FPS en Ally.
4. Vincular hash del EXE, fuente y recursos mediante manifiesto del candidato; no exigir que los hashes de artefactos distintos sean iguales.
5. Godot no se valida con afirmaciones genéricas sobre un recolector de basura. Medir allocations/objetos/tiempos si es pertinente, y documentar límites de evidencia.
6. Precisar que godot-art.lock serializa inferencia Qwen; no es un bloqueo automático de ediciones/materiales de Claude. La propiedad de archivos se coordina en tablero.

Entregar ENMIENDA_AGY.md, con estas seis aclaraciones vinculadas a los puntos. Mantener ENTREGA_AGY.md como registro original y no tocar código ni tests. El supervisor decide aceptación tras revisar la enmienda.
