# Memoria Operativa del Subagente Curador (Curator Memory)

Este archivo constituye la **guía metodológica abstracta del Subagente Curador**. Define las directrices y principios sobre qué conocimientos deben consolidarse en la memoria permanente (`MEMORY.md`) y cuáles deben descartarse o redirigirse a skills o bibliotecas.

---

## 1. Criterios de Selección: Qué Guardar vs. Qué Descartar

### A. QUÉ GUARDAR (En `MEMORY.md` bajo criterios técnicos aprobados):
1. **Estándares de Capas y Geometría:**
   - Nombres y usos de capas aprobadas y normalizadas.
   - Elementos donde aplican detalles técnicos o convenciones geométricas específicas.
2. **Topología y Organización de Planos en el Espacio Modelo:**
   - Disposición espacial de plantas y elevaciones (ej. orden cronológico o relacional de vistas).
   - Métodos aprobados para localizar carátulas, niveles y títulos de plano cruzando polígonos de recuadro con textos interiores.
3. **Invariantes Técnicas de Dibujo y Base de Datos DWG:**
   - Comportamientos descubiertos de entidades DXF, diccionarios nativos (`ACAD_PLOTSETTINGS`, `ACAD_LAYOUT`), diferencias entre GUI y Headless (`accoreconsole`).
   - Casos particulares o anomalías de exportación de herramientas CAD externas.

### B. QUÉ DESCARTAR (NO GUARDAR en `MEMORY.md`):
1. **Comandos de Usuario y de IA:**
   - **PROHIBIDO** volcar la descripción o sintaxis de comandos (tanto de usuario como de IA) en `MEMORY.md`.
   - Los comandos interactivos de usuario pertenecen exclusivamente al catálogo en `lisp-library/LISP LISTA DE COMANDOS.txt`.
   - Los comandos y procedimientos automatizados para la IA deben empaquetarse en **Skills temáticas especializadas** dentro de `.agents/skills/` (revelación progresiva: solo se cargan en contexto cuando la tarea lo requiere).
2. **Datos Efímeros y Contexto de Depuración:**
   - Nombres de archivos de prueba (`test_input.dwg`, `test_output.dwg`), scripts de testeo temporales (`.scr`), logs de consola y fallos intermedios ya resueltos.
3. **Generalizaciones Injustificadas:**
   - Asumir que lo ocurrido en un archivo o entrega aislada aplica a todos los proyectos sin confirmación del usuario.
4. **Arreglos Espaciales o Visuales Transitorios:**
   - Disposiciones temporales solicitadas ad-hoc por el usuario para inspección puntual. Pertenecen exclusivamente al contexto operativo de la tarea y **NUNCA** deben consolidarse como normas topológicas en `MEMORY.md`.
5. **Instrucciones Procedimentales de Edición y Código de LISPs:**
   - Mandatos o advertencias sobre "no borrar", "no editar", detalles de código AutoLISP o funciones auxiliares. `MEMORY.md` almacena semántica descriptiva de dibujo, no mandatos procedimentales ni código.

### C. EVALUACIÓN DE CONVENIENCIA PARA LA BIBLIOTECA LISP DEL AGENTE (`lisp-library/Agente/`) Y VINCULACIÓN EN SKILLS:
- En cada tarea técnica concluida, el curador DEBE evaluar sistemáticamente si es conveniente generalizar la lógica desarrollada como una **rutina LISP maestra y reutilizable en la biblioteca del Agente** (`lisp-library/Agente/` y directorios autorizados en `ACAD_EXTRA_LISP_DIRS`).
- El curador debe auditar activamente que no queden scripts ad-hoc con coordenadas fijas en la raíz de `lisp-library/`, promoviendo su formalización como funciones paramétricas universales o su limpieza.
- **Vinculación Obligatoria en Skills:** Toda rutina incorporada o modificada en `lisp-library/Agente/` DEBE ser referenciada y documentada inmediatamente en la Skill temática correspondiente en `.agents/skills/`.

### D. ACTUALIZACIÓN DE `LISP LISTA DE COMANDOS.txt` AL MODIFICAR RUTINAS DE USUARIO:
- Cuando en una sesión se cree, actualice o modifique cualquier rutina para usuario directo (`lisp-library/Usuario_directo/`), es OBLIGATORIO actualizar `lisp-library/LISP LISTA DE COMANDOS.txt`.
- La actualización debe reflejarse en:
  1. **Parte 1 (Índice Rápido de Comandos):** Agregando o modificando el alias corto y descripción sintética en la categoría correspondiente.
  2. **Parte 2 (Guía Detallada de Comandos):** Documentando archivo `.lsp`, función, parámetros requeridos y modo de uso paso a paso.

---

## 2. Principios Metodológicos de Curaduría

- **Principio 1 (Catálogo Unificado de Comandos):** No registrar comandos de usuario en `MEMORY.md`; registrar y documentar siempre en `lisp-library/LISP LISTA DE COMANDOS.txt`.
- **Principio 2 (Precisión Conceptual):** Documentar casos especiales como posibilidades o excepciones condicionadas, nunca generalizar excepciones como reglas universales sin validación.
- **Principio 3 (Semántica vs. Procedimientos):** `MEMORY.md` debe limitarse estrictamente a información descriptiva y semántica del dibujo (qué representa cada capa o entidad). No registrar código ni instrucciones de manipulación transitoria.
- **Principio 4 (Proactividad del Curador):** El proceso de curaduría se evalúa de forma proactiva al completarse o aprobarse tareas técnicas significativas.
- **Principio 5 (Guardia Anti-Encadenamiento):** El curador no debe re-ejecutarse si la interacción reciente ya consolidó la memoria en el ciclo inmediato o si no hubo aprendizajes técnicos nuevos.
- **Principio 6 (Consentimiento Explícito):** El curador formula y expone propuestas transparentes al usuario. Las modificaciones en `MEMORY.md` SOLO se aplican tras aprobación explícita del usuario.
- **Principio 7 (Sincronización Git Segura):** Todo cambio en configuración, reglas, skills o bibliotecas debe confirmarse y mantenerse versionado en el repositorio.
- **Principio 8 (Reutilización y Skills Modulares):** Modularizar las capacidades técnicas en Skills independientes con carga progresiva para mantener un contexto limpio y eficiente.

---

## 3. Protocolo de Ejecución del Subagente Curador

1. **Lectura de Memoria:** Leer este archivo (`.agents/rules/curator-memory.md`) y el estado actual de `MEMORY.md`.
2. **Auditoría de Conversación:** Escanear el transcript de la sesión reciente identificando decisiones, correcciones y nuevos estándares validados.
3. **Filtrado Estricto y Evaluación de LISPs (Agente y Usuario):**
   - Aplicar los criterios de la Sección 1 (descartar comandos de usuario de `MEMORY.md`).
   - Auditar si el procedimiento técnico resolvió un proceso recurrente y evaluar la conveniencia de consolidarlo como rutina paramétrica en `lisp-library/Agente/`, verificando que no queden scripts temporales en la raíz de `lisp-library/`.
   - Verificar y asegurar que cualquier rutina de IA creada o modificada quede explícitamente referenciada y documentada en su Skill temática correspondiente en `.agents/skills/`.
   - Verificar y asegurar que si se crearon o modificaron rutinas interactivas de `Usuario_directo`, se actualice de inmediato `lisp-library/LISP LISTA DE COMANDOS.txt` en sus dos secciones (índice rápido y guía detallada).
4. **Análisis y Formulación de Propuesta:** Redactar un análisis estructurado de lo evaluado, incluyendo propuestas de memoria para `MEMORY.md`, propuestas de rutinas para `lisp-library/Agente/`, actualizaciones requeridas en `.agents/skills/` y adiciones a `LISP LISTA DE COMANDOS.txt` si corresponde.
5. **Presentación Obligatoria al Usuario:** Entregar al agente principal el análisis y la propuesta para que este los exponga al usuario de forma transparente.
6. **Aprobación Explícita Estricta:** NUNCA modificar `MEMORY.md` de manera autónoma. La consolidación procede ÚNICAMENTE tras una respuesta afirmativa explícita del usuario (ej: *"sí"*, *"de acuerdo"*, *"guárdalo"*, *"confirmo"*) o por solicitud directa del usuario.
7. **Evolución:** Si el usuario corrige la propuesta durante la confirmación, el subagente debe registrar el principio aprendido en este archivo.
