# Encargo Agy — Resolución autónoma de pendientes y exportación ASUS ROG Ally

> [!IMPORTANT]
> **ORDEN DE EJECUCIÓN AUTÓNOMA DIRECTA:**
> ```bash
> agy --dangerously-skip-permissions --mode auto -p "$(cat planning/orquestacion/PROMPT_AGY_RESOLVER_PENDIENTES_Y_ROG_ALLY.md)"
> ```

Fecha: 2026-10-24
Motor: Godot 4.7.2.stable.official.ed1daf0bf (`tools/godot`)
Destino: Proyecto `/home/test-bench/Documents/B17-project/godot/B17`
Objetivo: Completar mejoras de jugabilidad pendientes y compilar versión portable para ASUS ROG Ally / Windows Desktop x86_64.

---

## 1.1.1.0 Alcance y Prioridades

- **1.1.1.1** Eres Agy en modo autónomo. Tu misión es tomar los pendientes del proyecto, completarlos sin bloquearte por dependencias externas y generar la exportación final para ASUS ROG Ally.
- **1.1.1.2** El motor es única y exclusivamente Godot 4.7.2. No utilizar ni instalar Unity. No tocar prototipos ni snapshots.
- **1.1.1.3** Preservar los 5 WAV de la ametralladora Browning M2 (`logs/audio_redesign/m2_protected_hashes.json`). Son inmutables.
- **1.1.1.4** Preservar los contratos ya verificados del Lote 9: 48 cazas enemigos (24 Bf 109G / 24 Fw 190A), 16 P-51D de escolta, formación masiva de 300 B-17, cámara orbital/exterior, flak calibrado, 100 nubes y banco de audio.

---

## 1.1.2.0 Tarea 1: Finalizar e Integrar las Cuatro Mejoras de Jugabilidad (BAJO)

Tomando la lógica ya testeada en `core/gameplay_hints.gd`:
1. **Avisos direccionales de amenaza en reloj:** Mostrar en el HUD la amenaza más cercana dentro de 1500 m (ejemplo: «CAZA · 3 EN PUNTO · ALTO · 450 m»).
2. **Confirmación visual de impactos y derribos:** Mostrar discretamente «IMPACTO» y «DERRIBO CONFIRMADO» al conectar disparos manuales del jugador.
3. **Objetivo inmediato contextual:** Mostrar en HUD la acción táctica recomendada según fase y estación (mantener formación, vigilar sector, soltar bombas, etc.).
4. **Resumen de misión enriquecido:** En `core/debrief.gd` y la pantalla final, separar derribos manuales vs automáticos y estado del avión/bombardeo.
5. **Verificación:** Ejecutar la suite de tests (`test_gameplay_hints.gd`, `test_player_feedback.gd` y tests de escena). Guardar señal `logs/jugabilidad_bajo/TERMINADO_Y_JUEGO_ABIERTO.json` con `{"complete": true}` y redactar `planning/orquestacion/ENTREGA_JUGABILIDAD_BAJO.md`.

---

## 1.1.3.0 Tarea 2: Compilación y Exportación para ASUS ROG Ally (Windows Desktop)

1. **Preset de Exportación:**
   - Inspeccionar `godot/B17/export_presets.cfg`.
   - Asegurar que `include_filter` incluya `*.json` para que los catálogos de diálogos y música (`assets/audio/voice/dialogue_catalog.json` y `assets/audio/music/music_catalog.json`) se empaqueten dentro del PCK.
   - Respaldo de `export_presets.cfg` antes de editar.
2. **Plantillas de Exportación:**
   - Verificar la presencia de las plantillas oficiales en `~/.local/share/godot/export_templates/4.7.2.stable/` (`windows_release_x86_64.exe`).
3. **Compilación:**
   - Crear directorio nuevo con marca de tiempo: `builds/rog_ally/<timestamp>/`.
   - Exportar con:
     ```bash
     tools/godot --headless --path godot/B17 --export-release "Windows Desktop" "$PWD/builds/rog_ally/<timestamp>/AuroraSobreEuropa.exe"
     ```
   - Verificar que el binario generado existe, tiene cabecera PE válida y tamaño acorde (>100 MB empaquetado).
4. **Empaquetado y Distribución Portable:**
   - Generar archivo comprimido `AuroraSobreEuropa_ROG_ALLY_<timestamp>.zip`.
   - Generar `SHA256SUMS.txt` con los hashes del ejecutable y archivos acompañantes.
   - Incluir `LEEME_ROG_ALLY.md` con instrucciones de mapeo de controles para ROG Ally / Ally X (mando Xbox), selector de resolución 720p/1080p y créditos de recursos.
   - Registrar la entrega en `planning/orquestacion/ENTREGA_ROG_ALLY.md` y actualizar `planning/orquestacion/TABLERO.md`.
