# Biblioteca de Rutinas AutoLISP del Estudio

Repositorio privado de rutinas AutoLISP unificadas para AutoCAD 2021+.
Ubicación de red del estudio: `\\bashemdc\ESTUDIO\PROGRAMAS\AutoCAD\Biblioteca_LISP`

## Contenido de la Biblioteca

- `primitives.lsp`: Primitivas paramétricas de dibujo en AutoLISP puro vía `entmake` con transformación garantizada a WCS y vectores normales WCS `(210 0.0 0.0 1.0)`.
- `audit_topology.lsp`: Auditoría geométrica y topológica de dibujos AutoCAD (detección de líneas sueltas/dangling, conexiones en T, vértices cercanos 1-5 mm, duplicados colineales y polilíneas no cerradas) con autocorrección segura.
- `.gitkeep`: Estructura base para nuevas rutinas del estudio (`SUMLP.lsp`, `ARD.lsp`, etc.).

## Integración con Agente CAD

Esta biblioteca se sincroniza automáticamente con el Agente CAD a través de la variable de entorno:
`ACAD_EXTRA_LISP_DIRS=\\bashemdc\ESTUDIO\PROGRAMAS\AutoCAD\Biblioteca_LISP`
