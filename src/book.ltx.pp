#lang pollen

◊(local-require
  racket/base
  racket/list
  pollen/pagetree)

◊(define (print-body doc)
   (apply string-append
          "\n\n\\newpage\n"
          (select-from-doc 'body doc)))

◊(define text-font "Baskerville 120 Pro")
◊(define sans-font "Stag Sans LC Light")
◊(define mono-font "Fira Mono")

◊string-append{
               \documentclass{tufte-book}
               %\usepackage[cm-default,no-math]{fontspec} % загрузка и управление шрифтами
               % cm-default - не загружать шрифты Latin Modern
               % no-math - не вносить изменения в математические шрифты.
               \usepackage{xltxtra} % полезные переопределения для XeLaTeX, загрузка доп.пакетов
               \usepackage{polyglossia} % пакет для включения переносов (вместо babel)
               \setdefaultlanguage{russian} % выбор основного языка (для переносов)
               \setotherlanguage{english} % выбор дополнительного языка (для переносов)
               \defaultfontfeatures{Mapping=tex-text} % нужен для того чтобы работали стандартные сочетания символов ---, — << >> и т.п.
               \setmainfont{◊|text-font|}
               \setsansfont{◊|sans-font|}
               \newfontfamily\russianfont{◊|text-font|}
               %\setromanfont[Mapping=tex-text,Ligatures={Common, Rare, Discretionary},Numbers=OldStyle]{◊|text-font|}
               %\setmonofont[Mapping=tex-text,Scale=MatchLowercase]{◊|mono-font|}

               % This is the default style configuration for Scribble-generated Latex
               \usepackage{verbatimbox} % for space before and after a table with \addvbuffer
               \usepackage{booktabs} % for table rullers
               \usepackage{multirow} % for multi rows in tables
               \usepackage{enumitem} % for itemize
               \setlist{nosep}
               %\setlist[enumerate]{itemsep=0.5mm}
               \usepackage{graphicx}
               \usepackage{ragged2e} % text alignment
               \usepackage{multicol} % multi columns
               \usepackage{hyperref}
               \hypersetup{breaklinks=true,
                           colorlinks=false,
                           pdfborderstyle={/S/U/W 1},
                           bookmarks=true,
                           bookmarksopen=true,
                           bookmarksnumbered=true}
               \renewcommand{\rmdefault}{ptm}
               \usepackage{relsize}
               \usepackage{mathabx}
               % Avoid conflicts between "mathabx" and "wasysym":
               \let\leftmoon\relax \let\rightmoon\relax \let\fullmoon\relax \let\newmoon\relax \let\diameter\relax
               \usepackage{wasysym}
               \usepackage{textcomp}
               \usepackage{framed}
               \usepackage[htt]{hyphenat}
               \usepackage{soul} % for underlined text
               % letter spacing
               \newcommand{\spacedsc}{\scshape\addfontfeatures{LetterSpace=20}}
               \newcommand{\spaced}{\scshape\addfontfeatures{LetterSpace=5}}

               \begin{document}

               \newgeometry{textwidth=17cm, textheight=25cm}
               \begin{titlepage}
               \begin{flushleft}
               {\LARGE Инесса Зенина, Наталья Рябова \vspace{7cm}\par}
               {\setstretch{0.80}
                           {\Huge Сохранить леса Беларуси: \\Практическое руководство.\par}}
               \bigskip
               \bigskip
               {\setstretch{1.25}
               {\LARGE \textsf{\spaced{Как использовать механизмы участия общественности в лесной сертификации FSC для охраны природы}} \par}}
               \vfill
               {\normalsize Публикация «Школы дикой природы», ОО «Багна»\par}
               {\normalsize В издании использованы материалы Георгия Козулько, ведущего аудитора компании «НЭПКон»\par}
               {\normalsize Минск, 2020}
               \end{flushleft}
               \end{titlepage}
               \restoregeometry

               \tableofcontents
               %\listoffigures

               ◊(apply string-append
                       (map print-body
                            (children 'pagetree-root (dynamic-require "index.ptree" 'doc)))
                       )
               \end{document}
               }
