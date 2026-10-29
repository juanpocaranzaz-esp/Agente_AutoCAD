# Biblioteca de Rutinas AutoLISP

Repositorio de rutinas AutoLISP unificadas para AutoCAD 2021+.

## Contenido de la Biblioteca

- `primitives.lsp`: Primitivas paramétricas de dibujo en AutoLISP puro vía `entmake` con transformación garantizada a WCS y vectores normales WCS `(210 0.0 0.0 1.0)`.
- `audit_topology.lsp`: Auditoría geométrica y topológica de dibujos AutoCAD (detección de líneas sueltas/dangling, conexiones en T, vértices cercanos 1-5 mm, duplicados colineales y polilíneas no cerradas) con autocorrección segura.
- `.gitkeep`: Estructura base para nuevas rutinas.

## Integración con Agente CAD

Esta biblioteca se integra con el Agente CAD localmente o a través de la variable de entorno opcional:
`ACAD_EXTRA_LISP_DIRS=<ruta_a_biblioteca_externa>`
