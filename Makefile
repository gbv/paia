REVHASH=$(shell git log -1 --format="%H" paia.md)
REVDATE=$(shell git log -1 --format="%ai" paia.md)
REVSHRT=$(shell git log -1 --format="%h" paia.md)
REVLINK=https://github.com/gbv/paia/commit/${REVHASH}

html: paia.html

pdf: paia.pdf

new: purge html changes

paia.html: paia.md template.html5 references.bib
	@echo "creating paia.html..."
	@sed 's/GIT_REVISION_DATE/${REVDATE}/' paia.md  > paia.tmp
	@ pandoc -N --template=template --toc -f markdown -t html5 paia.tmp \
	| perl -p -e 's!(http://[^<]+)\.</p>!<a href="$$1"><code class="url">$$1</code></a>.</p>!g' \
	| sed 's!<td style="text-align: center;">!<td>!' \
	| sed 's!GIT_REVISION_HASH!<a href="${REVLINK}">${REVSHRT}<\/a>!' > paia.html
	@git diff-index --quiet HEAD paia.md || echo "Current paia.md not checked in, so this is a DRAFT!" 

# FIXME: the current PDF does not look that nice...
paia.pdf: paia.md references.bib
	pandoc -N --bibliography=references.bib --toc -f markdown -o paia.pdf paia.md

changes: changes.html

changes.html:
	@git log -4 --pretty=format:'<li><a href=paia-%h.html><tt>%ci</tt></a>: <a href="https://github.com/gbv/paia/commit/%H"><em>%s</em></a></li>' paia.md > changes.html

revision: paia.html
	@cp paia.html paia-${REVSHRT}.html

website: clean purge revision changes.html
	@echo "new revision to be shown at http://gbv.github.com/paia/"
	@rm paia.html
	@git checkout gh-pages
	@perl -pi -e 's!paia-[0-9a-z]{7}!paia-${REVSHRT}!g' index.html
	@sed -i '/<!-- BEGIN CHANGES -->/,/<!-- END CHANGES -->/ {//!d}; /<!-- BEGIN CHANGES -->/r changes.html' index.html
	@git add index.html paia-${REVSHRT}.html
	@git commit -m "revision ${REVSHRT}"
	@git checkout master

cleancopy:
	@echo "checking that no local modifcations exist..."
	@git diff-index --quiet HEAD -- 

purge:
	@rm -f paia.html paia-*.html changes.html


.PHONY: clean purge html
