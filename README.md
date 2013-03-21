The **Patrons Account Information API (PAIA)** is a HTTP based programming
interface to access library patron information, such as loans, reservations,
and fees. See http://gbv.github.com/paia/paia.html for an overview.

This git repository, hosted at http://github.com/gbv/paia, contains a
preliminary specification of PAIA. The master file is `paia.md`.
The specification is written in
[Pandoc’s Markdown](http://johnmacfarlane.net/pandoc/demo/example9/pandocs-markdown.html).
The specification is managed with [makespec](https://github.com/jakobib/makespec)
to create a nice looking HTML version and the website.

# How to contribute to the specification

Please use the [issue tracker](https://github.com/gbv/paia/issues) to comment.
Given a GitHub account you can also fork this repository, do

    git clone git@github.com:YOURACCOUNT/paia.git
    cd paia
    git submodule update --init

    # modify paia.md

    make

    # check whether paia.html looks fine

    git add paia.md
    git commit -m "your comment"
    git push origin master

and request a pull of your modification.
