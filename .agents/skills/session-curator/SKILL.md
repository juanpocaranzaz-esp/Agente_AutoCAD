---
name: session-curator
description: Subagente de curaduría de memoria y estándares del estudio. Se invoca automáticamente cuando el usuario aprueba o valida los cambios realizados en una sesión para revisar qué guardar en MEMORY.md y qué descartar.
---

# Session Curator Skill & Subagent Guide

Este skill define el rol y procedimiento del **Subagente Curador de Memoria**.

## 1. Disparador de Ejecución
- El agente principal **DEBE invocar este subagente** (`invoke_subagent`) inmediatamente cuando el usuario apruebe o exprese satisfacción con el trabajo realizado (ej: *"gracias"*, *"perfecto"*, *"quedó bien"*, *"aprobado"*, o confirmación técnica de resultados correctos).
- Está **prohibido** que el agente principal responda con una despedida pasiva sin haber ejecutado la revisión de curaduría.

## 2. Memoria del Subagente
- El subagente cuenta con su propio archivo de memoria y aprendizaje evolutivo: [`.agents/rules/curator-memory.md`](file:///C:/Users/estu03/AgenteCAD/.agents/rules/curator-memory.md).
- Antes de analizar la sesión, el subagente DEBE leer `curator-memory.md` para aplicar los criterios aprobados por el usuario sobre qué guardar y qué no.

## 3. Procedimiento del Subagente
1. **Lectura de Memoria Propia:** Leer [`.agents/rules/curator-memory.md`](file:///C:/Users/estu03/AgenteCAD/.agents/rules/curator-memory.md) y [`MEMORY.md`](file:///C:/Users/estu03/AgenteCAD/MEMORY.md).
2. **Auditoría de Conversación:** Analizar los cambios validados y el feedback del usuario en la sesión.
3. **Filtrado Estricto de Criterios:**
   - **Guardar:** Estándares de capas, topología de modelos, organización de planos, excepciones de obra (redactadas con precisión como casos específicos, no generalizados), invariantes de AutoCAD.
   - **Descartar:** Comandos interactivos de `Usuario_directo` (van exclusivamente a `LISP LISTA DE COMANDOS.txt`), archivos temporales de testeo, rutas locales efímeras.
4. **Elaboración de Propuesta:** Redactar el texto exacto propuesto para incorporar bajo `## 2. Criterios Aprobados del Estudio` en `MEMORY.md`.
5. **Entrega al Agente Principal:** Enviar el texto propuesto al agente principal para que este solicite la confirmación del usuario.
6. **Actualización de la Memoria del Curador:** Si el usuario aprueba con ajustes o correcciones de criterio, registrar esa nueva lección en la sección de historial de `curator-memory.md`.
7. **Consolidación:** Con la confirmación del usuario, ejecutar `save_studio_learning(..., confirmed_by_user=True)`.
