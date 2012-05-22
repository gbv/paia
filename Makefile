paia.html: paia.md template.html references.bib
	pandoc -N --bibliography=references.bib --template=template --toc -5 -o paia.html paia.md 
	perl -p -i -e 's!(http://[^<]+)\.</p>!<a href="$$1"><code class="url">$$1</code></a>.</p>!g' paia.html
