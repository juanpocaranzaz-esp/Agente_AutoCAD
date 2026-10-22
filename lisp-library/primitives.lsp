;;; primitives.lsp
;;; Deterministic, headless-compatible parametric drawing primitives for AutoCAD 2021 (accoreconsole.exe)
;;; Uses standard AutoLISP (entmake / tblsearch) without GUI ActiveX dependencies.

(vl-load-com)

(defun mcp-ensure-layer (lyrName colorInt / tbl)
  (if (or (not lyrName) (= lyrName ""))
    (setq lyrName "0")
  )
  (if (not (tblsearch "LAYER" lyrName))
    (entmake
      (list
        '(0 . "LAYER")
        '(100 . "AcDbSymbolTableRecord")
        '(100 . "AcDbLayerTableRecord")
        (cons 2 lyrName)
        '(70 . 0)
        (cons 62 (if (and colorInt (> colorInt 0) (< colorInt 256)) colorInt 7))
        '(6 . "Continuous")
      )
    )
  )
  lyrName
)

(defun mcp-pt3d (pt elev)
  (list
    (float (if (car pt) (car pt) 0.0))
    (float (if (cadr pt) (cadr pt) 0.0))
    (float (if (caddr pt) (caddr pt) (if elev elev 0.0)))
  )
)

(defun mcp-draw-line (p1 p2 lyr colorInt / dxfList ent)
  (setq lyr (mcp-ensure-layer lyr colorInt))
  (setq dxfList
    (list
      '(0 . "LINE")
      '(100 . "AcDbEntity")
      (cons 8 lyr)
      '(210 0.0 0.0 1.0)
      '(100 . "AcDbLine")
      (cons 10 (mcp-pt3d p1 0.0))
      (cons 11 (mcp-pt3d p2 0.0))
    )
  )
  (if (and colorInt (> colorInt 0) (< colorInt 256))
    (setq dxfList (append dxfList (list (cons 62 colorInt))))
  )
  (if (entmake dxfList)
    (progn
      (setq ent (entlast))
      (princ (strcat "\n[MCP_PRIMITIVE_HANDLE]:" (cdr (assoc 5 (entget ent))) "\n"))
      ent
    )
    (progn
      (setq *mcp_err_flag* T)
      (princ "\n[MCP_LISP_ERROR]: entmake failed in mcp-draw-line\n")
      nil
    )
  )
)

(defun mcp-draw-circle (center rad lyr colorInt / dxfList ent)
  (setq lyr (mcp-ensure-layer lyr colorInt))
  (setq dxfList
    (list
      '(0 . "CIRCLE")
      '(100 . "AcDbEntity")
      (cons 8 lyr)
      '(210 0.0 0.0 1.0)
      '(100 . "AcDbCircle")
      (cons 10 (mcp-pt3d center 0.0))
      (cons 40 (float rad))
    )
  )
  (if (and colorInt (> colorInt 0) (< colorInt 256))
    (setq dxfList (append dxfList (list (cons 62 colorInt))))
  )
  (if (entmake dxfList)
    (progn
      (setq ent (entlast))
      (princ (strcat "\n[MCP_PRIMITIVE_HANDLE]:" (cdr (assoc 5 (entget ent))) "\n"))
      ent
    )
    (progn
      (setq *mcp_err_flag* T)
      (princ "\n[MCP_LISP_ERROR]: entmake failed in mcp-draw-circle\n")
      nil
    )
  )
)

(defun mcp-draw-arc (center rad startAngRad endAngRad lyr colorInt / dxfList ent)
  (setq lyr (mcp-ensure-layer lyr colorInt))
  (setq dxfList
    (list
      '(0 . "ARC")
      '(100 . "AcDbEntity")
      (cons 8 lyr)
      '(210 0.0 0.0 1.0)
      '(100 . "AcDbCircle")
      (cons 10 (mcp-pt3d center 0.0))
      (cons 40 (float rad))
      '(100 . "AcDbArc")
      (cons 50 (float startAngRad))
      (cons 51 (float endAngRad))
    )
  )
  (if (and colorInt (> colorInt 0) (< colorInt 256))
    (setq dxfList (append dxfList (list (cons 62 colorInt))))
  )
  (if (entmake dxfList)
    (progn
      (setq ent (entlast))
      (princ (strcat "\n[MCP_PRIMITIVE_HANDLE]:" (cdr (assoc 5 (entget ent))) "\n"))
      ent
    )
    (progn
      (setq *mcp_err_flag* T)
      (princ "\n[MCP_LISP_ERROR]: entmake failed in mcp-draw-arc\n")
      nil
    )
  )
)

(defun mcp-draw-lwpolyline (pts closedFlag lyr colorInt elev / dxfList pt ent)
  (setq lyr (mcp-ensure-layer lyr colorInt))
  (setq dxfList
    (list
      '(0 . "LWPOLYLINE")
      '(100 . "AcDbEntity")
      (cons 8 lyr)
      '(210 0.0 0.0 1.0)
      '(100 . "AcDbPolyline")
      (cons 90 (length pts))
      (cons 70 (if closedFlag 1 0))
      (cons 38 (float (if elev elev 0.0)))
    )
  )
  (if (and colorInt (> colorInt 0) (< colorInt 256))
    (setq dxfList (append dxfList (list (cons 62 colorInt))))
  )
  (foreach pt pts
    (setq dxfList
      (append
        dxfList
        (list (list 10 (float (car pt)) (float (cadr pt))))
      )
    )
  )
  (if (entmake dxfList)
    (progn
      (setq ent (entlast))
      (princ (strcat "\n[MCP_PRIMITIVE_HANDLE]:" (cdr (assoc 5 (entget ent))) "\n"))
      ent
    )
    (progn
      (setq *mcp_err_flag* T)
      (princ "\n[MCP_LISP_ERROR]: entmake failed in mcp-draw-lwpolyline\n")
      nil
    )
  )
)

(defun mcp-draw-rectangle (c1 c2 lyr closedFlag colorInt / x1 y1 x2 y2 minX minY maxX maxY zVal pts)
  (setq x1   (float (car c1))
        y1   (float (cadr c1))
        x2   (float (car c2))
        y2   (float (cadr c2))
        minX (min x1 x2)
        minY (min y1 y2)
        maxX (max x1 x2)
        maxY (max y1 y2)
        zVal (if (caddr c1) (float (caddr c1)) 0.0)
        pts  (list
               (list minX minY)
               (list maxX minY)
               (list maxX maxY)
               (list minX maxY)
             )
  )
  (mcp-draw-lwpolyline pts closedFlag lyr colorInt zVal)
)

(defun mcp-insert-block-param (blkName insPt sx sy rotRad lyr colorInt / dxfList ent)
  (setq lyr (mcp-ensure-layer lyr colorInt))
  (if (not (tblsearch "BLOCK" blkName))
    (progn
      (setq *mcp_err_flag* T)
      (princ (strcat "\n[MCP_LISP_ERROR]: Block definition not found in drawing: " blkName "\n"))
      nil
    )
    (progn
      (setq dxfList
        (list
          '(0 . "INSERT")
          '(100 . "AcDbEntity")
          (cons 8 lyr)
          '(210 0.0 0.0 1.0)
          '(100 . "AcDbBlockReference")
          (cons 2 blkName)
          (cons 10 (mcp-pt3d insPt 0.0))
          (cons 41 (float (if sx sx 1.0)))
          (cons 42 (float (if sy sy 1.0)))
          (cons 43 (abs (float (if sx sx 1.0))))
          (cons 50 (float (if rotRad rotRad 0.0)))
        )
      )
      (if (and colorInt (> colorInt 0) (< colorInt 256))
        (setq dxfList (append dxfList (list (cons 62 colorInt))))
      )
      (if (entmake dxfList)
        (progn
          (setq ent (entlast))
          (princ (strcat "\n[MCP_PRIMITIVE_HANDLE]:" (cdr (assoc 5 (entget ent))) "\n"))
          ent
        )
        (progn
          (setq *mcp_err_flag* T)
          (princ "\n[MCP_LISP_ERROR]: entmake failed in mcp-insert-block-param\n")
          nil
        )
      )
    )
  )
)
(princ)
