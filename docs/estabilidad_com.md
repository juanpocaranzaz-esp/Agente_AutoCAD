# Estándares de Estabilidad COM y Concurrencia para AutoCAD 2021

Este documento compila las directrices técnicas y lecciones aprendidas para garantizar la máxima estabilidad, rendimiento y seguridad al interactuar con AutoCAD 2021 (English) mediante la API COM (`win32com.client`) y en entornos asíncronos bajo Python 3.14+.

---

## 1. Arquitectura Híbrida: Headless-First vs. Live GUI

El agente opera bajo un principio estricto de priorización:
- **Headless (`accoreconsole.exe`):** Es la vía principal para todas las operaciones analíticas, mutaciones geométricas masivas, ploteos y extracciones de datos. Se ejecuta en 1 a 4 segundos, no interfiere con la GUI del usuario, no requiere inicialización de hilos STA y proporciona atomicidad total mediante respaldos secuenciales `-Legacy-N.dwg`.
- **Live GUI (`win32com.client`):** Es la vía secundaria interactiva. Se utiliza exclusivamente para inspeccionar la selección actual del mouse (`PickfirstSelectionSet`), abrir planos en la interfaz para que el usuario los visualice (`open_drawing_gui`), listar planos abiertos (`list_open_drawings_gui`), o cerrar documentos (`close_drawing_gui`).

---

## 2. Exclusión Mutua y Seguridad de Hilos (STA Locks)

### El Problema
La API COM de AutoCAD es un modelo de apartamento de un solo hilo (**Single-Threaded Apartment - STA**). En servidores MCP asíncronos o multihilo (como FastMCP), llamadas concurrentes desde el agente o desde hilos de fondo a la interfaz COM pueden causar corrupción de memoria o fallos fatales de Windows (`AccessViolation` / `RPC_E_WRONG_THREAD`).

### La Solución Implementada
Todas las herramientas que interactúan con la interfaz COM de AutoCAD están encapsuladas bajo un bloqueo de exclusión mutua global:
```python
COM_THREAD_LOCK = threading.Lock()

COM_THREAD_LOCK.acquire()
pythoncom.CoInitialize()
try:
    # Operaciones COM protegidas
    ...
finally:
    try:
        pythoncom.CoUninitialize()
    finally:
        COM_THREAD_LOCK.release()
```
Esto garantiza que cada llamada COM se serialice de manera estricta y segura.

---

## 3. Manejo de Rechazo de Llamadas RPC (`RPC_E_CALL_REJECTED`)

### El Problema
Cuando el usuario está interactuando activamente con AutoCAD (por ejemplo, arrastrando una entidad, con un comando en ejecución o dentro de un cuadro de diálogo modal), AutoCAD rechaza las llamadas COM externas devolviendo el código de error HRESULT `-2147418111` (`0x80010001` - `RPC_E_CALL_REJECTED`).

### La Solución Implementada
Se implementa un decorador con reintento exponencial (`com_retry`):
```python
def com_retry(max_attempts: int = 5, delay: float = 0.5):
    def decorator(func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            last_err = None
            for attempt in range(max_attempts):
                try:
                    return func(*args, **kwargs)
                except Exception as exc:
                    if _is_com_call_rejected(exc):
                        last_err = exc
                        time.sleep(delay * (attempt + 1))
                        continue
                    raise
            return {
                "status": "busy",
                "message": f"AutoCAD Live window busy (RPC_E_CALL_REJECTED) after {max_attempts} retries: {last_err}",
            }
        return wrapper
    return decorator
```

---

## 4. Tipos de Datos y Variantes COM en Python 3.14

### El Problema
En Python 3.14+, las conversiones automáticas entre tipos nativos (listas, tuplas) y estructuras Windows `VARIANT` son más estrictas. Los métodos de AutoCAD en `ModelSpace` exigen formatos binarios específicos:
- `AddLine(StartPoint, EndPoint)` requiere un arreglo de 3 flotantes de 64 bits (`VT_ARRAY | VT_R8`).
- `AddLightWeightPolyline(Vertices)` requiere un arreglo plano unidimensional de coordenadas 2D `(x1, y1, x2, y2, ...)` también en flotantes de 64 bits.

### Buenas Prácticas
1. Utilizar siempre `pythoncom.MakeVariant` o arreglos tipados con `array.array('d', ...)` si se invoca la API COM directa.
2. Para creación de primitivas geométricas, preferir la herramienta headless `draw_primitives_batch` o `entmake` en AutoLISP, las cuales manipulan la base de datos DWG directamente sin sobrecarga ni fragilidad de variantes COM.

---

## 5. Integración Vectorial Nativa con `ezdxf`

Al generar geometrías complejas (splines continuas, patrones de sombreado avanzados) con la librería `ezdxf`:
1. El archivo DXF generado puede insertarse en el espacio modelo como un bloque temporal.
2. Inmediatamente después de la inserción, invocar los métodos COM:
   ```python
   block_ref.Explode()
   block_ref.Delete()
   ```
3. Esto descompone las geometrías en entidades nativas independientes (`LINE`, `ARC`, `LWPOLYLINE`) en `ModelSpace`, permitiendo al usuario seleccionarlas y editarlas con normalidad.

---

## 6. Restricciones Geométricas Paramétricas (`GEOMCONSTRAINT`)

- Al aplicar restricciones paramétricas (tangencia, coincidencia, paralelismo) mediante comandos nativos, AutoCAD puede bloquearse si las entidades están excesivamente distantes o sobre-restringidas.
- **Regla:** Pre-posicionar matemáticamente las entidades a menos de 1 mm de su posición final esperada antes de ejecutar la restricción o utilizar `_AUTOCONSTRAIN`.

---

## 7. Catálogo de Herramientas de Ventana GUI

| Herramienta | Acción | Comportamiento |
|---|---|---|
| `open_drawing_gui` | Abrir DWG en pantalla | Si el archivo ya está abierto, activa su ventana. Si no, lo abre en la instancia visible de AutoCAD. |
| `list_open_drawings_gui` | Listar DWGs abiertos | Reporta nombres, rutas completas, si tienen cambios pendientes (`saved`) y cuál es la ventana activa. |
| `close_drawing_gui` | Cerrar DWG en pantalla | Permite cerrar el dibujo activo o uno específico por nombre, con opción de guardar cambios (`save=True/False`). |
| `execute_cad_live` | Inyectar LISP en vivo | Ejecuta LISP en la selección activa con gestión de UndoMarks y manejo de errores. |
