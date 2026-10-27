# Memoria Operativa del Estudio (AutoCAD 2021) - v1.4.9

Este archivo contiene los estándares aprobados del estudio y el índice de habilidades aprendidas. Capacidad máxima recomendada: 20 KB. Las reglas individuales obsoletas se consolidan periódicamente.

## 0. Identidad del Agente y Arquitectura de Repositorios
- **Nombre:** Clavi
- **Rol:** Agente de Ingeniería y Operación CAD (AutoCAD 2021 Headless & Live) para el estudio.
- **Diferenciación Estricta entre Repositorios:**
  - **`Agente_AutoCAD` (`C:\Users\estu03\Desktop\Juan Pablo\Agente_AutoCAD` | `Agente_AutoCAD.git`):**
    - *Rol:* **Agente Crudo / Base de Distribución / Instalador**.
    - *Contenido:* Motor MCP (`server.py`), instalador (`installer_gui.ps1`), scripts de empaquetado (`pack_spec.py`), especificación de distribución JSON, reglas constitucionales base (`AGENTS.md`), plantilla limpia de `MEMORY.md` y primitivas elementales (`primitives.lsp`, `audit_topology.lsp`).
    - *Restricción estricta:* NUNCA registrar allí rutinas de usuario del estudio, registros de proyectos, memorias aprendidas de obras específicas ni carpetas de pruebas de dibujos.
  - **`AgenteCAD` (`C:\Users\estu03\AgenteCAD` | `AgenteCAD.git`):**
    - *Rol:* **Agente Funcional / Entorno de Trabajo Operativo del Estudio**.
    - *Contenido:* Es el entorno de producción diario donde el agente opera y aprende. Contiene la memoria viva del estudio (`MEMORY.md` con estándares de capas y criterios de obra), el historial evolutivo del curador (`curator-memory.md`), las 7 Skills modulares por tipo de tarea (`.agents/skills/`), el catálogo completo de LISPs de usuario (`lisp-library/Usuario_directo/`), la guía maestra `LISP LISTA DE COMANDOS.txt` y los entornos de pruebas locales (`tests/`).

## 1. Estándares Generales de Dibujo y Entorno

- **Versión base:** AutoCAD 2021 English (AutoCAD.Application.24).
- **Motor preferido:** Headless (`accoreconsole.exe /l en-US`). Tiempo de respuesta típico: 1 a 4 segundos.
- **Seguridad en consola:** `SECURELOAD 0`, `FILEDIA 0`, `CMDECHO 0`, `DIMZIN 0` en todos los scripts por lotes. Idempotencia en restauración de UCS mediante bandera `mcp_ucs_pushed`.
- **Codificación de scripts:** Archivos `.lsp` con soporte UTF-8 BOM (`utf-8-sig`) y fallback ANSI (`cp1252`), y scripts `.scr` en `cp1252` para preservar tildes, ñ y símbolos técnicos (Ø, ±, °).
- **Coordenadas:** Los puntos DXF 10 de `TEXT`, `INSERT` y `LWPOLYLINE` se almacenan en OCS y se convierten a WCS mediante `(trans pt (if norm norm '(0 0 1)) 0)`; `MTEXT` almacena DXF 10 directamente en WCS.
- **Política de respaldo:** Toda mutación genera un archivo secuencial `Nombre-Legacy-0.dwg`, `-Legacy-1.dwg`, etc. previo y ejecuta `AUDIT` y `QSAVE` solo si no ocurrieron errores de ejecución (`*mcp_err_flag*`). En caso de fallo, se revierte atómicamente el dibujo eliminando el respaldo redundante.
- **Bloqueos de archivo:** Se verifica el acceso de escritura exclusivo en disco antes de procesar archivos cerrados, reportando el usuario y máquina que tienen el archivo abierto vía `.dwl`/`.dwl2`.
- **Biblioteca unificada de LISPs:** Estructura dual estandarizada en `lisp-library/` y en red en `\\bashemdc\ESTUDIO\PROGRAMAS\AutoCAD\Biblioteca_LISP`:
  - `LISP LISTA DE COMANDOS.txt`: Catálogo y guía de referencia unificada de comandos para usuario directo ubicado directamente en la raíz de `lisp-library/` y en `\\bashemdc\ESTUDIO\PROGRAMAS\AutoCAD\Biblioteca_LISP\LISP LISTA DE COMANDOS.txt`.
  - `Usuario_directo/`: Rutinas interactivas de uso manual diario en interfaz gráfica (`acaddoc.lsp`), con comandos cortos (`RT2`, `ARD`, `FM`, `RH`, `RAR`, `AT`, `Patitas`, `SUMLP`, etc.).
  - `Agente/`: Rutinas automatizadas puras para ejecución headless (`accoreconsole.exe`), sin interacción por teclado/pantalla (`primitives.lsp`, `audit_topology.lsp`).
- **Primitivas por lotes:** Preferir `draw_primitives_batch` sobre llamadas atómicas múltiples para consolidar transacciones y respaldos.

## 2. Criterios Aprobados del Estudio (Capas, Estilos, Escalas)

*(El Subagente Curador registrará aquí reglas permanentes aprobadas por el usuario)*

## 3. Índice de Skills Aprobadas (.agents/skills/)

- `cad-inspector-base`: Inspección granular en formato JSON de capas, textos, bloques (con nombre efectivo de bloques dinámicos en INSERT y BLOCK_RECORD), curvas/cómputos métricos (`include_takeoff`), ventana espacial WCS (`bbox`), proyección de campos (`fields`), comparación de versiones (`compare_with_dwg`), crítica de higiene CAD (`include_critique`), ploteo headless a PDF/PNG (`export_plot_path`), primitivas paramétricas por lotes (`draw_primitives_batch`), auditoría topológica (`audit_drawing_topology`) y vista previa visual multimodal (`capture_drawing_preview`).
- `session-curator`: Subagente de curaduría de memoria y estándares del estudio para auditar la sesión y sincronizar aprendizajes previa confirmación.
