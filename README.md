# Aurora sobre Europa — B-17 Flying Fortress — COMPLETADO ABIMAEL

Simulador de vuelo y combate de un bombardero B-17 sobre el invierno europeo de 1945, desarrollado en **Godot 4.7.2**. Autoría y dirección del proyecto: Abimael Silva.

## Qué es

Controlas un B-17 en una misión de bombardeo con tres puestos jugables (Piloto, Artillero, Bombardero), combate contra cazas enemigos, daño por motor/casco, instrumentos que se degradan por flak, escoltas P-51D bajo demanda, piloto automático, formación de ala, audio dinámico (motor, disparos, flak, bombas) y locuciones en inglés de época con subtítulos en español.

## Cómo jugar

Desde Linux, con consola visible:

```bash
./INICIAR_B17.sh
```

Diagnóstico de mando físico (Xbox / ROG Ally X):

```bash
./INICIAR_B17.sh --probar-mando
```

También hay una build portable para Windows / ASUS ROG Ally — ver `LEEME_ROG_ALLY.md` para requisitos y guía de controles completa.

## Controles (resumen; detalle por perfil en `LEEME_ROG_ALLY.md`)

| Acción | Teclado/Ratón | Mando Xbox/ROG Ally |
|---|---|---|
| Puesto Piloto / Artillero / Bombardero | `1` / `2` / `3` | Cruceta ↑ / → / ↓ |
| Vuelo (cabeceo/alabeo) | `W A S D` | Stick izquierdo |
| Potencia | `Shift` / `Ctrl` | `RT` / `LT` |
| Disparar torreta | Clic izq. / `Espacio` | `RB` / `X` |
| Soltar bombas | `Espacio` / `B` | `A` / `B` |
| Ciclo de torretas (Dorsal/Cola/Ventral) | `Q` (en puesto Artillero) | — |
| Embanderar motor dañado | `F1`–`F4` | `LB` + `X` |
| Extintor de motor | `Ctrl`/`Shift` + `F1`–`F4` | `LB` + `Y` |
| Pedir cobertura de escoltas | `E` | — |
| Piloto automático | `TAB` | `View`/`Back` |
| Pausa y ajustes | `Esc` / `P` | `Start`/`Menu` |
| Reiniciar misión | `R` | `A` (en fin de misión) |

## Estructura del proyecto

- `godot/B17/` — proyecto Godot (motor definitivo; Unity quedó descartado, ver `planning/DECISIONES.md`).
- `planning/` — coordinación entre agentes (Claude supervisa, Qwen programa, Codex integra, Agy hace QA) y documentos de decisión/estado.
- `logs/` — bitácoras de orquestación y resultados de pruebas.
- `tools/` — motor Godot portable y binarios auxiliares (no se modifica instalación global del sistema).

## Pruebas

Suite de pruebas automatizadas en `godot/B17/tests/`. Ejecución headless:

```bash
tools/godot --headless --path godot/B17 --script res://tests/<archivo>.gd
```

Las pruebas visuales (capturas GPU) requieren ventana real, sin `--headless`.

## Estado

Godot 4.7.2 fijado como motor definitivo. Lotes de combate, audio, cámara orbital y terreno integrados y verificados.

Menú principal, panel de Opciones (Audio/Video/Controles/Jugabilidad/Accesibilidad), remapeo de teclas con detección de conflictos, dificultad, modo de color para daltonismo y guardado/continuación de misión ya están implementados — ver `planning/ANALISIS_MEJORAS_MENUS_OPCIONES.md` y `planning/PRIORIZACION_COMPLEJIDAD_MENUS_OPCIONES.md` para el detalle de cada mejora y su estado. Pendiente explícito: doblaje/voces en más de un idioma (requiere locución nueva, no es un cambio de código) y todo lo marcado como SUPERIOR (campaña multi-misión, certificación de plataforma, multijugador, localización profesional completa).

## Nota sobre control de versiones

Este repositorio no tenía `git` instalado en el entorno de desarrollo original; los registros de intentos en `logs/` sirvieron como respaldo provisional. A partir de esta subida a GitHub, el historial de commits es la referencia principal.
