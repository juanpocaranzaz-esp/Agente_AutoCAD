# Memoria Operativa del Subagente Curador (Curator Memory)

Este archivo constituye la **memoria propia y evolutiva del Subagente Curador**. Define las directrices aprendidas sobre qué conocimientos deben consolidarse en la memoria permanente del estudio (`MEMORY.md`) y cuáles deben descartarse o redirigirse.

---

## 1. Criterios de Selección: Qué Guardar vs. Qué Descartar

### A. QUÉ GUARDAR (En `MEMORY.md` bajo `## 2. Criterios Aprobados del Estudio`):
1. **Estándares de Capas Estructurales:**
   - Nombres y usos de capas aprobadas en el estudio (ej. `PILAR_HORMIGON` vs. `PILAR_HORMIGON_APEADO`, `RECUAD_LIMITES`, capas de armaduras, capas de vigas).
   - Elementos donde aplican detalles técnicos específicos (ej. patitas de anclaje exclusivas en apeos/nacientes).
2. **Topología y Organización de Planos en el Espacio Modelo:**
   - Disposición espacial de plantas (ej. orden cronológico ascendente de abajo hacia arriba en el eje Y).
   - Métodos aprobados para localizar carátulas, niveles y títulos de plano cruzando polígonos de recuadro con textos interiores.
3. **Casos Especiales y Excepciones de Obra:**
   - Prácticas no convencionales detectadas en proyectos específicos (ej. plantas convertidas en bloques para comparación con arquitectura en OPBV2).
   - *Regla de precisión:* Debe registrarse explícitamente como una posibilidad o caso particular ("puede estar en bloques en ciertas obras"), **NUNCA** generalizar como si fuera la norma ("suele estar en bloques").
4. **Invariantes Técnicas de Dibujo y Base de Datos DWG:**
   - Comportamientos descubiertos de entidades DXF, diccionarios nativos (`ACAD_PLOTSETTINGS`, `ACAD_LAYOUT`), diferencias entre GUI y Headless (`accoreconsole`).

### B. QUÉ DESCARTAR (NO GUARDAR en `MEMORY.md`):
1. **Comandos de Usuario y de IA:**
   - **PROHIBIDO** volcar la descripción o sintaxis de comandos (tanto de usuario como de IA) en `MEMORY.md`.
   - Los comandos interactivos de usuario pertenecen exclusivamente a [`lisp-library/LISP LISTA DE COMANDOS.txt`](file:///C:/Users/estu03/AgenteCAD/lisp-library/LISP%20LISTA%20DE%20COMANDOS.txt).
   - Los comandos y procedimientos automatizados para la IA deben empaquetarse en **Skills temáticas especializadas** dentro de `.agents/skills/` (revelación progresiva: solo se cargan en contexto cuando la tarea lo requiere).
2. **Datos Efímeros y Contexto de Depuración:**
   - Nombres de archivos de prueba (`test_input.dwg`, `test_output.dwg`), scripts de testeo temporales (`.scr`), logs de consola y fallos intermedios ya resueltos.
3. **Generalizaciones Injustificadas:**
   - Asumir que lo ocurrido en un archivo o entrega aislada aplica a todos los proyectos del estudio sin confirmación del usuario.
4. **Arreglos Espaciales o Visuales Transitorios:**
   - Disposiciones temporales solicitadas ad-hoc por el usuario (ej. ordenar láminas horizontalmente en espacio modelo para facilitar la inspección visual humana durante una revisión). Pertenecen exclusivamente al contexto operativo de la tarea y **NUNCA** deben consolidarse como normas topológicas en `MEMORY.md`.
5. **Instrucciones Procedimentales de Edición y Código de LISPs:**
   - Mandatos o advertencias sobre "no borrar", "no editar", detalles de código AutoLISP, estilos de cota de implementación o funciones auxiliares. `MEMORY.md` almacena semántica descriptiva de dibujo (qué representa cada capa y entidad en la ingeniería del proyecto), no mandatos procedimentales ni código.

### C. EVALUACIÓN DE CONVENIENCIA PARA LA BIBLIOTECA LISP DEL AGENTE (`lisp-library/Agente/`) Y VINCULACIÓN EN SKILLS:
- En cada tarea técnica concluida, el curador DEBE evaluar sistemáticamente si es conveniente generalizar la lógica desarrollada como una **rutina LISP maestra y reutilizable en la biblioteca del Agente** (`lisp-library/Agente/` y `\\bashemdc\ESTUDIO\PROGRAMAS\AutoCAD\Biblioteca_LISP\Agente`).
- El curador debe auditar activamente que no queden scripts ad-hoc con coordenadas fijas en la raíz de `lisp-library/`, promoviendo su formalización como funciones paramétricas universales o su limpieza.
- **Vinculación Obligatoria en Skills:** Toda rutina incorporada o modificada en `lisp-library/Agente/` DEBE ser referenciada y documentada inmediatamente en la Skill temática correspondiente en `.agents/skills/` (detallando ruta del script, funciones exportadas, argumentos y capas requeridas).

### D. ACTUALIZACIÓN OBLIGATORIA DE `LISP LISTA DE COMANDOS.txt` AL MODIFICAR RUTINAS DE USUARIO:
- Cuando en una sesión se cree, actualice o modifique cualquier rutina para usuario directo (`lisp-library/Usuario_directo/` y `\\bashemdc\ESTUDIO\PROGRAMAS\AutoCAD\Biblioteca_LISP\Usuario_directo\`), es OBLIGATORIO actualizar `LISP LISTA DE COMANDOS.txt` (ubicado directamente en la raíz de `lisp-library/` y en `\\bashemdc\ESTUDIO\PROGRAMAS\AutoCAD\Biblioteca_LISP\LISP LISTA DE COMANDOS.txt`).
- La actualización debe reflejarse en dos partes del archivo:
  1. **Parte 1 (Índice Rápido de Comandos):** Agregando o modificando el alias corto y descripción sintética en la categoría correspondiente.
  2. **Parte 2 (Guía Detallada de Comandos):** Documentando archivo `.lsp`, función, parámetros requeridos y modo de uso paso a paso.

---

## 2. Historial de Aprendizajes del Subagente (Meta-Memoria)

- **[2026-10-23 - Sesión Licitatorio OPBV2 / Comando GH]:**
  - *Lección 1:* El usuario ordenó NO registrar comandos de usuario en `MEMORY.md`; redirigir siempre a `LISP LISTA DE COMANDOS.txt`.
  - *Lección 2:* El usuario corrigió la redacción sobre plantas en bloques: indicar que *"pueden estar en bloques"* (caso detectado en OPBV2), pero aclarar que es la única obra conocida donde sucede y no la norma del estudio.
  - *Lección 3:* Priorizar el registro de:
    - Columnas que vienen del nivel inferior (`PILAR_HORMIGON` / `COLUMNA_HORMIGON`).
    - Columnas que nacen (`PILAR_HORMIGON_APEADO` / `COLUMNA_HORMIGON_APEADO`).
    - Capa de marcos de hoja (`RECUAD_LIMITES`).
    - Extracción de nombres de lámina delimitados por recuadros.
  - *Lección 4:* El usuario ordenó que el proceso de curaduría se dispare **siempre de forma proactiva como subagente** en cuanto el usuario aprueba o valida los cambios, sin esperar a que el usuario lo solicite.
  - *Lección 5:* Cada modificación en el agente, reglas, skills, memoria o listados de comandos debe sincronizarse obligatoriamente con GitHub (`git push`).
  - *Lección 6:* El agente debe revisar y sincronizar el repositorio (`git pull --ff-only`) y consultar el catálogo de comandos antes de iniciar cualquier tarea para no reescribir rutinas preexistentes.
  - *Lección 7:* Modularizar las rutinas para la IA en Skills separadas por tipo de tarea (espejo de `LISP LISTA DE COMANDOS.txt`) para no contaminar `MEMORY.md` y cargar solo el contexto relevante.
  - *Lección 8:* Distinción estricta de repositorios: `Agente_AutoCAD` es el agente crudo/base de distribución (solo motor MCP y reglas universales; NUNCA volcar allí memorias de proyectos ni rutinas del estudio). `AgenteCAD` es el agente funcional donde se almacenan la memoria viva, las skills temáticas del estudio y los registros operativos.
  - *Lección 9:* Guardia anti-encadenamiento (Anti-Bucle): El subagente no debe ejecutarse cuando se agradece, finaliza o acepta una tarea que ya incluyó el registro de la actividad y guardado de memoria en el ciclo inmediato, para no encadenar de forma sucesiva ni redundante la revisión de memoria.
  - *Lección 10:* Presentación obligatoria del análisis y consentimiento explícito estricto: El subagente siempre debe realizar un análisis visible y presentarlo al usuario; los cambios en `MEMORY.md` SOLO se aplican si el usuario los acepta explícitamente o los pide directamente. Jamás aplicar cambios de memoria en silencio o de forma autónoma.
- **[2026-10-23 - Sesión LISP Patitas / Columnas CYPE / Formas en L]:**
  - *Lección 11:* No sobrecargar `MEMORY.md` con algoritmos matemáticos ni fórmulas geométricas (ej. bisectrices o productos cruz) si la rutina LISP y la skill especializada ya documentan e implementan esa lógica. En cambio, priorizar la definición conceptual de los elementos de dibujo (ej. "patitas de anclaje: líneas, en general de 10 cm, que marcan las columnas que nacen en el nivel").
  - *Lección 12:* Las anomalías de exportación de software externo (como las polilíneas de 5 vértices de CYPE CAD) deben documentarse en `MEMORY.md` como particularidades que pueden generar problemas o fallos en operaciones geométricas, sin imponer un mandato estricto de preprocesamiento obligatorio salvo cuando la tarea lo requiera.
- **[2026-10-26 - Sesión Cómputo Armaduras de Vigas / Duplicación y Reorganización de Planos]:**
  - *Lección 13 (Arreglos visuales temporales vs. normas de estudio):* Si el usuario pide alinear o reordenar láminas o entidades de forma horizontal para facilitar su revisión visual puntual, NUNCA debe generalizarse como estándar de topología del estudio. Fue un arreglo transitorio y debe descartarse por completo de `MEMORY.md`.
  - *Lección 14 (Cómputo de estribos internos / ramas suplementarias):* Los estribos interiores no son un tercio rígido (1/3) del ancho total. Su longitud depende de la cantidad de tramos en que se subdivide la sección transversal y el número de barras longitudinales enlazadas. La regla correcta es medir el ancho del estribo geométrico y redondear a una fracción de la longitud real.
  - *Lección 15 (Cómputo de vigas acarteladas / canto variable):* En vigas de sección variable o con cartelas, la longitud de los estribos debe computarse como la longitud promedio **por tramo** (evaluando de forma independiente cada sector de estribos según la variación local de canto) y nunca mediante un promedio total global de la viga.
  - *Lección 16 (Prohibición estricta de fórmulas matemáticas en MEMORY.md):* Las fórmulas algebraicas, expresiones LaTeX o ecuaciones de cálculo (ej. fórmulas de peso, cubicación con desperdicio) NO deben volcarse bajo ningún concepto en `MEMORY.md`. La memoria del estudio es exclusivamente conceptual y descriptiva (estándares de planos, capas, criterios cualitativos). La formulación matemática, lógica algorítmica y ecuaciones residen exclusivamente en las Skills modulares correspondientes (ej. `cad-estructuras-acero`).
- **[2026-10-27 - Sesión Consolidación de Biblioteca LISP de Agente]:**
  - *Lección 17 (Evaluación obligatoria de conveniencia para la biblioteca `Agente/`):* El usuario instruyó que en cada tarea técnica ejecutada, el curador revise y determine proactivamente si es conveniente crear y guardar una rutina LISP paramétrica en la biblioteca `lisp-library/Agente/` (y en red `\\bashemdc\ESTUDIO\PROGRAMAS\AutoCAD\Biblioteca_LISP\Agente`), impidiendo que soluciones valiosas queden aisladas como scripts específicos de un archivo o desordenadas en la raíz del repositorio.
  - *Lección 18 (Actualización obligatoria de Skills al consolidar rutinas de IA):* Cuando se crea o actualiza una rutina en la biblioteca del Agente (`lisp-library/Agente/`), es un requisito estricto actualizar en el mismo ciclo la Skill modular respectiva (`.agents/skills/`). Las skills son el manual de operaciones y memoria operativa del agente para cada dominio; una rutina LISP sin referencia en su Skill queda desconectada del contexto operativo futuro.
- **[2026-10-27 - Sesión Bandas de Distribución de Losas / Filtro Semántico vs. Procedural]:**
  - *Lección 19 (Memoria Semántica de Dibujo vs. Código o Mandatos de Edición):* El usuario instruyó que `MEMORY.md` debe limitarse estrictamente a información descriptiva y semántica del plano (definición de capas, qué entidades residen en ellas y su significado en el armado, como las bandas de distribución CYPE y los círculos de enlace barra-banda). NUNCA deben incluirse advertencias procedimentales ("no borrar", "no editar"), especificaciones de código LISP ni pautas de implementación de funciones, las cuales pertenecen exclusivamente a las Skills o al código fuente.
  - *Lección 19 (Actualización y ubicación directa de `LISP LISTA DE COMANDOS.txt`):* El catálogo unificado de comandos de usuario reside directamente en la raíz de la biblioteca (`lisp-library/LISP LISTA DE COMANDOS.txt` y en red `\\bashemdc\ESTUDIO\PROGRAMAS\AutoCAD\Biblioteca_LISP\LISP LISTA DE COMANDOS.txt`), no dentro de `Usuario_directo/`. Al modificar o crear cualquier rutina de usuario, el curador y el agente deben actualizar este catálogo inmediatamente en ambas partes (índice rápido y guía detallada).

---

## 3. Protocolo de Ejecución del Subagente Curador

1. **Lectura de Memoria:** Leer este archivo (`.agents/rules/curator-memory.md`) y el estado actual de `MEMORY.md`.
2. **Auditoría de Conversación:** Escanear el transcript de la sesión reciente identificando decisiones, correcciones y nuevos estándares validados.
3. **Filtrado Estricto y Evaluación de LISPs (Agente y Usuario):**
   - Aplicar los criterios de la Sección 1 (descartar comandos de usuario de `MEMORY.md`).
   - Auditar si el procedimiento técnico resolvió un proceso recurrente y evaluar la conveniencia de consolidarlo como rutina paramétrica en `lisp-library/Agente/` y replicarlo en red, verificando que no queden scripts temporales en la raíz de `lisp-library/`.
   - Verificar y asegurar que cualquier rutina de IA creada o modificada quede explícitamente referenciada y documentada en su Skill temática correspondiente en `.agents/skills/`.
   - Verificar y asegurar que si se crearon o modificaron rutinas interactivas de `Usuario_directo`, se actualice de inmediato `LISP LISTA DE COMANDOS.txt` (en la raíz de `lisp-library/` y en red) en sus dos secciones (índice rápido y guía detallada).
4. **Análisis y Formulación de Propuesta:** Redactar un análisis estructurado de lo evaluado, incluyendo propuestas de memoria para `MEMORY.md`, propuestas de rutinas para `lisp-library/Agente/`, actualizaciones requeridas en `.agents/skills/` y adiciones a `LISP LISTA DE COMANDOS.txt` si corresponde.
5. **Presentación Obligatoria al Usuario:** Entregar al agente principal el análisis y la propuesta para que este los exponga al usuario de forma transparente.
6. **Aprobación Explícita Estricta:** NUNCA modificar `MEMORY.md` de manera autónoma. La llamada a `save_studio_learning(..., confirmed_by_user=True)` procede ÚNICAMENTE tras una respuesta afirmativa explícita del usuario (ej: *"sí"*, *"de acuerdo"*, *"guárdalo"*, *"confirmo"*) o por solicitud directa del usuario.
7. **Evolución:** Si el usuario corrige la propuesta durante la confirmación, el subagente debe registrar la corrección en la Sección 2 de este archivo.
