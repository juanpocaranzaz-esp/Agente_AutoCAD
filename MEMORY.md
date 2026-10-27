# Memoria Operativa del Estudio (AutoCAD 2021) - v1.5.0

Este archivo contiene los estándares aprobados del estudio y el índice de habilidades aprendidas. Capacidad máxima recomendada: 20 KB. Las reglas individuales obsoletas se consolidan periódicamente.

## 0. Identidad del Agente y Arquitectura de Repositorios
- **Nombre:** Clavi
- **Rol:** Agente de Ingeniería y Operación CAD (AutoCAD 2021 Headless & Live) para el estudio.
- **Diferenciación Estricta entre Repositorios:**
  - **`Agente_AutoCAD` (`C:\Users\estu03\Desktop\Juan Pablo\Agente_AutoCAD` | `Agente_AutoCAD.git`):**
    - *Rol:* **Agente Crudo / Base de Distribución / Instalador**.
    - *Contenido:* Motor MCP (`server.py`), instalador (`installer_gui.ps1`), scripts de empaquetado (`pack_spec.py`), especificación de distribución JSON, reglas constitucionales base (`AGENTS.md`), plantilla limpia de `MEMORY.md` y primitivas elementales (`primitives.lsp`, `audit_topology.lsp`).
    - *Restricción estricta:* NUNCA registrar allí rutinas de usuario del estudio, registros de proyectos, memorias aprendidas de obras específicas ni carpetas de pruebas de dibujos.
  - **`AgenteCAD` (`C:\Users\estu03\AgenteCAD` | `AgenteCAD.git`):**
    - *Rol:* **Agente Funcional / Entorno de Trabajo Operativo del Estudio**.
    - *Contenido:* Es el entorno de producción diario donde el agente opera y aprende. Contiene la memoria viva del estudio (`MEMORY.md` con estándares de capas y criterios de obra), el historial evolutivo del curador (`curator-memory.md`), las 7 Skills modulares por tipo de tarea (`.agents/skills/`), el catálogo completo de LISPs de usuario (`lisp-library/Usuario_directo/`), la guía maestra `LISP LISTA DE COMANDOS.txt` y los entornos de pruebas locales (`tests/`).

## 1. Estándares Generales de Dibujo y Entorno

- **Versión base:** AutoCAD 2021 English (AutoCAD.Application.24).
- **Motor preferido:** Headless (`accoreconsole.exe /l en-US`). Tiempo de respuesta típico: 1 a 4 segundos.
- **Seguridad en consola:** `SECURELOAD 0`, `FILEDIA 0`, `CMDECHO 0`, `DIMZIN 0` en todos los scripts por lotes. Idempotencia en restauración de UCS mediante bandera `mcp_ucs_pushed`.
- **Codificación de scripts:** Archivos `.lsp` con soporte UTF-8 BOM (`utf-8-sig`) y fallback ANSI (`cp1252`), y scripts `.scr` en `cp1252` para preservar tildes, ñ y símbolos técnicos (Ø, ±, °).
- **Coordenadas:** Los puntos DXF 10 de `TEXT`, `INSERT` y `LWPOLYLINE` se almacenan en OCS y se convierten a WCS mediante `(trans pt (if norm norm '(0 0 1)) 0)`; `MTEXT` almacena DXF 10 directamente en WCS.
- **Política de respaldo:** Toda mutación genera un archivo secuencial `Nombre-Legacy-0.dwg`, `-Legacy-1.dwg`, etc. previo y ejecuta `AUDIT` y `QSAVE` solo si no ocurrieron errores de ejecución (`*mcp_err_flag*`). En caso de fallo, se revierte atómicamente el dibujo eliminando el respaldo redundante.
- **Bloqueos de archivo:** Se verifica el acceso de escritura exclusivo en disco antes de procesar archivos cerrados, reportando el usuario y máquina que tienen el archivo abierto vía `.dwl`/`.dwl2`.
- **Biblioteca unificada de LISPs:** Estructura dual estandarizada en el repositorio `lisp-library/` y en red en `\\bashemdc\ESTUDIO\PROGRAMAS\AutoCAD\Biblioteca_LISP`:
  - `LISP LISTA DE COMANDOS.txt`: Catálogo y guía de referencia unificada de comandos para usuario directo ubicado directamente en la raíz de `lisp-library/` y en `\\bashemdc\ESTUDIO\PROGRAMAS\AutoCAD\Biblioteca_LISP\LISP LISTA DE COMANDOS.txt`.
  - `Usuario_directo/`: Rutinas interactivas de uso manual diario en interfaz gráfica (`acaddoc.lsp`), con comandos cortos (`RT2`, `ARD`, `FM`, `RH`, `RAR`, `AT`, `Patitas`, `SUMLP`, etc.).
  - `Agente/`: Rutinas automatizadas puras para ejecución headless (`accoreconsole.exe`), sin interacción por teclado/pantalla (`primitives.lsp`, `audit_topology.lsp`, `computo_general_vigas.lsp`, `armado_vigas.lsp`).
- **Primitivas por lotes:** Preferir `draw_primitives_batch` sobre llamadas atómicas múltiples para consolidar transacciones y respaldos.

## 2. Criterios Aprobados del Estudio (Capas, Estilos, Escalas)


### 2.1. Estándares de Planos Estructurales y Capas (Estudio Bashem)

- **Columnas y Pilares de Hormigón:**
  - *Columnas continuas / pasantes (vienen del nivel inferior):* Capas `PILAR_HORMIGON` o `COLUMNA_HORMIGON`. En estas columnas no se colocan patitas porque la armadura continúa desde abajo.
  - *Columnas nacientes / apeadas (nacen en el nivel actual):* Capas `PILAR_HORMIGON_APEADO` o `COLUMNA_HORMIGON_APEADO`. Son los elementos exclusivos donde se insertan las patitas de anclaje (líneas, en general de 10 cm, que marcan las columnas que nacen en el nivel).
  - *Particularidad de CYPE CAD (polilíneas de columnas):* CYPE suele exportar las columnas como polilíneas pesadas (`POLYLINE`) o `LWPOLYLINE` de 5 vértices donde el 5º coincide con el 1º para simular el cierre visual; esto puede generar problemas o fallos en operaciones geométricas, cómputos o rutinas que esperan exactamente 4 vértices.
  - *Plantas agrupadas en Bloques (Casos especiales):* En ciertas obras como OPBV2, las plantas estructurales pueden estar convertidas en bloques para coordinar la comparación automática con arquitectura (no es la norma general en otras obras). Al buscar columnas o vigas, el agente debe verificar tanto entidades sueltas como la definición interna de dichos bloques.

- **Recuadros de Lámina e Impresión:**
  - *Límites de hoja:* Capa `RECUAD_LIMITES` (polilíneas cerradas `LWPOLYLINE` que definen el marco exterior de corte de cada lámina en espacio modelo).
  - *Disposición vertical de niveles:* En el espacio modelo, las plantas se organizan cronológicamente de abajo hacia arriba en el eje Y (desde subsuelos/fundaciones hasta niveles superiores/azotea).

- **Identificación de Planos, Niveles y Carátulas:**
  - Los títulos de plano y denominaciones de nivel se ubican delimitados dentro del recuadro de su respectiva lámina (habitualmente en la carátula inferior derecha o en textos principales de título bajo la planta).
  - Al generar layouts automáticos o reportes de planos, el nombre de la lámina debe extraerse cruzando el polígono de `RECUAD_LIMITES` con los textos contenidos en su interior.
### 2.2. Criterios de Armado, Despiece y Cómputo de Vigas (Estudio Bashem / CIRSOC 201)

- **Precedencia Geométrica (Encofrado vs. CYPECAD):**
  - Las dimensiones nominales de encofrado menos el recubrimiento libre (2.0 cm por cara) tienen precedencia estricta sobre el trazado esquemático generado por software externo (CYPECAD) para la deducción de medidas reales de estribos y barras.
- **Estribos Internos / Ramas Suplementarias:**
  - El ancho y longitud de los estribos interiores no son un valor fijo; dependen de la cantidad de tramos en que se subdivide transversalmente la sección y de las barras longitudinales que amarren. El cómputo exacto se realiza midiendo el ancho del estribo geométrico y redondeando a la fracción correspondiente de la longitud real de la sección.
- **Vigas de Sección Variable (Acarteladas):**
  - En vigas con cartelas o variación de canto, el cómputo de la longitud de los estribos debe determinarse a partir de la longitud promedio **por tramo** (evaluando de forma independiente cada sector o zona de estribos según la variación local de canto) y nunca mediante un promedio total global de la pieza.
  - En la rotulación gráfica del esquema de despiece, la longitud individual de la barra o estribo variable se consigna como `'VAR.'`.
- **Ramas Verticales y Ganchos (CIRSOC 201):**
  - El desarrollo de gancho estándar por extremo para ramas verticales de estribado se define según el diámetro:
    - Ø6 mm: desarrollo de gancho de 6 cm.
    - Ø8 mm: desarrollo de gancho de 8 cm.
    - Ø10 mm: desarrollo de gancho de 10 cm.
- **Cómputo General del Nivel en Planos de Pórticos ('Resumen Acero | Plano de pórticos'):**
  - *Agregación por Nivel:* Acumula las longitudes de armadura por diámetro (Ø6 a Ø25 mm) de las tablas de despiece de todas las hojas base del nivel.
  - *Cubicación y Desperdicio:* El peso por diámetro se calcula considerando la densidad nominal de acero ADN 420 y un 10% de desperdicio, redondeando cada diámetro al entero más cercano.
  - *Total General del Nivel:* Es la suma directa de los pesos enteros ya redondeados de cada diámetro (evitando discrepancias por redondeo continuo).
  - *Capas y Tipografía:* Se ubica en la última lámina del nivel (sin tablas duplicadas en cabecera). Capas: TABLAS para el reticulado/líneas y TEXTO_TABLAS para los textos. Estilo tipográfico: CYPETXT_Swis721_Ex_BT con altura 0.1333.

### 2.3. Estándares Tipográficos y Esquemas de Despiece de Armaduras

- **Factor de Ancho de Textos (Width Factor):**
  - Se aplica un factor de compresión de ancho de 0.877 (`DXF 41 = 0.877`) en textos de tablas de despiece/armado y cotas de esquemas para optimizar legibilidad y evitar desbordes en celdas y recuadros.
- **Orientación y Posición de Textos en Esquemas de Armado:**
  - Los textos de cota deben orientarse alineados con la directriz geométrica de cada segmento de barra (tramos horizontales a 0°, ganchos verticales a 90°, y tramos inclinados a su ángulo respectivo).
  - La ubicación del texto de cota debe situarse siempre en el exterior del segmento para evitar interferencias visuales con el trazado del acero.

### 2.4. Armaduras y Bandas de Distribución en Losas Macizas (CYPE CAD)

- **Capas de Armado y Distribución:**
  - `ARR_L_S_IG_LINEA`, `ARR_L_I_IG_LINEA`, `ARR_T_S_IG_LINEA`, `ARR_T_I_IG_LINEA`: Corresponden a los planos de armadura longitudinal y transversal, superior e inferior respectivamente. Contienen la geometría de las bandas de distribución (triángulos delimitadores en los extremos y segmentos de unión) y los círculos de conexión.
  - `ARR_L_S_IG_DIST`, `ARR_L_I_IG_DIST`, `ARR_T_S_IG_DIST`, `ARR_T_I_IG_DIST`: Contienen los textos que indican la longitud de la banda de distribución asociada.
- **Bandas de Distribución:**
  - Indican la zona y longitud de reparto a lo largo de la cual se distribuye una determinada barra de losa. Están conformadas por dos polilíneas en forma de triángulo enfrentadas en sus ápices en los extremos y unidas por segmentos de línea continua o a trazos.
- **Círculos de Conexión Barra-Banda:**
  - Situados en las capas `..._IG_LINEA`, indican el punto físico donde la barra de armadura se vincula con su correspondiente banda de distribución.


## 3. Índice de Skills Aprobadas (.agents/skills/)

- `cad-inspector-base`: Inspección granular en formato JSON de capas, textos, bloques (con nombre efectivo de bloques dinámicos en INSERT y BLOCK_RECORD), curvas/cómputos métricos (`include_takeoff`), ventana espacial WCS (`bbox`), proyección de campos (`fields`), comparación de versiones (`compare_with_dwg`), crítica de higiene CAD (`include_critique`), ploteo headless a PDF/PNG (`export_plot_path`), primitivas paramétricas por lotes (`draw_primitives_batch`), auditoría topológica (`audit_drawing_topology`) y vista previa visual multimodal (`capture_drawing_preview`).
- `session-curator`: Subagente de curaduría de memoria y estándares del estudio para auditar la sesión y sincronizar aprendizajes previa confirmación.
- `cad-medicion-computo`: Medición y cómputos métricos (longitudes, áreas y perímetros en `MEDICIONES.LSP`, tablas `AT`/`AF` y takeoffs headless).
- `cad-estructuras-acero`: Cálculo, cubicación y tablas de armaduras de acero (`PH`, `PESOACERO_SUM`, `RH`, `RAR` y tablas de densidades ADN 420).
- `cad-acotacion-segmentos`: Acotación y rotulación de longitudes en tramos y barras longitudinales (`MIDLEN`, `MLIN`, `ESC` y entmake determinístico).
- `cad-edicion-textos`: Rotulación, operaciones aritméticas y copia avanzada de textos (`RT`, `RT2`, `ATX`, `ARD`, `FM`, `SX`, `TXTAR`, `TXTABAJO`).
- `cad-detallado-columnas`: Detallado de columnas y patitas de anclaje (`PatitasRec`, `patitascirc`, `Patitas`, capas `PILAR_HORMIGON` vs apeadas y manejo de bloques).
- `cad-extraccion-datos`: Extracción y exportación de textos, atributos y listados de vigas (`EXTRAER-VIGAS`, volcado JSON y takeoffs CSV/Excel).
- `cad-reviewer`: Protocolo de control de calidad (QA) y verificación técnica integrada de planos CAD. Establece el checklist de auditoría (AUDIT, DBMOD=0, conciliación numérica, bbox y capas) que ejecuta obligatoriamente el mismo agente o subagente que realiza la mutación antes de reportar la finalización al usuario.
- `cad-hojas-layouts`: Generación y calibración de Layouts para publicación en lote con PUBLISH (`GH`, `GL`, `GENLAY`, Named Page Setups y bloqueo de viewports).
- `cad-armado-vigas`: Cómputo métrico, auditoría analítica, recálculo paramétrico y generación determinística de tablas de despiece ("Cuadro de armaduras de vigas") y tablas resumen ("Resumen Acero | Plano de pórticos") en planos de vigas (ARMVI) mediante la biblioteca `lisp-library/Agente/armado_vigas.lsp`.
