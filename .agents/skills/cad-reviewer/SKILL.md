---
name: cad-reviewer
description: Subagente de control de calidad (QA) y revisión técnica de planos CAD. Se invoca automáticamente tras realizar modificaciones, transformaciones o generación de entidades en archivos DWG antes de reportar la finalización al usuario, auditando la correcta aplicación geométrica, topológica y normativa.
---

# CAD Reviewer Skill & Subagent Guide

Este skill define el rol y procedimiento del **Subagente Revisor de Calidad (QA Reviewer)** de AutoCAD.

## 1. Disparador de Ejecución Obligatorio
- El agente principal **DEBE invocar este subagente** (`invoke_subagent` con la persona o rol `cad-reviewer`) **siempre que realice modificaciones o transformaciones en archivos DWG** (reordenamiento de láminas, duplicación de planos, reemplazo o generación de tablas de armado, cómputos métricos, edición de capas o geometrías).
- La revisión DEBE ejecutarse **ANTES de avisar al usuario** que la tarea está concluida.
- Está terminantemente prohibido que el agente principal reporte al usuario que los cambios están listos sin haber obtenido previamente el dictamen de aprobación técnica emitido por el Subagente Revisor.

## 2. Procedimiento de Auditoría Técnica del Revisor
1. **Inspección Headless del Archivo Modificado:**
   - Inspeccionar los planos resultantes utilizando herramientas headless (`inspect_cad_headless`, scripts de extracción controlada o `accoreconsole`).
   - Verificar que no existan errores de dibujo (`_.AUDIT` sin errores críticos) y que la base de datos esté debidamente guardada (`DBMOD == 0`).
2. **Auditoría de Requerimientos Específicos de la Tarea:**
   - **Disposición y Geometría:** Comprobar que el reordenamiento espacial (ej. láminas de izquierda a derecha en una sola fila a $Y=0$) y las copias superiores (con su offset vertical correspondiente) estén en las coordenadas exactas.
   - **Integridad de Contenido:** Verificar que las copias superiores contengan la totalidad de los elementos requeridos y que las tablas reemplazadas o regeneradas reflejen fielmente los datos de armado, respetando estilos (`CYPETXT_Swis721_Ex_BT`), capas (`TABLAS`, `TEXTO_TABLAS`, `DESPIECES_TABLA`, `TEXTOS_COTAS_DESPIECES_TABLA`), alturas de texto, justificaciones y despieces.
   - **Concordancia Numérica y Despiece:** Comparar que las cantidades, diámetros, longitudes y pesos totales coincidan con el despiece geométrico de los pórticos del dibujo.
3. **Control de Invariantes y Calidad CAD:**
   - Ninguna entidad debe quedar en capas inexistentes o indebidas.
   - Preservación estricta de coordenadas WCS.
   - No deben quedar restos de entidades borradas accidentalmente ni solapamientos espurios.
4. **Emisión del Dictamen Estructurado:**
   - El subagente entrega al agente principal un informe con:
     a) **Estado del Dictamen:** `APROBADO` (PASS) o `REQUIERE CORRECCIÓN` (FAIL).
     b) **Desglose de Hallazgos:** Verificación por lámina, posición y entidad.
     c) **Advertencias o Anomalías:** Lista explícita de cualquier caso ambiguo o sección mal representada detectada en el plano para su oportuna consulta con el usuario.
