◊(require txexpr)
<!DOCTYPE html>
<html lang="ru">
    <head profile="http://www.w3.org/2005/10/profile">
	<meta charset="utf-8"/>
	<title>◊(when (select 'h2 doc) (select 'h2 doc)) &mdash; Сохранить леса Беларуси: Практическое руководство</title>
	<link rel="stylesheet" href="/assets/tufte.css"/>
	<link rel="stylesheet" href="/assets/main.css"/>
	<meta name="viewport" content="width=device-width, initial-scale=1">
	<link rel="icon" 
	      type="image/png" 
	      href="/assets/favicon.png">
    </head>
    <body>
	◊(define prev-page (previous here))
	◊(define next-page (next here))
	<header class="site-header">
	    <nav>
		<a href="https://bahna.land/">bahna.land</a>
		<a href="/book.pdf" class="with-icon">
		    <img src="/assets/pdficon.png" height="15" width="15" style="width:auto" alt="Скачать PDF" />
		    <span>PDF-версия</span>
		</a>
	    </nav>
	    <nav>
		◊when/splice[prev-page]{
		<a href="◊|prev-page|">&larr; Назад</a>}
		<a href="/">&uarr; На главную</a>
		◊when/splice[next-page]{
		<a href="◊|next-page|">Вперёд &rarr;</a>}
	    </nav>
	</header>
	<article>
	    ◊(->html doc)
	</article>
	<footer>
	    ◊when/splice[prev-page]{
	    <div onclick="document.location.pathname='◊|next-page|';">
		<a href="◊|prev-page|">&larr; Назад</a>
		<span>◊(select-from-doc 'h1 (previous here))</span>
	    </div>}
	    <div onclick="document.location.pathname='/';">
		<a href="/">&uarr; На главную</a>
	    </div>
	    ◊when/splice[next-page]{
	    <div onclick="document.location.pathname='◊|next-page|';">
		<a href="◊|next-page|">Вперёд &rarr;<br></a>
		<span>◊(select-from-doc 'h1 (next here))</span>
	    </div>}
	</footer>
    </body>
</html>
