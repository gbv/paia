REVHASH=$(shell git log -1 --format="%H" paia.md)
REVDATE=$(shell git log -1 --format="%ai" paia.md)
REVSHRT=$(shell git log -1 --format="%h" paia.md)

paia.html: paia.md template.html5 references.bib
	sed 's/GIT_REVISION_DATE/${REVDATE}/' paia.md \
	| pandoc -N --bibliography=references.bib --template=template --toc -f markdown -t html5 -- \
	| perl -p -e 's!(http://[^<]+)\.</p>!<a href="$$1"><code class="url">$$1</code></a>.</p>!g' \
	| sed 's!GIT_REVISION_HASH!<a href="https://github.com/gbv/paia/commit/${REVHASH}">${REVSHRT}<\/a>!' > paia.html

revision: paia.html
	cp paia.html paia-${REVSHRT}.html

website: revision
	git checkout gh-pages
	rm paia.html
	ln -s paia-${REVSHRT}.html paia.html
	git add paia.html paia-${REVSHRT}.html
	git commit -m "added revision ${REVSHRT}"
	git checkout master

clean:
	rm -f paia.html paia-*.html

.PHONY: clean
