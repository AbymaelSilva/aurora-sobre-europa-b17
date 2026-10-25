# Relevo de supervisión Claude → Agy (B17 «Aurora sobre Europa»)

> Borrador iniciado por Claude (supervisor), 2026-10-24 15:30, a petición del usuario: «comienza un md para que delegues tus tareas a Agy».
> **Estado: BORRADOR, todavía no activado.** Para activarlo hay que (1) decidir qué permisos se le amplían a Agy (sección 5) y (2) anteponer la sección 7 a `planning/META_AGY_COORDINADOR.md`.

## 1. Qué recibe Agy
El papel de **supervisor**: asignar tareas a Qwen, revisar cada entrega con evidencia, devolver lo que no cumple, mantener el tablero y registrar cada avance en la consola del supervisor. El supervisor **no programa producción**: solo hace parches mínimos de una línea con diagnóstico exacto y los registra.

## 2. Estado al relevo
### 2.1 Juego
- Paquete vigente: `release/local-20261024-e38081fc3fed`, con restauración en frío verificada:
  - V1 local completa;
  - perfiles de control Teclado y ratón / Mando Xbox / ROG Ally X;
  - confirmación de R;
  - `--probar-mando`;
  - audio sin integrar.
- Tablero: `planning/orquestacion/TABLERO.md`, con 16/20 puntos verificados. Pendientes: 1.1.5.1–1.1.5.3 (dependen de la partida humana) y 1.1.5.4 (después de la V1).
### 2.2 En curso: LOTE 5 (`planning/META_AGY_COORDINADOR.md`)
- **A, terreno T1**: hecho. `farmland.gdshader` /1200 y `farmland_t1.png` (con mipmaps activados e importada por el supervisor). **Pendiente:** que `game.gd` vuelva a `preload("res://assets/terrain/farmland_t1.png")` en vez de cargar el PNG en bruto con `Image.load_from_file` (esa carga no tiene mipmaps).
- **B, `audio/sfx_bank.gd`**: hecho (Qwen), con una corrección del supervisor. `loop_end = round(get_length() * mix_rate)`, porque los WAV se importan en QOA y `data.size()` no son muestras PCM. **No lo revertir.** `test_sfx_bank.gd` debe comprobar `loop_end == round(get_length() * mix_rate)`, no solo que sea mayor que 0.
- **C, integración de audio en `game.gd`**: en curso. Prueba `tests/test_audio_integration.gd`.
### 2.3 Otros frentes
- **Dashboard**: `tools_review/dashboard.sh`. Datos y proceso de Qwen; vista de Claude.
- **Audio**: 47 WAV verificados en `godot/B17/assets/audio/sfx/`. Falta la escucha humana.
- **Meshy**: PARADO tras 3 pilotos del B-17 (30 créditos; saldo 1165). **Decide el usuario.** No gastar.
- **OpenArt**: saldo 441. Gastar solo con encargo del usuario y la regla de pieza piloto (`planning/PRESUPUESTO_ARTE.md`).
- **Disco**: 94 %. No borrar nada sin autorización del usuario.

## 3. Protocolo de supervisión que Agy debe aplicar
### 3.1 Antes de encargar
- 3.1.1 Una tarea por archivo. Los archivos NUEVOS los escribe Qwen por el puente `encargar_qwen.py`, con una prueba escrita ANTES por quien supervisa. Los archivos existentes los cambia el supervisor con parches mínimos.
- 3.1.2 Los briefs para Qwen llevan firmas y cuerpos casi literales. Qwen falla de forma repetida con:
  - sintaxis de Python (`s[0:19]`, `len()`);
  - variables declaradas dos veces en la misma función;
  - clases inventadas (`set_window_title`);
  - cambiar `extends`;
  - maquetación de pantallas.

  Si falla 3 rondas con el brief reducido, la implementación pasa a otro modelo.
- 3.1.3 Nunca pedir a Qwen que regenere un archivo existente grande: lo reescribe entero y rompe cosas (S3 de mission_overlay, 24-10, revertido).
### 3.2 Al revisar una entrega
- 3.2.1 Leer el diff completo, no solo el resultado de las pruebas.
- 3.2.2 Ejecutar UNO MISMO la prueba nueva y la regresión completa (lista en la META), con los hashes de producción antes y después, y la configuración del jugador `user://b17_settings.cfg` sin cambios.
- 3.2.3 Desconfiar de las pruebas que no recorren el camino real:
  - llamar a `handle_input` en vez de `Input.parse_input_event`;
  - lambdas que asignan variables locales (en GDScript se capturan por valor);
  - comprobar `> 0` en vez del valor esperado.
- 3.2.4 Lo visual no se acepta sin captura con GPU. Lo que se prueba sin ventana no es una revisión visual.
- 3.2.5 Registrar el dictamen en `logs/orquestacion/supervisor.log` con el formato `[ISO] [SUPERVISOR] [ETIQUETA] ESTADO | detalle | evidencia=ruta` y actualizar el TABLERO.
### 3.3 Herramientas del supervisor (en `tools_review/`)
- `menu_navigation_claude.gd`, `gamepad_gunner_claude.gd`: entrada real de teclado y mando.
- `capture_mission_claude.gd` (en tests/), `capture_profiles_claude.gd`, `terrain_preview_claude.gd`, `dashboard_capture_claude.gd`, `wm_close_leak_claude.gd`, `perf_local_claude.gd`: GPU.
- `build_candidate_claude.py`: paquete y restauración en frío, con reintento ante el abort intermitente de Godot al importar.

## 4. Lo que Agy PUEDE asumir ya, con los permisos actuales
- 4.1 Encargar a Qwen por el puente y revisar sus diffs.
- 4.2 Escribir pruebas y ejecutar pruebas sin ventana: `tools/godot --headless --path …/godot/B17 --script res://tests/<x>.gd`, con ruta absoluta.
- 4.3 Parches mínimos en archivos existentes, mantener TABLERO.md, supervisor.log, AGY_AVANCE y los encargos.
- 4.4 Devolver entregas con un diagnóstico exacto.

## 5. Lo que Agy NO puede hacer hoy (decisión del usuario)
Su regla de permisos (`~/.gemini/antigravity-cli/settings.json`) solo autoriza el puente y Godot sin ventana. Hoy se le deniegan:
- 5.1 Capturas con GPU (Godot con ventana): revisión visual de terreno, HUD, menú y aviones.
- 5.2 `tools/godot --headless --import`, necesario tras añadir o cambiar recursos.
- 5.3 `python3 tools_review/build_candidate_claude.py`: paquetes y restauración.
- 5.4 Abrir terminales (xfce4-terminal), lanzar otras instancias de Claude (audio, Meshy) o el dashboard.
- 5.5 Comprobar hashes (sha256sum, python3 -c), git o ls.

Opciones:
- (a) ampliar la regla con órdenes literales concretas, por ejemplo `command(/home/test-bench/Documents/B17-project/tools/godot --path /home/test-bench/Documents/B17-project/godot/B17)` o `command(python3 -I /home/test-bench/Documents/B17-project/tools_review/build_candidate_claude.py)`;
- (b) dejar esas tareas a Claude o al usuario y que Agy las pida por escrito en `planning/orquestacion/PETICIONES_AGY.md`.

**Claude no amplía permisos por su cuenta.**

## 6. Lo que sigue siendo del usuario
- Probar el mando real: `./INICIAR_B17.sh --probar-mando` y una partida con perfil Xbox o Ally X.
- La partida humana de la misión (1.1.3.1).
- Decidir sobre Meshy y sobre el borrado de los paquetes superados.
- Escuchar el set de audio.

## 7. Bloque para anteponer a la META de Agy al activar el relevo
```
# Agy es ahora SUPERVISOR (relevo de Claude). Lee planning/orquestacion/RELEVO_SUPERVISOR_AGY.md entero antes de actuar.
Primero cierra el LOTE 5 como supervisor (sección 2.2): parche preload de farmland_t1, prueba de loop_end exacta y regresión completa.
Todo lo de la sección 5 lo pides por escrito en planning/orquestacion/PETICIONES_AGY.md; no lo intentes (se deniega y detiene la ronda).
Registra cada dictamen en logs/orquestacion/supervisor.log con la etiqueta [SUPERVISOR-AGY].
```
