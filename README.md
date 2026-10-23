# Agente AutoCAD 2021 MCP (v1.4.9)

[![AutoCAD 2021](https://img.shields.io/badge/AutoCAD-2021%20English-0696D7.svg)](https://www.autodesk.com)
[![Python 3.10+](https://img.shields.io/badge/Python-3.10%2B-blue.svg)](https://www.python.org/)
[![Model Context Protocol](https://img.shields.io/badge/MCP-Protocol-purple.svg)](https://modelcontextprotocol.io/)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

Agente de ingeniería e integración CAD basado en el protocolo **Model Context Protocol (MCP)** y **FastMCP**, diseñado para operar sobre **AutoCAD 2021 (English)** en entornos profesionales (Casa / Oficina) de manera determinista, segura y de alto rendimiento.

---

## 🚀 Arquitectura Headless-First

El agente prioriza la ejecución **Headless** a través de `accoreconsole.exe` de AutoCAD:
- **Ultrarrápido:** Tiempos de respuesta de 1 a 4 segundos por transacción, sin sobrecarga gráfica de GUI.
- **Transaccional y Seguro:** Realiza copias de respaldo secuenciales automáticas (`<Dibujo>-Legacy-0.dwg`, `-Legacy-1.dwg`), garantizando atomicidad con reversión automática en caso de error.
- **Circuit Breaker Anti-Inyección:** Validación estructural AST y bloqueo estricto de llamadas peligrosas al sistema operativo (`startapp`, `_.SHELL`, `vl-file-*`, macros VBA/ARX o inyección en comandos).
- **Aislamiento de Datos No Confiables:** Todo texto, capa o atributo recuperado del DWG se entrega sanitizado dentro de bloques `<untrusted_cad_data>`.
- **Compatibilidad de Coordenadas:** Transformación determinista de coordenadas OCS (Object Coordinate System) a WCS (World Coordinate System) respetando extrusiones (`DXF 210`) y UCS del usuario.

```mermaid
flowchart LR
    IDE["IDE / Agente LLM<br/>(Antigravity, Codex, Claude)"] <-->|MCP Protocol (stdio)| Server["mcp-autocad/server.py<br/>(FastMCP)"]
    Server <-->|Headless Console| Accore["accoreconsole.exe<br/>(AutoCAD 2021)"]
    Server <-->|Live Fallback (COM)| AcadGUI["acad.exe (GUI)"]
    Accore <-->|Pure AutoLISP / entmake| DWG["Archivos .DWG"]
```

---

## 🛠️ Requisitos del Sistema

1. **Sistema Operativo:** Windows 10 o Windows 11 (64-bit).
2. **AutoCAD:** AutoCAD 2021 en inglés (con `accoreconsole.exe` en `C:\Program Files\Autodesk\AutoCAD 2021\accoreconsole.exe`).
3. **Python:** Python 3.10 o superior añadido al `PATH` del sistema.
4. **Entornos MCP compatibles:** Google Antigravity, OpenAI Codex o Claude Desktop.

---

## 📦 Instalación Rápida

### Opción 1: Asistente Visual (Recomendada)
Haz doble clic en:
```bat
instalar.bat
```
El instalador con interfaz gráfica (`installer_gui.ps1`):
1. Verificará la instalación de AutoCAD 2021 y Python.
2. Creará el entorno virtual (`.venv`) e instalará las dependencias requeridas (`mcp`, `pywin32`, `openpyxl`, `pypdfium2`, `Pillow`).
3. Creará los enlaces de Skills globales para Google Antigravity y OpenAI Codex.
4. Registrará el servidor MCP en los entornos seleccionados (`mcp_config.json`, `config.toml`, `claude_desktop_config.json`).

### Opción 2: Instalación por Línea de Comandos
Ejecuta en una terminal de comandos (CMD o PowerShell):
```bat
setup_local.bat
```

---

## 🔧 Catálogo de Herramientas MCP (16 Herramientas)

| Herramienta | Modo | Descripción |
|---|---|---|
| `inspect_cad_headless` | Headless | Inspecciona capas, textos, bloques dinámicos, atributos, límites espaciales, cubicaciones métricas (`include_takeoff`), críticas de higiene (`include_critique`) y genera plots de verificación (`export_plot_path`). |
| `mutate_cad_headless` | Headless | Modifica el dibujo ejecutando AutoLISP validado con rollback automático, guardado seguro (`_.QSAVE`) y auditoría (`_.AUDIT`). |
| `draw_primitives_batch` | Headless | Inserta lotes de primitivas geométricas paramétricas (`LINE`, `LWPOLYLINE`, `CIRCLE`, `RECTANGLE`, `ARC`, `INSERT`) en una sola transacción atómica. |
| `draw_line` | Headless | Dibuja una línea paramétrica entre dos puntos WCS con capa, color y tipo de línea. |
| `draw_lwpolyline` | Headless | Dibuja una polilínea liviana 2D cerrada o abierta con curvatura por abombamiento (bulge arcs). |
| `draw_circle` | Headless | Dibuja un círculo paramétrico por centro y radio en WCS. |
| `draw_rectangle` | Headless | Dibuja un rectángulo cerrado por esquinas opuestas con opción de chaflán/filete. |
| `draw_arc` | Headless | Dibuja un arco circular por centro, radio y ángulos en grados. |
| `insert_block_param` | Headless | Inserta una referencia de bloque con escala XYZ, rotación y atributos. |
| `audit_drawing_topology` | Headless | Audita y repara la topología del dibujo (extremos sueltos, empalmes en T, vértices cercanos, duplicados colineales y polilíneas abiertas). |
| `capture_drawing_preview`| Headless/Live | Genera una vista previa visual de alta resolución en PNG renderizada mediante vectorización PDF o captura de ventana en vivo. |
| `open_drawing_gui` | GUI (Live) | Abre un plano DWG en la interfaz visible de AutoCAD 2021 o activa su ventana si ya estaba abierto (STA COM thread-safe). |
| `list_open_drawings_gui` | GUI (Live) | Lista todos los dibujos actualmente abiertos en la interfaz de AutoCAD reportando ruta, pestaña activa y cambios pendientes. |
| `close_drawing_gui` | GUI (Live) | Cierra un dibujo abierto en AutoCAD GUI (activo o por nombre) con opción de guardar cambios (`save=True/False`). |
| `execute_cad_live` | GUI (Live) | Ejecuta comandos o LISP en la sesión activa de AutoCAD abierta por el usuario, preservando la selección actual (`Pickfirst`). |
| `save_studio_learning` | MCP | Curaduría y registro de nuevos aprendizajes y rutinas LISP estandarizadas del estudio. |

---

## ⚙️ Variables de Entorno

| Variable | Valor por Defecto | Propósito |
|---|---|---|
| `ACAD_CONSOLE_PATH` | `C:\Program Files\Autodesk\AutoCAD 2021\accoreconsole.exe` | Ruta al ejecutable de consola headless de AutoCAD. |
| `AGENTE_ROOT` | Ruta raíz del proyecto | Directorio base de scripts, plantillas y temporales. |
| `ACAD_EXTRA_LISP_DIRS` | Opcional | Directorios adicionales autorizados para carga de rutinas LISP seguras (ej. carpetas de red de estudio). |
| `ACAD_MCP_DEV_NO_INSTALL`| `0` | Modo desarrollo/banco de pruebas: desactiva la sincronización global involuntaria. |

---

## 🧪 Pruebas y Validación

Para ejecutar la suite exhaustiva de 15 pruebas unitarias y de integración:
```powershell
python run_tests_v1.4.9.py
```

La suite valida:
- Validez RFC 8259 de la especificación JSON.
- Integridad AST y compilación de `server.py`.
- Reglas de seguridad del Circuit Breaker y mitigación de inyecciones.
- Decodificación robusta de salidas UTF-16LE / ANSI CP1252 de `accoreconsole`.
- Cubicaciones métricas, áreas poligonales (Fórmula de Shoelace con arcos) y exportación UTF-8-BOM.
- Auditoría topológica y limpieza de micro-geometría.

---

## 📄 Licencia

Este proyecto está distribuido bajo los términos de la Licencia MIT. Consulta el archivo [LICENSE](LICENSE) para más detalles.
