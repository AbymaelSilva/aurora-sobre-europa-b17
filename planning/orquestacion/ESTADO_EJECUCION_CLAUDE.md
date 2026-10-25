# Estado de ejecución — Claude

Actualizado: 2026-10-24T11:14:29-07:00
**Estado: REVISION_VISUAL_INTEGRADA_ENTREGADA.** El dictamen se refiere al manifiesto `logs/revision_claude/20261024T175932Z-integrado/manifest_antes.txt` (estable antes y después; = staging `local-20261024-acd6e3ddfc40`, 135/135 archivos).

| Punto | Estado | Evidencia |
|---|---|---|
| 1.1.1.4 Modelos | **ACEPTADO**. O1–O7 PASS; O8 PASS con H-16 S3 | REVISION_CLAUDE_1.1.1.4.md; capturas_1280/, capturas_1920/ |
| 1.1.2.3 Cámaras | **ACEPTADO** en encuadre, oclusión y cambio de puesto (K1–K6 PASS; K7 S3). La ayuda de suelta (U01) queda fuera | REVISION_CLAUDE_1.1.2.3.md; oclusion_reticula/ |
| 1.1.3.4 Hallazgos | Sin S1/S2 propios. H-01, 02, 04, 05 y 06 cerrados; H-08 y H-11 reclasificados a S3 con motivo; nuevos H-14, 15 y 16 (S3) | REVISION_CLAUDE_1.1.3.4.md |
| H-11 ObjectDB | Reproducido en la salida real 3/3 y sin crecimiento (6 ciclos). Corrección propuesta a Agy: probada en el harness (0/6 con ella frente a 4/6 sin ella). No declarado resuelto | REVISION_CLAUDE_1.1.3.4.md §H-11 |
| 1.1.4.2 LOCAL | BORRADOR escrito, pendiente del id final de Codex y de las secciones ⚠ de U01/U02 | LEEME_LOCAL_BORRADOR.md |

**Bloqueo de V1 local que queda (no es mío):** U01/U02 (REVISION_BOMBARDEO_MANUAL_CODEX.md, ENCARGO_U01_U02_AGY.md).
**Al cambiar producción por U01/U02:** este dictamen no cubre los hashes nuevos. Hay que repetir `capture_mission_claude.gd` a 1280 y 1920 (≈15 s cada una), K2/K4, la vista Norden con la ayuda nueva y cerrar el LÉEME.
Producción no modificada. Herramientas propias cambiadas: `tests/capture_mission_claude.gd` (guardas: código 1 sin carpeta absoluta o en headless; capturas h_* de harness) y `tools_review/{fighter_visibility,gunner_occlusion,objectdb_exit,objectdb_fix_probe}_claude.gd` (nuevas). Hashes en `manifest_herramientas_claude.txt`.
