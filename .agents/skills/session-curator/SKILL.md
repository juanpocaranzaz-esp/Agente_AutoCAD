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
   - **Guardar:** Estándares globales de capas, topología de modelos, organización de planos, excepciones particulares (redactadas con precisión como casos específicos, no generalizados), invariantes de AutoCAD.
   - **Descartar de MEMORY.md:** Comandos interactivos de `Usuario_directo` (van exclusivamente a `LISP LISTA DE COMANDOS.txt`), criterios/fórmulas/parámetros ya documentados en una Skill (`.agents/skills/`) o rutina LISP (`lisp-library/`), archivos temporales de testeo y rutas locales efímeras.
   - **Evaluar Conveniencia de Rutina LISP para Agente:** Revisar si el proceso técnico resolvió una tarea recurrente y evaluar si conviene generalizarlo en una rutina LISP paramétrica en `lisp-library/Agente/` (o directorios autorizados en `ACAD_EXTRA_LISP_DIRS`), verificando que no queden scripts ad-hoc en la raíz del repositorio.
   - **Actualizar y Vincular Skills:** Si se crea o actualiza una rutina en `lisp-library/Agente/`, verificar y asegurar que la Skill temática correspondiente en `.agents/skills/` sea actualizada para referenciar la rutina, sus funciones, parámetros y directrices de uso.
   - **Actualizar Catálogo de Comandos de Usuario:** Si se crea, modifica o amplía una rutina en `Usuario_directo/`, verificar y asegurar que `LISP LISTA DE COMANDOS.txt` (en la raíz de `lisp-library/`) sea actualizado tanto en el índice rápido (Parte 1) como en la guía detallada (Parte 2).
   - **Sincronización Git Obligatoria de Biblioteca LISP (`git push`):** Si en la sesión o proceso de curaduría se crean, modifican o actualizan rutinas en `lisp-library/` (incluyendo `lisp-library/Agente/`, `lisp-library/Usuario_directo/` y `lisp-library/LISP LISTA DE COMANDOS.txt`), el curador DEBE verificar y ejecutar la sincronización inmediata con GitHub mediante `git add`, `git commit`, `git pull --rebase` y `git push` para garantizar la paridad absoluta entre las estaciones de trabajo.
4. **Elaboración de Análisis y Propuesta:** Redactar siempre un análisis estructurado de la sesión que distinga:
   - Temas técnicos abordados en la sesión.
   - Criterios o estándares identificados como candidatos para `MEMORY.md`.
   - Propuestas de consolidación de rutinas LISP en `lisp-library/Agente/` y actualizaciones en `.agents/skills/` si la tarea lo amerita.
   - Actualizaciones realizadas o requeridas en `LISP LISTA DE COMANDOS.txt` para rutinas de usuario.
   - Estado de sincronización Git (`git push`) de la biblioteca LISP si hubo modificaciones.
   - Elementos descartados (comandos de usuario de `MEMORY.md`, criterios ya contenidos en skills/LISPs, datos de prueba, scripts efímeros).
   - Texto exacto propuesto a incorporar en `MEMORY.md` (o dictamen de que no hay criterios nuevos por agregar).
5. **Presentación Transparente al Usuario:** Entregar el análisis y la propuesta al agente principal para que este los exponga directamente al usuario.
6. **Aplicación Estrictamente Condicional (Aprobación Humana Explícita):**
   - **PROHIBIDO** aplicar cambios a `MEMORY.md` de forma autónoma.
   - **SOLO** se ejecuta `save_studio_learning(..., confirmed_by_user=True)` si el usuario responde aceptando explícitamente la propuesta (ej. *"sí"*, *"correcto"*, *"guárdalo"*, *"aprobado"*) o si el usuario pide directamente que se guarde.
   - Si el usuario no responde afirmativamente, pide ajustes o rechaza la propuesta, `MEMORY.md` no se modifica.
7. **Ejecución de Push y Sincronización Git de Biblioteca LISP:**
   - Si se validaron o realizaron cambios en archivos de la biblioteca LISP (`lisp-library/`) o sus catálogos, asegurar la ejecución de `git add`, `git commit`, `git pull --rebase` y `git push` hacia `origin main`.
8. **Actualización de la Memoria del Curador:** Si el usuario aprueba con ajustes o corrige criterios de curaduría, registrar la lección en la sección de principios de `curator-memory.md`.
9. **Prohibición Estricta de Sincronización Externa:**
   - El subagente curador opera de forma 100% autónoma y exclusiva dentro de su propio repositorio local y remoto (`origin`).
   - Tiene terminantemente prohibido sincronizar, transferir, exportar o duplicar memorias, habilidades, criterios de proyectos o rutinas hacia o desde cualquier otro repositorio de agente base, plantilla o distribución externa.
