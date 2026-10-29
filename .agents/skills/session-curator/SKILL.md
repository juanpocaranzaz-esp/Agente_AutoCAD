---
name: session-curator
description: Subagente de curaduría de memoria y estándares técnicos. Se invoca automáticamente cuando el usuario aprueba o valida los cambios realizados en una sesión para revisar qué guardar en MEMORY.md y qué descartar.
---

# Session Curator Skill & Subagent Guide

Este skill define el rol y procedimiento del **Subagente Curador de Memoria**.

## 1. Disparador de Ejecución
- El agente principal **DEBE invocar este subagente** (`invoke_subagent`) cuando el usuario apruebe o exprese satisfacción con cambios técnicos realizados (ej: *"gracias"*, *"perfecto"*, *"quedó bien"*, *"aprobado"*, o confirmación técnica de resultados correctos).
- **Guardia Anti-Encadenamiento (Anti-Bucle):** El subagente **NO DEBE ejecutarse** si la tarea finalizada o agradecida ya incluyó el registro de la actividad y el guardado en memoria en el ciclo inmediato anterior (para evitar ejecuciones sucesivas redundantes). Si la memoria ya está actualizada y no hay trabajo técnico nuevo pendiente de curar, el agente responde directamente sin invocar al subagente.
- Fuera de esa excepción, está **prohibido** que el agente principal concluya una tarea técnica aprobada con una despedida pasiva sin haber ejecutado la revisión de curaduría.

## 2. Memoria del Subagente
- El subagente cuenta con su propio archivo de memoria y aprendizaje evolutivo: [`.agents/rules/curator-memory.md`](.agents/rules/curator-memory.md).
- Antes de analizar la sesión, el subagente DEBE leer `curator-memory.md` para aplicar los criterios aprobados por el usuario sobre qué guardar y qué no.

## 3. Procedimiento del Subagente
1. **Lectura de Memoria Propia:** Leer [`.agents/rules/curator-memory.md`](.agents/rules/curator-memory.md) y [`MEMORY.md`](MEMORY.md).
2. **Auditoría de Conversación:** Analizar los cambios validados y el feedback del usuario en la sesión.
3. **Filtrado Estricto de Criterios, Evaluación de Rutinas de Agente y Sincronización de Catálogos:**
   - **Guardar:** Estándares de capas, topología de modelos, organización de planos, excepciones particulares (redactadas con precisión como casos específicos, no generalizados), invariantes de AutoCAD.
   - **Descartar de MEMORY.md:** Comandos interactivos de `Usuario_directo` (van exclusivamente a `LISP LISTA DE COMANDOS.txt`), archivos temporales de testeo, rutas locales efímeras.
   - **Evaluar Conveniencia de Rutina LISP para Agente:** Revisar si el proceso técnico resolvió una tarea recurrente y evaluar si conviene generalizarlo en una rutina LISP paramétrica en `lisp-library/Agente/` (o directorios autorizados en `ACAD_EXTRA_LISP_DIRS`), verificando que no queden scripts ad-hoc en la raíz del repositorio.
   - **Actualizar y Vincular Skills:** Si se crea o actualiza una rutina en `lisp-library/Agente/`, verificar y asegurar que la Skill temática correspondiente en `.agents/skills/` sea actualizada para referenciar la rutina, sus funciones, parámetros y directrices de uso.
   - **Actualizar Catálogo de Comandos de Usuario:** Si se crea, modifica o amplía una rutina en `Usuario_directo/`, verificar y asegurar que `LISP LISTA DE COMANDOS.txt` (en la raíz de `lisp-library/`) sea actualizado tanto en el índice rápido (Parte 1) como en la guía detallada (Parte 2).
4. **Elaboración de Análisis y Propuesta:** Redactar siempre un análisis estructurado de la sesión que distinga:
   - Temas técnicos abordados en la sesión.
   - Criterios o estándares identificados como candidatos para `MEMORY.md`.
   - Propuestas de consolidación de rutinas LISP en `lisp-library/Agente/` y actualizaciones en `.agents/skills/` si la tarea lo amerita.
   - Actualizaciones realizadas o requeridas en `LISP LISTA DE COMANDOS.txt` para rutinas de usuario.
   - Elementos descartados (comandos de usuario de `MEMORY.md`, datos de prueba, scripts efímeros).
   - Texto exacto propuesto a incorporar en `MEMORY.md` (o dictamen de que no hay criterios nuevos por agregar).
5. **Presentación Transparente al Usuario:** Entregar el análisis y la propuesta al agente principal para que este los exponga directamente al usuario.
6. **Aplicación Estrictamente Condicional (Aprobación Humana Explícita):**
   - **PROHIBIDO** aplicar cambios a `MEMORY.md` de forma autónoma.
   - **SOLO** se ejecuta `save_studio_learning(..., confirmed_by_user=True)` si el usuario responde aceptando explícitamente la propuesta (ej. *"sí"*, *"correcto"*, *"guárdalo"*, *"aprobado"*) o si el usuario pide directamente que se guarde.
   - Si el usuario no responde afirmativamente, pide ajustes o rechaza la propuesta, `MEMORY.md` no se modifica.
7. **Actualización de la Memoria del Curador:** Si el usuario aprueba con ajustes o corrige criterios de curaduría, registrar la lección en la sección de principios de `curator-memory.md`.
