# Encargo preparado; no enviado ni implementado

Objetivo: comprobar la capacidad del modelo local para producir GDScript correcto antes de darle la implementación del juego.

Modelo: qwen2.5-coder:7b-instruct-q4_K_M.
Requisito previo: motor y versión exacta fijados; aportar documentación de esa versión. Inferencia local comprobada. No descargar modelos automáticamente.

## Prompt para Qwen
Actúa como codificador del prototipo B-17. Implementa únicamente un Resource llamado FlightCommand en Godot 4, con GDScript tipado. Usa la versión exacta proporcionada por el orquestador. No uses Python, C# ni APIs de Godot 3.

Archivo permitido: res://flight/flight_command.gd. No modifiques el proyecto, las entradas, escenas, física ni cámaras.

Contrato: propiedades pitch, roll y yaw (float, valor inicial 0), throttle (float, inicial 0). Método sanitize() sin retorno que limite los tres primeros al intervalo [-1,1] y throttle a [0,1]. Para cualquier NaN o infinito, sustituye ese campo por 0 antes de limitarlo. No debe depender de nodos o recursos externos.

Entrega el contenido completo del único archivo y una explicación breve de cómo satisface el contrato. No añadas funcionalidades.

## Revisión del orquestador
- Comprobar sintaxis y carga con la versión fijada del motor.
- Verificar límites negativos/positivos, valores internos, NaN e infinitos.
- Confirmar que no se modifican otros archivos.
- Si falla, devolver el error exacto a Qwen; reducir o aclarar el encargo antes de cambiar de autor.
- Registrar tiempo, resultado, correcciones y autoría. Este resultado no valida todavía vuelo, combate ni rendimiento.
