# Memoria Operativa del Agente (AutoCAD 2021) - v2.0.0

Este archivo contiene los estándares técnicos aprobados y el índice de habilidades del agente. Capacidad máxima recomendada: 20 KB. Las reglas individuales obsoletas se consolidan periódicamente.

## 0. Identidad del Agente
- **Rol:** Agente de Operación CAD (AutoCAD 2021 Headless & Live).
- **Entorno:** Distribución base estandarizada y agnóstica para automatización de flujos de trabajo de ingeniería y arquitectura en AutoCAD 2021.
- **Autonomía de Repositorio:** Cada instancia del agente opera de forma 100% autónoma y exclusiva dentro de su propio repositorio (`origin`), teniendo prohibido sincronizar o transferir memorias, habilidades o rutinas hacia o desde otros repositorios externos o de agentes base.

## 1. Estándares Generales de Dibujo y Entorno

- **Versión base:** AutoCAD 2021 English (AutoCAD.Application.24).
- **Motor preferido:** Headless (`accoreconsole.exe /l en-US`). Tiempo de respuesta típico: 1 a 4 segundos.
- **Seguridad en consola:** `SECURELOAD 0`, `FILEDIA 0`, `CMDECHO 0`, `DIMZIN 0` en todos los scripts por lotes. Idempotencia en restauración de UCS mediante bandera `mcp_ucs_pushed`.
- **Codificación de scripts:** Archivos `.lsp` con soporte UTF-8 BOM (`utf-8-sig`) y fallback ANSI (`cp1252`), y scripts `.scr` en `cp1252` para preservar tildes, ñ y símbolos técnicos (Ø, ±, °).
- **Coordenadas:** Los puntos DXF 10 de `TEXT`, `INSERT`, `LWPOLYLINE` y `POLYLINE` se almacenan en OCS y se convierten a WCS mediante `(trans pt (if norm norm '(0 0 1)) 0)`; `MTEXT` almacena DXF 10 directamente en WCS.
- **Política de respaldo:** Toda mutación genera un archivo secuencial `Nombre-Legacy-0.dwg`, `-Legacy-1.dwg`, etc. previo y ejecuta `AUDIT` y `QSAVE` solo si no ocurrieron errores de ejecución (`*mcp_err_flag*`). En caso de fallo, se revierte atómicamente el dibujo eliminando el respaldo redundante.
- **Bloqueos de archivo:** Se verifica el acceso de escritura exclusivo en disco antes de procesar archivos cerrados, reportando el usuario y máquina que tienen el archivo abierto vía `.dwl`/`.dwl2`.
- **Biblioteca unificada de LISPs:** Estructura modular estandarizada en el repositorio `lisp-library/`:
  - `LISP LISTA DE COMANDOS.txt`: Catálogo y guía de referencia unificada de comandos ubicado en `lisp-library/LISP LISTA DE COMANDOS.txt`.
  - `Usuario_directo/`: Rutinas interactivas de uso manual en interfaz gráfica (`acaddoc.lsp`).
  - `Agente/`: Rutinas automatizadas puras para ejecución headless (`accoreconsole.exe`), sin interacción por teclado/pantalla (`primitives.lsp`, `audit_topology.lsp`).
- **Primitivas por lotes:** Preferir `draw_primitives_batch` sobre llamadas atómicas múltiples para consolidar transacciones y respaldos.
- **Aseguramiento de Espacio en Ejecución Headless:** Si un dibujo fue guardado con una presentación activa (`TILEMODE 0`, `CTAB /= "Model"`), cualquier entidad generada por script sin espacio explícito queda asignada inadvertidamente al espacio papel. En toda rutina headless destinada al espacio modelo se debe asegurar `(setvar "CTAB" "Model")` y `(setvar "TILEMODE" 1)`, e incluir explícitamente los pares `'(67 . 0)` y `'(410 . "Model")` en las listas DXF de `entmake`.
- **Verificación Visual Vectorial Previa:** Antes de concluir y reportar cualquier mutación técnica compleja (especialmente en tablas, esquemas o anotaciones densas), es obligatorio generar un ploteo vectorial temporal en PDF (`DWG To PDF.pc3` / `capture_drawing_preview`) y convertirlo a PNG para realizar una inspección visual de holguras, legibilidad tipográfica y ausencia de colisiones antes de la entrega final.

## 2. Criterios Técnicos y Buenas Prácticas (Capas, Estilos, Escalas)

- **Capas y Geometría:**
  - Definir y utilizar capas descriptivas en mayúsculas según la disciplina correspondiente.
  - Asegurar la continuidad de polilíneas y verificar que los contornos cerrados tengan vértices limpios y normalizados (contemplando tanto polilíneas ligeras `LWPOLYLINE` como polilíneas 2D pesadas `POLYLINE`).
- **Textos y Anotaciones:**
  - Mantener coherencia en estilos de texto, alturas proporcionales a la escala del plano y factores de compresión acordes a los requerimientos de maquetación.
  - Orientar textos de cota y rotulación alineados con la geometría de referencia.
  - En los resúmenes y tablas de cómputo solo se computa lo expresamente mencionado y detallado en el plano.
- **Espacios y Presentación:**
  - Dibujar geometría a escala 1:1 en Model Space y maquetar hojas de impresión en Paper Space (Layouts).
  - Delimitar marcos exteriores de lámina en capas dedicadas para facilitar la extracción automatizada de vistas.

## 3. Índice de Skills Aprobadas (.agents/skills/)

- `cad-inspector-base`: Inspección granular en formato JSON de capas, textos, bloques (con nombre efectivo de bloques dinámicos en INSERT y BLOCK_RECORD), curvas/cómputos métricos (`include_takeoff` para `LINE`, `LWPOLYLINE`, `POLYLINE` 2D, `CIRCLE`, `ARC`), ventana espacial WCS (`bbox`), proyección de campos (`fields`), comparación de versiones (`compare_with_dwg`), crítica de higiene CAD (`include_critique`), ploteo headless a PDF/PNG (`export_plot_path`), primitivas paramétricas por lotes (`draw_primitives_batch`), auditoría topológica (`audit_drawing_topology`) y vista previa visual multimodal (`capture_drawing_preview`).
- `cad-reviewer`: Protocolo de control de calidad (QA) y verificación técnica integrada de planos CAD. Establece el checklist de auditoría (AUDIT, DBMOD=0, conciliación numérica, bbox y capas) que ejecuta obligatoriamente el mismo agente o subagente que realiza la mutación antes de reportar la finalización al usuario.
- `session-curator`: Subagente de curaduría de memoria y estándares para auditar la sesión y consolidar aprendizajes técnicos previa confirmación.
