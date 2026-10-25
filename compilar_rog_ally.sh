#!/usr/bin/env bash
# ==============================================================================
# B-17: Aurora sobre Europa — Script de Compilación y Empaquetado Portable
# Plataforma Destino: Windows x86-64 / ASUS ROG Ally / ROG Ally X / PC con Mando
# ==============================================================================
set -euo pipefail

PROJECT_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_ROOT"

GODOT_BIN="$PROJECT_ROOT/tools/godot"
GODOT_PROJECT_DIR="$PROJECT_ROOT/godot/B17"
TEMPLATES_DIR="$HOME/.local/share/godot/export_templates/4.7.2.stable"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
OUTPUT_BASE_DIR="$PROJECT_ROOT/builds/rog_ally"
BUILD_DIR="$OUTPUT_BASE_DIR/AuroraSobreEuropa_ROG_ALLY_$TIMESTAMP"
EXE_PATH="$BUILD_DIR/AuroraSobreEuropa.exe"
ZIP_NAME="AuroraSobreEuropa_ROG_ALLY_Windows_x86_64.zip"
ZIP_PATH="$OUTPUT_BASE_DIR/$ZIP_NAME"

echo "=========================================================="
echo " [1/5] Verificando Toolchain y Dependencias"
echo "=========================================================="
if [[ ! -x "$GODOT_BIN" ]]; then
  echo "ERROR: No se encontró el binario ejecutable de Godot en $GODOT_BIN" >&2
  exit 1
fi

GODOT_VER="$("$GODOT_BIN" --version)"
echo "Motor Godot detectado: $GODOT_VER"

if [[ ! -f "$TEMPLATES_DIR/windows_release_x86_64.exe" ]]; then
  echo "ERROR: Plantilla de exportación Windows no encontrada en $TEMPLATES_DIR" >&2
  exit 1
fi
echo "Plantilla Windows release verificada en $TEMPLATES_DIR"

# Asegurar que export_presets.cfg tiene include_filter para los catálogos JSON
PRESETS_FILE="$GODOT_PROJECT_DIR/export_presets.cfg"
if ! grep -q 'include_filter="\*\.json"' "$PRESETS_FILE"; then
  echo "Ajustando include_filter en export_presets.cfg..."
  sed -i 's/include_filter=""/include_filter="*.json"/' "$PRESETS_FILE"
fi

mkdir -p "$BUILD_DIR"

echo "=========================================================="
echo " [2/5] Compilando Ejecutable Windows x86-64 (Headless)"
echo "=========================================================="
echo "Destino del ejecutable: $EXE_PATH"

"$GODOT_BIN" --headless --path "$GODOT_PROJECT_DIR" \
  --export-release "Windows Desktop" "$EXE_PATH"

if [[ ! -f "$EXE_PATH" ]]; then
  echo "ERROR: La compilación no generó el archivo $EXE_PATH" >&2
  exit 1
fi

EXE_SIZE="$(du -h "$EXE_PATH" | cut -f1)"
echo "Ejecutable compilado con éxito. Tamaño: $EXE_SIZE"

echo "=========================================================="
echo " [3/5] Generando Documentación y Guía de Controles"
echo "=========================================================="
if [[ -f "$PROJECT_ROOT/LEEME_ROG_ALLY.md" ]]; then
  cp "$PROJECT_ROOT/LEEME_ROG_ALLY.md" "$BUILD_DIR/LEEME_ROG_ALLY.md"
else
  cat > "$BUILD_DIR/LEEME_ROG_ALLY.md" <<'EOF'
# Aurora sobre Europa — Versión Portable ASUS ROG Ally / Windows x86-64
Descomprimir y ejecutar AuroraSobreEuropa.exe. Compatible con mandos tipo Xbox/XInput.
EOF
fi

echo "=========================================================="
echo " [4/5] Generando Sumas de Verificación SHA-256"
echo "=========================================================="
(
  cd "$BUILD_DIR"
  sha256sum "$(basename "$EXE_PATH")" LEEME_ROG_ALLY.md > SHA256SUMS.txt
)
cat "$BUILD_DIR/SHA256SUMS.txt"

echo "=========================================================="
echo " [5/5] Creando Paquete Portable ZIP"
echo "=========================================================="
(
  cd "$OUTPUT_BASE_DIR"
  # Crear ZIP con el contenido del build recién generado
  zip -r "$ZIP_PATH" "$(basename "$BUILD_DIR")/"
)

ZIP_SIZE="$(du -h "$ZIP_PATH" | cut -f1)"

echo "=========================================================="
echo " PROCESO COMPLETADO EXITOSAMENTE"
echo "=========================================================="
echo " Ejecutable: $EXE_PATH ($EXE_SIZE)"
echo " Portable:   $ZIP_PATH ($ZIP_SIZE)"
echo " Carpeta:    $BUILD_DIR"
echo "=========================================================="
