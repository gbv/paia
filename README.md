The **Patrons Account Information API (PAIA)** is a HTTP based programming
interface to access library patron information, such as loans, reservations,
and fees. See <http://gbv.github.com/paia/> for the current version and
<https://github.com/gbv/paia/releases> for releases and release notes.

This git repository, hosted at <http://github.com/gbv/paia>, contains all
sources of and modifications to the PAIA specification.

The master file [paia.md](https://github.com/gbv/paia/blob/master/paia.md) is
written in [Pandoc’s Markdown].  HTML version of the specification is generated
from the master file with [makespec](https://github.com/jakobib/makespec). The
specification can be distributed freely under the terms of CC-BY-SA.

[Pandoc’s Markdown]: http://johnmacfarlane.net/pandoc/demo/example9/pandocs-markdown.html

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
