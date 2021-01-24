◊(require racket/string)
<!DOCTYPE html>
<html lang="ru">
    <head profile="http://www.w3.org/2005/10/profile">
	<meta charset="utf-8"/>
	<title>◊(hash-ref metas 'title)</title>
	<link rel="stylesheet" href="/assets/tufte.css"/>
	<link rel="stylesheet" href="/assets/main.css"/>
	<meta name="viewport" content="width=device-width, initial-scale=1">
	<link rel="icon" 
	      type="image/png" 
	      href="/assets/favicon.png">
    </head>
    <body class="index-page">
	<header class="site-header">
	    <nav>
		<a href="https://bahna.land/">bahna.land</a>
		<a href="/book.pdf" class="with-icon">
		    <img src="/assets/pdficon.png" height="15" width="15" style="width:auto" alt="Скачать PDF" />
		    <span>PDF-версия</span></a>
	    </nav>
	    <nav>
		◊(define prev-page (previous here))
		◊(define next-page (next here))
		◊when/splice[prev-page]{
		<a href="◊|prev-page|">&larr; Назад</a>}
		◊when/splice[next-page]{
		<a href="◊|next-page|">Вперёд &rarr;</a>}
	    </nav>
	</header>
	<article>
	    <h1>◊(hash-ref metas 'title)</h1>
	    <p class="subtitle">Как использовать механизмы участия общественности в лесной сертификации FSC для&nbsp;охраны природы</p>
	    <p>
		◊(hash-ref metas 'author)<br>
		◊(hash-ref metas 'publisher)<br>
		Минск, 2020
	    </p>

	    ◊(define (print-list-item pagenode)
	    (when (select 'h1 (get-doc pagenode))
	    (->html `(li (a ((href ,(format "~a" pagenode))) ,(select 'h1 (get-doc pagenode)))))))
	    
	    <ol>
		◊(map print-list-item (children 'pagetree-root (current-pagetree)))
	    </ol>
	</article>
    </body>
</html>
