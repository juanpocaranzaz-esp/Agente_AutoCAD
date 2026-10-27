---
name: cad-reviewer
description: Protocolo de control de calidad (QA) y verificación técnica integrada de planos CAD. Establece el checklist de auditoría (AUDIT, DBMOD=0, conciliación numérica, bbox, capas y FILEDIA 1) que ejecuta obligatoriamente el mismo agente o subagente que realiza la mutación antes de reportar la finalización al usuario.
---

# CAD Reviewer — Protocolo de Verificación Técnica Integrada (QA)

Este skill define el checklist y procedimiento obligatorio de **Control de Calidad (QA Integrado)** en AutoCAD.

## 1. Principio de Ejecución Integrada
- **QA Integrado en el Ejecutor:** La verificación técnica se ejecuta de forma obligatoria **como paso final dentro del mismo agente o subagente que realizó la modificación** antes de notificar al usuario.
- **Sin Subagentes Desacoplados:** Está prohibido lanzar un subagente revisor externo posterior para releer el mismo DWG, eliminando re-inspecciones duplicadas, tiempos muertos de arranque en frío y desincronizaciones de contexto.
- **Prohibición de Shell Crudo:** Todas las verificaciones deben ejecutarse exclusivamente mediante las herramientas Headless MCP (`inspect_cad_headless`, `audit_drawing_topology`, `capture_drawing_preview`), garantizando rollback y preservación de `FILEDIA 1`.

## 2. Checklist Obligatorio de Auditoría Técnica

1. **Integridad de Base de Datos y Comandos:**
   - Confirmar en el retorno de `mutate_cad_headless` que `status == "ok"` y `command_warnings == []`.
   - Verificar que `_.AUDIT _Y` finalizó con 0 errores críticos (`Total errors found 0 fixed 0`).
   - Verificar que los cambios se persistieron en el disco (`DBMOD == 0`).
   - Verificar que la variable `FILEDIA` quedó restaurada en `1`.

2. **Auditoría Geométrica y de Contenido (vía `inspect_cad_headless` con `bbox`):**
   - **Ventana Espacial Acotada:** Inspeccionar la zona modificada pasando `bbox=[xmin, ymin, xmax, ymax]` y `fields=[...]` para auditar entidades sin saturar el contexto.
   - **Disposición y Coordenadas:** Comprobar que las entidades modificadas o generadas estén en las coordenadas WCS exactas.
   - **Capas y Estilos:** Verificar que ninguna entidad quede en capas indebidas y que los textos y cotas respeten estilos del estudio (`CYPETXT_Swis721_Ex_BT`), alturas, width factor (ej. `0.877` en tablas) y capas estándar (`TABLAS`, `TEXTO_TABLAS`, `DESPIECES_TABLA`).

3. **Concordancia Numérica y Despieces:**
   - Si se generaron o modificaron tablas de armado o cómputos, contrastar analíticamente que las sumatorias de pesos, longitudes y cantidades coincidan 100% con las entidades del dibujo o la tabla de referencia.

4. **Higiene Topológica:**
   - Si se generaron primitivas o contornos, validar la continuidad con `audit_drawing_topology` o inspección de vértices (evitando vértices duplicados o colapsados).

## 3. Reporte Estructurado de Conclusión
Al finalizar la tarea, el agente incluye en su respuesta al usuario el resumen del QA integrado:
- **Estado:** `APROBADO (PASS)` o `CORRECCIÓN APLICADA EN SESIÓN`.
- **Métricas:** Conteo de entidades agregadas/modificadas, confirmación de `DBMOD == 0` y `AUDIT` limpio.
- **Observaciones Técnicas:** Advertencias o aclaraciones pertinentes sobre la geometría.
