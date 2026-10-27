---
name: cad-armado-vigas
description: Cómputo métrico, auditoría analítica, recálculo paramétrico y generación determinística de tablas de despiece ("Cuadro de armaduras de vigas") y tablas resumen ("Resumen Acero | Plano de pórticos") en planos de vigas (ARMVI) para el agente Clavi.
---

# Skill: Cómputo y Tablas de Armado de Vigas (`cad-armado-vigas`)

## 1. Propósito y Cuándo Activar esta Skill
Activar esta skill cuando el agente (Clavi) deba:
- Auditar, verificar y recalcular el cómputo de armaduras de vigas en planos de pórticos (CYPECAD / CIRSOC 201).
- Generar o reemplazar el **Cuadro de armaduras de vigas** (despiece por lámina) y/o la tabla de **Resumen Acero | Plano de pórticos** (resumen general del plano).
- Detectar discrepancias entre la geometría real del encofrado de hormigón y los esquemas simplificados de armadura generados por el software de cálculo.
- Estandarizar la presentación de tablas según los criterios de ingeniería estructural y tipografía del Estudio Bashem.

---

## 2. Criterios de Ingeniería Estructural y Reglas del Estudio

### A. Precedencia Geométrica Analítica de Encofrados:
- La geometría nominal de la viga en el encofrado (ancho $b$ y altura $h$ de la sección de hormigón en capa `SEC_CONT_VIG_HORMIGON_SECCION` o textos de sección `20x45`, `25x60`, etc.) menos el recubrimiento estricto de **$2.0\text{ cm}$** por cara prevalece analíticamente sobre las polilíneas de despiece esquemático de CYPECAD.
- Dimensiones del estribo cerrado perimetral:
  $$\text{Ancho útil } w = b_{\text{encofrado}} - 2 \cdot 2.0\text{ cm}$$
  $$\text{Altura útil } h_{\text{útil}} = h_{\text{encofrado}} - 2 \cdot 2.0\text{ cm}$$
  $$\text{Longitud de estribo } L_{\text{est}} = 2 \cdot w + 2 \cdot h_{\text{útil}} + G_{\text{adic}}$$
  donde $G_{\text{adic}}$ es el desarrollo adicional por gancho a 135° según CIRSOC 201 ($14\text{ cm}$ en Ø6, $17\text{ cm}$ en Ø8, $20\text{ cm}$ en Ø10, $23\text{ cm}$ en Ø12).

### B. Estribos Internos (Subdivisiones Transversales):
- **Cálculo:** El ancho de los estribos internos se determina midiendo el ancho geométrico del estribo y redondeándolo a la fracción modular de la longitud real de la sección transversal, según la cantidad de ramas/subdivisiones y las barras longitudinales agarradas (evitar suposiciones rígidas como asumir 1/3 ciegamente).
  $$w_{\text{int}} = \text{round}\left(\frac{b_{\text{encofrado}} - 2 \cdot \text{rec}}{n_{\text{subdivisiones}}}\right)$$

### C. Vigas Acarteladas (Variables):
- En vigas con canto variable (acarteladas), el cómputo de estribos se calcula utilizando la **longitud promedio por tramo/sector independiente** (no un promedio global de toda la viga continua):
  $$h_{\text{prom}} = \frac{h_{\text{mín}} + h_{\text{máx}}}{2}$$
- En la tabla de despiece, la columna de longitud individual (`Long.`) se rotula como `'VAR.'`, mientras que la longitud total del tramo y el peso en kg se computan con la longitud promedio real del sector.

### D. Ramas Verticales / Trabas (CIRSOC 201):
- Desarrollo de gancho estándar por extremo en ramas verticales:
  - $\varnothing 6$: $6\text{ cm}$ por extremo.
  - $\varnothing 8$: $8\text{ cm}$ por extremo.
  - $\varnothing 10$: $10\text{ cm}$ por extremo.
  - $\varnothing 12$: $12\text{ cm}$ por extremo.
  $$\text{Longitud total de rama } L = h_{\text{útil}} + 2 \cdot G_{\text{rama}}$$

### E. Tipografía, Estilos y Factor de Ancho Obligatorio:
- **Factor de Ancho (Width Factor):** Es **estrictamente obligatorio** aplicar `DXF 41 = 0.877` a todos los textos de tablas (`TEXTO_TABLAS`) y cotas numéricas de esquemas (`TEXTOS_COTAS_DESPIECES_TABLA`).
- **Estilo de texto:** `CYPETXT_Swis721_Ex_BT` (o el estilo por defecto si no está cargado).
- **Capas oficiales:**
  - `TABLAS`: Líneas de marcos, grillas y divisiones de celdas.
  - `TEXTO_TABLAS`: Encabezados de tabla, nombres de pórticos, posiciones, diámetros, cantidades y totales.
  - `DESPIECES_TABLA`: Polilíneas (`LWPOLYLINE`) del dibujo esquemático de barras y estribos.
  - `TEXTOS_COTAS_DESPIECES_TABLA`: Textos de cotas de longitud y ganchos de las barras.

### F. Orientación Geométrica de Cotas en Esquemas de Barras:
- Las cotas numéricas en los esquemas deben ubicarse en el exterior de la barra y orientarse según la directriz geométrica de cada segmento:
  - **Segmentos horizontales:** Ángulo $0.0^\circ$ ($0\text{ rad}$), centrado encima o debajo de la barra (`j = (1, 0)` o `(1, 3)`).
  - **Ganchos verticales:** Ángulo $90.0^\circ$ ($\pi/2\text{ rad}$), centrado al exterior de la patilla (`j = (1, 2)` con desplazamiento de $0.07\text{ m}$).
  - **Ganchos inclinados:** Ángulo normalizado $\theta \in (-\pi/2, \pi/2]$ a lo largo del segmento inclinado, posicionado a $0.08\text{ m}$ perpendicular al eje.
  - **Estribos:** Cota de ancho a $0.0^\circ$ en la base exterior; cota de altura a $90.0^\circ$ en el lateral izquierdo exterior; rótulo de diámetro del gancho a $45.0^\circ$ en la esquina superior derecha.

---

## 3. Biblioteca AutoLISP para Clavi (`lisp-library/Agente/armado_vigas.lsp`)

La biblioteca está optimizada para ejecución headless (`accoreconsole.exe`) con primitivas puras `entmake` determinísticas, sin dependencias ActiveX ni prompts modales.

### Funciones Principales:

1. **`clavi:dibujar-cuadro-despiece (pt_sup_der lista_porticos lista_subtotales peso_total)`**
   - **`pt_sup_der`**: Coordenada `(x_der y_sup)` de la esquina superior derecha de la tabla en la lámina.
   - **`lista_porticos`**: Lista de pórticos con su estructura:
     ```lisp
     (list
       (list "Pórtico 1"
         (list
           (list 'RECTA pos diam num l_ind l_tot peso '(l_dibujo txt_l))
           (list 'GANCHOS pos diam num l_ind l_tot peso '(l_dibujo h_gancho txt_l txt_g1 txt_g2))
           (list 'INCLINADA pos diam num l_ind l_tot peso '(l_dibujo l_pat ang_rad txt_l txt_g1 txt_g2))
           (list 'ESTRIBO pos diam num l_ind l_tot peso '(w_dib h_dib diam_mm txt_w txt_h))
           (list 'RAMA pos diam num l_ind l_tot peso '(h_dib diam_mm txt_h txt_g))
         )
       )
       ...
     )
     ```
   - **`lista_subtotales`**: Lista de pares `(diametro peso_kg)` para el bloque resumen inferior.
   - **`peso_total`**: Peso total acumulado de la lámina en kg.
   - **Retorno:** Coordenada `y` inferior de cierre de la tabla.

2. **`clavi:dibujar-resumen-acero (pt_anc datos)`**
   - Dibuja la tabla "Resumen Acero | Plano de pórticos" a partir del punto de inserción `pt_anc` y la lista de filas `'( (diametro long_total peso_con_10) ... )`.

3. **`clavi:limpiar-tablas-lamina (pt_min pt_max)`**
   - Elimina de forma segura las entidades previas en capas de tablas dentro de la ventana de selección.

4. **`clavi:reemplazar-cuadro-despiece (pt_min pt_max pt_sup_der lista_porticos lista_subtotales peso_total)`**
   - Ejecuta la limpieza de la tabla obsoleta y redibuja la tabla recalculada en una sola transacción atómica.

5. **Funciones de Cálculo Analítico:**
   - `(clavi:calc-estribo-nominal b_encofrado h_encofrado diam recubrimiento)` $\rightarrow$ `(w_util h_util l_total)`
   - `(clavi:calc-estribo-interno b_real num_subdivs diam recubrimiento)` $\rightarrow$ `w_interno`
   - `(clavi:calc-estribo-variable b_real h_min h_max diam recubrimiento)` $\rightarrow$ `(w_util h_util l_prom)`
   - `(clavi:peso-nominal-adn420 diam)` $\rightarrow$ `kg/m`
   - `(clavi:gancho-rama-cirsoc diam)` $\rightarrow$ `gancho_cm`

---

## 4. Protocolo de Ejecución de Clavi (Flujo de Trabajo Operativo)

Para auditar o transformar planos de armado de vigas:

1. **Paso 1: Inspección Headless de Láminas y Entidades**
   - Cargar entidades del DWG con `inspect_cad_headless` o volcado JSON.
   - Detectar recuadros de lámina (`RECUAD_LIMITES`) y ordenar la secuencia de lectura natural.

2. **Paso 2: Contraste de Encofrados vs Tablas**
   - Comparar las secciones nominales de vigas (`SEC_CONT_VIG_HORMIGON_SECCION` o textos de sección) contra las dimensiones acotadas en los esquemas de estribos de la tabla CYPE.
   - Identificar discrepancias:
     - Si la tabla acota dimensiones erróneas respecto al encofrado nominal menos recubrimiento (2.0 cm), corregir las dimensiones de estribo aplicando `clavi:calc-estribo-nominal`.
     - Si hay vigas acarteladas, aplicar `clavi:calc-estribo-variable` por tramo independiente y marcar `'VAR.'`.
     - Si hay estribos internos, calcular el ancho proporcional modular con `clavi:calc-estribo-interno`.

3. **Paso 3: Generación Paramétrica y Reemplazo**
   - Cargar `lisp-library/Agente/armado_vigas.lsp`.
   - Si se requiere conservar la lámina original y generar la lámina corregida, duplicar o mover con offset controlado.
   - Invocar `clavi:reemplazar-cuadro-despiece` o `clavi:dibujar-cuadro-despiece` aplicando width factor 0.877 y cotas orientadas.
   - Ejecutar `_.AUDIT _Y` y `_.QSAVE` verificando `DBMOD == 0`.

4. **Paso 4: Auditoría Obligatoria de Control de Calidad Integrada (QA)**
   - Ejecutar el checklist de QA integrado dentro del mismo agente/subagente ejecutor:
     - Comprobar que no existan entidades fuera de lámina ni textos huérfanos.
     - Confirmar que todos los textos de tablas posean width factor 0.877.
     - Validar que las cotas de los esquemas sigan la orientación de sus segmentos.
     - Comprobar analíticamente que los pesos totales y subtotales coincidan con las longitudes y diámetros.
     - Verificar que el retorno de `mutate_cad_headless` confirme `AUDIT` limpio y `DBMOD == 0`.

5. **Paso 5: Curaduría de Sesión (Session Curator)**
   - Si el usuario valida o expresa satisfacción con el resultado, invocar al subagente `session-curator` para registrar aprendizajes y actualizar la memoria según los protocolos vigentes.
