The **Patrons Account Information API (PAIA)** is a HTTP based programming
interface to access library patron information, such as loans, reservations,
and fees. See http://gbv.github.com/paia for an overview (included in the
`gh-pages` in this repository).

This git repository, hosted at http://github.com/gbv/paia, contains a
preliminary specification of PAIA. The master file is `paia.md` with
bibliographic references in `references.bib`. The specification is written in
[Pandoc’s
Markdown](http://johnmacfarlane.net/pandoc/demo/example9/pandocs-markdown.html).

# How to modify the specification

The best method is to create a github account so you can

1. Fork the repository: <http://github.com/gbv/paia/fork_select>
2. Check out your fork
3. Modify `paia.md`.
4. Commit you changes and push to github
5. Request a merge of your modification

You can also just comment in the project Issue tracker and in the wiki:

* https://github.com/gbv/paia/issues
* https://github.com/gbv/paia/wiki

Creating a nice HTML version and other output formats from `paia.md` requires
[Pandoc](http://johnmacfarlane.net/pandoc/) 1.9: simply call `make` in your
working directory. With `make pdf` you get a (less nice) PDF version.
