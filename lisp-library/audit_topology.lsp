;;; audit_topology.lsp
;;; Headless topological audit and automatic geometry cleanup for AutoCAD 2021 (accoreconsole.exe)
;;; Detects and optionally repairs:
;;; - Unclosed LWPOLYLINE entities whose start and end vertices nearly coincide (near-closed polylines)
;;; - Exact/within-tolerance collinear duplicate LINE entities
;;; - Zero-length degenerate LINE and LWPOLYLINE entities

(vl-load-com)

(defun mcp-topo-pt-dist2d (p1 p2 / dx dy)
  (setq dx (- (car p2) (car p1))
        dy (- (cadr p2) (cadr p1)))
  (sqrt (+ (* dx dx) (* dy dy)))
)

(defun mcp-topo-floor (val / i)
  (setq i (fix val))
  (if (and (< val 0.0) (/= val (float i)))
    (1- i)
    i
  )
)

(defun mcp-topo-norm-seg-key (p1 p2 tol / s1 s2 k1 k2)
  (setq tol (if (and tol (> tol 1e-6)) tol 1.0)
        k1  (strcat (rtos (* (mcp-topo-floor (+ (/ (car p1) tol) 0.5)) tol) 2 2) ","
                    (rtos (* (mcp-topo-floor (+ (/ (cadr p1) tol) 0.5)) tol) 2 2))
        k2  (strcat (rtos (* (mcp-topo-floor (+ (/ (car p2) tol) 0.5)) tol) 2 2) ","
                    (rtos (* (mcp-topo-floor (+ (/ (cadr p2) tol) 0.5)) tol) 2 2)))
  (if (< (vl-string-mismatch k1 k2) (strlen k1))
    (if (< (ascii (substr k1 (1+ (vl-string-mismatch k1 k2)) 1))
           (ascii (substr k2 (1+ (vl-string-mismatch k1 k2)) 1)))
      (strcat k1 "|" k2)
      (strcat k2 "|" k1)
    )
    (strcat k1 "|" k2)
  )
)

(defun mcp-audit-and-clean-topology (filterLayersRaw snapTol nearMissTol autoFix / flt ss i ent ed etype lyr p1 p2 d
                                     pts item isClosed n closedFixedCount dupRemovedCount zeroRemovedCount
                                     unclosedCount nearClosedCount seenSegs segKey newEd)
  (setq flt (list '(0 . "LINE,LWPOLYLINE")))
  (if (and filterLayersRaw (/= filterLayersRaw "") (/= filterLayersRaw "*"))
    (setq flt (append flt (list (cons 8 filterLayersRaw))))
  )
  (setq ss (ssget "_X" flt)
        i 0
        closedFixedCount 0
        dupRemovedCount  0
        zeroRemovedCount 0
        unclosedCount    0
        nearClosedCount  0
        seenSegs         nil)
  (if ss
    (while (< i (sslength ss))
      (setq ent   (ssname ss i)
            ed    (entget ent)
            etype (cdr (assoc 0 ed))
            lyr   (cdr (assoc 8 ed)))
      (cond
        ((= etype "LINE")
         (setq p1 (cdr (assoc 10 ed))
               p2 (cdr (assoc 11 ed))
               d  (if (and p1 p2) (mcp-topo-pt-dist2d p1 p2) 0.0))
         (if (<= d 1e-5)
           (if autoFix
             (progn
               (entdel ent)
               (setq zeroRemovedCount (1+ zeroRemovedCount))
             )
           )
           (progn
             (setq segKey (strcat (strcase lyr) ":" (mcp-topo-norm-seg-key p1 p2 snapTol)))
             (if (member segKey seenSegs)
               (if autoFix
                 (progn
                   (entdel ent)
                   (setq dupRemovedCount (1+ dupRemovedCount))
                 )
               )
               (setq seenSegs (cons segKey seenSegs))
             )
           )
         ))
        ((= etype "LWPOLYLINE")
         (setq pts nil
               isClosed (= (logand (if (assoc 70 ed) (cdr (assoc 70 ed)) 0) 1) 1))
         (foreach item ed
           (if (= (car item) 10)
             (setq pts (cons (cdr item) pts))
           )
         )
         (setq pts (reverse pts)
               n   (length pts))
         (setq polyLen 0.0
               k_idx 0)
         (while (< k_idx (1- n))
           (setq polyLen (+ polyLen (mcp-topo-pt-dist2d (nth k_idx pts) (nth (1+ k_idx) pts))))
           (setq k_idx (1+ k_idx))
         )
         (if (and isClosed (> n 1))
           (setq polyLen (+ polyLen (mcp-topo-pt-dist2d (nth (1- n) pts) (nth 0 pts))))
         )
         (if (<= polyLen 1e-5)
           (if autoFix
             (progn
               (entdel ent)
               (setq zeroRemovedCount (1+ zeroRemovedCount))
             )
           )
         )
         (if (and (not isClosed) (>= n 3) (> polyLen 1e-5))
           (progn
             (setq unclosedCount (1+ unclosedCount)
                   p1 (car pts)
                   p2 (nth (1- n) pts)
                   d  (mcp-topo-pt-dist2d p1 p2))
             (if (<= d nearMissTol)
               (progn
                 (setq nearClosedCount (1+ nearClosedCount))
                 (if autoFix
                   (progn
                     (setq newEd
                       (if (assoc 70 ed)
                         (subst (cons 70 (logior (cdr (assoc 70 ed)) 1)) (assoc 70 ed) ed)
                         (append ed (list '(70 . 1)))
                       )
                     )
                     (if (entmod newEd)
                       (setq closedFixedCount (1+ closedFixedCount))
                     )
                   )
                 )
               )
             )
           )
         ))
      )
      (setq i (1+ i))
    )
  )
  (princ
    (strcat
      "\n[MCP_TOPO_CLEAN_SUMMARY]:"
      "closed_fixed=" (itoa closedFixedCount)
      ",dup_removed=" (itoa dupRemovedCount)
      ",zero_removed=" (itoa zeroRemovedCount)
      ",unclosed_found=" (itoa unclosedCount)
      ",near_closed_found=" (itoa nearClosedCount)
      "\n"
    )
  )
  (princ)
)
(princ)
