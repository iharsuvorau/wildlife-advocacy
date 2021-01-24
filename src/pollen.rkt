#lang racket/base

(require
    pollen/core
    pollen/decode
    pollen/setup
    racket/date
    racket/list
    racket/match
    racket/path
    racket/string
    (only-in srfi/13 string-contains)
    txexpr)

(provide (all-defined-out))

(module setup racket/base
	(provide (all-defined-out))
	(define poly-targets '(html ltx pdf)))

(define (root . elements)
  (case (current-poly-target)
    [(ltx pdf)
     (define first-pass (decode-elements elements
                                         #:inline-txexpr-proc (compose1 txt-decode
					;hyperlink-decoder
									)
					;#:string-proc (compose1 ltx-escape-str smart-quotes smart-dashes)
					 ;#:txexpr-elements-proc decode-linebreaks
					 #:string-proc (compose1 ltx-escape-str)
                                         #:exclude-tags '(script style figure txt-noescape)))
     (make-txexpr 'body null
		  (decode-elements first-pass #:inline-txexpr-proc txt-decode))]

    [else
      (define first-pass (decode-elements elements
                                          #:txexpr-elements-proc (compose1 decode-linebreaks
									   decode-paragraphs)
                                          #:exclude-tags '(script style figure)))
      (make-txexpr 'body null
                   (decode-elements first-pass
                                    #:block-txexpr-proc detect-newthoughts
                                    ;#:inline-txexpr-proc hyperlink-decoder
					;#:string-proc (compose1 smart-quotes smart-dashes)
                                    #:exclude-tags '(script style)))]))

(define (heading . elements)
	(case (current-poly-target)
		[(ltx pdf) (apply string-append `("\\chapter{" ,@elements "}"))]
		[else (txexpr 'h1 empty elements)]))

(define (em . elements)
	(case (current-poly-target)
		[(ltx pdf) (apply string-append `("\\textit{" ,@elements "}"))]
		[else (txexpr 'em empty elements)]))

; Escape $,%,# and & for LaTeX
; The approach here is rather indiscriminate; I’ll probably have to change
; it once I get around to handline inline math, etc.
(define (ltx-escape-str str)
  (regexp-replace* #px"([$#%&_])" str "\\\\\\1"))

#|
`txt` is called by root when targeting LaTeX/PDF. It converts all elements inside
a ◊txt tag into a single concatenated string. ◊txt is not intended to be used in
normal markup; its sole purpose is to allow other tag functions to return LaTeX
code as a valid X-expression rather than as a string.
|#
(define (txt-decode xs)
    (if (member (get-tag xs) '(txt txt-noescape))
        (get-elements xs)
        xs))

#|
detect-newthoughts: called by root above when targeting HTML.
The ◊newthought tag (defined further below) makes use of the \newthought
command in Tufte-LaTeX and the .newthought CSS style in Tufte-CSS to start a
new section with some words in small caps. In LaTeX, this command additionally
adds some vertical spacing in front of the enclosing paragraph. There is no way
to do this in HTML/CSS without adding in some Javascript: i.e., there is no
CSS selector for “p tags that contain a span of class ‘newthought’”. So we can
handle it at the Pollen processing level.
|#
(define (detect-newthoughts block-xpr)
  (define is-newthought? (λ(x) (and (txexpr? x)
                                    (eq? 'span (get-tag x))
                                    (attrs-have-key? x 'class)
                                    (string=? "newthought" (attr-ref x 'class)))))
  (if (and(eq? (get-tag block-xpr) 'p)             ; Is it a <p> tag?
          (findf-txexpr block-xpr is-newthought?)) ; Does it contain a <span class="newthought">?
      (attr-set block-xpr 'class "pause-before")   ; Add the ‘pause-before’ class
      block-xpr))                                  ; Otherwise return it unmodified

#|
◊numbered-note, ◊margin-figure, ◊margin-note:
  These three tag functions produce markup for "sidenotes" in HTML and LaTeX.
  In our LaTeX template, any hyperlinks also get auto-converted to numbered
  sidenotes, which is kinda neat. Unfortunately, this also means that when
  targeting LaTeX, you can't have a hyperlink inside a sidenote since that would
  equate to a sidenote within a sidenote, which causes Problems.

  We handle this by not using a normal tag function for hyperlinks. Instead,
  within these three tag functions we call latex-no-hyperlinks-in-margin to
  filter out any hyperlinks inside these tags (for LaTeX/PDF only). Then the
  root function uses a separate decoder to properly handle any hyperlinks that
  sit outside any of these three tags.
|#

(define (numbered-note . text)
    (define refid (number->string (equal-hash-code (car text))))
    (case (current-poly-target)
      [(ltx pdf)
       `(txt "\\footnote{" ,@(latex-no-hyperlinks-in-margin text) "}")]
      [else
        `(@ (label [[for ,refid] [class "margin-toggle sidenote-number"]])
            (input [[type "checkbox"] [id ,refid] [class "margin-toggle"]])
            (span [(class "sidenote")] ,@text))]))

(define (margin-figure-small source . caption)
    (define refid (number->string (equal-hash-code source)))
    (case (current-poly-target)
      [(ltx pdf)
       `(txt "\\begin{marginfigure}"
             "\\includegraphics[width=2.5cm]{" ,source "}"
             "\\caption{" ,@(latex-no-hyperlinks-in-margin caption) "}"
             "\\end{marginfigure}")]
      [else
        `(@ (label [[for ,refid] [class "margin-toggle"]] 8853)
            (input [[type "checkbox"] [id ,refid] [class "margin-toggle"]])
            (span [[class "marginnote marginnote-small"]] (img [[src ,source]]) ,@caption))]))

(define (margin-figure-medium source . caption)
    (define refid (number->string (equal-hash-code source)))
    (case (current-poly-target)
      [(ltx pdf)
       `(txt "\\begin{marginfigure}"
             "\\includegraphics[width=3.5cm]{" ,source "}"
             "\\caption{" ,@(latex-no-hyperlinks-in-margin caption) "}"
             "\\end{marginfigure}")]
      [else
        `(@ (label [[for ,refid] [class "margin-toggle"]] 8853)
            (input [[type "checkbox"] [id ,refid] [class "margin-toggle"]])
            (span [[class "marginnote marginnote-medium"]] (img [[src ,source]]) ,@caption))]))

(define (margin-figure-big source . caption)
    (define refid (number->string (equal-hash-code source)))
    (case (current-poly-target)
      [(ltx pdf)
       `(txt "\\begin{marginfigure}"
             "\\includegraphics[width=5cm]{" ,source "}"
             "\\caption{" ,@(latex-no-hyperlinks-in-margin caption) "}"
             "\\end{marginfigure}")]
      [else
        `(@ (label [[for ,refid] [class "margin-toggle"]] 8853)
            (input [[type "checkbox"] [id ,refid] [class "margin-toggle"]])
            (span [[class "marginnote"]] (img [[src ,source]]) ,@caption))]))

(define (margin-figure-big-bordered source . caption)
    (define refid (number->string (equal-hash-code source)))
    (case (current-poly-target)
      [(ltx pdf)
       `(txt "\\begin{marginfigure}"
             "\\fbox{\\includegraphics[width=5cm]{" ,source "}}"
             "\\caption{" ,@(latex-no-hyperlinks-in-margin caption) "}"
             "\\end{marginfigure}")]
      [else
        `(@ (label [[for ,refid] [class "margin-toggle"]] 8853)
            (input [[type "checkbox"] [id ,refid] [class "margin-toggle"]])
            (span [[class "marginnote"]] (img [[src ,source]]) ,@caption))]))

(define (margin-figure source . caption)
    (define refid (number->string (equal-hash-code source)))
    (case (current-poly-target)
      [(ltx pdf)
       `(txt "\\begin{marginfigure}"
             "\\includegraphics{" ,source "}"
             "\\caption{" ,@(latex-no-hyperlinks-in-margin caption) "}"
             "\\end{marginfigure}")]
      [else
        `(@ (label [[for ,refid] [class "margin-toggle"]] 8853)
            (input [[type "checkbox"] [id ,refid] [class "margin-toggle"]])
            (span [[class "marginnote"]] (img [[src ,source]]) ,@caption))]))

(define (margin-note . text)
    (define refid (number->string (equal-hash-code (car text))))
    (case (current-poly-target)
      [(ltx pdf)
       `(txt "\\marginnote{" ,@(latex-no-hyperlinks-in-margin text) "}")]
      [else
        `(@ (label [[for ,refid] [class "margin-toggle"]] 8853)
            (input [[type "checkbox"] [id ,refid] [class "margin-toggle"]])
            (span [[class "marginnote"]] ,@text))]))
#|
  This function is called from within the margin/sidenote functions when
  targeting Latex/PDF, to filter out hyperlinks from within those tags.
  (See notes above)
|#
(define (latex-no-hyperlinks-in-margin txpr)
  ; First define a local function that will transform each ◊hyperlink
  (define (cleanlinks inline-tx)
      (if (eq? 'hyperlink (get-tag inline-tx))
        `(txt ,@(cdr (get-elements inline-tx))
              ; Return the text with the URI in parentheses
              " (\\url{" ,(ltx-escape-str (car (get-elements inline-tx))) "})")
        inline-tx)) ; otherwise pass through unchanged
  ; Run txpr through the decode-elements wringer using the above function to
  ; flatten out any ◊hyperlink tags
  (decode-elements txpr #:inline-txexpr-proc cleanlinks))

;; (define (hyperlink-decoder inline-tx)
;;   (define (hyperlinker url . words)
;;     (case (current-poly-target)
;;       [(ltx pdf) `(txt "\\href{" ,url "}" "{" ,@words "}")]
;;       [else `(a [[href ,url]] ,@words)]))

;;   (if (eq? 'hyperlink (get-tag inline-tx))
;;       (apply hyperlinker (get-elements inline-tx))
;;       inline-tx))

(define (p . words)
  (case (current-poly-target)
    [(ltx pdf) `(txt ,@words)]
    [else `(p ,@words)]))

(define (blockquote . words)
  (case (current-poly-target)
    [(ltx pdf) `(txt "\\begin{quote}" ,@words "\\end{quote}")]
    [else `(blockquote ,@words)]))

(define (newthought . words)
  (case (current-poly-target)
    [(ltx pdf) `(txt "\\newthought{" ,@words "}")]
    [else `(span [[class "newthought"]] ,@words)]))

(define (smallcaps . words)
  (case (current-poly-target)
    [(ltx pdf) `(txt "\\sc{" ,@words "}")]
    [else `(span [[class "smallcaps"]] ,@words)]))

(define (∆ . elems)
  (case (current-poly-target)
    [(ltx pdf) `(txt-noescape "$" ,@elems "$")]
    [else `(span "\\(" ,@elems "\\)")]))

(define (center . words)
  (case (current-poly-target)
    [(ltx pdf) `(txt "\\begin{center}" ,@words "\\end{center}")]
    [else `(div [[style "text-align: center"]] ,@words)]))

(define (section title . text)
  (define id (gensym))
  (case (current-poly-target)
    [(ltx pdf) `(txt "\\section*{" ,title "}"
                 "\\label{sec:" ,title ,(symbol->string id) "}"
                 ,@text)]
    [else `(section (h2 ((id ,(symbol->string id))) ,title) ,@text)]))

(define (subsection title . text)
  (define id (gensym))
  (case (current-poly-target)
    [(ltx pdf) `(txt "\\subsection*{" ,title "}"
                 "\\label{sec:" ,title ,(symbol->string (gensym)) "}"
                 ,@text)]
    [else `(section (h3 ((id ,(symbol->string id))) ,title) ,@text)]))

(define (index-entry entry . text)
  (case (current-poly-target)
    [(ltx pdf) `(txt "\\index{" ,entry "}" ,@text)]
    [else
      (case (apply string-append text)
        [("") `(a [[id ,entry] [class "index-entry"]])]
        [else `(a [[id ,entry] [class "index-entry"]] ,@text)])]))

(define (figure source #:fullwidth [fullwidth #f] . caption)
  (case (current-poly-target)
    [(ltx pdf)
     (define figure-env (if fullwidth "figure*" "figure"))
     `(txt "\\begin{" ,figure-env "}"
           "\\includegraphics[width=\\linewidth]{" ,source "}"
           "\\caption{" ,@(latex-no-hyperlinks-in-margin caption) "}"
           "\\end{" ,figure-env "}")]
    [else (if fullwidth
              ; Note the syntax for calling another tag function, margin-note,
              ; from inside this one. Because caption is a list, we need to use
              ; (apply) to pass the values in that list as individual arguments.
              `(figure [[class "fullwidth"]] ,(apply margin-note caption) (img [[src ,source]]))
              `(figure ,(apply margin-note caption) (img [[src ,source]])))]))

(define (code . text)
  (case (current-poly-target)
    [(ltx pdf) `(txt "\\texttt{" ,@text "}")]
    [else `(span [[class "code"]] ,@text)]))

(define (blockcode . text)
  (case (current-poly-target)
    [(ltx pdf) `(txt "\\begin{verbatim}" ,@text "\\end{verbatim}")]
    [else `(pre [[class "code"]] ,@text)]))

(define (ol . elements)
  (case (current-poly-target)
    [(ltx pdf) `(txt "\\begin{enumerate}" ,@elements "\\end{enumerate}")]
    [else `(ol ,@elements)]))

(define (ul . elements)
  (case (current-poly-target)
    [(ltx pdf) `(txt "\\begin{itemize}" ,@elements "\\end{itemize}")]
    [else `(ul ,@elements)]))

(define (li . elements)
  (case (current-poly-target)
    [(ltx pdf) `(txt "\\item " ,@elements)]
    [else `(li ,@elements)]))

(define (sup . text)
  (case (current-poly-target)
    [(ltx pdf) `(txt "\\textsuperscript{" ,@text "}")]
    [else `(sup ,@text)]))

(define (hyperlink url . text)
  (case (current-poly-target)
    [(ltx pdf) `(txt "\\href{" ,url "}" "{" ,@text "}")]
    [else `(a [[href ,url]] ,@text)]))

(define (br)
  (case (current-poly-target)
    [(ltx pdf) `(txt "\\")]
    [else `(br)]))

(define (i . text)
  (case (current-poly-target)
    [(ltx pdf) `(txt "{\\itshape " ,@text "}")]
    [else `(i ,@text)]))

(define (emph . text)
  (case (current-poly-target)
    [(ltx pdf) `(txt "\\emph{" ,@text "}")]
    [else `(em ,@text)]))

(define (b . text)
  (case (current-poly-target)
    [(ltf pdf) `(txt "{\\bfseries " ,@text "}")]
    [else `(b ,@text)]))

(define (strong . text)
  (case (current-poly-target)
    [(ltx pdf) `(txt "\\textbf{" ,@text "}")]
    [else `(strong ,@text)]))

(define (fullwidth . words)
  (case (current-poly-target)
    [(ltx pdf) `(txt "\\begin{fullwidth}" ,@words "\\end{fullwidth}")]
    [else `(div [[class "fullwidth"]] ,@words)]))

(define (additional-materials . text)
  (case (current-poly-target)
    [(ltx pdf) `(txt "\\par\\noindent\\rule{\\linewidth}{0.1pt}\\
\\noindent{" ,@text "}\\vspace{-2mm}
\\par\\noindent\\rule{\\linewidth}{0.1pt}\\par\\smallskip")]
    [else `(div [[class "additional-materials"]] ,@text)]))

(define (small . text)
  (case (current-poly-target)
    [(ltx pdf) `(txt "\\small{" ,@text "}}")]
    [else `(small ,@text)]))

(define (boxed . text)
  (case (current-poly-target)
    [(ltx pdf) `(txt "\\vspace{3mm}\\fbox{\\parbox{0.9\\textwidth}{\\small{" ,@text "}}}\\vspace{3mm}")]
    [else `(div [[class "boxed"]] ,@text)]))

(define (paragraph . text)
  (case (current-poly-target)
    [(ltx pdf) `(txt "\\paragraph{" ,@text "}")]
    [else `(span [[class "paragraph"]] ,@text)]))

;; (define (epigraph author . text)
;;   (case (current-poly-target)
;;     [(ltx pdf) `(txt "\\openepigraph{" ,@text "}{" ,author "}")]
;;     [else `(div [[class "additional-materials"]] ,@text)]))
