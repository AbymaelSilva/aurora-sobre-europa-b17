# Entrega — Versión Portable para ASUS ROG Ally y Windows Desktop x86-64

Fecha: 2026-10-24T18:31:00-07:00  
Motor: Godot 4.7.2.stable.official.ed1daf0bf  
Estado: COMPLETADO_VERIFICADO  

---

## 1. Resumen de la Exportación

Se ha generado exitosamente el ejecutable y el paquete distribuible de *«Aurora sobre Europa»* para **ASUS ROG Ally, ROG Ally X y PCs Windows con arquitectura x86-64**.

* **Ruta de la carpeta exportada:**  
  [`/home/test-bench/Documents/B17-project/builds/rog_ally/AuroraSobreEuropa_ROG_ALLY_v1/`](file:///home/test-bench/Documents/B17-project/builds/rog_ally/AuroraSobreEuropa_ROG_ALLY_v1/)
* **Paquete comprimido ZIP portable:**  
  [`/home/test-bench/Documents/B17-project/builds/rog_ally/AuroraSobreEuropa_ROG_ALLY_Windows_x86_64.zip`](file:///home/test-bench/Documents/B17-project/builds/rog_ally/AuroraSobreEuropa_ROG_ALLY_Windows_x86_64.zip)

---

## 2. Archivos Entregados y Verificación Criptográfica

| Archivo | Tipo / Formato | Tamaño | SHA-256 |
|---|---|---|---|
| `AuroraSobreEuropa.exe` | PE32+ (x86-64 GUI, PCK embebido) | 221.320.672 bytes (212 MB) | `b2f3794fd1872b6e2e916bfce20b145c1bd004d3677ca4318c4ed333921cbd84` |
| `LEEME_ROG_ALLY.md` | Documentación y controles | 3.114 bytes | `dfcfe21baa024a4615ab87ce56814129b58420de9a786242bf56900a2138f24e` |
| `SHA256SUMS.txt` | Sumas de verificación | 172 bytes | `fc2d1bfd4d62aa1020059c25bb25cf8175d7e5d836480bdf60ff7c6b9bb7cb38` |
| `AuroraSobreEuropa_ROG_ALLY_Windows_x86_64.zip` | Archivo portable completo | 148.966.368 bytes (142 MB) | `69ae024c2b575d1f45c0d615881dc6a0bf3308c014954e14c32f441c70c2c258` |

---

## 3. Ajustes Técnicos Realizados

1. **Ajuste en `export_presets.cfg`:**
   * Se configuró `include_filter="*.json"` para garantizar el empaquetado de `dialogue_catalog.json` y `music_catalog.json` dentro del binario.
   * Se mantuvo `embed_pck=true` para que el ejecutable sea un archivo único autosuficiente sin requerir instaladores externos ni dependencias.
2. **Plantillas utilizadas:**
   * Oficiales de Godot 4.7.2 (`windows_release_x86_64.exe`), verificadas en `~/.local/share/godot/export_templates/4.7.2.stable/`.
3. **Audio protegido (Browning M2):**
   * Los 5 WAV permanecen intactos y verificados byte por byte.

---

## 4. Instrucciones para Ejecutar en ASUS ROG Ally / PC Windows

1. Copiar el archivo `AuroraSobreEuropa_ROG_ALLY_Windows_x86_64.zip` al dispositivo (o transferirlo por pendrive/red).
2. Descomprimir la carpeta.
3. Hacer doble clic en **`AuroraSobreEuropa.exe`**.
4. El juego iniciará directamente en resolución adaptada y listo para jugar con el mando integrado de la consola.
