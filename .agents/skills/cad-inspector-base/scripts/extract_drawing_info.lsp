;;; extract_drawing_info.lsp
;;; Headless inspection tool for AutoCAD 2021 (accoreconsole.exe)
;;; Generates RFC 8259 compliant JSON with layer names, texts, blocks, dynamic effective names,
;;; multiline attributes, and drawing bounds with strict formatting.

(vl-load-com)

(defun str-replace-all (str old new / pos oldLen search-idx)
  (setq oldLen (strlen old)
        search-idx 0)
  (if (> oldLen 0)
    (while (setq pos (vl-string-search old str search-idx))
      (setq str (strcat (substr str 1 pos) new (substr str (+ pos oldLen 1))))
      (setq search-idx (+ pos (strlen new)))
    )
  )
  str
)

(defun clean-mtext-braces (str / i len res ch nxt)
  (setq len (strlen str)
        res ""
        i 1)
  (while (<= i len)
    (setq ch (substr str i 1))
    (cond
      ((= ch "\\")
       (if (<= (1+ i) len)
         (progn
           (setq nxt (substr str (1+ i) 1))
           (cond
             ((or (= nxt "{") (= nxt "}"))
              (setq res (strcat res nxt)
                    i (+ i 2)))
             ((= nxt "\\")
              (setq res (strcat res "\\\\")
                    i (+ i 2)))
             (t
              (setq res (strcat res ch)
                    i (1+ i)))
           )
         )
         (setq res (strcat res ch)
               i (1+ i))
       ))
      ((or (= ch "{") (= ch "}"))
       (setq i (1+ i)))
      (t
       (setq res (strcat res ch)
             i (1+ i)))
    )
  )
  res
)

(defun unformat-mtext (str / prefixes pos semi search-idx inner)
  (if (not str) (setq str ""))
  ;; 1. Protect literal double-backslashes (\\) before formatting code replacements
  (setq str (str-replace-all str "\\\\" "\001BSLASH\001"))

  ;; 2. Newlines and non-breaking spaces
  (setq str (str-replace-all str "\\P" "\n"))
  (setq str (str-replace-all str "\\~" " "))

  ;; 3. Remove formatting tags (\A...;, \C...;, \f...;, \H...;, \Q...;, \T...;, \W...;, \p...;)
  (setq prefixes '("\\A" "\\C" "\\c" "\\f" "\\F" "\\H" "\\Q" "\\T" "\\W" "\\p"))
  (foreach prefix prefixes
    (setq search-idx 0)
    (while (setq pos (vl-string-search prefix str search-idx))
      (setq semi (vl-string-search ";" str (+ pos (strlen prefix))))
      (if (and semi (< (- semi pos) 64))
        (setq str (strcat (substr str 1 pos) (substr str (+ semi 2))))
        (setq search-idx (+ pos (strlen prefix)))
      )
    )
  )

  ;; 4. Stacked fractions (\S...;)
  (setq search-idx 0)
  (while (setq pos (vl-string-search "\\S" str search-idx))
    (setq semi (vl-string-search ";" str (+ pos 2)))
    (if (and semi (< (- semi pos) 64))
      (progn
        (setq inner (substr str (+ pos 3) (- semi (+ pos 2))))
        (setq inner (vl-string-translate "#" "/" inner))
        (if (and (> (strlen inner) 0) (= (substr inner (strlen inner) 1) "^"))
          (setq inner (substr inner 1 (1- (strlen inner))))
        )
        (if (and (> (strlen inner) 0) (= (substr inner 1 1) "^"))
          (setq inner (substr inner 2))
        )
        (setq inner (str-replace-all inner "^" "/"))
        (setq str (strcat (substr str 1 pos) inner (substr str (+ semi 2))))
      )
      (setq search-idx (+ pos 2))
    )
  )

  ;; 5. Simple toggles (\L, \O, \K)
  (foreach code '("\\L" "\\l" "\\O" "\\o" "\\K" "\\k")
    (setq str (str-replace-all str code ""))
  )

  ;; 6. Clean grouping braces without inserting spaces, preserving \{ and \}
  (setq str (clean-mtext-braces str))

  ;; 7. Restore protected literal double-backslashes
  (setq str (str-replace-all str "\001BSLASH\001" "\\\\"))
  str
)

(defun esc-json (str is-mtext / res ch code i len)
  (if (not str) (setq str ""))
  (if is-mtext
    (setq str (unformat-mtext str))
  )
  (setq len (strlen str)
        res ""
        i 1)
  (while (<= i len)
    (setq ch   (substr str i 1)
          code (ascii ch))
    (cond
      ((= code 92) (setq res (strcat res "\\\\")))
      ((= code 34) (setq res (strcat res "\\\"")))
      ((= code 10) (setq res (strcat res "\\n")))
      ((= code 13) (setq res (strcat res "\\r")))
      ((= code 9)  (setq res (strcat res "\\t")))
      ((< code 32) (setq res (strcat res " ")))
      (t           (setq res (strcat res ch)))
    )
    (setq i (1+ i))
  )
  ;; Convert technical CAD symbols to exact JSON Unicode escapes in TEXT, MTEXT, and ATTRIB
  (setq res (str-replace-all res "%%c" "\\u00d8"))
  (setq res (str-replace-all res "%%C" "\\u00d8"))
  (setq res (str-replace-all res "%%d" "\\u00b0"))
  (setq res (str-replace-all res "%%D" "\\u00b0"))
  (setq res (str-replace-all res "%%p" "\\u00b1"))
  (setq res (str-replace-all res "%%P" "\\u00b1"))
  res
)

(defun get-full-text (ed / txt item)
  (setq txt "")
  (foreach item ed
    (if (= (car item) 3)
      (setq txt (strcat txt (cdr item)))
    )
  )
  (if (assoc 1 ed)
    (setq txt (strcat txt (cdr (assoc 1 ed))))
  )
  txt
)

(defun get-attrib-text (attEd / isMulti subList fullTxt item)
  (setq isMulti (member '(101 . "Embedded Object") attEd))
  (if isMulti
    (progn
      ;; Sublist starting right after '(101 . "Embedded Object")
      (setq subList (cdr isMulti)
            fullTxt "")
      (foreach item subList
        (if (= (car item) 3)
          (setq fullTxt (strcat fullTxt (cdr item)))
        )
      )
      (if (assoc 1 subList)
        (setq fullTxt (strcat fullTxt (cdr (assoc 1 subList))))
        (if (assoc 1 attEd)
          (setq fullTxt (strcat fullTxt (cdr (assoc 1 attEd))))
        )
      )
      fullTxt
    )
    (if (assoc 1 attEd) (cdr (assoc 1 attEd)) "")
  )
)

(defun num-json (val / s)
  (setq s (rtos (if val val 0.0) 2 4))
  (cond
    ((= (substr s 1 1) ".") (strcat "0" s))
    ((= (substr s 1 2) "-.") (strcat "-0." (substr s 3)))
    (t s)
  )
)

(defun pt-wcs-json (pt norm / wpt p3d)
  (if pt
    (progn
      (setq p3d (list (car pt) (cadr pt) (if (caddr pt) (caddr pt) 0.0)))
      (if norm
        (setq wpt (trans p3d norm 0))
        (setq wpt p3d)
      )
      (strcat "["
              (num-json (car wpt)) ","
              (num-json (cadr wpt)) ","
              (num-json (if (caddr wpt) (caddr wpt) 0.0))
              "]")
    )
    "null"
  )
)

(defun resolve-rep-dict (xDict / repDict repData effObj btagHandle)
  (if (and xDict (setq repDict (dictsearch xDict "AcDbBlockRepresentation")))
    (progn
      (setq effObj (cdr (assoc 340 repDict)))
      (if (and (not effObj) (setq repData (dictsearch (cdr (assoc -1 repDict)) "AcDbRepData")))
        (setq effObj (cdr (assoc 340 repData)))
      )
      (if (and (not effObj) (setq repData (dictsearch (cdr (assoc -1 repDict)) "AcDbBlockRepETemplate")))
        (setq effObj (cdr (assoc 340 repData)))
      )
      (if (and (not effObj) (setq repData (dictsearch (cdr (assoc -1 repDict)) "AcDbBlockRepBTag")))
        (progn
          (setq btagHandle (cdr (assoc 1005 repData)))
          (if (and btagHandle (handent btagHandle))
            (setq effObj (handent btagHandle))
          )
        )
      )
      (if (and effObj (entget effObj))
        (cdr (assoc 2 (entget effObj)))
        nil
      )
    )
    nil
  )
)

(defun get-eff-name (ent blkName / blkEnt blkRec entXDict blkXDict resolved)
  (setq resolved nil)
  (if (and blkName (= (strcase (substr blkName 1 2)) "*U"))
    (progn
      ;; 1. Try INSERT entity extension dictionary first
      (if ent
        (progn
          (setq entXDict (cdr (assoc 360 (entget ent))))
          (setq resolved (resolve-rep-dict entXDict))
        )
      )
      ;; 2. Fallback to BLOCK_RECORD extension dictionary
      (if (not resolved)
        (progn
          (setq blkEnt (tblobjname "BLOCK" blkName))
          (if blkEnt
            (progn
              (setq blkRec (cdr (assoc 330 (entget blkEnt))))
              (if blkRec
                (progn
                  (setq blkXDict (cdr (assoc 360 (entget blkRec))))
                  (setq resolved (resolve-rep-dict blkXDict))
                )
              )
            )
          )
        )
      )
    )
  )
  (if resolved resolved blkName)
)

(defun csv-token-allowed-p (token filterCsv)
  (if (or (not filterCsv) (= filterCsv "") (= filterCsv "*"))
    T
    (if (vl-string-search (strcat "," (strcase token) ",") filterCsv) T nil)
  )
)

(defun layer-allowed-p (lyr filterCsv)
  (csv-token-allowed-p lyr filterCsv)
)

(defun type-allowed-p (etype filterTypesCsv)
  (or (csv-token-allowed-p etype filterTypesCsv)
      (and (= etype "LAYER") (csv-token-allowed-p "LAYERS" filterTypesCsv))
      (and (= etype "TEXT") (csv-token-allowed-p "TEXTS" filterTypesCsv))
      (and (= etype "MTEXT") (csv-token-allowed-p "TEXTS" filterTypesCsv))
      (and (= etype "INSERT") (or (csv-token-allowed-p "BLOCKS" filterTypesCsv) (csv-token-allowed-p "INSERTS" filterTypesCsv)))
      (and (= etype "BLOCK") (or (csv-token-allowed-p "BLOCKS" filterTypesCsv) (csv-token-allowed-p "INSERTS" filterTypesCsv))))
)

(defun space-allowed-p (sp spaceFilter)
  (if (or (not spaceFilter) (= spaceFilter "") (= spaceFilter "ALL"))
    T
    (= (strcase sp) spaceFilter)
  )
)

(defun pt-wcs-coords (pt norm / p3d)
  (if pt
    (progn
      (setq p3d (list (car pt) (cadr pt) (if (caddr pt) (caddr pt) 0.0)))
      (if norm
        (trans p3d norm 0)
        p3d
      )
    )
    nil
  )
)

(defun parse-bbox-csv (bboxStr / p1 p2 p3 s1 s2 s3 s4 x1 y1 x2 y2 minX minY maxX maxY)
  (if (and bboxStr (/= bboxStr "") (/= bboxStr "*"))
    (progn
      (setq p1 (vl-string-search "," bboxStr))
      (setq p2 (if p1 (vl-string-search "," bboxStr (1+ p1)) nil))
      (setq p3 (if p2 (vl-string-search "," bboxStr (1+ p2)) nil))
      (if (and p1 p2 p3)
        (progn
          (setq s1 (substr bboxStr 1 p1)
                s2 (substr bboxStr (+ p1 2) (- p2 p1 1))
                s3 (substr bboxStr (+ p2 2) (- p3 p2 1))
                s4 (substr bboxStr (+ p3 2))
                x1 (distof s1 2)
                y1 (distof s2 2)
                x2 (distof s3 2)
                y2 (distof s4 2))
          (if (and x1 y1 x2 y2)
            (progn
              (setq minX (min x1 x2)
                    minY (min y1 y2)
                    maxX (max x1 x2)
                    maxY (max y1 y2))
              (list minX minY maxX maxY)
            )
            nil
          )
        )
        nil
      )
    )
    nil
  )
)

(defun pt-in-bbox-p (pt norm bboxList / wpt x y)
  (if (not bboxList)
    T
    (if (not pt)
      nil
      (progn
        (setq wpt (pt-wcs-coords pt norm)
              x   (car wpt)
              y   (cadr wpt))
        (and (>= x (nth 0 bboxList))
             (<= x (nth 2 bboxList))
             (>= y (nth 1 bboxList))
             (<= y (nth 3 bboxList)))
      )
    )
  )
)

(defun calc-bulge-arc-len (p1 p2 bulge / dx dy chord absB halfAng sinHalf theta)
  (setq dx    (- (car p2) (car p1))
        dy    (- (cadr p2) (cadr p1))
        chord (sqrt (+ (* dx dx) (* dy dy)))
        absB  (abs (if bulge bulge 0.0)))
  (if (or (< chord 1e-9) (< absB 1e-9))
    chord
    (progn
      (setq halfAng (* 2.0 (atan absB))
            sinHalf (sin halfAng)
            theta   (* 4.0 (atan absB)))
      (if (> (abs sinHalf) 1e-9)
        (* (/ chord (* 2.0 sinHalf)) theta)
        chord
      )
    )
  )
)

(defun calc-bulge-seg-area (p1 p2 bulge / dx dy chord absB halfAng sinHalf theta rad segArea)
  (setq dx    (- (car p2) (car p1))
        dy    (- (cadr p2) (cadr p1))
        chord (sqrt (+ (* dx dx) (* dy dy)))
        absB  (abs (if bulge bulge 0.0)))
  (if (or (< chord 1e-9) (< absB 1e-9))
    0.0
    (progn
      (setq halfAng (* 2.0 (atan absB))
            sinHalf (sin halfAng)
            theta   (* 4.0 (atan absB)))
      (if (> (abs sinHalf) 1e-9)
        (progn
          (setq rad     (/ chord (* 2.0 sinHalf))
                segArea (* 0.5 rad rad (- theta (sin theta))))
          (if (< bulge 0.0) (- segArea) segArea)
        )
        0.0
      )
    )
  )
)

(defun calc-lwpoly-metrics (ed norm / elev pts bulges item ocsPt isClosed n i p1 p2 b totalLen shoelace segSum areaVal startWcs endWcs)
  (setq elev     (if (assoc 38 ed) (cdr (assoc 38 ed)) 0.0)
        pts      nil
        bulges   nil
        isClosed (= (logand (if (assoc 70 ed) (cdr (assoc 70 ed)) 0) 1) 1)
        totalLen 0.0
        shoelace 0.0
        segSum   0.0
        areaVal  0.0)
  (foreach item ed
    (cond
      ((= (car item) 10)
       (setq ocsPt (list (car (cdr item)) (cadr (cdr item)) elev))
       (setq pts (cons ocsPt pts)))
      ((= (car item) 42)
       (setq bulges (cons (cdr item) bulges)))
    )
  )
  (setq pts    (reverse pts)
        bulges (reverse bulges)
        n      (length pts))
  (while (< (length bulges) n)
    (setq bulges (append bulges (list 0.0)))
  )
  (if (> n 1)
    (progn
      (setq i 0)
      (while (< i (1- n))
        (setq p1 (nth i pts)
              p2 (nth (1+ i) pts)
              b  (nth i bulges)
              totalLen (+ totalLen (calc-bulge-arc-len p1 p2 b))
              shoelace (+ shoelace (- (* (car p1) (cadr p2)) (* (car p2) (cadr p1))))
              segSum   (+ segSum (calc-bulge-seg-area p1 p2 b))
              i        (1+ i))
      )
      (if isClosed
        (progn
          (setq p1 (nth (1- n) pts)
                p2 (nth 0 pts)
                b  (nth (1- n) bulges)
                totalLen (+ totalLen (calc-bulge-arc-len p1 p2 b))
                shoelace (+ shoelace (- (* (car p1) (cadr p2)) (* (car p2) (cadr p1))))
                segSum   (+ segSum (calc-bulge-seg-area p1 p2 b)))
          (setq areaVal (abs (+ (* 0.5 shoelace) segSum)))
        )
      )
    )
  )
  (setq startWcs (if pts (pt-wcs-coords (car pts) norm) nil)
        endWcs   (if pts (pt-wcs-coords (nth (1- n) pts) norm) nil))
  (list totalLen areaVal isClosed startWcs endWcs)
)

(defun build-ssget-filter (etypeStr filterLayersRaw filterSpace / flt)
  (setq flt (list (cons 0 etypeStr)))
  (if (and filterLayersRaw (/= filterLayersRaw "") (/= filterLayersRaw "*"))
    (setq flt (append flt (list (cons 8 filterLayersRaw))))
  )
  (cond
    ((= filterSpace "MODEL") (setq flt (append flt (list (cons 67 0)))))
    ((= filterSpace "PAPER") (setq flt (append flt (list (cons 67 1)))))
  )
  flt
)

(defun c:DUMP_CAD_JSON ( / outPath f tbl lyrName lyrColor lyrStatus first rewindTbl ss i ent ed etype hnd lyr norm pt
                           spaceVal layoutVal txt blkName effName attEnt attEd attVal isAttMulti attJson firstAtt limitStr limitVal
                           filterLayers filterSpace filterLayersRaw filterTypesRaw filterTypes olderr oldDimzin
                           totalTextsMatched textsCount totalBlocksMatched blocksCount textFilterDxf wantText wantMtext bboxRaw bboxList takeoffRaw wantTakeoff totalCurvesMatched curvesCount lwMetrics cLen cArea cClosed cPos pEnd radVal ang1 ang2 angSpan curveFilterDxf cTypesList cTypesStr ct curveLimitVal)
  (setq olderr *error*)
  (setq oldDimzin (getvar "DIMZIN"))
  (defun *error* (msg)
    (if f (close f))
    (if oldDimzin (setvar "DIMZIN" oldDimzin))
    (princ (strcat "\n[MCP_INSPECT_ERROR] " (if msg msg "Unknown error") "\n"))
    (setq *error* olderr)
    (princ)
  )

  (setvar "DIMZIN" 0)

  (setq outPath (getenv "MCP_JSON_OUT"))
  (setq limitStr (getenv "MCP_LIMIT"))
  (setq limitVal (if (and limitStr (/= limitStr "")) (atoi limitStr) 200))

  (setq filterLayersRaw (getenv "MCP_FILTER_LAYERS"))
  (if (and filterLayersRaw (/= filterLayersRaw "") (/= filterLayersRaw "*"))
    (setq filterLayers (strcat "," (strcase filterLayersRaw) ","))
    (setq filterLayers nil)
  )

  (setq filterTypesRaw (getenv "MCP_ENTITY_TYPES"))
  (if (and filterTypesRaw (/= filterTypesRaw "") (/= filterTypesRaw "*"))
    (setq filterTypes (strcat "," (strcase filterTypesRaw) ","))
    (setq filterTypes nil)
  )

  (setq filterSpace (getenv "MCP_SPACE"))
  (if filterSpace
    (setq filterSpace (strcase filterSpace))
    (setq filterSpace "ALL")
  )

  (setq bboxRaw (getenv "MCP_BBOX"))
  (setq bboxList (parse-bbox-csv bboxRaw))

  (setq takeoffRaw (getenv "MCP_TAKEOFF"))
  (setq wantTakeoff (or (and takeoffRaw (= takeoffRaw "1"))
                        (csv-token-allowed-p "TAKEOFF" filterTypes)
                        (csv-token-allowed-p "METRICS" filterTypes)
                        (csv-token-allowed-p "CURVES" filterTypes)
                        (csv-token-allowed-p "LWPOLYLINE" filterTypes)
                        (csv-token-allowed-p "LINE" filterTypes)))

  (if (and outPath (/= outPath ""))
    (progn
      (setq f (open outPath "w"))
      (write-line "{" f)
      (write-line (strcat "  \"dwgname\": \"" (esc-json (getvar "DWGNAME") nil) "\",") f)
      (write-line (strcat "  \"insunits\": " (itoa (getvar "INSUNITS")) ",") f)
      (write-line (strcat "  \"measurement\": " (itoa (getvar "MEASUREMENT")) ",") f)
      (write-line (strcat "  \"tilemode\": " (itoa (getvar "TILEMODE")) ",") f)
      (write-line (strcat "  \"ctab\": \"" (esc-json (getvar "CTAB") nil) "\",") f)
      (write-line (strcat "  \"extmin\": " (pt-wcs-json (getvar "EXTMIN") nil) ",") f)
      (write-line (strcat "  \"extmax\": " (pt-wcs-json (getvar "EXTMAX") nil) ",") f)

      ;; 1. Layers (rewindTbl separated from first comma tracker)
      (write-line "  \"layers\": [" f)
      (if (type-allowed-p "LAYER" filterTypes)
        (progn
          (setq first T
                rewindTbl T)
          (while (setq tbl (tblnext "LAYER" rewindTbl))
            (setq rewindTbl nil)
            (setq lyrName (cdr (assoc 2 tbl)))
            (if (layer-allowed-p lyrName filterLayers)
              (progn
                (if (not first) (write-line "," f))
                (setq first nil)
                (setq lyrColor (itoa (cdr (assoc 62 tbl))))
                (setq lyrStatus (itoa (cdr (assoc 70 tbl))))
                (princ (strcat "    {\"name\": \"" (esc-json lyrName nil) "\", \"color\": " lyrColor ", \"status\": " lyrStatus "}") f)
              )
            )
          )
        )
      )
      (write-line "\n  ]," f)

      ;; 2. Texts (TEXT, MTEXT filtered via C++ DXF ssget filter prior to truncation)
      (write-line "  \"texts\": [" f)
      (setq wantText  (type-allowed-p "TEXT" filterTypes)
            wantMtext (type-allowed-p "MTEXT" filterTypes)
            textFilterDxf (cond
                            ((and wantText wantMtext) "TEXT,MTEXT")
                            (wantText "TEXT")
                            (wantMtext "MTEXT")
                            (t nil)
                          )
            ss (if textFilterDxf (ssget "_X" (build-ssget-filter textFilterDxf filterLayersRaw filterSpace)) nil)
            first T
            i 0
            totalTextsMatched (if ss (sslength ss) 0)
            textsCount 0)
      (if ss
        (progn
          (while (and (< i (sslength ss)) (< textsCount limitVal))
            (setq ent (ssname ss i)
                  ed  (entget ent)
                  lyr (cdr (assoc 8 ed))
                  spaceVal (if (= (cdr (assoc 67 ed)) 1) "paper" "model")
            )
            (if (and (layer-allowed-p lyr filterLayers) (space-allowed-p spaceVal filterSpace))
              (progn
                (setq etype (cdr (assoc 0 ed))
                      hnd (esc-json (cdr (assoc 5 ed)) nil)
                      norm (cdr (assoc 210 ed))
                      layoutVal (esc-json (cdr (assoc 410 ed)) nil)
                )
                ;; Use alignment point (DXF 11) for aligned/centered TEXT safely checking nil
                (if (and (= etype "TEXT")
                         (or (and (assoc 72 ed) (/= (cdr (assoc 72 ed)) 0))
                             (and (assoc 73 ed) (/= (cdr (assoc 73 ed)) 0)))
                         (assoc 11 ed)
                    )
                  (setq pt (cdr (assoc 11 ed)))
                  (setq pt (cdr (assoc 10 ed)))
                )
                (if (pt-in-bbox-p pt (if (= etype "MTEXT") nil norm) bboxList)
                  (progn
                    (setq txt (esc-json (get-full-text ed) (= etype "MTEXT")))
                    (if (not first) (write-line "," f))
                    (setq first nil)
                    ;; Note: MTEXT stores DXF 10 directly in WCS; only transform with norm if not MTEXT
                    (princ (strcat "    {\"handle\": \"" hnd "\", \"type\": \"" etype "\", \"layer\": \"" (esc-json lyr nil) "\", \"space\": \"" spaceVal "\", \"layout\": \"" layoutVal "\", \"text\": \"" txt "\", \"pos\": " (pt-wcs-json pt (if (= etype "MTEXT") nil norm)) "}") f)
                    (setq textsCount (1+ textsCount))
                  )
                  (setq totalTextsMatched (1- totalTextsMatched))
                )
              )
            )
            (setq i (1+ i))
          )
        )
      )
      (write-line "\n  ]," f)
      (write-line (strcat "  \"total_texts_matched\": " (itoa totalTextsMatched) ",") f)
      (write-line (strcat "  \"texts_truncated\": " (if (> totalTextsMatched limitVal) "true" "false") ",") f)

      ;; 3. Block References (INSERT) with Attributes & Dynamic Name Resolution
      (write-line "  \"blocks\": [" f)
      (setq ss (if (or (type-allowed-p "INSERT" filterTypes) (type-allowed-p "BLOCK" filterTypes))
                 (ssget "_X" (build-ssget-filter "INSERT" filterLayersRaw filterSpace))
                 nil
               )
            first T
            i 0
            totalBlocksMatched (if ss (sslength ss) 0)
            blocksCount 0)
      (if ss
        (progn
          (while (and (< i (sslength ss)) (< blocksCount limitVal))
            (setq ent     (ssname ss i)
                  ed      (entget ent)
                  lyr     (cdr (assoc 8 ed))
                  spaceVal (if (= (cdr (assoc 67 ed)) 1) "paper" "model")
            )
            (if (and (layer-allowed-p lyr filterLayers) (space-allowed-p spaceVal filterSpace))
              (progn
                (setq hnd     (esc-json (cdr (assoc 5 ed)) nil)
                      norm    (cdr (assoc 210 ed))
                      pt      (cdr (assoc 10 ed))
                      blkName (cdr (assoc 2 ed))
                      effName (get-eff-name ent blkName)
                      layoutVal (esc-json (cdr (assoc 410 ed)) nil)
                      attJson "["
                      firstAtt T
                )
                (if (= (cdr (assoc 66 ed)) 1)
                  (progn
                    (setq attEnt (entnext ent))
                    (while (and attEnt (/= (cdr (assoc 0 (setq attEd (entget attEnt)))) "SEQEND"))
                      (if (= (cdr (assoc 0 attEd)) "ATTRIB")
                        (progn
                          (if (not firstAtt) (setq attJson (strcat attJson ", ")))
                          (setq firstAtt nil)
                          (setq attVal (get-attrib-text attEd))
                          (setq isAttMulti (if (member '(101 . "Embedded Object") attEd) t nil))
                          (setq attJson (strcat attJson "{\"tag\": \"" (esc-json (cdr (assoc 2 attEd)) nil) "\", \"val\": \"" (esc-json attVal isAttMulti) "\"}"))
                        )
                      )
                      (setq attEnt (entnext attEnt))
                    )
                  )
                )
                (setq attJson (strcat attJson "]"))
                (if (pt-in-bbox-p pt norm bboxList)
                  (progn
                    (if (not first) (write-line "," f))
                    (setq first nil)
                    (princ (strcat "    {\"handle\": \"" hnd "\", \"name\": \"" (esc-json blkName nil) "\", \"effective_name\": \"" (esc-json effName nil) "\", \"is_dynamic\": " (if (/= blkName effName) "true" "false") ", \"layer\": \"" (esc-json lyr nil) "\", \"space\": \"" spaceVal "\", \"layout\": \"" layoutVal "\", \"pos\": " (pt-wcs-json pt norm) ", \"attributes\": " attJson "}") f)
                    (setq blocksCount (1+ blocksCount))
                  )
                  (setq totalBlocksMatched (1- totalBlocksMatched))
                )
              )
            )
            (setq i (1+ i))
          )
        )
      )
      (write-line "\n  ]," f)
      (write-line (strcat "  \"total_blocks_matched\": " (itoa totalBlocksMatched) ",") f)
      (if wantTakeoff
        (progn
          (write-line (strcat "  \"blocks_truncated\": " (if (> totalBlocksMatched limitVal) "true" "false") ",") f)
          (write-line "  \"curves\": [" f)
          (setq curveFilterDxf
            (if (or (not filterTypes)
                    (csv-token-allowed-p "TAKEOFF" filterTypes)
                    (csv-token-allowed-p "METRICS" filterTypes)
                    (csv-token-allowed-p "CURVES" filterTypes))
              "LINE,LWPOLYLINE,CIRCLE,ARC"
              (progn
                (setq cTypesList nil)
                (if (csv-token-allowed-p "LINE" filterTypes) (setq cTypesList (cons "LINE" cTypesList)))
                (if (csv-token-allowed-p "LWPOLYLINE" filterTypes) (setq cTypesList (cons "LWPOLYLINE" cTypesList)))
                (if (csv-token-allowed-p "CIRCLE" filterTypes) (setq cTypesList (cons "CIRCLE" cTypesList)))
                (if (csv-token-allowed-p "ARC" filterTypes) (setq cTypesList (cons "ARC" cTypesList)))
                (if cTypesList
                  (progn
                    (setq cTypesStr (car cTypesList))
                    (foreach ct (cdr cTypesList)
                      (setq cTypesStr (strcat cTypesStr "," ct))
                    )
                    cTypesStr
                  )
                  "LINE,LWPOLYLINE,CIRCLE,ARC"
                )
              )
            )
          )
          (setq curveLimitVal (if (and takeoffRaw (= takeoffRaw "1")) (max limitVal 5000) limitVal))
          (setq ss (ssget "_X" (build-ssget-filter curveFilterDxf filterLayersRaw filterSpace))
                first T
                i 0
                totalCurvesMatched (if ss (sslength ss) 0)
                curvesCount 0)
          (if ss
            (progn
              (while (and (< i (sslength ss)) (< curvesCount curveLimitVal))
                (setq ent      (ssname ss i)
                      ed       (entget ent)
                      etype    (cdr (assoc 0 ed))
                      lyr      (cdr (assoc 8 ed))
                      norm     (cdr (assoc 210 ed))
                      spaceVal (if (= (cdr (assoc 67 ed)) 1) "paper" "model")
                      layoutVal (esc-json (cdr (assoc 410 ed)) nil)
                      hnd      (esc-json (cdr (assoc 5 ed)) nil)
                      cLen     0.0
                      cArea    0.0
                      cClosed  nil
                      cPos     nil
                      pEnd     nil)
                (cond
                  ((= etype "LINE")
                   (setq cPos (cdr (assoc 10 ed))
                         pEnd (cdr (assoc 11 ed))
                         cLen (if (and cPos pEnd) (distance (pt-wcs-coords cPos nil) (pt-wcs-coords pEnd nil)) 0.0)
                         norm nil))
                  ((= etype "LWPOLYLINE")
                   (setq lwMetrics (calc-lwpoly-metrics ed norm)
                         cLen      (nth 0 lwMetrics)
                         cArea     (nth 1 lwMetrics)
                         cClosed   (nth 2 lwMetrics)
                         cPos      (nth 3 lwMetrics)
                         pEnd      (nth 4 lwMetrics)
                         norm      nil))
                  ((= etype "CIRCLE")
                   (setq cPos    (cdr (assoc 10 ed))
                         pEnd    cPos
                         radVal  (if (assoc 40 ed) (cdr (assoc 40 ed)) 0.0)
                         cLen    (* 2.0 pi radVal)
                         cArea   (* pi radVal radVal)
                         cClosed T))
                  ((= etype "ARC")
                   (setq cPos    (cdr (assoc 10 ed))
                         pEnd    cPos
                         radVal  (if (assoc 40 ed) (cdr (assoc 40 ed)) 0.0)
                         ang1    (if (assoc 50 ed) (cdr (assoc 50 ed)) 0.0)
                         ang2    (if (assoc 51 ed) (cdr (assoc 51 ed)) 0.0)
                         angSpan (- ang2 ang1))
                   (if (< angSpan 0.0) (setq angSpan (+ angSpan (* 2.0 pi))))
                   (setq cLen (* radVal angSpan)))
                )
                (if (and (layer-allowed-p lyr filterLayers)
                         (space-allowed-p spaceVal filterSpace)
                         (or (pt-in-bbox-p cPos norm bboxList)
                             (and pEnd (pt-in-bbox-p pEnd norm bboxList))))
                  (progn
                    (if (not first) (write-line "," f))
                    (setq first nil)
                    (princ (strcat "    {\"handle\": \"" hnd "\", \"type\": \"" etype "\", \"layer\": \"" (esc-json lyr nil) "\", \"space\": \"" spaceVal "\", \"layout\": \"" layoutVal "\", \"closed\": " (if cClosed "true" "false") ", \"length\": " (num-json cLen) ", \"area\": " (num-json cArea) ", \"pos\": " (pt-wcs-json cPos norm) ", \"end_pos\": " (pt-wcs-json pEnd norm) "}") f)
                    (setq curvesCount (1+ curvesCount))
                  )
                  (setq totalCurvesMatched (1- totalCurvesMatched))
                )
                (setq i (1+ i))
              )
            )
          )
          (write-line "\n  ]," f)
          (write-line (strcat "  \"total_curves_matched\": " (itoa totalCurvesMatched) ",") f)
          (write-line (strcat "  \"curves_truncated\": " (if (> totalCurvesMatched curveLimitVal) "true" "false")) f)
        )
        (write-line (strcat "  \"blocks_truncated\": " (if (> totalBlocksMatched limitVal) "true" "false")) f)
      )
      (write-line "}" f)
      (close f)
      (setq f nil)
      (princ "\n[MCP_INSPECT_SUCCESS]\n")
    )
  )
  (if oldDimzin (setvar "DIMZIN" oldDimzin))
  (setq *error* olderr)
  (princ)
)
(c:DUMP_CAD_JSON)
