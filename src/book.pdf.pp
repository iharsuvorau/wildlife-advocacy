#lang racket
(local-require racket/file racket/system)

(define working-directory
    (build-path (current-directory) "pollen-latex-work"))
(unless (directory-exists? working-directory)
    (make-directory working-directory))
(define temp-ltx-path (build-path (current-directory) "book.ltx"))
(define command (format "xelatex -output-directory='~a' '~a'" working-directory temp-ltx-path))
(define doc
    ; We run the command once, then if successful we run it again.
    ; This is because two passes are required to ensure the TOC is updated.
    (if (and (system command) (system command))
        (file->bytes (build-path working-directory "book.pdf"))
        (error "xelatex: rendering error")))
(define metas (hash))
(provide doc metas)

(module+ main
  (display doc))
