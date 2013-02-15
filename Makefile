NAME=paia
GITHUB=http://github.com/gbv/paia/

SOURCE=$(NAME).md
REVHASH=$(shell git log -1 --format="%H" $(SOURCE))
REVDATE=$(shell git log -1 --format="%ai" $(SOURCE))
REVSHRT=$(shell git log -1 --format="%h" $(SOURCE))

REVLINK=$(GITHUB)commit/$(REVHASH)

RESULTFILES=$(NAME).html

new: purge html changes

html: $(NAME).html
pdf:  $(NAME).pdf

$(NAME).html: $(NAME).md template.html5 references.bib
	@echo "creating $@..."
	@sed 's/GIT_REVISION_DATE/${REVDATE}/' $(SOURCE) > $(NAME).tmp
	@pandoc -s -N --template=template --toc -f markdown -t html5 $(NAME).tmp \
		| perl -p -e 's!(http://[^<]+)\.</p>!<a href="$$1"><code class="url">$$1</code></a>.</p>!g' \
		| perl -p -e 's!(<h2(.+)span>\s*([^<]+)</a></h2>)!<a id="$$3"></a>$$1!g' \
		| sed 's!<td style="text-align: center;">!<td>!' \
		| sed 's!GIT_REVISION_HASH!<a href="${REVLINK}">${REVSHRT}<\/a>!' > $@
	@git diff-index --quiet HEAD $(SOURCE) || echo "Current $(SOURCE) not checked in, so this is a DRAFT!"

# FIXME: the current PDF does not look that nice...
$(NAME).pdf: $(NAME).md references.bib
	pandoc -N --bibliography=references.bib --toc -f markdown -o $(NAME).pdf $(NAME).md

changes: changes.html

changes.html:
	@git log -4 --pretty=format:'<li><a href=$(NAME)-%h.html><tt>%ci</tt></a>: <a href="$(GITHUB)commit/%H"><em>%s</em></a></li>' $(SOURCE) > $@

revision: $(RESULTFILES)
	@cp $(NAME).html $(NAME)-${REVSHRT}.html

website: clean purge revision changes.html 
	@echo "new revision to be shown at $(GITHUB)"
	@rm $(RESULTFILES)
	@git checkout gh-pages
	@perl -pi -e 's!$(NAME)-[0-9a-z]{7}!$(NAME)-${REVSHRT}!g' index.html
	@sed -i '/<!-- BEGIN CHANGES -->/,/<!-- END CHANGES -->/ {//!d}; /<!-- BEGIN CHANGES -->/r changes.html' index.html
	@cp $(NAME)-${REVSHRT}.html $(NAME).html
	@git add index.html $(NAME)-${REVSHRT}.html $(RESULTFILES)
	@git commit -m "revision ${REVSHRT}"
	@git checkout master

cleancopy:
	@echo "checking that no local modifcations exist..."
	@git diff-index --quiet HEAD -- 

purge:
	@rm -f $(NAME).html $(NAME)-*.html changes.html

.PHONY: clean purge html
