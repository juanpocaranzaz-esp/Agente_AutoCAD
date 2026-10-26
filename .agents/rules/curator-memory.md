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
   - Los comandos interactivos de usuario pertenecen exclusivamente a [`lisp-library/Usuario_directo/LISP LISTA DE COMANDOS.txt`](file:///C:/Users/estu03/AgenteCAD/lisp-library/LISP%20LISTA%20DE%20COMANDOS.txt).
   - Los comandos y procedimientos automatizados para la IA deben empaquetarse en **Skills temáticas especializadas** dentro de `.agents/skills/` (revelación progresiva: solo se cargan en contexto cuando la tarea lo requiere).
2. **Datos Efímeros y Contexto de Depuración:**
   - Nombres de archivos de prueba (`test_input.dwg`, `test_output.dwg`), scripts de testeo temporales (`.scr`), logs de consola y fallos intermedios ya resueltos.
3. **Generalizaciones Injustificadas:**
   - Asumir que lo ocurrido en un archivo o entrega aislada aplica a todos los proyectos del estudio sin confirmación del usuario.
4. **Arreglos Espaciales o Visuales Transitorios:**
   - Disposiciones temporales solicitadas ad-hoc por el usuario (ej. ordenar láminas horizontalmente en espacio modelo para facilitar la inspección visual humana durante una revisión). Pertenecen exclusivamente al contexto operativo de la tarea y **NUNCA** deben consolidarse como normas topológicas en `MEMORY.md`.

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

---

## 3. Protocolo de Ejecución del Subagente Curador

1. **Lectura de Memoria:** Leer este archivo (`.agents/rules/curator-memory.md`) y el estado actual de `MEMORY.md`.
2. **Auditoría de Conversación:** Escanear el transcript de la sesión reciente identificando decisiones, correcciones y nuevos estándares validados.
3. **Filtrado Estricto:** Aplicar los criterios de la Sección 1 (descartar comandos de usuario, descartar generalizaciones).
4. **Análisis y Formulación de Propuesta:** Redactar un análisis estructurado de lo evaluado y el texto propuesto para `MEMORY.md` (o indicar claramente si no hay criterios nuevos).
5. **Presentación Obligatoria al Usuario:** Entregar al agente principal el análisis y la propuesta para que este los exponga al usuario de forma transparente.
6. **Aprobación Explícita Estricta:** NUNCA modificar `MEMORY.md` de manera autónoma. La llamada a `save_studio_learning(..., confirmed_by_user=True)` procede ÚNICAMENTE tras una respuesta afirmativa explícita del usuario (ej: *"sí"*, *"de acuerdo"*, *"guárdalo"*, *"confirmo"*) o por solicitud directa del usuario.
7. **Evolución:** Si el usuario corrige la propuesta durante la confirmación, el subagente debe registrar la corrección en la Sección 2 de este archivo.
