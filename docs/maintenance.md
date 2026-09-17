# Maintaining iogos

The entry point for a maintainer of this repository, at the path the Eunoia
ecosystem's shared repository policy says anybody can guess.

**Footing:** `associate` — held to the Eunoia ecosystem's shared
repository policy by this repository's own choice, and owing that ecosystem
nothing. The obligation is self-imposed: it is recorded here, this repository
answers to it by itself, and nobody is owed it. It is kept off the front page
because there is not yet enough here to put behind a declaration — this tree is
not published, it is one person's working tree, and the calculus itself has not
been installed yet, so announcing membership on the README would oversell what
is in it. The claim moves here rather than being dropped, so that a reader has
a line to hold this repository to.

## The policy check

[`.github/workflows/anoieu.yml`](../.github/workflows/anoieu.yml) runs the
shared policy checker on every push and pull request, as `anoieu / policy`.
What it reads is this tree; what it is read against is the marker above.

| | |
| --- | --- |
| checker | [anoieu](https://github.com/ajreynol/anoieu), `scripts/policy_check.py` |
| pinned revision | `6f9ee38b3c142dce22458a5ba290c062b7899aa9` |
| policy text | [`docs/policy.md`](https://github.com/ajreynol/kanon/blob/main/docs/policy.md) in [kanon](https://github.com/ajreynol/kanon), read at commit `ec5c960a1b8fd91fe0ad7b15e9294e780deaf785` |

The pin is a commit and never a branch, because a run that can turn green
without anybody committing is not evidence that a commit was good. Move it only
to a commit where anoieu's own CI is green, and ask the checker about that
commit rather than about its tip.

**What the check prints here is a measurement.** An associate owes this
ecosystem nothing, so a failing run is nobody's fault, obliges this repository
to nothing, and counts toward nothing. It is run because reading the result
back against the line above is worth having, not because anybody is due it.
