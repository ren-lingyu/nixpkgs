(use-modules (bibtex bib-utils))
(lazy-define (convert bibtex bibtextm) parse-bibtex-snippet)
(module-provide '(bibtex plain))
(module-provide '(bibtex alpha))
(module-provide '(bibtex abbrv))

(define root (getenv "PROBE_ROOT"))
(define output (getenv "PROBE_OUT"))
(define manifest
  (call-with-input-file (getenv "PROBE_MANIFEST") read))
(define report
  (open-output-file (string-append output "/observations.tsv")))

(define (join-values xs)
  (if (null? xs) ""
      (if (null? (cdr xs)) (car xs)
          (string-append (car xs) "," (join-values (cdr xs))))))

(define (emit cells)
  (let loop ((xs cells) (first #t))
    (if (pair? xs)
        (begin
          (if (not first) (display "\t" report))
          (display (car xs) report)
          (loop (cdr xs) #f))
        (begin (newline report) (force-output report)))))

(define (save name value)
  (call-with-output-file (string-append output "/" name ".scm")
    (lambda (port) (write value port) (newline port))))

(define (read-bytes path)
  (call-with-input-file path
    (lambda (port)
      (let loop ((chars '()))
        (let ((c (read-char port)))
          (if (eof-object? c) (list->string (reverse chars))
              (loop (cons c chars))))))))

(define (entries tree)
  (if (and (pair? tree) (eq? (car tree) 'document))
      (let loop ((xs (cdr tree)) (found '()))
        (if (null? xs) (reverse found)
            (loop (cdr xs)
                  (if (and (pair? (car xs))
                           (eq? (caar xs) 'bib-entry))
                      (cons (car xs) found) found))))
      '()))

(define (collect-tag tree tag)
  (if (not (pair? tree)) '()
      (if (eq? (car tree) tag) (list tree)
          (apply append (map (lambda (x) (collect-tag x tag)) tree)))))

(define (inspect-case name)
  (catch #t
    (lambda ()
      (let* ((source (read-bytes (string-append root "/" name ".bib")))
             (tree (parse-bibtex-snippet source))
             (found (entries tree))
             (keys (map (lambda (entry) (list-ref entry 2)) found)))
        (save (string-append name "-parsed") tree)
        (emit (list name "parse" "no-exception"
                    (if (and (pair? tree) (eq? (car tree) 'document))
                        "document" "non-document")
                    (join-values keys)))
        (for-each
          (lambda (style)
            (catch #t
              (lambda ()
                (let* ((body (bib-process "probe" style (cons 'document found)))
                       (labels (collect-tag body 'label))
                       (items (collect-tag body 'bibitem*)))
                  (save (string-append name "-" style) body)
                  (emit (list name style "no-exception"
                              (number->string (length items))
                              (join-values (map cadr labels))))))
              (lambda args
                (save (string-append name "-" style "-error") args)
                (emit (list name style "exception" "" "")))))
          '("plain" "alpha" "abbrv"))))
    (lambda args
      (save (string-append name "-parse-error") args)
      (emit (list name "parse" "exception" "" "")))))

(catch #t
  (lambda ()
    (for-each inspect-case manifest)
    (close-output-port report)
    (call-with-output-file (string-append output "/COMPLETE")
      (lambda (port) (display "all observations written\n" port))))
  (lambda args
    (display "EXPERIMENT-FATAL ") (write args) (newline)))
(quit-TeXmacs)
