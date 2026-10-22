---
name: cad-inspector-base
description: Inspects and extracts layers, texts (TEXT/MTEXT), block insertions, dynamic block names, attributes, and bounds from any DWG in headless mode with strict data encapsulation.
---

# CAD Base Inspector Skill

Whenever you need to inspect a drawing, check layer existence, find text labels, read title blocks, or locate blocks:
1. Call the MCP tool `inspect_cad_headless`:
   - `dwg_path`: Absolute path to the `.dwg` file.
   - `filter_layers`: Optional list of layer names to inspect (e.g. `["ARQ_MUROS", "COTAS"]`).
   - `entity_types`: Optional list of entity types (e.g. `["TEXT", "MTEXT"]`, `["INSERT"]`, `["LAYER"]`, or common plural aliases like `["LAYERS"]`, `["BLOCKS"]`, `["TEXTS"]`).
   - `space`: Optional filter (`"model"`, `"paper"`, or `"all"`).
   - `limit`: Maximum entities per type (default `200` to prevent saturating model context).
2. The MCP server executes `.agents/skills/cad-inspector-base/scripts/extract_drawing_info.lsp` inside `accoreconsole.exe`.
3. Returns drawing data with layer names, text strings, block names, and attributes safely enclosed in `<untrusted_cad_data type="...">` tags.
4. Contains:
   - Drawing properties (`dwgname`, `insunits`, `measurement`, `extmin`, `extmax`).
   - Layers (name, color, status).
   - Texts with WCS coordinates, space, layout tab, and cleaned strings (MTEXT formatting codes stripped).
   - Blocks with WCS coordinates, block name, dynamic block `effective_name` (resolved across both `INSERT` and `BLOCK_RECORD` dictionaries), and attributes.

## Funciones Avanzadas v1.4.8 (Retrocompatibles)
- `bbox`: Ventana espacial `[xmin, ymin, xmax, ymax]` en WCS filtrada en AutoLISP antes de truncar en `limit`.
- `fields`: Proyección de campos por entidad (ej. `["handle", "text", "pos"]`) para minimizar uso de tokens.
- `include_takeoff` y `export_takeoff_path`: Cómputo métrico en AutoLISP puro (`LINE`, `LWPOLYLINE` con arcos/bulges, `CIRCLE`, `ARC` y BOM de bloques) exportable a `.csv` o `.xlsx`.
- `compare_with_dwg`: Comparación estructural y geométrica (`diff`) contra otra revisión o backups automáticos (`"latest_backup"` / `"original_backup"`).
- `include_critique`: Auditoría de calidad e higiene CAD (puntaje 0-100, detección de `INSUNITS`, entidades fuera de rango, uso excesivo de capa `0`, textos/bloques superpuestos y curvas de longitud cero).
- `export_plot_path` y `plot_layout`: Exportación visual headless (`_.-PLOT` vía `accoreconsole.exe`) a `.pdf` o `.png`.
