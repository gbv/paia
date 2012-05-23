REVHASH=$(shell git log -1 --format="%H" paia.md)
REVDATE=$(shell git log -1 --format="%ad" --date=short paia.md)

paia.html: paia.md template.html5 references.bib
	sed s/GIT_REVISION_DATE/${REVDATE}/ paia.md \
	| pandoc -N --bibliography=references.bib --template=template --toc -f markdown -t html5 -- \
	| perl -p -e 's!(http://[^<]+)\.</p>!<a href="$$1"><code class="url">$$1</code></a>.</p>!g' \
	| sed 's!GIT_REVISION_HASH!<a href="https://github.com/gbv/paia/commit/${REVHASH}">${REVHASH}<\/a>!' > paia.html


