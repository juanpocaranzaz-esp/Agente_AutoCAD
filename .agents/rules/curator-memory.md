# Memoria Operativa del Subagente Curador (Curator Memory - Base)

Este archivo constituye la **memoria propia y evolutiva del Subagente Curador**. Define las directrices aprendidas sobre qué conocimientos deben consolidarse en la memoria permanente del estudio (`MEMORY.md`) y cuáles deben descartarse o modularizarse en habilidades.

---

## 1. Criterios de Selección: Qué Guardar vs. Qué Descartar

### A. QUÉ GUARDAR (En `MEMORY.md` bajo `## 2. Criterios Aprobados del Estudio`):
1. **Estándares de Capas Estructurales:**
   - Nombres y usos de capas aprobadas en el estudio (ej. columnas pasantes vs nacientes, capas de marcos de lámina).
2. **Topología y Organización de Planos en el Espacio Modelo:**
   - Disposición espacial de plantas (orden vertical ascendente en Y, detección de carátulas).
3. **Casos Especiales y Excepciones de Obra:**
   - Prácticas no convencionales detectadas en proyectos específicos (redactadas con precisión como posibilidad o caso particular, nunca generalizadas).
4. **Invariantes Técnicas de Dibujo y Base de Datos DWG:**
   - Comportamientos descubiertos de entidades DXF, diccionarios nativos (`ACAD_PLOTSETTINGS`), diferencias entre GUI y Headless (`accoreconsole`).

### B. QUÉ DESCARTAR (NO GUARDAR en `MEMORY.md`):
1. **Comandos de Usuario y de IA:**
   - **PROHIBIDO** volcar sintaxis de comandos en `MEMORY.md`.
   - Los comandos de usuario pertenecen a `LISP LISTA DE COMANDOS.txt`.
   - Los procedimientos automatizados de IA pertenecen a Skills modulares en `.agents/skills/`.
2. **Datos Efímeros y Contexto de Depuración:**
   - Nombres de archivos de prueba, scripts temporales, logs de consola.
3. **Generalizaciones Injustificadas:**
   - Asumir que lo ocurrido en un archivo aislado aplica a todos los proyectos sin confirmación.

---

## 2. Protocolo de Ejecución del Subagente Curador

1. **Lectura de Memoria:** Leer este archivo y el estado actual de `MEMORY.md`.
2. **Auditoría de Conversación:** Escanear el transcript de la sesión identificando decisiones y nuevos estándares validados.
3. **Filtrado Estricto:** Aplicar los criterios de la Sección 1.
4. **Formulación de Propuesta:** Redactar la propuesta en formato markdown conciso para `MEMORY.md`.
5. **Reporte al Agente Principal:** Entregar al agente principal el texto propuesto para confirmación final del usuario.
6. **Evolución:** Si el usuario corrige la propuesta durante la confirmación, registrar la lección en la sección de historial de este archivo.
7. **Guardia Anti-Encadenamiento (Anti-Bucle):** El subagente NO debe invocarse cuando el usuario simplemente agradece, finaliza o acepta una tarea cuya memoria y registro ya fueron consolidados en el ciclo previo, evitando bucles redundantes.

---

## 3. Historial de Aprendizajes del Subagente (Meta-Memoria)

*(El subagente registrará aquí las correcciones y criterios de refinamiento aprobados por el usuario a lo largo de las sesiones).*
