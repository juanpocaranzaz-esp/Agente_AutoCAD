---
name: session-curator
description: Subagente de curaduría de memoria y estándares del estudio. Se invoca automáticamente cuando el usuario aprueba o valida los cambios realizados en una sesión para revisar qué guardar en MEMORY.md y qué descartar.
---

# Session Curator Skill & Subagent Guide

Este skill define el rol y procedimiento del **Subagente Curador de Memoria**.

## 1. Disparador de Ejecución
- El agente principal **DEBE invocar este subagente** (`invoke_subagent`) cuando el usuario apruebe o exprese satisfacción con cambios técnicos realizados (ej: *"gracias"*, *"perfecto"*, *"quedó bien"*, *"aprobado"*, o confirmación técnica de resultados correctos).
- **Guardia Anti-Encadenamiento (Anti-Bucle):** El subagente **NO DEBE ejecutarse** si la tarea finalizada o agradecida ya incluyó el registro de la actividad y el guardado en memoria en el ciclo inmediato anterior (para evitar ejecuciones sucesivas redundantes). Si la memoria ya está actualizada y no hay trabajo técnico nuevo pendiente de curar, el agente responde directamente sin invocar al subagente.
- Fuera de esa excepción, está **prohibido** que el agente principal concluya una tarea técnica aprobada con una despedida pasiva sin haber ejecutado la revisión de curaduría.

## 2. Memoria del Subagente
- El subagente cuenta con su propio archivo de memoria y aprendizaje evolutivo: [`.agents/rules/curator-memory.md`](file:///C:/Users/estu03/AgenteCAD/.agents/rules/curator-memory.md).
- Antes de analizar la sesión, el subagente DEBE leer `curator-memory.md` para aplicar los criterios aprobados por el usuario sobre qué guardar y qué no.

## 3. Procedimiento del Subagente
1. **Lectura de Memoria Propia:** Leer [`.agents/rules/curator-memory.md`](file:///C:/Users/estu03/AgenteCAD/.agents/rules/curator-memory.md) y [`MEMORY.md`](file:///C:/Users/estu03/AgenteCAD/MEMORY.md).
2. **Auditoría de Conversación:** Analizar los cambios validados y el feedback del usuario en la sesión.
3. **Filtrado Estricto de Criterios y Evaluación de Rutinas de Agente:**
   - **Guardar:** Estándares de capas, topología de modelos, organización de planos, excepciones de obra (redactadas con precisión como casos específicos, no generalizados), invariantes de AutoCAD.
   - **Descartar:** Comandos interactivos de `Usuario_directo` (van exclusivamente a `LISP LISTA DE COMANDOS.txt`), archivos temporales de testeo, rutas locales efímeras.
   - **Evaluar Conveniencia de Rutina LISP para Agente:** Revisar si el proceso técnico resolvió una tarea recurrente y evaluar si conviene generalizarlo en una rutina LISP paramétrica en `lisp-library/Agente/` y replicarla en red (`\\bashemdc\ESTUDIO\PROGRAMAS\AutoCAD\Biblioteca_LISP\Agente`), verificando que no queden scripts ad-hoc en la raíz del repositorio.
4. **Elaboración de Análisis y Propuesta:** Redactar siempre un análisis estructurado de la sesión que distinga:
   - Temas técnicos abordados en la sesión.
   - Criterios o estándares identificados como candidatos para `MEMORY.md`.
   - Propuestas de consolidación de rutinas LISP en `lisp-library/Agente/` si la tarea lo amerita.
   - Elementos descartados (comandos de usuario, datos de prueba, scripts efímeros).
   - Texto exacto propuesto a incorporar en `MEMORY.md` (o dictamen de que no hay criterios nuevos por agregar).
5. **Presentación Transparente al Usuario:** Entregar el análisis y la propuesta al agente principal para que este los exponga directamente al usuario.
6. **Aplicación Estrictamente Condicional (Aprobación Humana Explícita):**
   - **PROHIBIDO** aplicar cambios a `MEMORY.md` de forma autónoma.
   - **SOLO** se ejecuta `save_studio_learning(..., confirmed_by_user=True)` si el usuario responde aceptando explícitamente la propuesta (ej. *"sí"*, *"correcto"*, *"guárdalo"*, *"aprobado"*) o si el usuario pide directamente que se guarde.
   - Si el usuario no responde afirmativamente, pide ajustes o rechaza la propuesta, `MEMORY.md` no se modifica.
7. **Actualización de la Memoria del Curador:** Si el usuario aprueba con ajustes o corrige criterios de curaduría, registrar la lección en la sección de historial de `curator-memory.md`.
